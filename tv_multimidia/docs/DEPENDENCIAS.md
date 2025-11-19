# Dependências e Configurações

## Visão Geral

Este documento descreve todas as dependências utilizadas no projeto TV Multimidia, suas finalidades e configurações específicas no `pubspec.yaml`.

## Arquivo pubspec.yaml

```yaml
name: tv_multimidia
description: "A new Flutter project."
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.8.1
```

## Dependências de Produção

### Banco de Dados e Persistência

#### sqflite: ^2.4.1
- **Finalidade**: Biblioteca SQLite para Flutter
- **Uso**: Armazenamento local de dados em dispositivos móveis e desktop
- **Plataformas**: Android, iOS, Windows, Linux, macOS
- **Documentação**: https://pub.dev/packages/sqflite

#### sqflite_common_ffi: ^2.3.3
- **Finalidade**: Extensão FFI para sqflite em desktop
- **Uso**: Suporte ao SQLite em plataformas desktop (Windows, Linux, macOS)
- **Dependência**: Necessária para sqflite funcionar em desktop
- **Documentação**: https://pub.dev/packages/sqflite_common_ffi

#### sqflite_common_ffi_web: ^0.4.0
- **Finalidade**: Suporte ao sqflite na web
- **Uso**: Emulação de SQLite na web usando IndexedDB
- **Limitações**: Funciona apenas para leitura; operações de escrita falham na web
- **Documentação**: https://pub.dev/packages/sqflite_common_ffi_web

#### drift: ^2.20.0
- **Finalidade**: ORM avançado para SQLite
- **Uso**: Abstração de queries SQL, migrações, relacionamentos
- **Alternativa**: Usado em conjunto com sqflite para funcionalidades avançadas
- **Documentação**: https://pub.dev/packages/drift

#### sqlite3_flutter_libs: ^0.5.24
- **Finalidade**: Bibliotecas nativas SQLite para Flutter
- **Uso**: Binários SQLite otimizados para cada plataforma
- **Benefício**: Melhor performance e compatibilidade
- **Documentação**: https://pub.dev/packages/sqlite3_flutter_libs

### Rede e Comunicação

#### http: ^1.5.0
- **Finalidade**: Cliente HTTP para Dart
- **Uso**: Comunicação com API TMDB
- **Características**: Suporte a GET, POST, PUT, DELETE
- **Documentação**: https://pub.dev/packages/http

### Sistema de Arquivos

#### path_provider: ^2.1.5
- **Finalidade**: Acesso a diretórios específicos da plataforma
- **Uso**: Localização do banco de dados SQLite
- **Diretórios**: Documents, Downloads, Cache, etc.
- **Documentação**: https://pub.dev/packages/path_provider

### Armazenamento Local

#### shared_preferences: ^2.5.3
- **Finalidade**: Armazenamento de chave-valor simples
- **Uso**: Configurações do usuário, preferências
- **Plataformas**: Todas suportadas pelo Flutter
- **Documentação**: https://pub.dev/packages/shared_preferences

### Serialização JSON

#### json_annotation: ^4.9.0
- **Finalidade**: Anotações para serialização JSON
- **Uso**: Marcar classes e campos para geração automática de código
- **Dependência**: Usado com build_runner
- **Documentação**: https://pub.dev/packages/json_annotation

### Interface do Usuário

#### cupertino_icons: ^1.0.8
- **Finalidade**: Ícones no estilo iOS
- **Uso**: Interface consistente em todas as plataformas
- **Fonte**: Cupertino Icons font
- **Documentação**: https://pub.dev/packages/cupertino_icons

## Dependências de Desenvolvimento

#### build_runner: ^2.4.13
- **Finalidade**: Executor de builders de código
- **Uso**: Geração de código automático (serialização JSON)
- **Comando**: `flutter pub run build_runner build`
- **Documentação**: https://pub.dev/packages/build_runner

#### json_serializable: ^6.8.0
- **Finalidade**: Builder para gerar código de serialização JSON
- **Uso**: Gera métodos `fromJson` e `toJson` automaticamente
- **Anotações**: `@JsonSerializable()`, `@JsonKey()`
- **Documentação**: https://pub.dev/packages/json_serializable

#### flutter_lints: ^5.0.0
- **Finalidade**: Conjunto de regras de lint recomendadas
- **Uso**: Análise estática de código, identificação de problemas
- **Configuração**: `analysis_options.yaml`
- **Documentação**: https://pub.dev/packages/flutter_lints

