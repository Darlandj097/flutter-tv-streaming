# Telas e Widgets Principais

## Visão Geral

O TV Multimidia possui uma interface rica e interativa, otimizada para navegação por controle remoto e teclado. As telas são organizadas de forma hierárquica, com navegação intuitiva e design responsivo.

## Arquitetura de UI

### Padrões de Design

- **Material Design**: Baseado no Material Design do Flutter
- **Dark Theme**: Tema escuro otimizado para TV
- **Focus Management**: Sistema avançado de foco para navegação por teclado
- **Responsive Layout**: Layouts adaptáveis a diferentes tamanhos de tela
- **Accessibility**: Suporte a navegação assistiva

### Componentes Base

#### Focus Management
```dart
class _HomeScreenState extends State<HomeScreen> {
  // Nós de foco para navegação
  FocusNode _tabFocusNode = FocusNode();
  FocusNode _syncFocusNode = FocusNode();
  List<FocusNode> _sectionFocusNodes = [];

  // Navegação por teclado
  void _handleKeyEvent(KeyEvent event) {
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft: _navigateLeft();
      case LogicalKeyboardKey.arrowRight: _navigateRight();
      case LogicalKeyboardKey.arrowUp: _navigateUp();
      case LogicalKeyboardKey.arrowDown: _navigateDown();
      case LogicalKeyboardKey.enter: _activateCurrentItem();
    }
  }
}
```

## Tela Principal (HomeScreen)

### Estrutura Geral

**Arquivo**: `lib/src/ui/home_screen.dart`

**Responsabilidades:**
- Exibir conteúdo organizado por abas
- Gerenciar navegação principal
- Coordenar carregamento de dados
- Fornecer acesso a configurações

### Layout

```
┌─────────────────────────────────────┐
│ AppBar: TV Multimidia | Settings | Sync │
├─────────────────────────────────────┤
│ TabBar: TV ao Vivo | Séries | Filmes | Infantil │
├─────────────────────────────────────┤
│ Content Area (TabBarView)           │
│ ┌─────────────────────────────────┐ │
│ │ Section 1: Canais ao Vivo      │ │
│ │ [Channel Cards...]             │ │
│ ├─────────────────────────────────┤ │
│ │ Section 2: Séries em Alta      │ │
│ │ [TV Series Cards...]           │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### Componentes Principais

#### AppBar
```dart
AppBar(
  title: const Text('TV Multimidia'),
  actions: [
    IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () => _navigateToSettings(),
    ),
    Focus(
      focusNode: _syncFocusNode,
      child: IconButton(
        icon: const Icon(Icons.sync),
        onPressed: _syncData,
      ),
    ),
  ],
)
```

#### TabBar
```dart
TabBar(
  tabs: const [
    Tab(text: 'TV ao Vivo'),
    Tab(text: 'Séries'),
    Tab(text: 'Filmes'),
    Tab(text: 'Infantil'),
  ],
  onTap: (index) => setState(() => _currentTabIndex = index),
)
```

#### TabBarView
- **TV ao Vivo**: Lista canais de TV
- **Séries**: Séries organizadas por gênero
- **Filmes**: Filmes organizados por gênero
- **Infantil**: Conteúdo infantil (filmes e séries)

### Seções de Conteúdo

#### _buildSection
```dart
Widget _buildSection(String title, List<dynamic> items, int sectionIndex) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Título da seção com indicador de foco
      Focus(
        focusNode: _sectionFocusNodes[sectionIndex],
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: isFocused ? Colors.blue.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isFocused ? Colors.blue : Colors.black,
            ),
          ),
        ),
      ),

      // Lista horizontal de itens
      SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          itemBuilder: (context, index) => _buildItemCard(items[index]),
        ),
      ),
    ],
  );
}
```

#### _buildItemCard
```dart
Widget _buildItemCard(dynamic item, [bool isFocused = false]) {
  return Container(
    width: 120,
    margin: const EdgeInsets.only(right: 12),
    decoration: BoxDecoration(
      border: isFocused ? Border.all(color: Colors.blue, width: 3) : null,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        // Imagem do poster
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: imageUrl.isNotEmpty
                  ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                  : null,
              color: Colors.grey[300],
            ),
          ),
        ),

        // Título
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: isFocused ? Colors.blue : Colors.black,
            fontWeight: isFocused ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}
