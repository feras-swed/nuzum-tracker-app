import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}


class ApiService {

  static const String _apiUrl = 'https://d72f2aef-918c-4148-9723-15870f8c7cf6-00-2c1ygyxvqoldk.riker.replit.dev/api/external/employee-location';
  static Future<bool> sendLocation({
    required String apiKey,
    required String jobNumber,
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final formattedDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(now);
      
      final body = {
        "api_key": apiKey,
        "job_number": jobNumber,
        "latitude": latitude,
        "longitude": longitude,
        "accuracy": accuracy,
        "recorded_at": formattedDate,
      };

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print('✅ [API] Location sent successfully!');
        return true;
      } else {
        print('❌ [API] Failed to send location. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ [API] Error sending location: $e');
      return false;
    }
  }
}