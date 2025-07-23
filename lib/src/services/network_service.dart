import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bkcrm_flutter/src/config/app_constants.dart';
import 'package:http/http.dart' as http;

class NetworkTester {
  static final NetworkTester instance = NetworkTester._internal();
  factory NetworkTester() => instance;
  NetworkTester._internal();

  Future<bool> testInternetConnectivity() async {
    if (kIsWeb) {
      // Para web, usar HTTP request simples
      try {
        final response = await http.get(Uri.parse('https://www.google.com')).timeout(const Duration(seconds: 5));
        return response.statusCode == 200;
      } catch (_) {
        return false;
      }
    } else {
      // Para mobile/desktop, usar InternetAddress.lookup
      try {
        final result = await InternetAddress.lookup('google.com');
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on SocketException catch (_) {
        return false;
      }
    }
  }

  Future<bool> testSupabaseDns() async {
    if (kIsWeb) {
      // Para web, sempre retornar true pois DNS é gerenciado pelo browser
      return true;
    } else {
      // Para mobile/desktop, usar InternetAddress.lookup
      try {
        final result = await InternetAddress.lookup('supabase.co');
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on SocketException catch (_) {
        return false;
      }
    }
  }

  Future<bool> testSupabaseConnectivity(String supabaseUrl) async {
    if (kIsWeb) {
      // Para web, testar conectividade HTTP
      try {
        final response = await http.get(Uri.parse('$supabaseUrl/rest/v1/')).timeout(const Duration(seconds: 10));
        return response.statusCode == 200 || response.statusCode == 401; // 401 é esperado sem auth
      } catch (_) {
        return false;
      }
    } else {
      // Para mobile/desktop, usar InternetAddress.lookup
      try {
        final uri = Uri.parse(supabaseUrl);
        final result = await InternetAddress.lookup(uri.host);
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on SocketException catch (_) {
        return false;
      }
    }
  }

  void showDnsWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(AppConstants.dnsProblemTitle),
          content: const Text(AppConstants.dnsProblemContent),
          actions: <Widget>[
            TextButton(
              child: const Text(AppConstants.ok),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void configureHttpOverrides() {
    // HTTP overrides configuration if needed
  }

  Future<void> preloadDnsInfo(String supabaseUrl) async {
    // Preload DNS information if needed
  }
}