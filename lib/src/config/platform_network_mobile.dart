import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

Future<List<InternetAddress>> resolveDns(String domain) async {
  try {
    final addresses = await InternetAddress.lookup(domain);
    return addresses;
  } catch (e) {
    debugPrint('❌ Erro ao resolver DNS para $domain: $e');
    return [];
  }
}

Future<bool> testInternetConnectivity() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (e) {
    debugPrint('❌ Erro ao testar conectividade com a internet: $e');
    return false;
  }
}

Future<bool> testSupabaseConnectivity(String supabaseUrl) async {
  try {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);

    final request = await client.getUrl(Uri.parse(supabaseUrl));
    final response = await request.close();

    client.close();

    return response.statusCode >= 200 && response.statusCode < 500;
  } catch (e) {
    debugPrint('❌ Erro ao testar conectividade com Supabase: $e');
    return false;
  }
}

Future<String?> getIpFromExternalApi(String domain) async {
  try {
    final client = HttpClient();
    final uri = Uri.parse('https://dns.google/resolve?name=$domain');
    final request = await client.getUrl(uri);
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    final data = json.decode(responseBody);

    if (data['Answer'] != null && data['Answer'].isNotEmpty) {
      final ip = data['Answer'][0]['data'];
      if (ip != null) {
        return ip;
      }
    }
    return null;
  } catch (e) {
    debugPrint('❌ Erro ao obter IP via API externa para $domain: $e');
    return null;
  }
}