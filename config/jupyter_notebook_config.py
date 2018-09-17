import os
from s3contents import S3ContentsManager
c = get_config()

c.NotebookApp.terminals_enabled = False
c.NotebookApp.contents_manager_class = S3ContentsManager
c.S3ContentsManager.access_key_id = "__JPYNB_S3_ACCESS_KEY_ID__"
c.S3ContentsManager.secret_access_key = "__JPYNB_S3_SECRET_ACCESS_KEY__"
c.S3ContentsManager.region_name= "__JPYNB_S3_REGION_NAME__"
c.S3ContentsManager.bucket = "__JPYNB_S3_BUCKET_NAME__"
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
