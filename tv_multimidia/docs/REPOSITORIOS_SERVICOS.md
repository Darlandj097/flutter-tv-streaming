# Repositórios e Serviços

## Visão Geral

Os repositórios e serviços do TV Multimidia implementam o padrão Repository para abstrair o acesso a dados e centralizar a lógica de negócio. Esta camada é responsável pela comunicação entre a interface do usuário e as fontes de dados (local e remota).

## Arquitetura dos Repositórios

### Padrão Repository

Os repositórios seguem o padrão Repository, que:
- Abstrai a complexidade do acesso a dados
- Permite troca de implementações (local/remoto)
- Centraliza lógica de cache e sincronização
- Fornece interface consistente para a UI

### Estrutura Base

```dart
class MovieRepository {
  final LocalDataSource? _localDataSource;
  final TmdbDataSource _remoteDataSource;

  MovieRepository(this._localDataSource, this._remoteDataSource);

  // Métodos de leitura (UI)
  Future<List<Movie>> getTrendingMovies() async { ... }

  // Métodos de sincronização (background)
  Future<void> syncTrendingMovies() async { ... }
}
```

## Repositórios Principais

### 1. MovieRepository

**Arquivo**: `lib/src/data/repositories/movie_repository.dart`

**Responsabilidades:**
- Gerenciar acesso a dados de filmes
- Abstrair fonte de dados (local/remoto)
- Coordenar sincronização de filmes

**Métodos de Leitura (UI):**
```dart
Future<List<Movie>> getTrendingMovies()
Future<List<Movie>> getPopularMovies()
Future<List<Movie>> getMoviesByGenre(int genreId)
```

**Métodos de Sincronização:**
```dart
Future<void> syncTrendingMovies()
Future<void> syncPopularMovies()
Future<void> syncMoviesByGenre(int genreId)
```

**Lógica de Decisão:**
- Se `_localDataSource` for `null` (web): busca dados remotos
- Se `_localDataSource` existir (desktop/mobile): busca dados locais
- Sincronização sempre salva no local (se disponível)

### 2. TVSeriesRepository

**Arquivo**: `lib/src/data/repositories/tv_series_repository.dart`

**Estrutura Similar ao MovieRepository:**
- `getTrendingTVSeries()`
- `getPopularTVSeries()`
- `getTVSeriesByGenre(int genreId)`
- Métodos de sincronização correspondentes

**Diferenças:**
- Campo `name` ao invés de `title`
- Campo `firstAirDate` ao invés de `releaseDate`
- Campo adicional `originCountry`

### 3. ChannelRepository

**Arquivo**: `lib/src/data/repositories/channel_repository.dart`

**Características Específicas:**
- Apenas dados locais (não há API para canais)
- Canais carregados do CSV `logos.csv`
- Funcionalidade limitada comparada aos outros repositórios

**Métodos:**
```dart
Future<List<Channel>> getAllChannels()
Future<void> saveChannels(List<Channel> channels)
```

## Serviços

### 1. SyncService

**Arquivo**: `lib/src/services/sync_service.dart`

**Responsabilidades:**
- Coordenar sincronização de todos os dados
- Gerenciar frequência de sincronização
- Controlar cache de sincronização

**Métodos Principais:**
```dart
Future<void> syncDataIfNeeded()  // Sincroniza se necessário (24h)
Future<void> forceSync()         // Força sincronização imediata
```

**Lógica de Sincronização:**
1. Verifica timestamp da última sincronização
2. Se passou 24 horas, executa `_performSync()`
3. Salva novo timestamp

**Fluxo de Sincronização:**
```
syncDataIfNeeded()
├── Verificar SharedPreferences
├── Se necessário:
│   ├── _performSync()
│   │   ├── Filmes em alta
│   │   ├── Filmes populares
│   │   ├── Séries em alta
│   │   ├── Séries populares
│   │   └── Gêneros principais
│   └── Atualizar timestamp
```

**Gêneros Sincronizados:**
```dart
const mainGenres = [
  28,  // Ação
  12,  // Aventura
  16,  // Animação
  35,  // Comédia
  80,  // Crime
  99,  // Documentário
  18,  // Drama
  10751, // Família
  14,  // Fantasia
  36,  // História
  27,  // Terror
  10402, // Música
  9648, // Mistério
  10749, // Romance
  878,  // Ficção Científica
  10770, // TV Movie
  53,  // Suspense
  10752, // Guerra
  37,  // Faroeste
];
```

### 2. AuthService

**Arquivo**: `lib/src/services/auth_service.dart`

**Responsabilidades:**
- Gerenciar autenticação de usuários
- Controlar sessão atual
- Interface com LocalDataSource para usuários