## Configurações Flutter

### Material Design
```yaml
flutter:
  uses-material-design: true
```

- **Finalidade**: Habilita Material Icons
- **Benefício**: Acesso aos ícones do Material Design
- **Uso**: `Icon(Icons.movie)`, `Icon(Icons.tv)`, etc.

### Assets (Opcional)
```yaml
# assets:
#   - images/a_dot_burr.jpeg
#   - images/a_dot_ham.jpeg
```

- **Estrutura**: Comentada por padrão
- **Uso**: Imagens, fontes, arquivos estáticos
- **Formato**: Lista de caminhos relativos

### Fonts (Opcional)
```yaml
# fonts:
#   - family: Schyler
#     fonts:
#       - asset: fonts/Schyler-Regular.ttf
#       - asset: fonts/Schyler-Italic.ttf
#         style: italic
```

- **Estrutura**: Comentada por padrão
- **Uso**: Fontes customizadas
- **Formato**: Família e variantes

## Configuração do Projeto

### Versão
```yaml
version: 1.0.0+1
```

- **Formato**: `major.minor.patch+build`
- **Android**: `versionName` = "1.0.0", `versionCode` = 1
- **iOS**: `CFBundleShortVersionString` = "1.0.0", `CFBundleVersion` = "1"
- **Windows**: Parte da versão do produto e arquivo

### Ambiente SDK
```yaml
environment:
  sdk: ^3.8.1
```

- **Significado**: Compatível com Dart SDK 3.8.1 ou superior
- **Restrição**: Até próxima quebra de compatibilidade (4.0.0)

### Publicação
```yaml
publish_to: 'none'
```

- **Finalidade**: Impede publicação acidental no pub.dev
- **Uso**: Projetos privados
- **Para publicar**: Remover ou alterar para `'https://pub.dev'`

## Dependências Nativas por Plataforma

### Android
- **Gradle**: Configurado em `android/build.gradle.kts`
- **Kotlin**: Usado para configuração nativa
- **Min SDK**: Definido nas configurações do Android

### iOS
- **Swift/Objective-C**: Para código nativo
- **CocoaPods**: Gerenciamento de dependências iOS
- **Xcode**: Ambiente de desenvolvimento

### Desktop (Windows/Linux/macOS)
- **FFI**: Foreign Function Interface para SQLite
- **CMake**: Sistema de build para código nativo
- **Visual Studio**: Para Windows (C++)

### Web
- **JavaScript**: Compilação do Dart para JS
- **IndexedDB**: Emulação de SQLite na web
- **Service Workers**: Para funcionalidades offline

## Gerenciamento de Dependências

### Atualização
```bash
# Atualizar para versões compatíveis mais recentes
flutter pub upgrade

# Atualizar para major versions (potencialmente breaking)
flutter pub upgrade --major-versions
```

### Verificação
```bash
# Verificar dependências desatualizadas
flutter pub outdated

# Verificar dependências não utilizadas
flutter pub deps
```

### Resolução de Conflitos
```bash
# Limpar cache e reinstalar
flutter pub cache clean
flutter pub get
```

## Considerações de Segurança

### Chaves de API
- **TMDB API Key**: Hardcoded no código (não recomendado para produção)
- **Recomendação**: Mover para variáveis de ambiente ou configuração segura

### Dependências Vulneráveis
- **Monitoramento**: Usar `flutter pub audit` regularmente
- **Atualizações**: Manter dependências atualizadas
- **Auditoria**: Verificar fontes das dependências

## Otimização

### Tamanho do APK/IPA
- **Análise**: `flutter build apk --analyze-size`
- **Otimização**: Remover dependências não utilizadas
- **Compressão**: Ativada por padrão

### Performance
- **Lazy Loading**: Dependências carregadas sob demanda
- **Tree Shaking**: Remoção de código não utilizado
- **Minificação**: Para builds de release

## Troubleshooting

### Problemas Comuns

#### sqflite na Web
- **Erro**: "Unsupported operation: Unsupported on the web"
- **Solução**: Usar apenas dados remotos na web ou implementar alternativa

#### Versões Incompatíveis
- **Sintoma**: Erros de compilação
- **Solução**: Verificar compatibilidade de versões no pub.dev

#### Dependências Conflitantes
- **Sintoma**: "Version solving failed"
- **Solução**: Ajustar restrições de versão ou resolver conflitos

Este documento serve como referência completa para entender e gerenciar as dependências do projeto TV Multimidia.