import os
import socket
from oauthenticator.generic import GenericOAuthenticator
c.JupyterHub.authenticator_class = GenericOAuthenticator

c.JupyterHub.db_url = os.environ.get('DB_URL', 'sqlite:///jupyterhub.sqlite')
c.JupyterHub.ssl_cert = '/etc/jupyter/ssl.crt'
c.JupyterHub.ssl_key = '/etc/jupyter/ssl.key'

c.Authenticator.auto_login = True
c.Authenticator.enable_auth_state = True
c.Authenticator.admin_users = set([os.environ['ADMIN_USERS']])

c.JupyterHub.spawner_class = 'dockerspawner.DockerSpawner'
c.DockerSpawner.image = os.environ['DOCKER_SPAWNER_IMAGE']
c.DockerSpawner.volumes = {'/etc/jupyter':'/etc/jupyter'}
c.DockerSpawner.remove_containers = True
c.DockerSpawner.debug = True
c.Spawner.env_keep = ['PATH', 'DATABASE_URL']
c.Spawner.cmd = ['jupyter-labhub']
c.Spawner.default_url = '/lab'
