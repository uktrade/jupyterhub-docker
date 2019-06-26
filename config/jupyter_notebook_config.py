import sentry_sdk
import sentry_sdk.transport
from sentry_sdk.integrations.tornado import TornadoIntegration

# We use self-signed certs in the proxy
def _get_pool_options(self, ca_certs):
    return {
        'num_pools': 2,
        'cert_reqs': 'CERT_NONE'
    }
sentry_sdk.transport.HttpTransport._get_pool_options = _get_pool_options
sentry_sdk.init()
sentry_sdk.init(integrations=[TornadoIntegration()])

import logging
import os
import sys
from jupyters3 import JupyterS3, JupyterS3ECSRoleAuthentication

handler = logging.StreamHandler(sys.stdout)
handler.setLevel(logging.DEBUG)

loggers = [
    logging.getLogger(),
    logging.getLogger('urllib3'),
    logging.getLogger('tornado'),
    logging.getLogger('tornado.access'),
    logging.getLogger('tornado.application'),
    logging.getLogger('tornado.general'),
]
for logger in loggers:
    logger.addHandler(handler)
c = get_config()

c.NotebookApp.ip = '0.0.0.0'
c.NotebookApp.terminals_enabled = False
c.NotebookApp.contents_manager_class = JupyterS3
c.NotebookApp.log_level = 'DEBUG'

c.JupyterS3.prefix = os.environ['S3_PREFIX']
c.JupyterS3.aws_region = os.environ['S3_REGION']
c.JupyterS3.aws_s3_host  = os.environ['S3_HOST']
c.JupyterS3.aws_s3_bucket = os.environ['S3_BUCKET']
c.JupyterS3.authentication_class = JupyterS3ECSRoleAuthentication
