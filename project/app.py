import os
from dotenv import load_dotenv
import psycopg
from psycopg.rows import dict_row
from flask import Flask, render_template, request

load_dotenv()

app = Flask(__name__)

def get_db_connection():
    return psycopg.connect(os.getenv('DATABASE_URL'), row_factory=dict_row)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/gry')
def lista_gier():
    search_query = request.args.get('search', '')
    
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            if search_query:
                sql = """
                    SELECT id_gry, nazwa, typ, min_stawka 
                    FROM gra 
                    WHERE nazwa ILIKE %s OR typ ILIKE %s 
                    ORDER BY id_gry
                """
                params = (f"%{search_query}%", f"%{search_query}%")
                cur.execute(sql, params)
            else:
                cur.execute("SELECT id_gry, nazwa, typ, min_stawka FROM gra ORDER BY id_gry")
            
            gry_z_bazy = cur.fetchall()
    
    return render_template('gry.html', gry=gry_z_bazy, search=search_query)

if __name__ == '__main__':
    app.run(debug=True)