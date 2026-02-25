import os
from flask import Flask
import sqlalchemy
from google.cloud.sql.connector import Connector, IPTypes
import pg8000

app = Flask(__name__)

# Environment Variables
# For the Connector, this is "project:region:instance-name"
# You can find this on the Cloud SQL Overview page.
instance_connection_name = os.environ.get("INSTANCE_CONNECTION_NAME") 
db_user = os.environ.get("DB_USER") # Service Account email without .gserviceaccount.com
db_name = os.environ.get("DB_NAME", "postgres")

# Initialize Connector
connector = Connector(refresh_strategy="lazy")

def getconn() -> pg8000.dbapi.Connection:
    # This function creates a connection with IAM Auth enabled
    conn: pg8000.dbapi.Connection = connector.connect(
        instance_connection_name,
        "pg8000",
        user=db_user,
        db=db_name,
        enable_iam_auth=True, # This replaces the password with a token
        ip_type=IPTypes.PSC   # Tells the connector to use your PSC path
    )
    return conn

# Create SQLAlchemy Engine
# Note: The URL is just a prefix; 'creator' does the actual work.
pool = sqlalchemy.create_engine(
    "postgresql+pg8000://",
    creator=getconn,
)

@app.route("/")
def check_connection():
    try:
        with pool.connect() as conn:
            result = conn.execute(sqlalchemy.text("SELECT NOW(), current_user, current_database()")).fetchone()
            
            return f"""
            <html>
                <body style="font-family: sans-serif; padding: 50px;">
                    <h1 style="color: green;">✅ IAM Connection Successful!</h1>
                    <p><b>Database Time:</b> {result[0]}</p>
                    <p><b>Connected User:</b> {result[1]}</p>
                    <p><b>Database Name:</b> {result[2]}</p>
                </body>
            </html>
            """
    except Exception as e:
        return f"<h1>❌ Connection Failed</h1><pre>{str(e)}</pre>", 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))