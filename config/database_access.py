import datetime
import json
import re
import secrets
import string
import aiopg
from tornado.httpclient import (
    AsyncHTTPClient,
    HTTPRequest,
)


def database_access_spawn_hooks(database_endpoint, databases, users):
    password_alphabet = string.ascii_letters + string.digits
    user_alphabet = string.ascii_lowercase + string.digits

    async def pre_spawn_hook(spawner):
        email_address = spawner.user.name
        spawner.log.debug('User (%s) setting up database URLs...', email_address)

        def postgres_user():
            unique_enough = ''.join(secrets.choice(user_alphabet) for i in range(5))
            return 'user_' + re.sub('[^a-z0-9]', '_', email_address.lower()) + '_' + unique_enough

        def postgres_password():
            return ''.join(secrets.choice(password_alphabet) for i in range(64))

        async def grant_select_permissions(database, user, password, table_names_str):
            tomorrow = (datetime.date.today() + datetime.timedelta(days=1)).isoformat()
            master_dsn = f'host={database["HOST"]} port={database["PORT"]} dbname={database["NAME"]} user={database["MASTER_USER"]} password={database["MASTER_PASSWORD"]}'
            async with \
                    aiopg.create_pool(master_dsn) as pool, \
                    pool.acquire() as conn, \
                    conn.cursor() as cur:

                await cur.execute(f"CREATE USER {user} WITH PASSWORD '{password}' VALID UNTIL '{tomorrow}';")
                await cur.execute(f"GRANT CONNECT ON DATABASE {database['NAME']} TO {user};")
                await cur.execute(f"GRANT USAGE ON SCHEMA public TO {user};")
                await cur.execute(f"GRANT SELECT ON {table_names_str} TO {user};")
                await cur.execute(f"COMMIT;")

        database_tables = \
            users[email_address]['TABLES'].items() if email_address in users else \
            []

        database_dsns = []
        for database_friendly_name, table_names in database_tables:
            database = databases[database_friendly_name]
            user = postgres_user()
            password = postgres_password()
            table_names_str = ','.join(table_names)
            await grant_select_permissions(database, user, password, table_names_str)

            database_dsns.append((
                f'DATABASE_DSN__{database_friendly_name}__{table_names_str}',
                f'host={database["HOST"]} port={database["PORT"]} sslmode=require dbname={database["NAME"]} user={user} password={password}'
            ))

        token = (await spawner.user.get_auth_state())['access_token']
        http_client = AsyncHTTPClient()
        http_request = HTTPRequest(database_endpoint, method='GET', headers={
            'Authorization': f'Bearer {token}',
        })
        http_response = await http_client.fetch(http_request)
        for database in json.loads(http_response.body)['databases']:
            database_dsns.append((
                f'DATABASE_DSN__{database["memorable_name"]}',
                f'host={database["db_host"]} port={database["db_port"]} sslmode=require dbname={database["db_name"]} user={database["db_user"]} password={database["db_password"]}'
            ))

        spawner.environment = {
            **spawner.environment,
            **dict(database_dsns),
        }

        spawner.log.debug('User (%s) setting up database DSNs... done (%s)', email_address, database_dsns)

    async def post_stop_hook(spawner):
        # Possibly YAGNI, but small prices for consisent API for later changes
        pass

    return pre_spawn_hook, post_stop_hook