**Estado:**
```dart
User? _currentUser;
bool get isLoggedIn => _currentUser != null;
```

**Métodos:**
```dart
Future<bool> register(String name, String email, String password)
Future<bool> login(String email, String password)
void logout()
```

**Fluxo de Autenticação:**
```
register()
├── Verificar se email existe
├── Criar User
├── Salvar no LocalDataSource
└── Definir _currentUser

login()
├── Autenticar via LocalDataSource
├── Se sucesso: definir _currentUser
└── Retornar resultado
```

## Fontes de Dados (Data Sources)

### LocalDataSource

**Arquivo**: `lib/src/data/local/local_data_source.dart`

**Responsabilidades:**
- Interface com banco de dados SQLite
- Operações CRUD para todas as entidades
- Queries otimizadas

**Métodos Principais:**
```dart
// Movies
Future<List<Movie>> getAllMovies()
Future<void> saveMovies(List<Movie> movies)
Future<List<Movie>> getMoviesByGenre(int genreId)

// TV Series
Future<List<TVSeries>> getAllTVSeries()
Future<void> saveTVSeries(List<TVSeries> series)

// Channels
Future<List<Channel>> getAllChannels()
Future<void> saveChannels(List<Channel> channels)

// Users
Future<int> createUser(User user)
Future<User?> getUserByEmail(String email)
Future<User?> authenticateUser(String email, String password)
```

### TmdbDataSource

**Arquivo**: `lib/src/data/remote/tmdb_data_source.dart`

**Responsabilidades:**
- Comunicação com API TMDB
- Parsing de respostas JSON
- Tratamento de erros de rede

**Configuração:**
```dart
class TmdbDataSource {
  final String baseUrl = 'https://api.themoviedb.org/3';
  final String apiKey = 'eyJhbGciOiJIUzI1NiJ9...'; // Bearer token
  final String language = 'pt-BR';
}
```

**Métodos da API:**
```dart
Future<List<Movie>> fetchTrendingMovies()
Future<List<Movie>> fetchPopularMovies()
Future<List<Movie>> fetchMoviesByGenre(int genreId)
Future<List<TVSeries>> fetchTrendingTVSeries()
Future<List<TVSeries>> fetchPopularTVSeries()
Future<List<TVSeries>> fetchTVSeriesByGenre(int genreId)
Future<List<Genre>> fetchMovieGenres()
Future<List<Genre>> fetchTVGenres()
```

## Padrões de Tratamento de Erro

### Estratégia Geral
- Try-catch em todos os métodos assíncronos
- Rethrow de exceções para tratamento na UI
- Logging de erros para debug

### Tratamento Específico
```dart
try {
  final result = await _remoteDataSource.fetchTrendingMovies();
  return result;
} catch (e) {
  print('Erro ao buscar filmes em alta: $e');
  rethrow;
}
```

## Cache e Performance

### Cache de Sincronização
- SharedPreferences para timestamp da última sync
- Controle de frequência (24 horas)
- Evita chamadas desnecessárias à API

### Cache Local
- Dados armazenados em SQLite
- Acesso rápido para UI
- Sincronização em background

## Testabilidade

### Mocks para Testes
```dart
class MockMovieRepository implements MovieRepository {
  @override
  Future<List<Movie>> getTrendingMovies() async => mockMovies;
  // ...
}
```

### Dependências Injetadas
- Construtores recebem dependências
- Facilita injeção de mocks
- Testes isolados

## Considerações de Plataforma

### Desktop/Mobile vs Web
```dart
// Repository decide baseado na disponibilidade
if (_localDataSource == null) {
  // Web: dados remotos
  return await _remoteDataSource.fetchTrendingMovies();
} else {
  // Desktop/Mobile: dados locais
  return _localDataSource!.getAllMovies();
}
```

### Limitações da Web
- SQLite não funciona nativamente
- sqflite_common_ffi_web emula com IndexedDB
- Operações de escrita falham (apenas leitura)

## Monitoramento e Logs

### Logging Implementado
- Prints em operações de sincronização
- Contagem de itens salvos
- Erros de API e rede

### Exemplo de Output
```
Iniciando sincronização de dados...
Sincronizando filmes em alta...
Salvando 20 filmes em alta no banco local
Filmes em alta sincronizados
```

## Extensões Futuras

### Possíveis Melhorias
- Cache inteligente (LRU)
- Sincronização incremental
- Retry automático em falhas
- Compressão de dados
- Background sync

### Novos Repositórios
- UserRepository (para perfis)
- FavoritesRepository (para listas)
- SearchRepository (para buscas)

Esta documentação serve como referência completa para entender como os repositórios e serviços funcionam no projeto TV Multimidia.