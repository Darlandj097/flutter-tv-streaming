import psycopg2
import psycopg2.extras
import os
import requests
import json
import time
import csv
from datetime import datetime, timedelta

class DatabaseService:
    def __init__(self, host='localhost', port=5432, dbname='tv_multimidia', user='tv_user', password='tv_password'):
        self.host = host
        self.port = port
        self.dbname = dbname
        self.user = user
        self.password = password
        self.connection = None
        self.cursor = None

        # Configurar locale para Windows - problema de encoding
        import os
        os.environ['PYTHONIOENCODING'] = 'utf-8'
        os.environ['LC_ALL'] = 'C.UTF-8'
        os.environ['LANG'] = 'C.UTF-8'
        # Forçar ASCII para evitar problemas com caracteres especiais
        os.environ['PYTHONUTF8'] = '0'

    def connect(self):
        """Conecta ao banco de dados PostgreSQL."""
        try:
            # RECOMENDAÇÃO: Usa os valores do __init__, permitindo override por env vars
            host = os.getenv('DB_HOST', self.host)
            port = os.getenv('DB_PORT', self.port)
            dbname = os.getenv('DB_NAME', self.dbname)
            user = os.getenv('DB_USER', self.user)
            password = os.getenv('DB_PASSWORD', self.password)
            
            conn_string = f"host={host} port={port} dbname={dbname} user={user} password={password}"
            self.connection = psycopg2.connect(conn_string)
            self.connection.set_client_encoding('UTF8')
            self.cursor = self.connection.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
            print(f"Conectado ao banco de dados PostgreSQL em {host}:{port}")
        except psycopg2.Error as e:
            print(f"Erro ao conectar ao PostgreSQL: {e}")
            raise

    def create_tables(self):
        """Cria as tabelas do banco de dados."""
        # Tabela de filmes
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS movies(
                id SERIAL PRIMARY KEY,
                title TEXT NOT NULL,
                overview TEXT,
                posterPath TEXT,
                backdropPath TEXT,
                releaseDate DATE,
                voteAverage REAL,
                voteCount INTEGER,
                genreIds TEXT,
                adult BOOLEAN,
                originalLanguage TEXT,
                originalTitle TEXT,
                popularity REAL,
                video BOOLEAN,
                imageUrls TEXT
            )
        ''')

        # Tabela de séries
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS tv_series(
                id SERIAL PRIMARY KEY,
                name TEXT NOT NULL,
                overview TEXT,
                posterPath TEXT,
                backdropPath TEXT,
                firstAirDate DATE,
                voteAverage REAL,
                voteCount INTEGER,
                genreIds TEXT,
                adult BOOLEAN,
                originalLanguage TEXT,
                originalName TEXT,
                popularity REAL,
                originCountry TEXT,
                imageUrls TEXT
            )
        ''')

        # Tabela de canais
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS channels(
                id SERIAL PRIMARY KEY,
                name TEXT NOT NULL,
                logoPath TEXT,
                streamUrl TEXT,
                category TEXT,
                description TEXT,
                imageUrls TEXT
            )
        ''')
        # Adiciona um índice na coluna 'name' para otimizar a atualização pelo CSV
        self.cursor.execute('CREATE INDEX IF NOT EXISTS idx_channels_name ON channels(name);')
        # Adiciona um índice na coluna 'category' para otimizar a busca por categoria
        self.cursor.execute('CREATE INDEX IF NOT EXISTS idx_channels_category ON channels(category);')

        # Tabela de temporadas
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS seasons(
                id SERIAL PRIMARY KEY,
                seriesId INTEGER NOT NULL REFERENCES tv_series(id),
                seasonNumber INTEGER NOT NULL,
                name TEXT,
                overview TEXT,
                airDate DATE,
                episodeCount INTEGER,
                posterPath TEXT,
                voteAverage REAL,
                imageUrls TEXT
            )
        ''')

        # Tabela de episódios
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS episodes(
                id SERIAL PRIMARY KEY,
                seriesId INTEGER NOT NULL REFERENCES tv_series(id),
                seasonId INTEGER NOT NULL REFERENCES seasons(id),
                episodeNumber INTEGER NOT NULL,
                name TEXT,
                overview TEXT,
                airDate DATE,
                runtime INTEGER,
                stillPath TEXT,
                voteAverage REAL,
                voteCount INTEGER,
                imageUrls TEXT
            )
        ''')

        # Tabela para cache de sincronização
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS sync_cache(
                key TEXT PRIMARY KEY,
                timestamp BIGINT,
                data TEXT
            )
        ''')

        # Tabela de usuários
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS users(
                id SERIAL PRIMARY KEY,
                name TEXT NOT NULL,
                email TEXT NOT NULL UNIQUE,
                password TEXT NOT NULL,
                installation_id TEXT,
                android_id TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')

        self.connection.commit()
        print("Tabelas criadas com sucesso.")

    def save_movies_batch(self, movies):
        """Salva múltiplos filmes no banco de dados."""
        query = '''
            INSERT INTO movies (id, title, overview, posterPath, backdropPath, releaseDate, voteAverage, voteCount, genreIds, adult, originalLanguage, originalTitle, popularity, video, imageUrls)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (id) DO UPDATE SET
                title = EXCLUDED.title,
                overview = EXCLUDED.overview,
                posterPath = EXCLUDED.posterPath,
                backdropPath = EXCLUDED.backdropPath,
                releaseDate = EXCLUDED.releaseDate,
                voteAverage = EXCLUDED.voteAverage,
                voteCount = EXCLUDED.voteCount,
                genreIds = EXCLUDED.genreIds,
                adult = EXCLUDED.adult,
                originalLanguage = EXCLUDED.originalLanguage,
                originalTitle = EXCLUDED.originalTitle,
                popularity = EXCLUDED.popularity,
                video = EXCLUDED.video,
                imageUrls = EXCLUDED.imageUrls
        '''
        psycopg2.extras.execute_batch(self.cursor, query, movies)
        self.connection.commit()
        print(f"{len(movies)} filmes salvos com sucesso.")

    def save_tv_series_batch(self, series):
        """Salva múltiplas séries no banco de dados."""
        query = '''
            INSERT INTO tv_series (id, name, overview, posterPath, backdropPath, firstAirDate, voteAverage, voteCount, genreIds, adult, originalLanguage, originalName, popularity, originCountry, imageUrls)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (id) DO UPDATE SET
                name = EXCLUDED.name,
                overview = EXCLUDED.overview,
                posterPath = EXCLUDED.posterPath,
                backdropPath = EXCLUDED.backdropPath,
                firstAirDate = EXCLUDED.firstAirDate,
                voteAverage = EXCLUDED.voteAverage,
                voteCount = EXCLUDED.voteCount,
                genreIds = EXCLUDED.genreIds,
                adult = EXCLUDED.adult,
                originalLanguage = EXCLUDED.originalLanguage,
                originalName = EXCLUDED.originalName,
                popularity = EXCLUDED.popularity,
                originCountry = EXCLUDED.originCountry,
                imageUrls = EXCLUDED.imageUrls
        '''
        psycopg2.extras.execute_batch(self.cursor, query, series)
        self.connection.commit()
        print(f"{len(series)} séries salvas com sucesso.")

    def save_channels_batch(self, channels):
        """Salva múltiplos canais no banco de dados."""
        query = '''
            INSERT INTO channels (id, name, logoPath, streamUrl, category, description, imageUrls)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (id) DO UPDATE SET
                name = EXCLUDED.name,
                logoPath = EXCLUDED.logoPath,
                streamUrl = EXCLUDED.streamUrl,
                category = EXCLUDED.category,
                description = EXCLUDED.description,
                imageUrls = EXCLUDED.imageUrls
        '''
        psycopg2.extras.execute_batch(self.cursor, query, channels)
        self.connection.commit()
        print(f"{len(channels)} canais salvos com sucesso.")

    def save_seasons_batch(self, seasons):
        """Salva múltiplas temporadas no banco de dados."""
        query = '''
            INSERT INTO seasons (id, seriesId, seasonNumber, name, overview, airDate, episodeCount, posterPath, voteAverage, imageUrls)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (id) DO UPDATE SET
                seriesId = EXCLUDED.seriesId,
                seasonNumber = EXCLUDED.seasonNumber,
                name = EXCLUDED.name,
                overview = EXCLUDED.overview,
                airDate = EXCLUDED.airDate,
                episodeCount = EXCLUDED.episodeCount,
                posterPath = EXCLUDED.posterPath,
                voteAverage = EXCLUDED.voteAverage,
                imageUrls = EXCLUDED.imageUrls
        '''
        psycopg2.extras.execute_batch(self.cursor, query, seasons)
        self.connection.commit()
        print(f"{len(seasons)} temporadas salvas com sucesso.")

    def save_episodes_batch(self, episodes):
        """Salva múltiplos episódios no banco de dados."""
        query = '''
            INSERT INTO episodes (id, seriesId, seasonId, episodeNumber, name, overview, airDate, runtime, stillPath, voteAverage, voteCount, imageUrls)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (id) DO UPDATE SET
                seriesId = EXCLUDED.seriesId,
                seasonId = EXCLUDED.seasonId,
                episodeNumber = EXCLUDED.episodeNumber,
                name = EXCLUDED.name,
                overview = EXCLUDED.overview,
                airDate = EXCLUDED.airDate,
                runtime = EXCLUDED.runtime,
                stillPath = EXCLUDED.stillPath,
                voteAverage = EXCLUDED.voteAverage,
                voteCount = EXCLUDED.voteCount,
                imageUrls = EXCLUDED.imageUrls
        '''
        psycopg2.extras.execute_batch(self.cursor, query, episodes)
        self.connection.commit()
        print(f"{len(episodes)} episódios salvos com sucesso.")

    def get_all_movies(self):
        """(Ineficiente) Retorna TODOS os filmes. Use com cuidado."""
        self.cursor.execute('SELECT * FROM movies')
        return [dict(row) for row in self.cursor.fetchall()]

    def get_all_tv_series(self):
        """(Ineficiente) Retorna TODAS as séries. Use com cuidado."""
        self.cursor.execute('SELECT * FROM tv_series')
        return [dict(row) for row in self.cursor.fetchall()]

    def get_all_channels(self):
        """(Ineficiente) Retorna TODOS os canais. Use com cuidado."""
        self.cursor.execute('SELECT * FROM channels')
        return [dict(row) for row in self.cursor.fetchall()]
    
    ## --- NOVAS FUNÇÕES EFICIENTES ---
    # Estas funções são chamadas pelo app.py atualizado para 
    # garantir que o banco de dados (PostgreSQL) faça o trabalho
    # de filtrar e ordenar, o que é muito mais rápido.

    def get_trending_movies(self, limit=20):
        """(Eficiente) Retorna filmes em alta, ordenados por popularidade."""
        query = "SELECT * FROM movies ORDER BY popularity DESC LIMIT %s"
        self.cursor.execute(query, (limit,))
        return [dict(row) for row in self.cursor.fetchall()]

    def get_popular_movies(self, limit=20):
        """(Eficiente) Retorna filmes populares, ordenados por popularidade."""
        # Nota: Usando a mesma lógica de 'trending' por popularidade.
        # Ajuste o 'ORDER BY' se tiver um critério diferente.
        query = "SELECT * FROM movies ORDER BY popularity DESC LIMIT %s"
        self.cursor.execute(query, (limit,))
        return [dict(row) for row in self.cursor.fetchall()]

    def get_trending_series(self, limit=20):
        """(Eficiente) Retorna séries em alta, ordenadas por popularidade."""
        query = "SELECT * FROM tv_series ORDER BY popularity DESC LIMIT %s"
        self.cursor.execute(query, (limit,))
        return [dict(row) for row in self.cursor.fetchall()]

    def get_popular_series(self, limit=20):
        """(Eficiente) Retorna séries populares, ordenadas por popularidade."""
        query = "SELECT * FROM tv_series ORDER BY popularity DESC LIMIT %s"
        self.cursor.execute(query, (limit,))
        return [dict(row) for row in self.cursor.fetchall()]

    def get_distinct_categories(self):
        """(Eficiente) Retorna uma lista de categorias de canais únicas."""
        query = "SELECT DISTINCT category FROM channels WHERE category IS NOT NULL AND category != '' ORDER BY category"
        self.cursor.execute(query)
        # Converte lista de dicts [{'category': 'A'}, {'category': 'B'}] para lista de strings ['A', 'B']
        categories = [row['category'] for row in self.cursor.fetchall()]
        return categories

    def get_channels_by_category(self, category):
        """(Eficiente) Retorna canais por uma categoria específica."""
        query = "SELECT * FROM channels WHERE category = %s ORDER BY name"
        self.cursor.execute(query, (category,))
        return [dict(row) for row in self.cursor.fetchall()]

    ## --- FIM DAS NOVAS FUNÇÕES ---

    def load_channels_from_csv(self, csv_file_path):
        """
        RECOMENDAÇÃO: Atualiza logotipos de canais EXISTENTES a partir de um CSV.
        Isso assume que os canais já estão no banco (ex: de um M3U) e o CSV
        é usado apenas para adicionar/corrigir os logotipos.
        """
        updates = []
        try:
            with open(csv_file_path, 'r', encoding='utf-8') as file:
                reader = csv.DictReader(file)
                for row in reader:
                    name = row.get('channel', '').strip()
                    logo_url = row.get('url', '').strip()
                    if name and logo_url:
                        # Prepara tupla para (logoPath, imageUrls, name)
                        updates.append((logo_url, logo_url, name))
        except FileNotFoundError:
            print(f"Arquivo CSV '{csv_file_path}' não encontrado.")
            return
        except Exception as e:
            print(f"Erro ao ler CSV: {e}")
            return

        if updates:
            query = """
                UPDATE channels SET 
                    logoPath = %s, 
                    imageUrls = %s 
                WHERE name = %s
            """
            # psycopg2.extras.execute_batch é mais eficiente para updates em massa
            psycopg2.extras.execute_batch(self.cursor, query, updates)
            self.connection.commit()
            print(f"{self.cursor.rowcount} canais atualizados com logotipos do CSV.")
        else:
            print("Nenhum dado válido de logotipo encontrado no CSV.")

    def save_cache(self, key, data):
        """Salva dados no cache."""
        timestamp = int(time.time() * 1000)
        self.cursor.execute('''
            INSERT INTO sync_cache (key, timestamp, data)
            VALUES (%s, %s, %s)
            ON CONFLICT (key) DO UPDATE SET
                timestamp = EXCLUDED.timestamp,
                data = EXCLUDED.data
        ''', (key, timestamp, json.dumps(data)))
        self.connection.commit()

    def get_cache(self, key):
        """Retorna dados do cache se ainda válidos (24h)."""
        one_day_ago = int((datetime.now() - timedelta(days=1)).timestamp() * 1000)
        self.cursor.execute('''
            SELECT data, timestamp FROM sync_cache
            WHERE key = %s AND timestamp > %s
        ''', (key, one_day_ago))
        result = self.cursor.fetchone()
        if result:
            return json.loads(result['data'])
        return None

    def create_user(self, name, email, password_hash, installation_id=None, android_id=None):
        """Cria um novo usuário."""
        self.cursor.execute('''
            INSERT INTO users (name, email, password, installation_id, android_id)
            VALUES (%s, %s, %s, %s, %s)
            RETURNING id
        ''', (name, email, password_hash, installation_id, android_id))
        # fetchone() retornará um dict como {'id': 1} por causa do RealDictCursor
        user_id = self.cursor.fetchone()['id']
        self.connection.commit()
        print(f"Usuário criado: {user_id}")
        return user_id

    def get_user_by_email(self, email):
        """Busca usuário por email."""
        self.cursor.execute('SELECT * FROM users WHERE email = %s', (email,))
        result = self.cursor.fetchone()
        return dict(result) if result else None

    def get_user_by_id(self, user_id):
        """Busca usuário por ID."""
        self.cursor.execute('SELECT * FROM users WHERE id = %s', (user_id,))
        result = self.cursor.fetchone()
        return dict(result) if result else None

    def close(self):
        """Fecha a conexão com o banco de dados."""
        if self.cursor:
            self.cursor.close()
        if self.connection:
            self.connection.close()
            print("Conexão com o banco de dados fechada.")

class TMDBDataSource:
    def __init__(self):
        self.base_url = 'https://api.themoviedb.org/3'
        # RECOMENDAÇÃO: Mova esta chave para uma variável de ambiente (os.environ.get('TMDB_API_KEY'))
        self.api_key = 'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJmMTk3M2Q4YzE4YmUxODYyNjI5OWE2ZGNlNmQyYzdjMCIsIm5iZiI6MTc1MDczNTQ0Ni44NjQsInN1YiI6IjY4NWExYTU2MmY1OTMwN2NkMjU3MmVhZCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.WqJC6aM33pww1-c_7N3aplZbE7jVGbP8UEqf_enOS1Y'
        self.headers = {
            'Authorization': f'Bearer {self.api_key}',
            'accept': 'application/json',
        }
        self.language = 'pt-BR'  # Idioma português brasileiro

    def fetch_popular_movies(self):
        """Busca filmes populares."""
        url = f'{self.base_url}/movie/popular?language={self.language}'
        response = requests.get(url, headers=self.headers)
        if response.status_code == 200:
            data = response.json()
            return data['results']
        else:
            raise Exception(f'Erro ao buscar filmes populares: {response.status_code}')

    def fetch_trending_movies(self):
        """Busca filmes em alta."""
        url = f'{self.base_url}/trending/movie/day?language={self.language}'
        response = requests.get(url, headers=self.headers)
        if response.status_code == 200:
            data = response.json()
            return data['results']
        else:
            raise Exception(f'Erro ao buscar filmes em alta: {response.status_code}')

    def fetch_popular_tv_series(self):
        """Busca séries populares."""
        url = f'{self.base_url}/tv/popular?language={self.language}'
        response = requests.get(url, headers=self.headers)
        if response.status_code == 200:
            data = response.json()
            return data['results']
        else:
            raise Exception(f'Erro ao buscar séries populares: {response.status_code}')

    def fetch_trending_tv_series(self):
        """Busca séries em alta."""
        url = f'{self.base_url}/trending/tv/day?language={self.language}'
        response = requests.get(url, headers=self.headers)
        if response.status_code == 200:
            data = response.json()
            return data['results']
        else:
            raise Exception(f'Erro ao buscar séries em alta: {response.status_code}')

    def fetch_movies_by_genre(self, genre_id):
        """Busca filmes por gênero."""
        url = f'{self.base_url}/discover/movie?with_genres={genre_id}&language={self.language}'
        response = requests.get(url, headers=self.headers)
        if response.status_code == 200:
            data = response.json()
            return data['results']
        else:
            raise Exception(f'Erro ao buscar filmes por gênero: {response.status_code}')

    def fetch_tv_series_by_genre(self, genre_id):
        """Busca séries por gênero."""
        url = f'{self.base_url}/discover/tv?with_genres={genre_id}&language={self.language}'
        response = requests.get(url, headers=self.headers)
        if response.status_code == 200:
            data = response.json()
            return data['results']
        else:
            raise Exception(f'Erro ao buscar séries por gênero: {response.status_code}')

    def fetch_tv_series_details(self, series_id):
        """Busca detalhes de uma série."""
        url = f'{self.base_url}/tv/{series_id}?language={self.language}'
        response = requests.get(url, headers=self.headers)
        if response.status_code == 200:
            return response.json()
        else:
            raise Exception(f'Erro ao buscar detalhes da série: {response.status_code}')

    def fetch_season_details(self, series_id, season_number):
        """Busca detalhes de uma temporada."""
        url = f'{self.base_url}/tv/{series_id}/season/{season_number}?language={self.language}'
        response = requests.get(url, headers=self.headers)
        if response.status_code == 200:
            return response.json()
        else:
            raise Exception(f'Erro ao buscar detalhes da temporada: {response.status_code}')

class SyncService:
    def __init__(self, db_service, tmdb_source):
        self.db = db_service
        self.tmdb = tmdb_source

    def sync_data_if_needed(self):
        """Sincroniza dados se necessário (cache expirado)."""
        last_sync = self.db.get_cache('last_sync')
        now = int(time.time() * 1000)
        one_day_in_millis = 24 * 60 * 60 * 1000

        if not last_sync or (now - last_sync) > one_day_in_millis:
            self._perform_sync()
            self.db.save_cache('last_sync', now)
        else:
            print("Dados já sincronizados recentemente.")

    def force_sync(self):
        """Força sincronização."""
        self._perform_sync()
        now = int(time.time() * 1000)
        self.db.save_cache('last_sync', now)

    def _perform_sync(self):
        """Executa a sincronização."""
        try:
            print('Iniciando sincronização de dados...')

            # Sincronizar filmes
            print('Sincronizando filmes em alta...')
            trending_movies = self.tmdb.fetch_trending_movies()
            self._save_movies(trending_movies)
            print('Filmes em alta sincronizados')

            print('Sincronizando filmes populares...')
            popular_movies = self.tmdb.fetch_popular_movies()
            self._save_movies(popular_movies)
            print('Filmes populares sincronizados')

            # Sincronizar séries
            print('Sincronizando séries em alta...')
            trending_series = self.tmdb.fetch_trending_tv_series()
            self._save_tv_series(trending_series)
            print('Séries em alta sincronizadas')

            print('Sincronizando séries populares...')
            popular_series = self.tmdb.fetch_popular_tv_series()
            self._save_tv_series(popular_series)
            print('Séries populares sincronizadas')

            # Sincronizar gêneros principais
            print('Sincronizando filmes por gênero...')
            self._sync_genres()

            # Sincronizar detalhes das séries (temporadas e episódios)
            print('Sincronizando detalhes das séries...')
            self.sync_series_details()

            print('Sincronização concluída com sucesso')
        except Exception as e:
            print(f'Erro durante sincronização: {e}')
            raise

    def _sync_genres(self):
        """Sincroniza gêneros principais."""
        main_genres = [28, 12, 16, 35, 80, 99, 18, 10751, 14, 36, 27, 10402, 9648, 10749, 878, 10770, 53, 10752, 37]
        for genre_id in main_genres:
            try:
                movies = self.tmdb.fetch_movies_by_genre(genre_id)
                self._save_movies(movies)
                series = self.tmdb.fetch_tv_series_by_genre(genre_id)
                self._save_tv_series(series)
            except Exception as e:
                print(f'Erro ao sincronizar gênero {genre_id}: {e}')

    def sync_series_details(self, series_ids=None):
        """Sincroniza detalhes de séries, incluindo temporadas e episódios."""
        if series_ids is None:
            # Busca IDs das séries já salvas
            self.db.cursor.execute('SELECT id FROM tv_series')
            series_ids = [row['id'] for row in self.db.cursor.fetchall()] # Ajustado para RealDictCursor

        for series_id in series_ids[:5]:  # Limita a 5 séries para não sobrecarregar
            try:
                print(f'Sincronizando detalhes da série {series_id}...')
                series_details = self.tmdb.fetch_tv_series_details(series_id)
                seasons = series_details.get('seasons', [])

                for season in seasons:
                    if season['season_number'] > 0:  # Ignora temporada 0 (especiais)
                        season_details = self.tmdb.fetch_season_details(series_id, season['season_number'])
                        self._save_season(season_details, series_id)
                        self._save_episodes(season_details, series_id)

                print(f'Detalhes da série {series_id} sincronizados')
            except Exception as e:
                print(f'Erro ao sincronizar série {series_id}: {e}')

    def _save_movies(self, movies):
        """Salva filmes no banco."""
        movie_data = []
        base_image_url = 'https://image.tmdb.org/t/p/w500'
        for movie in movies:
            image_urls = []
            if movie.get('poster_path'):
                image_urls.append(f"{base_image_url}{movie['poster_path']}")
            if movie.get('backdrop_path'):
                image_urls.append(f"{base_image_url}{movie['backdrop_path']}")
            
            # Garante que release_date é nulo se for string vazia
            release_date = movie.get('release_date', '')
            if not release_date:
                release_date = None

            movie_data.append((
                movie['id'],
                movie.get('title', ''),
                movie.get('overview', ''),
                movie.get('poster_path', ''),
                movie.get('backdrop_path', ''),
                release_date,
                movie.get('vote_average', 0.0),
                movie.get('vote_count', 0),
                ','.join(map(str, movie.get('genre_ids', []))),
                bool(movie.get('adult', False)),
                movie.get('original_language', ''),
                movie.get('original_title', ''),
                movie.get('popularity', 0.0),
                bool(movie.get('video', False)),
                ','.join(image_urls)
            ))
        if movie_data:
            self.db.save_movies_batch(movie_data)

    def _save_tv_series(self, series):
        """Salva séries no banco."""
        series_data = []
        base_image_url = 'https://image.tmdb.org/t/p/w500'
        for serie in series:
            image_urls = []
            if serie.get('poster_path'):
                image_urls.append(f"{base_image_url}{serie['poster_path']}")
            if serie.get('backdrop_path'):
                image_urls.append(f"{base_image_url}{serie['backdrop_path']}")
            
            first_air_date = serie.get('first_air_date', '')
            if not first_air_date:
                first_air_date = None

            series_data.append((
                serie['id'],
                serie.get('name', ''),
                serie.get('overview', ''),
                serie.get('poster_path', ''),
                serie.get('backdrop_path', ''),
                first_air_date,
                serie.get('vote_average', 0.0),
                serie.get('vote_count', 0),
                ','.join(map(str, serie.get('genre_ids', []))),
                bool(serie.get('adult', False)),
                serie.get('original_language', ''),
                serie.get('original_name', ''),
                serie.get('popularity', 0.0),
                ','.join(serie.get('origin_country', [])),
                ','.join(image_urls)
            ))
        if series_data:
            self.db.save_tv_series_batch(series_data)

    def _save_season(self, season_details, series_id):
        """Salva temporada no banco."""
        base_image_url = 'https://image.tmdb.org/t/p/w500'
        image_urls = []
        if season_details.get('poster_path'):
            image_urls.append(f"{base_image_url}{season_details['poster_path']}")
        
        air_date = season_details.get('air_date', '')
        if not air_date:
            air_date = None

        season_data = [(
            season_details['id'],
            series_id,
            season_details.get('season_number', 0),
            season_details.get('name', ''),
            season_details.get('overview', ''),
            air_date,
            season_details.get('episode_count', 0),
            season_details.get('poster_path', ''),
            season_details.get('vote_average', 0.0),
            ','.join(image_urls)
        )]
        self.db.save_seasons_batch(season_data)

    def _save_episodes(self, season_details, series_id):
        """Salva episódios no banco."""
        episodes = season_details.get('episodes', [])
        episode_data = []
        season_id = season_details['id']
        base_image_url = 'https://image.tmdb.org/t/p/w500'

        for episode in episodes:
            image_urls = []
            if episode.get('still_path'):
                image_urls.append(f"{base_image_url}{episode['still_path']}")
            
            air_date = episode.get('air_date', '')
            if not air_date:
                air_date = None
            
            episode_data.append((
                episode['id'],
                series_id,
                season_id,
                episode.get('episode_number', 0),
                episode.get('name', ''),
                episode.get('overview', ''),
                air_date,
                episode.get('runtime', 0),
                episode.get('still_path', ''),
                episode.get('vote_average', 0.0),
                episode.get('vote_count', 0),
                ','.join(image_urls)
            ))

        if episode_data:
            self.db.save_episodes_batch(episode_data)

# Exemplo de uso
if __name__ == "__main__":
    # Conectar ao banco local (ou Docker se 'localhost' resolver para o container)
    db = DatabaseService(host='localhost', port=5432, dbname='tv_multimidia', user='tv_user', password='tv_password')
    db.connect()
    db.create_tables()

    tmdb = TMDBDataSource()
    sync = SyncService(db, tmdb)

    # Sincronizar dados do TMDB
    sync.force_sync()

    # Carregar/Atualizar logotipos dos canais do CSV
    csv_file_path = 'logos.csv'
    db.load_channels_from_csv(csv_file_path)

    # Consultas de exemplo (agora usando as funções eficientes)
    print("Filmes em Alta:", len(db.get_trending_movies()))
    print("Séries Populares:", len(db.get_popular_series()))
    print("Categorias de Canais:", db.get_distinct_categories())
    print("Canais 'Filmes':", len(db.get_channels_by_category('Filmes'))) # Exemplo

    db.close()