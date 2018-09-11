import os
import subprocess
from ecs_spawner import EcsSpawner
from oauthenticator.generic import GenericOAuthenticator

c.JupyterHub.log_level = 'DEBUG'
c.JupyterHub.db_url = os.environ.get('DB_URL', 'sqlite:///jupyterhub.sqlite')

ssl_cert = '/etc/jupyter/ssl.crt'
ssl_key = '/etc/jupyter/ssl.key'
subprocess.check_call([
    'openssl', 'req', '-new', '-newkey', 'rsa:2048', '-days', '3650', '-nodes', '-x509',
    '-subj', '/CN=selfsigned',
    '-keyout', ssl_key,
    '-out', ssl_cert,
])
c.JupyterHub.ssl_cert = ssl_cert
c.JupyterHub.ssl_key = ssl_key

c.JupyterHub.authenticator_class = GenericOAuthenticator
c.Authenticator.auto_login = True
c.Authenticator.enable_auth_state = True
c.Authenticator.admin_users = set(os.environ['ADMIN_USERS'].split())

c.JupyterHub.spawner_class = EcsSpawner
c.EcsSpawner.endpoint = {
    'cluster_name': os.environ['ECS_SPAWNER__CUSTER_NAME'],
    'task_definition_arn': os.environ['ECS_SPAWNER__TASK_DEFINITION_ARN'],
    'security_groups': [os.environ['ECS_SPAWNER__SECURITY_GROUP']],
    'subnets': [os.environ['ECS_SPAWNER__SUBNET']],
    'region': os.environ['ECS_SPAWNER__REGION'],
    'host': os.environ['ECS_SPAWNER__HOST'],
    'access_key_id': os.environ['ECS_SPAWNER__ACCESS_KEY_ID'],
    'secret_access_key': os.environ['ECS_SPAWNER__SECRET_ACCESS_KEY'],
    'port': int(os.environ['ECS_SPAWNER__PORT']),
    'notebook_args': [
        '--config=/etc/jupyter/jupyter_notebook_config.py',
        '--S3ContentsManager.access_key_id=' + os.environ['JPYNB_S3_ACCESS_KEY_ID'],
        '--S3ContentsManager.secret_access_key=' + os.environ['JPYNB_S3_SECRET_ACCESS_KEY'],
        '--S3ContentsManager.region_name=' + os.environ['JPYNB_S3_REGION_NAME'],
        '--S3ContentsManager.bucket=' + os.environ['JPYNB_S3_BUCKET_NAME'],
    ],
}
c.EcsSpawner.debug = True
c.EcsSpawner.start_timeout = 600
c.Spawner.env_keep = ['PATH', 'DATABASE_URL']
# c.Spawner.cmd = ['jupyter-labhub']
# c.Spawner.default_url = '/lab'

c.JupyterHub.tornado_settings = {
    # We immediately show the page with the progress bar
    'slow_spawn_timeout': 0,
}
