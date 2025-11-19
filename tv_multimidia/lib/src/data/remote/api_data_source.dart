import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import '../models/tv_series.dart';
import '../models/channel.dart';

class ApiDataSource {
  final String baseUrl;

  ApiDataSource({this.baseUrl = 'http://localhost:5000/api'});

  // Movies
  Future<List<Movie>> fetchMovies() async {
    print('[ApiDataSource] Buscando filmes da API: $baseUrl/movies');
    try {
      final response = await http.get(Uri.parse('$baseUrl/movies'));
      print('[ApiDataSource] Resposta da API filmes: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('[ApiDataSource] Filmes obtidos da API: ${data.length}');
        return data.map((json) => Movie.fromMap(json)).toList();
      } else {
        print(
          '[ApiDataSource] Erro ao buscar filmes: ${response.statusCode} - ${response.body}',
        );
        throw Exception('Erro ao buscar filmes: ${response.statusCode}');
      }
    } catch (e) {
      print('[ApiDataSource] Erro na conexão com a API para filmes: $e');
      throw Exception('Erro na conexão com a API: $e');
    }
  }

  Future<List<Movie>> fetchTrendingMovies() async {
    print(
      '[ApiDataSource] Buscando filmes em alta da API: $baseUrl/movies/trending',
    );
    try {
      final response = await http.get(Uri.parse('$baseUrl/movies/trending'));
      print(
        '[ApiDataSource] Resposta da API filmes em alta: ${response.statusCode}',
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('[ApiDataSource] Filmes em alta obtidos da API: ${data.length}');
        return data.map((json) => Movie.fromMap(json)).toList();
      } else {
        print(
          '[ApiDataSource] Erro ao buscar filmes em alta: ${response.statusCode} - ${response.body}',
        );
        throw Exception(
          'Erro ao buscar filmes em alta: ${response.statusCode}',
        );
      }
    } catch (e) {
      print(
        '[ApiDataSource] Erro na conexão com a API para filmes em alta: $e',
      );
      throw Exception('Erro na conexão com a API: $e');
    }
  }

