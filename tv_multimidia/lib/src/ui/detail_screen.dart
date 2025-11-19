import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../data/models/movie.dart';
import '../data/models/tv_series.dart';
import '../data/remote/tmdb_data_source.dart';
import '../data/local/local_data_source.dart';
import '../data/local/database_service.dart';

class DetailScreen extends StatefulWidget {
  final dynamic item; // Movie or TVSeries

  const DetailScreen({super.key, required this.item});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  String title = '';
  String posterPath = '';
  String overview = '';
  String releaseDate = '';
  double voteAverage = 0.0;
  String backdropPath = '';
  bool isMovie = true;

  // Estados das listas
  bool isInMyList = false;
  bool isInFavorites = false;

  // Dados específicos para séries
  List<Map<String, dynamic>> seasons = [];
  List<Map<String, dynamic>> episodes = [];
  int selectedSeasonIndex = 0;
  int selectedEpisodeIndex = 0;
  bool isLoadingSeasons = false;
  bool isLoadingEpisodes = false;

  // Controle de foco para navegação por teclado
  late PageController _episodeController;
  FocusNode _detailFocusNode = FocusNode();
  FocusNode _playButtonFocusNode = FocusNode();
  FocusNode _myListButtonFocusNode = FocusNode();
  FocusNode _favoriteButtonFocusNode = FocusNode();
  List<FocusNode> _seasonFocusNodes = [];
  List<FocusNode> _episodeFocusNodes = [];

  @override
  void initState() {
    super.initState();
    _episodeController = PageController(
      viewportFraction: 0.85,
      initialPage: selectedEpisodeIndex,
    );
    _detailFocusNode = FocusNode();
    _playButtonFocusNode = FocusNode();
    _seasonFocusNodes = List.generate(
      20,
      (_) => FocusNode(),
    ); // Máximo 20 temporadas
    _episodeFocusNodes = List.generate(
      50,
      (_) => FocusNode(),
    ); // Máximo 50 episódios
    _initializeData();
  }

  @override
  void dispose() {
    _episodeController.dispose();
    _detailFocusNode.dispose();
    _playButtonFocusNode.dispose();
    _myListButtonFocusNode.dispose();
    _favoriteButtonFocusNode.dispose();
    _playButtonFocusNode.removeListener(_onFocusChange);
    _myListButtonFocusNode.removeListener(_onFocusChange);
    _favoriteButtonFocusNode.removeListener(_onFocusChange);
    for (final node in _seasonFocusNodes) {
      node.removeListener(_onFocusChange);
      node.dispose();
    }
    for (final node in _episodeFocusNodes) {
      node.removeListener(_onFocusChange);
      node.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {}); // Força rebuild para atualizar visual dos botões
  }

  void _initializeData() async {
    if (widget.item is Movie) {
      title = widget.item.title;
      posterPath = widget.item.posterPath;
      overview = widget.item.overview;
      releaseDate = widget.item.releaseDate;
      voteAverage = widget.item.voteAverage;
      backdropPath = posterPath;
      isMovie = true;
    } else if (widget.item is TVSeries) {
      title = widget.item.name;
      posterPath = widget.item.posterPath;
      overview = widget.item.overview;
      releaseDate = widget.item.firstAirDate;
      voteAverage = widget.item.voteAverage;
      backdropPath = posterPath;
      isMovie = false;

      // Carregar dados da série
      _loadSeriesData();
    }

    // Verificar status das listas
    await _checkListStatus();
  }

  Future<void> _loadSeriesData() async {
    if (isMovie) return;

    setState(() => isLoadingSeasons = true);

    try {
      final tmdbDataSource = TmdbDataSource();
      final seriesDetails = await tmdbDataSource.fetchTVSeriesDetails(
        widget.item.tmdbId,
      );

      final seasonsData = seriesDetails['seasons'] as List? ?? [];
      seasons = seasonsData
          .where(
            (season) => season['season_number'] > 0,
          ) // Excluir temporada especial (0)
          .map((season) => season as Map<String, dynamic>)
          .toList();

      if (seasons.isNotEmpty) {
        await _loadEpisodesForSeason(
          0,
        ); // Carregar primeira temporada por padrão
      }
    } catch (e) {
      print('Erro ao carregar dados da série: $e');
    } finally {
      setState(() => isLoadingSeasons = false);
    }
  }

