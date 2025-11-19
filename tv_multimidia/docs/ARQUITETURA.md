# Arquitetura e Estrutura de Pastas

## Visão Geral da Arquitetura

O projeto TV Multimidia segue uma arquitetura limpa (Clean Architecture) com separação clara de responsabilidades, organizada em camadas bem definidas. Esta abordagem facilita a manutenção, testabilidade e escalabilidade do código.

## Estrutura de Pastas

```
tv_multimidia/
├── lib/
│   ├── src/
│   │   ├── data/
│   │   │   ├── local/              # Camada de dados locais
│   │   │   │   ├── database_service.dart    # Serviço de banco de dados
│   │   │   │   └── local_data_source.dart   # Fonte de dados local
│   │   │   ├── models/             # Modelos de dados
│   │   │   │   ├── movie.dart              # Modelo Movie
│   │   │   │   ├── tv_series.dart          # Modelo TVSeries
│   │   │   │   ├── channel.dart            # Modelo Channel
│   │   │   │   ├── user.dart               # Modelo User
│   │   │   │   ├── user_list.dart          # Modelo UserList
│   │   │   │   ├── movie.g.dart            # Código gerado para Movie
│   │   │   │   ├── tv_series.g.dart        # Código gerado para TVSeries
│   │   │   │   └── channel.g.dart          # Código gerado para Channel
│   │   │   ├── remote/             # Camada de dados remotos
│   │   │   │   └── tmdb_data_source.dart   # Fonte de dados TMDB
│   │   │   └── repositories/       # Camada de repositórios
│   │   │       ├── movie_repository.dart      # Repositório de filmes
│   │   │       ├── tv_series_repository.dart  # Repositório de séries
│   │   │       └── channel_repository.dart    # Repositório de canais
│   │   ├── services/              # Camada de serviços
│   │   │   ├── auth_service.dart           # Serviço de autenticação
│   │   │   └── sync_service.dart           # Serviço de sincronização
│   │   ├── ui/                    # Camada de apresentação
│   │   │   ├── home_screen.dart           # Tela principal
│   │   │   ├── detail_screen.dart         # Tela de detalhes
│   │   │   ├── catalog_screen.dart        # Tela de catálogo
│   │   │   └── settings_screen.dart       # Tela de configurações
│   │   ├── utils/                 # Utilitários
│   │   │   ├── remote_control_manager.dart # Gerenciador de controle remoto
│   │   │   └── genre_localization.dart    # Localização de gêneros
│   │   └── widgets/               # Widgets reutilizáveis
│   │       └── remote_control_widgets.dart # Widgets de controle remoto
│   ├── l10n/                      # Internacionalização
│   │   ├── app_pt.arb              # Strings em português
│   │   ├── app_pt_BR.arb           # Strings em português brasileiro
│   │   └── app_en.arb              # Strings em inglês
│   └── main.dart                  # Ponto de entrada da aplicação
├── android/                       # Configurações Android
├── ios/                          # Configurações iOS
├── linux/                        # Configurações Linux
├── macos/                        # Configurações macOS
├── windows/                      # Configurações Windows
├── web/                          # Configurações Web
├── test/                         # Testes
│   └── widget_test.dart
├── docs/                         # Documentação
├── database.py                   # Script auxiliar Python para BD
├── logos.csv                     # Dados de canais de TV
├── pubspec.yaml                  # Configurações do projeto Flutter
├── pubspec.lock                  # Lockfile das dependências
├── analysis_options.yaml         # Configurações de análise de código
└── README.md                     # Documentação principal
```

## Camadas da Arquitetura

### 1. Camada de Apresentação (Presentation Layer)

**Responsabilidades:**
- Exibir dados para o usuário
- Capturar interações do usuário
- Gerenciar estado da UI
- Navegação entre telas

**Componentes principais:**
- `HomeScreen`: Tela principal com navegação por abas
- `DetailScreen`: Tela de detalhes de filmes/séries
- `CatalogScreen`: Tela de catálogo por gênero
- `SettingsScreen`: Tela de configurações

**Características:**
- Widgets stateful para gerenciamento de estado
- Navegação por teclado otimizada para TV
- Design responsivo
- Suporte a controle remoto

### 2. Camada de Domínio (Domain Layer)

