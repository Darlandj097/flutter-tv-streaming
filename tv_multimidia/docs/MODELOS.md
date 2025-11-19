# Modelos de Dados

## Visão Geral

Os modelos de dados do TV Multimidia representam as entidades principais da aplicação: filmes, séries de TV, canais, usuários e listas personalizadas. Estes modelos são responsáveis por estruturar os dados recebidos da API TMDB e armazenados localmente no SQLite.

## Arquitetura dos Modelos

### Características Gerais

- **Imutabilidade**: Todos os campos são `final`
- **Serialização**: Métodos `fromJson()`, `toJson()`, `fromMap()`, `toMap()`
- **Tratamento de Nulos**: Valores padrão para campos opcionais
- **Compatibilidade**: Entre API TMDB e banco de dados local

## Modelos Principais

### 1. Movie (Filme)

**Arquivo**: `lib/src/data/models/movie.dart`

**Campos:**
- `id` (int): Identificador único do TMDB
- `title` (String): Título do filme
- `overview` (String): Sinopse/resumo
- `posterPath` (String): Caminho do poster (relativo)
- `backdropPath` (String): Caminho do backdrop (relativo)
- `releaseDate` (String): Data de lançamento (YYYY-MM-DD)
- `voteAverage` (double): Média de votos (0.0-10.0)
- `voteCount` (int): Número total de votos
- `genreIds` (List<int>): Lista de IDs de gêneros
- `adult` (bool): Indica se é conteúdo adulto
- `originalLanguage` (String): Idioma original (código ISO)
- `originalTitle` (String): Título original
- `popularity` (double): Pontuação de popularidade
- `video` (bool): Indica se há vídeo disponível
- `imageUrls` (String): URLs de imagens concatenadas (para cache)

**Exemplo de Uso:**
```dart
final movie = Movie.fromJson(apiResponse);
print(movie.title); // "O Rei Leão"
print(movie.voteAverage); // 8.5
```

**Mapeamento JSON ↔ Banco:**
- `genre_ids` (JSON) ↔ `genreIds` (String separado por vírgula)
- `poster_path` (JSON) ↔ `posterPath` (String)
- `adult` (bool) ↔ `adult` (int: 0/1)

### 2. TVSeries (Série de TV)

**Arquivo**: `lib/src/data/models/tv_series.dart`

**Campos:**
- `id` (int): Identificador único do TMDB
- `name` (String): Nome da série
- `overview` (String): Sinopse/resumo
- `posterPath` (String): Caminho do poster
- `backdropPath` (String): Caminho do backdrop
- `firstAirDate` (String): Data do primeiro episódio
- `voteAverage` (double): Média de votos
- `voteCount` (int): Número total de votos
- `genreIds` (List<int>): Lista de IDs de gêneros
- `adult` (bool): Indica se é conteúdo adulto
- `originalLanguage` (String): Idioma original
- `originalName` (String): Nome original
- `popularity` (double): Pontuação de popularidade
- `originCountry` (String): País de origem (códigos ISO separados por vírgula)
- `imageUrls` (String): URLs de imagens concatenadas

**Getter Especial:**
- `tmdbId`: Alias para `id` (compatibilidade)

**Diferenças do Movie:**
- `name` ao invés de `title`
- `firstAirDate` ao invés de `releaseDate`
- Campo adicional `originCountry`

### 3. Channel (Canal)

**Arquivo**: `lib/src/data/models/channel.dart`

**Campos:**
- `id` (int): Identificador único
- `name` (String): Nome do canal
- `logoPath` (String): URL do logo
- `streamUrl` (String): URL de streaming
- `category` (String): Categoria do canal
- `description` (String): Descrição do canal
- `imageUrls` (String): URLs de imagens concatenadas

**Características:**
- Dados carregados do arquivo CSV `logos.csv`
- Usado principalmente para TV ao vivo
- Campos `streamUrl`, `category`, `description` podem estar vazios

### 4. User (Usuário)

**Arquivo**: `lib/src/data/models/user.dart`

**Características:**
- Usa `json_serializable` para geração automática de código
- Arquivo gerado: `user.g.dart`

**Campos:**
- `id` (int?): Identificador único (opcional para novos usuários)
- `name` (String): Nome do usuário
- `email` (String): Email do usuário
- `password` (String): Senha (deve ser hashada em produção)

**Exemplo de Geração:**
```dart
// Código gerado automaticamente
User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as int?,
  name: json['name'] as String,
  email: json['email'] as String,
  password: json['password'] as String,
);
```

### 5. UserList (Lista de Usuário)

**Arquivo**: `lib/src/data/models/user_list.dart`

**Características:**
- Usa `json_serializable` para geração automática
- Gerencia listas personalizadas do usuário

