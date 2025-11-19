# Scripts Auxiliares

## Visão Geral

O projeto TV Multimidia inclui scripts auxiliares em Python para facilitar operações de banco de dados e manutenção. Estes scripts complementam a funcionalidade principal da aplicação Flutter.

## Script database.py

### Localização
`tv_multimidia/database.py`

### Finalidade
Script Python para gerenciamento completo do banco de dados SQLite, incluindo:
- Criação de tabelas
- Sincronização inicial de dados
- Carregamento de canais externos
- Operações de manutenção

### Estrutura do Script

#### Classe DatabaseService

```python
class DatabaseService:
    def __init__(self, db_name='dadostv.db'):
        self.db_name = db_name
        self.connection = None
        self.cursor = None

    def connect(self):
        """Conecta ao banco de dados SQLite."""
        self.connection = sqlite3.connect(self.db_name)
        self.cursor = self.connection.cursor()
        print(f"Conectado ao banco de dados: {self.db_name}")

    def create_tables(self):
        """Cria as tabelas do banco de dados."""
        # Implementação das tabelas...
```

#### Tabelas Criadas

##### movies (Filmes)
```sql
CREATE TABLE IF NOT EXISTS movies(
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    overview TEXT,
    posterPath TEXT,
    backdropPath TEXT,
    releaseDate TEXT,
    voteAverage REAL,
    voteCount INTEGER,
    genreIds TEXT,
    adult INTEGER,
    originalLanguage TEXT,
    originalTitle TEXT,
    popularity REAL,
    video INTEGER,
    imageUrls TEXT
)
```

##### tv_series (Séries de TV)
```sql
CREATE TABLE IF NOT EXISTS tv_series(
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    overview TEXT,
    posterPath TEXT,
    backdropPath TEXT,
    firstAirDate TEXT,
    voteAverage REAL,
    voteCount INTEGER,
    genreIds TEXT,
    adult INTEGER,
    originalLanguage TEXT,
    originalName TEXT,
    popularity REAL,
    originCountry TEXT,
    imageUrls TEXT
)
```

##### channels (Canais)
```sql
CREATE TABLE IF NOT EXISTS channels(
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    logoPath TEXT,
    streamUrl TEXT,
    category TEXT,
    description TEXT,
    imageUrls TEXT
)
```

##### seasons (Temporadas)
```sql
CREATE TABLE IF NOT EXISTS seasons(
    id INTEGER PRIMARY KEY,
    seriesId INTEGER NOT NULL,
    seasonNumber INTEGER NOT NULL,
    name TEXT,
    overview TEXT,
    airDate TEXT,
    episodeCount INTEGER,
    posterPath TEXT,
    voteAverage REAL,
    imageUrls TEXT,
    FOREIGN KEY (seriesId) REFERENCES tv_series (id)
)
```

##### episodes (Episódios)
```sql
CREATE TABLE IF NOT EXISTS episodes(
    id INTEGER PRIMARY KEY,
    seriesId INTEGER NOT NULL,
    seasonId INTEGER NOT NULL,
    episodeNumber INTEGER NOT NULL,
    name TEXT,
    overview TEXT,
    airDate TEXT,
    runtime INTEGER,
    stillPath TEXT,
    voteAverage REAL,
    voteCount INTEGER,
    imageUrls TEXT,
    FOREIGN KEY (seriesId) REFERENCES tv_series (id),
    FOREIGN KEY (seasonId) REFERENCES seasons (id)
)
```

##### sync_cache (Cache de Sincronização)
```sql
CREATE TABLE IF NOT EXISTS sync_cache(
    key TEXT PRIMARY KEY,
    timestamp INTEGER,
    data TEXT
)
```

#### Classe TMDBDataSource

```python
class TMDBDataSource:
    def __init__(self):
        self.base_url = 'https://api.themoviedb.org/3'
        self.api_key = 'eyJhbGciOiJIUzI1NiJ9...'  # Mesmo token do Flutter
        self.headers = {
            'Authorization': f'Bearer {self.api_key}',
            'accept': 'application/json',
        }
        self.language = 'pt-BR'
```

#### Métodos da API TMDB

```python
def fetch_popular_movies(self):
    """Busca filmes populares."""
    url = f'{self.base_url}/movie/popular?language={self.language}'
    response = requests.get(url, headers=self.headers)
    if response.status_code == 200:
        data = response.json()
        return data['results']
    else:
        raise Exception(f'Erro ao buscar filmes populares: {response.status_code}')
```

