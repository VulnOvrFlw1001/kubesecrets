import json, psycopg2, os
from flask import Flask, request

app = Flask(__name__)

@app.route('/', methods = ['POST'])
def handler(): 
    try:
        data = request.get_json(force=True)
    except json.JSONDecodeError as e:
        return f"Error Decoding JSON: {e}", 400

    token_parts = data.get('spec', {}).get('token', '').split(':')
    if len(token_parts) != 2:
        return f"Badly formatted token: {data.get('spec', {}).get('token', '').split(':')}", 400

    username, password = token_parts
    try:
        user_info, err = db_search(username, password)
        if err is not None:
            return f"Failed Search Request: {err}", 500
        if user_info is not None:
            response = {
                "status": {
                    "authenticated": True,
                    "user" : user_info
                }
            }
        else:
            response = {
                "status": {
                    "authenticated": False,
                }
            }
        return json.dumps(response)
    except Exception as e:
        return f"Internal Server Error: {e}", 500
    
def db_search(username,password):
    try:
        conn = psycopg2.connect(database="postgres", user="postgres", password=f"{os.environ['POSTGRES_PASSWORD']}", host="", port="5432")
        cursor = conn.cursor()
        cursor.execute(f"SELECT password FROM users where NAME = '{username}'")
        real_password = cursor.fetchall()
        cursor.close()
        conn.close()
        if real_password[0][0] == password:
            user_info = {
                'username': username
            }
            return user_info, None
        else:
            return None, None
    except Exception as e:
        return None, e

if __name__ == '__main__':
    app.run(host="0.0.0.0")