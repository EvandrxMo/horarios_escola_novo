import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../preferences/tarefasData.dart';
import '../models/tarefa_model.dart';

class TarefasPage extends StatefulWidget {
  const TarefasPage({super.key});

  @override
  State<TarefasPage> createState() => _TarefasPageState();
}

class _TarefasPageState extends State<TarefasPage> {
  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    await TarefasData.carregarTarefas();
    setState(() {});
  }

  // Adicionar nova tarefa
  void _adicionarTarefa() {
    final nomeController = TextEditingController();
    DateTime? dataSelecionada;
    PrioridadeTarefa prioridadeSelecionada = PrioridadeTarefa.media;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nova Tarefa'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome da tarefa
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da tarefa',
                    border: OutlineInputBorder(),
                    hintText: 'Ex: Estudar para prova de matemática',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Data (opcional)
                const Text(
                  'Data (opcional):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    dataSelecionada != null
                        ? '${dataSelecionada!.day.toString().padLeft(2, '0')}/${dataSelecionada!.month.toString().padLeft(2, '0')}/${dataSelecionada!.year}'
                        : 'Nenhuma data selecionada',
                    style: TextStyle(
                      color: dataSelecionada != null ? Colors.black : Colors.grey,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (dataSelecionada != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setDialogState(() {
                              dataSelecionada = null;
                            });
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final data = await showDatePicker(
                            context: context,
                            initialDate: dataSelecionada ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (data != null) {
                            setDialogState(() {
                              dataSelecionada = data;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Prioridade
                const Text(
                  'Prioridade:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...PrioridadeTarefa.values.map((prioridade) {
                  return RadioListTile<PrioridadeTarefa>(
                    contentPadding: EdgeInsets.zero,
                    title: Row(
                      children: [
                        Icon(
                          prioridade.icone,
                          color: prioridade.cor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(prioridade.nome),
                      ],
                    ),
                    value: prioridade,
                    groupValue: prioridadeSelecionada,
                    onChanged: (value) {
                      setDialogState(() {
                        prioridadeSelecionada = value!;
                      });
                    },
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nomeController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Digite o nome da tarefa')),
                  );
                  return;
                }

                final tarefa = Tarefa(
                  id: const Uuid().v4(),
                  nome: nomeController.text.trim(),
                  data: dataSelecionada,
                  prioridade: prioridadeSelecionada,
                );

                TarefasData.adicionarTarefa(tarefa);
                await TarefasData.salvarTarefas();
                setState(() {});
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tarefa adicionada!')),
                );
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  // Editar tarefa
  void _editarTarefa(Tarefa tarefa) {
    final nomeController = TextEditingController(text: tarefa.nome);
    DateTime? dataSelecionada = tarefa.data;
    PrioridadeTarefa prioridadeSelecionada = tarefa.prioridade;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Tarefa'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da tarefa',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Data (opcional):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    dataSelecionada != null
                        ? '${dataSelecionada!.day.toString().padLeft(2, '0')}/${dataSelecionada!.month.toString().padLeft(2, '0')}/${dataSelecionada!.year}'
                        : 'Nenhuma data selecionada',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (dataSelecionada != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setDialogState(() {
                              dataSelecionada = null;
                            });
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final data = await showDatePicker(
                            context: context,
                            initialDate: dataSelecionada ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (data != null) {
                            setDialogState(() {
                              dataSelecionada = data;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Prioridade:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...PrioridadeTarefa.values.map((prioridade) {
                  return RadioListTile<PrioridadeTarefa>(
                    contentPadding: EdgeInsets.zero,
                    title: Row(
                      children: [
                        Icon(
                          prioridade.icone,
                          color: prioridade.cor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(prioridade.nome),
                      ],
                    ),
                    value: prioridade,
                    groupValue: prioridadeSelecionada,
                    onChanged: (value) {
                      setDialogState(() {
                        prioridadeSelecionada = value!;
                      });
                    },
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nomeController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Digite o nome da tarefa')),
                  );
                  return;
                }

                final tarefaAtualizada = tarefa.copyWith(
                  nome: nomeController.text.trim(),
                  data: dataSelecionada,
                  prioridade: prioridadeSelecionada,
                );

                TarefasData.editarTarefa(tarefaAtualizada);
                await TarefasData.salvarTarefas();
                setState(() {});
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tarefa atualizada!')),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  // Remover tarefa
  void _removerTarefa(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover tarefa?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() {
        TarefasData.removerTarefa(id);
      });
      await TarefasData.salvarTarefas();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarefa removida')),
      );
    }
  }

  // Limpar tarefas concluídas
  void _limparConcluidas() async {
    if (TarefasData.tarefasConcluidas == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma tarefa concluída para remover')),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar tarefas concluídas?'),
        content: Text('Isso irá remover ${TarefasData.tarefasConcluidas} tarefa(s) concluída(s).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() {
        TarefasData.limparTarefasConcluidas();
      });
      await TarefasData.salvarTarefas();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarefas concluídas removidas')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tarefasAgrupadas = TarefasData.obterTarefasAgrupadas();
    final datasOrdenadas = tarefasAgrupadas.keys.toList()
      ..sort((a, b) {
        if (a == 'Sem data') return 1;
        if (b == 'Sem data') return -1;
        return a.compareTo(b);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarefas'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: _limparConcluidas,
            tooltip: 'Limpar concluídas',
          ),
        ],
      ),
      body: TarefasData.tarefas.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma tarefa cadastrada',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toque no + para adicionar',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Estatísticas
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.deepPurple[50],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildEstatistica(
                        'Total',
                        TarefasData.totalTarefas.toString(),
                        Icons.list,
                        Colors.blue,
                      ),
                      _buildEstatistica(
                        'Pendentes',
                        TarefasData.tarefasPendentes.toString(),
                        Icons.pending_actions,
                        Colors.orange,
                      ),
                      _buildEstatistica(
                        'Concluídas',
                        TarefasData.tarefasConcluidas.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ],
                  ),
                ),

                // Lista de tarefas
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: datasOrdenadas.length,
                    itemBuilder: (context, index) {
                      final data = datasOrdenadas[index];
                      final tarefas = tarefasAgrupadas[data]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cabeçalho da data
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  data == 'Sem data' ? Icons.inbox : Icons.calendar_today,
                                  size: 18,
                                  color: Colors.deepPurple,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  data,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${tarefas.length})',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Tarefas
                          ...tarefas.map((tarefa) => _buildTarefaCard(tarefa)),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarTarefa,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEstatistica(String label, String valor, IconData icone, Color cor) {
    return Column(
      children: [
        Icon(icone, color: cor, size: 24),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildTarefaCard(Tarefa tarefa) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: tarefa.concluida ? 1 : 2,
      color: tarefa.concluida ? Colors.grey[100] : Colors.white,
      child: ListTile(
        leading: Checkbox(
          value: tarefa.concluida,
          onChanged: (value) async {
            setState(() {
              TarefasData.toggleConclusao(tarefa.id);
            });
            await TarefasData.salvarTarefas();
          },
        ),
        title: Text(
          tarefa.nome,
          style: TextStyle(
            decoration: tarefa.concluida ? TextDecoration.lineThrough : null,
            color: tarefa.concluida ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: tarefa.data != null
            ? Text(
                tarefa.dataFormatada,
                style: TextStyle(
                  fontSize: 12,
                  color: tarefa.concluida ? Colors.grey : Colors.black54,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Flag de prioridade
            Icon(
              tarefa.prioridade.icone,
              color: tarefa.prioridade.cor,
              size: 20,
            ),
            const SizedBox(width: 8),
            // Botão editar
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editarTarefa(tarefa),
              color: Colors.blue,
            ),
            // Botão remover
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: () => _removerTarefa(tarefa.id),
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}