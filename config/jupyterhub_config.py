import os
import socket
from oauthenticator.generic import GenericOAuthenticator
c.JupyterHub.authenticator_class = GenericOAuthenticator

c.JupyterHub.bind_url = 'https://0.0.0.0:8000'
c.JupyterHub.db_url = os.environ.get('DB_URL', 'sqlite:///jupyterhub.sqlite')
c.JupyterHub.ssl_cert = '/etc/jupyter/ssl.crt'
c.JupyterHub.ssl_key = '/etc/jupyter/ssl.key'

c.Authenticator.auto_login = True
c.Authenticator.enable_auth_state = True
c.Authenticator.admin_users = set([os.environ['ADMIN_USERS']])

c.JupyterHub.spawner_class = 'dockerspawner.DockerSpawner'
c.DockerSpawner.image = os.environ['DOCKER_SPAWNER_IMAGE']
c.Spawner.env_keep = ['PATH', 'JPYNB_S3_ACCESS_KEY_ID', 'JPYNB_S3_SECRET_ACCESS_KEY', 'JPYNB_S3_REGION_NAME', 'JPYNB_S3_BUCKET_NAME']
