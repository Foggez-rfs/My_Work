// Сервис экстренного вызова помощи (SOS)
// При нажатии кнопки SOS отправляет SMS доверенному контакту с геолокацией
import 'package:url_launcher/url_launcher.dart';

class SosService {
  // Позвонить доверенному контакту
  static Future<void> callEmergencyContact(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Не удалось совершить звонок';
    }
  }

  // Отправить SMS доверенному контакту
  static Future<void> sendSosSms({
    required String phoneNumber,
    required String message,
  }) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: {'body': message},
    );
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      throw 'Не удалось отправить SMS';
    }
  }

  // Позвонить в экстренные службы (112)
  static Future<void> callEmergencyServices() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '112');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  // Сформировать SOS-сообщение с геолокацией
  static String buildSosMessage({
    required String userName,
    double? lat,
    double? lon,
  }) {
    String message = '🆘 SOS! $userName нуждается в помощи!';
    
    if (lat != null && lon != null) {
      message += '\n\n📍 Геолокация: https://maps.google.com/?q=$lat,$lon';
    }
    
    message += '\n\nПожалуйста, позвоните немедленно!';
    
    return message;
  }

  // Активировать SOS: звонок + SMS
  static Future<void> activateSos({
    required String emergencyPhone,
    required String userName,
    double? lat,
    double? lon,
  }) async {
    final message = buildSosMessage(
      userName: userName,
      lat: lat,
      lon: lon,
    );

    // Сначала отправляем SMS
    await sendSosSms(phoneNumber: emergencyPhone, message: message);
    
    // Затем звоним
    await Future.delayed(const Duration(seconds: 2));
    await callEmergencyContact(emergencyPhone);
  }
}
