import hashlib
import json
import os
import re
import urllib

from tornado.httpclient import (
    AsyncHTTPClient,
    HTTPError,
    HTTPRequest,
)

from utils import aws_sig_v4_headers


def access_spawn_hooks(notebook_task_role, database_endpoint):

    async def pre_spawn_hook(spawner):
        auth_state = await spawner.user.get_auth_state()
        user_id = auth_state['oauth_user']['user_id']
        email_address = spawner.user.name
        spawner.log.debug('User (%s,%s) setting up database DSNs..', user_id, email_address)

        token = (await spawner.user.get_auth_state())['access_token']
        http_client = AsyncHTTPClient()
        http_request = HTTPRequest(database_endpoint, method='GET', headers={
            'Authorization': f'Bearer {token}',
        })
        http_response = await http_client.fetch(http_request)
        database_dsns = [
            (
                f'DATABASE_DSN__{database["memorable_name"]}',
                f'host={database["db_host"]} port={database["db_port"]} sslmode=require dbname={database["db_name"]} user={database["db_user"]} password={database["db_password"]}'
            )
            for database in json.loads(http_response.body)['databases']
        ]
        s3_prefix = 'user/federated/' + hashlib.sha256(user_id.encode('utf-8')).hexdigest() + '/'

        spawner.environment = {
            **spawner.environment,
            **dict(database_dsns),
            'S3_PREFIX': s3_prefix,
        }

        spawner.log.debug('User (%s) setting up database DSNs... done (%s)', email_address, database_dsns)
        spawner.log.debug('User (%s) setting up AWS role...', email_address)

        request = HTTPRequest('http://169.254.170.2/' + os.environ['AWS_CONTAINER_CREDENTIALS_RELATIVE_URI'], method='GET')
        creds = json.loads((await AsyncHTTPClient().fetch(request)).body.decode('utf-8'))
        access_key_id = creds['AccessKeyId']
        secret_access_key = creds['SecretAccessKey']
        pre_auth_headers = {
            'x-amz-security-token': creds['Token'],
        }

        role_name = notebook_task_role['role_prefix'] + email_address
        payload_create_role = urllib.parse.urlencode({
            'Action': 'CreateRole',
            'Version': '2010-05-08',
            'RoleName': role_name,
            'Path': '/',
            'AssumeRolePolicyDocument': notebook_task_role['assume_role_policy_document'],
            'PermissionsBoundary': notebook_task_role['permissions_boundary_arn'],
        }).encode('utf-8')
        try:
            await make_iam_request(spawner.log, access_key_id, secret_access_key, pre_auth_headers,
                                   payload_create_role)
        except HTTPError as exception:
            if exception.response.code != 409 or b'<Code>EntityAlreadyExists</Code>' not in exception.response.body:
                raise

        payload_put_role_policy = urllib.parse.urlencode({
            'Action': 'PutRolePolicy',
            'Version': '2010-05-08',
            'RoleName': role_name,
            'PolicyName': notebook_task_role['policy_name'],
            'PolicyDocument': notebook_task_role['policy_document_template'].replace('__S3_PREFIX__', s3_prefix),
        }).encode('utf-8')
        await make_iam_request(spawner.log, access_key_id, secret_access_key, pre_auth_headers,
                               payload_put_role_policy)

        payload_get_role = urllib.parse.urlencode({
            'Action': 'GetRole',
            'Version': '2010-05-08',
            'RoleName': role_name,
        }).encode('utf-8')
        response_get_role = await make_iam_request(spawner.log, access_key_id, secret_access_key, pre_auth_headers,
                                                   payload_get_role)
        spawner.task_role_arn = re.search(b'<Arn>([^<]+)</Arn>', response_get_role.body)[1]

        spawner.log.debug('User (%s) set up AWS role... done (%s)', email_address, spawner.task_role_arn)

    async def post_stop_hook(spawner):
        # Possibly YAGNI, but small prices for consisent API for later changes
        pass

    return pre_spawn_hook, post_stop_hook


async def make_iam_request(log, access_key_id, secret_access_key, pre_auth_headers, payload):
    host = 'iam.amazonaws.com'
    method = 'POST'
    path = '/'
    query = {}

    headers = aws_sig_v4_headers(
        access_key_id, secret_access_key, pre_auth_headers,
        'iam', 'us-east-1', host, 'POST', path, query, payload,
    )
    request = HTTPRequest(f'https://{host}{path}', method=method, headers=headers, body=payload)

    try:
        response = await AsyncHTTPClient().fetch(request)
    except HTTPError as exception:
        log.error(exception.response.body)
        raise

    return response