#### Classe SyncService

```python
class SyncService:
    def __init__(self, db_service, tmdb_source):
        self.db = db_service
        self.tmdb = tmdb_source

    def sync_data_if_needed(self):
        """Sincroniza dados se necessário (cache expirado)."""
        # Implementação similar ao Flutter
```

### Como Usar

#### Execução Básica
```bash
cd tv_multimidia
python database.py
```

#### O que o script faz automaticamente:
1. Conecta ao banco de dados
2. Cria todas as tabelas
3. Sincroniza filmes em alta
4. Sincroniza filmes populares
5. Sincroniza séries em alta
6. Sincroniza séries populares
7. Sincroniza gêneros principais
8. Carrega canais do CSV
9. Exibe estatísticas finais

#### Saída Esperada
```
Conectado ao banco de dados: dadostv.db
Tabelas criadas com sucesso.
Sincronizando filmes em alta...
Salvando 20 filmes em alta no banco local
Filmes em alta sincronizados
...
Sincronização concluída com sucesso
20 canais carregados do CSV.
Filmes: 100
Séries: 80
Canais: 20
```

### Funcionalidades Avançadas

#### Carregamento de Canais CSV

```python
def load_channels_from_csv(self, csv_file_path):
    """Carrega canais do arquivo CSV e salva no banco de dados."""
    channels_data = []
    with open(csv_file_path, 'r', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        for row in reader:
            name = row.get('channel', '').strip()
            logo_url = row.get('url', '').strip()
            if name and logo_url:
                channels_data.append((None, name, logo_url, None, None, None, logo_url))
    if channels_data:
        self.save_channels_batch(channels_data)
        print(f"{len(channels_data)} canais carregados do CSV.")
```

## Arquivo logos.csv

### Localização
`tv_multimidia/logos.csv`

### Estrutura
Arquivo CSV contendo informações de canais de TV ao vivo:

```csv
channel,feed,tags,width,height,format,url
"Canal 1","http://example.com/stream1",tv,1920,1080,hls,http://logo1.png
"Canal 2","http://example.com/stream2",tv,1280,720,hls,http://logo2.png
...
```

### Campos

- **channel**: Nome do canal
- **feed**: URL do stream de vídeo
- **tags**: Tags/categorias (ex: tv, news, sports)
- **width**: Largura do vídeo
- **height**: Altura do vídeo
- **format**: Formato do stream (hls, dash, etc.)
- **url**: URL do logo/imagem do canal

### Como o CSV é Processado

```python
# No database.py
for row in reader:
    name = row.get('channel', '').strip()
    logo_url = row.get('url', '').strip()
    if name and logo_url:
        channels_data.append((None, name, logo_url, None, None, None, logo_url))
```

**Mapeamento:**
- `channel` → `name` (tabela channels)
- `url` → `logoPath` (tabela channels)
- `url` → `imageUrls` (tabela channels)

### Manutenção do CSV

#### Adicionando Novos Canais
1. Abrir `logos.csv` em um editor
2. Adicionar nova linha seguindo o formato
3. Executar `python database.py` para recarregar

#### Formato Esperado
- Codificação: UTF-8
- Separador: vírgula (`,`)
- Aspas: Opcionais, mas recomendadas para campos com espaços
- Quebra de linha: LF (Unix) ou CRLF (Windows)

#### Validação
```python
if name and logo_url:
    # Só adiciona se ambos os campos essenciais estiverem presentes
    channels_data.append(...)
```

## Utilitários e Ferramentas

### Dependências Python Necessárias

```bash
pip install requests
```

- **requests**: Para chamadas HTTP à API TMDB
- **sqlite3**: Incluído no Python padrão
- **csv**: Módulo padrão do Python
- **json**: Módulo padrão do Python
- **datetime/time**: Módulos padrão

### Configuração da API Key

```python
self.api_key = 'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJmMTk3M2Q4YzE4YmUxODYyNjI5OWE2ZGNlNmQyYzdjMCIsIm5iZiI6MTc1MDczNTQ0Ni44NjQsInN1YiI6IjY4NWExYTU2MmY1OTMwN2NkMjU3MmVhZCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.WqJC6aM33pww1-c_7N3aplZbE7jVGbP8UEqf_enOS1Y'
```

