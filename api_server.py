import os
import json
import bcrypt
import jwt
from datetime import datetime, timedelta
from flask import Flask, jsonify, request
from flask_cors import CORS
from tv_multimidia.database import DatabaseService, TMDBDataSource, SyncService

app = Flask(__name__)
CORS(app)  # Permite requisições do Flutter

# --- Configuração de Segurança ---
# A chave secreta NUNCA deve ser deixada no código.
# Use uma variável de ambiente.
app.config['SECRET_KEY'] = os.environ.get('JWT_SECRET_KEY', 'tv_multimidia_super_secret_key_fallback')
if app.config['SECRET_KEY'] == 'tv_multimidia_super_secret_key_fallback':
    print("AVISO: Usando chave secreta de fallback. Defina a variável de ambiente JWT_SECRET_KEY em produção.")

# Inicializar serviços
db = DatabaseService()
tmdb = TMDBDataSource()
sync_service = SyncService(db, tmdb)

@app.route('/api/health', methods=['GET'])
def health_check():
    """Verifica se a API está funcionando"""
    return jsonify({"status": "OK", "timestamp": datetime.now().isoformat()})

# --- Rotas de Filmes ---

@app.route('/api/movies', methods=['GET'])
def get_movies():
    """Retorna todos os filmes (Use paginação em produção)"""
    try:
        # AVISO: Retornar TODOS os filmes é ineficiente.
        # Considere paginação (ex: ?page=1&limit=20)
        movies = db.get_all_movies()
        return jsonify(movies)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/movies/trending', methods=['GET'])
def get_trending_movies():
    """RECOMENDAÇÃO: Retorna filmes em alta diretamente do DB"""
    try:
        # Eficiente: Pede ao DB apenas os 20 filmes em alta.
        # Você precisará criar esta função em database.py
        movies = db.get_trending_movies(limit=20)
        return jsonify(movies)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/movies/popular', methods=['GET'])
def get_popular_movies():
    """RECOMENDAÇÃO: Retorna filmes populares diretamente do DB"""
    try:
        # Eficiente: Pede ao DB apenas os 20 filmes populares.
        # Você precisará criar esta função em database.py
        movies = db.get_popular_movies(limit=20)
        return jsonify(movies)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# --- Rotas de Séries ---

@app.route('/api/series', methods=['GET'])
def get_series():
    """Retorna todas as séries (Use paginação em produção)"""
    try:
        # AVISO: Ineficiente. Considere paginação.
        series = db.get_all_tv_series()
        return jsonify(series)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/series/trending', methods=['GET'])
def get_trending_series():
    """RECOMENDAÇÃO: Retorna séries em alta diretamente do DB"""
    try:
        # Eficiente: Pede ao DB apenas as 20 séries em alta.
        # Você precisará criar esta função em database.py
        series = db.get_trending_series(limit=20)
        return jsonify(series)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/series/popular', methods=['GET'])
def get_popular_series():
    """RECOMENDAÇÃO: Retorna séries populares diretamente do DB"""
    try:
        # Eficiente: Pede ao DB apenas as 20 séries populares.
        # Você precisará criar esta função em database.py
        series = db.get_popular_series(limit=20)
        return jsonify(series)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# --- Rotas de Canais ---

@app.route('/api/channels', methods=['GET'])
def get_channels():
    """Retorna todos os canais"""
    try:
        # AVISO: Esta rota é a causa da lentidão na aba TV.
        # O app Flutter deve buscar canais por categoria.
        channels = db.get_all_channels()
        return jsonify(channels)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/channels/categories', methods=['GET'])
def get_channel_categories():
    """RECOMENDAÇÃO: Retorna todas as categorias distintas do DB"""
    try:
        # Eficiente: Pede ao DB apenas a lista de categorias únicas.
        # Você precisará criar esta função em database.py (ex: SELECT DISTINCT category FROM channels)
        categories = db.get_distinct_categories()
        return jsonify(categories)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/channels/category/<string:category>', methods=['GET'])
def get_channels_by_category(category):
    """RECOMENDAÇÃO: Retorna canais por categoria diretamente do DB"""
    try:
        # Eficiente: Pede ao DB apenas os canais daquela categoria.
        # Você precisará criar esta função em database.py (ex: SELECT * FROM channels WHERE category = ?)
        filtered_channels = db.get_channels_by_category(category)
        return jsonify(filtered_channels)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# --- Rotas de Sincronização ---

