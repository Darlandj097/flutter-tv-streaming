import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/repositories/movie_repository.dart';
import '../data/repositories/tv_series_repository.dart';
import '../data/models/movie.dart';
import '../data/models/tv_series.dart';
import '../data/remote/tmdb_data_source.dart';
import '../data/local/local_data_source.dart';
import 'detail_screen.dart';

class _SectionData {
  final String title;
  final List<dynamic> items;

  _SectionData(this.title, this.items);
}

class CatalogScreen extends StatefulWidget {
  final String type; // 'movies' or 'series'
  final MovieRepository movieRepository;
  final TVSeriesRepository tvSeriesRepository;

  const CatalogScreen({
    super.key,
    required this.type,
    required this.movieRepository,
    required this.tvSeriesRepository,
  });

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  List<Genre> _genres = [];
  Genre? _selectedGenre;
  List<dynamic> _items = [];
  List<dynamic> _filteredItems = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // Controle de foco para navegação por teclado
  FocusNode _searchFocusNode = FocusNode();
  List<FocusNode> _sidebarFocusNodes = [];
  List<FocusNode> _itemFocusNodes = [];
  int _currentSidebarIndex = 0;
  int _currentItemIndex = 0;

  // Itens da barra lateral (abas + gêneros)
  List<String> _sidebarItems = [];
  Map<String, int> _itemCounts = {};
  Map<int, List<dynamic>> _itemsByGenre = {};

  // IDs dos itens em listas
  Set<int> _myListIds = {};
  Set<int> _favoritesIds = {};

  @override
  void initState() {
    super.initState();
    _loadGenres();
    _initializeFocusNodes();
  }

