import 'dart:io';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../config/network_config.dart';

/// Utilitário para testar conectividade e diagnosticar problemas de rede
class ConnectivityTest {
  /// Executa um teste completo de conectividade
  static Future<ConnectivityResult> runFullTest() async {
    final result = ConnectivityResult();
    
    try {
      // 1. Testar conectividade básica com a internet
      result.hasInternet = await NetworkTester.instance.testInternetConnectivity();
      
      if (!result.hasInternet) {
        result.addError('Sem conectividade com a internet');
        return result;
      }
      
      // 2. Testar resolução DNS do Supabase
      final supabaseHost = Uri.parse(AppConfig.supabaseUrl).host;
      result.supabaseDnsResolved = await _testDnsResolution(supabaseHost);
      
      if (!result.supabaseDnsResolved) {
        result.addError('Falha na resolução DNS do Supabase: $supabaseHost');
      }
      
      // 3. Testar conectividade HTTP com Supabase
      result.supabaseReachable = await NetworkTester.instance.testSupabaseConnectivity(AppConfig.supabaseUrl);
      
      if (!result.supabaseReachable) {
        result.addError('Supabase não está acessível via HTTP');
      }
      
      // 4. Testar resolução DNS da Evolution API
      final evolutionHost = Uri.parse(AppConfig.evolutionApiBaseUrl).host;
      result.evolutionDnsResolved = await _testDnsResolution(evolutionHost);
      
      if (!result.evolutionDnsResolved) {
        result.addError('Falha na resolução DNS da Evolution API: $evolutionHost');
      }
      
      // 5. Testar conectividade HTTP com Evolution API
      result.evolutionReachable = await _testHttpConnectivity(AppConfig.evolutionApiBaseUrl);
      
      if (!result.evolutionReachable) {
        result.addError('Evolution API não está acessível via HTTP');
      }
      
      result.success = result.hasInternet && 
                      result.supabaseDnsResolved && 
                      result.supabaseReachable;
      
    } catch (e) {
      result.addError('Erro durante teste de conectividade: $e');
    }
    
    return result;
  }
  
  /// Testa resolução DNS para um hostname específico
  static Future<bool> _testDnsResolution(String hostname) async {
    try {
      final addresses = await NetworkTester.instance.resolveDns(hostname);
      if (kDebugMode) {
        print('DNS resolvido para $hostname: ${addresses.join(", ")}');
      }
      return addresses.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Erro na resolução DNS para $hostname: $e');
      }
      return false;
    }
  }
  
  /// Testa conectividade HTTP básica
  static Future<bool> _testHttpConnectivity(String url) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      
      client.close();
      
      final success = response.statusCode >= 200 && response.statusCode < 500;
      
      if (kDebugMode) {
        print('HTTP test para $url: ${response.statusCode} - ${success ? "Sucesso" : "Falha"}');
      }
      
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Erro no teste HTTP para $url: $e');
      }
      return false;
    }
  }
  
  /// Gera um relatório detalhado de conectividade
  static String generateReport(ConnectivityResult result) {
    final buffer = StringBuffer();
    
    buffer.writeln('=== RELATÓRIO DE CONECTIVIDADE ===');
    buffer.writeln('Status Geral: ${result.success ? "✅ SUCESSO" : "❌ FALHA"}');
    buffer.writeln('');
    
    buffer.writeln('📡 Conectividade:');
    buffer.writeln('  Internet: ${result.hasInternet ? "✅" : "❌"} ${result.hasInternet ? "Conectado" : "Sem conexão"}');
    buffer.writeln('');
    
    buffer.writeln('🗄️ Supabase:');
    buffer.writeln('  DNS: ${result.supabaseDnsResolved ? "✅" : "❌"} ${result.supabaseDnsResolved ? "Resolvido" : "Falha na resolução"}');
    buffer.writeln('  HTTP: ${result.supabaseReachable ? "✅" : "❌"} ${result.supabaseReachable ? "Acessível" : "Inacessível"}');
    buffer.writeln('  URL: ${AppConfig.supabaseUrl}');
    buffer.writeln('');
    
    buffer.writeln('🤖 Evolution API:');
    buffer.writeln('  DNS: ${result.evolutionDnsResolved ? "✅" : "❌"} ${result.evolutionDnsResolved ? "Resolvido" : "Falha na resolução"}');
    buffer.writeln('  HTTP: ${result.evolutionReachable ? "✅" : "❌"} ${result.evolutionReachable ? "Acessível" : "Inacessível"}');
    buffer.writeln('  URL: ${AppConfig.evolutionApiBaseUrl}');
    buffer.writeln('');
    
    if (result.errors.isNotEmpty) {
      buffer.writeln('❌ Erros Encontrados:');
      for (int i = 0; i < result.errors.length; i++) {
        buffer.writeln('  ${i + 1}. ${result.errors[i]}');
      }
      buffer.writeln('');
    }
    
    buffer.writeln('📱 Informações do Sistema:');
    buffer.writeln('  Plataforma: ${Platform.operatingSystem}');
    buffer.writeln('  Versão: ${Platform.operatingSystemVersion}');
    buffer.writeln('  Debug Mode: ${kDebugMode ? "Sim" : "Não"}');
    
    return buffer.toString();
  }
}

/// Resultado do teste de conectividade
class ConnectivityResult {
  bool success = false;
  bool hasInternet = false;
  bool supabaseDnsResolved = false;
  bool supabaseReachable = false;
  bool evolutionDnsResolved = false;
  bool evolutionReachable = false;
  List<String> errors = [];
  
  void addError(String error) {
    errors.add(error);
  }
  
  /// Retorna true se todos os serviços críticos estão funcionando
  bool get allCriticalServicesWorking => hasInternet && supabaseDnsResolved && supabaseReachable;
  
  /// Retorna uma lista de problemas encontrados
  List<String> get issues {
    final issues = <String>[];
    
    if (!hasInternet) issues.add('Sem conectividade com a internet');
    if (!supabaseDnsResolved) issues.add('DNS do Supabase não resolve');
    if (!supabaseReachable) issues.add('Supabase não está acessível');
    if (!evolutionDnsResolved) issues.add('DNS da Evolution API não resolve');
    if (!evolutionReachable) issues.add('Evolution API não está acessível');
    
    return issues;
  }
}