**Campos:**
- `id` (int?): Identificador único da entrada na lista
- `userId` (int): ID do usuário proprietário
- `itemId` (int): ID do filme/série
- `itemType` (String): Tipo do item ('movie' ou 'tv_series')
- `listType` (String): Tipo da lista ('my_list' ou 'favorites')

## Padrões de Serialização

### From JSON (API TMDB)

```dart
factory Movie.fromJson(Map<String, dynamic> json) {
  return Movie(
    id: json['id'] ?? 0,
    title: json['title'] ?? '',
    // ... outros campos com valores padrão
    genreIds: List<int>.from(json['genre_ids'] ?? []),
    voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
  );
}
```

**Tratamentos Especiais:**
- Conversão de tipos (`num` para `double`)
- Valores padrão para campos nulos
- Parsing de listas (`genre_ids` → `List<int>`)

### To JSON (Envio para API)

```dart
Map<String, dynamic> toJson() {
  return {
    'id': id,
    'title': title,
    // ... mapeamento direto
    'genreIds': genreIds.join(','), // Lista → String
    'adult': adult ? 1 : 0, // Bool → Int
  };
}
```

### From Map (Banco de Dados)

```dart
factory Movie.fromMap(Map<String, dynamic> map) {
  return Movie(
    id: map['id'],
    title: map['title'],
    // ... campos diretos
    genreIds: (map['genreIds'] as String?)
        ?.split(',')
        .map(int.parse)
        .toList() ?? [],
    adult: map['adult'] == 1, // Int → Bool
  );
}
```

## Gêneros (Genre)

Embora não seja um modelo dedicado, os gêneros são representados por uma classe simples:

```dart
class Genre {
  final int id;
  final String name;

  Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'],
      name: json['name'],
    );
  }
}
```

**IDs de Gêneros Principais:**
- 28: Ação
- 12: Aventura
- 16: Animação
- 35: Comédia
- 80: Crime
- 99: Documentário
- 18: Drama
- 10751: Família
- 14: Fantasia
- 36: História
- 27: Terror
- 10402: Música
- 9648: Mistério
- 10749: Romance
- 878: Ficção Científica
- 10770: TV Movie
- 53: Suspense
- 10752: Guerra
- 37: Faroeste

## Validações e Regras de Negócio

### Regras Gerais
- IDs devem ser positivos
- Strings não podem ser nulas (valores padrão vazios)
- Datas seguem formato ISO 8601
- URLs de imagens são relativas (completadas em runtime)

### Validações Específicas
- `voteAverage`: Entre 0.0 e 10.0
- `genreIds`: Lista não vazia para categorização
- `posterPath`: Essencial para exibição na UI

## Extensões e Utilitários

### Extensões para Imagens
```dart
extension MovieImages on Movie {
  String get fullPosterUrl => posterPath.isNotEmpty
      ? 'https://image.tmdb.org/t/p/w500$posterPath'
      : '';

  String get fullBackdropUrl => backdropPath.isNotEmpty
      ? 'https://image.tmdb.org/t/p/original$backdropPath'
      : '';
}
```

### Helpers de Formatação
```dart
extension MovieFormatters on Movie {
  String get formattedReleaseYear {
    if (releaseDate.isEmpty) return '';
    return DateTime.parse(releaseDate).year.toString();
  }

  String get ratingDisplay => voteAverage > 0
      ? voteAverage.toStringAsFixed(1)
      : 'N/A';
}
```

## Considerações de Performance

### Memória
- Modelos são imutáveis (não há estado mutável)
- Listas são criadas sob demanda
- Strings são eficientes em Dart

### Serialização
- `fromJson` é otimizado para parsing rápido
- `toJson` minimiza alocações
- Cache de imagens via `imageUrls`

### Banco de Dados
- Conversões eficientes entre tipos
- Índices apropriados nas tabelas
- Queries otimizadas nos repositórios

## Testes

### Testes Unitários
```dart
void main() {
  test('Movie.fromJson parses correctly', () {
    final json = {'id': 1, 'title': 'Test Movie'};
    final movie = Movie.fromJson(json);
    expect(movie.id, 1);
    expect(movie.title, 'Test Movie');
  });
}
```

### Testes de Integração
- Verificar compatibilidade com API TMDB
- Validar persistência no SQLite
- Testar conversões de tipos

## Manutenção e Evolução

### Adição de Campos
1. Adicionar campo na classe
2. Atualizar `fromJson` com valor padrão
3. Atualizar `toJson` e `toMap`
4. Atualizar `fromMap`
5. Migrar banco de dados se necessário

### Mudanças na API
- Monitorar mudanças no schema da TMDB
- Atualizar parsing conforme necessário
- Manter compatibilidade com versões antigas

### Geração de Código
Para modelos com `json_serializable`:
```bash
flutter pub run build_runner build
```

Este documento serve como referência completa para entender e trabalhar com os modelos de dados do projeto TV Multimidia.