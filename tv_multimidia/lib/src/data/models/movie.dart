/**
 * Modelo de dados para Filme
 *
 * Representa um filme obtido da API TMDB. Contém todas as informações
 * relevantes sobre um filme, incluindo metadados, avaliações e caminhos
 * para imagens.
 *
 * Compatível com serialização JSON e mapeamento para banco de dados SQLite.
 */
class Movie {
  /// Identificador único do filme na TMDB
  final int id;

  /// Título do filme no idioma solicitado
  final String title;

  /// Sinopse/resumo do filme
  final String overview;

  /// Caminho relativo do poster (completar com base URL da TMDB)
  final String posterPath;

  /// Caminho relativo do backdrop/imagem de fundo
  final String backdropPath;

  /// Data de lançamento (formato YYYY-MM-DD)
  final String releaseDate;

  /// Média das avaliações dos usuários (0.0 a 10.0)
  final double voteAverage;

  /// Número total de votos/avaliações
  final int voteCount;

  /// Lista de IDs dos gêneros associados ao filme
  final List<int> genreIds;

  /// Indica se o conteúdo é classificado como adulto
  final bool adult;

  /// Idioma original do filme (código ISO 639-1)
  final String originalLanguage;

  /// Título original do filme (no idioma original)
  final String originalTitle;

  /// Pontuação de popularidade calculada pela TMDB
  final double popularity;

  /// Indica se há vídeo/trailer disponível
  final bool video;

  /// URLs de imagens concatenadas (usado para cache)
  final String imageUrls;

  /// Construtor do modelo Movie
  ///
  /// Todos os campos são obrigatórios para garantir integridade dos dados.
  /// Use [Movie.fromJson] para criar instâncias a partir de dados da API.
  Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.releaseDate,
    required this.voteAverage,
    required this.voteCount,
    required this.genreIds,
    required this.adult,
    required this.originalLanguage,
    required this.originalTitle,
    required this.popularity,
    required this.video,
    required this.imageUrls,
  });

  /// Cria uma instância de Movie a partir de dados JSON da API TMDB
  ///
  /// Trata valores nulos e conversões de tipos de forma segura.
  /// Campos opcionais recebem valores padrão apropriados.
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
      imageUrls: '', // Inicialmente vazio, preenchido por cache se necessário
    );
  }

  /// Converte a instância para Map<String, dynamic> compatível com SQLite
  ///
  /// Converte tipos Dart para tipos compatíveis com banco de dados:
  /// - List<int> → String (separado por vírgula)
  /// - bool → int (0/1)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'overview': overview,
      'posterPath': posterPath,
      'backdropPath': backdropPath,
      'releaseDate': releaseDate,
      'voteAverage': voteAverage,
      'voteCount': voteCount,
      'genreIds': genreIds.join(','), // Lista → String para SQLite
      'adult': adult ? 1 : 0, // Bool → Int para SQLite
      'originalLanguage': originalLanguage,
      'originalTitle': originalTitle,
      'popularity': popularity,
      'video': video ? 1 : 0, // Bool → Int para SQLite
      'imageUrls': imageUrls,
    };
  }

  /// Alias para toJson() para compatibilidade
  Map<String, dynamic> toMap() {
    return toJson();
  }

  /// Cria uma instância de Movie a partir de dados do banco SQLite
  ///
  /// Reverte as conversões feitas em toJson():
  /// - String → List<int> (split por vírgula)
  /// - int → bool (1 = true, outros = false)
  factory Movie.fromMap(Map<String, dynamic> map) {
    return Movie(
      id: map['id'] ?? 0,
      title: map['title'] ?? '',
      overview: map['overview'] ?? '',
      posterPath: map['posterPath'] ?? '',
      backdropPath: map['backdropPath'] ?? '',
      releaseDate: map['releaseDate'] ?? '',
      voteAverage: map['voteAverage'] ?? 0.0,
      voteCount: map['voteCount'] ?? 0,
      genreIds:
          (map['genreIds'] as String?)?.split(',').map(int.parse).toList() ??
          [],
      adult: map['adult'] == 1, // Int → Bool
      originalLanguage: map['originalLanguage'] ?? '',
      originalTitle: map['originalTitle'] ?? '',
      popularity: map['popularity'] ?? 0.0,
      video: map['video'] == 1, // Int → Bool
      imageUrls: map['imageUrls'] ?? '',
    );
  }
}
