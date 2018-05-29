from s3contents import S3ContentsManager
c = get_config()

c.NotebookApp.contents_manager_class = S3ContentsManager
c.S3ContentsManager.prefix = os.environ['JUPYTERHUB_USER']
## TODO: Server Side Encryption (SSE) not supported in current version
# c.S3ContentsManager.sse = "AES256"
