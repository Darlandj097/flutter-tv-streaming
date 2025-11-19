import '../data/local/local_data_source.dart';
import '../data/remote/api_data_source.dart';
import '../data/models/user.dart';

class AuthService {
  final LocalDataSource? _localDataSource;
  final ApiDataSource? _apiDataSource;

  AuthService(this._localDataSource, {ApiDataSource? apiDataSource})
    : _apiDataSource = apiDataSource;

  User? _currentUser;

  User? get currentUser => _currentUser;

  Future<bool> register(
    String name,
    String email,
    String password, {
    String? installationId,
    String? androidId,
  }) async {
    try {
      if (_apiDataSource != null) {
        // Usar API para web
        final result = await _apiDataSource!.register(name, email, password);
        _currentUser = User(
          id: result['id'],
          name: result['name'],
          email: result['email'],
          password: '', // Não armazenar senha em memória
        );
        return true;
      } else if (_localDataSource != null) {
        // Usar SQLite para desktop
        final existingUser = await _localDataSource!.getUserByEmail(email);
        if (existingUser != null) {
          return false; // User already exists
        }

        final user = User(name: name, email: email, password: password);
        final userId = await _localDataSource!.createUser(user);
        _currentUser = User(
          id: userId,
          name: name,
          email: email,
          password: password,
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      if (_apiDataSource != null) {
        // Usar API para web
        final result = await _apiDataSource!.login(email, password);
        _currentUser = User(
          id: result['user']['id'],
          name: result['user']['name'],
          email: result['user']['email'],
          password: '', // Não armazenar senha em memória
        );
        return true;
      } else if (_localDataSource != null) {
        // Usar SQLite para desktop
        final user = await _localDataSource!.authenticateUser(email, password);
        if (user != null) {
          _currentUser = user;
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void logout() {
    _currentUser = null;
  }

  bool get isLoggedIn => _currentUser != null;
}