@app.route('/api/sync', methods=['POST'])
def sync_data():
    """Sincroniza dados com TMDB"""
    try:
        sync_service.force_sync()
        return jsonify({"message": "Sincronização concluída com sucesso"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# --- Rotas de Usuário (Segurança Aplicada) ---

@app.route('/api/users/login', methods=['POST'])
def login_user():
    """Login de usuário com Bcrypt"""
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')

        if not email or not password:
            return jsonify({"error": "Email e senha são obrigatórios"}), 400

        user = db.get_user_by_email(email)

        # RECOMENDAÇÃO DE SEGURANÇA (Bcrypt):
        # Verifica se o usuário existe E se a senha bate com o hash no banco.
        if not user or not bcrypt.checkpw(password.encode('utf-8'), user['password'].encode('utf-8')):
            return jsonify({"error": "Email ou senha incorreta"}), 401

        # Gerar token JWT
        token = jwt.encode({
            'user_id': user['id'],
            'email': user['email'],
            'exp': datetime.utcnow() + timedelta(days=7)
        }, app.config['SECRET_KEY'], algorithm='HS256')

        user_data = {
            "id": user['id'],
            "name": user['name'],
            "email": user['email'],
            "installation_id": user.get('installation_id'),
            "android_id": user.get('android_id')
        }
        print(f"Login realizado para: {user_data}")

        return jsonify({
            "user": user_data,
            "token": token
        })
    except Exception as e:
        print(f"Erro no login: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/users/register', methods=['POST'])
def register_user():
    """Registro de usuário com Bcrypt e JSON simplificado"""
    try:
        # RECOMENDAÇÃO: Simplifica o parse de JSON.
        # Garanta que o Flutter envia 'Content-Type: application/json'
        if not request.is_json:
            return jsonify({"error": "Content-Type header must be application/json"}), 415
        
        try:
            data = request.get_json()
        except Exception as e:
            print(f"Erro no parse JSON: {e}")
            return jsonify({"error": f"JSON inválido: {str(e)}"}), 400

        if not data or not isinstance(data, dict):
            return jsonify({"error": "Dados JSON inválidos ou vazios"}), 400
        
        name = data.get('name')
        email = data.get('email')
        password = data.get('password')
        installation_id = data.get('installationId')
        android_id = data.get('androidId')

        if not name or not email or not password:
            return jsonify({"error": "Nome, email e senha são obrigatórios"}), 400

        if db.get_user_by_email(email):
            return jsonify({"error": "Email já cadastrado"}), 400

        # RECOMENDAÇÃO DE SEGURANÇA (Bcrypt):
        # Gera um hash seguro (com "salt") para a senha.
        password_hash_bytes = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
        password_hash = password_hash_bytes.decode('utf-8') # Salva como string

        user_id = db.create_user(name, email, password_hash, installation_id, android_id)

        user_data = {
            "id": user_id,
            "name": name,
            "email": email,
            "installation_id": installation_id,
            "android_id": android_id
        }
        print(f"Usuário registrado com sucesso: {user_data}")

        return jsonify({
            "user": user_data,
            "message": "Usuário registrado com sucesso"
        }), 201

    except Exception as e:
        print(f"Erro no registro: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

# --- Rotas Mock (Listas de Usuário) ---
# AVISO: Estas rotas ainda são ineficientes e não são seguras.
# Elas devem ser protegidas por JWT e usar queries eficientes.

@app.route('/api/user/lists/movies', methods=['GET'])
def get_user_movie_list():
    """Retorna lista de filmes do usuário (MOCK)"""
    try:
        movies = db.get_all_movies()
        return jsonify(movies[:10])
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/user/lists/series', methods=['GET'])
def get_user_series_list():
    """Retorna lista de séries do usuário (MOCK)"""
    try:
        series = db.get_all_tv_series()
        return jsonify(series[:10])
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/user/favorites/movies', methods=['GET'])
def get_user_favorite_movies():
    """Retorna filmes favoritos do usuário (MOCK)"""
    try:
        movies = db.get_all_movies()
        return jsonify(movies[:5])
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/user/favorites/series', methods=['GET'])
def get_user_favorite_series():
    """Retorna séries favoritas do usuário (MOCK)"""
    try:
        series = db.get_all_tv_series()
        return jsonify(series[:5])
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # Conectar ao banco
    db.connect()
    db.create_tables()

    # Iniciar servidor
    print("Iniciando API REST na porta 5000...")
    app.run(host='0.0.0.0', port=5000, debug=True)