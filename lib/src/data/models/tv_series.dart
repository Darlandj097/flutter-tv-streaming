import 'package:isar/isar.dart';

part 'tv_series.g.dart';

@collection
class TVSeries {
  Id id = Isar.autoIncrement; // Auto-incremented ID for Isar

  @Index(unique: true, replace: true)
  late int tmdbId; // TMDB ID as unique identifier

  late String name;
  late String posterPath;
  late String overview;
  late String firstAirDate;
  late String category; // e.g., 'popular', 'trending'

  TVSeries({
    required this.tmdbId,
    required this.name,
    required this.posterPath,
    required this.overview,
    required this.firstAirDate,
    required this.category,
  });

  factory TVSeries.fromJson(Map<String, dynamic> json) {
    return TVSeries(
      tmdbId: json['id'],
      name: json['name'] ?? '',
      posterPath: json['poster_path'] ?? '',
      overview: json['overview'] ?? '',
      firstAirDate: json['first_air_date'] ?? '',
      category: '', // Will be set when fetching
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': tmdbId,
      'name': name,
      'poster_path': posterPath,
      'overview': overview,
      'first_air_date': firstAirDate,
    };
  }
}
