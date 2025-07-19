import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../styles/app_theme.dart';
import '../../stores/auth_store.dart';
import '../main_layout.dart';
import '../debug/connectivity_debug_page.dart';
import '../../components/ui/toast_message.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();

    // Verificar se já está autenticado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authStore = context.read<AuthStore>();
      if (authStore.isAuthenticated) {
        _navigateToMainApp();
      }
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1024;
    final isTablet = MediaQuery.of(context).size.width > 768 &&
        MediaQuery.of(context).size.width <= 1024;

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: SafeArea(
        child: Consumer<AuthStore>(
          builder: (context, authStore, child) {
            // Se autenticado, navegar para app principal
            if (authStore.isAuthenticated) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _navigateToMainApp();
              });
            }

            return AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: isDesktop
                        ? _buildDesktopLayout(authStore)
                        : isTablet
                            ? _buildTabletLayout(authStore)
                            : _buildMobileLayout(authStore),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Layout para Desktop
  Widget _buildDesktopLayout(AuthStore authStore) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF8FAFC),
            const Color(0xFFF1F5F9),
          ],
        ),
      ),
      child: Row(
        children: [
          // Lado esquerdo - Informações e branding
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withValues(alpha: 0.9),
                    AppTheme.primaryColor.withValues(alpha: 0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(60.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    // Logo e branding
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        PhosphorIcons.headset(),
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'BKCRM',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 48,
                            letterSpacing: -1,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sistema de CRM Moderno',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontWeight: FontWeight.w400,
                                fontSize: 20,
                              ),
                    ),
                    const SizedBox(height: 60),
                    // Features destacadas
                    _buildFeatureItem(
                      icon: PhosphorIcons.ticket(),
                      title: 'Gerenciamento de Tickets',
                      description:
                          'Organize e acompanhe todos os tickets de suporte',
                    ),
                    const SizedBox(height: 30),
                    _buildFeatureItem(
                      icon: PhosphorIcons.chatCircle(),
                      title: 'Chat Integrado',
                      description: 'Comunicação em tempo real com clientes',
                    ),
                    const SizedBox(height: 30),
                    _buildFeatureItem(
                      icon: PhosphorIcons.currencyDollar(),
                      title: 'Orçamentos',
                      description: 'Crie e gerencie propostas comerciais',
                    ),
                    const SizedBox(height: 30),
                    _buildFeatureItem(
                      icon: PhosphorIcons.chartLine(),
                      title: 'Relatórios',
                      description:
                          'Análises e insights para melhorar resultados',
                    ),
                    const SizedBox(height: 40),
                    // Footer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            PhosphorIcons.shieldCheck(),
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Seguro e confiável',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          // Lado direito - Formulário de login
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(60.0),
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: _buildLoginForm(authStore),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Layout para Tablet
  Widget _buildTabletLayout(AuthStore authStore) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Card(
          elevation: 20,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(60.0),
            child: _buildLoginForm(authStore),
          ),
        ),
      ),
    );
  }

  // Layout para Mobile (mantém o original)
  Widget _buildMobileLayout(AuthStore authStore) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              MediaQuery.of(context).padding.bottom,
        ),
        child: IntrinsicHeight(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing24),
            child: _buildLoginForm(authStore),
          ),
        ),
      ),
    );
  }

  // Item de feature para desktop
  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(AuthStore authStore) {
    final isDesktop = MediaQuery.of(context).size.width > 1024;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isDesktop) ...[
          const SizedBox(height: AppTheme.spacing32),
          _buildHeader(),
          const SizedBox(height: AppTheme.spacing32),
        ] else ...[
          _buildDesktopHeader(),
          const SizedBox(height: AppTheme.spacing32),
        ],
        _buildForm(),
        if (authStore.errorMessage != null) ...[
          const SizedBox(height: AppTheme.spacing16),
          _buildErrorMessage(authStore.errorMessage!),
        ],
        const SizedBox(height: AppTheme.spacing24),
        _buildLoginButton(authStore),
        const SizedBox(height: AppTheme.spacing24),
        _buildDivider(),
        const SizedBox(height: AppTheme.spacing24),
        _buildSocialLogin(),
        const SizedBox(height: AppTheme.spacing32),
        _buildSignUpLink(),
        const SizedBox(height: AppTheme.spacing16),
        _buildForgotPassword(),
        const SizedBox(height: AppTheme.spacing16),
      ],
    );
  }

  // Header específico para desktop
  Widget _buildDesktopHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  PhosphorIcons.headset(),
                  color: Colors.white,
                  size: 35,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Bem-vindo de volta!',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1F2937),
                      fontSize: 32,
                      letterSpacing: -0.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Faça login para acessar sua conta',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF6B7280),
                      fontSize: 16,
                      height: 1.4,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            PhosphorIcons.headset(),
            color: Colors.white,
            size: 35,
          ),
        ),
        const SizedBox(height: AppTheme.spacing20),
        Text(
          'Bem-vindo de volta!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF374151),
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'Faça login para acessar sua conta',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6B7280),
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm() {
    final isDesktop = MediaQuery.of(context).size.width > 1024;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 32 : AppTheme.spacing24),
      decoration: isDesktop
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                ),
              ],
              border: Border.all(
                color: const Color(0xFFF3F4F6),
                width: 1,
              ),
            )
          : AppTheme.getCardDecoration(context),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildEmailField(),
            SizedBox(height: isDesktop ? 28 : AppTheme.spacing24),
            _buildPasswordField(),
            SizedBox(height: isDesktop ? 24 : AppTheme.spacing16),
            _buildRememberMe(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    final isDesktop = MediaQuery.of(context).size.width > 1024;

    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      style: TextStyle(
        fontSize: isDesktop ? 17 : 14,
        color: const Color(0xFF1F2937),
      ),
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'seu@email.com',
        labelStyle: TextStyle(
          color: const Color(0xFF6B7280),
          fontSize: isDesktop ? 16 : 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: const Color(0xFF9CA3AF),
          fontSize: isDesktop ? 16 : 14,
        ),
        prefixIcon: Icon(
          PhosphorIcons.envelope(),
          color: const Color(0xFF9CA3AF),
          size: isDesktop ? 26 : 20,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: isDesktop ? 18 : AppTheme.spacing16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Email é obrigatório';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Email inválido';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    final isDesktop = MediaQuery.of(context).size.width > 1024;

    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      autofillHints: const [AutofillHints.password],
      style: TextStyle(
        fontSize: isDesktop ? 17 : 14,
        color: const Color(0xFF1F2937),
      ),
      decoration: InputDecoration(
        labelText: 'Senha',
        hintText: '••••••••',
        labelStyle: TextStyle(
          color: const Color(0xFF6B7280),
          fontSize: isDesktop ? 16 : 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: const Color(0xFF9CA3AF),
          fontSize: isDesktop ? 16 : 14,
        ),
        prefixIcon: Icon(
          PhosphorIcons.lock(),
          color: const Color(0xFF9CA3AF),
          size: isDesktop ? 26 : 20,
        ),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          icon: Icon(
            _obscurePassword ? PhosphorIcons.eye() : PhosphorIcons.eyeSlash(),
            color: const Color(0xFF9CA3AF),
            size: isDesktop ? 26 : 20,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: isDesktop ? 18 : AppTheme.spacing16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Senha é obrigatória';
        }
        if (value.length < 6) {
          return 'Senha deve ter pelo menos 6 caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildRememberMe() {
    final isDesktop = MediaQuery.of(context).size.width > 1024;

    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (value) {
            setState(() {
              _rememberMe = value ?? false;
            });
          },
          activeColor: AppTheme.primaryColor,
        ),
        Text(
          'Lembrar de mim',
          style: TextStyle(
            color: const Color(0xFF374151),
            fontSize: isDesktop ? 16 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String message) {
    // Verificar se é um erro de configuração do Supabase
    final isConfigError = message.contains('Configuração do Supabase') ||
        message.contains('credenciais');

    // Verificar se é um erro de conectividade/DNS
    final isConnectivityError = message.contains('Failed host lookup') ||
        message.contains('SocketException') ||
        message.contains('ClientException') ||
        message.contains('NetworkException') ||
        message.contains('supabase.co');

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: isConfigError
            ? AppTheme.warningColor.withValues(alpha: 0.1)
            : AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConfigError ? AppTheme.warningColor : AppTheme.errorColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isConfigError ? PhosphorIcons.gear() : PhosphorIcons.warning(),
                color:
                    isConfigError ? AppTheme.warningColor : AppTheme.errorColor,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: Text(
                  isConfigError
                      ? 'Configuração Necessária'
                      : isConnectivityError
                          ? 'Erro de Conectividade'
                          : 'Erro',
                  style: TextStyle(
                    color: isConfigError
                        ? AppTheme.warningColor
                        : AppTheme.errorColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            message,
            style: TextStyle(
              color: isConfigError
                  ? AppTheme.warningColor.withValues(alpha: 0.8)
                  : AppTheme.errorColor.withValues(alpha: 0.8),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          Wrap(
            spacing: AppTheme.spacing8,
            runSpacing: AppTheme.spacing8,
            children: [
              if (isConfigError)
                OutlinedButton.icon(
                  onPressed: _showConfigHelp,
                  icon: Icon(
                    PhosphorIcons.info(),
                    size: 16,
                    color: AppTheme.warningColor,
                  ),
                  label: const Text('Como configurar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.warningColor,
                    side: BorderSide(color: AppTheme.warningColor),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing12,
                      vertical: AppTheme.spacing8,
                    ),
                  ),
                ),
              if (isConnectivityError)
                OutlinedButton.icon(
                  onPressed: _openConnectivityDiagnostic,
                  icon: Icon(
                    PhosphorIcons.wifiHigh(),
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  label: const Text('Testar Conectividade'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing12,
                      vertical: AppTheme.spacing8,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(AuthStore authStore) {
    final isDesktop = MediaQuery.of(context).size.width > 1024;

    return Container(
      width: double.infinity,
      height: isDesktop ? 60 : 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: authStore.isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child: authStore.isLoading
            ? SizedBox(
                width: isDesktop ? 30 : 24,
                height: isDesktop ? 30 : 24,
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Entrar',
                style: TextStyle(
                  fontSize: isDesktop ? 20 : 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFE5E7EB),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
          child: Text(
            'ou',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFE5E7EB),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLogin() {
    final isDesktop = MediaQuery.of(context).size.width > 1024;

    return Row(
      children: [
        Expanded(
          child: _buildSocialButton(
            icon: PhosphorIcons.googleLogo(),
            label: 'Google',
            onPressed: _handleGoogleLogin,
            isDesktop: isDesktop,
          ),
        ),
        const SizedBox(width: AppTheme.spacing12),
        Expanded(
          child: _buildSocialButton(
            icon: PhosphorIcons.microsoftOutlookLogo(),
            label: 'Microsoft',
            onPressed: _handleMicrosoftLogin,
            isDesktop: isDesktop,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isDesktop,
  }) {
    return Container(
      height: isDesktop ? 55 : 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: isDesktop ? 24 : 20,
          color: const Color(0xFF374151),
        ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: isDesktop ? 17 : 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF374151),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.symmetric(
            vertical: isDesktop ? 18 : 12,
            horizontal: isDesktop ? 24 : 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    final isDesktop = MediaQuery.of(context).size.width > 1024;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            'Não tem uma conta? ',
            style: TextStyle(
              color: const Color(0xFF6B7280),
              fontSize: isDesktop ? 16 : 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        GestureDetector(
          onTap: _navigateToSignUp,
          child: Text(
            'Criar conta',
            style: TextStyle(
              color: const Color(0xFF3B82F6),
              fontWeight: FontWeight.w600,
              fontSize: isDesktop ? 16 : 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPassword() {
    final isDesktop = MediaQuery.of(context).size.width > 1024;

    return Center(
      child: GestureDetector(
        onTap: _handleForgotPassword,
        child: Text(
          'Esqueceu sua senha?',
          style: TextStyle(
            color: const Color(0xFF6B7280),
            decoration: TextDecoration.underline,
            fontSize: isDesktop ? 16 : 14,
          ),
        ),
      ),
    );
  }

  // Actions
  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authStore = context.read<AuthStore>();

    // Mostrar loading
    setState(() {
      // O loading será controlado pelo AuthStore
    });

    final success = await authStore.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      // Aguardar um pouco para garantir que o estado foi atualizado
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        _showSuccessMessage('Login realizado com sucesso!');

        // Verificar se o usuário está realmente autenticado
        if (authStore.isAuthenticated) {
          _navigateToMainApp();
        } else {
          // Se não estiver autenticado, aguardar mais um pouco
          await Future.delayed(const Duration(milliseconds: 1000));
          if (mounted && authStore.isAuthenticated) {
            _navigateToMainApp();
          } else {
            _showErrorMessage('Erro ao processar login. Tente novamente.');
          }
        }
      }
    } else if (mounted) {
      // Mostrar erro específico do AuthStore
      final errorMessage = authStore.errorMessage ?? 'Erro ao fazer login';
      _showErrorMessage(errorMessage);
    }
  }

  void _handleGoogleLogin() {
    ToastService.instance.showInfo(
      context,
      message: 'Login com Google será implementado em breve',
      title: 'Em desenvolvimento',
    );
  }

  void _handleMicrosoftLogin() {
    ToastService.instance.showInfo(
      context,
      message: 'Login com Microsoft será implementado em breve',
      title: 'Em desenvolvimento',
    );
  }

  void _navigateToSignUp() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SignUpPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  void _handleForgotPassword() {
    _showForgotPasswordDialog();
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar Senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Digite seu email para receber as instruções de recuperação:'),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'seu@email.com',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          Consumer<AuthStore>(
            builder: (context, authStore, child) {
              return ElevatedButton(
                onPressed: authStore.isLoading
                    ? null
                    : () => _sendPasswordReset(emailController.text),
                child: authStore.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enviar'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _sendPasswordReset(String email) async {
    if (email.isEmpty) {
      _showErrorMessage('Digite um email válido');
      return;
    }

    final authStore = context.read<AuthStore>();
    final success = await authStore.resetPassword(email);

    if (mounted) {
      Navigator.pop(context); // Fechar dialog

      if (success) {
        _showSuccessMessage(
            'Email de recuperação enviado! Verifique sua caixa de entrada.');
      } else {
        _showErrorMessage(authStore.errorMessage ?? 'Erro ao enviar email');
      }
    }
  }

  void _navigateToMainApp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const MainLayout(),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ToastService.instance.showSuccess(
      context,
      message: message,
      title: 'Sucesso!',
    );
  }

  void _showErrorMessage(String message) {
    ToastService.instance.showError(
      context,
      message: message,
      title: 'Erro',
    );
  }

  void _openConnectivityDiagnostic() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConnectivityDebugPage(),
      ),
    );
  }

  void _showConfigHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              PhosphorIcons.gear(),
              color: const Color(0xFFF59E0B),
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Configurar Supabase'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Para usar este app, você precisa configurar suas credenciais do Supabase:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                '📋 Passos para configurar:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Acesse https://supabase.com\n'
                '2. Crie um projeto ou acesse um existente\n'
                '3. Vá em Settings > API\n'
                '4. Copie a "URL" e a "anon/public key"\n'
                '5. Edite o arquivo:\n'
                '   lib/src/config/app_config.dart\n'
                '6. Substitua as constantes:\n'
                '   - supabaseUrl\n'
                '   - supabaseAnonKey',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '💡 Dica: Após configurar, reinicie o app para aplicar as mudanças.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// Página de Cadastro
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            PhosphorIcons.arrowLeft(),
            color: const Color(0xFF374151),
          ),
        ),
      ),
      body: SafeArea(
        child: Consumer<AuthStore>(
          builder: (context, authStore, child) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: AppTheme.spacing32),
                    _buildForm(),
                    if (authStore.errorMessage != null) ...[
                      const SizedBox(height: AppTheme.spacing16),
                      _buildErrorMessage(authStore.errorMessage!),
                    ],
                    const SizedBox(height: AppTheme.spacing24),
                    _buildSignUpButton(authStore),
                    const SizedBox(height: AppTheme.spacing24),
                    _buildLoginLink(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            PhosphorIcons.userPlus(),
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: AppTheme.spacing24),
        Text(
          'Criar nova conta',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2937),
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'Preencha os dados para criar sua conta',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6B7280),
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildNameField(),
            const SizedBox(height: AppTheme.spacing24),
            _buildEmailField(),
            const SizedBox(height: AppTheme.spacing24),
            _buildPasswordField(),
            const SizedBox(height: AppTheme.spacing24),
            _buildConfirmPasswordField(),
            const SizedBox(height: AppTheme.spacing16),
            _buildAcceptTerms(),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Nome completo',
        hintText: 'Seu nome completo',
        prefixIcon: Icon(
          PhosphorIcons.user(),
          color: const Color(0xFF6B7280),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Nome é obrigatório';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'seu@email.com',
        prefixIcon: Icon(
          PhosphorIcons.envelope(),
          color: const Color(0xFF6B7280),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Email é obrigatório';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Email inválido';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Senha',
        hintText: 'Sua senha',
        prefixIcon: Icon(
          PhosphorIcons.lock(),
          color: const Color(0xFF6B7280),
        ),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          icon: Icon(
            _obscurePassword ? PhosphorIcons.eye() : PhosphorIcons.eyeSlash(),
            color: const Color(0xFF6B7280),
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Senha é obrigatória';
        }
        if (value.length < 6) {
          return 'Senha deve ter no mínimo 6 caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      decoration: InputDecoration(
        labelText: 'Confirmar senha',
        hintText: 'Confirme sua senha',
        prefixIcon: Icon(
          PhosphorIcons.lock(),
          color: const Color(0xFF6B7280),
        ),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
          icon: Icon(
            _obscureConfirmPassword
                ? PhosphorIcons.eye()
                : PhosphorIcons.eyeSlash(),
            color: const Color(0xFF6B7280),
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Confirmação de senha é obrigatória';
        }
        if (value != _passwordController.text) {
          return 'Senhas não conferem';
        }
        return null;
      },
    );
  }

  Widget _buildAcceptTerms() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) {
            setState(() {
              _acceptTerms = value ?? false;
            });
          },
          activeColor: const Color(0xFF10B981),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: AppTheme.spacing8),
        const Expanded(
          child: Text.rich(
            TextSpan(
              text: 'Eu aceito os ',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
              ),
              children: [
                TextSpan(
                  text: 'Termos de Uso',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(text: ' e '),
                TextSpan(
                  text: 'Política de Privacidade',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIcons.warning(),
            color: const Color(0xFFEF4444),
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpButton(AuthStore authStore) {
    return ElevatedButton(
      onPressed: authStore.isLoading || !_acceptTerms ? null : _handleSignUp,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: authStore.isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Criar conta',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Já tem uma conta? ',
          style: TextStyle(
            color: Color(0xFF6B7280),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            'Fazer login',
            style: TextStyle(
              color: Color(0xFF10B981),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      _showErrorMessage('Você deve aceitar os termos de uso');
      return;
    }

    final authStore = context.read<AuthStore>();
    final success = await authStore.signUp(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      _showSuccessMessage('Conta criada com sucesso!');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainLayout(),
        ),
      );
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  void _showConfigHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              PhosphorIcons.gear(),
              color: const Color(0xFFF59E0B),
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Configurar Supabase'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Para usar este app, você precisa configurar suas credenciais do Supabase:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                '📋 Passos para configurar:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Acesse https://supabase.com\n'
                '2. Crie um projeto ou acesse um existente\n'
                '3. Vá em Settings > API\n'
                '4. Copie a "URL" e a "anon/public key"\n'
                '5. Edite o arquivo:\n'
                '   lib/src/config/app_config.dart\n'
                '6. Substitua as constantes:\n'
                '   - supabaseUrl\n'
                '   - supabaseAnonKey',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '💡 Dica: Após configurar, reinicie o app para aplicar as mudanças.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
