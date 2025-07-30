import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'src/styles/enhanced_theme.dart';
import 'src/styles/design_tokens.dart';
import 'src/styles/micro_animations.dart';
import 'src/pages/auth/login_page.dart';
import 'src/services/ai/gemini_service.dart';
import 'src/services/supabase/supabase_service.dart';
import 'src/stores/chat_store.dart';
import 'src/stores/auth_store.dart';
import 'src/stores/ticket_store.dart';
import 'src/stores/quote_store.dart';
import 'src/stores/theme_store.dart';
import 'src/stores/dashboard_store.dart';
import 'src/stores/notification_store.dart';
import 'src/components/auth/auth_wrapper.dart';

import 'src/config/app_config.dart';
import 'src/services/network_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar overrides de rede para resolver problemas de DNS no Android
  NetworkTester.instance.configureHttpOverrides();

  // Pré-carregar informações de rede importantes
  await NetworkTester.instance.preloadDnsInfo(AppConfig.supabaseUrl);

  // Inicializar Hive para armazenamento local
  await Hive.initFlutter();

  // Testar conectividade antes de inicializar Supabase
  final networkTester = NetworkTester.instance;
  await networkTester.testInternetConnectivity();

  // Testar resolução de DNS para o Supabase
  final hasSupabaseDns = await networkTester.testSupabaseDns();
  if (!hasSupabaseDns) {
    // Testar conectividade direta com o Supabase usando IP
    await networkTester.testSupabaseConnectivity(AppConfig.supabaseUrl);
  }

  // Inicializar Supabase
  final supabaseService = SupabaseService();
  await supabaseService.initialize();

  // Permitir todas as orientações para suporte a web e desktop
  // Não restringimos a orientação para permitir visualização em qualquer dispositivo

  // Configurar barra de status
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const BKCRMApp());
}

class BKCRMApp extends StatefulWidget {
  const BKCRMApp({super.key});

  @override
  State<BKCRMApp> createState() => _BKCRMAppState();
}

class _BKCRMAppState extends State<BKCRMApp> {
  bool _hasDnsIssue = false;

  @override
  void initState() {
    super.initState();
    _checkDnsStatus();
  }

  Future<void> _checkDnsStatus() async {
    // Verificar se há problemas de DNS após a inicialização do aplicativo
    final hasSupabaseDns = await NetworkTester.instance.testSupabaseDns();
    if (!hasSupabaseDns) {
      if (mounted) {
        setState(() {
          _hasDnsIssue = true;
        });
      }
    }
  }

  void _showDnsWarningIfNeeded(BuildContext context) {
    // Mostrar o diálogo apenas uma vez após a construção do widget
    if (_hasDnsIssue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          NetworkTester.instance.showDnsWarningDialog(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider para serviços de IA
        Provider<GeminiService>(
          create: (_) => GeminiService(),
        ),
        ChangeNotifierProvider<DashboardStore>(
          create: (_) => DashboardStore(),
        ),
        ChangeNotifierProvider<NotificationStore>(
          create: (_) => NotificationStore(),
        ),
        // Provider para Supabase
        Provider<SupabaseService>(
          create: (_) => SupabaseService(),
        ),
        // Store para autenticação
        ChangeNotifierProvider<AuthStore>(
          create: (_) => AuthStore(),
        ),
        // Store para gerenciamento de chats
        ChangeNotifierProvider<ChatStore>(
          create: (_) => ChatStore(),
        ),
        // Store para gerenciamento de tickets
        ChangeNotifierProvider<TicketStore>(
          create: (_) => TicketStore(),
        ),
        // Store para gerenciamento de orçamentos
        ChangeNotifierProvider<QuoteStore>(
          create: (_) => QuoteStore(),
        ),
        // Store para gerenciamento de tema
        ChangeNotifierProvider<ThemeStore>(
          create: (_) => ThemeStore(),
        ),
      ],
      child: Consumer<ThemeStore>(
        builder: (context, themeStore, child) {
          return MaterialApp(
            title: 'BKCRM - Sistema de CRM',
            debugShowCheckedModeBanner: false,
            theme: EnhancedTheme.lightTheme,
            home: const AuthWrapper(),
            builder: (context, child) {
              // Verificar se há problemas de DNS e mostrar aviso se necessário
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showDnsWarningIfNeeded(context);
              });

              return ScrollConfiguration(
                behavior: const _ScrollBehavior(),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  late AuthStore _authStore;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authStore = Provider.of<AuthStore>(context, listen: false);
    _authStore.addListener(_onAuthStateChanged);
  }

  void _onAuthStateChanged() {
    if (mounted) {
      switch (_authStore.state) {
        case AuthState.authenticated:
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const AuthWrapper(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
          break;
        case AuthState.unauthenticated:
        case AuthState.error:
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const LoginPage(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
          break;
        case AuthState.loading:
        case AuthState.initial:
          break;
      }
    }
  }

  @override
  @override
  void dispose() {
    _animationController.dispose();
    _authStore.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              DesignTokens.primary500,
              DesignTokens.secondary500,
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: MicroAnimations.enterAnimation(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MicroAnimations.scaleIn(
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius:
                                  BorderRadius.circular(DesignTokens.radius2xl),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: DesignTokens.borderWidth2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.support_agent,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: DesignTokens.space32),
                        MicroAnimations.fadeIn(
                          child: Text(
                            'BKCRM',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: DesignTokens.fontWeightBold,
                                  letterSpacing: 2,
                                ),
                          ),
                        ),
                        const SizedBox(height: DesignTokens.space8),
                        MicroAnimations.slideIn(
                          child: Text(
                            'Sistema de CRM Moderno',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                          ),
                        ),
                        const SizedBox(height: DesignTokens.space48),
                        MicroAnimations.pulse(
                          child: const SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Configuração de scroll behavior personalizada
class _ScrollBehavior extends ScrollBehavior {
  const _ScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child; // Remove o indicador de overscroll no Android
  }
}
