import os
from s3contents import S3ContentsManager
c = get_config()

c.NotebookApp.contents_manager_class = S3ContentsManager
c.NotebookApp.terminals_enabled = False
c.S3ContentsManager.access_key_id = os.environ['JPYNB_S3_ACCESS_KEY_ID']
c.S3ContentsManager.secret_access_key = os.environ['JPYNB_S3_SECRET_ACCESS_KEY']
c.S3ContentsManager.region_name= os.environ['JPYNB_S3_REGION_NAME']
c.S3ContentsManager.bucket = os.environ['JPYNB_S3_BUCKET_NAME']
c.S3ContentsManager.prefix = os.environ['JUPYTERHUB_USER']
## TODO: Server Side Encryption (SSE) not supported in current version
# c.S3ContentsManager.sse = "AES256"
