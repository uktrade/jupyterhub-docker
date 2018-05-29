import os
from oauthenticator.generic import GenericOAuthenticator
c.JupyterHub.authenticator_class = GenericOAuthenticator

c.JupyterHub.bind_url = 'http://0.0.0.0:8000'
c.ConfigurableHTTPProxy.api_url = 'http://0.0.0.0:8001'
c.JupyterHub.pid_file = '/var/run/jupyterhub.lock'
c.Authenticator.auto_login = True
c.Authenticator.enable_auth_state = True
c.JupyterHub.admin_users = set([os.environ['ADMIN_USERS']])
c.DockerSpawner.image = os.environ['DOCKER_SPAWNER_IMAGE']

from subprocess import check_call
def docker_init(spawner):
    check_call(['/spawner-init.sh', spawner.user.name])
    check_call(['docker', 'pull', os.environ['DOCKER_SPAWNER_IMAGE']])
    c.Spawner.args = ['--NotebookApp.S3ContentsManager.prefix=' + spawner.user.name]

c.Spawner.pre_spawn_hook = docker_init
