import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/connectivity_test.dart';
import '../../styles/app_theme.dart';

class ConnectivityDebugPage extends StatefulWidget {
  const ConnectivityDebugPage({super.key});

  @override
  State<ConnectivityDebugPage> createState() => _ConnectivityDebugPageState();
}

class _ConnectivityDebugPageState extends State<ConnectivityDebugPage> {
  ConnectivityResult? _result;
  bool _isLoading = false;
  String _fullReport = '';

  @override
  void initState() {
    super.initState();
    _runTest();
  }

  Future<void> _runTest() async {
    setState(() {
      _isLoading = true;
      _result = null;
      _fullReport = '';
    });

    try {
      final result = await ConnectivityTest.runFullTest();
      final report = ConnectivityTest.generateReport(result);
      
      setState(() {
        _result = result;
        _fullReport = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro durante o teste: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyReport() {
    if (_fullReport.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _fullReport));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Relatório copiado para a área de transferência'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico de Conectividade'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _runTest,
          ),
          if (_fullReport.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: _copyReport,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Testando conectividade...'),
                ],
              ),
            )
          : _result == null
              ? const Center(
                  child: Text('Erro ao executar teste de conectividade'),
                )
              : _buildResultView(),
    );
  }

  Widget _buildResultView() {
    final result = _result!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Geral
          Card(
            color: result.success ? Colors.green.shade50 : Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    result.success ? Icons.check_circle : Icons.error,
                    color: result.success ? Colors.green : Colors.red,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.success ? 'Conectividade OK' : 'Problemas Detectados',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: result.success ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                        if (!result.success)
                          Text(
                            '${result.issues.length} problema(s) encontrado(s)',
                            style: TextStyle(color: Colors.red.shade600),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Testes Individuais
          _buildTestSection('Conectividade Básica', [
            _buildTestItem('Internet', result.hasInternet, 'Conexão com a internet'),
          ]),
          
          _buildTestSection('Supabase', [
            _buildTestItem('DNS', result.supabaseDnsResolved, 'Resolução de DNS'),
            _buildTestItem('HTTP', result.supabaseReachable, 'Conectividade HTTP'),
          ]),
          
          _buildTestSection('Evolution API', [
            _buildTestItem('DNS', result.evolutionDnsResolved, 'Resolução de DNS'),
            _buildTestItem('HTTP', result.evolutionReachable, 'Conectividade HTTP'),
          ]),
          
          // Erros
          if (result.errors.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Erros Detectados',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...result.errors.map((error) => Padding(
                      padding: const EdgeInsets.only(left: 32, top: 4),
                      child: Text(
                        '• $error',
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ],
          
          // Relatório Completo
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.description),
                      const SizedBox(width: 8),
                      const Text(
                        'Relatório Completo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _copyReport,
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copiar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      _fullReport,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildTestSection(String title, List<Widget> tests) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...tests,
          ],
        ),
      ),
    );
  }
  
  Widget _buildTestItem(String name, bool success, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.cancel,
            color: success ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            success ? 'OK' : 'FALHA',
            style: TextStyle(
              color: success ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}