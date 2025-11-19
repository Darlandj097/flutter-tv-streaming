import 'package:flutter/foundation.dart' show kIsWeb;
import '../local/local_data_source.dart';
import '../remote/tmdb_data_source.dart';
import '../remote/api_data_source.dart';
import '../models/movie.dart';

class MovieRepository {
  final LocalDataSource? _localDataSource;
  final dynamic _remoteDataSource; // Pode ser TmdbDataSource ou ApiDataSource

  MovieRepository(this._localDataSource, this._remoteDataSource);

  // Método de exibição (Leitura): Chamado pela camada BLoC/Riverpod para mostrar dados na UI
  Future<List<Movie>> getTrendingMovies() async {
    print('[MovieRepository] Buscando filmes em alta');
    try {
      List<Movie> movies;
      if (_remoteDataSource is ApiDataSource) {
        movies = await (_remoteDataSource as ApiDataSource)
            .fetchTrendingMovies();
        print(
          '[MovieRepository] Filmes em alta obtidos da ApiDataSource: ${movies.length}',
        );
      } else if (_localDataSource != null) {
        movies = await _localDataSource!.getAllMovies();
        print(
          '[MovieRepository] Filmes em alta obtidos do LocalDataSource: ${movies.length}',
        );
      } else {
        movies = await (_remoteDataSource as TmdbDataSource)
            .fetchTrendingMovies();
        print(
          '[MovieRepository] Filmes em alta obtidos da TmdbDataSource: ${movies.length}',
        );
      }
      return movies;
    } catch (e) {
      print('[MovieRepository] Erro ao buscar filmes em alta: $e');
      rethrow;
    }
  }

  Future<List<Movie>> getPopularMovies() async {
    if (_remoteDataSource is ApiDataSource) {
      return await (_remoteDataSource as ApiDataSource).fetchPopularMovies();
    } else if (_localDataSource != null) {
      return _localDataSource!.getAllMovies();
    } else {
      return await (_remoteDataSource as TmdbDataSource).fetchPopularMovies();
    }
  }

  // Método de carga (Sincronização): Chamado uma vez ao dia, ou na primeira execução
  Future<void> syncTrendingMovies() async {
    if (_localDataSource == null) return;
    final remoteMovies = await _remoteDataSource.fetchTrendingMovies();
    print('Salvando ${remoteMovies.length} filmes em alta no banco local');
    await _localDataSource!.saveMovies(remoteMovies);
  }

  Future<void> syncPopularMovies() async {
    if (_localDataSource == null) return;
    final remoteMovies = await _remoteDataSource.fetchPopularMovies();
    print('Salvando ${remoteMovies.length} filmes populares no banco local');
    await _localDataSource!.saveMovies(remoteMovies);
  }

  Future<List<Movie>> getMoviesByGenre(int genreId) async {
    print('[MovieRepository] Buscando filmes por gênero: $genreId');
    try {
      List<Movie> movies;
      if (_localDataSource != null) {
        movies = await _localDataSource!.getMoviesByGenre(genreId);
        print(
          '[MovieRepository] Filmes por gênero obtidos do LocalDataSource: ${movies.length}',
        );
      } else {
        // Sempre usar TMDB para busca por gênero, já que ApiDataSource não implementa
        final tmdbDataSource = _remoteDataSource is TmdbDataSource
            ? _remoteDataSource
            : TmdbDataSource();
        movies = await tmdbDataSource.fetchMoviesByGenre(genreId);
        print(
          '[MovieRepository] Filmes por gênero obtidos da TmdbDataSource: ${movies.length}',
        );
      }
      return movies;
    } catch (e) {
      print('[MovieRepository] Erro ao buscar filmes por gênero $genreId: $e');
      rethrow;
    }
  }

  Future<void> syncMoviesByGenre(int genreId) async {
    if (_localDataSource == null) return;
    final remoteMovies = await _remoteDataSource.fetchMoviesByGenre(genreId);
    print(
      'Salvando ${remoteMovies.length} filmes do gênero $genreId no banco local',
    );
    await _localDataSource!.saveMovies(remoteMovies);
  }
}
