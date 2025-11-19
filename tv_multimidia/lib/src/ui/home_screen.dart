import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import '../data/repositories/movie_repository.dart';
import '../data/repositories/tv_series_repository.dart';
import '../data/repositories/channel_repository.dart';
import '../services/sync_service.dart';
import '../services/auth_service.dart';
import '../data/local/local_data_source.dart';
import '../data/models/movie.dart';
import '../data/models/tv_series.dart';
import '../data/models/channel.dart';
import '../data/remote/tmdb_data_source.dart';
import '../data/remote/api_data_source.dart';
import 'catalog_screen.dart';
import 'detail_screen.dart';
import 'settings_screen.dart';
import 'search_screen.dart';

class _SectionData {
  final String title;
  final List<dynamic> items;

  _SectionData(this.title, this.items);
}

class MyApp extends StatelessWidget {
  final MovieRepository movieRepository;
  final TVSeriesRepository tvSeriesRepository;
  final ChannelRepository channelRepository;
  final SyncService syncService;
  final AuthService authService;
  final LocalDataSource localDataSource;

  const MyApp({
    super.key,
    required this.movieRepository,
    required this.tvSeriesRepository,
    required this.channelRepository,
    required this.syncService,
    required this.authService,
    required this.localDataSource,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TV Multimidia',
      theme: ThemeData(primarySwatch: Colors.blue),
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

class HomeScreen extends StatefulWidget {
  final MovieRepository movieRepository;
  final TVSeriesRepository tvSeriesRepository;
  final ChannelRepository channelRepository;
  final SyncService syncService;
  final AuthService? authService;
  final LocalDataSource? localDataSource;
  final ApiDataSource? apiDataSource;

  const HomeScreen({
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
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Movie> _trendingMovies = [];
  List<Movie> _popularMovies = [];
  List<TVSeries> _trendingTVSeries = [];
  List<Channel> _channels = [];
  List<Genre> _movieGenres = [];
  List<Genre> _tvGenres = [];
  Map<int, List<Movie>> _moviesByGenre = {};
  Map<int, List<TVSeries>> _tvSeriesByGenre = {};
  bool _isLoading = true;

  // Controle de foco para navegação por teclado
  FocusNode _tabFocusNode = FocusNode();
  FocusNode _syncFocusNode = FocusNode();
  List<FocusNode> _sectionFocusNodes = [];
  int _currentTabIndex = 0;
  int _currentSectionIndex = 0;
  int _currentItemIndex = 0;

  // Estado para TV ao Vivo
  String? _selectedCategory;
  Channel? _selectedChannel;
  VideoPlayerController? _videoController;
  String _searchQuery = '';
  List<Channel> _filteredChannels = [];
  Timer? _debounceTimer;
  late Future<List<String>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = widget.channelRepository.getAllCategories();
    _loadData();
    _initializeFocusNodes();
  }

  @override
  void dispose() {
    _tabFocusNode.dispose();
    _syncFocusNode.dispose();
    for (final node in _sectionFocusNodes) {
      node.dispose();
    }
    _videoController?.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _initializeFocusNodes() {
    _tabFocusNode = FocusNode();
    _syncFocusNode = FocusNode();
    _sectionFocusNodes = List.generate(
      50,
      (_) => FocusNode(),
    ); // Máximo de 50 seções para acomodar todos os gêneros
  }

  Future<List<Genre>> _getDefaultGenres() async {
    // Retornar gêneros padrão quando não conseguir carregar da API
    return [
      Genre(id: 28, name: 'Ação'),
      Genre(id: 12, name: 'Aventura'),
      Genre(id: 16, name: 'Animação'),
      Genre(id: 35, name: 'Comédia'),
      Genre(id: 80, name: 'Crime'),
      Genre(id: 99, name: 'Documentário'),
      Genre(id: 18, name: 'Drama'),
      Genre(id: 10751, name: 'Família'),
      Genre(id: 14, name: 'Fantasia'),
      Genre(id: 36, name: 'História'),
      Genre(id: 27, name: 'Terror'),
      Genre(id: 10402, name: 'Música'),
      Genre(id: 9648, name: 'Mistério'),
      Genre(id: 10749, name: 'Romance'),
      Genre(id: 878, name: 'Ficção Científica'),
      Genre(id: 10770, name: 'TV Movie'),
      Genre(id: 53, name: 'Thriller'),
      Genre(id: 10752, name: 'Guerra'),
      Genre(id: 37, name: 'Faroeste'),
    ];
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final trendingMovies = await widget.movieRepository.getTrendingMovies();
      final popularMovies = await widget.movieRepository.getPopularMovies();
      final trendingTVSeries = await widget.tvSeriesRepository
          .getTrendingTVSeries();
      // Forçar carregamento fresco dos canais - ignorar cache local
      final channels = await widget.channelRepository.getAllChannels();
      print('[HomeScreen] Carregados ${channels.length} canais da API');

      // Para desktop, salvar canais no banco local para ter categorias
      if (!kIsWeb) {
        await widget.channelRepository.clearAllChannels();
        await widget.channelRepository.syncChannels(channels);
        print('[HomeScreen] Canais salvos no banco local');
        // Recarregar categorias após salvar canais
        setState(() {
          _categoriesFuture = widget.channelRepository.getAllCategories();
        });
      }

      // Carregar gêneros - usar API para web, TMDB para desktop
      List<Genre> movieGenres = [];
      List<Genre> tvGenres = [];

      if (kIsWeb) {
        // Para web, usar gêneros padrão já que a API pode não ter endpoint de gêneros
        movieGenres = await _getDefaultGenres();
        tvGenres = await _getDefaultGenres();
      } else {
        // Para desktop, buscar do TMDB
        final tmdbDataSource = TmdbDataSource();
        movieGenres = await tmdbDataSource.fetchMovieGenres();
        tvGenres = await tmdbDataSource.fetchTVGenres();
      }

      // Carregar filmes e séries por gênero
      final moviesByGenre = <int, List<Movie>>{};
      final tvSeriesByGenre = <int, List<TVSeries>>{};

      for (final genre in movieGenres) {
        try {
          final movies = await widget.movieRepository.getMoviesByGenre(
            genre.id,
          );
          if (movies.isNotEmpty) {
            moviesByGenre[genre.id] = movies;
          }
        } catch (e) {
          print('Erro ao carregar filmes do gênero ${genre.name}: $e');
          // Mostrar erro na UI apenas se for web
          if (kIsWeb) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao carregar filmes de ${genre.name}'),
              ),
            );
          }
        }
      }

      for (final genre in tvGenres) {
        try {
          final series = await widget.tvSeriesRepository.getTVSeriesByGenre(
            genre.id,
          );
          if (series.isNotEmpty) {
            tvSeriesByGenre[genre.id] = series;
          }
        } catch (e) {
          print('Erro ao carregar séries do gênero ${genre.name}: $e');
          // Mostrar erro na UI apenas se for web
          if (kIsWeb) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao carregar séries de ${genre.name}'),
              ),
            );
          }
        }
      }

