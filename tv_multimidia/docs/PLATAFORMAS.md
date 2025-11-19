# Suporte a Múltiplas Plataformas

## Visão Geral

O TV Multimidia é desenvolvido com Flutter, permitindo execução nativa em múltiplas plataformas a partir de uma única base de código. O aplicativo suporta Windows, Android, iOS, Web, Linux e macOS, com adaptações específicas para cada plataforma.

## Plataformas Suportadas

### ✅ Windows (Desktop)
**Status:** Totalmente suportado
**Comando:** `flutter run -d windows`

#### Características Específicas
- **Banco de dados:** SQLite nativo via sqflite_common_ffi
- **Interface:** Janela desktop otimizada
- **Navegação:** Teclado e mouse
- **Build:** `flutter build windows`

#### Configuração
```yaml
# windows/runner/main.cpp
#ifndef _DEBUG
  // Otimizações de release
#endif
```

### ✅ Android (Mobile & TV)
**Status:** Totalmente suportado
**Comando:** `flutter run -d android`

#### Características Específicas
- **Banco de dados:** SQLite via sqflite
- **Interface:** Material Design adaptado para Android TV
- **Navegação:** Touch, D-pad, controle remoto
- **Build:** `flutter build apk` ou `flutter build aab`

#### Configurações Android
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- Suporte a Android TV -->
<uses-feature android:name="android.software.leanback" android:required="false" />
<uses-feature android:name="android.hardware.touchscreen" android:required="false" />
```

### ✅ iOS (Mobile & TV)
**Status:** Totalmente suportado
**Comando:** `flutter run -d ios`

#### Características Específicas
- **Banco de dados:** SQLite via sqflite
- **Interface:** Cupertino widgets adaptados
- **Navegação:** Touch, Siri Remote
- **Build:** `flutter build ios` ou `flutter build ipa`

#### Configurações iOS
```xml
<!-- ios/Runner/Info.plist -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>

<!-- Suporte a tvOS -->
<key>UIDeviceFamily</key>
<array>
    <integer>1</integer> <!-- iPhone/iPod -->
    <integer>2</integer> <!-- iPad -->
    <integer>3</integer> <!-- Apple TV -->
</array>
```

### ✅ Web (Browser)
**Status:** Suportado com limitações
**Comando:** `flutter run -d chrome`

#### Características Específicas
- **Banco de dados:** IndexedDB via sqflite_common_ffi_web (somente leitura)
- **Interface:** HTML/CSS otimizado
- **Navegação:** Mouse e teclado
- **Build:** `flutter build web`

#### Limitações na Web
- **SQLite:** Operações de escrita falham
- **Funcionalidades:** Modo somente leitura
- **Fallback:** Dados remotos quando local não disponível

#### Tratamento de Plataforma Web
```dart
import 'package:flutter/foundation.dart' show kIsWeb;

if (kIsWeb) {
  // Usar apenas dados remotos
  return await _remoteDataSource.fetchTrendingMovies();
} else {
  // Desktop/mobile: usar dados locais
  return _localDataSource!.getAllMovies();
}
```

### ✅ Linux (Desktop)
**Status:** Totalmente suportado
**Comando:** `flutter run -d linux`

#### Características Específicas
- **Banco de dados:** SQLite via sqflite_common_ffi
- **Interface:** GTK-based window
- **Navegação:** Teclado e mouse
- **Build:** `flutter build linux`

### ✅ macOS (Desktop)
**Status:** Totalmente suportado
**Comando:** `flutter run -d macos`

#### Características Específicas
- **Banco de dados:** SQLite via sqflite_common_ffi
- **Interface:** macOS native window
- **Navegação:** Teclado e trackpad
- **Build:** `flutter build macos`

## Arquitetura Multiplataforma

### Código Compartilhado
- **Dart/Flutter:** 100% do código compartilhado
- **UI:** Widgets adaptáveis automaticamente
- **Lógica:** Regras de negócio independentes de plataforma

### Adaptações por Plataforma
- **Build files:** Configurações específicas em `android/`, `ios/`, etc.
- **Assets:** Recursos otimizados por plataforma
- **Dependências:** Bibliotecas específicas quando necessário

### Detecção de Plataforma
```dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// Exemplos de detecção
bool isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
bool isWeb = kIsWeb;
```

## Configurações por Plataforma

### Build Configurations

#### Android
```gradle
// android/app/build.gradle.kts
android {
    defaultConfig {
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }
}
```

#### iOS
```swift
// ios/Runner/AppDelegate.swift
@UIApplicationMain
class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Configurações específicas do iOS
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
```

#### Web
```html
<!-- web/index.html -->
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TV Multimidia</title>
</head>
<body>
    <script src="main.dart.js" type="application/javascript"></script>
</body>
</html>
```

### Assets por Plataforma

#### Estrutura de Assets
```
assets/
├── images/           # Imagens compartilhadas
├── icons/           # Ícones da app
└── platform/
    ├── android/     # Assets específicos Android
    ├── ios/         # Assets específicos iOS
    └── web/         # Assets específicos Web
