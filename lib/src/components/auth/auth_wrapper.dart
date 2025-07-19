import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../stores/auth_store.dart';
import '../../pages/auth/login_page.dart';
import '../../pages/main_layout.dart';

/// Widget que controla a navegação baseada no estado de autenticação
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthStore>(
      builder: (context, authStore, child) {
        switch (authStore.state) {
          case AuthState.initial:
          case AuthState.loading:
            return const AuthLoadingScreen();

          case AuthState.authenticated:
            return const MainLayout();

          case AuthState.unauthenticated:
          case AuthState.error:
            return const LoginPage();
        }
      },
    );
  }
}

/// Tela de loading durante inicialização da autenticação
class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3B82F6),
              Color(0xFF6366F1),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Ícone
              Icon(
                Icons.support_agent,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 32),

              // Texto
              Text(
                'BKCRM',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 16),

              Text(
                'Carregando...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 32),

              // Loading indicator
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