  Future<void> _loadEpisodesForSeason(int seasonIndex) async {
    if (seasons.isEmpty || seasonIndex >= seasons.length) return;

    setState(() => isLoadingEpisodes = true);

    try {
      final season = seasons[seasonIndex];
      final seasonNumber = season['season_number'];
      final tmdbDataSource = TmdbDataSource();
      final seasonDetails = await tmdbDataSource.fetchSeasonDetails(
        widget.item.tmdbId,
        seasonNumber,
      );

      episodes = (seasonDetails['episodes'] as List? ?? [])
          .map((episode) => episode as Map<String, dynamic>)
          .toList();

      // Resetar seleção de episódio para o primeiro
      selectedEpisodeIndex = 0;
    } catch (e) {
      print('Erro ao carregar episódios: $e');
      episodes = [];
    } finally {
      setState(() => isLoadingEpisodes = false);
    }
  }

  Future<void> _checkListStatus() async {
    try {
      // Aguardar um pouco para garantir que o banco esteja inicializado
      await Future.delayed(const Duration(milliseconds: 100));

      final itemId = widget.item.id;
      final itemType = widget.item is Movie ? 'movie' : 'tv_series';

      // Verificar se está na minha lista
      final localDataSource = LocalDataSource();
      isInMyList = await localDataSource.isInMyList(itemId, itemType);
      isInFavorites = await localDataSource.isInFavorites(itemId, itemType);

      setState(() {});
    } catch (e) {
      print('Erro ao verificar status das listas: $e');
    }
  }

  Future<void> _toggleMyList() async {
    try {
      // Aguardar um pouco para garantir que o banco esteja inicializado
      await Future.delayed(const Duration(milliseconds: 100));

      final itemId = widget.item.id;
      final itemType = widget.item is Movie ? 'movie' : 'tv_series';

      final localDataSource = LocalDataSource();

      if (isInMyList) {
        await localDataSource.removeFromMyList(itemId, itemType);
        setState(() => isInMyList = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removido da Minha Lista')),
        );
      } else {
        await localDataSource.addToMyList(itemId, itemType);
        setState(() => isInMyList = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adicionado à Minha Lista')),
        );
      }
    } catch (e) {
      print('Erro ao alterar Minha Lista: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao alterar Minha Lista')),
      );
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      // Aguardar um pouco para garantir que o banco esteja inicializado
      await Future.delayed(const Duration(milliseconds: 100));

      final itemId = widget.item.id;
      final itemType = widget.item is Movie ? 'movie' : 'tv_series';

      final localDataSource = LocalDataSource();

