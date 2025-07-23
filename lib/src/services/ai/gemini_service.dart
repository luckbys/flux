import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../models/message.dart';
import '../../models/ticket.dart';

class GeminiService {
  static const String _apiKey =
      'YOUR_GEMINI_API_KEY'; // TODO: Mover para variáveis de ambiente
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: _apiKey,
    );
  }

  // Análise de sentimento de mensagens
  Future<SentimentAnalysis> analyzeSentiment(String text) async {
    try {
      final prompt = '''
Analise o sentimento da seguinte mensagem em português brasileiro e retorne apenas um JSON válido:

Mensagem: "$text"

Retorne no formato:
{
  "sentiment": "positive|negative|neutral",
  "confidence": 0.95,
  "emotions": ["alegria", "satisfação"],
  "urgency": "low|medium|high"
}
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final jsonString = response.text?.trim() ?? '{}';

      // Remove markdown if present
      final cleanJson =
          jsonString.replaceAll('```json', '').replaceAll('```', '').trim();
      final data = json.decode(cleanJson);

      return SentimentAnalysis.fromJson(data);
    } catch (e) {
      // Retorna análise neutra em caso de erro
      return SentimentAnalysis(
        sentiment: 'neutral',
        confidence: 0.5,
        emotions: [],
        urgency: 'low',
      );
    }
  }

  // Classificação automática de tickets
  Future<TicketClassification> classifyTicket(
      String title, String description) async {
    try {
      final prompt = '''
Classifique o seguinte ticket de suporte em português brasileiro e retorne apenas um JSON válido:

Título: "$title"
Descrição: "$description"

Analise e retorne no formato:
{
  "category": "technical|billing|general|complaint|feature",
  "priority": "low|normal|high|urgent",
  "tags": ["tag1", "tag2"],
  "estimatedResolutionTime": "30m|2h|1d|3d|1w",
  "requiredDepartment": "suporte|tecnico|financeiro|vendas"
}
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final jsonString = response.text?.trim() ?? '{}';

      final cleanJson =
          jsonString.replaceAll('```json', '').replaceAll('```', '').trim();
      final data = json.decode(cleanJson);

      return TicketClassification.fromJson(data);
    } catch (e) {
      // Retorna classificação padrão em caso de erro
      return TicketClassification(
        category: TicketCategory.general,
        priority: TicketPriority.normal,
        tags: [],
        estimatedResolutionTime: '1d',
        requiredDepartment: 'suporte',
      );
    }
  }

  // Sugestões de resposta para agentes
  Future<List<String>> generateResponseSuggestions({
    required String customerMessage,
    required List<Message> conversationHistory,
    required TicketCategory category,
  }) async {
    try {
      final historyText = conversationHistory
          .take(5) // Últimas 5 mensagens para contexto
          .map((msg) => '${msg.sender.name}: ${msg.content}')
          .join('\n');

      final prompt = '''
Com base na conversa de suporte ao cliente abaixo, gere 3 sugestões de resposta profissionais e úteis em português brasileiro.

Categoria do ticket: ${_getCategoryText(category)}
Histórico da conversa:
$historyText

Última mensagem do cliente: "$customerMessage"

Retorne apenas um JSON válido com 3 sugestões:
{
  "suggestions": [
    "Resposta sugerida 1",
    "Resposta sugerida 2", 
    "Resposta sugerida 3"
  ]
}
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final jsonString = response.text?.trim() ?? '{}';

      final cleanJson =
          jsonString.replaceAll('```json', '').replaceAll('```', '').trim();
      final data = json.decode(cleanJson);

      return List<String>.from(data['suggestions'] ?? []);
    } catch (e) {
      // Retorna sugestões padrão em caso de erro
      return [
        'Obrigado por entrar em contato. Vou analisar sua solicitação.',
        'Entendo sua preocupação. Vamos resolver isso juntos.',
        'Preciso de mais informações para ajudá-lo melhor.',
      ];
    }
  }

  // Tradução automática de mensagens
  Future<String> translateMessage(String text, String targetLanguage) async {
    try {
      final prompt = '''
Traduza a seguinte mensagem para $targetLanguage mantendo o tom e contexto:

"$text"

Retorne apenas a tradução, sem explicações adicionais.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? text;
    } catch (e) {
      return text; // Retorna texto original em caso de erro
    }
  }

  // Análise de satisfação do cliente
  Future<CustomerSatisfactionAnalysis> analyzeCustomerSatisfaction(
    List<Message> conversationHistory,
  ) async {
    try {
      final conversationText = conversationHistory
          .map((msg) => '${msg.sender.name}: ${msg.content}')
          .join('\n');

      final prompt = '''
Analise a satisfação do cliente com base na conversa de suporte abaixo e retorne apenas um JSON válido:

Conversa:
$conversationText

Retorne no formato:
{
  "satisfactionLevel": "very_low|low|medium|high|very_high",
  "score": 8.5,
  "indicators": ["cliente agradeceu", "problema resolvido"],
  "recommendations": ["manter qualidade", "follow-up em 24h"]
}
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final jsonString = response.text?.trim() ?? '{}';

      final cleanJson =
          jsonString.replaceAll('```json', '').replaceAll('```', '').trim();
      final data = json.decode(cleanJson);

      return CustomerSatisfactionAnalysis.fromJson(data);
    } catch (e) {
      return CustomerSatisfactionAnalysis(
        satisfactionLevel: 'medium',
        score: 5.0,
        indicators: [],
        recommendations: [],
      );
    }
  }

  // Detecção de spam/abuso
  Future<SpamDetectionResult> detectSpam(String content) async {
    try {
      final prompt = '''
Analise se o seguinte conteúdo é spam, abusivo ou inadequado e retorne apenas um JSON válido:

Conteúdo: "$content"

Retorne no formato:
{
  "isSpam": false,
  "isAbusive": false,
  "confidence": 0.95,
  "reasons": ["linguagem apropriada", "contexto válido"],
  "action": "allow|flag|block"
}
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final jsonString = response.text?.trim() ?? '{}';

      final cleanJson =
          jsonString.replaceAll('```json', '').replaceAll('```', '').trim();
      final data = json.decode(cleanJson);

      return SpamDetectionResult.fromJson(data);
    } catch (e) {
      return SpamDetectionResult(
        isSpam: false,
        isAbusive: false,
        confidence: 0.5,
        reasons: [],
        action: 'allow',
      );
    }
  }

  String _getCategoryText(TicketCategory category) {
    switch (category) {
      case TicketCategory.technical:
        return 'Técnico';
      case TicketCategory.billing:
        return 'Financeiro';
      case TicketCategory.general:
        return 'Geral';
      case TicketCategory.complaint:
        return 'Reclamação';
      case TicketCategory.feature:
        return 'Feature';
    }
  }
}

