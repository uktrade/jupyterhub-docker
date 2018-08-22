import os
import socket
from oauthenticator.generic import GenericOAuthenticator
c.JupyterHub.authenticator_class = GenericOAuthenticator

c.JupyterHub.bind_url = 'https://0.0.0.0:8000'
c.JupyterHub.hub_ip = ''
c.JupyterHub.db_url = os.environ.get('DB_URL', 'sqlite:///jupyterhub.sqlite')
c.JupyterHub.ssl_cert = '/etc/jupyter/ssl.crt'
c.JupyterHub.ssl_key = '/etc/jupyter/ssl.key'

c.Authenticator.auto_login = True
c.Authenticator.enable_auth_state = True
c.Authenticator.admin_users = set([os.environ['ADMIN_USERS']])

c.JupyterHub.spawner_class = 'dockerspawner.DockerSpawner'
c.DockerSpawner.image = os.environ['DOCKER_SPAWNER_IMAGE']
network_name = os.environ['DOCKER_NETWORK_NAME'] or 'host'
c.DockerSpawner.network_name = network_name
c.DockerSpawner.extra_host_config = { 'network_mode': network_name }
c.DockerSpawner.volumes = {'/etc/jupyter':'/etc/jupyter'}
c.DockerSpawner.remove_containers = True
c.DockerSpawner.debug = True
c.Spawner.env_keep = ['PATH']
