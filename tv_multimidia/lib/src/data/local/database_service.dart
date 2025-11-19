import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:postgres/postgres.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/movie.dart';
import '../models/tv_series.dart';
import '../models/channel.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'dadostv_v2.db';

  static Future<Database> get database async {
    if (_database != null) return _database!;

    if (kIsWeb) {
      // Para web, usar sqflite_common_ffi que suporta web
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      _database = await openDatabase(
        inMemoryDatabasePath,
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final path = join(dir.path, _dbName);

      _database = await openDatabase(
        path,
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }

    return _database!;
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // Add missing columns
      try {
        await db.execute('ALTER TABLE tv_series ADD COLUMN imageUrls TEXT');
      } catch (e) {
        // Column might already exist or table needs recreation
      }
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Tabela de filmes
    await db.execute('''
      CREATE TABLE movies(
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        overview TEXT,
        posterPath TEXT,
        backdropPath TEXT,
        releaseDate TEXT,
        voteAverage REAL,
        voteCount INTEGER,
        genreIds TEXT,
        adult INTEGER,
        originalLanguage TEXT,
        originalTitle TEXT,
        popularity REAL,
        video INTEGER,
        imageUrls TEXT
      )
    ''');

    // Tabela de séries
    await db.execute('''
      CREATE TABLE tv_series(
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        overview TEXT,
        posterPath TEXT,
        backdropPath TEXT,
        firstAirDate TEXT,
        voteAverage REAL,
        voteCount INTEGER,
        genreIds TEXT,
        adult INTEGER,
        originalLanguage TEXT,
        originalName TEXT,
        popularity REAL,
        originCountry TEXT,
        imageUrls TEXT
      )
    ''');

    // Tabela de canais
    await db.execute('''
      CREATE TABLE channels(
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        logoPath TEXT,
        streamUrl TEXT,
        category TEXT,
        description TEXT,
        imageUrls TEXT
      )
    ''');

    // Tabela de minha lista
    await db.execute('''
      CREATE TABLE my_list(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        item_type TEXT NOT NULL, -- 'movie' or 'tv_series'
        added_date TEXT NOT NULL,
        UNIQUE(item_id, item_type)
      )
    ''');

    // Tabela de curtidas
    await db.execute('''
      CREATE TABLE favorites(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        item_type TEXT NOT NULL, -- 'movie' or 'tv_series'
        added_date TEXT NOT NULL,
        user_id INTEGER, -- nullable for backward compatibility
        UNIQUE(item_id, item_type, user_id)
      )
    ''');

    // Tabela de usuários
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Tabela de listas do usuário (minha lista e curtidas)
    await db.execute('''
      CREATE TABLE user_lists(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        item_id INTEGER NOT NULL,
        item_type TEXT NOT NULL, -- 'movie' or 'tv_series'
        list_type TEXT NOT NULL, -- 'my_list' or 'favorites'
        added_date TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        UNIQUE(user_id, item_id, item_type, list_type)
      )
    ''');
  }

  static Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