  Future<List<Movie>> fetchPopularMovies() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/movies/popular'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Movie.fromMap(json)).toList();
      } else {
        throw Exception(
          'Erro ao buscar filmes populares: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erro na conexão com a API: $e');
    }
  }

  // TV Series
  Future<List<TVSeries>> fetchTVSeries() async {
    print('[ApiDataSource] Buscando séries da API: $baseUrl/series');
    try {
      final response = await http.get(Uri.parse('$baseUrl/series'));
      print('[ApiDataSource] Resposta da API séries: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('[ApiDataSource] Séries obtidas da API: ${data.length}');
        return data.map((json) => TVSeries.fromMap(json)).toList();
      } else {
        print(
          '[ApiDataSource] Erro ao buscar séries: ${response.statusCode} - ${response.body}',
        );
        throw Exception('Erro ao buscar séries: ${response.statusCode}');
      }
    } catch (e) {
      print('[ApiDataSource] Erro na conexão com a API para séries: $e');
      throw Exception('Erro na conexão com a API: $e');
    }
  }

  Future<List<TVSeries>> fetchTrendingTVSeries() async {
    print(
      '[ApiDataSource] Buscando séries em alta da API: $baseUrl/series/trending',
    );
    try {
      final response = await http.get(Uri.parse('$baseUrl/series/trending'));
      print(
        '[ApiDataSource] Resposta da API séries em alta: ${response.statusCode}',
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('[ApiDataSource] Séries em alta obtidas da API: ${data.length}');
        return data.map((json) => TVSeries.fromMap(json)).toList();
      } else {
        print(
          '[ApiDataSource] Erro ao buscar séries em alta: ${response.statusCode} - ${response.body}',
        );
        throw Exception(
          'Erro ao buscar séries em alta: ${response.statusCode}',
        );
      }
    } catch (e) {
      print(
        '[ApiDataSource] Erro na conexão com a API para séries em alta: $e',
      );
      throw Exception('Erro na conexão com a API: $e');
    }
  }

  Future<List<TVSeries>> fetchPopularTVSeries() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/series/popular'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => TVSeries.fromMap(json)).toList();
      } else {
        throw Exception(
          'Erro ao buscar séries populares: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erro na conexão com a API: $e');
    }
  }

  // Channels
  Future<List<Channel>> fetchChannels() async {
    print('[ApiDataSource] Buscando canais da API: $baseUrl/channels');
    try {
      // Adicionar timestamp para evitar cache
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(
        Uri.parse('$baseUrl/channels?t=$timestamp'),
      );
      print('[ApiDataSource] Resposta da API canais: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('[ApiDataSource] Canais obtidos da API: ${data.length}');
        if (data.isNotEmpty) {
          print('[ApiDataSource] Primeiro canal da API: ${data[0]}');
        }
        final channels = data.map((json) => Channel.fromMap(json)).toList();
        print('[ApiDataSource] Canais mapeados: ${channels.length}');
        if (channels.isNotEmpty) {
          print(
            '[ApiDataSource] Primeiro canal mapeado - nome: ${channels[0].name}, logoPath: "${channels[0].logoPath}"',
          );
        }
        return channels;
      } else {
        print(
          '[ApiDataSource] Erro ao buscar canais: ${response.statusCode} - ${response.body}',
        );
        throw Exception('Erro ao buscar canais: ${response.statusCode}');
      }
    } catch (e) {
      print('[ApiDataSource] Erro na conexão com a API para canais: $e');
      throw Exception('Erro na conexão com a API: $e');
    }
  }

  Future<List<String>> fetchChannelCategories() async {
    print(
      '[ApiDataSource] Buscando categorias da API: $baseUrl/channels/categories',
    );
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/channels/categories'),
      );
      print(
        '[ApiDataSource] Resposta da API categorias: ${response.statusCode}',
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('[ApiDataSource] Categorias obtidas da API: ${data.length}');
        return data.map((item) => item.toString()).toList();
      } else {
        throw Exception('Erro ao buscar categorias: ${response.statusCode}');
      }
    } catch (e) {
      print('[ApiDataSource] Erro na conexão com a API para categorias: $e');
      throw Exception('Erro na conexão com a API: $e');
    }
  }

  Future<List<Channel>> fetchChannelsByCategory(String category) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/channels/category/$category'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Channel.fromMap(json)).toList();
      } else {
        throw Exception(
          'Erro ao buscar canais da categoria: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erro na conexão com a API: $e');
    }
  }

  // User operations
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Erro no login');
      }
    } catch (e) {
      throw Exception('Erro na conexão com a API: $e');
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name, 'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Erro no registro');
      }
    } catch (e) {
      throw Exception('Erro na conexão com a API: $e');
    }
  }

  Future<List<Movie>> fetchUserMovieList() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/user/lists/movies'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Movie.fromMap(json)).toList();
      } else {
        throw Exception(
          'Erro ao buscar lista de filmes: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erro na conexão com a API: $e');
    }
  }

  Future<List<TVSeries>> fetchUserSeriesList() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/user/lists/series'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => TVSeries.fromMap(json)).toList();
      } else {
        throw Exception(
          'Erro ao buscar lista de séries: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erro na conexão com a API: $e');
    }
  }

  Future<List<Movie>> fetchUserFavoriteMovies() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/favorites/movies'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Movie.fromMap(json)).toList();
      } else {
        throw Exception(
          'Erro ao buscar filmes favoritos: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erro na conexão com a API: $e');
    }
  }

  Future<List<TVSeries>> fetchUserFavoriteSeries() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/favorites/series'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => TVSeries.fromMap(json)).toList();
      } else {
        throw Exception(
          'Erro ao buscar séries favoritas: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erro na conexão com a API: $e');
    }
  }

  // Health check
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erro no health check: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na conexão com a API: $e');
    }
  }

  // Sync operation
  Future<void> syncData() async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/sync'));
      if (response.statusCode != 200) {
        throw Exception('Erro na sincronização: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na conexão com a API: $e');
    }
  }
}
