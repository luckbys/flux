import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;

Future<List<String>> resolveDns(String domain) async {
  return ['127.0.0.1'];
}

Future<bool> testInternetConnectivity() async {
  return html.window.navigator.onLine ?? true;
}

Future<bool> testSupabaseConnectivity(String supabaseUrl) async {
  try {
    final response = await html.HttpRequest.request(
      supabaseUrl,
      method: 'GET',
      sendData: null,
    );
    return response.status! >= 200 && response.status! < 500;
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
    print('❌ Erro ao obter IP via API externa para $domain: $e');
    return null;
  }
}