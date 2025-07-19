# 🚀 Integração Evolution API - BKCRM

Esta documentação descreve como implementar e usar a integração com a Evolution API para envio e recebimento de mensagens do WhatsApp no sistema BKCRM.

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Configuração](#configuração)
- [Instalação](#instalação)
- [Uso Básico](#uso-básico)
- [Recursos Avançados](#recursos-avançados)
- [Webhooks](#webhooks)
- [Exemplos de Código](#exemplos-de-código)
- [Troubleshooting](#troubleshooting)

## 🎯 Visão Geral

A Evolution API é uma solução completa para integração com WhatsApp Business que permite:

- ✅ Envio de mensagens de texto
- ✅ Envio de mídias (imagens, vídeos, áudios, documentos)
- ✅ Recebimento de mensagens via webhooks
- ✅ Gerenciamento de status de conexão
- ✅ QR Code para autenticação
- ✅ Suporte a múltiplas instâncias

## ⚙️ Configuração

### 1. Configuração da Evolution API

Edite o arquivo `lib/src/config/app_config.dart`:

```dart
class AppConfig {
  // Evolution API Configuration
  static const String evolutionApiBaseUrl = 'https://sua-evolution-api.com';
  static const String evolutionApiKey = 'sua-api-key';
  static const String evolutionInstanceName = 'bkcrm-instance';
  static const String evolutionWebhookUrl = 'https://seu-app.com/webhook/evolution';
  
  // Webhook Configuration
  static const String webhookSecret = 'seu-webhook-secret';
  
  // WhatsApp Configuration
  static const String whatsappBusinessName = 'BKCRM Support';
}
```

### 2. Dependências

Adicione as dependências no `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.1.0
  crypto: ^3.0.3
  equatable: ^2.0.5
  qr_flutter: ^4.1.0  # Para exibir QR Code
```

## 🔧 Instalação

### 1. Estrutura de Arquivos

A integração está organizada nos seguintes arquivos:

```
lib/src/
├── config/
│   └── app_config.dart
├── services/evolution/
│   ├── evolution_api_service.dart
│   ├── evolution_models.dart
│   ├── evolution_webhook_handler.dart
│   └── whatsapp_integration_service.dart
└── components/whatsapp/
    └── whatsapp_integration_widget.dart
```

### 2. Inicialização

Para inicializar a integração:

```dart
import 'package:seu_app/src/services/evolution/whatsapp_integration_service.dart';

final whatsappService = WhatsAppIntegrationService();

// Inicializar a integração
final success = await whatsappService.initialize();
if (success) {
  print('WhatsApp integrado com sucesso!');
}
```

## 🚀 Uso Básico

### 1. Verificar Status da Conexão

```dart
// Verificar se está conectado
bool isConnected = whatsappService.isWhatsAppConnected;

// Obter instância atual
EvolutionInstance? instance = whatsappService.currentInstance;

// Escutar mudanças de status
whatsappService.instanceStatusStream.listen((instance) {
  print('Status mudou: ${instance.status.name}');
});
```

### 2. Obter QR Code

```dart
// Escutar atualizações do QR Code
whatsappService.qrCodeStream.listen((qrCode) {
  // Exibir QR Code para o usuário escanear
  showQrCodeDialog(qrCode);
});
```

### 3. Enviar Mensagens de Texto

```dart
final success = await whatsappService.sendTextMessage(
  phoneNumber: '5511999999999',
  message: 'Olá! Esta é uma mensagem de teste do BKCRM.',
);

if (success) {
  print('Mensagem enviada!');
}
```

### 4. Enviar Arquivos de Mídia

```dart
final success = await whatsappService.sendMediaMessage(
  phoneNumber: '5511999999999',
  mediaPath: '/caminho/para/arquivo.jpg',
  caption: 'Legenda da imagem',
);

if (success) {
  print('Mídia enviada!');
}
```

### 5. Receber Mensagens

```dart
// Escutar novas mensagens
whatsappService.newMessageStream.listen((message) {
  print('Nova mensagem de ${message.sender.name}: ${message.content}');
  
  // Processar mensagem recebida
  processIncomingMessage(message);
});

// Escutar atualizações de mensagem (status de leitura, etc.)
whatsappService.messageUpdateStream.listen((message) {
  print('Mensagem atualizada: ${message.status.name}');
});
```

## 🔗 Webhooks

### 1. Configuração do Webhook

A Evolution API enviará webhooks para o endpoint configurado. Você precisa implementar um servidor HTTP para receber os webhooks:

```dart
import 'dart:io';
import 'dart:convert';

void startWebhookServer() async {
  final server = await HttpServer.bind('0.0.0.0', 8080);
  
  await for (HttpRequest request in server) {
    if (request.method == 'POST' && request.uri.path == '/webhook/evolution') {
      final headers = <String, String>{};
      request.headers.forEach((name, values) {
        headers[name] = values.first;
      });
      
      final body = await utf8.decodeStream(request);
      
      // Processar webhook
      final response = await whatsappService.processWebhook(headers, body);
      
      request.response
        ..statusCode = response['success'] ? 200 : 400
        ..headers.contentType = ContentType.json
        ..write(json.encode(response));
      
      await request.response.close();
    }
  }
}
```

### 2. Eventos de Webhook

Os seguintes eventos são suportados:

- `MESSAGES_UPSERT`: Nova mensagem recebida
- `MESSAGES_UPDATE`: Atualização de status da mensagem
- `CONNECTION_UPDATE`: Mudança no status da conexão
- `QRCODE_UPDATED`: Novo QR Code disponível

## 💡 Exemplos de Código

### 1. Widget Completo de Integração

```dart
import 'package:flutter/material.dart';
import 'package:seu_app/src/components/whatsapp/whatsapp_integration_widget.dart';

class WhatsAppPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const WhatsAppIntegrationWidget();
  }
}
```

### 2. Envio de Mensagem Personalizada

```dart
Future<void> sendCustomMessage({
  required String phoneNumber,
  required String customerName,
  required String ticketId,
}) async {
  final message = '''
Olá $customerName!

Seu ticket #$ticketId foi recebido e está sendo processado.
Em breve nossa equipe entrará em contato.

Atenciosamente,
Equipe BKCRM
''';

  final success = await whatsappService.sendTextMessage(
    phoneNumber: phoneNumber,
    message: message,
  );

  if (success) {
    print('Notificação enviada para $customerName');
  }
}
```

### 3. Processamento de Mensagens Recebidas

```dart
void setupMessageHandling() {
  whatsappService.newMessageStream.listen((message) {
    // Verificar se é uma mensagem de cliente
    if (message.sender.role == UserRole.customer) {
      // Criar ticket automaticamente
      createTicketFromMessage(message);
      
      // Enviar confirmação automática
      sendAutoReply(message.sender);
      
      // Notificar agentes
      notifyAgents(message);
    }
  });
}

Future<void> sendAutoReply(User customer) async {
  final autoReply = '''
Olá! Recebemos sua mensagem e em breve um de nossos atendentes irá responder.

Horário de atendimento: Segunda a Sexta, 8h às 18h.

Obrigado por entrar em contato!
''';

  await whatsappService.sendTextMessage(
    phoneNumber: extractPhoneNumber(customer.id),
    message: autoReply,
  );
}
```

## 🔍 Troubleshooting

### Problemas Comuns

#### 1. Erro de Conexão

```
Erro: Failed to initialize WhatsApp integration
```

**Solução**: Verifique as configurações da API:
- URL da Evolution API está correta
- API Key é válida
- Nome da instância existe

#### 2. QR Code não aparece

```
Erro: QR Code não foi gerado
```

**Solução**: 
- Verifique se a instância precisa de QR Code
- Reinicie a conexão
- Verifique os logs da Evolution API

#### 3. Mensagens não são recebidas

```
Erro: Webhook não está funcionando
```

**Solução**:
- Verifique se o webhook está configurado corretamente
- Confirme se o endpoint está acessível
- Verifique os logs do servidor webhook

#### 4. Erro ao enviar mídia

```
Erro: Failed to send media message
```

**Solução**:
- Verifique se o arquivo existe
- Confirme se o tipo de arquivo é suportado
- Verifique o tamanho do arquivo (máx 16MB)

### Logs e Debug

Para habilitar logs detalhados:

```dart
// No app_config.dart
static const bool enableLogging = true;
```

Os logs aparecerão no console com o formato:
```
[2024-01-20T10:30:00] [WhatsAppIntegration] Sending text message to 5511999999999
```

## 📞 Suporte

Para suporte adicional:

1. Verifique a documentação da Evolution API
2. Consulte os logs do aplicativo
3. Teste a conexão com a API manualmente
4. Entre em contato com o suporte técnico

## 🔐 Segurança

### Recomendações de Segurança

1. **API Key**: Mantenha a API key segura e não compartilhe
2. **Webhook Secret**: Use um secret forte para validar webhooks
3. **HTTPS**: Sempre use HTTPS para comunicação
4. **Validação**: Valide todas as mensagens recebidas
5. **Rate Limiting**: Implemente controle de taxa para evitar spam

### Exemplo de Validação de Webhook

```dart
bool validateWebhook(Map<String, String> headers, String body) {
  final signature = headers['x-evolution-signature'];
  final expectedSignature = generateSignature(body, AppConfig.webhookSecret);
  
  return signature == expectedSignature;
}
```

## 📈 Métricas e Monitoramento

### Métricas Importantes

- Taxa de entrega de mensagens
- Tempo de resposta da API
- Status de conexão da instância
- Volume de mensagens por hora

### Exemplo de Monitoramento

```dart
class WhatsAppMetrics {
  static int messagesSent = 0;
  static int messagesReceived = 0;
  static DateTime? lastConnectionTime;
  
  static void trackMessageSent() {
    messagesSent++;
    AppConfig.log('Messages sent: $messagesSent');
  }
  
  static void trackMessageReceived() {
    messagesReceived++;
    AppConfig.log('Messages received: $messagesReceived');
  }
}
```

---

**Versão da Documentação**: 1.0.0  
**Última Atualização**: Janeiro 2024  
**Compatibilidade**: Evolution API v1.x 