  Future<void> _loadGenres() async {
    setState(() => _isLoading = true);

    try {
      final tmdbDataSource = TmdbDataSource();
      if (widget.type == 'movies') {
        _genres = await tmdbDataSource.fetchMovieGenres();
      } else {
        _genres = await tmdbDataSource.fetchTVGenres();
      }

      _initializeSidebarItems();

      // Carregar itens por gênero para calcular contadores
      for (final genre in _genres) {
        try {
          List<dynamic> items;
          if (widget.type == 'movies') {
            items = await widget.movieRepository.getMoviesByGenre(genre.id);
          } else {
            items = await widget.tvSeriesRepository.getTVSeriesByGenre(
              genre.id,
            );
          }
          if (items.isNotEmpty) {
            _itemsByGenre[genre.id] = items;
          }
        } catch (e) {
          // Ignorar erro para este gênero específico
        }
      }

      await _loadAllItems();
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    for (final node in _sidebarFocusNodes) {
      node.dispose();
    }
    for (final node in _itemFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _initializeFocusNodes() {
    _searchFocusNode = FocusNode();
    _sidebarFocusNodes = List.generate(
      50,
      (_) => FocusNode(),
    ); // Máximo de 50 itens na barra lateral (3 abas + 47 gêneros)
    _itemFocusNodes = List.generate(
      500,
      (_) => FocusNode(),
    ); // Máximo de 500 itens
  }

  void _initializeSidebarItems() {
    _sidebarItems = [
      'Todos',
      'Minha Lista',
      'Curtidas',
      ..._genres.map((genre) => genre.name),
    ];
    _calculateItemCounts();
    setState(() {}); // Forçar atualização da UI para mostrar os contadores
  }

  void _calculateItemCounts() async {
    _itemCounts = {};

    // Contar itens para "Todos"
    int totalCount = 0;
    for (final genre in _genres) {
      final items = _itemsByGenre[genre.id] ?? [];
      totalCount += items.length;
      _itemCounts[genre.name] = items.length;
    }
    _itemCounts['Todos'] = totalCount;

    // Contar itens para Minha Lista e Curtidas
    try {
      final localDataSource = LocalDataSource();
      if (widget.type == 'movies') {
        final myListMovies = await localDataSource.getMyListMovies();
        final favoriteMovies = await localDataSource.getFavoriteMovies();
        _itemCounts['Minha Lista'] = myListMovies.length;
        _itemCounts['Curtidas'] = favoriteMovies.length;
        _myListIds = myListMovies.map((m) => m.id).toSet();
        _favoritesIds = favoriteMovies.map((m) => m.id).toSet();
      } else {
        final myListSeries = await localDataSource.getMyListTVSeries();
        final favoriteSeries = await localDataSource.getFavoriteTVSeries();
        _itemCounts['Minha Lista'] = myListSeries.length;
        _itemCounts['Curtidas'] = favoriteSeries.length;
        _myListIds = myListSeries.map((s) => s.id).toSet();
        _favoritesIds = favoriteSeries.map((s) => s.id).toSet();
      }
    } catch (e) {
      print('Erro ao calcular contadores de listas: $e');
      _itemCounts['Minha Lista'] = 0;
      _itemCounts['Curtidas'] = 0;
      _myListIds = {};
      _favoritesIds = {};
    }
  }

  Future<void> _loadItemsByGenre(Genre genre) async {
    setState(() => _isLoading = true);

    try {
      if (widget.type == 'movies') {
        _items = await widget.movieRepository.getMoviesByGenre(genre.id);
      } else {
        _items = await widget.tvSeriesRepository.getTVSeriesByGenre(genre.id);
      }
      _filterItems();
    } catch (e) {
      _items = [];
      _filteredItems = [];
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredItems = _items);
    } else {
      final filtered = _items.where((item) {
        final title = item is Movie ? item.title : (item as TVSeries).name;
        return title.toLowerCase().contains(query);
      }).toList();
      setState(() => _filteredItems = filtered);
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
    } else if (_currentSidebarIndex > 0) {
      setState(() {
        _currentSidebarIndex--;
        _currentItemIndex = 0;
      });
      _onSidebarItemSelected(_currentSidebarIndex);
    }
  }

  void _navigateRight() {
    setState(() => _currentItemIndex++);
  }

  void _navigateUp() {
    if (_currentSidebarIndex > 0) {
      setState(() {
        _currentSidebarIndex--;
        _currentItemIndex = 0;
      });
      _onSidebarItemSelected(_currentSidebarIndex);
    } else {
      // Move focus to search
      _searchFocusNode.requestFocus();
    }
  }

  void _navigateDown() {
    if (_currentSidebarIndex < _sidebarItems.length - 1) {
      setState(() {
        _currentSidebarIndex++;
        _currentItemIndex = 0;
      });
      _onSidebarItemSelected(_currentSidebarIndex);
    }
  }

  void _onSidebarItemSelected(int index) {
    setState(() => _currentSidebarIndex = index);
    final item = _sidebarItems[index];
    if (item == 'Todos') {
      setState(() => _selectedGenre = null);
      _loadAllItems();
    } else if (item == 'Minha Lista') {
      setState(() => _selectedGenre = null);
      _loadMyList();
    } else if (item == 'Curtidas') {
      setState(() => _selectedGenre = null);
      _loadFavorites();
    } else {
      // It's a genre
      final genreIndex = index - 3; // Subtract 3 for the tabs
      if (genreIndex >= 0 && genreIndex < _genres.length) {
        final genre = _genres[genreIndex];
        setState(() => _selectedGenre = genre);
        _loadItemsByGenre(genre);
      }
    }
  }

  Future<void> _loadAllItems() async {
    setState(() => _isLoading = true);
    try {
      final allItems = <dynamic>[];
      for (final genre in _genres) {
        try {
          List<dynamic> items;
          if (widget.type == 'movies') {
            items = await widget.movieRepository.getMoviesByGenre(genre.id);
          } else {
            items = await widget.tvSeriesRepository.getTVSeriesByGenre(
              genre.id,
            );
          }
          allItems.addAll(items);
        } catch (e) {
          // Ignore errors for individual genres
        }
      }
      _items = allItems;
      _filterItems();
    } catch (e) {
      _items = [];
      _filteredItems = [];
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMyList() async {
    setState(() => _isLoading = true);
    try {
      final localDataSource = LocalDataSource();
      if (widget.type == 'movies') {
        _items = await localDataSource.getMyListMovies();
      } else {
        _items = await localDataSource.getMyListTVSeries();
      }
      _filterItems();
    } catch (e) {
      print('Erro ao carregar Minha Lista: $e');
      _items = [];
      _filteredItems = [];
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    try {
      final localDataSource = LocalDataSource();
      if (widget.type == 'movies') {
        _items = await localDataSource.getFavoriteMovies();
      } else {
        _items = await localDataSource.getFavoriteTVSeries();
      }
      _filterItems();
    } catch (e) {
      print('Erro ao carregar Curtidos: $e');
      _items = [];
      _filteredItems = [];
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _activateCurrentItem() {
    if (_searchFocusNode.hasFocus) {
      // Search is focused, do nothing special
    } else {
      // Sidebar item is focused, already handled by navigation
      // Item is focused, navigate to detail
      _navigateToItem();
    }
  }

  void _navigateToItem() {
    if (_currentItemIndex < _filteredItems.length) {
      final item = _filteredItems[_currentItemIndex];
      if (item is Movie || item is TVSeries) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailScreen(item: item)),
        );
      }
    }
  }

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.type == 'movies' ? 'Catálogo de Filmes' : 'Catálogo de Séries',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Focar no campo de busca
              _searchFocusNode.requestFocus();
            },
            tooltip: 'Buscar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FocusScope(
              autofocus: true,
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: _handleKeyEvent,
                child: Column(
                  children: [
                    // Barra de pesquisa
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Focus(
                        focusNode: _searchFocusNode,
                        child: Stack(
                          children: [
                            TextField(
                              controller: _searchController,
                              onChanged: (_) => _filterItems(),
                              style: const TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                hintText:
                                    'Buscar ${widget.type == 'movies' ? 'filmes' : 'séries'}...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty &&
                                _filteredItems.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 60),
                                constraints: const BoxConstraints(
                                  maxHeight: 300,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _filteredItems.length > 5
                                      ? 5
                                      : _filteredItems.length,
                                  itemBuilder: (context, index) {
                                    final item = _filteredItems[index];
                                    String title = '';
                                    String imageUrl = '';

                                    if (item is Movie) {
                                      title = item.title;
                                      imageUrl = item.posterPath.isNotEmpty
                                          ? 'https://image.tmdb.org/t/p/w92${item.posterPath}'
                                          : '';
                                    } else if (item is TVSeries) {
                                      title = item.name;
                                      imageUrl = item.posterPath.isNotEmpty
                                          ? 'https://image.tmdb.org/t/p/w92${item.posterPath}'
                                          : '';
                                    }

                                    return ListTile(
                                      leading: imageUrl.isNotEmpty
                                          ? Image.network(
                                              imageUrl,
                                              width: 40,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(
                                                    Icons.image,
                                                    size: 40,
                                                  ),
                                            )
                                          : const Icon(Icons.image, size: 40),
                                      title: Text(
                                        title,
                                        style: const TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                DetailScreen(item: item),
                                          ),
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

                    // Conteúdo principal
                    Expanded(
                      child: Row(
                        children: [
                          // Coluna esquerda - Itens da barra lateral
                          Container(
                            width: 200,
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: ListView.builder(
                              itemCount: _sidebarItems.length,
                              itemBuilder: (context, index) {
                                final item = _sidebarItems[index];
                                final isSelected =
                                    _currentSidebarIndex == index;
                                final isFocused = _currentSidebarIndex == index;

                                final count = _itemCounts[item] ?? 0;
                                final displayText = count > 0
                                    ? '$item ($count)'
                                    : item;

                                return Focus(
                                  focusNode: _sidebarFocusNodes[index],
                                  child: ListTile(
                                    title: Text(
                                      displayText,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isFocused
                                            ? Colors.blue
                                            : (isSelected
                                                  ? Theme.of(
                                                      context,
                                                    ).primaryColor
                                                  : null),
                                      ),
                                    ),
                                    selected: isSelected,
                                    tileColor: isFocused
                                        ? Colors.blue.withOpacity(0.1)
                                        : null,
                                    onTap: () => _onSidebarItemSelected(index),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Coluna direita - Catálogo
                          Expanded(child: _buildCatalog()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCatalog() {
    if (_filteredItems.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Text(
          'Nenhum ${widget.type == 'movies' ? 'filme' : 'série'} encontrado para "${_searchController.text}"',
        ),
      );
    }

    if (_items.isEmpty) {
      String message = '';
      final currentItem = _sidebarItems[_currentSidebarIndex];
      if (currentItem == 'Todos') {
        message =
            'Nenhum ${widget.type == 'movies' ? 'filme' : 'série'} encontrado';
      } else if (currentItem == 'Minha Lista') {
        message =
            'Sua lista está vazia. Adicione ${widget.type == 'movies' ? 'filmes' : 'séries'} à sua lista!';
      } else if (currentItem == 'Curtidas') {
        message =
            'Você ainda não curtiu nenhum ${widget.type == 'movies' ? 'filme' : 'série'}.';
      } else {
        // It's a genre
        message =
            'Nenhum ${widget.type == 'movies' ? 'filme' : 'série'} encontrado para o gênero $currentItem';
      }
      return Center(child: Text(message));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        final isFocused = _currentItemIndex == index;
        return Focus(
          focusNode: _itemFocusNodes[index],
          child: _buildItemCard(item, isFocused),
        );
      },
    );
  }

  Widget _buildItemCard(dynamic item, [bool isFocused = false]) {
    String title = '';
    String imageUrl = '';
    String backdropUrl = '';
    double voteAverage = 0.0;
    int itemId = 0;

    if (item is Movie) {
      title = item.title;
      imageUrl = item.posterPath.isNotEmpty
          ? 'https://image.tmdb.org/t/p/w200${item.posterPath}'
          : '';
      backdropUrl = item.backdropPath.isNotEmpty
          ? 'https://image.tmdb.org/t/p/w500${item.backdropPath}'
          : '';
      voteAverage = item.voteAverage;
      itemId = item.id;
    } else if (item is TVSeries) {
      title = item.name;
      imageUrl = item.posterPath.isNotEmpty
          ? 'https://image.tmdb.org/t/p/w200${item.posterPath}'
          : '';
      backdropUrl = item.backdropPath.isNotEmpty
          ? 'https://image.tmdb.org/t/p/w500${item.backdropPath}'
          : '';
      voteAverage = item.voteAverage;
      itemId = item.id;
    }

    // Usar backdrop se disponível, senão usar poster
    final displayImageUrl = backdropUrl.isNotEmpty ? backdropUrl : imageUrl;

    // Verificar se está em listas
    final isInMyList = _myListIds.contains(itemId);
    final isInFavorites = _favoritesIds.contains(itemId);

    return GestureDetector(
      onTap: () {
        if (item is Movie || item is TVSeries) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DetailScreen(item: item)),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isFocused ? Border.all(color: Colors.blue, width: 3) : null,
          image: displayImageUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(displayImageUrl),
                  fit: BoxFit.cover,
                )
              : null,
          color: Colors.grey[300],
        ),
        child: Stack(
          children: [
            if (displayImageUrl.isEmpty)
              const Center(child: Icon(Icons.image, size: 40)),
            // Indicador Minha Lista
            if (isInMyList)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 12),
                ),
              ),
            // Indicador Curtidas
            if (isInFavorites)
              Positioned(
                top: 8,
                left: isInMyList ? 32 : 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            if (voteAverage > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.yellow, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        voteAverage.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: isFocused ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
