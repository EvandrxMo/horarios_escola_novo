import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/pomodoro_service.dart';
import 'foco_relatorio_page.dart';
import '../preferences/classesData.dart';
import '../preferences/tarefasData.dart';
import '../preferences/provasData.dart';
import '../models/tarefa_model.dart';

class FocoPage extends StatefulWidget {
  const FocoPage({super.key});

  @override
  State<FocoPage> createState() => _FocoPageState();
}

class _FocoPageState extends State<FocoPage> {
  String? _tarefaSelecionada;
  String? _provaSelecionada;

  @override
  void initState() {
    super.initState();
    _mostrarAvisoBloqueioNotificacoes();
  }

  void _mostrarAvisoBloqueioNotificacoes() {
    Future.delayed(const Duration(milliseconds: 500), () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.notifications_off, color: Colors.orange),
              SizedBox(width: 8),
              Text('Modo Foco'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📱 Notificações silenciadas',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Apenas emergências serão exibidas'),
              Text('• Redes sociais pausadas'),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.phone, color: Colors.green, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Chamadas importantes funcionam',
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Entendi'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PomodoroService(),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text('Modo Foco'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.bar_chart),
              tooltip: 'Relatório',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FocoRelatorioPage()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: _mostrarConfiguracoes,
            ),
          ],
        ),
        body: Consumer<PomodoroService>(
          builder: (context, pomodoro, child) {
            if (pomodoro.estaEmExecucao) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTimerCircular(pomodoro),
                      const SizedBox(height: 30),
                      _buildControles(pomodoro),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Timer principal
                  _buildTimerCircular(pomodoro),
                  const SizedBox(height: 30),
                  
                  // Informações da sessão
                  _buildInformacoesSessao(pomodoro),
                  const SizedBox(height: 30),
                  
                  // Seleção de matéria/tarefa
                  _buildSelecaoAtividade(pomodoro),
                  const SizedBox(height: 30),
                  
                  // Controles
                  _buildControles(pomodoro),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimerCircular(PomodoroService pomodoro) {
    return Container(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Círculo de progresso
          SizedBox(
            width: 250,
            height: 250,
            child: CircularProgressIndicator(
              value: pomodoro.progressoPercentual,
              strokeWidth: 12,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(pomodoro.corEstado),
            ),
          ),
          
          // Conteúdo central
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                pomodoro.tempoFormatado,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: pomodoro.corEstado,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                pomodoro.tituloEstado,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                pomodoro.descricaoEstado,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInformacoesSessao(PomodoroService pomodoro) {
    final stats = pomodoro.estatisticasSessaoAtual;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (stats.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.book, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  'Matéria: ${stats['materia']}',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SizedBox(height: 8),
          ],
          Row(
            children: [
              Icon(
                pomodoro.notificacoesBloqueadas ? Icons.notifications_off : Icons.notifications_active,
                color: pomodoro.notificacoesBloqueadas ? Colors.red : Colors.green,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                pomodoro.notificacoesBloqueadas
                  ? 'Notificações bloqueadas durante foco'
                  : 'Notificações ativas',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Ciclo Atual',
                  '${pomodoro.cicloAtual}',
                  Icons.loop,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'Ciclos Hoje',
                  '${pomodoro.ciclosCompletos}',
                  Icons.emoji_events,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String titulo, String valor, IconData icone, Color cor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icone, color: cor, size: 24),
          SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelecaoAtividade(PomodoroService pomodoro) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'O que estudar?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          
          // Seleção de matéria
          _buildSelecaoMateria(pomodoro),
          const SizedBox(height: 12),
          
          // Seleção de tarefa
          _buildSelecaoTarefa(pomodoro),
          const SizedBox(height: 12),
          // Seleção de prova
          _buildSelecaoProva(pomodoro),
        ],
      ),
    );
  }



  Widget _buildSelecaoMateria(PomodoroService pomodoro) {
    final materias = ClassesData.obterMateriasUnicas();
    final materiaSelecionada = pomodoro.materiaSelecionada;

    // Se a matéria selecionada for uma tarefa/prova customizada (com emoji), adiciona como opção
    final materiasDisponiveis = <String>[];
    materiasDisponiveis.addAll(materias);
    if (materiaSelecionada != null && materiaSelecionada.isNotEmpty && !materiasDisponiveis.contains(materiaSelecionada)) {
      materiasDisponiveis.add(materiaSelecionada);
    }

    return DropdownButtonFormField<String>(
      value: materiaSelecionada,
      decoration: InputDecoration(
        labelText: 'Matéria',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.school),
      ),
      items: [
        DropdownMenuItem(
          value: null,
          child: Text('Sem matéria'),
        ),
        ...materiasDisponiveis.map((materia) {
          return DropdownMenuItem(
            value: materia,
            child: Text(
              materia,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }),
      ],
      onChanged: (value) {
        pomodoro.selecionarMateria(value);
      },
    );
  }

  Widget _buildSelecaoTarefa(PomodoroService pomodoro) {
    final tarefasPendentes = TarefasData.tarefas.where((t) => !t.concluida).toList();
    
    // Garantir que não há IDs duplicados (caso raro de bug nos dados)
    final tarefasUnicas = <String, Tarefa>{};
    for (final tarefa in tarefasPendentes) {
      tarefasUnicas[tarefa.id] = tarefa;
    }
    final tarefasFiltradas = tarefasUnicas.values.toList();
    
    if (tarefasFiltradas.isEmpty) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              'Nenhuma tarefa pendente',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return DropdownButtonFormField<String>(
      value: _tarefaSelecionada,
      decoration: InputDecoration(
        labelText: 'Tarefa (opcional)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.task),
      ),
      items: [
        DropdownMenuItem(
          value: null,
          child: Text('Sem tarefa'),
        ),
        ...tarefasFiltradas.map((tarefa) {
          String textoExibicao = tarefa.nome;
          if (tarefa.materia != null && tarefa.materia != 'OUTROS') {
            textoExibicao = '${tarefa.materia}: ${tarefa.nome}';
          } else if (tarefa.materia == 'OUTROS') {
            textoExibicao = 'OUTROS: ${tarefa.nome}';
          }
          
          return DropdownMenuItem(
            value: tarefa.id,
            child: Text(
              textoExibicao,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          _tarefaSelecionada = value;
        });

        if (value != null) {
          try {
            final tarefa = tarefasFiltradas.firstWhere((t) => t.id == value);
            pomodoro.selecionarMateria('📝 ${tarefa.nome}');
          } catch (e) {
            print('Tarefa não encontrada: $value');
          }
        } else {
          pomodoro.selecionarMateria(null);
        }
      },
    );
  }

  Widget _buildSelecaoProva(PomodoroService pomodoro) {
    final provas = ProvasData.provas;
    final proximasProvas = provas
        .where((p) => p.data.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.data.compareTo(b.data)); // Ordena por data
    
    // Garantir que não há chaves duplicadas (caso raro de bug nos dados)
    final provasUnicas = <String, dynamic>{};
    for (final prova in proximasProvas) {
      provasUnicas[prova.chave] = prova;
    }
    final provasFiltradas = provasUnicas.values.toList().cast();
    
    if (provasFiltradas.isEmpty) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              'Nenhuma prova próxima',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return DropdownButtonFormField<String>(
      value: _provaSelecionada,
      decoration: InputDecoration(
        labelText: 'Estudar para prova (opcional)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.assignment),
      ),
      items: [
        DropdownMenuItem(
          value: null,
          child: Text('Sem prova'),
        ),
        ...provasFiltradas.map((prova) {
          String textoExibicao;
          if (prova.materia == 'SIMULADO') {
            textoExibicao = 'SIMULADO - ${prova.dataFormatada}';
          } else {
            textoExibicao = '${prova.materia} - ${prova.dataFormatada}';
          }
          
          return DropdownMenuItem(
            value: prova.chave,
            child: Text(
              textoExibicao,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          _provaSelecionada = value;
        });

        if (value != null) {
          try {
            final prova = provasFiltradas.firstWhere((p) => p.chave == value);
            pomodoro.selecionarMateria('📚 ${prova.materia} - Prova');
          } catch (e) {
            print('Prova não encontrada: $value');
          }
        } else {
          pomodoro.selecionarMateria(null);
        }
      },
    );
  }

  Widget _buildControles(PomodoroService pomodoro) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Botão principal
          ElevatedButton(
            onPressed: () {
              if (pomodoro.estaEmExecucao) {
                pomodoro.pausar();
              } else {
                pomodoro.iniciar();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: pomodoro.corEstado,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  pomodoro.estaEmExecucao ? Icons.pause : Icons.play_arrow,
                ),
                SizedBox(width: 8),
                Text(
                  pomodoro.estaEmExecucao ? 'Pausar' : 'Iniciar',
                ),
              ],
            ),
          ),
          
          // Botões secundários
          Column(
            children: [
              IconButton(
                onPressed: () {
                  pomodoro.pular();
                },
                icon: Icon(Icons.skip_next),
                tooltip: 'Pular',
              ),
              Text('Pular', style: TextStyle(fontSize: 12)),
            ],
          ),
          
          Column(
            children: [
              IconButton(
                onPressed: () {
                  pomodoro.parar();
                },
                icon: Icon(Icons.stop),
                tooltip: 'Parar',
              ),
              Text('Parar', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }


  @override
  void dispose() {
    super.dispose();
  }

  Future<bool> _temInternet() async {
    try {
      final result = await InternetAddress.lookup('example.com').timeout(Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _mostrarConfiguracoes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Configurações'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.notifications_off),
              title: Text('Bloqueio de Notificações'),
              subtitle: Text('Configurar apps'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Em desenvolvimento')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Configurar Timer'),
              subtitle: Text('Ajustar tempos'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Em desenvolvimento')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fechar'),
          ),
        ],
      ),
    );
  }

}