```

#### Exemplo de Uso
```dart
// Carregar asset específico da plataforma
String getPlatformAsset(String assetName) {
  if (Platform.isAndroid) {
    return 'assets/platform/android/$assetName';
  } else if (Platform.isIOS) {
    return 'assets/platform/ios/$assetName';
  }
  return 'assets/$assetName'; // Padrão
}
```

## Banco de Dados Multiplataforma

### Estratégia de Abstração
```dart
// lib/src/data/local/database_service.dart
class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;

    // Detectar plataforma e inicializar apropriadamente
    if (kIsWeb) {
      // Web: usar sqflite_common_ffi_web
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfiWeb;
    } else {
      // Desktop/Mobile: usar sqflite_ffi
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _database = await _initDatabase();
    return _database!;
  }
}
```

### Limitações por Plataforma

#### Web
- **IndexedDB:** Emulação de SQLite
- **Escrita:** Não suportada (operações falham silenciosamente)
- **Leitura:** Funciona normalmente
- **Solução:** Fallback para dados remotos

#### Desktop
- **SQLite nativo:** Performance otimizada
- **FFI:** Interface nativa via Foreign Function Interface
- **Dependências:** sqflite_common_ffi + sqlite3_flutter_libs

## Interface Adaptável

### Design Responsivo
```dart
class ResponsiveLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return _buildWideLayout(); // Desktop/Web grande
        } else {
          return _buildNarrowLayout(); // Mobile/Pequeno
        }
      },
    );
  }
}
```

### Navegação por Plataforma

#### Desktop/Web
- **Teclado:** Setas, Enter, Escape
- **Mouse:** Click, scroll
- **Focus:** Visual indicators

#### Mobile
- **Touch:** Gestos, tap
- **Controle:** D-pad, botões
- **TV Remote:** Siri Remote, Android TV remote

### Tema Adaptável
```dart
ThemeData getThemeForPlatform() {
  if (kIsWeb) {
    return _webTheme;
  } else if (Platform.isAndroid) {
    return _androidTheme;
  } else if (Platform.isIOS) {
    return _iosTheme;
  }
  return _desktopTheme;
}
```

## Build e Distribuição

### Comandos de Build

#### Android
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (recomendado)
flutter build appbundle --release
```

#### iOS
```bash
# Para desenvolvimento
flutter build ios --debug

# Para distribuição
flutter build ios --release
```

#### Web
```bash
# Build para web
flutter build web --release

# Servir localmente
flutter run -d chrome
```

#### Desktop
```bash
# Windows
flutter build windows --release

# Linux
flutter build linux --release

# macOS
flutter build macos --release
```

### Distribuição

#### Google Play (Android)
- **Formato:** AAB (Android App Bundle)
- **Requisitos:** Assinatura, ícones, screenshots
- **TV Support:** Leanback library

#### App Store (iOS)
- **Formato:** IPA
- **Requisitos:** Certificados, provisioning profiles
- **tvOS:** Suporte opcional

#### Microsoft Store (Windows)
- **Formato:** MSIX
- **Requisitos:** Manifest, certificados
- **Distribuição:** Via Microsoft Partner Center

#### Web
- **Hospedagem:** Qualquer servidor web
- **PWA:** Service workers para offline
- **SEO:** Meta tags, structured data

## Testes Multiplataforma

### Estratégia de Testes
```dart
// Teste específico de plataforma
void main() {
  group('Database Tests', () {
    test('should work on all platforms', () async {
      if (kIsWeb) {
        // Testes específicos para web
      } else {
        // Testes para desktop/mobile
      }
    });
  });
}
```

### CI/CD Multiplataforma
```yaml
# .github/workflows/build.yml
name: Build Multiplatform
on: [push, pull_request]

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter build apk

  build-web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter build web
```

## Performance por Plataforma

### Otimizações Específicas

#### Web
- **Tree Shaking:** Remover código não utilizado
- **Lazy Loading:** Carregar assets sob demanda
- **Service Workers:** Cache para offline

#### Mobile
- **AOT Compilation:** Ahead-of-Time para performance
- **Native Code:** Platform channels quando necessário
- **Memory Management:** Dispose adequado de recursos

#### Desktop
- **FFI:** Chamadas nativas otimizadas
- **GPU Acceleration:** Renderização hardware
- **Memory:** Gerenciamento eficiente

## Troubleshooting

### Problemas Comuns

#### SQLite na Web
**Sintoma:** Erro "Unsupported operation: Unsupported on the web"
**Solução:** Verificar detecção de plataforma e usar fallback

#### Build Falhas
**Sintoma:** Erros específicos de plataforma
**Solução:** Verificar configurações em `android/`, `ios/`, etc.

#### Performance Issues
**Sintoma:** Lentidão em alguma plataforma
**Solução:** Otimizações específicas e profiling

### Debugging Multiplataforma
```dart
// Logs específicos por plataforma
void logPlatformInfo() {
  if (kIsWeb) {
    print('Running on Web');
  } else {
    print('Running on ${Platform.operatingSystem}');
    print('Version: ${Platform.operatingSystemVersion}');
  }
}
```

## Monitoramento

### Analytics por Plataforma
- **Firebase:** Suporte nativo para Android/iOS/Web
- **Custom:** Implementação própria para desktop
- **Métricas:** Uso por plataforma, erros, performance

### Error Reporting
- **Sentry:** Suporte multiplataforma
- **Firebase Crashlytics:** Para mobile
- **Custom logging:** Para desktop

Esta documentação garante que o TV Multimidia possa ser desenvolvido, testado e distribuído eficientemente em todas as plataformas suportadas pelo Flutter.