      setState(() {
        _trendingMovies = trendingMovies;
        _popularMovies = popularMovies;
        _trendingTVSeries = trendingTVSeries;
        _channels = channels;
        _movieGenres = movieGenres;
        _tvGenres = tvGenres;
        _moviesByGenre = moviesByGenre;
        _tvSeriesByGenre = tvSeriesByGenre;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
    }
  }

  Future<void> _syncData() async {
    try {
      await widget.syncService.forceSync();
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados sincronizados com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro na sincronização: $e')));
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
          _navigateLeft();
          break;
        case LogicalKeyboardKey.arrowRight:
          _navigateRight();
          break;
        case LogicalKeyboardKey.arrowUp:
          _navigateUp();
          break;
        case LogicalKeyboardKey.arrowDown:
          _navigateDown();
          break;
        case LogicalKeyboardKey.enter:
        case LogicalKeyboardKey.select:
          _activateCurrentItem();
          break;
        case LogicalKeyboardKey.escape:
        case LogicalKeyboardKey.goBack:
          _goBack();
          break;
      }
    }
  }

  void _navigateLeft() {
    if (_currentItemIndex > 0) {
      setState(() => _currentItemIndex--);
    } else if (_currentSectionIndex > 0) {
      setState(() {
        _currentSectionIndex--;
        _currentItemIndex = 0; // Reset to first item in new section
      });
    }
  }

  void _navigateRight() {
    // This will be implemented based on the current section's item count
    setState(() => _currentItemIndex++);
  }

  void _navigateUp() {
    if (_currentSectionIndex > 0) {
      setState(() {
        _currentSectionIndex--;
        _currentItemIndex = 0;
      });
    } else {
      // Move focus to tabs
      _tabFocusNode.requestFocus();
    }
  }

  void _navigateDown() {
    setState(() {
      _currentSectionIndex++;
      _currentItemIndex = 0;
    });
  }

  void _activateCurrentItem() {
    // Implement activation logic based on current focus
    if (_tabFocusNode.hasFocus) {
      // Tab is focused, switch to that tab
      final tabController = DefaultTabController.maybeOf(context);
      if (tabController != null) {
        tabController.animateTo(_currentTabIndex);
      }
    } else if (_syncFocusNode.hasFocus) {
      _syncData();
    } else {
      // Section item is focused, navigate to catalog or play content
      _navigateToItem();
    }
  }

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _navigateToItem() {
    // Implement navigation to catalog or content playback
    final sections = _getCurrentTabSections();
    if (_currentSectionIndex < sections.length) {
      final section = sections[_currentSectionIndex];
      if (section.title.contains('Filmes de') ||
          section.title.contains('Séries de')) {
        final type = section.title.contains('Filmes') ? 'movies' : 'series';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CatalogScreen(
              type: type,
              movieRepository: widget.movieRepository,
              tvSeriesRepository: widget.tvSeriesRepository,
            ),
          ),
        );
      }
    }
  }

  List<_SectionData> _getCurrentTabSections() {
    switch (_currentTabIndex) {
      case 0:
        return [_SectionData('Canais ao Vivo', _channels)];
      case 1:
        final sections = [
          _SectionData('Séries em Alta', _trendingTVSeries),
          _SectionData('Séries Populares', _trendingTVSeries.take(20).toList()),
        ];
        for (final genre in _tvGenres) {
          final series = _tvSeriesByGenre[genre.id] ?? [];
          if (series.isNotEmpty) {
            sections.add(_SectionData('Séries de ${genre.name}', series));
          }
        }
        return sections;
      case 2:
        final sections = [
          _SectionData('Filmes em Alta', _trendingMovies),
          _SectionData('Filmes Populares', _popularMovies),
        ];
        for (final genre in _movieGenres) {
          final movies = _moviesByGenre[genre.id] ?? [];
          if (movies.isNotEmpty) {
            sections.add(_SectionData('Filmes de ${genre.name}', movies));
          }
        }
        return sections;
      case 3:
        return [
          _SectionData('Filmes Infantis', _moviesByGenre[10751] ?? []),
          _SectionData('Séries Infantis', _tvSeriesByGenre[10751] ?? []),
          _SectionData('Animações', _moviesByGenre[16] ?? []),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE50914),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.tv, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'TV Multimidia',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          // Search button
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 28),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(
                    movieRepository: widget.movieRepository,
                    tvSeriesRepository: widget.tvSeriesRepository,
                    channelRepository: widget.channelRepository,
                  ),
                ),
              );
              if (result is Channel) {
                setState(() {
                  _selectedChannel = result;
                  _playChannel(result);
                });
              }
            },
            tooltip: 'Buscar',
          ),

          // Profile/Settings button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE50914), width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
            onPressed: () {
              if (widget.authService != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      authService: widget.authService!,
                      localDataSource: widget.localDataSource,
                      apiDataSource: widget.apiDataSource,
                    ),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SettingsScreen(apiDataSource: widget.apiDataSource),
                  ),
                );
              }
            },
            tooltip: 'Perfil',
          ),

          // Sync button
          Focus(
            focusNode: _syncFocusNode,
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
              onPressed: () => _loadData(),
              focusColor: const Color(0xFFE50914).withOpacity(0.3),
              tooltip: 'Atualizar',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF121212), Color(0xFF0F0F0F)],
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFE50914),
                        ),
                        strokeWidth: 3,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Carregando conteúdo...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF121212), Color(0xFF0F0F0F)],
                ),
              ),
              child: FocusScope(
                autofocus: true,
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: _handleKeyEvent,
                  child: DefaultTabController(
                    length: 4,
                    child: Column(
                      children: [
                        // Tab Bar with modern styling
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Focus(
                            focusNode: _tabFocusNode,
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TabBar(
                                tabs: const [
                                  Tab(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        'TV ao Vivo',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Tab(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        'Séries',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Tab(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        'Filmes',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Tab(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        'Infantil',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                onTap: (index) {
                                  setState(() => _currentTabIndex = index);
                                },
                                indicator: BoxDecoration(
                                  color: const Color(0xFFE50914),
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFE50914,
                                      ).withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                indicatorSize: TabBarIndicatorSize.tab,
                                labelColor: Colors.white,
                                unselectedLabelColor: const Color(0xFFB3B3B3),
                                dividerColor: Colors.transparent,
                                padding: EdgeInsets.zero,
                                labelPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),

                        // Content Area
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildTVLiveTab(),
                              _buildSeriesTab(),
                              _buildMoviesTab(),
                              _buildKidsTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<dynamic> items, int sectionIndex) {
    final isFocused = _currentSectionIndex == sectionIndex;
    final isClickable =
        title.contains('Filmes de') || title.contains('Séries de');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              // Section Title
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              // "Ver Tudo" button for clickable sections
              if (isClickable)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      final type = title.contains('Filmes')
                          ? 'movies'
                          : 'series';
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CatalogScreen(
                            type: type,
                            movieRepository: widget.movieRepository,
                            tvSeriesRepository: widget.tvSeriesRepository,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE50914),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Ver Tudo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Items List
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            padding: const EdgeInsets.only(bottom: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              final isItemFocused = isFocused && _currentItemIndex == index;
              return Focus(
                autofocus: isItemFocused,
                child: _buildItemCard(item, isItemFocused),
              );
            },
          ),
        ),

        // Bottom spacing
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTVLiveTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildTVLiveColumns()],
      ),
    );
  }

  Widget _buildSeriesTab() {
    int sectionIndex = 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._tvGenres.map((genre) {
            final series = _tvSeriesByGenre[genre.id] ?? [];
            if (series.isEmpty) return const SizedBox.shrink();
            return _buildSection(
              'Séries de ${genre.name}',
              series,
              sectionIndex++,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMoviesTab() {
    int sectionIndex = 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._movieGenres.map((genre) {
            final movies = _moviesByGenre[genre.id] ?? [];
            if (movies.isEmpty) return const SizedBox.shrink();
            return _buildSection(
              'Filmes de ${genre.name}',
              movies,
              sectionIndex++,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildKidsTab() {
    int sectionIndex = 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            'Filmes Infantis',
            _moviesByGenre[10751] ?? [],
            sectionIndex++,
          ),
          _buildSection(
            'Séries Infantis',
            _tvSeriesByGenre[10751] ?? [],
            sectionIndex++,
          ),
          _buildSection('Animações', _moviesByGenre[16] ?? [], sectionIndex++),
        ],
      ),
    );
  }

  Widget _buildTVLiveColumns() {
    return FutureBuilder<List<String>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erro ao carregar categorias: ${snapshot.error}'),
          );
        }

        final categories = snapshot.data ?? [];
        if (categories.isEmpty) {
          return const Center(child: Text('Nenhuma categoria encontrada'));
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coluna da esquerda: Categorias
            Expanded(
              flex: 1,
              child: Container(
                height: MediaQuery.of(context).size.height - 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Categorias',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Opção "Todos" acima da lista de categorias
                    ListTile(
                      title: const Text(
                        'Todos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedCategory = null; // null significa "Todos"
                          _searchQuery = ''; // Limpar busca ao mudar categoria
                        });
                      },
                      selected: _selectedCategory == null,
                      selectedTileColor: Colors.blue.shade50,
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return ListTile(
                            title: Text(category),
                            onTap: () {
                              setState(() {
                                _selectedCategory = category;
                                _searchQuery =
                                    ''; // Limpar busca ao mudar categoria
                              });
                            },
                            selected: _selectedCategory == category,
                            selectedTileColor: Colors.blue.shade50,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Coluna do meio: Canais da categoria selecionada
            Expanded(
              flex: 2,
              child: Container(
                height: MediaQuery.of(context).size.height - 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedCategory != null
                                ? 'Canais: $_selectedCategory'
                                : 'Todos os Canais',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Campo de busca
                          Stack(
                            children: [
                              TextField(
                                style: const TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  hintText: 'Buscar canais...',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                // O CÓDIGO CORRIGIDO (COM DEBOUNCE)
                                onChanged: (value) {
                                  // Cancela o timer anterior se ele estiver ativo
                                  if (_debounceTimer?.isActive ?? false)
                                    _debounceTimer!.cancel();

                                  // Cria um novo timer de 500ms
                                  _debounceTimer = Timer(
                                    const Duration(milliseconds: 500),
                                    () {
                                      // Este código só roda 500ms DEPOIS que o usuário parar de digitar
                                      print(
                                        '[DEBUG] Executando busca por: $value',
                                      );
                                      setState(() {
                                        _searchQuery = value.toLowerCase();
                                      });
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          // Filtrar canais baseado na categoria selecionada
                          final categoryFilteredChannels =
                              _selectedCategory != null
                              ? _channels
                                    .where(
                                      (channel) =>
                                          channel.category == _selectedCategory,
                                    )
                                    .toList()
                              : _channels;

                          // Filtrar canais baseado na busca
                          final filteredChannels = _searchQuery.isEmpty
                              ? categoryFilteredChannels
                              : categoryFilteredChannels
                                    .where(
                                      (channel) =>
                                          channel.name.toLowerCase().contains(
                                            _searchQuery,
                                          ) ||
                                          channel.description
                                              .toLowerCase()
                                              .contains(_searchQuery),
                                    )
                                    .toList();

                          if (filteredChannels.isEmpty) {
                            return const Center(
                              child: Text(
                                'Nenhum canal encontrado nesta categoria',
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: filteredChannels.length,
                            itemBuilder: (context, index) {
                              final channel = filteredChannels[index];
                              print(
                                '[DEBUG] Carregando canal: ${channel.name}, logoPath: "${channel.logoPath}"',
                              );
                              return ListTile(
                                leading: channel.logoPath.isNotEmpty
                                    ? Image.network(
                                        channel.logoPath,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return const SizedBox(
                                                width: 40,
                                                height: 40,
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              );
                                            },
                                        errorBuilder: (context, error, stackTrace) {
                                          print(
                                            '[DEBUG] Erro ao carregar logo para ${channel.name}: $error',
                                          );
                                          return const Icon(Icons.tv, size: 40);
                                        },
                                      )
                                    : const Icon(Icons.tv, size: 40),
                                title: Text(channel.name),
                                subtitle: Text(channel.description),
                                onTap: () {
                                  setState(() {
                                    _selectedChannel = channel;
                                    // Reproduzir automaticamente ao clicar
                                    _playChannel(channel);
                                  });
                                },
                                selected: _selectedChannel?.id == channel.id,
                                selectedTileColor: Colors.green.shade50,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Coluna da direita: Player de vídeo - maior e responsivo
            Expanded(
              flex: 3, // Aumentado de 2 para 3 para ser maior
              child: Container(
                height: MediaQuery.of(context).size.height - 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _selectedChannel != null
                    ? _buildVideoPlayer(_selectedChannel!)
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Selecione um canal para reproduzir',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVideoPlayer(Channel channel) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categoria
          Text(
            'Categoria: ${channel.category}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          // Canal
          Text(
            'Canal: ${channel.name}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          // Label "Reproduzindo" e nome do canal
          Text(
            'Reproduzindo: ${channel.name}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // Área do player de vídeo - maior e responsivo
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  _playChannel(channel), // Clique simples para reproduzir
              onDoubleTap: () =>
                  _toggleFullScreen(channel), // Duplo clique para tela cheia
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade600, width: 1),
                ),
                child:
                    _videoController != null &&
                        _videoController!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.tv, size: 80, color: Colors.white70),
                            SizedBox(height: 16),
                            Text(
                              'Clique para reproduzir\nDuplo clique para tela cheia',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _playChannel(Channel channel) async {
    try {
      // Dispose do controller anterior
      await _videoController?.dispose();

      // Criar novo controller
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(channel.streamUrl),
      );

      // Inicializar o controller
      await _videoController!.initialize();

      // Iniciar reprodução
      await _videoController!.play();

      // Atualizar UI
      setState(() {});

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Reproduzindo: ${channel.name}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao reproduzir: $e')));
    }
  }

  void _toggleFullScreen(Channel channel) {
    // Implementar tela cheia - para web, podemos usar fullscreen API
    if (kIsWeb) {
      // Para web, usar Fullscreen API
      // Note: Isso requer implementação específica para Flutter web
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Modo tela cheia não implementado para web'),
        ),
      );
    } else {
      // Para mobile/desktop, implementar navegação para tela cheia
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modo tela cheia não implementado')),
      );
    }
  }

  Widget _buildItemCard(dynamic item, [bool isFocused = false]) {
    String title = '';
    String imageUrl = '';
    double voteAverage = 0.0;
    String year = '';
    String genre = '';

    if (item is Movie) {
      title = item.title;
      imageUrl = item.posterPath.isNotEmpty
          ? 'https://image.tmdb.org/t/p/w300${item.posterPath}'
          : '';
      voteAverage = item.voteAverage;
      year = item.releaseDate.isNotEmpty
          ? item.releaseDate.substring(0, 4)
          : '';
      genre = item.genreIds.isNotEmpty ? item.genreIds[0].toString() : '';
    } else if (item is TVSeries) {
      title = item.name;
      imageUrl = item.posterPath.isNotEmpty
          ? 'https://image.tmdb.org/t/p/w300${item.posterPath}'
          : '';
      voteAverage = item.voteAverage;
      year = item.firstAirDate.isNotEmpty
          ? item.firstAirDate.substring(0, 4)
          : '';
      genre = item.genreIds.isNotEmpty ? item.genreIds[0].toString() : '';
    } else if (item is Channel) {
      title = item.name;
      imageUrl = item.logoPath;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (item is Movie || item is TVSeries) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DetailScreen(item: item)),
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 160,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xFFE50914).withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                // Background image
                Container(
                  height: 240,
                  decoration: BoxDecoration(
                    image: imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: const Color(0xFF2A2A2A),
                  ),
                  child: imageUrl.isEmpty
                      ? const Icon(
                          Icons.image,
                          size: 60,
                          color: Color(0xFF666666),
                        )
                      : null,
                ),

                // Gradient overlay
                Container(
                  height: 240,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.0, 0.5, 0.7, 0.9, 1.0],
                    ),
                  ),
                ),

                // Rating badge
                if (voteAverage > 0)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE50914),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            voteAverage.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Content info at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        if (year.isNotEmpty || genre.isNotEmpty)
                          const SizedBox(height: 4),
                        if (year.isNotEmpty || genre.isNotEmpty)
                          Text(
                            [
                              if (year.isNotEmpty) year,
                              if (genre.isNotEmpty) genre,
                            ].join(' • '),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB3B3B3),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Focus indicator
                if (isFocused)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFE50914),
                        width: 3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
