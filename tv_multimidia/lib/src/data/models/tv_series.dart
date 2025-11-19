class TVSeries {
  final int id;
  final String name;
  final String overview;
  final String posterPath;
  final String backdropPath;
  final String firstAirDate;
  final double voteAverage;
  final int voteCount;
  final List<int> genreIds;
  final bool adult;
  final String originalLanguage;
  final String originalName;
  final double popularity;
  final String originCountry;
  final String imageUrls;

  int get tmdbId => id;

  TVSeries({
    required this.id,
    required this.name,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.firstAirDate,
    required this.voteAverage,
    required this.voteCount,
    required this.genreIds,
    required this.adult,
    required this.originalLanguage,
    required this.originalName,
    required this.popularity,
    required this.originCountry,
    required this.imageUrls,
  });

  factory TVSeries.fromJson(Map<String, dynamic> json) {
    return TVSeries(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'] ?? '',
      backdropPath: json['backdrop_path'] ?? '',
      firstAirDate: json['first_air_date'] ?? '',
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['vote_count'] ?? 0,
      genreIds: List<int>.from(json['genre_ids'] ?? []),
      adult: json['adult'] ?? false,
      originalLanguage: json['original_language'] ?? '',
      originalName: json['original_name'] ?? '',
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
      originCountry:
          (json['origin_country'] as List<dynamic>?)?.join(',') ?? '',
      imageUrls: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'overview': overview,
      'posterPath': posterPath,
      'backdropPath': backdropPath,
      'firstAirDate': firstAirDate,
      'voteAverage': voteAverage,
      'voteCount': voteCount,
      'genreIds': genreIds.join(','),
      'adult': adult ? 1 : 0,
      'originalLanguage': originalLanguage,
      'originalName': originalName,
      'popularity': popularity,
      'originCountry': originCountry,
      'imageUrls': imageUrls,
    };
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }

  factory TVSeries.fromMap(Map<String, dynamic> map) {
    return TVSeries(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      overview: map['overview'] ?? '',
      posterPath: map['posterPath'] ?? '',
      backdropPath: map['backdropPath'] ?? '',
      firstAirDate: map['firstAirDate'] ?? '',
      voteAverage: map['voteAverage'] ?? 0.0,
      voteCount: map['voteCount'] ?? 0,
      genreIds:
          (map['genreIds'] as String?)?.split(',').map(int.parse).toList() ??
          [],
      adult: map['adult'] == 1,
      originalLanguage: map['originalLanguage'] ?? '',
      originalName: map['originalName'] ?? '',
      popularity: map['popularity'] ?? 0.0,
      originCountry: map['originCountry'] ?? '',
      imageUrls: map['imageUrls'] ?? '',
    );
  }
}
