import os
import subprocess
import urllib
from fargate_spawner import FargateSpawner
from jupyterhub.app import JupyterHub
from oauthenticator.generic import GenericOAuthenticator
from tornado.httpclient import AsyncHTTPClient

c.JupyterHub.log_level = 'DEBUG'
c.JupyterHub.db_url = os.environ['DB_URL']

# The interface that the hub listens on, 0.0.0.0 == all
c.JupyterHub.hub_ip = '0.0.0.0'

# The IP that _other_ services will connect to the hub on, i.e. the current private IP address
with urllib.request.urlopen('http://169.254.169.254/latest/meta-data/local-ipv4') as response:
   c.JupyterHub.hub_connect_ip = response.read().decode('ascii')

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

# The Notebook uses a self signed cert, which is presented both to the hub
# and to the proxy. Note:
# - The diagram at https://jupyterhub.readthedocs.io/en/stable/ doesn't
#   mention that the hub initiates connections with the Notebook directly,
#   but it does: to determine if it's running or not
# - JupyterHub seems to use CurlAsyncHTTPClient, with no way of passing
#   any default args. Hence the monkey-patching below.
def init_pycurl(self):
    AsyncHTTPClient.configure('tornado.curl_httpclient.CurlAsyncHTTPClient', defaults=dict(validate_cert=False))
JupyterHub.init_pycurl = init_pycurl
c.ConfigurableHTTPProxy.command = ['configurable-http-proxy', '--insecure']

c.JupyterHub.authenticator_class = GenericOAuthenticator
c.Authenticator.auto_login = True
c.Authenticator.enable_auth_state = True
c.Authenticator.admin_users = set(os.environ['ADMIN_USERS'].split())

c.JupyterHub.spawner_class = FargateSpawner
c.FargateSpawner.endpoint = {
    'cluster_name': os.environ['FARGATE_SPAWNER__CUSTER_NAME'],
    'task_definition_arn': os.environ['FARGATE_SPAWNER__TASK_DEFINITION_ARN'],
    'security_groups': [os.environ['FARGATE_SPAWNER__SECURITY_GROUP']],
    'subnets': [os.environ['FARGATE_SPAWNER__SUBNET']],
    'region': os.environ['FARGATE_SPAWNER__REGION'],
    'host': os.environ['FARGATE_SPAWNER__HOST'],
    'access_key_id': os.environ['FARGATE_SPAWNER__ACCESS_KEY_ID'],
    'secret_access_key': os.environ['FARGATE_SPAWNER__SECRET_ACCESS_KEY'],
    'notebook_port': int(os.environ['FARGATE_SPAWNER__PORT']),
    'notebook_scheme': 'https',
    'notebook_args': [
        '--config=/etc/jupyter/jupyter_notebook_config.py',
        # The default behaviour is that the Notebook connects to the Hub directly by HTTP.
        # We connect via the proxy, which is on the same IP as the hub, and which is
        # listening on HTTPS
        '--SingleUserNotebookApp.hub_api_url=' + f'https://{c.JupyterHub.hub_connect_ip}:8000/hub/api',
        '--S3ContentsManager.access_key_id=' + os.environ['JPYNB_S3_ACCESS_KEY_ID'],
        '--S3ContentsManager.secret_access_key=' + os.environ['JPYNB_S3_SECRET_ACCESS_KEY'],
        '--S3ContentsManager.region_name=' + os.environ['JPYNB_S3_REGION_NAME'],
        '--S3ContentsManager.bucket=' + os.environ['JPYNB_S3_BUCKET_NAME'],
    ],
}
c.FargateSpawner.debug = True
c.FargateSpawner.start_timeout = 600
c.Spawner.env_keep = ['PATH', 'DATABASE_URL']
# c.Spawner.cmd = ['jupyter-labhub']
# c.Spawner.default_url = '/lab'

c.JupyterHub.tornado_settings = {
    # We immediately show the page with the progress bar
    'slow_spawn_timeout': 0,
}