**Nota**: Esta é a mesma chave usada no aplicativo Flutter.

### Sistema de Cache

```python
def save_cache(self, key, data):
    """Salva dados no cache."""
    timestamp = int(time.time() * 1000)
    self.cursor.execute('''
        INSERT OR REPLACE INTO sync_cache (key, timestamp, data)
        VALUES (?, ?, ?)
    ''', (key, timestamp, json.dumps(data)))
    self.connection.commit()

def get_cache(self, key):
    """Retorna dados do cache se ainda válidos (24h)."""
    one_day_ago = int((datetime.now() - timedelta(days=1)).timestamp() * 1000)
    self.cursor.execute('''
        SELECT data, timestamp FROM sync_cache
        WHERE key = ? AND timestamp > ?
    ''', (key, one_day_ago))
    result = self.cursor.fetchone()
    if result:
        return json.loads(result[0])
    return None
```

## Casos de Uso

### Desenvolvimento
- **Inicialização rápida**: Popular banco com dados de teste
- **Debug**: Verificar estado do banco de dados
- **Migração**: Atualizar estrutura do banco

### Produção
- **Setup inicial**: Preparar ambiente de produção
- **Backup/Restore**: Migrar dados entre ambientes
- **Manutenção**: Limpeza e otimização do banco

### Testes
- **Dados de teste**: Popular com conteúdo conhecido
- **Performance**: Testar operações em lote
- **Integração**: Verificar compatibilidade com Flutter

## Limitações e Considerações

### Limitações do SQLite
- Sem suporte nativo a JSON (usa TEXT)
- Foreign keys opcionais (depende da configuração)
- Sem tipos de data nativos

### Limitações da API TMDB
- Rate limiting (500 requests/dia para contas gratuitas)
- Dados em português podem estar incompletos
- Alguns campos opcionais podem estar vazios

### Limitações do CSV
- Não suporta caracteres especiais complexos
- Validação limitada de URLs
- Sem suporte a metadados avançados

## Troubleshooting

### Problemas Comuns

#### Erro de Conexão à API
```
Exception: Failed to load popular movies: 401
```
**Solução**: Verificar se a API key é válida e não expirou.

#### Arquivo CSV não encontrado
```
FileNotFoundError: logos.csv
```
**Solução**: Verificar se o arquivo existe no diretório correto.

#### Erro de SQLite
```
sqlite3.OperationalError: table movies already exists
```
**Solução**: O script usa `IF NOT EXISTS`, então pode ser ignorado.

#### Encoding do CSV
```
UnicodeDecodeError: 'utf-8' codec can't decode
```
**Solução**: Salvar CSV com encoding UTF-8.

### Logs e Debug

#### Habilitar Debug
```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

#### Verificar Dados
```python
# Consultar tabelas
cursor.execute('SELECT COUNT(*) FROM movies')
print(f"Total de filmes: {cursor.fetchone()[0]}")
```

## Extensões Futuras

### Possíveis Melhorias

#### Interface Web
- Converter script em aplicação web Flask/Django
- Interface gráfica para gerenciamento

#### Automação
- Integração com CI/CD
- Scripts de backup automático
- Monitoramento de saúde do banco

#### Validação
- Validação de dados da API
- Verificação de integridade do banco
- Testes automatizados

#### Performance
- Operações em lote otimizadas
- Índices adicionais
- Compressão de dados

## Segurança

### Proteção da API Key
- **Atual**: Hardcoded (não recomendado)
- **Recomendado**: Variável de ambiente
```bash
export TMDB_API_KEY="your_key_here"
# Usar os.environ.get('TMDB_API_KEY')
```

### Validação de Dados
- Sanitização de inputs do CSV
- Validação de URLs
- Escape de caracteres especiais

## Manutenção

### Atualização Regular
- Manter API key válida
- Atualizar URLs de canais
- Limpar cache periodicamente

### Backup
```python
import shutil
shutil.copy('dadostv.db', f'dadostv_backup_{datetime.now().strftime("%Y%m%d")}.db')
```

### Monitoramento
- Logs de execução
- Contagem de registros
- Verificação de integridade

Esta documentação cobre completamente os scripts auxiliares, permitindo que desenvolvedores entendam e utilizem essas ferramentas efetivamente no projeto TV Multimidia.