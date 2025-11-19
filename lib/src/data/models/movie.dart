import 'package:isar/isar.dart';

part 'movie.g.dart';

@collection
class Movie {
  Id id = Isar.autoIncrement; // Auto-incremented ID for Isar

  @Index(unique: true, replace: true)
  late int tmdbId; // TMDB ID as unique identifier

  late String title;
  late String posterPath;
  late String overview;
  late String releaseDate;
  late String category; // e.g., 'popular', 'trending'

  Movie({
    required this.tmdbId,
    required this.title,
    required this.posterPath,
    required this.overview,
    required this.releaseDate,
    required this.category,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      tmdbId: json['id'],
      title: json['title'] ?? '',
      posterPath: json['poster_path'] ?? '',
      overview: json['overview'] ?? '',
      releaseDate: json['release_date'] ?? '',
      category: '', // Will be set when fetching
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': tmdbId,
      'title': title,
      'poster_path': posterPath,
      'overview': overview,
      'release_date': releaseDate,
    };
  }
}