// Modelos de dados para análises de IA
class SentimentAnalysis {
  final String sentiment;
  final double confidence;
  final List<String> emotions;
  final String urgency;

  SentimentAnalysis({
    required this.sentiment,
    required this.confidence,
    required this.emotions,
    required this.urgency,
  });

  factory SentimentAnalysis.fromJson(Map<String, dynamic> json) {
    return SentimentAnalysis(
      sentiment: json['sentiment'] ?? 'neutral',
      confidence: (json['confidence'] ?? 0.5).toDouble(),
      emotions: List<String>.from(json['emotions'] ?? []),
      urgency: json['urgency'] ?? 'low',
    );
  }
}

class TicketClassification {
  final TicketCategory category;
  final TicketPriority priority;
  final List<String> tags;
  final String estimatedResolutionTime;
  final String requiredDepartment;

  TicketClassification({
    required this.category,
    required this.priority,
    required this.tags,
    required this.estimatedResolutionTime,
    required this.requiredDepartment,
  });

  factory TicketClassification.fromJson(Map<String, dynamic> json) {
    return TicketClassification(
      category: _parseCategory(json['category']),
      priority: _parsePriority(json['priority']),
      tags: List<String>.from(json['tags'] ?? []),
      estimatedResolutionTime: json['estimatedResolutionTime'] ?? '1d',
      requiredDepartment: json['requiredDepartment'] ?? 'suporte',
    );
  }

  static TicketCategory _parseCategory(String? category) {
    switch (category) {
      case 'technical':
        return TicketCategory.technical;
      case 'billing':
        return TicketCategory.billing;
      case 'complaint':
        return TicketCategory.complaint;
      case 'feature':
        return TicketCategory.feature;
      default:
        return TicketCategory.general;
    }
  }

  static TicketPriority _parsePriority(String? priority) {
    switch (priority) {
      case 'low':
        return TicketPriority.low;
      case 'high':
        return TicketPriority.high;
      case 'urgent':
        return TicketPriority.urgent;
      default:
        return TicketPriority.normal;
    }
  }
}

class CustomerSatisfactionAnalysis {
  final String satisfactionLevel;
  final double score;
  final List<String> indicators;
  final List<String> recommendations;

  CustomerSatisfactionAnalysis({
    required this.satisfactionLevel,
    required this.score,
    required this.indicators,
    required this.recommendations,
  });

  factory CustomerSatisfactionAnalysis.fromJson(Map<String, dynamic> json) {
    return CustomerSatisfactionAnalysis(
      satisfactionLevel: json['satisfactionLevel'] ?? 'medium',
      score: (json['score'] ?? 5.0).toDouble(),
      indicators: List<String>.from(json['indicators'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }
}

class SpamDetectionResult {
  final bool isSpam;
  final bool isAbusive;
  final double confidence;
  final List<String> reasons;
  final String action;

  SpamDetectionResult({
    required this.isSpam,
    required this.isAbusive,
    required this.confidence,
    required this.reasons,
    required this.action,
  });

  factory SpamDetectionResult.fromJson(Map<String, dynamic> json) {
    return SpamDetectionResult(
      isSpam: json['isSpam'] ?? false,
      isAbusive: json['isAbusive'] ?? false,
      confidence: (json['confidence'] ?? 0.5).toDouble(),
      reasons: List<String>.from(json['reasons'] ?? []),
      action: json['action'] ?? 'allow',
    );
  }
}
