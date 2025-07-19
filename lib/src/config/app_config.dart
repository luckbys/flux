class AppConfig {
  // ⚠️ IMPORTANTE: Substitua pelas suas credenciais reais do Supabase
  // Para obter essas informações:
  // 1. Acesse https://supabase.com
  // 2. Crie um novo projeto ou acesse um existente
  // 3. Vá em Settings > API
  // 4. Copie a URL e as chaves abaixo

  // 🔗 Supabase Configuration
  // SUBSTITUA pela URL do seu projeto Supabase
  static const String supabaseUrl = 'https://inhaxsjsjybpxtohfgmp.supabase.co';

  // SUBSTITUA pela sua chave anônima (anon/public key)
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImluaGF4c2pzanlicHh0b2hmZ21wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU1MzYyODgsImV4cCI6MjA2MTExMjI4OH0.KCl6UGrNhBuUfESwr-znf5BgEPmAXDanHRd8qP8xGJc';

  // SUBSTITUA pela sua chave de serviço (service_role key) - OPCIONAL
  static const String supabaseServiceKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImluaGF4c2pzanlicHh0b2hmZ21wIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0NTUzNjI4OCwiZXhwIjoyMDYxMTEyMjg4fQ.gc1U-TA4QZ6J5ET_0-R1QALnwdT28CKU660oSW2tmrI';

  // Evolution API Configuration
  static const String evolutionApiBaseUrl = 'https://evochat.devsible.com.br';
  static const String evolutionApiKey = '429683C4C977415CAAFCCE10F7D57E11';
  static const String evolutionInstanceName = 'your-instance-name';
  static const String evolutionWebhookUrl =
      'https://your-app.com/webhook/evolution';

  // WhatsApp Configuration
  static const String whatsappBusinessName = 'BKCRM Support';
  static const Duration messageTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;

  // Media Configuration
  static const int maxFileSize = 16 * 1024 * 1024; // 16MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> allowedDocumentTypes = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'txt'
  ];
  static const List<String> allowedAudioTypes = ['mp3', 'wav', 'ogg', 'aac'];
  static const List<String> allowedVideoTypes = ['mp4', 'avi', 'mov', 'mkv'];

  // Webhook Configuration
  static const String webhookSecret = 'your-webhook-secret';
  static const Duration webhookTimeout = Duration(seconds: 10);

  // Development/Production flags
  static const bool isDevelopment = true;
  static const bool enableLogging = true;
  static const bool enableWebhookValidation = true;

  // API Endpoints
  static String get sendMessageEndpoint =>
      '$evolutionApiBaseUrl/message/sendText/$evolutionInstanceName';
  static String get sendMediaEndpoint =>
      '$evolutionApiBaseUrl/message/sendMedia/$evolutionInstanceName';
  static String get instanceInfoEndpoint =>
      '$evolutionApiBaseUrl/instance/fetchInstances';
  static String get qrCodeEndpoint =>
      '$evolutionApiBaseUrl/instance/connect/$evolutionInstanceName';
  static String get webhookSetupEndpoint =>
      '$evolutionApiBaseUrl/webhook/set/$evolutionInstanceName';

  // Headers
  static Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'apikey': evolutionApiKey,
      };

  // Logging
  static void log(String message, {String? tag}) {
    if (enableLogging) {
      final timestamp = DateTime.now().toIso8601String();
      final logTag = tag ?? 'AppConfig';
      print('[$timestamp] [$logTag] $message');
    }
  }

  // 🔧 Método para validar se as configurações estão corretas
  static bool get isConfigurationValid {
    // Verificar se as credenciais são válidas
    final hasValidUrl = supabaseUrl.isNotEmpty &&
        supabaseUrl.contains('.supabase.co') &&
        supabaseUrl.startsWith('https://');

    final hasValidKey = supabaseAnonKey.isNotEmpty &&
        supabaseAnonKey.length > 100; // Chaves Supabase são longas

    final isValid = hasValidUrl && hasValidKey;

    if (!isValid) {
      log('Configuração inválida detectada:', tag: 'AppConfig');
      log('URL válida: $hasValidUrl', tag: 'AppConfig');
      log('Chave válida: $hasValidKey', tag: 'AppConfig');
    }

    return isValid;
  }

  // 🔧 Método para obter informações de configuração
  static Map<String, dynamic> get configurationInfo {
    return {
      'supabaseUrl': supabaseUrl,
      'hasValidUrl':
          supabaseUrl.isNotEmpty && supabaseUrl.contains('.supabase.co'),
      'hasValidKey': supabaseAnonKey.isNotEmpty && supabaseAnonKey.length > 100,
      'isDevelopment': isDevelopment,
      'enableLogging': enableLogging,
    };
  }
}
