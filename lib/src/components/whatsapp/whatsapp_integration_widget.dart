import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../services/evolution/whatsapp_integration_service.dart';
import '../../services/evolution/evolution_models.dart';
import '../../styles/app_theme.dart';
import '../../config/app_config.dart';

class WhatsAppIntegrationWidget extends StatefulWidget {
  const WhatsAppIntegrationWidget({super.key});

  @override
  State<WhatsAppIntegrationWidget> createState() =>
      _WhatsAppIntegrationWidgetState();
}

class _WhatsAppIntegrationWidgetState extends State<WhatsAppIntegrationWidget> {
  final WhatsAppIntegrationService _whatsappService =
      WhatsAppIntegrationService();

  EvolutionInstance? _currentInstance;
  String? _qrCode;
  bool _isInitializing = false;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeIntegration();
    _setupStreamListeners();
  }

  void _initializeIntegration() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      final success = await _whatsappService.initialize();
      if (success) {
        AppConfig.log('WhatsApp integration initialized',
            tag: 'WhatsAppWidget');
      } else {
        _showError('Falha ao inicializar integração com WhatsApp');
      }
    } catch (e) {
      _showError('Erro ao inicializar: $e');
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  void _setupStreamListeners() {
    // Listen to instance status changes
    _whatsappService.instanceStatusStream.listen((instance) {
      setState(() {
        _currentInstance = instance;
      });
    });

    // Listen to QR code updates
    _whatsappService.qrCodeStream.listen((qrCode) {
      setState(() {
        _qrCode = qrCode;
      });
    });

    // Listen to new messages
    _whatsappService.newMessageStream.listen((message) {
      _showSnackBar('Nova mensagem recebida de ${message.sender.name}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Integração WhatsApp'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _refreshConnection,
            icon: Icon(PhosphorIcons.arrowClockwise()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConnectionStatus(),
            const SizedBox(height: AppTheme.spacing24),
            if (_needsQrCode()) _buildQrCodeSection(),
            if (_isConnected()) _buildMessageSection(),
            const SizedBox(height: AppTheme.spacing24),
            _buildConnectionInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    final status = _currentInstance?.status ?? EvolutionInstanceStatus.closed;
    final statusText = _getStatusText(status);
    final statusColor = _getStatusColor(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                'Status da Conexão',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            statusText,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
          ),
          if (_isInitializing) ...[
            const SizedBox(height: AppTheme.spacing8),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildQrCodeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            PhosphorIcons.qrCode(),
            size: 48,
            color: Colors.green,
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            'Escaneie o QR Code no WhatsApp',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Abra o WhatsApp > Menu > Dispositivos conectados > Conectar um dispositivo',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing24),
          if (_qrCode != null)
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: QrImageView(
                data: _qrCode!,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            )
          else
            Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.chatCircle(),
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                'Enviar Mensagem de Teste',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Número do WhatsApp',
              hintText: '5511999999999',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppTheme.spacing16),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Mensagem',
              hintText: 'Digite sua mensagem...',
              prefixIcon: Icon(Icons.message),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: AppTheme.spacing16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sendTestMessage,
              icon: Icon(PhosphorIcons.paperPlaneTilt()),
              label: const Text('Enviar Mensagem'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.info(),
                color: Colors.blue[600],
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                'Informações da Conexão',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[600],
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          _buildInfoRow('Instância', AppConfig.evolutionInstanceName),
          _buildInfoRow('URL da API', AppConfig.evolutionApiBaseUrl),
          if (_currentInstance?.ownerJid != null)
            _buildInfoRow('WhatsApp JID', _currentInstance!.ownerJid!),
          if (_currentInstance?.profileName != null)
            _buildInfoRow('Nome do Perfil', _currentInstance!.profileName!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.blue[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.blue[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  bool _needsQrCode() {
    return _currentInstance?.needsQrCode ?? false;
  }

  bool _isConnected() {
    return _currentInstance?.isConnected ?? false;
  }

  String _getStatusText(EvolutionInstanceStatus status) {
    switch (status) {
      case EvolutionInstanceStatus.connecting:
        return 'Conectando...';
      case EvolutionInstanceStatus.open:
        return 'Conectado';
      case EvolutionInstanceStatus.closed:
        return 'Desconectado';
      case EvolutionInstanceStatus.qr:
        return 'Aguardando QR Code';
    }
  }

  Color _getStatusColor(EvolutionInstanceStatus status) {
    switch (status) {
      case EvolutionInstanceStatus.connecting:
        return Colors.orange;
      case EvolutionInstanceStatus.open:
        return Colors.green;
      case EvolutionInstanceStatus.closed:
        return Colors.red;
      case EvolutionInstanceStatus.qr:
        return Colors.blue;
    }
  }

  void _refreshConnection() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      await _whatsappService.disconnect();
      await _whatsappService.initialize();
    } catch (e) {
      _showError('Erro ao atualizar conexão: $e');
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  void _sendTestMessage() async {
    if (_phoneController.text.isEmpty || _messageController.text.isEmpty) {
      _showError('Por favor, preencha todos os campos');
      return;
    }

    try {
      final success = await _whatsappService.sendTextMessage(
        phoneNumber: _phoneController.text,
        message: _messageController.text,
      );

      if (success) {
        _showSnackBar('Mensagem enviada com sucesso!');
        _messageController.clear();
      } else {
        _showError('Falha ao enviar mensagem');
      }
    } catch (e) {
      _showError('Erro ao enviar mensagem: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
