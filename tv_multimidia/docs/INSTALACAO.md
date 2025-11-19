# Guia de Instalação e Configuração

## Visão Geral

Este guia fornece instruções completas para instalar, configurar e executar o TV Multimidia em diferentes plataformas. O projeto utiliza Flutter e requer configurações específicas para cada ambiente de desenvolvimento.

## Pré-requisitos

### Sistema Operacional
- **Windows**: 10 ou superior (64-bit)
- **macOS**: 10.15 ou superior
- **Linux**: Ubuntu 18.04 ou superior
- **Chrome OS**: Qualquer versão recente

### Hardware Mínimo
- **CPU**: Intel i5 ou equivalente
- **RAM**: 8 GB
- **Armazenamento**: 5 GB disponível
- **GPU**: Suporte a OpenGL 3.0 (para desktop)

## Instalação do Flutter

### Windows

1. **Baixar Flutter SDK**
   ```bash
   # Baixe o SDK do site oficial: https://flutter.dev/docs/get-started/install/windows
   # Extraia para C:\src\flutter
   ```

2. **Adicionar ao PATH**
   - Variável de ambiente: `C:\src\flutter\bin`
   - Reiniciar terminal/PowerShell

3. **Verificar instalação**
   ```bash
   flutter doctor
   ```

4. **Instalar Android Studio** (opcional para desenvolvimento Android)
   - Baixar: https://developer.android.com/studio
   - Instalar Android SDK e ferramentas

### macOS

1. **Instalar via Homebrew**
   ```bash
   brew install flutter
   ```

2. **Ou baixar manualmente**
   ```bash
   # Baixar do site oficial e extrair
   export PATH="$PATH:`pwd`/flutter/bin"
   ```

3. **Verificar instalação**
   ```bash
   flutter doctor
   ```

4. **Instalar Xcode** (para iOS)
   ```bash
   xcode-select --install
   ```

### Linux

1. **Baixar e extrair**
   ```bash
   cd ~/development
   wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.8.1-stable.tar.xz
   tar xf flutter_linux_3.8.1-stable.tar.xz
   export PATH="$PATH:`pwd`/flutter/bin"
   ```

2. **Instalar dependências**
   ```bash
   sudo apt-get update
   sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
   ```

3. **Verificar instalação**
   ```bash
   flutter doctor
   ```

## Configuração do Projeto

### Clonagem e Dependências

1. **Clonar repositório**
   ```bash
   git clone <url-do-repositorio>
   cd tv_multimidia
   ```

2. **Instalar dependências**
   ```bash
   flutter pub get
   ```

3. **Gerar código automático**
   ```bash
   flutter pub run build_runner build
   ```

### Configuração da API TMDB

1. **Obter chave da API**
   - Acesse: https://www.themoviedb.org/settings/api
   - Crie uma conta gratuita
   - Gere uma chave de API (v4 auth - Bearer token)

2. **Configurar chave**
   - Abra `lib/src/data/remote/tmdb_data_source.dart`
   - Substitua o valor da constante `_apiKey`

**Nota**: Para produção, mova a chave para variáveis de ambiente.

## Configuração por Plataforma

### Android

1. **Instalar Android SDK**
   ```bash
   flutter doctor --android-licenses
   ```

2. **Configurar dispositivo/emulador**
   ```bash
   # Conectar dispositivo USB
   adb devices

   # Ou criar emulador no Android Studio
   ```

3. **Executar**
   ```bash
   flutter run -d android
   ```

### iOS (macOS apenas)

1. **Instalar CocoaPods**
   ```bash
   sudo gem install cocoapods
   ```

2. **Configurar simulador**
   ```bash
   open -a Simulator
   ```

3. **Executar**
   ```bash
   flutter run -d ios
   ```

### Windows

1. **Habilitar modo desenvolvedor**
   - Configurações > Atualização e Segurança > Para desenvolvedores
   - Ativar "Modo desenvolvedor"

2. **Executar**
   ```bash
   flutter run -d windows
   ```

### Web

1. **Habilitar web**
   ```bash
   flutter config --enable-web
   ```

2. **Executar**
   ```bash
   flutter run -d chrome
   ```

### Linux

1. **Instalar dependências do sistema**
   ```bash
   sudo apt-get install libgtk-3-dev
   ```

2. **Executar**
   ```bash
   flutter run -d linux
   ```

### macOS

1. **Executar**
   ```bash
   flutter run -d macos
   ```

## Inicialização do Banco de Dados

### Script Python Auxiliar

O projeto inclui um script Python para inicializar o banco de dados:

1. **Instalar Python** (se não tiver)
   ```bash
   # Windows
   # Baixar: https://www.python.org/downloads/

   # Linux/macOS
   # Geralmente já instalado
   python3 --version
   ```

