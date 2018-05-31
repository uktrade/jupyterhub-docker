import os
from oauthenticator.generic import GenericOAuthenticator
c.JupyterHub.authenticator_class = GenericOAuthenticator

c.JupyterHub.ip = '0.0.0.0'
c.JupyterHub.hub_ip = '0.0.0.0'
c.Authenticator.auto_login = True
c.Authenticator.enable_auth_state = True
c.Authenticator.admin_users = set([os.environ['ADMIN_USERS']])
c.JupyterHub.db_url = os.environ.get('DB_URL', 'sqlite:///jupyterhub.sqlite')
c.Spawner.env_keep = ['JPYNB_S3_ACCESS_KEY_ID', 'JPYNB_S3_SECRET_ACCESS_KEY', 'JPYNB_S3_REGION_NAME', 'JPYNB_S3_BUCKET_NAME']

from subprocess import check_call
def spawner_init(spawner):
    check_call(['/spawner-init.sh', spawner.user.name])
    c.Spawner.args = ['--NotebookApp.S3ContentsManager.prefix=' + spawner.user.name]

c.Spawner.pre_spawn_hook = spawner_init
