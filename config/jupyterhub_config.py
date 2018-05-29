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
c.JupyterHub.spawner_class = 'dockerspawner.DockerSpawner'
c.DockerSpawner.image = os.environ['DOCKER_SPAWNER_IMAGE']
c.DockerSpawner.remove_containers = True
c.Spawner.start_timeout = 300
c.Spawner.env_keep = ['JPYNB_S3_ACCESS_KEY_ID', 'JPYNB_S3_SECRET_ACCESS_KEY', 'JPYNB_S3_REGION_NAME', 'JPYNB_S3_BUCKET_NAME']
c.Spawner.args = ['--allow-root', '--debug']

from subprocess import check_call
def docker_init(spawner):
    check_call(['docker', 'pull', os.environ['DOCKER_SPAWNER_IMAGE']])

c.Spawner.pre_spawn_hook = docker_init
