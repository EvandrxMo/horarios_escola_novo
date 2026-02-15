import 'package:flutter/material.dart';
import 'dart:async';
import '../services/sptransService.dart';
import '../models/onibus_model.dart';

class OnibusDetalhesPage extends StatefulWidget {
  const OnibusDetalhesPage({super.key});

  @override
  State<OnibusDetalhesPage> createState() => _OnibusDetalhesPageState();
}

class _OnibusDetalhesPageState extends State<OnibusDetalhesPage> {
  final SPTransService _service = SPTransService();
  List<PrevisaoOnibus> _previsoes = [];
  bool _carregando = true;
  String? _erro;
  Timer? _timer;

  // Configurações fixas para o ônibus 917H-10
  final String _codigoPonto = '390000299';
  final String _nomeLinha = '917H-10';

  @override
  void initState() {
    super.initState();
    _buscarPrevisoes();
    // Atualiza a cada 30 segundos
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _buscarPrevisoes();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _buscarPrevisoes() async {
    if (!mounted) return;
    
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final previsoes = await _service.buscarPrevisao(_codigoPonto, _nomeLinha);
      
      if (!mounted) return;
      
      setState(() {
        _previsoes = previsoes;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _erro = 'Erro ao buscar previsões';
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Previsão de Ônibus'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _buscarPrevisoes,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _buscarPrevisoes,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Informações da linha
            Card(
              color: Colors.deepPurple[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_bus, size: 32, color: Colors.deepPurple),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Linha $_nomeLinha',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Ponto: $_codigoPonto',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Previsões
            if (_carregando)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_erro != null)
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _erro!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_previsoes.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.schedule, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum ônibus previsto no momento',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Próximos ônibus (${_previsoes.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._previsoes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final previsao = entry.value;
                    final isPrimeiro = index == 0;
                    
                    return Card(
                      elevation: isPrimeiro ? 4 : 2,
                      color: isPrimeiro ? Colors.white : Colors.grey[50],
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Indicador de posição
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isPrimeiro ? previsao.cor : Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}º',
                                  style: TextStyle(
                                    color: isPrimeiro ? Colors.white : Colors.black54,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Informações
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    previsao.tempoLongo,
                                    style: TextStyle(
                                      fontSize: isPrimeiro ? 20 : 16,
                                      fontWeight: isPrimeiro ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Previsão: ${previsao.horarioChegada}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Ícone de tempo
                            Icon(
                              Icons.access_time,
                              color: isPrimeiro ? previsao.cor : Colors.grey,
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
          ],
        ),
      ),
    );
  }
}