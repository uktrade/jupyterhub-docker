from s3contents import S3ContentsManager
c = get_config()

c.NotebookApp.contents_manager_class = S3ContentsManager

## TODO: Server Side Encryption (SSE) not supported in current version
# c.S3ContentsManager.sse = "AES256"
