import 'package:flutter/foundation.dart' show kIsWeb;
import '../local/local_data_source.dart';
import '../remote/tmdb_data_source.dart';
import '../remote/api_data_source.dart';
import '../models/tv_series.dart';

class TVSeriesRepository {
  final LocalDataSource? _localDataSource;
  final dynamic _remoteDataSource; // Pode ser TmdbDataSource ou ApiDataSource

  TVSeriesRepository(this._localDataSource, this._remoteDataSource);

  // Método de exibição (Leitura): Chamado pela camada BLoC/Riverpod para mostrar dados na UI
  Future<List<TVSeries>> getTrendingTVSeries() async {
    print('[TVSeriesRepository] Buscando séries em alta');
    try {
      List<TVSeries> series;
      if (_remoteDataSource is ApiDataSource) {
        series = await (_remoteDataSource as ApiDataSource)
            .fetchTrendingTVSeries();
        print(
          '[TVSeriesRepository] Séries em alta obtidas da ApiDataSource: ${series.length}',
        );
      } else if (_localDataSource != null) {
        series = await _localDataSource!.getAllTVSeries();
        print(
          '[TVSeriesRepository] Séries em alta obtidas do LocalDataSource: ${series.length}',
        );
      } else {
        series = await (_remoteDataSource as TmdbDataSource)
            .fetchTrendingTVSeries();
        print(
          '[TVSeriesRepository] Séries em alta obtidas da TmdbDataSource: ${series.length}',
        );
      }
      return series;
    } catch (e) {
      print('[TVSeriesRepository] Erro ao buscar séries em alta: $e');
      rethrow;
    }
  }

  Future<List<TVSeries>> getPopularTVSeries() async {
    if (_remoteDataSource is ApiDataSource) {
      return await (_remoteDataSource as ApiDataSource).fetchPopularTVSeries();
    } else if (_localDataSource != null) {
      return _localDataSource!.getAllTVSeries();
    } else {
      return await (_remoteDataSource as TmdbDataSource).fetchPopularTVSeries();
    }
  }

  // Método de carga (Sincronização): Chamado uma vez ao dia, ou na primeira execução
  Future<void> syncTrendingTVSeries() async {
    if (_localDataSource == null) return;
    final remoteSeries = await _remoteDataSource.fetchTrendingTVSeries();
    print('Salvando ${remoteSeries.length} séries em alta no banco local');
    await _localDataSource!.saveTVSeries(remoteSeries);
  }

  Future<void> syncPopularTVSeries() async {
    if (_localDataSource == null) return;
    final remoteSeries = await _remoteDataSource.fetchPopularTVSeries();
    print('Salvando ${remoteSeries.length} séries populares no banco local');
    await _localDataSource!.saveTVSeries(remoteSeries);
  }

  Future<List<TVSeries>> getTVSeriesByGenre(int genreId) async {
    print('[TVSeriesRepository] Buscando séries por gênero: $genreId');
    try {
      List<TVSeries> series;
      if (_localDataSource != null) {
        series = await _localDataSource!.getTVSeriesByGenre(genreId);
        print(
          '[TVSeriesRepository] Séries por gênero obtidas do LocalDataSource: ${series.length}',
        );
      } else {
        // Sempre usar TMDB para busca por gênero, já que ApiDataSource não implementa
        final tmdbDataSource = _remoteDataSource is TmdbDataSource
            ? _remoteDataSource
            : TmdbDataSource();
        series = await tmdbDataSource.fetchTVSeriesByGenre(genreId);
        print(
          '[TVSeriesRepository] Séries por gênero obtidas da TmdbDataSource: ${series.length}',
        );
      }
      return series;
    } catch (e) {
      print(
        '[TVSeriesRepository] Erro ao buscar séries por gênero $genreId: $e',
      );
      rethrow;
    }
  }

  Future<void> syncTVSeriesByGenre(int genreId) async {
    if (_localDataSource == null) return;
    final remoteSeries = await _remoteDataSource.fetchTVSeriesByGenre(genreId);
    print(
      'Salvando ${remoteSeries.length} séries do gênero $genreId no banco local',
    );
    await _localDataSource!.saveTVSeries(remoteSeries);
  }
}
