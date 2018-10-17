import json
import os
import subprocess
import urllib
from database_access import database_access_spawn_hooks
from env_utils import normalise_environment
from fargatespawner import FargateSpawner
from jupyterhub.app import JupyterHub
from oauthenticator.generic import GenericOAuthenticator
from tornado.httpclient import AsyncHTTPClient

env = normalise_environment(os.environ)

c.JupyterHub.log_level = 'DEBUG'
c.JupyterHub.db_url = env['DB_URL']

# The interface that the hub listens on, 0.0.0.0 == all
c.JupyterHub.hub_ip = '0.0.0.0'

# The IP that _other_ services will connect to the hub on, i.e. the current private IP address
with urllib.request.urlopen('http://169.254.170.2/v2/metadata') as response:
   c.JupyterHub.hub_connect_ip = json.loads(response.read().decode('utf-8'))['Containers'][0]['Networks'][0]['IPv4Addresses'][0]

ssl_cert = env['HOME'] + '/ssl.crt'
ssl_key = env['HOME'] + '/ssl.key'
subprocess.check_call([
    'openssl', 'req', '-new', '-newkey', 'rsa:2048', '-days', '3650', '-nodes', '-x509',
    '-subj', '/CN=selfsigned',
    '-keyout', ssl_key,
    '-out', ssl_cert,
], env={'RANDFILE': env['HOME'] + '/openssl_rnd'})
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
c.ConfigurableHTTPProxy.pid_file = env['HOME'] + '/proxy.pid'

c.JupyterHub.authenticator_class = GenericOAuthenticator
c.Authenticator.auto_login = True
c.Authenticator.enable_auth_state = True
c.Authenticator.admin_users = set(env['ADMIN_USERS'].split())

c.JupyterHub.spawner_class = FargateSpawner
c.FargateSpawner.aws_region = env['FARGATE_SPAWNER']['AWS_REGION']
c.FargateSpawner.aws_host = env['FARGATE_SPAWNER']['AWS_HOST']
c.FargateSpawner.aws_access_key_id = env['FARGATE_SPAWNER']['AWS_ACCESS_KEY_ID']
c.FargateSpawner.aws_secret_access_key = env['FARGATE_SPAWNER']['AWS_SECRET_ACCESS_KEY']
c.FargateSpawner.task_cluster_name = env['FARGATE_SPAWNER']['TASK_CUSTER_NAME']
c.FargateSpawner.task_container_name = env['FARGATE_SPAWNER']['TASK_CONTAINER_NAME']
c.FargateSpawner.task_definition_arn = env['FARGATE_SPAWNER']['TASK_DEFINITION_ARN']
c.FargateSpawner.task_security_groups = [env['FARGATE_SPAWNER']['TASK_SECURITY_GROUP']]
c.FargateSpawner.task_subnets = [env['FARGATE_SPAWNER']['TASK_SUBNET']]
c.FargateSpawner.notebook_port = int(env['FARGATE_SPAWNER']['NOTEBOOK_PORT'])
c.FargateSpawner.notebook_scheme = 'https'
c.FargateSpawner.notebook_args = [
    '--config=/etc/jupyter/jupyter_notebook_config.py',
    # The default behaviour is that the Notebook connects to the Hub directly by HTTP.
    # We connect via the proxy, which is on the same IP as the hub, and which is
    # listening on HTTPS
    '--SingleUserNotebookApp.hub_api_url=' + f'https://{c.JupyterHub.hub_connect_ip}:8000/hub/api',
    '--JupyterS3.aws_access_key_id=' + env['JPYNB_S3_ACCESS_KEY_ID'],
    '--JupyterS3.aws_secret_access_key=' + env['JPYNB_S3_SECRET_ACCESS_KEY'],
    '--JupyterS3.aws_region=' + env['JPYNB_S3_REGION_NAME'],
    '--JupyterS3.aws_s3_host=' + env['JPYNB_S3_BUCKET_NAME'] + '.s3.' + env['JPYNB_S3_REGION_NAME'] + '.amazonaws.com',
    '--JupyterS3.aws_s3_bucket=' + env['JPYNB_S3_BUCKET_NAME']
]

c.FargateSpawner.pre_spawn_hook, c.FargateSpawner.post_stop_hook = database_access_spawn_hooks(env['DATABASE_ACCESS']['URL'])
c.FargateSpawner.debug = True
c.FargateSpawner.start_timeout = 480
c.FargateSpawner.env_keep = ['DATABASE_URL']
c.FargateSpawner.cmd = ['jupyter-labhub']

c.JupyterHub.tornado_settings = {
    # We immediately show the page with the progress bar
    'slow_spawn_timeout': 0,
}
