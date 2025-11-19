import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import '../models/tv_series.dart';
import '../../utils/genre_localization.dart';

class Genre {
  final int id;
  String name;

  Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(id: json['id'], name: json['name']);
  }
}

class TmdbDataSource {
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  // Carrega a chave da API de forma segura
  static String get _apiKey {
    // Tenta carregar da variável de ambiente
    final envKey = Platform.environment['TMDB_API_KEY'];
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }

    // Fallback para desenvolvimento (NUNCA usar em produção!)
    return 'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJmMTk3M2Q4YzE4YmUxODYyNjI5OWE2ZGNlNmQyYzdjMCIsIm5iZiI6MTc1MDczNTQ0Ni44NjQsInN1YiI6IjY4NWExYTU2MmY1OTMwN2NkMjU3MmVhZCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.WqJC6aM33pww1-c_7N3aplZbE7jVGbP8UEqf_enOS1Y';
  }

  Future<List<Movie>> fetchPopularMovies() async {
    final url = Uri.parse('$_baseUrl/movie/popular?language=pt-BR');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      return results.map((json) => Movie.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load popular movies');
    }
  }

  Future<List<Movie>> fetchTrendingMovies() async {
    final url = Uri.parse('$_baseUrl/trending/movie/day?language=pt-BR');
    print('Fetching trending movies from: $url');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'accept': 'application/json',
      },
    );
    print('Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      print('Found ${results.length} trending movies');
      return results.map((json) => Movie.fromJson(json)).toList();
    } else {
      print('Error response: ${response.body}');
      throw Exception('Failed to load trending movies: ${response.statusCode}');
    }
  }

  Future<List<TVSeries>> fetchPopularTVSeries() async {
    final url = Uri.parse('$_baseUrl/tv/popular?language=pt-BR');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      return results.map((json) => TVSeries.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load popular TV series');
    }
  }

  Future<List<TVSeries>> fetchTrendingTVSeries() async {
    final url = Uri.parse('$_baseUrl/trending/tv/day?language=pt-BR');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      return results.map((json) => TVSeries.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load trending TV series');
    }
  }

  Future<List<Genre>> fetchMovieGenres() async {
    final url = Uri.parse('$_baseUrl/genre/movie/list?language=pt-BR');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final genres = data['genres'] as List;
      return genres.map((json) {
        final genre = Genre.fromJson(json);
        // Localizar o nome do gênero
        genre.name = GenreLocalization.getLocalizedGenreName(genre.id);
        return genre;
      }).toList();
    } else {
      throw Exception('Falha ao carregar gêneros de filmes');
    }
  }

  Future<List<Genre>> fetchTVGenres() async {
    final url = Uri.parse('$_baseUrl/genre/tv/list?language=pt-BR');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final genres = data['genres'] as List;
      return genres.map((json) {
        final genre = Genre.fromJson(json);
        // Localizar o nome do gênero
        genre.name = GenreLocalization.getLocalizedGenreName(genre.id);
        return genre;
      }).toList();
    } else {
      throw Exception('Falha ao carregar gêneros de séries');
    }
  }

  Future<List<Movie>> fetchMoviesByGenre(int genreId) async {
    final url = Uri.parse(
      '$_baseUrl/discover/movie?with_genres=$genreId&language=pt-BR',
    );
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      return results.map((json) => Movie.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load movies by genre');
    }
  }

  Future<List<TVSeries>> fetchTVSeriesByGenre(int genreId) async {
    final url = Uri.parse(
      '$_baseUrl/discover/tv?with_genres=$genreId&language=pt-BR',
    );
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      return results.map((json) => TVSeries.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load TV series by genre');
    }
  }

  Future<Map<String, dynamic>> fetchTVSeriesDetails(int seriesId) async {
    final url = Uri.parse('$_baseUrl/tv/$seriesId?language=pt-BR');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load TV series details');
    }
  }

  Future<Map<String, dynamic>> fetchSeasonDetails(
    int seriesId,
    int seasonNumber,
  ) async {
    final url = Uri.parse(
      '$_baseUrl/tv/$seriesId/season/$seasonNumber?language=pt-BR',
    );
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load season details');
    }
  }

  Future<List<Movie>> fetchMovieRecommendations(int movieId) async {
    final url = Uri.parse(
      '$_baseUrl/movie/$movieId/recommendations?language=pt-BR',
    );
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      return results.map((json) => Movie.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load movie recommendations');
    }
  }
}
