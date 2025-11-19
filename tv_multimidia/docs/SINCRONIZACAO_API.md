# Sincronização e API TMDB

## Visão Geral

O TV Multimidia utiliza a API do The Movie Database (TMDB) como fonte primária de dados para filmes e séries de TV. O sistema de sincronização garante que o conteúdo local esteja sempre atualizado com as informações mais recentes da plataforma.

## API TMDB

### Configuração da API

**Classe Base:** `TmdbDataSource`

```dart
class TmdbDataSource {
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _apiKey = 'eyJhbGciOiJIUzI1NiJ9...'; // Bearer Token

  // Headers padrão para todas as requisições
  final Map<String, String> _headers = {
    'Authorization': 'Bearer $_apiKey',
    'accept': 'application/json',
  };
}
```

### Autenticação

- **Tipo:** Bearer Token Authentication
- **Token:** JWT (JSON Web Token) fornecido pela TMDB
- **Escopo:** `api_read` (somente leitura)
- **Validade:** Token permanente (não expira)

### Endpoints Utilizados

#### 1. Filmes Populares
```
GET /movie/popular?language=pt-BR
```
- **Uso:** Obter lista de filmes populares
- **Parâmetros:** `language=pt-BR`
- **Retorno:** Lista paginada de filmes

#### 2. Filmes em Alta (Trending)
```
GET /trending/movie/day?language=pt-BR
```
- **Uso:** Obter filmes em tendência do dia
- **Parâmetros:** `language=pt-BR`
- **Retorno:** Lista de filmes trending

#### 3. Séries Populares
```
GET /tv/popular?language=pt-BR
```
- **Uso:** Obter séries de TV populares
- **Parâmetros:** `language=pt-BR`

#### 4. Séries em Alta (Trending)
```
GET /trending/tv/day?language=pt-BR
```
- **Uso:** Obter séries em tendência

#### 5. Gêneros de Filmes
```
GET /genre/movie/list?language=pt-BR
```
- **Uso:** Lista de gêneros disponíveis para filmes
- **Localização:** Nomes traduzidos para português

#### 6. Gêneros de Séries
```
GET /genre/tv/list?language=pt-BR
```
- **Uso:** Lista de gêneros para séries de TV

#### 7. Filmes por Gênero
```
GET /discover/movie?with_genres={genre_id}&language=pt-BR
```
- **Uso:** Descobrir filmes de um gênero específico
- **Parâmetros:** `with_genres` (ID do gênero)

#### 8. Séries por Gênero
```
GET /discover/tv?with_genres={genre_id}&language=pt-BR
```
- **Uso:** Descobrir séries de um gênero específico

#### 9. Detalhes da Série
```
GET /tv/{series_id}?language=pt-BR
```
- **Uso:** Informações completas de uma série
- **Retorno:** Detalhes, temporadas, elenco, etc.

#### 10. Detalhes da Temporada
```
GET /tv/{series_id}/season/{season_number}?language=pt-BR
```
- **Uso:** Episódios de uma temporada específica

#### 11. Recomendações de Filmes
```
GET /movie/{movie_id}/recommendations?language=pt-BR
```
- **Uso:** Filmes similares/recomendados
- **Baseado em:** Algoritmos da TMDB

## Sistema de Sincronização

### Arquitetura

```
SyncService
├── syncDataIfNeeded()     // Verifica necessidade de sync
├── forceSync()           // Força sincronização
└── _performSync()        // Executa sincronização completa
    ├── Filmes em alta
    ├── Filmes populares
    ├── Séries em alta
    ├── Séries populares
    └── Gêneros principais
```

### Controle de Frequência

```dart
class SyncService {
  static const String _lastSyncKey = 'last_sync_timestamp';

  Future<void> syncDataIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt(_lastSyncKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final oneDayInMillis = 24 * 60 * 60 * 1000; // 24 horas

    if (now - lastSync > oneDayInMillis) {
      await _performSync();
      await prefs.setInt(_lastSyncKey, now);
    }
  }
}
```

