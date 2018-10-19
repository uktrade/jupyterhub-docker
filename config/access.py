import json
from tornado.httpclient import (
    AsyncHTTPClient,
    HTTPRequest,
)


def access_spawn_hooks(database_endpoint):

    async def pre_spawn_hook(spawner):
        email_address = spawner.user.name
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

    async def post_stop_hook(spawner):
        # Possibly YAGNI, but small prices for consisent API for later changes
        pass

    return pre_spawn_hook, post_stop_hook