      if (isInFavorites) {
        await localDataSource.removeFromFavorites(itemId, itemType);
        setState(() => isInFavorites = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Removido dos Curtidos')));
      } else {
        await localDataSource.addToFavorites(itemId, itemType);
        setState(() => isInFavorites = true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Curtido!')));
      }
    } catch (e) {
      print('Erro ao alterar Curtidos: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erro ao alterar Curtidos')));
    }
  }

  Future<List<Movie>> _getSimilarMovies() async {
    try {
      // Aguardar um pouco para garantir que o banco esteja inicializado
      await Future.delayed(const Duration(milliseconds: 100));

      final movie = widget.item as Movie;

      // Primeiro tentar buscar recomendações da TMDB (mais preciso)
      try {
        final tmdbDataSource = TmdbDataSource();
        final recommendations = await tmdbDataSource.fetchMovieRecommendations(
          movie.id,
        );
        if (recommendations.isNotEmpty) {
          return recommendations.take(10).toList();
        }
      } catch (e) {
        print('Erro ao buscar recomendações da TMDB: $e');
      }

      // Fallback: buscar filmes do mesmo gênero do banco local
      final localDataSource = LocalDataSource();
      final genreIds = movie.genreIds;

      if (genreIds.isEmpty) {
        return [];
      }

      // Pegar filmes do primeiro gênero
      final similarMovies = await localDataSource.getMoviesByGenre(
        genreIds.first,
      );

      // Filtrar o filme atual e limitar a 10 filmes
      return similarMovies.where((m) => m.id != movie.id).take(10).toList();
    } catch (e) {
      print('Erro ao buscar filmes similares: $e');
      return [];
    }
  }

  void _selectSeason(int seasonIndex) {
    if (seasonIndex != selectedSeasonIndex) {
      setState(() => selectedSeasonIndex = seasonIndex);
      _loadEpisodesForSeason(seasonIndex);
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
          Navigator.pop(context);
          break;
      }
    }
  }

  void _navigateLeft() {
    if (_playButtonFocusNode.hasFocus) {
      // Se estiver no botão reproduzir, vai para temporadas
      if (seasons.isNotEmpty) {
        _seasonFocusNodes[0].requestFocus();
      }
    } else if (_seasonFocusNodes.any((node) => node.hasFocus)) {
      // Navegar entre temporadas
      final currentIndex = _seasonFocusNodes.indexWhere(
        (node) => node.hasFocus,
      );
      if (currentIndex > 0) {
        _seasonFocusNodes[currentIndex - 1].requestFocus();
      }
    } else if (_episodeFocusNodes.any((node) => node.hasFocus)) {
      // Navegar entre episódios
      _navigateEpisode(-1);
    }
  }

  void _navigateRight() {
    if (_playButtonFocusNode.hasFocus) {
      // Se estiver no botão reproduzir, vai para temporadas
      if (seasons.isNotEmpty) {
        _seasonFocusNodes[0].requestFocus();
      }
    } else if (_seasonFocusNodes.any((node) => node.hasFocus)) {
      // Navegar entre temporadas
      final currentIndex = _seasonFocusNodes.indexWhere(
        (node) => node.hasFocus,
      );
      if (currentIndex < seasons.length - 1) {
        _seasonFocusNodes[currentIndex + 1].requestFocus();
      }
    } else if (_episodeFocusNodes.any((node) => node.hasFocus)) {
      // Navegar entre episódios
      _navigateEpisode(1);
    }
  }

  void _navigateUp() {
    if (_episodeFocusNodes.any((node) => node.hasFocus)) {
      // De episódios para temporadas
      if (seasons.isNotEmpty) {
        _seasonFocusNodes[selectedSeasonIndex].requestFocus();
      }
    } else if (_seasonFocusNodes.any((node) => node.hasFocus)) {
      // De temporadas para botão reproduzir
      _playButtonFocusNode.requestFocus();
    }
  }

  void _navigateDown() {
    if (_playButtonFocusNode.hasFocus) {
      // De botão reproduzir para temporadas
      if (seasons.isNotEmpty) {
        _seasonFocusNodes[selectedSeasonIndex].requestFocus();
      }
    } else if (_seasonFocusNodes.any((node) => node.hasFocus)) {
      // De temporadas para episódios
      if (episodes.isNotEmpty) {
        _episodeFocusNodes[selectedEpisodeIndex].requestFocus();
      }
    }
  }

  void _activateCurrentItem() {
    if (_playButtonFocusNode.hasFocus) {
      // Reproduzir filme/série
      _playContent();
    } else if (_seasonFocusNodes.any((node) => node.hasFocus)) {
      // Selecionar temporada
      final seasonIndex = _seasonFocusNodes.indexWhere((node) => node.hasFocus);
      if (seasonIndex >= 0 && seasonIndex < seasons.length) {
        _selectSeason(seasonIndex);
      }
    } else if (_episodeFocusNodes.any((node) => node.hasFocus)) {
      // Reproduzir episódio
      _playCurrentEpisode();
    }
  }

  void _playContent() {
    if (isMovie) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reprodução iniciada'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      // Para séries, reproduzir primeiro episódio da temporada selecionada
      _playCurrentEpisode();
    }
  }

  void _navigateEpisode(int direction) {
    if (episodes.isEmpty) return;

    int newIndex = selectedEpisodeIndex + direction;
    if (newIndex >= 0 && newIndex < episodes.length) {
      setState(() => selectedEpisodeIndex = newIndex);
      // Verificar se o controller está anexado antes de animar
      if (_episodeController.hasClients) {
        _episodeController.animateToPage(
          newIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _playCurrentEpisode() {
    if (episodes.isNotEmpty && selectedEpisodeIndex < episodes.length) {
      final episode = episodes[selectedEpisodeIndex];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reproduzindo: ${episode['name'] ?? 'Episódio ${selectedEpisodeIndex + 1}'}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título (já está na AppBar, mas pode ser repetido se necessário)
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 16),

        // Metadados
        Row(
          children: [
            // Avaliação
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.yellow[700],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    voteAverage.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Ano
            if (releaseDate.isNotEmpty)
              Text(
                releaseDate.split('-')[0], // Apenas o ano
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),

            const SizedBox(width: 16),

            // Tipo (Filme/Série)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isMovie ? 'Filme' : 'Série',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Descrição
        Text(
          overview.isNotEmpty ? overview : 'Descrição não disponível.',
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 32),

        // Botões de ação (Reproduzir, Minha Lista, Curtir)
        Row(
          children: [
            // Botão de Reproduzir
            Focus(
              focusNode: _playButtonFocusNode,
              child: ElevatedButton.icon(
                onPressed: () {
                  _playContent();
                },
                icon: const Icon(Icons.play_arrow, size: 24),
                label: const Text(
                  'Reproduzir',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _playButtonFocusNode.hasFocus
                      ? Colors.red
                      : Colors.white,
                  foregroundColor: _playButtonFocusNode.hasFocus
                      ? Colors.white
                      : Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: _playButtonFocusNode.hasFocus
                      ? const BorderSide(color: Colors.white, width: 2)
                      : null,
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Botão Minha Lista
            Focus(
              focusNode: _myListButtonFocusNode,
              child: IconButton(
                onPressed: _toggleMyList,
                icon: Icon(
                  isInMyList ? Icons.check : Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
                tooltip: isInMyList
                    ? 'Remover da Minha Lista'
                    : 'Adicionar à Minha Lista',
                style: IconButton.styleFrom(
                  backgroundColor: _myListButtonFocusNode.hasFocus
                      ? Colors.red
                      : (isInMyList ? Colors.red : Colors.grey[800]),
                  padding: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: _myListButtonFocusNode.hasFocus
                      ? const BorderSide(color: Colors.white, width: 2)
                      : null,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Botão Curtir
            Focus(
              focusNode: _favoriteButtonFocusNode,
              child: IconButton(
                onPressed: _toggleFavorite,
                icon: Icon(
                  isInFavorites ? Icons.thumb_up : Icons.thumb_up_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                tooltip: isInFavorites ? 'Remover dos Curtidos' : 'Curtir',
                style: IconButton.styleFrom(
                  backgroundColor: _favoriteButtonFocusNode.hasFocus
                      ? Colors.red
                      : (isInFavorites ? Colors.red : Colors.grey[800]),
                  padding: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: _favoriteButtonFocusNode.hasFocus
                      ? const BorderSide(color: Colors.white, width: 2)
                      : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: FocusScope(
        autofocus: true,
        child: KeyboardListener(
          focusNode: _detailFocusNode,
          onKeyEvent: _handleKeyEvent,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Layout responsivo: coluna em telas pequenas, linha em telas grandes
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWideScreen = constraints.maxWidth > 800;

                      return isWideScreen
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Lado esquerdo: Banner/Imagem
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    height: 400,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: posterPath.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(
                                                'https://image.tmdb.org/t/p/w500$posterPath',
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                      color: Colors.grey[900],
                                    ),
                                    child: posterPath.isEmpty
                                        ? const Center(
                                            child: Icon(
                                              Icons.image,
                                              size: 80,
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),

                                const SizedBox(width: 24),

                                // Lado direito: Informações
                                Expanded(flex: 2, child: _buildInfoSection()),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Banner/Imagem no topo
                                Container(
                                  height: 250,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: posterPath.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(
                                              'https://image.tmdb.org/t/p/w500$posterPath',
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                    color: Colors.grey[900],
                                  ),
                                  child: posterPath.isEmpty
                                      ? const Center(
                                          child: Icon(
                                            Icons.image,
                                            size: 60,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),

                                const SizedBox(height: 16),

                                // Informações abaixo
                                _buildInfoSection(),
                              ],
                            );
                    },
                  ),
                ),

                // Seções específicas para séries
                if (!isMovie) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Temporadas',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Lista de temporadas
                        isLoadingSeasons
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.red,
                                ),
                              )
                            : seasons.isEmpty
                            ? Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Nenhuma temporada encontrada',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              )
                            : SizedBox(
                                height: 60,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: seasons.length,
                                  itemBuilder: (context, index) {
                                    final season = seasons[index];
                                    final isSelected =
                                        index == selectedSeasonIndex;

                                    return Focus(
                                      focusNode: _seasonFocusNodes[index],
                                      child: GestureDetector(
                                        onTap: () => _selectSeason(index),
                                        child: Container(
                                          width: 120,
                                          margin: const EdgeInsets.only(
                                            right: 12,
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.red
                                                : (_seasonFocusNodes[index]
                                                          .hasFocus
                                                      ? Colors.red.withOpacity(
                                                          0.8,
                                                        )
                                                      : Colors.grey[800]),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color:
                                                  isSelected ||
                                                      _seasonFocusNodes[index]
                                                          .hasFocus
                                                  ? Colors.white
                                                  : Colors.grey[600]!,
                                              width: 2,
                                            ),
                                            boxShadow:
                                                _seasonFocusNodes[index]
                                                    .hasFocus
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.red
                                                          .withOpacity(0.3),
                                                      blurRadius: 8,
                                                      spreadRadius: 2,
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'T${season['season_number']}',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight:
                                                      isSelected ||
                                                          _seasonFocusNodes[index]
                                                              .hasFocus
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              if (season['episode_count'] !=
                                                  null)
                                                Text(
                                                  '${season['episode_count']} eps',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                        const SizedBox(height: 24),

                        const Text(
                          'Episódios',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Carrossel de episódios estilo Globoplay
                        isLoadingEpisodes
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.red,
                                ),
                              )
                            : episodes.isEmpty
                            ? Container(
                                height: 300,
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Nenhum episódio encontrado',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              )
                            : SizedBox(
                                height:
                                    320, // Altura aumentada para o efeito 3D
                                child: PageView.builder(
                                  controller: _episodeController,
                                  onPageChanged: (index) {
                                    setState(
                                      () => selectedEpisodeIndex = index,
                                    );
                                  },
                                  itemCount: episodes.length,
                                  itemBuilder: (context, index) {
                                    final episode = episodes[index];
                                    final isSelected =
                                        index == selectedEpisodeIndex;

                                    // Calcular a posição relativa para efeito 3D
                                    double scale = 1.0;
                                    double opacity = 1.0;
                                    double verticalOffset = 0.0;

                                    if (!isSelected) {
                                      // Episódios não selecionados ficam menores e mais opacos
                                      scale = 0.85;
                                      opacity = 0.7;
                                      verticalOffset = 20.0;
                                    }

                                    return Focus(
                                      focusNode: _episodeFocusNodes[index],
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                        transform: Matrix4.identity()
                                          ..scale(scale)
                                          ..translate(0.0, verticalOffset, 0.0),
                                        child: Opacity(
                                          opacity: opacity,
                                          child: Container(
                                            margin: EdgeInsets.symmetric(
                                              horizontal: isSelected ? 0 : 12,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: isSelected
                                                  ? [
                                                      BoxShadow(
                                                        color: Colors.red
                                                            .withOpacity(0.4),
                                                        blurRadius: 25,
                                                        spreadRadius: 8,
                                                        offset: const Offset(
                                                          0,
                                                          8,
                                                        ),
                                                      ),
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.3),
                                                        blurRadius: 15,
                                                        spreadRadius: 2,
                                                        offset: const Offset(
                                                          0,
                                                          4,
                                                        ),
                                                      ),
                                                    ]
                                                  : [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.2),
                                                        blurRadius: 10,
                                                        spreadRadius: 1,
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                      ),
                                                    ],
                                              border:
                                                  _episodeFocusNodes[index]
                                                      .hasFocus
                                                  ? Border.all(
                                                      color: Colors.white,
                                                      width: 3,
                                                    )
                                                  : null,
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: Stack(
                                                children: [
                                                  // Imagem de fundo do episódio
                                                  Container(
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                    decoration: BoxDecoration(
                                                      image:
                                                          episode['still_path'] !=
                                                              null
                                                          ? DecorationImage(
                                                              image: NetworkImage(
                                                                'https://image.tmdb.org/t/p/w500${episode['still_path']}',
                                                              ),
                                                              fit: BoxFit.cover,
                                                            )
                                                          : null,
                                                      color: Colors.grey[800],
                                                    ),
                                                    child:
                                                        episode['still_path'] ==
                                                            null
                                                        ? const Center(
                                                            child: Icon(
                                                              Icons.image,
                                                              size: 60,
                                                              color: Colors
                                                                  .white54,
                                                            ),
                                                          )
                                                        : null,
                                                  ),

                                                  // Gradiente escuro na parte inferior (mais intenso para episódios não selecionados)
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter,
                                                        colors: isSelected
                                                            ? [
                                                                Colors
                                                                    .transparent,
                                                                Colors.black
                                                                    .withOpacity(
                                                                      0.1,
                                                                    ),
                                                                Colors.black
                                                                    .withOpacity(
                                                                      0.4,
                                                                    ),
                                                                Colors.black
                                                                    .withOpacity(
                                                                      0.7,
                                                                    ),
                                                              ]
                                                            : [
                                                                Colors.black
                                                                    .withOpacity(
                                                                      0.2,
                                                                    ),
                                                                Colors.black
                                                                    .withOpacity(
                                                                      0.5,
                                                                    ),
                                                                Colors.black
                                                                    .withOpacity(
                                                                      0.7,
                                                                    ),
                                                                Colors.black
                                                                    .withOpacity(
                                                                      0.9,
                                                                    ),
                                                              ],
                                                        stops: const [
                                                          0.0,
                                                          0.5,
                                                          0.8,
                                                          1.0,
                                                        ],
                                                      ),
                                                    ),
                                                  ),

                                                  // Conteúdo do card
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          24,
                                                        ),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        // Número do episódio
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 14,
                                                                vertical: 8,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: isSelected
                                                                ? Colors.white
                                                                      .withOpacity(
                                                                        0.95,
                                                                      )
                                                                : Colors.white
                                                                      .withOpacity(
                                                                        0.8,
                                                                      ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  24,
                                                                ),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                      0.2,
                                                                    ),
                                                                blurRadius: 4,
                                                                offset:
                                                                    const Offset(
                                                                      0,
                                                                      2,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                          child: Text(
                                                            'EP ${episode['episode_number'] ?? index + 1}',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.black,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize:
                                                                  isSelected
                                                                  ? 14
                                                                  : 12,
                                                            ),
                                                          ),
                                                        ),

                                                        const SizedBox(
                                                          height: 16,
                                                        ),

                                                        // Título do episódio
                                                        Text(
                                                          episode['name'] ??
                                                              'Episódio ${index + 1}',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: isSelected
                                                                ? 24
                                                                : 20,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            shadows: const [
                                                              Shadow(
                                                                blurRadius: 6.0,
                                                                color: Colors
                                                                    .black,
                                                                offset: Offset(
                                                                  2.0,
                                                                  2.0,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),

                                                        const SizedBox(
                                                          height: 12,
                                                        ),

                                                        // Descrição
                                                        if (episode['overview'] !=
                                                                null &&
                                                            episode['overview']
                                                                .isNotEmpty)
                                                          Text(
                                                            episode['overview'],
                                                            maxLines: isSelected
                                                                ? 3
                                                                : 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize:
                                                                  isSelected
                                                                  ? 15
                                                                  : 13,
                                                              height: 1.4,
                                                              shadows: const [
                                                                Shadow(
                                                                  blurRadius:
                                                                      3.0,
                                                                  color: Colors
                                                                      .black,
                                                                  offset:
                                                                      Offset(
                                                                        1.0,
                                                                        1.0,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),

                                                        const SizedBox(
                                                          height: 16,
                                                        ),

                                                        // Data de exibição
                                                        if (episode['air_date'] !=
                                                            null)
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 6,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                    0.5,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              episode['air_date'],
                                                              style: const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ),

                                                        const SizedBox(
                                                          height: 20,
                                                        ),

                                                        // Botão de reproduzir
                                                        ElevatedButton.icon(
                                                          onPressed: () {
                                                            _playCurrentEpisode();
                                                          },
                                                          icon: const Icon(
                                                            Icons.play_arrow,
                                                            size: 20,
                                                          ),
                                                          label: const Text(
                                                            'Reproduzir',
                                                          ),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                isSelected
                                                                ? Colors.white
                                                                : Colors.white
                                                                      .withOpacity(
                                                                        0.9,
                                                                      ),
                                                            foregroundColor:
                                                                Colors.black,
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      24,
                                                                  vertical: 12,
                                                                ),
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                            ),
                                                            elevation:
                                                                isSelected
                                                                ? 8
                                                                : 4,
                                                            shadowColor: Colors
                                                                .black
                                                                .withOpacity(
                                                                  0.3,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                  // Indicador de seleção (só aparece no selecionado)
                                                  if (isSelected)
                                                    Positioned(
                                                      top: 20,
                                                      right: 20,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              10,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.red,
                                                          shape:
                                                              BoxShape.circle,
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.red
                                                                  .withOpacity(
                                                                    0.4,
                                                                  ),
                                                              blurRadius: 8,
                                                              spreadRadius: 2,
                                                            ),
                                                          ],
                                                        ),
                                                        child: const Icon(
                                                          Icons
                                                              .play_circle_filled,
                                                          color: Colors.white,
                                                          size: 28,
                                                        ),
                                                      ),
                                                    ),

                                                  // Overlay para episódios não selecionados
                                                  if (!isSelected)
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.black
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              16,
                                                            ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                        // Indicadores de página (dots)
                        if (episodes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                episodes.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  width: selectedEpisodeIndex == index ? 20 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: selectedEpisodeIndex == index
                                        ? Colors.red
                                        : Colors.grey[600],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                // Seções para filmes
                if (isMovie) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mais como este',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Lista de filmes similares
                        FutureBuilder<List<Movie>>(
                          future: _getSimilarMovies(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.red,
                                ),
                              );
                            } else if (snapshot.hasError) {
                              return Container(
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Erro ao carregar filmes similares',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              );
                            } else if (snapshot.hasData &&
                                snapshot.data!.isNotEmpty) {
                              return SizedBox(
                                height: 200,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: snapshot.data!.length,
                                  itemBuilder: (context, index) {
                                    final movie = snapshot.data![index];
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                DetailScreen(item: movie),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: 120,
                                        margin: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        child: Column(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  image:
                                                      movie
                                                          .posterPath
                                                          .isNotEmpty
                                                      ? DecorationImage(
                                                          image: NetworkImage(
                                                            'https://image.tmdb.org/t/p/w200${movie.posterPath}',
                                                          ),
                                                          fit: BoxFit.cover,
                                                        )
                                                      : null,
                                                  color: Colors.grey[800],
                                                ),
                                                child: movie.posterPath.isEmpty
                                                    ? const Icon(
                                                        Icons.image,
                                                        size: 40,
                                                        color: Colors.white54,
                                                      )
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              movie.title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            } else {
                              return Container(
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Nenhum filme similar encontrado',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
