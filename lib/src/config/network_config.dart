import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'platform_network_mobile.dart'
    if (dart.library.html) 'platform_network_web.dart' as platform_network;

import 'network_config_mobile.dart' if (dart.library.html) 'empty.dart'
    as platform_config;

// Handled in platform files

class NetworkConfig {
  static final networkTester = NetworkTester._();
  static void setupHttpOverrides() {
    platform_config.platformSetupHttpOverrides();
  }

  static Future<void> preloadNetworkInfo(String supabaseUrl) async {
    final uri = Uri.parse(supabaseUrl);
    final domain = uri.host;

    await NetworkTester.instance.testSupabaseDns();

    if (networkTester._getCachedIp(domain) == null) {
      debugPrint(
          '⚠️ Não foi possível resolver o DNS do Supabase, tentando alternativa...');
      await networkTester._resolveDns('google.com');
      await networkTester._resolveDns(domain);

      if (networkTester._getCachedIp(domain) == null) {
        await networkTester.getIpFromExternalApi(domain);
      }
    }
  }

  static Future<bool> testSupabaseDns() async {
    return await NetworkTester.instance.testSupabaseDns();
  }

  static void showDnsWarningDialog(BuildContext context) {
    NetworkTester.instance.showDnsWarningDialog(context);
  }
}

class NetworkTester {
  // Cache de IPs resolvidos
  final Map<String, String> _dnsCache = {};
  bool _lastKnownConnectivityStatus = false;
  DateTime _lastConnectivityCheck = DateTime.now();
  static const Duration _connectivityCheckInterval = Duration(minutes: 5);

  NetworkTester._();
  static final NetworkTester _instance = NetworkTester._();

  /// Getter para acessar a instância singleton
  static NetworkTester get instance => _instance;

  /// Testa a resolução de DNS para o domínio do Supabase
  Future<bool> testSupabaseDns() async {
    try {
      final addresses = await _resolveDns('inhaxsjsjybpxtohfgmp.supabase.co');
      debugPrint('🔍 Endereços DNS resolvidos: ${addresses.join(', ')}');
      return addresses.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Erro ao resolver DNS do Supabase: $e');
      return false;
    }
  }

