import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../data/local/local_data_source.dart';
import '../data/remote/api_data_source.dart';
import '../widgets/qr_registration_widget.dart';

class SettingsScreen extends StatefulWidget {
  final AuthService? authService;
  final LocalDataSource? localDataSource;
  final ApiDataSource? apiDataSource;
  final String domain;

  const SettingsScreen({
    super.key,
    this.authService,
    this.localDataSource,
    this.apiDataSource,
    this.domain = 'tv-multimidia.com', // Domínio padrão
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();
  bool _isTestingConnection = false;

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
  }

  Future<void> _testDatabaseConnection() async {
    if (widget.apiDataSource == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API não configurada para teste de conexão'),
        ),
      );
      return;
    }

    setState(() => _isTestingConnection = true);

    try {
      final result = await widget.apiDataSource!.healthCheck();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Conexão com banco de dados OK!\nStatus: ${result['status']}\nTimestamp: ${result['timestamp']}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro na conexão com banco de dados: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isTestingConnection = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        children: [
          if (widget.authService == null ||
              !widget.authService!.isLoggedIn) ...[
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Login'),
              subtitle: const Text('Entre com sua conta'),
              onTap: () => _showLoginDialog(context),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('Cadastro de Usuário'),
              subtitle: const Text('Gerar QR code para cadastro'),
              onTap: () => _showQrRegistrationDialog(context),
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.person),
              title: Text('Olá, ${widget.authService!.currentUser?.name}'),
              subtitle: Text(widget.authService!.currentUser?.email ?? ''),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              subtitle: const Text('Sair da conta'),
              onTap: () {
                widget.authService!.logout();
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logout realizado com sucesso!'),
                  ),
                );
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Informações de Pagamento'),
            subtitle: const Text('Gerenciar métodos de pagamento'),
            onTap: () {
              if (widget.authService == null ||
                  !widget.authService!.isLoggedIn) {
                _showLoginRequiredDialog(context);
              } else {
                _showPaymentInfoDialog(context);
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: _isTestingConnection
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.network_check),
            title: const Text('Testar Conexão com Banco'),
            subtitle: const Text('Verificar se o PostgreSQL está conectado'),
            onTap: _isTestingConnection ? null : _testDatabaseConnection,
          ),
        ],
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _loginEmailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _loginPasswordController,
                decoration: const InputDecoration(labelText: 'Senha'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showQrRegistrationDialog(context);
                },
                child: const Text('Não tem conta? Cadastre-se'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (widget.authService != null) {
                  final success = await widget.authService!.login(
                    _loginEmailController.text,
                    _loginPasswordController.text,
                  );
                  Navigator.of(context).pop();
                  if (success) {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Login realizado com sucesso!'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email ou senha incorretos!'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Entrar'),
            ),
          ],
        );
      },
    );
  }

  void _showQrRegistrationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(16),
            child: QrRegistrationWidget(domain: widget.domain),
          ),
        );
      },
    );
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login Necessário'),
          content: const Text(
            'Você precisa estar logado para acessar esta funcionalidade.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showLoginDialog(context);
              },
              child: const Text('Fazer Login'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Informações de Pagamento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Número do Cartão',
                ),
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Data de Expiração',
                ),
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'CVV'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                // Lógica para salvar informações de pagamento
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Informações de pagamento salvas!'),
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
}