**Frequência:** Uma vez por dia
**Armazenamento:** SharedPreferences
**Chave:** `last_sync_timestamp`

### Processo de Sincronização

#### 1. Verificação de Necessidade
- Compara timestamp atual com última sincronização
- Se passou 24 horas, inicia processo

#### 2. Execução da Sincronização
```dart
Future<void> _performSync() async {
  print('Iniciando sincronização de dados...');

  // Sincronizar filmes
  await _movieRepository.syncTrendingMovies();
  await _movieRepository.syncPopularMovies();

  // Sincronizar séries
  await _tvSeriesRepository.syncTrendingTVSeries();
  await _tvSeriesRepository.syncPopularTVSeries();

  // Sincronizar gêneros
  await _syncGenres();
}
```

#### 3. Sincronização por Gênero
```dart
Future<void> _syncGenres() async {
  const mainGenres = [
    28, 12, 16, 35, 80, 99, 18, 10751, 14, 36,
    27, 10402, 9648, 10749, 878, 10770, 53, 10752, 37
  ];

  for (final genreId in mainGenres) {
    await _movieRepository.syncMoviesByGenre(genreId);
    await _tvSeriesRepository.syncTVSeriesByGenre(genreId);
  }
}
```

### Tratamento de Erros

#### Estratégia
- Try-catch em todas as operações
- Logging detalhado de erros
- Continuação do processo mesmo com falhas parciais
- Rethrow para tratamento na UI

#### Exemplo de Tratamento
```dart
try {
  final movies = await _remoteDataSource.fetchTrendingMovies();
  await _localDataSource.saveMovies(movies);
  print('Filmes em alta sincronizados');
} catch (e) {
  print('Erro ao sincronizar filmes em alta: $e');
  // Continua com próximas sincronizações
}
```

## Mapeamento de Dados

### Conversão JSON ↔ Modelos

#### Movie.fromJson()
```dart
factory Movie.fromJson(Map<String, dynamic> json) {
  return Movie(
    id: json['id'] ?? 0,
    title: json['title'] ?? '',
    overview: json['overview'] ?? '',
    posterPath: json['poster_path'] ?? '',
    backdropPath: json['backdrop_path'] ?? '',
    releaseDate: json['release_date'] ?? '',
    voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
    voteCount: json['vote_count'] ?? 0,
    genreIds: List<int>.from(json['genre_ids'] ?? []),
    adult: json['adult'] ?? false,
    originalLanguage: json['original_language'] ?? '',
    originalTitle: json['original_title'] ?? '',
    popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
    video: json['video'] ?? false,
    imageUrls: '', // Preenchido depois se necessário
  );
}
```

#### TVSeries.fromJson()
```dart
factory TVSeries.fromJson(Map<String, dynamic> json) {
  return TVSeries(
    id: json['id'] ?? 0,
    name: json['name'] ?? '', // Campo diferente: 'name' ao invés de 'title'
    overview: json['overview'] ?? '',
    posterPath: json['poster_path'] ?? '',
    backdropPath: json['backdrop_path'] ?? '',
    firstAirDate: json['first_air_date'] ?? '', // Campo diferente
    voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
    voteCount: json['vote_count'] ?? 0,
    genreIds: List<int>.from(json['genre_ids'] ?? []),
    adult: json['adult'] ?? false,
    originalLanguage: json['original_language'] ?? '',
    originalName: json['original_name'] ?? '', // Campo diferente
    popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
    originCountry: (json['origin_country'] as List<dynamic>?)?.join(',') ?? '',
    imageUrls: '',
  );
}
```

### Tratamento de Tipos

#### Conversões Seguras
- `num?` → `double`: `(json['vote_average'] as num?)?.toDouble() ?? 0.0`
- `List<dynamic>` → `List<int>`: `List<int>.from(json['genre_ids'] ?? [])`
- `bool?` → `bool`: `json['adult'] ?? false`

