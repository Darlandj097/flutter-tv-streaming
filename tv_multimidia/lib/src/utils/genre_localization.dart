class GenreLocalization {
  static const Map<int, String> genreNames = {
    // Gêneros de filmes e séries
    28: 'Ação',
    12: 'Aventura',
    16: 'Animação',
    35: 'Comédia',
    80: 'Crime',
    99: 'Documentário',
    18: 'Drama',
    10751: 'Família',
    14: 'Fantasia',
    36: 'História',
    27: 'Terror',
    10402: 'Música',
    9648: 'Mistério',
    10749: 'Romance',
    878: 'Ficção Científica',
    10770: 'TV Movie',
    53: 'Thriller',
    10752: 'Guerra',
    37: 'Faroeste',
    10759: 'Ação e Aventura',
    10762: 'Infantil',
    10763: 'Notícias',
    10764: 'Reality',
    10765: 'Ficção Científica e Fantasia',
    10766: 'Soap Opera',
    10767: 'Talk Show',
    10768: 'Guerra e Política',
  };

  static String getGenreName(int genreId) {
    return genreNames[genreId] ?? 'Desconhecido';
  }

  static String getLocalizedGenreName(int genreId) {
    return getGenreName(genreId);
  }
}
