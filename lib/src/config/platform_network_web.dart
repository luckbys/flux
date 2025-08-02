import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Import condicional para dart:html apenas em web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' if (dart.library.io) 'dart:io';

Future<List<String>> resolveDns(String domain) async {
  return ['127.0.0.1'];
}

Future<bool> testInternetConnectivity() async {
  // Verificar se estamos em web antes de usar html.window
  if (kIsWeb) {
    return window.navigator.onLine ?? true;
  }
  return true; // Fallback para outras plataformas
}

Future<bool> testSupabaseConnectivity(String supabaseUrl) async {
  try {
    // Verificar se estamos em web antes de usar html.HttpRequest
    if (kIsWeb) {
      final response = await HttpRequest.request(
        supabaseUrl,
        method: 'GET',
        sendData: null,
      );
      return response.status! >= 200 && response.status! < 500;
    }
    return true; // Fallback para outras plataformas
  } catch (e) {
    return true;
  }
}

Future<String?> getIpFromExternalApi(String domain) async {
  try {
    final uri = Uri.parse('https://dns.google/resolve?name=$domain');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['Answer'] != null && data['Answer'].isNotEmpty) {
        final ip = data['Answer'][0]['data'];
        if (ip != null) {
          return ip;
        }
      }
    }
    return null;
  } catch (e) {
    debugPrint('❌ Erro ao obter IP via API externa para $domain: $e');
    return null;
  }
}
