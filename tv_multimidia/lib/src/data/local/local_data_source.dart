import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/movie.dart';
import '../models/tv_series.dart';
import '../models/channel.dart';
import '../models/user.dart';
import '../models/user_list.dart';
import 'database_service.dart';

class LocalDataSource {
  Future<Database> get _database => DatabaseService.database;

  // Movies CRUD
  Future<List<Movie>> getMoviesByGenre(int genreId) async {
    print('[LocalDataSource] Buscando filmes por gênero: $genreId');
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'movies',
      where: 'genreIds LIKE ?',
      whereArgs: ['%$genreId%'],
    );
    print(
      '[LocalDataSource] Encontrados ${maps.length} filmes para gênero $genreId',
    );
    return List.generate(maps.length, (i) => Movie.fromMap(maps[i]));
  }

  Future<List<Movie>> getAllMovies() async {
    print('[LocalDataSource] Buscando todos os filmes');
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query('movies');
    print('[LocalDataSource] Encontrados ${maps.length} filmes no total');
    return List.generate(maps.length, (i) => Movie.fromMap(maps[i]));
  }

  Future<void> saveMovies(List<Movie> movies) async {
    final db = await _database;
    final batch = db.batch();
    for (final movie in movies) {
      batch.insert(
        'movies',
        movie.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteAllMovies() async {
    final db = await _database;
    await db.delete('movies');
  }

  // TV Series CRUD
  Future<List<TVSeries>> getTVSeriesByGenre(int genreId) async {
    print('[LocalDataSource] Buscando séries por gênero: $genreId');
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tv_series',
      where: 'genreIds LIKE ?',
      whereArgs: ['%$genreId%'],
    );
    print(
      '[LocalDataSource] Encontradas ${maps.length} séries para gênero $genreId',
    );
    return List.generate(maps.length, (i) => TVSeries.fromMap(maps[i]));
  }

  Future<List<TVSeries>> getAllTVSeries() async {
    print('[LocalDataSource] Buscando todas as séries');
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query('tv_series');
    print('[LocalDataSource] Encontradas ${maps.length} séries no total');
    return List.generate(maps.length, (i) => TVSeries.fromMap(maps[i]));
  }

  Future<void> saveTVSeries(List<TVSeries> series) async {
    final db = await _database;
    final batch = db.batch();
    for (final serie in series) {
      batch.insert(
        'tv_series',
        serie.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteAllTVSeries() async {
    final db = await _database;
    await db.delete('tv_series');
  }

  // Channels CRUD
  Future<List<Channel>> getAllChannels() async {
    print('[LocalDataSource] Buscando todos os canais');
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query('channels');
    print('[LocalDataSource] Encontrados ${maps.length} canais no total');
    return List.generate(maps.length, (i) => Channel.fromMap(maps[i]));
  }

  Future<void> saveChannels(List<Channel> channels) async {
    final db = await _database;
    final batch = db.batch();
    for (final channel in channels) {
      batch.insert(
        'channels',
        channel.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteAllChannels() async {
    final db = await _database;
    await db.delete('channels');
  }

  // Obter todas as categorias únicas
  Future<List<String>> getAllCategories() async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT DISTINCT category FROM channels ORDER BY category',
    );
    return result.map((row) => row['category'] as String).toList();
  }

  // Obter canais por categoria
  Future<List<Channel>> getChannelsByCategory(String category) async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'channels',
      where: 'category = ?',
      whereArgs: [category],
    );
    return List.generate(maps.length, (i) => Channel.fromMap(maps[i]));
  }

  // User CRUD
  Future<int> createUser(User user) async {
    final db = await _database;
    return await db.insert('users', {
      'name': user.name,
      'email': user.email,
      'password': user.password,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await _database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (result.isNotEmpty) {
      return User.fromJson(result.first);
    }
    return null;
  }

  Future<User?> getUserById(int id) async {
    final db = await _database;
    final result = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return User.fromJson(result.first);
    }
    return null;
  }

  Future<User?> authenticateUser(String email, String password) async {
    final db = await _database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (result.isNotEmpty) {
      return User.fromJson(result.first);
    }
    return null;
  }

  // User Lists CRUD
  Future<void> addToUserList(
    int userId,
    int itemId,
    String itemType,
    String listType,
  ) async {
    final db = await _database;
    await db.insert('user_lists', {
      'user_id': userId,
      'item_id': itemId,
      'item_type': itemType,
      'list_type': listType,
      'added_date': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeFromUserList(
    int userId,
    int itemId,
    String itemType,
    String listType,
  ) async {
    final db = await _database;
    await db.delete(
      'user_lists',
      where: 'user_id = ? AND item_id = ? AND item_type = ? AND list_type = ?',
      whereArgs: [userId, itemId, itemType, listType],
    );
  }

  Future<bool> isInUserList(
    int userId,
    int itemId,
    String itemType,
    String listType,
  ) async {
    final db = await _database;
    final result = await db.query(
      'user_lists',
      where: 'user_id = ? AND item_id = ? AND item_type = ? AND list_type = ?',
      whereArgs: [userId, itemId, itemType, listType],
    );
    return result.isNotEmpty;
  }

  Future<List<Movie>> getUserListMovies(int userId, String listType) async {
    final db = await _database;
    final userListItems = await db.query(
      'user_lists',
      where: 'user_id = ? AND item_type = ? AND list_type = ?',
      whereArgs: [userId, 'movie', listType],
      orderBy: 'added_date DESC',
    );

    final movies = <Movie>[];
    for (final item in userListItems) {
      final movieData = await db.query(
        'movies',
        where: 'id = ?',
        whereArgs: [item['item_id']],
      );
      if (movieData.isNotEmpty) {
        movies.add(Movie.fromMap(movieData.first));
      }
    }
    return movies;
  }

  Future<List<TVSeries>> getUserListTVSeries(
    int userId,
    String listType,
  ) async {
    final db = await _database;
    final userListItems = await db.query(
      'user_lists',
      where: 'user_id = ? AND item_type = ? AND list_type = ?',
      whereArgs: [userId, 'tv_series', listType],
      orderBy: 'added_date DESC',
    );

    final series = <TVSeries>[];
    for (final item in userListItems) {
      final seriesData = await db.query(
        'tv_series',
        where: 'id = ?',
        whereArgs: [item['item_id']],
      );
      if (seriesData.isNotEmpty) {
        series.add(TVSeries.fromMap(seriesData.first));
      }
    }
    return series;
  }

  // Legacy My List CRUD (for backward compatibility)
  Future<void> addToMyList(int itemId, String itemType) async {
    if (kIsWeb) return; // Not supported on web
    final db = await _database;
    await db.insert('my_list', {
      'item_id': itemId,
      'item_type': itemType,
      'added_date': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeFromMyList(int itemId, String itemType) async {
    if (kIsWeb) return; // Not supported on web
    final db = await _database;
    await db.delete(
      'my_list',
      where: 'item_id = ? AND item_type = ?',
      whereArgs: [itemId, itemType],
    );
  }

  Future<bool> isInMyList(int itemId, String itemType) async {
    if (kIsWeb) return false; // Not supported on web
    final db = await _database;
    final result = await db.query(
      'my_list',
      where: 'item_id = ? AND item_type = ?',
      whereArgs: [itemId, itemType],
    );
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getMyList() async {
    final db = await _database;
    return await db.query('my_list', orderBy: 'added_date DESC');
  }

  Future<List<Movie>> getMyListMovies() async {
    if (kIsWeb) return []; // Not supported on web
    final db = await _database;
    final myListItems = await db.query(
      'my_list',
      where: 'item_type = ?',
      whereArgs: ['movie'],
      orderBy: 'added_date DESC',
    );

    final movies = <Movie>[];
    for (final item in myListItems) {
      final movieData = await db.query(
        'movies',
        where: 'id = ?',
        whereArgs: [item['item_id']],
      );
      if (movieData.isNotEmpty) {
        movies.add(Movie.fromMap(movieData.first));
      }
    }
    return movies;
  }

  Future<List<TVSeries>> getMyListTVSeries() async {
    if (kIsWeb) return []; // Not supported on web
    final db = await _database;
    final myListItems = await db.query(
      'my_list',
      where: 'item_type = ?',
      whereArgs: ['tv_series'],
      orderBy: 'added_date DESC',
    );

    final series = <TVSeries>[];
    for (final item in myListItems) {
      final seriesData = await db.query(
        'tv_series',
        where: 'id = ?',
        whereArgs: [item['item_id']],
      );
      if (seriesData.isNotEmpty) {
        series.add(TVSeries.fromMap(seriesData.first));
      }
    }
    return series;
  }

  // Favorites CRUD (Legacy for backward compatibility)
  Future<void> addToFavorites(int itemId, String itemType) async {
    if (kIsWeb) return; // Not supported on web
    final db = await _database;
    await db.insert('favorites', {
      'item_id': itemId,
      'item_type': itemType,
      'added_date': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeFromFavorites(int itemId, String itemType) async {
    if (kIsWeb) return; // Not supported on web
    final db = await _database;
    await db.delete(
      'favorites',
      where: 'item_id = ? AND item_type = ?',
      whereArgs: [itemId, itemType],
    );
  }

  Future<bool> isInFavorites(int itemId, String itemType) async {
    if (kIsWeb) return false; // Not supported on web
    final db = await _database;
    final result = await db.query(
      'favorites',
      where: 'item_id = ? AND item_type = ?',
      whereArgs: [itemId, itemType],
    );
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    final db = await _database;
    return await db.query('favorites', orderBy: 'added_date DESC');
  }

  Future<List<Movie>> getFavoriteMovies() async {
    if (kIsWeb) return []; // Not supported on web
    final db = await _database;
    final favoriteItems = await db.query(
      'favorites',
      where: 'item_type = ?',
      whereArgs: ['movie'],
      orderBy: 'added_date DESC',
    );

    final movies = <Movie>[];
    for (final item in favoriteItems) {
      final movieData = await db.query(
        'movies',
        where: 'id = ?',
        whereArgs: [item['item_id']],
      );
      if (movieData.isNotEmpty) {
        movies.add(Movie.fromMap(movieData.first));
      }
    }
    return movies;
  }

  Future<List<TVSeries>> getFavoriteTVSeries() async {
    if (kIsWeb) return []; // Not supported on web
    final db = await _database;
    final favoriteItems = await db.query(
      'favorites',
      where: 'item_type = ?',
      whereArgs: ['tv_series'],
      orderBy: 'added_date DESC',
    );

    final series = <TVSeries>[];
    for (final item in favoriteItems) {
      final seriesData = await db.query(
        'tv_series',
        where: 'id = ?',
        whereArgs: [item['item_id']],
      );
      if (seriesData.isNotEmpty) {
        series.add(TVSeries.fromMap(seriesData.first));
      }
    }
    return series;
  }
}