**Responsabilidades:**
- Regras de negócio
- Casos de uso da aplicação
- Interfaces para repositórios

**Componentes principais:**
- `AuthService`: Gerenciamento de autenticação de usuários
- `SyncService`: Coordenação de sincronização de dados

**Características:**
- Lógica independente de frameworks
- Fácil de testar
- Reutilizável

### 3. Camada de Dados (Data Layer)

**Responsabilidades:**
- Acesso a dados (local e remoto)
- Mapeamento de dados
- Cache de dados
- Abstração de fontes de dados

**Subcamadas:**

#### 3.1 Repositórios (Repositories)
- `MovieRepository`: Interface unificada para acesso a filmes
- `TVSeriesRepository`: Interface unificada para acesso a séries
- `ChannelRepository`: Interface unificada para acesso a canais

**Padrão Repository:**
- Abstrai a complexidade do acesso a dados
- Permite troca de implementações (local/remoto)
- Centraliza lógica de cache e sincronização

#### 3.2 Fontes de Dados (Data Sources)
- **Local**: `LocalDataSource`, `DatabaseService`
- **Remoto**: `TmdbDataSource`

#### 3.3 Modelos (Models)
- `Movie`: Representa um filme
- `TVSeries`: Representa uma série de TV
- `Channel`: Representa um canal de TV
- `User`: Representa um usuário
- `UserList`: Representa listas personalizadas

### 4. Camada de Infraestrutura (Infrastructure Layer)

**Responsabilidades:**
- Configurações específicas de plataforma
- Integrações com sistemas externos
- Utilitários transversais

**Componentes:**
- Scripts auxiliares (`database.py`)
- Arquivos de configuração por plataforma
- Utilitários de localização

## Padrões de Design Utilizados

### 1. Repository Pattern
- Abstrai o acesso a dados
- Permite testes com mocks
- Facilita mudança de fonte de dados

### 2. Dependency Injection
- Injeção de dependências no `main.dart`
- Separação de responsabilidades
- Facilita testes e manutenção

### 3. Provider Pattern (implícito)
- Gerenciamento de estado através de injeção
- Widgets como `HomeScreen` recebem dependências via construtor

### 4. Factory Pattern
- Criação condicional de dependências baseada na plataforma
- Exemplo: SQLite vs dados remotos para web

## Fluxo de Dados

### Para Dados Locais (Desktop/Mobile):
1. UI solicita dados ao Repository
2. Repository consulta LocalDataSource
3. LocalDataSource acessa DatabaseService (SQLite)
4. Dados retornam pela mesma cadeia

### Para Dados Remotos (Web):
1. UI solicita dados ao Repository
2. Repository consulta TmdbDataSource diretamente
3. TmdbDataSource faz requisições HTTP para TMDB API
4. Dados retornam pela mesma cadeia

### Sincronização:
1. SyncService coordena sincronização
2. Busca dados da API TMDB
3. Salva no banco local via Repository/LocalDataSource
4. UI é atualizada automaticamente

## Benefícios da Arquitetura

### Manutenibilidade
- Separação clara de responsabilidades
- Código organizado por funcionalidades
- Fácil localização de bugs

### Testabilidade
- Dependências injetadas permitem mocks
- Lógica isolada facilita testes unitários
- Repositórios podem ser testados independentemente

### Escalabilidade
- Novas funcionalidades podem ser adicionadas sem afetar existentes
- Mudanças em uma camada não impactam outras
- Suporte a múltiplas plataformas

### Reutilização
- Widgets reutilizáveis
- Serviços compartilhados
- Utilitários transversais

## Considerações Específicas

### Suporte Multiplataforma
- Código Dart único para todas as plataformas
- Configurações específicas por plataforma (android/, ios/, etc.)
- Adaptações para web (sqflite_common_ffi_web)

### Navegação por Teclado
- Implementada na camada de apresentação
- Suporte a controle remoto
- Navegação intuitiva similar a smart TVs

### Internacionalização
- Arquivos ARB para diferentes idiomas
- Suporte completo ao português brasileiro
- Localização de gêneros e categorias

Esta arquitetura proporciona uma base sólida para o desenvolvimento contínuo do projeto, facilitando a adição de novas funcionalidades e a manutenção do código existente.