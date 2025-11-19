# Localização e Internacionalização

## Visão Geral

O TV Multimidia suporta internacionalização completa, permitindo a adaptação da interface para diferentes idiomas e regiões. O sistema utiliza o framework de localização do Flutter (flutter_localizations) e arquivos ARB (Application Resource Bundle) para gerenciar strings traduzidas.

## Arquitetura de Localização

### Estrutura de Arquivos

```
lib/l10n/
├── app_en.arb          # Strings em inglês (idioma base)
├── app_pt.arb          # Strings em português
└── app_pt_BR.arb       # Strings em português brasileiro
```

### Configuração no Código

#### MaterialApp Configuration
```dart
MaterialApp(
  // ...
  locale: const Locale('pt', 'BR'), // Define português brasileiro como padrão
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [
    Locale('en'),      // Inglês
    Locale('pt'),      // Português
    Locale('pt', 'BR'), // Português brasileiro
  ],
  // ...
)
```

#### Geração Automática
Os arquivos de localização são gerados automaticamente através do `flutter_intl`:

```bash
flutter pub run intl_utils:generate
```

## Sistema ARB (Application Resource Bundle)

### Formato ARB

Os arquivos ARB seguem o formato JSON com chaves específicas:

```json
{
  "@@locale": "pt_BR",
  "@@context": "TV Multimidia App",
  "appTitle": "TV Multimidia",
  "@appTitle": {
    "description": "Título principal da aplicação"
  },
  "homeTab": "Início",
  "@homeTab": {
    "description": "Rótulo da aba de início"
  }
}
```

### Elementos ARB

- **@@locale**: Define o locale do arquivo
- **@@context**: Contexto geral da aplicação
- **chave**: String traduzida
- **@chave**: Metadados da string (descrição, placeholders, etc.)

### Placeholders

```json
{
  "movieCount": "Encontrados {count} filmes",
  "@movieCount": {
    "description": "Mensagem mostrando contagem de filmes",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```

## Utilização no Código

### Classe AppLocalizations

Gerada automaticamente pelo flutter_intl:

```dart
class AppLocalizations {
  // Getters para strings traduzidas
  String get appTitle => _localizedValues['appTitle'] ?? 'TV Multimidia';

  String get homeTab => _localizedValues['homeTab'] ?? 'Home';

  // Método para interpolação
  String movieCount(int count) {
    return Intl.message(
      'Found $count movies',
      name: 'movieCount',
      args: [count],
      desc: 'Message showing movie count',
    );
  }

  // Método estático para acesso
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
}
```

### Uso nos Widgets

```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
      ),
      body: Center(
        child: Text(l10n.homeTab),
      ),
    );
  }
}
```

## Localização de Gêneros

### Classe GenreLocalization

**Arquivo:** `lib/src/utils/genre_localization.dart`

```dart
class GenreLocalization {
  static String getLocalizedGenreName(int genreId) {
    const genreMap = {
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
      53: 'Suspense',
      10752: 'Guerra',
      37: 'Faroeste',
    };
    return genreMap[genreId] ?? 'Desconhecido';
  }
}
```

### Integração com API TMDB

```dart
Future<List<Genre>> fetchMovieGenres() async {
  final response = await http.get(
    Uri.parse('$_baseUrl/genre/movie/list?language=pt-BR'),
    headers: _headers,
  );

  final genres = data['genres'] as List;
  return genres.map((json) {
    final genre = Genre.fromJson(json);
    // Sobrescreve com tradução local
    genre.name = GenreLocalization.getLocalizedGenreName(genre.id);
    return genre;
  }).toList();
}
```

## Configuração de Locale

### Locale Padrão

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('pt', 'BR'), // Português brasileiro
      // ...
    );
  }
}
```

### Detecção Automática

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: null, // Usa locale do dispositivo
      // ...
    );
  }
}
```

### Mudança Dinâmica

```dart
void changeLanguage(BuildContext context, Locale locale) {
  MyApp.setLocale(context, locale);
}
```

## Pluralização

### Suporte a Plurals

