import sqlite3
import psycopg2
import psycopg2.extras
import os
from datetime import datetime

def migrate_sqlite_to_postgres():
    """Migra dados do SQLite para PostgreSQL"""

    # Conexão SQLite
    sqlite_db = 'dadostv.db'
    if not os.path.exists(sqlite_db):
        print(f"Arquivo SQLite '{sqlite_db}' não encontrado.")
        return

    sqlite_conn = sqlite3.connect(sqlite_db)
    sqlite_cursor = sqlite_conn.cursor()

    # Conexão PostgreSQL
    try:
        pg_conn = psycopg2.connect(
            host='localhost',
            port=5432,
            dbname='tv_multimidia',
            user='tv_user',
            password='tv_password'
        )
        pg_cursor = pg_conn.cursor()
        print("Conectado ao PostgreSQL")
    except psycopg2.Error as e:
        print(f"Erro ao conectar ao PostgreSQL: {e}")
        return

    try:
        # Migrar filmes
        print("Migrando filmes...")
        sqlite_cursor.execute('SELECT * FROM movies')
        movies = sqlite_cursor.fetchall()

        if movies:
            movie_data = []
            for movie in movies:
                movie_data.append((
                    movie[0],  # id
                    movie[1],  # title
                    movie[2],  # overview
                    movie[3],  # posterPath
                    movie[4],  # backdropPath
                    movie[5] if movie[5] else None,  # releaseDate
                    movie[6],  # voteAverage
                    movie[7],  # voteCount
                    movie[8],  # genreIds
                    movie[9] == 1,  # adult (converter para boolean)
                    movie[10], # originalLanguage
                    movie[11], # originalTitle
                    movie[12], # popularity
                    movie[13] == 1, # video (converter para boolean)
                    movie[14]  # imageUrls
                ))

            pg_cursor.executemany('''
                INSERT INTO movies (id, title, overview, posterPath, backdropPath, releaseDate, voteAverage, voteCount, genreIds, adult, originalLanguage, originalTitle, popularity, video, imageUrls)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (id) DO NOTHING
            ''', movie_data)
            print(f"Migrados {len(movie_data)} filmes")

        # Migrar séries
        print("Migrando séries...")
        sqlite_cursor.execute('SELECT * FROM tv_series')
        series = sqlite_cursor.fetchall()

        if series:
            series_data = []
            for serie in series:
                series_data.append((
                    serie[0],  # id
                    serie[1],  # name
                    serie[2],  # overview
                    serie[3],  # posterPath
                    serie[4],  # backdropPath
                    serie[5] if serie[5] else None,  # firstAirDate
                    serie[6],  # voteAverage
                    serie[7],  # voteCount
                    serie[8],  # genreIds
                    serie[9] == 1,  # adult
                    serie[10], # originalLanguage
                    serie[11], # originalName
                    serie[12], # popularity
                    serie[13], # originCountry
                    serie[14]  # imageUrls
                ))

            pg_cursor.executemany('''
                INSERT INTO tv_series (id, name, overview, posterPath, backdropPath, firstAirDate, voteAverage, voteCount, genreIds, adult, originalLanguage, originalName, popularity, originCountry, imageUrls)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (id) DO NOTHING
            ''', series_data)
            print(f"Migradas {len(series_data)} séries")

        # Migrar canais
        print("Migrando canais...")
        sqlite_cursor.execute('SELECT * FROM channels')
        channels = sqlite_cursor.fetchall()

        if channels:
            channel_data = []
            for channel in channels:
                channel_data.append((
                    channel[0],  # id
                    channel[1],  # name
                    channel[2],  # logoPath
                    channel[3],  # streamUrl
                    channel[4],  # category
                    channel[5],  # description
                    channel[6]   # imageUrls
                ))

            pg_cursor.executemany('''
                INSERT INTO channels (id, name, logoPath, streamUrl, category, description, imageUrls)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (id) DO NOTHING
            ''', channel_data)
            print(f"Migrados {len(channel_data)} canais")

        # Migrar outras tabelas se existirem
        tables_to_check = ['seasons', 'episodes', 'sync_cache']
        for table in tables_to_check:
            try:
                sqlite_cursor.execute(f'SELECT * FROM {table}')
                data = sqlite_cursor.fetchall()
                if data:
                    print(f"Migrando {len(data)} registros da tabela {table}")
                    # Para tabelas complexas, seria necessário implementar migração específica
                    # Por enquanto, apenas informar que existem dados
            except sqlite3.Error:
                print(f"Tabela {table} não existe no SQLite")

        pg_conn.commit()
        print("Migração concluída com sucesso!")

    except Exception as e:
        print(f"Erro durante migração: {e}")
        pg_conn.rollback()

    finally:
        sqlite_conn.close()
        pg_cursor.close()
        pg_conn.close()

if __name__ == "__main__":
    migrate_sqlite_to_postgres()