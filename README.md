# 🎬 TV Multimidia - Portfólio Educacional

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Clean Architecture](https://img.shields.io/badge/Clean%20Architecture-checked?style=for-the-badge&color=green)
![SQLite](https://img.shields.io/badge/SQLite-07405E?style=for-the-badge&logo=sqlite&logoColor=white)

> **Projeto desenvolvido para demonstrar habilidades avançadas em engenharia de software móvel e desktop, focando em Clean Architecture e interfaces para TV.**

[![Assista ao Vídeo](https://img.youtube.com/vi/COLOCAR_ID_DO_VIDEO_AQUI/0.jpg)](https://youtu.be/FSd5IIVLUsI))

---

## 📋 Sobre o Projeto

O **TV Multimidia** é uma simulação de plataforma de streaming (estilo Netflix) projetada para funcionar nativamente em **Smart TVs (Android TV)**, Desktop (Windows) e Mobile.

O diferencial técnico deste projeto não é apenas a interface, mas a **engenharia por trás dela**:
* **Offline-First:** O app funciona parcialmente sem internet graças ao cache local via SQLite.
* **TV Navigation:** Sistema complexo de gerenciamento de foco para navegar usando apenas as setas do teclado/controle remoto.
* **Clean Architecture:** Código desacoplado e testável.

## 🚀 Tecnologias e Arquitetura

O projeto segue estritamente os princípios da **Clean Architecture** para garantir escalabilidade:

| Camada | Responsabilidade | Tecnologias |
| :--- | :--- | :--- |
| **Presentation** | UI e Gerenciamento de Estado | Flutter, Bloc/Provider |
| **Domain** | Regras de Negócio (Pure Dart) | UseCases, Entities |
| **Data** | Repositórios e Fontes de Dados | Repository Pattern |
| **External** | APIs e Banco de Dados | TMDB API, Sqflite (SQLite) |

### 🛠️ Principais Features
- [x] **Consumo de API REST:** Integração completa com a API do TMDB (The Movie Database).
- [x] **Persistência de Dados:** Banco de dados SQLite local para favoritos e cache.
- [x] **Design Responsivo:** Layout adaptável para telas grandes (TV) e pequenas (Celular).
- [x] **Tratamento de Erros:** Feedback visual amigável para o usuário em caso de falhas de rede.

## 📂 Estrutura de Pastas (Clean Arch)

```bash
lib/
├── src/
│   ├── core/           # Configurações globais e utils
│   ├── data/           # Implementação de Repositórios e DataSources (API/SQLite)
│   ├── domain/         # Entidades e Contratos (Interfaces)
│   └── presentation/   # Widgets, Pages e Controllers
└── main.dart
⚠️ Aviso Legal (Educational Purpose)
Este software foi desenvolvido exclusivamente para fins de estudo e portfólio.

Não fornece acesso a conteúdo pirata ou IPTV ilegal.

Utiliza dados públicos da API oficial do TMDB.

O código serve como demonstração técnica para recrutadores e comunidade dev.

🔧 Como rodar o projeto
Clone o repositório:

Bash

git clone [https://github.com/Darlandj097/flutter-streaming-tv-clean-arch.git](https://github.com/Darlandj097/flutter-streaming-tv-clean-arch.git)
Instale as dependências:

Bash

flutter pub get
Configure a API Key: Crie um arquivo .env na raiz e adicione sua chave do TMDB (ou solicite ao autor para testes):

Fragmento do código

TMDB_API_KEY=SUA_CHAVE_AQUI
Execute:

Bash

flutter run
Desenvolvido por Darlan - LinkedIn