  /// Exibe um diálogo de aviso sobre problemas de DNS
  void showDnsWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Problema de Conectividade Detectado'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: [
                Text(
                  'O aplicativo está tendo dificuldades para se conectar ao servidor Supabase.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('Possíveis soluções:'),
                SizedBox(height: 8),
                Text('• Verifique sua conexão com a internet'),
                Text('• Tente trocar para uma rede Wi-Fi diferente'),
                Text('• Configure um DNS público (8.8.8.8 ou 1.1.1.1)'),
                Text('• Desative temporariamente VPN ou proxy'),
                SizedBox(height: 16),
                Text(
                  'Para mais detalhes, consulte o arquivo ANDROID_DNS_FIX_GUIDE.md',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Tentar Novamente'),
              onPressed: () {
                Navigator.of(context).pop();
                // Aqui você pode adicionar lógica para tentar reconectar
              },
            ),
            TextButton(
              child: const Text('Continuar Mesmo Assim'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Método público para resolver DNS
  Future<List<String>> resolveDns(String domain) async {
    return await _resolveDns(domain);
  }

  Future<List<String>> _resolveDns(String domain) async {
    final addresses = await platform_network.resolveDns(domain);
    if (addresses.isNotEmpty) {
      _dnsCache[domain] = addresses.first.toString();
    }
    return addresses.map((addr) => addr.toString()).toList();
  }

  /// Obtém IP de um domínio usando a API DNS do Google
  Future<String?> getIpFromExternalApi(String domain) async {
    final ip = await platform_network.getIpFromExternalApi(domain);
    if (ip != null) {
      _dnsCache[domain] = ip;
    }
    return ip;
  }

  /// Resolve um domínio para seu IP

  /// Obtém o IP em cache para um domínio
  String? _getCachedIp(String domain) {
    return _dnsCache[domain];
  }

  /// Testa a conectividade com a internet
  Future<bool> testInternetConnectivity() async {
    try {
      final isConnected = await platform_network.testInternetConnectivity();
      _lastKnownConnectivityStatus = isConnected;
      _lastConnectivityCheck = DateTime.now();
      return isConnected;
    } catch (e) {
      debugPrint('❌ Erro ao testar conectividade com a internet: $e');
      _lastKnownConnectivityStatus = false;
      _lastConnectivityCheck = DateTime.now();
      return false;
    }
  }

  /// Testa a conectividade com o Supabase
  Future<bool> testSupabaseConnectivity(String supabaseUrl) async {
    try {
      return await platform_network.testSupabaseConnectivity(supabaseUrl);
    } catch (e) {
      debugPrint('❌ Erro ao testar conectividade com Supabase: $e');
      return false;
    }
  }

  /// Verifica se é hora de testar a conectividade novamente
  bool get shouldCheckConnectivity {
    return DateTime.now().difference(_lastConnectivityCheck) >
        _connectivityCheckInterval;
  }

  /// Atualiza o status da última verificação de conectividade
  void updateConnectivityStatus(bool status) {
    _lastKnownConnectivityStatus = status;
    _lastConnectivityCheck = DateTime.now();
  }

  /// Retorna o último status de conectividade conhecido
  bool get lastKnownConnectivityStatus => _lastKnownConnectivityStatus;
  // Singleton para armazenar o status da conectividade

  /// Monitora a conectividade e tenta métodos alternativos quando necessário
  Future<bool> monitorAndFixConnectivity(String supabaseUrl) async {
    // Se não for hora de verificar, retorna o último status conhecido
    if (!shouldCheckConnectivity) return _lastKnownConnectivityStatus;

    // No ambiente web, usar verificação simplificada
    if (kIsWeb) {
      debugPrint('🌐 Ambiente web - usando verificação simplificada');
      final isConnected = await testSupabaseConnectivity(supabaseUrl);
      updateConnectivityStatus(isConnected);
      return isConnected;
    }

    // Testar conectividade direta
    bool isConnected = await testSupabaseConnectivity(supabaseUrl);

    // Se não conseguiu conectar, tentar métodos alternativos
    if (!isConnected) {
      debugPrint(
          '⚠️ Problemas de conectividade detectados, tentando métodos alternativos...');

      // Tentar resolver DNS primeiro
      final uri = Uri.parse(supabaseUrl);
      final addresses = await _resolveDns(uri.host);
      if (addresses.isNotEmpty) {
        // Se DNS resolveu, tentar conectar novamente
        isConnected = await testSupabaseConnectivity(supabaseUrl);
      } else {
        // Se DNS falhou, tentar com IP direto
        debugPrint('⚠️ DNS falhou, tentando IP direto...');
        try {
          final ip = _getCachedIp(uri.host);

          if (ip != null) {
            isConnected = await testSupabaseConnectivity(supabaseUrl);
          }
        } catch (e) {
          debugPrint('❌ Erro ao tentar IP direto: $e');
        }
      }
    }

    // Atualizar status da conectividade
    updateConnectivityStatus(isConnected);
    return isConnected;
  }

  /// Verifica se o dispositivo está usando DNS personalizado
  Future<bool> checkCustomDns() async {
    try {
      // Tenta resolver um domínio conhecido usando diferentes servidores DNS
      final googleDns = await _resolveDns('google.com');

      if (googleDns.isEmpty) {
        debugPrint(
            '⚠️ Não foi possível resolver google.com - possível problema de DNS');
        return false;
      }

      // Verifica se consegue resolver o domínio do Supabase
      final supabaseDns = await _resolveDns('supabase.co');

      // Compara os resultados
      if (googleDns.isNotEmpty && supabaseDns.isEmpty) {
        debugPrint(
            '⚠️ DNS seletivo detectado: resolve google.com mas não supabase.co');
        debugPrint(
            '📋 Recomendação: Configure um DNS público como 8.8.8.8 ou 1.1.1.1');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Erro ao verificar DNS personalizado: $e');
      return false;
    }
  }
}
