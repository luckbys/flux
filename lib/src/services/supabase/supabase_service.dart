import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_config.dart';
import '../../config/network_config.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? _client;
  bool _isInitialized = false;

  SupabaseClient get client {
    if (!_isInitialized || _client == null) {
      throw Exception(
          'Supabase não foi inicializado. Chame initialize() primeiro.');
    }
    return _client!;
  }

  bool get isInitialized => _isInitialized;

  /// Inicializa o cliente Supabase
  Future<bool> initialize() async {
    try {
      AppConfig.log('Inicializando Supabase...', tag: 'SupabaseService');

      // 🔧 Validar configuração antes de inicializar
      if (!AppConfig.isConfigurationValid) {
        AppConfig.log(
          '❌ ERRO: Configuração do Supabase inválida!\n'
          '📋 Para corrigir:\n'
          '1. Acesse https://supabase.com\n'
          '2. Crie um projeto ou acesse um existente\n'
          '3. Vá em Settings > API\n'
          '4. Copie a URL e chave anônima\n'
          '5. Atualize lib/src/config/app_config.dart',
          tag: 'SupabaseService',
        );
        return false;
      }

      // Verificar e tentar corrigir problemas de conectividade
      final canConnect = await NetworkTester.instance
          .monitorAndFixConnectivity(AppConfig.supabaseUrl);
      if (!canConnect) {
        AppConfig.log(
          '⚠️ Aviso: Problemas de conectividade com o Supabase detectados.\n'
          '📱 Se estiver no Android, verifique o guia ANDROID_DNS_FIX_GUIDE.md',
          tag: 'SupabaseService',
        );
        // Continua a inicialização mesmo com problemas, pois pode resolver depois
      }

      // Configurar Supabase com tratamento de erro melhorado
      try {
        await Supabase.initialize(
          url: AppConfig.supabaseUrl,
          anonKey: AppConfig.supabaseAnonKey,
          debug: AppConfig.isDevelopment,
        );

        _client = Supabase.instance.client;
        _isInitialized = true;

        AppConfig.log('✅ Supabase inicializado com sucesso!',
            tag: 'SupabaseService');

        // Testar a conexão após inicialização
        final connectionTest = await testConnection();
        if (!connectionTest) {
          AppConfig.log('⚠️ Supabase inicializado mas conexão instável',
              tag: 'SupabaseService');
        }

        return true;
      } catch (initError) {
        AppConfig.log('❌ Erro na inicialização do Supabase: $initError',
            tag: 'SupabaseService');

        // Tentar inicializar novamente com configurações mais básicas
        try {
          await Supabase.initialize(
            url: AppConfig.supabaseUrl,
            anonKey: AppConfig.supabaseAnonKey,
            debug: false, // Desabilitar debug para tentar novamente
          );

          _client = Supabase.instance.client;
          _isInitialized = true;

          AppConfig.log('✅ Supabase inicializado na segunda tentativa!',
              tag: 'SupabaseService');
          return true;
        } catch (retryError) {
          AppConfig.log('❌ Falha na segunda tentativa: $retryError',
              tag: 'SupabaseService');
          return false;
        }
      }
    } catch (e) {
      AppConfig.log('❌ Erro geral ao inicializar Supabase: $e',
          tag: 'SupabaseService');

      // Verificar se é erro de configuração
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('No address associated with hostname')) {
        AppConfig.log(
          '🔧 Este erro indica que as credenciais do Supabase estão incorretas.\n'
          'Verifique se você configurou corretamente em app_config.dart',
          tag: 'SupabaseService',
        );
      }

      return false;
    }
  }

  /// Verifica se o usuário está autenticado
  bool get isAuthenticated => _client?.auth.currentUser != null;

  /// Obtém o usuário atual
  User? get currentUser => _client?.auth.currentUser;

  /// Obtém o ID do usuário atual
  String? get currentUserId => _client?.auth.currentUser?.id;

  /// Realiza login com email e senha
  Future<AuthResponse?> signIn({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      // Verificar se está inicializado
      if (!_isInitialized) {
        AppConfig.log('❌ Supabase não inicializado!', tag: 'SupabaseService');
        throw Exception(
            'Supabase não está configurado corretamente. Verifique as credenciais em app_config.dart');
      }

      AppConfig.log('🔐 SupabaseService.signIn iniciado', tag: 'SupabaseService');
      AppConfig.log('📧 Email: $email', tag: 'SupabaseService');
      AppConfig.log('🔒 RememberMe: $rememberMe', tag: 'SupabaseService');
      AppConfig.log('🌐 URL: ${AppConfig.supabaseUrl}', tag: 'SupabaseService');
      
      AppConfig.log('🚀 Chamando client.auth.signInWithPassword...', tag: 'SupabaseService');
      
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      AppConfig.log('📥 Resposta recebida do Supabase Auth', tag: 'SupabaseService');
      AppConfig.log('👤 User ID: ${response.user?.id ?? "null"}', tag: 'SupabaseService');
      AppConfig.log('📧 User Email: ${response.user?.email ?? "null"}', tag: 'SupabaseService');
      AppConfig.log('🎫 Session válida: ${response.session?.accessToken != null}', tag: 'SupabaseService');
      AppConfig.log('⏰ Session expira em: ${response.session?.expiresAt}', tag: 'SupabaseService');
      
      if (response.user != null) {
        AppConfig.log('✅ Login realizado com sucesso!', tag: 'SupabaseService');

        // Se "Lembrar de mim" estiver ativado, configurar a sessão para persistir
        if (rememberMe && response.session != null) {
          // O Supabase Flutter já gerencia automaticamente a persistência da sessão
          // baseado na configuração do cliente. Por padrão, as sessões são persistentes.
          AppConfig.log('💾 Sessão será persistida (RememberMe ativo)',
              tag: 'SupabaseService');
        }
      } else {
        AppConfig.log('❌ Login falhou - usuário nulo', tag: 'SupabaseService');
      }

      return response;
    } catch (e) {
      AppConfig.log('💥 Erro no SupabaseService.signIn: $e', tag: 'SupabaseService');
      AppConfig.log('🔍 Tipo do erro: ${e.runtimeType}', tag: 'SupabaseService');
      rethrow;
    }
  }

  /// Realiza cadastro com email e senha
  Future<AuthResponse?> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Verificar se está inicializado
      if (!_isInitialized) {
        throw Exception(
            'Supabase não está configurado corretamente. Verifique as credenciais em app_config.dart');
      }

      AppConfig.log('Criando conta: $email', tag: 'SupabaseService');

      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: data,
      );

      if (response.user != null) {
        AppConfig.log('Conta criada com sucesso!', tag: 'SupabaseService');
      }

      return response;
    } catch (e) {
      AppConfig.log('Erro no cadastro: $e', tag: 'SupabaseService');
      rethrow;
    }
  }

  /// Realiza logout
  Future<void> signOut() async {
    try {
      AppConfig.log('Fazendo logout...', tag: 'SupabaseService');
      await client.auth.signOut();
      AppConfig.log('Logout realizado com sucesso!', tag: 'SupabaseService');
    } catch (e) {
      AppConfig.log('Erro no logout: $e', tag: 'SupabaseService');
      rethrow;
    }
  }

  /// Stream de mudanças de autenticação
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  /// Método genérico para executar queries
  SupabaseQueryBuilder from(String table) => client.from(table);

  /// Método para verificar conectividade
  Future<bool> testConnection() async {
    try {
      if (!_isInitialized) return false;

      // Tentar fazer uma query simples para testar a conexão
      // Usar a tabela 'users' que sabemos que existe
      await client.from('users').select('id').limit(1);
      return true;
    } catch (e) {
      AppConfig.log('Erro no teste de conectividade: $e',
          tag: 'SupabaseService');

      // Se for erro de tabela não encontrada, tentar uma query mais simples
      try {
        final session = client.auth.currentSession;
        return session != null;
      } catch (sessionError) {
        AppConfig.log('Erro ao verificar sessão: $sessionError',
            tag: 'SupabaseService');
        return false;
      }
    }
  }

  /// Cleanup
  void dispose() {
    _client = null;
    _isInitialized = false;
  }
}
