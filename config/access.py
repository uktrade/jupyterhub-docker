from collections import namedtuple
import datetime
import hashlib
import hmac
import json
import re
import urllib
from tornado.httpclient import (
    AsyncHTTPClient,
    HTTPError,
    HTTPRequest,
)


def access_spawn_hooks(notebook_task_role, database_endpoint):

    async def pre_spawn_hook(spawner):
        email_address = spawner.user.name
        spawner.log.debug('User (%s) setting up database DSNs..', email_address)

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

        spawner.environment = {
            **spawner.environment,
            **dict(database_dsns),
        }

        spawner.log.debug('User (%s) setting up database DSNs... done (%s)', email_address, database_dsns)
        spawner.log.debug('User (%s) setting up AWS role...', email_address)

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
            await make_iam_request(spawner.log, notebook_task_role['access_key_id'], notebook_task_role['secret_access_key'],
                                   payload_create_role)
        except HTTPError as exception:
            if exception.response.code != 409 or b'<Code>EntityAlreadyExists</Code>' not in exception.response.body:
                raise

        payload_put_role_policy = urllib.parse.urlencode({
            'Action': 'PutRolePolicy',
            'Version': '2010-05-08',
            'RoleName': role_name,
            'PolicyName': notebook_task_role['policy_name'],
            'PolicyDocument': notebook_task_role['policy_document_template'].replace('__JUPYTERHUB_USER__', email_address),
        }).encode('utf-8')
        await make_iam_request(spawner.log, notebook_task_role['access_key_id'], notebook_task_role['secret_access_key'],
                               payload_put_role_policy)

        payload_get_role = urllib.parse.urlencode({
            'Action': 'GetRole',
            'Version': '2010-05-08',
            'RoleName': role_name,
        }).encode('utf-8')
        response_get_role = await make_iam_request(spawner.log, notebook_task_role['access_key_id'], notebook_task_role['secret_access_key'],
                                                   payload_get_role)
        spawner.task_role_arn = re.search(b'<Arn>([^<]+)</Arn>', response_get_role.body)[1]

        spawner.log.debug('User (%s) set up AWS role... done (%s)', email_address, spawner.task_role_arn)

    async def post_stop_hook(spawner):
        # Possibly YAGNI, but small prices for consisent API for later changes
        pass

    return pre_spawn_hook, post_stop_hook


async def make_iam_request(log, access_key_id, secret_access_key, payload):
    host = 'iam.amazonaws.com'
    method = 'POST'
    path = '/'
    pre_auth_headers = {}

    headers = _aws_headers(
        service='iam', access_key_id=access_key_id, secret_access_key=secret_access_key,
        region='us-east-1', host=host, method='POST', path='/',
        query={}, pre_auth_headers=pre_auth_headers, payload=payload,
    )
    request = HTTPRequest(f'https://{host}{path}', method=method, headers=headers, body=payload)

    try:
        response = await AsyncHTTPClient().fetch(request)
    except HTTPError as exception:
        log.error(exception.response.body)
        raise

    return response


def _aws_headers(service, access_key_id, secret_access_key,
                 region, host, method, path, query, pre_auth_headers, payload):
    algorithm = 'AWS4-HMAC-SHA256'

    now = datetime.datetime.utcnow()
    amzdate = now.strftime('%Y%m%dT%H%M%SZ')
    datestamp = now.strftime('%Y%m%d')
    credential_scope = f'{datestamp}/{region}/{service}/aws4_request'
    headers_lower = {
        header_key.lower().strip(): header_value.strip()
        for header_key, header_value in pre_auth_headers.items()
    }
    signed_header_keys = sorted([header_key
                                 for header_key in headers_lower.keys()] + ['host', 'x-amz-date'])
    signed_headers = ';'.join([header_key for header_key in signed_header_keys])
    payload_hash = hashlib.sha256(payload).hexdigest()

    def signature():
        def canonical_request():
            header_values = {
                **headers_lower,
                'host': host,
                'x-amz-date': amzdate,
            }

            canonical_uri = urllib.parse.quote(path, safe='/~')
            query_keys = sorted(query.keys())
            canonical_querystring = '&'.join([
                urllib.parse.quote(key, safe='~') + '=' + urllib.parse.quote(query[key], safe='~')
                for key in query_keys
            ])
            canonical_headers = ''.join([
                header_key + ':' + header_values[header_key] + '\n'
                for header_key in signed_header_keys
            ])

            return f'{method}\n{canonical_uri}\n{canonical_querystring}\n' + \
                   f'{canonical_headers}\n{signed_headers}\n{payload_hash}'

        def sign(key, msg):
            return hmac.new(key, msg.encode('utf-8'), hashlib.sha256).digest()

        string_to_sign = \
            f'{algorithm}\n{amzdate}\n{credential_scope}\n' + \
            hashlib.sha256(canonical_request().encode('utf-8')).hexdigest()

        date_key = sign(('AWS4' + secret_access_key).encode('utf-8'), datestamp)
        region_key = sign(date_key, region)
        service_key = sign(region_key, service)
        request_key = sign(service_key, 'aws4_request')
        return sign(request_key, string_to_sign).hex()

    return {
        **pre_auth_headers,
        'x-amz-date': amzdate,
        'x-amz-content-sha256': payload_hash,
        'Authorization': (
            f'{algorithm} Credential={access_key_id}/{credential_scope}, ' +
            f'SignedHeaders={signed_headers}, Signature=' + signature()
        ),
    }