2. **Instalar dependências Python**
   ```bash
   pip install requests
   ```

3. **Executar script de inicialização**
   ```bash
   cd tv_multimidia
   python database.py
   ```

### O que o script faz:
- Cria tabelas do banco de dados
- Sincroniza dados iniciais da TMDB
- Carrega canais do arquivo `logos.csv`
- Popula dados para desenvolvimento

## Configuração de Desenvolvimento

### IDE Recomendada: Visual Studio Code

1. **Instalar VS Code**
   - Baixar: https://code.visualstudio.com/

2. **Instalar extensões Flutter**
   - Flutter
   - Dart
   - Awesome Flutter Snippets

3. **Configurar VS Code**
   ```json
   // .vscode/settings.json
   {
     "dart.flutterSdkPath": "C:\\src\\flutter",
     "flutter.hotReloadOnSave": "all"
   }
   ```

### Android Studio (Alternativa)

1. **Instalar plugins Flutter/Dart**
2. **Configurar SDK do Flutter**
   - File > Settings > Languages & Frameworks > Flutter
   - Definir Flutter SDK path

## Build para Produção

### Android APK/AAB

```bash
# APK
flutter build apk --release

# App Bundle (recomendado)
flutter build appbundle --release
```

### iOS IPA

```bash
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

### Desktop

```bash
# Windows
flutter build windows --release

# Linux
flutter build linux --release

# macOS
flutter build macos --release
```

## Distribuição

### Google Play (Android)

1. **Criar conta de desenvolvedor**
   - Acesse: https://play.google.com/console/
   - Taxa: $25 (uma vez)

2. **Enviar App Bundle**
   ```bash
   flutter build appbundle --release
   # Enviar app-release.aab pelo console
   ```

### App Store (iOS)

1. **Criar conta Apple Developer**
   - Acesse: https://developer.apple.com/
   - Taxa: $99/ano

2. **Enviar via Xcode**
   ```bash
   flutter build ios --release
   # Abrir no Xcode e enviar
   ```

### Microsoft Store (Windows)

1. **Criar conta de desenvolvedor**
   - Acesse: https://partner.microsoft.com/
   - Taxa: $19/ano

2. **Empacotar como MSIX**
   ```bash
   flutter build windows --release
   # Usar ferramenta de empacotamento
   ```

### Web

1. **Hospedar arquivos**
   ```bash
   flutter build web --release
   # Hospedar conteúdo de build/web/
   ```

2. **Serviços recomendados**
   - Firebase Hosting
   - Vercel
   - Netlify
   - GitHub Pages

## Solução de Problemas

### Problemas Comuns

#### Flutter doctor mostra erros

```bash
# Verificar status detalhado
flutter doctor -v

# Resolver problemas específicos
flutter doctor --android-licenses
```

#### Build falha

```bash
# Limpar cache
flutter clean
flutter pub get

# Para Android
flutter build apk --debug
```

#### Dispositivo não reconhecido

```bash
# Android
adb devices
adb kill-server && adb start-server

# iOS
flutter devices
```

#### Dependências desatualizadas

```bash
# Atualizar
flutter pub upgrade

# Verificar conflitos
flutter pub deps
```

### Logs de Debug

```bash
# Ver logs detalhados
flutter run --verbose

# Logs específicos de plataforma
flutter logs
```

### Suporte da Comunidade

- **Documentação oficial**: https://flutter.dev/docs
- **Stack Overflow**: Tag `flutter`
- **Discord**: Flutter Community
- **Reddit**: r/FlutterDev

## Configurações Avançadas

### Variáveis de Ambiente

```bash
# Criar arquivo .env
TMDB_API_KEY=your_api_key_here

# Usar no código
import 'package:flutter_dotenv/flutter_dotenv.dart';
final apiKey = dotenv.env['TMDB_API_KEY'];
```

### CI/CD com GitHub Actions

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
        with:
          flutter-version: '3.8.1'
      - run: flutter build apk

  build-web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.8.1'
      - run: flutter build web
```

### Performance

```bash
# Analisar tamanho do build
flutter build apk --analyze-size

# Profile de performance
flutter run --profile
```

## Verificação Final

Após instalação, execute estes comandos para verificar:

```bash
# Verificar Flutter
flutter doctor

# Verificar projeto
flutter analyze

# Executar testes
flutter test

# Build de verificação
flutter build apk --debug
```

Se tudo estiver funcionando, o TV Multimidia estará pronto para desenvolvimento e uso!

## Suporte

Para problemas específicos:
1. Verifique os logs de erro
2. Consulte a documentação do Flutter
3. Busque na comunidade
4. Abra uma issue no repositório

---

**Nota**: Este guia é atualizado para Flutter 3.8.1. Para versões diferentes, consulte a documentação oficial do Flutter.