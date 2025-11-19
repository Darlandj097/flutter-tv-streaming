import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../utils/device_info_service.dart';

class QrRegistrationWidget extends StatefulWidget {
  final String domain;

  const QrRegistrationWidget({super.key, required this.domain});

  @override
  State<QrRegistrationWidget> createState() => _QrRegistrationWidgetState();
}

class _QrRegistrationWidgetState extends State<QrRegistrationWidget> {
  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  String? _registrationUrl;
  Map<String, String>? _deviceInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      _registrationUrl = await _deviceInfoService.generateRegistrationUrl(
        widget.domain,
      );
      _deviceInfo = await _deviceInfoService.getDeviceInfo();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar informações do dispositivo: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando informações do dispositivo...'),
          ],
        ),
      );
    }

    if (_registrationUrl == null || _deviceInfo == null) {
      return const Center(
        child: Text('Erro ao carregar informações do dispositivo'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Cadastro de Usuário',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Escaneie o QR code abaixo para acessar o site de cadastro',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: _registrationUrl!,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Ou acesse o link manualmente:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              _registrationUrl!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Informações do Dispositivo:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Domínio: ${widget.domain}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ID da Instalação: ${_deviceInfo!['installationId']}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID do Android: ${_deviceInfo!['androidId']}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID do Dispositivo: ${_deviceInfo!['deviceId']}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadDeviceInfo,
            icon: const Icon(Icons.refresh),
            label: const Text('Atualizar QR Code'),
          ),
        ],
      ),
    );
  }
}