```

## Tela de Detalhes (DetailScreen)

### Estrutura Geral

**Arquivo**: `lib/src/ui/detail_screen.dart`

**Responsabilidades:**
- Exibir informações detalhadas de filmes/séries
- Gerenciar reprodução de conteúdo
- Controlar listas pessoais (Minha Lista, Favoritos)
- Navegar entre episódios (para séries)

### Layout Responsivo

#### Layout para Telas Grandes
```
┌─────────────────┬──────────────────┐
│                 │                  │
│   Poster/       │   Título         │
│   Backdrop      │   Avaliação      │
│                 │   Ano/Tipo       │
│                 │   Sinopse        │
│                 │   Botões Ação    │
│                 │                  │
└─────────────────┴──────────────────┘
```

#### Layout para Telas Pequenas
```
┌─────────────────┐
│                 │
│   Poster/       │
│   Backdrop      │
│                 │
├─────────────────┤
│   Título        │
│   Avaliação     │
│   Ano/Tipo      │
│   Sinopse       │
│   Botões Ação   │
└─────────────────┘
```

### Componentes Principais

#### Informações do Conteúdo
```dart
Widget _buildInfoSection() {
  return Column(
    children: [
      // Título
      Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),

      // Metadados
      Row(children: [
        // Avaliação com estrelas
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.yellow[700],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(children: [
            const Icon(Icons.star, color: Colors.white, size: 16),
            Text(voteAverage.toStringAsFixed(1)),
          ]),
        ),

        // Ano de lançamento
        Text(releaseDate.split('-')[0]),

        // Tipo (Filme/Série)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(isMovie ? 'Filme' : 'Série'),
        ),
      ]),

      // Sinopse
      Text(overview, style: const TextStyle(fontSize: 16, height: 1.6)),

      // Botões de ação
      Row(children: [
        // Reproduzir
        ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow),
          label: const Text('Reproduzir'),
          onPressed: _playContent,
        ),

        // Minha Lista
        IconButton(
          icon: Icon(isInMyList ? Icons.check : Icons.add),
          onPressed: _toggleMyList,
        ),

        // Favoritos
        IconButton(
          icon: Icon(isInFavorites ? Icons.thumb_up : Icons.thumb_up_outlined),
          onPressed: _toggleFavorite,
        ),
      ]),
    ],
  );
}
```

#### Seções Específicas para Séries

##### Temporadas
```dart
Widget _buildSeasonsSection() {
  return SizedBox(
    height: 60,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: seasons.length,
      itemBuilder: (context, index) {
        final season = seasons[index];
        final isSelected = index == selectedSeasonIndex;

        return Focus(
          focusNode: _seasonFocusNodes[index],
          child: GestureDetector(
            onTap: () => _selectSeason(index),
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.red : Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('T${season['season_number']}',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('${season['episode_count']} eps',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
```

##### Episódios (Carrossel 3D)
```dart
Widget _buildEpisodesSection() {
  return SizedBox(
    height: 320,
    child: PageView.builder(
      controller: _episodeController,
      onPageChanged: (index) => setState(() => selectedEpisodeIndex = index),
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        final episode = episodes[index];
        final isSelected = index == selectedEpisodeIndex;

        // Efeito 3D baseado na seleção
        double scale = isSelected ? 1.0 : 0.85;
        double opacity = isSelected ? 1.0 : 0.7;

        return Focus(
          focusNode: _episodeFocusNodes[index],
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            transform: Matrix4.identity()..scale(scale),
            child: Opacity(
              opacity: opacity,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: isSelected ? 0 : 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 25,
                      spreadRadius: 8,
                    )
                  ] : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(children: [
                    // Imagem de fundo
                    Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage('https://image.tmdb.org/t/p/w500${episode['still_path']}'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // Gradiente e conteúdo
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Número do episódio
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text('EP ${episode['episode_number'] ?? index + 1}'),
                          ),

                          // Título
                          Text(
                            episode['name'] ?? 'Episódio ${index + 1}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSelected ? 24 : 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          // Descrição
                          if (episode['overview']?.isNotEmpty ?? false)
                            Text(
                              episode['overview'],
                              maxLines: isSelected ? 3 : 2,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSelected ? 15 : 13,
                              ),
                            ),

                          // Botão reproduzir
                          ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Reproduzir'),
                            onPressed: _playCurrentEpisode,
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
```

#### Indicadores de Página
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: List.generate(
    episodes.length,
    (index) => AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: selectedEpisodeIndex == index ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: selectedEpisodeIndex == index ? Colors.red : Colors.grey[600],
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  ),
)
```

## Tela de Catálogo (CatalogScreen)

**Arquivo**: `lib/src/ui/catalog_screen.dart`

**Responsabilidades:**
- Exibir listagem completa de filmes/séries por gênero
- Permitir navegação paginada
- Suporte a filtros e busca

## Tela de Configurações (SettingsScreen)

**Arquivo**: `lib/src/ui/settings_screen.dart`

**Responsabilidades:**
- Gerenciar configurações do usuário
- Controle de autenticação
- Configurações de sincronização

## Widgets Reutilizáveis

### RemoteControlWidgets

**Arquivo**: `lib/src/widgets/remote_control_widgets.dart`

**Componentes:**
- Botões virtuais de controle remoto
- Indicadores de foco
- Controles de navegação

### Utilitários de UI

#### GenreLocalization
**Arquivo**: `lib/src/utils/genre_localization.dart`

**Função:** Localizar nomes de gêneros para português

```dart
String getLocalizedGenreName(int genreId) {
  const genreMap = {
    28: 'Ação',
    12: 'Aventura',
    16: 'Animação',
    // ...
  };
  return genreMap[genreId] ?? 'Desconhecido';
}
```

## Sistema de Navegação

### Navegação por Teclado

#### Mapeamento de Teclas
- **Setas**: Navegação direcional
- **Enter/Select**: Ativar item
- **Escape/Back**: Voltar
- **Tab**: Alternar entre seções

#### Estados de Foco
- **Tab Focus**: Navegação entre abas principais
- **Section Focus**: Navegação entre seções
- **Item Focus**: Navegação entre itens individuais

### Navegação Touch/Mouse

- **Tap**: Ativar item ou seção
- **Scroll**: Navegação horizontal/vertical
- **Drag**: Arrastar para navegar

## Design System

### Cores
```dart
const Color primaryColor = Colors.blue;
const Color accentColor = Colors.red;
const Color backgroundColor = Colors.black;
const Color surfaceColor = Color(0xFF1E1E1E);
const Color textColor = Colors.white;
```

### Tipografia
```dart
const TextStyle headlineStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: Colors.white,
);

const TextStyle bodyStyle = TextStyle(
  fontSize: 16,
  height: 1.6,
  color: Colors.white,
);
```

### Espaçamentos
```dart
const double smallSpacing = 8.0;
const double mediumSpacing = 16.0;
const double largeSpacing = 24.0;
const double extraLargeSpacing = 32.0;
```

## Responsividade

### Breakpoints
- **Mobile**: < 600px
- **Tablet**: 600-1200px
- **Desktop**: > 1200px

### Layouts Adaptáveis
```dart
LayoutBuilder(
  builder: (context, constraints) {
    final isWideScreen = constraints.maxWidth > 800;
    return isWideScreen ? _buildWideLayout() : _buildNarrowLayout();
  },
)
```

## Performance

### Otimizações Implementadas

#### Lazy Loading
- Carregamento sob demanda de imagens
- Paginação em listas grandes
- Cache de widgets

#### Animações Eficientes
- `AnimatedContainer` para transições suaves
- `Hero` animations para navegação
- Throttling de eventos de teclado

#### Gerenciamento de Estado
- `setState` localizado
- Evitar rebuilds desnecessários
- Dispose adequado de recursos

## Acessibilidade

### Suporte a Leitores de Tela
- Labels descritivos em botões
- Textos alternativos em imagens
- Estrutura semântica

### Navegação por Teclado
- Indicadores visuais de foco
- Ordem lógica de tabulação
- Atalhos de teclado consistentes

### Contraste e Legibilidade
- Alto contraste em texto
- Fontes legíveis
- Tamanhos adequados

## Testes

### Testes de Widget
```dart
void main() {
  testWidgets('HomeScreen displays tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.text('TV ao Vivo'), findsOneWidget);
    expect(find.text('Séries'), findsOneWidget);
    expect(find.text('Filmes'), findsOneWidget);
  });
}
```

### Testes de Integração
- Testar navegação entre telas
- Verificar estados de foco
- Validar carregamento de dados

Esta documentação cobre os principais aspectos das telas e widgets do TV Multimidia, fornecendo uma base sólida para desenvolvimento e manutenção da interface do usuário.