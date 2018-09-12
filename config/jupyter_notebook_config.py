import os
import subprocess
from s3contents import S3ContentsManager
from jupyterhub.services.auth import HubOAuth
from tornado.httpclient import AsyncHTTPClient
c = get_config()

c.NotebookApp.ip = '0.0.0.0'
c.NotebookApp.terminals_enabled = False
c.NotebookApp.contents_manager_class = S3ContentsManager

c.S3ContentsManager.prefix = os.environ['JUPYTERHUB_USER']
c.S3ContentsManager.sse = "AES256"

import dj_database_url
db_url = dj_database_url.parse(url=os.environ['DATABASE_URL'])
file = open(os.environ['HOME'] + "/.odbc.ini", "w")
file.write("[TiVA]" + "\n")
file.write("Driver = PostgreSQL Unicode" + "\n")
file.write("Servername = " + db_url['HOST'] + "\n")
file.write("Port = " + str(db_url['PORT']) + "\n")
file.write("Database = " + db_url['NAME'] + "\n")
file.write("UserName = " + db_url['USER'] + "\n")
file.write("Password = " + db_url['PASSWORD'] + "\n")
file.close()

keyfile = '/etc/jupyter/ssl.key'
certfile = '/etc/jupyter/ssl.crt'
subprocess.check_call([
    'openssl', 'req', '-new', '-newkey', 'rsa:2048', '-days', '3650', '-nodes', '-x509',
    '-subj', '/CN=selfsigned',
    '-keyout', keyfile,
    '-out', certfile,
])
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
