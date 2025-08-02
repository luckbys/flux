import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase/supabase_service.dart';
import '../models/user.dart' as app_user;
import '../config/app_config.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthStore extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  AuthState _state = AuthState.initial;
  User? _supabaseUser;
  app_user.User? _appUser;
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  AuthState get state => _state;
  User? get supabaseUser => _supabaseUser;
  app_user.User? get appUser => _appUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _state == AuthState.authenticated;
  String? get currentUserId => _supabaseUser?.id;

  AuthStore() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _setState(AuthState.loading);

      // Verificar se a configuração do Supabase é válida
      if (!AppConfig.isConfigurationValid) {
        _setError('Configuração do Supabase necessária!\n\n'
            'Para usar o app, você precisa:\n'
            '1. Criar um projeto no Supabase\n'
            '2. Configurar as credenciais em app_config.dart');
        return;
      }

      if (!_supabaseService.isInitialized) {
        final initialized = await _supabaseService.initialize();
        if (!initialized) {
          _setError('Erro de conexão com Supabase!\n\n'
              'Verifique:\n'
              '• Sua conexão com a internet\n'
              '• Se as credenciais estão corretas\n'
              '• Se o projeto Supabase existe');
          return;
        }
      }

      // Verificar se já existe usuário logado
      _supabaseUser = _supabaseService.currentUser;

      if (_supabaseUser != null) {
        AppConfig.log(
            'Usuário já autenticado encontrado: ${_supabaseUser!.email}',
            tag: 'AuthStore');
        await _loadAppUser();
        _setState(AuthState.authenticated);
      } else {
        AppConfig.log('Nenhum usuário autenticado encontrado',
            tag: 'AuthStore');
        _setState(AuthState.unauthenticated);
      }

      // Ouvir mudanças de autenticação
      _supabaseService.authStateChanges.listen((authChangeEvent) {
        AppConfig.log(
            'Evento de mudança de auth recebido: ${authChangeEvent.event}',
            tag: 'AuthStore');
        _onAuthStateChanged(authChangeEvent);
      });

      AppConfig.log('AuthStore inicializado com sucesso', tag: 'AuthStore');
    } catch (e) {
      AppConfig.log('Erro ao inicializar AuthStore: $e', tag: 'AuthStore');
      _setError('Erro ao inicializar autenticação');
    }
  }

  void _onAuthStateChanged(dynamic authEvent) async {
    try {
      AppConfig.log('Mudança de estado de autenticação detectada',
          tag: 'AuthStore');

      _supabaseUser = _supabaseService.currentUser;

      if (_supabaseUser != null) {
        AppConfig.log('Usuário autenticado: ${_supabaseUser!.email}',
            tag: 'AuthStore');
        await _loadAppUser();
        _setState(AuthState.authenticated);
      } else {
        AppConfig.log('Usuário não autenticado', tag: 'AuthStore');
        _appUser = null;
        _setState(AuthState.unauthenticated);
      }
    } catch (e) {
      AppConfig.log('Erro ao processar mudança de auth: $e', tag: 'AuthStore');
      _setError('Erro ao processar autenticação');
    }
  }

  Future<void> _loadAppUser() async {
    if (_supabaseUser == null) return;

    try {
      AppConfig.log('Carregando dados do usuário: ${_supabaseUser!.id}',
          tag: 'AuthStore');

      final response = await _supabaseService
          .from('users')
          .select()
          .eq('id', _supabaseUser!.id)
          .single();

      _appUser = app_user.User.fromJson(response);
      AppConfig.log('Dados do usuário carregados com sucesso',
          tag: 'AuthStore');
    } catch (e) {
      AppConfig.log('Erro ao carregar dados do usuário: $e', tag: 'AuthStore');

      // Se não encontrar o usuário, tentar criar
      try {
        await _createAppUser();
      } catch (createError) {
        AppConfig.log('Erro ao criar usuário: $createError', tag: 'AuthStore');
        // Criar um usuário temporário para não quebrar a aplicação
        _appUser = app_user.User(
          id: _supabaseUser!.id,
          name: _supabaseUser!.userMetadata?['name'] ??
              _supabaseUser!.email?.split('@').first ??
              'Usuário',
          email: _supabaseUser!.email!,
          avatarUrl: _supabaseUser!.userMetadata?['avatar_url'],
          role: app_user.UserRole.customer,
          status: app_user.UserStatus.online,
          createdAt: DateTime.now(),
        );
      }
    }
  }

  Future<void> _createAppUser() async {
    if (_supabaseUser == null) return;

    try {
      AppConfig.log('Criando usuário na base de dados: ${_supabaseUser!.id}',
          tag: 'AuthStore');

      final userData = {
        'id': _supabaseUser!.id,
        'name': _supabaseUser!.userMetadata?['name'] ??
            _supabaseUser!.email?.split('@').first ??
            'Usuário',
        'email': _supabaseUser!.email!,
        'avatar_url': _supabaseUser!.userMetadata?['avatar_url'],
        'role': 'customer',
        'user_status': 'online',
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabaseService
          .from('users')
          .insert(userData)
          .select()
          .single();

      _appUser = app_user.User.fromJson(response);
      AppConfig.log('Usuário criado na base de dados com sucesso',
          tag: 'AuthStore');
    } catch (e) {
      AppConfig.log('Erro ao criar usuário na base de dados: $e',
          tag: 'AuthStore');

      // Se não conseguir criar na base, criar um usuário temporário
      _appUser = app_user.User(
        id: _supabaseUser!.id,
        name: _supabaseUser!.userMetadata?['name'] ??
            _supabaseUser!.email?.split('@').first ??
            'Usuário',
        email: _supabaseUser!.email!,
        avatarUrl: _supabaseUser!.userMetadata?['avatar_url'],
        role: app_user.UserRole.customer,
        status: app_user.UserStatus.online,
        createdAt: DateTime.now(),
      );

      AppConfig.log('Usuário temporário criado localmente', tag: 'AuthStore');
    }
  }

  /// Realizar login com email e senha
  Future<bool> signIn({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      AppConfig.log('🔐 Iniciando processo de login...', tag: 'AuthStore');
      AppConfig.log('📧 Email: $email', tag: 'AuthStore');
      AppConfig.log('🔒 RememberMe: $rememberMe', tag: 'AuthStore');
      
      // Verificar se o Supabase está inicializado
      if (!_supabaseService.isInitialized) {
        AppConfig.log('❌ Supabase não inicializado, tentando inicializar...', tag: 'AuthStore');
        final initialized = await _supabaseService.initialize();
        if (!initialized) {
          _setError('Erro de conexão com o servidor');
          return false;
        }
      }

      AppConfig.log('🚀 Chamando _supabaseService.signIn...', tag: 'AuthStore');
      final response = await _supabaseService.signIn(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );

      AppConfig.log('📥 Resposta do Supabase recebida', tag: 'AuthStore');
      AppConfig.log('👤 User: ${response?.user?.email ?? "null"}', tag: 'AuthStore');
      AppConfig.log('🎫 Session: ${response?.session?.accessToken != null ? "válida" : "null"}', tag: 'AuthStore');

      if (response?.user != null) {
        _supabaseUser = response!.user;
        AppConfig.log('✅ Login realizado com sucesso!', tag: 'AuthStore');
        AppConfig.log('🆔 User ID: ${_supabaseUser!.id}', tag: 'AuthStore');

        // Carregar dados do usuário da aplicação
        AppConfig.log('📊 Carregando dados do usuário...', tag: 'AuthStore');
        await _loadAppUser();

        // Atualizar o estado para autenticado
        AppConfig.log('🎯 Definindo estado como autenticado', tag: 'AuthStore');
        _setState(AuthState.authenticated);
        AppConfig.log('✅ AuthStore - Estado atualizado para authenticated',
            tag: 'AuthStore');

        return true;
      } else {
        AppConfig.log('❌ Resposta inválida do Supabase', tag: 'AuthStore');
        _setError('Email ou senha incorretos');
        return false;
      }
    } on AuthException catch (e) {
      AppConfig.log('💥 Erro de autenticação: ${e.message}', tag: 'AuthStore');
      AppConfig.log('🔍 Tipo do erro: ${e.runtimeType}', tag: 'AuthStore');
      _setError(_parseAuthError(e.message));
      return false;
    } catch (e) {
      AppConfig.log('💥 Erro no login: $e', tag: 'AuthStore');
      AppConfig.log('🔍 Tipo do erro: ${e.runtimeType}', tag: 'AuthStore');
      
      String errorMessage = 'Erro interno. Tente novamente.';
      if (e.toString().contains('Invalid login credentials')) {
        errorMessage = 'Email ou senha incorretos';
      } else if (e.toString().contains('Email not confirmed')) {
        errorMessage = 'Email não confirmado. Verifique sua caixa de entrada.';
      } else if (e.toString().contains('Too many requests')) {
        errorMessage = 'Muitas tentativas. Tente novamente em alguns minutos.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Erro de conexão. Verifique sua internet.';
      }
      
      _setError(errorMessage);
      return false;
    } finally {
      _setLoading(false);
      AppConfig.log('🏁 Processo de login finalizado', tag: 'AuthStore');
    }
  }

  /// Realizar cadastro com email e senha
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      AppConfig.log('Tentando criar conta: $email', tag: 'AuthStore');

      final response = await _supabaseService.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (response?.user != null) {
        AppConfig.log('Conta criada com sucesso!', tag: 'AuthStore');

        // Se confirmação por email estiver desabilitada, o usuário já estará logado
        if (response!.session != null) {
          return true;
        } else {
          _setError('Verifique seu email para confirmar a conta');
          return false;
        }
      } else {
        _setError('Erro ao criar conta');
        return false;
      }
    } on AuthException catch (e) {
      AppConfig.log('Erro no cadastro: ${e.message}', tag: 'AuthStore');
      _setError(_parseAuthError(e.message));
      return false;
    } catch (e) {
      AppConfig.log('Erro no cadastro: $e', tag: 'AuthStore');
      _setError('Erro interno. Tente novamente.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Realizar logout
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _supabaseService.signOut();

      // Limpar dados do usuário
      _supabaseUser = null;
      _appUser = null;
      _setState(AuthState.unauthenticated);

      AppConfig.log('Logout realizado com sucesso', tag: 'AuthStore');
    } catch (e) {
      AppConfig.log('Erro no logout: $e', tag: 'AuthStore');
      _setError('Erro ao fazer logout');
    } finally {
      _setLoading(false);
    }
  }

  /// Resetar senha
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabaseService.client.auth.resetPasswordForEmail(email);
      AppConfig.log('Email de recuperação enviado para: $email',
          tag: 'AuthStore');
      return true;
    } on AuthException catch (e) {
      AppConfig.log('Erro ao enviar email de recuperação: ${e.message}',
          tag: 'AuthStore');
      _setError(_parseAuthError(e.message));
      return false;
    } catch (e) {
      AppConfig.log('Erro ao enviar email de recuperação: $e',
          tag: 'AuthStore');
      _setError('Erro interno. Tente novamente.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Atualizar perfil do usuário
  Future<bool> updateProfile({
    String? name,
    String? avatarUrl,
    String? phone,
  }) async {
    if (_appUser == null) return false;

    try {
      _setLoading(true);
      _clearError();

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (phone != null) updates['phone'] = phone;

      if (updates.isEmpty) return true;

      updates['updated_at'] = DateTime.now().toIso8601String();

      await _supabaseService
          .from('users')
          .update(updates)
          .eq('id', _appUser!.id);

      // Atualizar dados locais
      _appUser = _appUser!.copyWith(
        name: name ?? _appUser!.name,
        avatarUrl: avatarUrl ?? _appUser!.avatarUrl,
        phone: phone ?? _appUser!.phone,
      );

      notifyListeners();
      AppConfig.log('Perfil atualizado com sucesso', tag: 'AuthStore');
      return true;
    } catch (e) {
      AppConfig.log('Erro ao atualizar perfil: $e', tag: 'AuthStore');
      _setError('Erro ao atualizar perfil');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Helper methods
  void _setState(AuthState newState) {
    AppConfig.log('🔄 AuthStore - Mudando estado de $_state para $newState',
        tag: 'AuthStore');
    _state = newState;
    AppConfig.log('📢 AuthStore - Chamando notifyListeners()',
        tag: 'AuthStore');
    notifyListeners();
    AppConfig.log('✅ AuthStore - notifyListeners() executado',
        tag: 'AuthStore');
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _setState(AuthState.error);
  }

  void _clearError() {
    _errorMessage = null;
  }

  String _parseAuthError(String message) {
    // Traduzir mensagens de erro comuns
    switch (message.toLowerCase()) {
      case 'invalid login credentials':
        return 'Email ou senha incorretos';
      case 'email not confirmed':
        return 'Email não confirmado. Verifique sua caixa de entrada.';
      case 'user already registered':
        return 'Este email já está cadastrado';
      case 'password should be at least 6 characters':
        return 'A senha deve ter pelo menos 6 caracteres';
      case 'signup is disabled':
        return 'Cadastro desabilitado temporariamente';
      case 'email rate limit exceeded':
        return 'Muitas tentativas. Tente novamente em alguns minutos.';
      default:
        return message;
    }
  }
}
