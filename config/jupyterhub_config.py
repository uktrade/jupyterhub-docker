import os
import socket
from oauthenticator.generic import GenericOAuthenticator
c.JupyterHub.authenticator_class = GenericOAuthenticator

c.JupyterHub.bind_url = 'http://0.0.0.0:8000'
c.ConfigurableHTTPProxy.api_url = 'http://0.0.0.0:8001'
c.Authenticator.auto_login = True
c.Authenticator.enable_auth_state = True
c.Authenticator.admin_users = set([os.environ['ADMIN_USERS']])
c.JupyterHub.db_url = os.environ.get('DB_URL', 'sqlite:///jupyterhub.sqlite')
c.Spawner.cmd = ['/opt/conda/bin/jupyterhub-singleuser']
c.Spawner.env_keep = ['PATH', 'JPYNB_S3_ACCESS_KEY_ID', 'JPYNB_S3_SECRET_ACCESS_KEY', 'JPYNB_S3_REGION_NAME', 'JPYNB_S3_BUCKET_NAME']

from subprocess import check_call
def spawner_init(spawner):
    check_call(['/spawner-init.sh', spawner.user.name])

c.Spawner.pre_spawn_hook = spawner_init
