import os
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
