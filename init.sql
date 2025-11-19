-- Script de inicialização do banco PostgreSQL para TV Multimidia

-- Criar tabelas
CREATE TABLE IF NOT EXISTS movies(
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    overview TEXT,
    posterPath TEXT,
    backdropPath TEXT,
    releaseDate DATE,
    voteAverage REAL,
    voteCount INTEGER,
    genreIds TEXT,
    adult BOOLEAN,
    originalLanguage TEXT,
    originalTitle TEXT,
    popularity REAL,
    video BOOLEAN,
    imageUrls TEXT
);

CREATE TABLE IF NOT EXISTS tv_series(
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    overview TEXT,
    posterPath TEXT,
    backdropPath TEXT,
    firstAirDate DATE,
    voteAverage REAL,
    voteCount INTEGER,
    genreIds TEXT,
    adult BOOLEAN,
    originalLanguage TEXT,
    originalName TEXT,
    popularity REAL,
    originCountry TEXT,
    imageUrls TEXT
);

CREATE TABLE IF NOT EXISTS channels(
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    logoPath TEXT,
    streamUrl TEXT,
    category TEXT,
    description TEXT,
    imageUrls TEXT
);

CREATE TABLE IF NOT EXISTS seasons(
    id SERIAL PRIMARY KEY,
    seriesId INTEGER NOT NULL REFERENCES tv_series(id),
    seasonNumber INTEGER NOT NULL,
    name TEXT,
    overview TEXT,
    airDate DATE,
    episodeCount INTEGER,
    posterPath TEXT,
    voteAverage REAL,
    imageUrls TEXT
);

CREATE TABLE IF NOT EXISTS episodes(
    id SERIAL PRIMARY KEY,
    seriesId INTEGER NOT NULL REFERENCES tv_series(id),
    seasonId INTEGER NOT NULL REFERENCES seasons(id),
    episodeNumber INTEGER NOT NULL,
    name TEXT,
    overview TEXT,
    airDate DATE,
    runtime INTEGER,
    stillPath TEXT,
    voteAverage REAL,
    voteCount INTEGER,
    imageUrls TEXT
);

CREATE TABLE IF NOT EXISTS sync_cache(
    key TEXT PRIMARY KEY,
    timestamp BIGINT,
    data TEXT
);

-- Índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_movies_title ON movies(title);
CREATE INDEX IF NOT EXISTS idx_tv_series_name ON tv_series(name);
CREATE INDEX IF NOT EXISTS idx_channels_name ON channels(name);
CREATE INDEX IF NOT EXISTS idx_seasons_series_id ON seasons(seriesId);
CREATE INDEX IF NOT EXISTS idx_episodes_series_id ON episodes(seriesId);
CREATE INDEX IF NOT EXISTS idx_episodes_season_id ON episodes(seasonId);