import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'src/data/local/database_service.dart';
import 'src/data/local/local_data_source.dart';
import 'src/data/remote/tmdb_data_source.dart';
import 'src/data/remote/api_data_source.dart';
import 'src/data/repositories/movie_repository.dart';
import 'src/data/repositories/tv_series_repository.dart';
import 'src/data/repositories/channel_repository.dart';
import 'src/services/sync_service.dart';
import 'src/services/auth_service.dart';
import 'src/ui/home_screen.dart';

/**
 * TV Multimidia - Aplicativo Flutter para streaming multimídia
 *
 * Este é o ponto de entrada principal da aplicação. Responsável por:
 * - Inicializar o framework Flutter
 * - Configurar o banco de dados SQLite (desktop/web)
 * - Injetar dependências (repositories, services)
 * - Executar sincronização inicial de dados
 * - Iniciar a interface do usuário
 *
 * Suporte multiplataforma: Windows, macOS, Linux, Android, iOS, Web
 */

/// Função principal da aplicação
///
/// Inicializa o Flutter e configura todas as dependências necessárias
/// para o funcionamento multiplataforma do TV Multimidia.
void main() async {
  // Garante que o Flutter esteja inicializado antes de qualquer operação assíncrona
  WidgetsFlutterBinding.ensureInitialized();

  // Configuração do SQLite para diferentes plataformas
  // Desktop (Windows/macOS/Linux): usa sqflite_ffi para acesso nativo ao SQLite
  // Web: usa sqflite_common_ffi_web para emulação via IndexedDB
  if (!kIsWeb) {
    // Para desktop, inicializar sqflite_ffi
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  } else {
    // Para web, inicializar sqflite_ffi_web
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiWeb;
  }

  // Inicialização das dependências da aplicação
  // Usa injeção de dependência para facilitar testes e manutenção
  LocalDataSource? localDataSource;
  AuthService? authService;
  ApiDataSource? apiDataSource;
  MovieRepository? movieRepository;
  TVSeriesRepository? tvSeriesRepository;
  ChannelRepository? channelRepository;
  SyncService? syncService;

  if (!kIsWeb) {
    // Configuração para plataformas desktop (Windows/macOS/Linux)
    // Usa SQLite local para armazenamento persistente
    await DatabaseService.database;

    // Inicializar camadas de dados locais
    localDataSource = LocalDataSource();
    authService = AuthService(localDataSource);
    final remoteDataSource = TmdbDataSource();

    // Inicializar repositórios com dados locais e remotos
    movieRepository = MovieRepository(localDataSource, remoteDataSource);
    tvSeriesRepository = TVSeriesRepository(localDataSource, remoteDataSource);
    channelRepository = ChannelRepository(
      localDataSource,
      apiDataSource: ApiDataSource(),
    );

    // Serviço de sincronização para manter dados atualizados
    syncService = SyncService(movieRepository, tvSeriesRepository);

    // Forçar sincronização inicial para garantir dados atualizados
    await syncService.forceSync();
  } else {
    // Configuração para plataforma web
    // Usa API REST que conecta ao PostgreSQL
    apiDataSource = ApiDataSource();
    movieRepository = MovieRepository(null, apiDataSource);
    tvSeriesRepository = TVSeriesRepository(null, apiDataSource);
    channelRepository = ChannelRepository(null, apiDataSource: apiDataSource);
    authService = AuthService(null, apiDataSource: apiDataSource);
    syncService = SyncService(
      movieRepository,
      tvSeriesRepository,
      apiDataSource: apiDataSource,
    );
  }

  runApp(
    MyApp(
      movieRepository: movieRepository!,
      tvSeriesRepository: tvSeriesRepository!,
      channelRepository: channelRepository!,
      syncService: syncService!,
      authService: authService,
      localDataSource: localDataSource,
      apiDataSource: apiDataSource,
    ),
  );
}

/**
 * Widget raiz da aplicação TV Multimidia
 *
 * Configura o MaterialApp com tema, localização e navegação principal.
 * Recebe todas as dependências injetadas via construtor para facilitar
 * testes e manutenção.
 */
class MyApp extends StatelessWidget {
  final MovieRepository movieRepository;
  final TVSeriesRepository tvSeriesRepository;
  final ChannelRepository channelRepository;
  final SyncService syncService;
  final AuthService? authService; // Opcional para web
  final LocalDataSource? localDataSource; // Opcional para web
  final ApiDataSource? apiDataSource; // Opcional para web

  const MyApp({
    super.key,
    required this.movieRepository,
    required this.tvSeriesRepository,
    required this.channelRepository,
    required this.syncService,
    this.authService,
    this.localDataSource,
    this.apiDataSource,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TV Multimidia',
      // Tema dark mode profissional inspirado em apps de streaming
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: Color(0xFFE50914), // Vermelho Netflix-like para seleção
          unselectedLabelColor: Color(0xFFB3B3B3),
          indicatorColor: Color(0xFFE50914),
          labelStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.normal,
            color: Color(0xFFE0E0E0),
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Color(0xFFB3B3B3),
          ),
          labelLarge: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE50914), // Vermelho Netflix
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE50914)),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF1E1E1E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF2A2A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide(color: Color(0xFF404040)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide(color: Color(0xFFE50914)),
          ),
          labelStyle: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFFB3B3B3),
          ),
          hintStyle: TextStyle(fontFamily: 'Poppins', color: Color(0xFF666666)),
        ),
      ),
      // Define português do Brasil como locale padrão
      locale: const Locale('pt', 'BR'),
      // Tela inicial com todas as dependências injetadas
      home: HomeScreen(
        movieRepository: movieRepository,
        tvSeriesRepository: tvSeriesRepository,
        channelRepository: channelRepository,
        syncService: syncService,
        authService: authService,
        localDataSource: localDataSource,
      ),
    );
  }
}