```json
{
  "itemCount": "{count, plural, =0{Nenhum item} =1{1 item} other{{count} itens}}",
  "@itemCount": {
    "description": "Contagem de itens com pluralização",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```

### Uso no Código

```dart
String getItemCountText(int count) {
  return Intl.plural(
    count,
    zero: 'Nenhum item',
    one: '1 item',
    other: '$count itens',
    name: 'itemCount',
    args: [count],
    desc: 'Item count with pluralization',
  );
}
```

## Direção do Texto (RTL/LTR)

### Suporte a Idiomas RTL

```dart
MaterialApp(
  // ...
  builder: (context, child) {
    return Directionality(
      textDirection: _getTextDirection(context),
      child: child,
    );
  },
)

TextDirection _getTextDirection(BuildContext context) {
  final locale = Localizations.localeOf(context);
  return _isRTL(locale) ? TextDirection.rtl : TextDirection.ltr;
}

bool _isRTL(Locale locale) {
  return ['ar', 'he', 'fa', 'ur'].contains(locale.languageCode);
}
```

## Formatação de Datas e Números

### Intl Package

```dart
import 'package:intl/intl.dart';

String formatDate(DateTime date) {
  final formatter = DateFormat('dd/MM/yyyy', 'pt_BR');
  return formatter.format(date);
}

String formatCurrency(double value) {
  final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  return formatter.format(value);
}
```

## Testes de Localização

### Testes Unitários

```dart
void main() {
  test('Genre localization works', () {
    expect(GenreLocalization.getLocalizedGenreName(28), 'Ação');
    expect(GenreLocalization.getLocalizedGenreName(999), 'Desconhecido');
  });

  testWidgets('App supports Portuguese', (tester) async {
    await tester.pumpWidget(const MyApp());

    // Verifica se strings estão em português
    expect(find.text('TV Multimidia'), findsOneWidget);
  });
}
```

### Testes de Integração

```dart
void main() {
  testWidgets('Locale changes work', (tester) async {
    await tester.pumpWidget(const MyApp());

    // Muda locale
    await tester.tap(find.byIcon(Icons.language));
    await tester.tap(find.text('English'));
    await tester.pump();

    // Verifica mudança
    expect(find.text('TV Multimidia'), findsNothing);
    expect(find.text('TV Multimedia'), findsOneWidget);
  });
}
```

## Adição de Novos Idiomas

### Passos para Adicionar Idioma

1. **Criar arquivo ARB**
   ```
   lib/l10n/app_es.arb  # Espanhol
   ```

2. **Adicionar traduções**
   ```json
   {
     "@@locale": "es",
     "appTitle": "TV Multimidia",
     "homeTab": "Inicio"
   }
   ```

3. **Atualizar MaterialApp**
   ```dart
   supportedLocales: const [
     Locale('en'),
     Locale('pt'),
     Locale('pt', 'BR'),
     Locale('es'),  // Novo idioma
   ],
   ```

4. **Regenerar código**
   ```bash
   flutter pub run intl_utils:generate
   ```

## Boas Práticas

### Organização
- Manter arquivos ARB organizados alfabeticamente
- Usar descrições claras para todas as strings
- Agrupar strings relacionadas

### Performance
- Strings são carregadas uma vez na inicialização
- Uso de const para strings estáticas
- Lazy loading para localizações complexas

### Manutenibilidade
- Documentar mudanças nos arquivos ARB
- Versionar arquivos de localização
- Revisar traduções com falantes nativos

### Acessibilidade
- Considerar comprimento das strings traduzidas
- Testar com diferentes tamanhos de tela
- Verificar contraste e legibilidade

## Troubleshooting

### Problemas Comuns

#### Strings Não Aparecem
- Verificar se arquivo ARB está correto
- Regenerar código de localização
- Limpar cache do Flutter

#### Locale Não Muda
- Verificar supportedLocales
- Testar mudança de locale no dispositivo
- Verificar ordem dos delegates

#### Erros de Build
- Verificar sintaxe JSON dos arquivos ARB
- Validar placeholders
- Checar conflitos de nomes

Esta documentação cobre completamente o sistema de localização e internacionalização do TV Multimidia, garantindo uma experiência consistente em diferentes idiomas e regiões.