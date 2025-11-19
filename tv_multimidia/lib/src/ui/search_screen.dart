import 'package:flutter/material.dart';
import '../data/repositories/movie_repository.dart';
import '../data/repositories/tv_series_repository.dart';
import '../data/repositories/channel_repository.dart';
import '../data/models/movie.dart';
import '../data/models/tv_series.dart';
import '../data/models/channel.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final MovieRepository movieRepository;
  final TVSeriesRepository tvSeriesRepository;
  final ChannelRepository channelRepository;

  const SearchScreen({
    super.key,
    required this.movieRepository,
    required this.tvSeriesRepository,
    required this.channelRepository,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Movie> _movies = [];
  List<TVSeries> _tvSeries = [];
  List<Channel> _channels = [];
  List<dynamic> _allItems = [];
  List<dynamic> _filteredItems = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllItems() async {
    setState(() => _isLoading = true);

    List<Movie> movies = [];
    List<TVSeries> tvSeries = [];
    List<Channel> channels = [];

    try {
      movies = await widget.movieRepository.getPopularMovies();
    } catch (e) {
      print('Erro ao carregar filmes: $e');
    }

    try {
      tvSeries = await widget.tvSeriesRepository.getTrendingTVSeries();
    } catch (e) {
      print('Erro ao carregar séries: $e');
    }

    try {
      channels = await widget.channelRepository.getAllChannels();
    } catch (e) {
      print('Erro ao carregar canais: $e');
    }

    setState(() {
      _movies = movies;
      _tvSeries = tvSeries;
      _channels = channels;
      _allItems = [...movies, ...tvSeries, ...channels];
      _filteredItems = _allItems;
      _isLoading = false;
    });
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredItems = _allItems);
    } else {
      final filtered = _allItems.where((item) {
        if (item is Movie) {
          return item.title.toLowerCase().contains(query) ||
              item.overview.toLowerCase().contains(query);
        } else if (item is TVSeries) {
          return item.name.toLowerCase().contains(query) ||
              item.overview.toLowerCase().contains(query);
        } else if (item is Channel) {
          return item.name.toLowerCase().contains(query) ||
              item.description.toLowerCase().contains(query);
        }
        return false;
      }).toList();
      setState(() => _filteredItems = filtered);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar'),
        backgroundColor: const Color(0xFF121212),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF121212), Color(0xFF0F0F0F)],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Stack(
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: (_) => _filterItems(),
                          autofocus: true,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Buscar filmes, séries ou canais...',
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
                        ),
                        if (_searchController.text.isNotEmpty &&
                            _filteredItems.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 60),
                            constraints: const BoxConstraints(maxHeight: 300),
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
                              itemCount: _filteredItems.length > 10
                                  ? 10
                                  : _filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = _filteredItems[index];
                                String title = '';
                                String imageUrl = '';
                                String type = '';

                                if (item is Movie) {
                                  title = item.title;
                                  imageUrl = item.posterPath.isNotEmpty
                                      ? 'https://image.tmdb.org/t/p/w92${item.posterPath}'
                                      : '';
                                  type = 'Filme';
                                } else if (item is TVSeries) {
                                  title = item.name;
                                  imageUrl = item.posterPath.isNotEmpty
                                      ? 'https://image.tmdb.org/t/p/w92${item.posterPath}'
                                      : '';
                                  type = 'Série';
                                } else if (item is Channel) {
                                  title = item.name;
                                  imageUrl = item.logoPath;
                                  type = 'Canal';
                                }

                                return ListTile(
                                  leading: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          width: 40,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.image,
                                                    size: 40,
                                                  ),
                                        )
                                      : const Icon(Icons.image, size: 40),
                                  title: Text(
                                    title,
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                  subtitle: Text(
                                    type,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  onTap: () {
                                    if (item is Movie || item is TVSeries) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              DetailScreen(item: item),
                                        ),
                                      );
                                    } else if (item is Channel) {
                                      // For channels, perhaps navigate back and select the channel
                                      // Or implement channel playback here
                                      Navigator.pop(context, item);
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _searchController.text.isEmpty
                        ? const Center(
                            child: Text(
                              'Digite para buscar',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        : _filteredItems.isEmpty
                        ? Center(
                            child: Text(
                              'Nenhum resultado para "${_searchController.text}"',
                              style: const TextStyle(color: Colors.white),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];
                              String title = '';
                              String imageUrl = '';
                              String type = '';
                              String subtitle = '';

                              if (item is Movie) {
                                title = item.title;
                                imageUrl = item.posterPath.isNotEmpty
                                    ? 'https://image.tmdb.org/t/p/w200${item.posterPath}'
                                    : '';
                                type = 'Filme';
                                subtitle = item.releaseDate.isNotEmpty
                                    ? item.releaseDate.substring(0, 4)
                                    : '';
                              } else if (item is TVSeries) {
                                title = item.name;
                                imageUrl = item.posterPath.isNotEmpty
                                    ? 'https://image.tmdb.org/t/p/w200${item.posterPath}'
                                    : '';
                                type = 'Série';
                                subtitle = item.firstAirDate.isNotEmpty
                                    ? item.firstAirDate.substring(0, 4)
                                    : '';
                              } else if (item is Channel) {
                                title = item.name;
                                imageUrl = item.logoPath;
                                type = 'Canal';
                                subtitle = item.category;
                              }

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          width: 50,
                                          height: 75,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.image,
                                                    size: 50,
                                                  ),
                                        )
                                      : const Icon(Icons.image, size: 50),
                                  title: Text(title),
                                  subtitle: Text('$type • $subtitle'),
                                  onTap: () {
                                    if (item is Movie || item is TVSeries) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              DetailScreen(item: item),
                                        ),
                                      );
                                    } else if (item is Channel) {
                                      Navigator.pop(context, item);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
