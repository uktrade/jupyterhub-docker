import os
import subprocess
from jupyters3 import JupyterS3
from jupyterhub.services.auth import HubOAuth
from tornado.httpclient import AsyncHTTPClient
c = get_config()

c.NotebookApp.ip = '0.0.0.0'
c.NotebookApp.terminals_enabled = False
c.NotebookApp.contents_manager_class = JupyterS3

c.JupyterS3.prefix = os.environ['JUPYTERHUB_USER'] + '/'

keyfile = os.environ['HOME'] + '/ssl.key'
certfile = os.environ['HOME'] + '/ssl.crt'
subprocess.check_call([
    os.environ['CONDA_DIR'] + '/bin/openssl', 'req', '-new', '-newkey', 'rsa:2048', '-days', '3650', '-nodes', '-x509',
    '-subj', '/CN=selfsigned',
    '-keyout', keyfile,
    '-out', certfile,
], env={'RANDFILE': os.environ['HOME'] + '/openssl_rnd'})
c.NotebookApp.keyfile = keyfile
c.NotebookApp.certfile = certfile

# API requests to the hub are via the proxy and HTTPS, which uses a self
# signed certificate. Strangly, some requests use Tornado's AsyncHTTPClient
# (but not the version that uses pycurl like the Hub proper does)...
AsyncHTTPClient.configure(None, defaults=dict(validate_cert=False))

# ... and some seem to use requests, with no apparent way to pass in extra
# arguments other than monkey patching
_api_request_original = HubOAuth._api_request
def _api_request(self, method, url, **kwargs):
    args_verify_false = {
        **kwargs,
        'verify': False,
    }
    return _api_request_original(self, method, url, **args_verify_false)
HubOAuth._api_request = _api_request
