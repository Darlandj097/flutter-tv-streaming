import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceInfoService {
  static const String _installationIdKey = 'installation_id';
  static const String _androidIdKey = 'android_id';

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Uuid _uuid = const Uuid();

  Future<String> getInstallationId() async {
    final prefs = await SharedPreferences.getInstance();
    String? installationId = prefs.getString(_installationIdKey);

    if (installationId == null) {
      installationId = _uuid.v4();
      await prefs.setString(_installationIdKey, installationId);
    }

    return installationId;
  }

  Future<String?> getAndroidId() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.id;
    } catch (e) {
      // Para plataformas que não são Android, retorna null
      return null;
    }
  }

  Future<String?> getDeviceId() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.id;
    } catch (e) {
      // Para outras plataformas, tenta usar iOS info
      try {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor;
      } catch (e) {
        // Para web ou outras plataformas, retorna null
        return null;
      }
    }
  }

  Future<Map<String, String>> getDeviceInfo() async {
    final installationId = await getInstallationId();
    final androidId = await getAndroidId();
    final deviceId = await getDeviceId();

    return {
      'installationId': installationId,
      'androidId': androidId ?? 'N/A',
      'deviceId': deviceId ?? 'N/A',
    };
  }

  Future<String> generateRegistrationUrl(String domain) async {
    final deviceInfo = await getDeviceInfo();
    final installationId = deviceInfo['installationId']!;
    final androidId = deviceInfo['androidId']!;

    // URL para redirecionar para o site de cadastro local (desenvolvimento)
    return 'http://localhost:8081/?installationId=$installationId&androidId=$androidId';
  }
}
