import 'package:flutter/material.dart';
import '../../services/evolution/evolution_api_service.dart';
import '../../services/evolution/whatsapp_integration_service.dart';
import '../../styles/app_theme.dart';
import '../../utils/color_extensions.dart';

class WhatsAppSetupPage extends StatefulWidget {
  const WhatsAppSetupPage({super.key});

  @override
  State<WhatsAppSetupPage> createState() => _WhatsAppSetupPageState();
}

class _WhatsAppSetupPageState extends State<WhatsAppSetupPage> {
  final _instanceController = TextEditingController();
  final _qrController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isConnected = false;
  bool _showQRInput = false;
  String? _instanceName;
  String? _connectionStatus;

  final EvolutionApiService _evolutionService = EvolutionApiService();
  final WhatsAppIntegrationService _integrationService =
      WhatsAppIntegrationService();

  @override
  void initState() {
    super.initState();
    _checkExistingConnection();
  }

  @override
  void dispose() {
    _instanceController.dispose();
    _qrController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingConnection() async {
    setState(() => _isLoading = true);

    try {
      // Verificar se já existe uma instância configurada
      final response = await _evolutionService.getInstanceInfo();
      setState(() {
        _isConnected = response.success && response.data?.status.name == 'open';
        _connectionStatus = response.data?.status.name ?? 'disconnected';
      });
    } catch (e) {
      debugPrint('Erro ao verificar conexão: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _generateQRCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final instanceName = _instanceController.text.trim();

      // Gerar QR Code para conexão
      final qrResponse = await _evolutionService.getQrCode();

      if (qrResponse.success) {
        setState(() {
          _instanceName = instanceName;
          _showQRInput = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('QR Code gerado! Agora conecte seu WhatsApp.'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao gerar QR Code: ${qrResponse.message}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar instância: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _connectWhatsApp() async {
    setState(() => _isLoading = true);

    try {
      // Simular processo de conexão com WhatsApp
      await Future.delayed(const Duration(seconds: 2));

      // Verificar status da conexão
      final response = await _evolutionService.getInstanceInfo();

      if (response.success && response.data?.status.name == 'open') {
        setState(() {
          _isConnected = true;
          _connectionStatus = 'open';
          _showQRInput = false;
        });

        // Inicializar integração
        await _integrationService.initialize();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('WhatsApp conectado com sucesso!'),
              backgroundColor: AppTheme.successColor,
            ),
          );

          // Retornar para a tela anterior
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception('Falha na conexão com WhatsApp');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro na conexão: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _disconnectWhatsApp() async {
    setState(() => _isLoading = true);

    try {
      setState(() {
        _isConnected = false;
        _connectionStatus = 'disconnected';
        _instanceName = null;
        _showQRInput = false;
      });

      _instanceController.clear();
      _qrController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp desconectado com sucesso!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao desconectar: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuração WhatsApp'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildConnectionStatus(),
          const SizedBox(height: AppTheme.spacing20),
          if (!_isConnected) ...[
            if (!_showQRInput) ...[
              _buildInstanceForm(),
              const SizedBox(height: AppTheme.spacing20),
              _buildSetupInstructions(),
            ] else ...[
              _buildQRConnectionSteps(),
              const SizedBox(height: AppTheme.spacing20),
              _buildConnectButton(),
            ],
          ] else ...[
            _buildConnectedInfo(),
            const SizedBox(height: AppTheme.spacing20),
            _buildDisconnectButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: _isConnected
            ? AppTheme.successColor.withValues(alpha:  0.1)
            : AppTheme.errorColor.withValues(alpha:  0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isConnected ? AppTheme.successColor : AppTheme.errorColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isConnected ? Icons.check_circle : Icons.error,
            color: _isConnected ? AppTheme.successColor : AppTheme.errorColor,
            size: 24,
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isConnected ? 'WhatsApp Conectado' : 'WhatsApp Desconectado',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _isConnected
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                  ),
                ),
                if (_connectionStatus != null)
                  Text(
                    'Status: $_connectionStatus',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstanceForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nome da Instância',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          TextFormField(
            controller: _instanceController,
            decoration: const InputDecoration(
              hintText: 'Ex: minha-empresa-whatsapp',
              prefixIcon: Icon(Icons.business),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Digite o nome da instância';
              }
              if (value.trim().length < 3) {
                return 'Nome deve ter pelo menos 3 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.spacing16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _generateQRCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Gerar QR Code'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRConnectionSteps() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha:  0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha:  0.2),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.qr_code,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              SizedBox(width: AppTheme.spacing12),
              Text(
                'Conectar WhatsApp',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacing16),
          Text(
            'Siga os passos para conectar:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
          SizedBox(height: AppTheme.spacing8),
          Text(
            '1. Abra o WhatsApp no seu celular\n'
            '2. Vá em Menu > Dispositivos conectados\n'
            '3. Toque em "Conectar um dispositivo"\n'
            '4. Aponte a câmera para o QR Code da Evolution API\n'
            '5. Aguarde a conexão ser estabelecida',
            style: TextStyle(
              color: AppTheme.textColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _connectWhatsApp,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF25D366), // Cor do WhatsApp
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline),
            SizedBox(width: AppTheme.spacing8),
            Text(
              'Confirmar Conexão',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupInstructions() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha:  0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha:  0.2),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              SizedBox(width: AppTheme.spacing8),
              Text(
                'Como conectar',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacing12),
          Text(
            '1. Digite um nome único para sua instância\n'
            '2. Clique em "Gerar QR Code"\n'
            '3. Siga as instruções para conectar seu WhatsApp\n'
            '4. Confirme a conexão quando estabelecida',
            style: TextStyle(
              color: AppTheme.textColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedInfo() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha:  0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.successColor.withValues(alpha:  0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Instância Conectada',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.successColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Nome: ${_instanceName ?? "Não definido"}',
            style: const TextStyle(color: AppTheme.textColor),
          ),
          const Text(
            'Status: Ativo',
            style: TextStyle(color: AppTheme.textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _disconnectWhatsApp,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.errorColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('Desconectar WhatsApp'),
      ),
    );
  }
}