#### Valores Padrão
- Strings vazias: `?? ''`
- Números zero: `?? 0` ou `?? 0.0`
- Listas vazias: `?? []`

## Localização de Gêneros

### Classe GenreLocalization

**Arquivo:** `lib/src/utils/genre_localization.dart`

```dart
class GenreLocalization {
  static String getLocalizedGenreName(int genreId) {
    const genreMap = {
      28: 'Ação',
      12: 'Aventura',
      16: 'Animação',
      35: 'Comédia',
      80: 'Crime',
      99: 'Documentário',
      18: 'Drama',
      10751: 'Família',
      14: 'Fantasia',
      36: 'História',
      27: 'Terror',
      10402: 'Música',
      9648: 'Mistério',
      10749: 'Romance',
      878: 'Ficção Científica',
      10770: 'TV Movie',
      53: 'Suspense',
      10752: 'Guerra',
      37: 'Faroeste',
    };
    return genreMap[genreId] ?? 'Desconhecido';
  }
}
```

### Integração com API
```dart
Future<List<Genre>> fetchMovieGenres() async {
  // ... requisição HTTP ...
  return genres.map((json) {
    final genre = Genre.fromJson(json);
    genre.name = GenreLocalization.getLocalizedGenreName(genre.id);
    return genre;
  }).toList();
}
```

## Limites e Rate Limiting

### Limites da API TMDB
- **Requests por dia:** 500 (para contas gratuitas)
- **Requests por segundo:** Não especificado, mas recomenda-se delay
- **Cache:** Implementado para reduzir chamadas

### Estratégia de Otimização
- Sincronização diária ao invés de tempo real
- Cache local de dados
- Tratamento de erros para evitar retry excessivo

## Monitoramento e Debugging

### Logging Implementado
```dart
// Logs de requisições
print('Fetching trending movies from: $url');
print('Response status: ${response.statusCode}');
print('Found ${results.length} trending movies');

// Logs de erros
print('Error response: ${response.body}');
throw Exception('Failed to load trending movies: ${response.statusCode}');
```

### Métricas Úteis
- Número de itens sincronizados
- Tempo de resposta da API
- Taxa de sucesso de requisições
- Tamanho do cache local

## Tratamento de Falhas

### Cenários de Falha
1. **Sem conexão:** Fallback para dados locais
2. **API indisponível:** Retry com delay exponencial
3. **Rate limit excedido:** Aguardar e tentar novamente
4. **Dados corrompidos:** Limpar cache e refazer sync

### Estratégia de Recuperação
```dart
Future<T> _withRetry<T>(Future<T> Function() operation) async {
  int attempts = 0;
  const maxAttempts = 3;

  while (attempts < maxAttempts) {
    try {
      return await operation();
    } catch (e) {
      attempts++;
      if (attempts >= maxAttempts) rethrow;

      // Delay exponencial
      await Future.delayed(Duration(seconds: attempts * 2));
    }
  }
}
```

## Segurança

### Proteção da Chave API
- **Armazenamento:** Hardcoded no código (NÃO recomendado para produção)
- **Recomendação:** Usar variáveis de ambiente ou configuração segura
- **Alternativa:** Proxy server próprio para ocultar chave

### Validação de Dados
- Verificação de tipos de resposta
- Sanitização de strings
- Validação de URLs de imagem

## Extensões Futuras

### Possíveis Melhorias
- **Webhooks:** Notificações automáticas de mudanças
- **GraphQL:** Queries mais eficientes
- **Streaming:** Suporte a dados em tempo real
- **Cache Inteligente:** Invalidação baseada em TTL
- **Compressão:** Redução de tamanho dos dados transferidos

### Novos Endpoints
- Busca por texto
- Detalhes de filmes/séries
- Créditos (elenco e equipe)
- Reviews e avaliações
- Vídeos (trailers)

Esta documentação cobre completamente como o TV Multimidia se integra com a API TMDB e mantém seus dados sincronizados e atualizados.