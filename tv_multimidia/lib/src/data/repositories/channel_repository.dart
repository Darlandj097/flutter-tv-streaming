import 'package:flutter/foundation.dart' show kIsWeb;
import '../local/local_data_source.dart';
import '../remote/api_data_source.dart';
import '../models/channel.dart';

class ChannelRepository {
  final LocalDataSource? _localDataSource;
  final ApiDataSource? _apiDataSource;

  ChannelRepository(this._localDataSource, {ApiDataSource? apiDataSource})
    : _apiDataSource = apiDataSource;

  // Método de exibição (Leitura): Chamado pela camada BLoC/Riverpod para mostrar dados na UI
  Future<List<Channel>> getAllChannels() async {
    if (_apiDataSource != null) {
      return await _apiDataSource!.fetchChannels();
    } else if (_localDataSource != null) {
      return _localDataSource!.getAllChannels();
    }
    return []; // Retorna lista vazia se não houver fonte
  }

  // Método de carga (Sincronização): Para canais, pode ser carregado de um arquivo CSV local
  Future<void> syncChannels(List<Channel> channels) async {
    if (_localDataSource == null) return;
    await _localDataSource!.saveChannels(channels);
  }

  // Método para obter todas as categorias únicas
  Future<List<String>> getAllCategories() async {
    if (_apiDataSource != null) {
      return await _apiDataSource!.fetchChannelCategories();
    } else if (_localDataSource != null) {
      return _localDataSource!.getAllCategories();
    }
    return []; // Retorna lista vazia se não houver fonte
  }

  // Método para obter canais por categoria
  Future<List<Channel>> getChannelsByCategory(String category) async {
    if (_apiDataSource != null) {
      return await _apiDataSource!.fetchChannelsByCategory(category);
    } else if (_localDataSource != null) {
      return _localDataSource!.getChannelsByCategory(category);
    }
    return []; // Retorna lista vazia se não houver fonte
  }

  // Método para limpar todos os canais
  Future<void> clearAllChannels() async {
    if (_localDataSource == null) return;
    await _localDataSource!.deleteAllChannels();
  }
}
