import 'dart:io';

class CustomHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);

    client.connectionTimeout = const Duration(seconds: 30);
    client.idleTimeout = const Duration(seconds: 30);

    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      return host.contains('supabase.co') || host.contains('devsible.com.br');
    };

    return client;
  }

  @override
  String findProxyFromEnvironment(Uri url, Map<String, String>? environment) {
    if (url.host.contains('supabase.co') || url.host.contains('devsible.com.br')) {
      return 'DIRECT';
    }
    return super.findProxyFromEnvironment(url, environment);
  }
}

void platformSetupHttpOverrides() {
  HttpOverrides.global = CustomHttpOverrides();
}