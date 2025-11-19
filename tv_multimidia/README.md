# TV Multimidia

Um aplicativo Flutter completo para streaming de conteúdo multimídia, oferecendo filmes, séries de TV e canais ao vivo em uma interface intuitiva e acessível.

## 📋 Sobre o Projeto

TV Multimidia é uma aplicação multiplataforma desenvolvida em Flutter que permite aos usuários explorar e assistir conteúdo multimídia de forma organizada. O aplicativo integra dados da API TMDB (The Movie Database) para fornecer informações atualizadas sobre filmes e séries, além de suportar canais de TV ao vivo através de feeds externos.

### ✨ Principais Funcionalidades

- **🎬 Catálogo de Filmes e Séries**: Navegue por filmes em alta, populares e organizados por gênero
- **📺 Canais ao Vivo**: Acesso a canais de TV ao vivo com logos e informações
- **👨‍👩‍👧‍👦 Conteúdo Infantil**: Seção dedicada com filmes e séries apropriados para crianças
- **🔍 Navegação Intuitiva**: Interface otimizada para navegação por teclado e controle remoto
- **🌐 Suporte Multiplataforma**: Compatível com Windows, Android, iOS, Web, Linux e macOS
- **💾 Armazenamento Local**: Dados armazenados localmente usando SQLite
- **🔄 Sincronização Automática**: Atualização automática de conteúdo via API TMDB
- **🌍 Localização**: Suporte completo ao português brasileiro
- **📱 Design Responsivo**: Interface adaptável a diferentes tamanhos de tela

## 🏗️ Arquitetura

O projeto segue uma arquitetura limpa com separação de responsabilidades:

- **Data Layer**: Repositórios, fontes de dados (local e remota) e modelos
- **Domain Layer**: Serviços de negócio (autenticação, sincronização)
- **Presentation Layer**: Telas, widgets e gerenciamento de estado
- **Utils**: Utilitários para localização, gerenciamento de controle remoto, etc.

### 📁 Estrutura de Pastas

```
lib/
├── src/
│   ├── data/
│   │   ├── local/          # Armazenamento local (SQLite)
│   │   ├── models/         # Modelos de dados (Movie, TVSeries, Channel)
│   │   ├── remote/         # Fontes de dados remotas (TMDB API)
│   │   └── repositories/   # Repositórios para acesso a dados
│   ├── services/           # Serviços de negócio
│   ├── ui/                 # Telas principais (Home, Detail, Settings)
│   ├── utils/              # Utilitários diversos
│   └── widgets/            # Widgets reutilizáveis
├── l10n/                   # Arquivos de localização
└── main.dart               # Ponto de entrada da aplicação
```

## 🚀 Instalação e Configuração

### Pré-requisitos

- Flutter SDK (versão 3.8.1 ou superior)
- Dart SDK
- Para desenvolvimento desktop: Visual Studio Build Tools (Windows) ou Xcode (macOS)

### Instalação

1. **Clone o repositório:**
   ```bash
   git clone <url-do-repositorio>
   cd tv_multimidia
   ```

2. **Configure as variáveis de ambiente:**
   ```bash
   # Copie o arquivo de exemplo
   cp .env.example .env

   # Edite o arquivo .env com suas configurações
   nano .env
   ```

   **Variáveis obrigatórias:**
   - `TMDB_API_KEY`: Chave da API TMDB (obtenha em https://www.themoviedb.org/settings/api)

3. **Instale as dependências:**
   ```bash
   flutter pub get
   ```

4. **Execute o aplicativo:**

   - **Para Windows:**
     ```bash
     flutter run -d windows
     ```

   - **Para Web:**
     ```bash
     flutter run -d chrome
     ```

   - **Para Android/iOS:**
     ```bash
     flutter run
     ```

### Configuração do Banco de Dados

O aplicativo utiliza um script Python auxiliar (`database.py`) para inicializar e popular o banco de dados SQLite:

```bash
python database.py
```

Este script:
- Cria todas as tabelas necessárias
- Sincroniza dados iniciais da API TMDB
- Carrega canais de TV do arquivo `logos.csv`

## 📊 Tecnologias Utilizadas

- **Framework**: Flutter
- **Linguagem**: Dart
- **Banco de Dados**: SQLite (sqflite, drift)
- **API Externa**: TMDB (The Movie Database)
- **HTTP Client**: Dart HTTP package
- **Serialização**: json_annotation, json_serializable
- **Internacionalização**: Flutter intl
- **Armazenamento**: shared_preferences, path_provider

## 🌐 API TMDB

O aplicativo integra com a API TMDB para obter dados de filmes e séries. A integração inclui:

- Filmes em alta (trending)
- Filmes populares
- Séries em alta e populares
- Busca por gênero
- Detalhes completos de séries (temporadas e episódios)
- Imagens (posters, backdrops)

### Configuração da API

1. **Obtenha uma chave da API TMDB:**
   - Acesse: https://www.themoviedb.org/settings/api
   - Crie uma conta gratuita
   - Gere uma chave de API (v4 auth - Bearer token)

2. **Configure a chave no arquivo `.env`:**
   ```bash
   TMDB_API_KEY=sua_chave_bearer_token_aqui
   ```

**Segurança**: A chave da API é carregada via variáveis de ambiente e nunca é commitada no código fonte.

## 🎮 Navegação e Controles

### Navegação por Teclado

O aplicativo suporta navegação completa por teclado, ideal para uso com controle remoto:

- **Setas**: Navegação entre itens e seções
- **Enter/Select**: Ativar item selecionado
- **Escape/Back**: Voltar
- **Tab**: Alternar entre abas

### Controles de Mídia

- Controle remoto virtual integrado
- Suporte a diferentes dispositivos de entrada
- Interface otimizada para TV

## 🌍 Localização

O aplicativo está completamente localizado para português brasileiro:

- Arquivos de localização: `lib/l10n/`
- Idiomas suportados: pt-BR, pt, en
- Localização de gêneros e categorias

## 📱 Plataformas Suportadas

- ✅ **Windows**: Desktop nativo
- ✅ **Android**: Mobile e TV
- ✅ **iOS**: Mobile e TV
- ✅ **Web**: Navegadores modernos
- ✅ **Linux**: Desktop
- ✅ **macOS**: Desktop

## 🔧 Desenvolvimento

### Scripts Auxiliares

- `database.py`: Script Python para gerenciamento do banco de dados
- `logos.csv`: Arquivo CSV com informações de canais de TV

### Geração de Código

O projeto utiliza build_runner para gerar código:

```bash
# Gerar serialização JSON
flutter pub run build_runner build

# Assistir mudanças
flutter pub run build_runner watch
```

### Testes

```bash
flutter test
```

## 📝 Licença

Este projeto é distribuído sob a licença MIT. Veja o arquivo LICENSE para mais detalhes.

## 🤝 Contribuição

Contribuições são bem-vindas! Por favor, leia as diretrizes de contribuição antes de submeter pull requests.

## 📞 Suporte

Para suporte ou dúvidas, entre em contato através das issues do repositório.

---

Desenvolvido com ❤️ usando Flutter
