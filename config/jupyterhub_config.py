import os
from oauthenticator.generic import GenericOAuthenticator
c.JupyterHub.authenticator_class = GenericOAuthenticator

c.JupyterHub.bind_url = 'http://0.0.0.0:8000'
c.JupyterHub.hub_ip = '0.0.0.0'
c.ConfigurableHTTPProxy.api_url = 'http://0.0.0.0:8001'
c.JupyterHub.pid_file = '/var/run/jupyterhub.lock'
c.Authenticator.auto_login = True
c.Authenticator.enable_auth_state = True
c.Authenticator.admin_users = set([os.environ['ADMIN_USERS']])

from subprocess import check_call
def spawner_init(spawner):
    check_call(['/spawner-init.sh', spawner.user.name])
    c.Spawner.args = ['--NotebookApp.S3ContentsManager.prefix=' + username]

c.Spawner.pre_spawn_hook = spawner_init
