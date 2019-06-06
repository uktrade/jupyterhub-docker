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
from logging.handlers import HTTPHandler
import os
import subprocess

from async_http_logging_handler import AsyncHTTPLoggingHandler
from jupyters3 import JupyterS3, JupyterS3ECSRoleAuthentication
from tornado.ioloop import IOLoop
from tornado.httpclient import AsyncHTTPClient

http_handler = AsyncHTTPLoggingHandler(
    ioloop=IOLoop.current(),
    client=AsyncHTTPClient(force_instance=True),
    host=os.environ['LOGSTASH_HOST'],
    port=os.environ['LOGSTASH_PORT'],
    path="/",
)
loggers = [
    logging.getLogger(),
    # These can result in a lot of log messages
    # logging.getLogger('urllib3'),
    # logging.getLogger('tornado'),
    # logging.getLogger('tornado.access'),
    # For logging exceptions
    logging.getLogger('tornado.application'),
    logging.getLogger('tornado.general'),
]
for logger in loggers:
    logger.addHandler(http_handler)
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
