import 'package:shared_preferences/shared_preferences.dart';
import '../data/repositories/movie_repository.dart';
import '../data/repositories/tv_series_repository.dart';
import '../data/remote/tmdb_data_source.dart';
import '../data/remote/api_data_source.dart';

class SyncService {
  final MovieRepository _movieRepository;
  final TVSeriesRepository _tvSeriesRepository;
  final ApiDataSource? _apiDataSource;

  SyncService(
    this._movieRepository,
    this._tvSeriesRepository, {
    ApiDataSource? apiDataSource,
  }) : _apiDataSource = apiDataSource;

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

  Future<void> forceSync() async {
    // Se temos API, sincronizar via API
    if (_apiDataSource != null) {
      try {
        await _apiDataSource!.syncData();
        print('Sincronização via API concluída');
      } catch (e) {
        print('Erro na sincronização via API: $e');
      }
    } else {
      // Caso contrário, fazer sincronização local
      await _performSync();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _performSync() async {
    try {
      print('Iniciando sincronização de dados...');

      // Sincronizar filmes
      print('Sincronizando filmes em alta...');
      await _movieRepository.syncTrendingMovies();
      print('Filmes em alta sincronizados');

      print('Sincronizando filmes populares...');
      await _movieRepository.syncPopularMovies();
      print('Filmes populares sincronizados');

      // Sincronizar séries
      print('Sincronizando séries em alta...');
      await _tvSeriesRepository.syncTrendingTVSeries();
      print('Séries em alta sincronizadas');

      print('Sincronizando séries populares...');
      await _tvSeriesRepository.syncPopularTVSeries();
      print('Séries populares sincronizadas');

      // Sincronizar gêneros (opcional - pode ser pesado)
      print('Sincronizando filmes por gênero...');
      await _syncGenres();

      print('Sincronização concluída com sucesso');
    } catch (e) {
      print('Erro durante sincronização: $e');
      rethrow;
    }
  }

  Future<void> _syncGenres() async {
    try {
      // Buscar gêneros
      final tmdbDataSource = TmdbDataSource();
      final movieGenres = await tmdbDataSource.fetchMovieGenres();
      final tvGenres = await tmdbDataSource.fetchTVGenres();

      // Sincronizar alguns gêneros principais (para não sobrecarregar)
      final mainGenres = [
        28,
        12,
        16,
        35,
        80,
        99,
        18,
        10751,
        14,
        36,
        27,
        10402,
        9648,
        10749,
        878,
        10770,
        53,
        10752,
        37,
      ]; // IDs dos gêneros principais

      for (final genreId in mainGenres) {
        try {
          await _movieRepository.syncMoviesByGenre(genreId);
          await _tvSeriesRepository.syncTVSeriesByGenre(genreId);
        } catch (e) {
          // Ignorar erro para este gênero
        }
      }
    } catch (e) {
      print('Erro ao sincronizar gêneros: $e');
    }
  }
}
