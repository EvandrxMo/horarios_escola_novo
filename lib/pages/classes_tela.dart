import 'package:flutter/material.dart';
import '../preferences/classesData.dart';
import '../preferences/appData.dart';
import '../models/aula_model.dart';

class ClassesPage extends StatefulWidget {
  const ClassesPage({super.key});

  @override
  State<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    await ClassesData.carregarAulas();
    await AppData.carregarDados();
    setState(() {});
  }

  // Alterna entre visualização semanal e diária
  void _alternarVisualizacao() async {
    setState(() {
      AppData.visualizacaoSemanal = !AppData.visualizacaoSemanal;
    });
    await AppData.salvarDados();
  }

  // NOVO: Mostra lista de todas as aulas cadastradas
  void _mostrarListaAulas() {
    // Coleta todas as aulas
    final todasAulas = <Aula>[];
    for (var dia in ClassesData.diasSemana) {
      for (var horario in ClassesData.horarios) {
        if (horario != 'INTERVALO') {
          final aula = ClassesData.buscarAula(dia, horario);
          if (aula != null) {
            todasAulas.add(aula);
          }
        }
      }
    }

    if (todasAulas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma aula cadastrada')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aulas Cadastradas'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: todasAulas.length,
            itemBuilder: (context, index) {
              final aula = todasAulas[index];
              return Card(
                color: aula.cor ?? Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(
                    aula.materia,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (aula.professor.isNotEmpty)
                        Text('Professor: ${aula.professor}'),
                      Text('${aula.diaSemana} - ${aula.horario}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.pop(context);
                          _editarAula(aula);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          Navigator.pop(context);
                          _removerAula(aula.diaSemana, aula.horario);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // NOVO: Editar aula existente
  void _editarAula(Aula aulaOriginal) {
    final materiaController = TextEditingController(text: aulaOriginal.materia);
    final professorController = TextEditingController(text: aulaOriginal.professor);
    Color? corSelecionada = aulaOriginal.cor;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Editar Aula - ${aulaOriginal.diaSemana} ${aulaOriginal.horario}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: materiaController,
                  decoration: const InputDecoration(
                    labelText: 'Matéria',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: professorController,
                  decoration: const InputDecoration(
                    labelText: 'Professor',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Cor (opcional):', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildCorOption(null, corSelecionada, setDialogState, (cor) => corSelecionada = cor),
                    ...[
                      Colors.red[300]!,
                      Colors.blue[300]!,
                      Colors.green[300]!,
                      Colors.yellow[300]!,
                      Colors.purple[300]!,
                      Colors.orange[300]!,
                      Colors.pink[300]!,
                      Colors.teal[300]!,
                    ].map((cor) => _buildCorOption(cor, corSelecionada, setDialogState, (c) => corSelecionada = c)),
                  ],
                ),
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
                if (materiaController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, insira a matéria')),
                  );
                  return;
                }

                final aulaAtualizada = Aula(
                  materia: materiaController.text.trim(),
                  professor: professorController.text.trim(),
                  diaSemana: aulaOriginal.diaSemana,
                  horario: aulaOriginal.horario,
                  cor: corSelecionada,
                );

                ClassesData.adicionarAula(aulaAtualizada);
                await ClassesData.salvarAulas();
                setState(() {});
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Aula atualizada!')),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  // Abre dialog para adicionar nova aula
  void _adicionarNovaAula() {
    final materiaController = TextEditingController();
    final professorController = TextEditingController();
    Color? corSelecionada;
    final horariosRecorrentes = <String, Set<String>>{}; // dia -> set de horários

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nova Aula'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Campo Matéria
                TextField(
                  controller: materiaController,
                  decoration: const InputDecoration(
                    labelText: 'Matéria',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Campo Professor
                TextField(
                  controller: professorController,
                  decoration: const InputDecoration(
                    labelText: 'Professor',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Seletor de cor
                const Text('Cor (opcional):', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildCorOption(null, corSelecionada, setDialogState, (cor) => corSelecionada = cor),
                    ...[ 
                      Colors.red[300]!,
                      Colors.blue[300]!,
                      Colors.green[300]!,
                      Colors.yellow[300]!,
                      Colors.purple[300]!,
                      Colors.orange[300]!,
                      Colors.pink[300]!,
                      Colors.teal[300]!,
                    ].map((cor) => _buildCorOption(cor, corSelecionada, setDialogState, (c) => corSelecionada = c)),
                  ],
                ),
                const SizedBox(height: 16),

                // Seleção de horários
                const Text('Selecione os horários:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...ClassesData.diasSemana.map((dia) {
                  return ExpansionTile(
                    title: Text(dia),
                    children: ClassesData.horarios
                        .where((h) => h != 'INTERVALO')
                        .map((horario) {
                      final jaTemAula = ClassesData.existeAula(dia, horario);
                      final estaSelecionado = horariosRecorrentes[dia]?.contains(horario) ?? false;

                      return CheckboxListTile(
                        title: Text(horario),
                        subtitle: jaTemAula ? const Text('Já possui aula', style: TextStyle(color: Colors.orange, fontSize: 11)) : null,
                        value: estaSelecionado,
                        dense: true,
                        onChanged: (valor) {
                          setDialogState(() {
                            if (valor == true) {
                              horariosRecorrentes.putIfAbsent(dia, () => {});
                              horariosRecorrentes[dia]!.add(horario);
                            } else {
                              horariosRecorrentes[dia]?.remove(horario);
                            }
                          });
                        },
                      );
                    }).toList(),
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
                if (materiaController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, insira a matéria')),
                  );
                  return;
                }

                // Verifica se selecionou pelo menos um horário
                final totalSelecionados = horariosRecorrentes.values.fold<int>(
                  0,
                  (sum, set) => sum + set.length,
                );

                if (totalSelecionados == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Selecione pelo menos um horário')),
                  );
                  return;
                }

                // Verifica conflitos
                final List<String> conflitos = [];
                horariosRecorrentes.forEach((dia, horarios) {
                  for (var horario in horarios) {
                    if (ClassesData.existeAula(dia, horario)) {
                      conflitos.add('$dia às $horario');
                    }
                  }
                });

                // Se houver conflitos, pede confirmação
                if (conflitos.isNotEmpty) {
                  final confirmar = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sobrescrever aulas?'),
                      content: Text(
                        'Os seguintes horários já possuem aulas:\n\n${conflitos.join('\n')}\n\nDeseja sobrescrever?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Sobrescrever'),
                        ),
                      ],
                    ),
                  );

                  if (confirmar != true) return;
                }

                // Adiciona todas as aulas
                horariosRecorrentes.forEach((dia, horarios) {
                  for (var horario in horarios) {
                    final aula = Aula(
                      materia: materiaController.text.trim(),
                      professor: professorController.text.trim(),
                      diaSemana: dia,
                      horario: horario,
                      cor: corSelecionada,
                    );
                    ClassesData.adicionarAula(aula);
                  }
                });

                await ClassesData.salvarAulas();
                setState(() {});
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$totalSelecionados aula(s) adicionada(s)!')),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para selecionar cor
  Widget _buildCorOption(Color? cor, Color? corAtual, StateSetter setState, Function(Color?) onSelect) {
    final selecionada = (cor == null && corAtual == null) || (cor != null && cor == corAtual);
    
    return GestureDetector(
      onTap: () => setState(() => onSelect(cor)),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cor ?? Colors.white,
          border: Border.all(
            color: selecionada ? Colors.deepPurple : Colors.grey[300]!,
            width: selecionada ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: cor == null
            ? const Center(
                child: Icon(Icons.close, size: 20, color: Colors.grey),
              )
            : null,
      ),
    );
  }

  // Remover aula específica
  void _removerAula(String dia, String horario) async {
    final aula = ClassesData.buscarAula(dia, horario);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover aula?'),
        content: Text(
          aula != null 
            ? 'Deseja remover a aula de ${aula.materia} ($dia às $horario)?'
            : 'Deseja remover a aula de $dia às $horario?'
        ),
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
        ClassesData.removerAula(dia, horario);
      });
      await ClassesData.salvarAulas();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aula removida')),
      );
    }
  }

  // Limpar toda a grade
  void _limparGrade() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar grade completa?'),
        content: const Text('Esta ação irá remover TODAS as aulas cadastradas. Não é possível desfazer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar tudo'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() {
        ClassesData.limparTodasAulas();
      });
      await ClassesData.salvarAulas();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grade limpa')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final diaAtual = _obterDiaAtual();
    final diasParaMostrar = AppData.visualizacaoSemanal 
        ? ClassesData.diasSemana 
        : (diaAtual != null ? [diaAtual] : ClassesData.diasSemana);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Horários'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          // NOVO: Lista de aulas
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _mostrarListaAulas,
            tooltip: 'Ver todas as aulas',
          ),
          // Toggle visualização
          IconButton(
            icon: Icon(AppData.visualizacaoSemanal ? Icons.view_day : Icons.view_week),
            onPressed: _alternarVisualizacao,
            tooltip: AppData.visualizacaoSemanal ? 'Ver só hoje' : 'Ver semana',
          ),
          // Limpar grade
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _limparGrade,
            tooltip: 'Limpar grade',
          ),
        ],
      ),
      // ALTERADO: Condicional para vista de um dia ocupar tela toda
      body: AppData.visualizacaoSemanal 
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: _buildDataTable(diasParaMostrar),
            ),
          )
        : SingleChildScrollView(
            child: _buildDataTable(diasParaMostrar),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarNovaAula,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // NOVO: Método separado para construir a tabela
  Widget _buildDataTable(List<String> diasParaMostrar) {
    // Para vista de um dia, usar Table em vez de DataTable
    if (!AppData.visualizacaoSemanal && diasParaMostrar.length == 1) {
      return _buildTabelaDiaUnico(diasParaMostrar.first);
    }
    
    return DataTable(
      headingRowColor: MaterialStateProperty.all(Colors.deepPurple[50]),
      border: TableBorder.all(color: Colors.grey[300]!),
      columnSpacing: 20,
      dataRowHeight: 60,
      columns: [
        const DataColumn(label: Text('Horário', style: TextStyle(fontWeight: FontWeight.bold))),
        ...diasParaMostrar.map((dia) => DataColumn(
          label: Text(
            _abreviarDia(dia),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        )),
      ],
      rows: ClassesData.horarios.map((horario) {
        if (horario == 'INTERVALO') {
          return DataRow(
            color: MaterialStateProperty.all(Colors.grey[200]),
            cells: [
              const DataCell(Text('INTERVALO', style: TextStyle(fontStyle: FontStyle.italic))),
              ...diasParaMostrar.map((dia) => const DataCell(Text('-'))),
            ],
          );
        }

        return DataRow(
          cells: [
            DataCell(Text(horario, style: const TextStyle(fontWeight: FontWeight.bold))),
            ...diasParaMostrar.map((dia) {
              final aula = ClassesData.buscarAula(dia, horario);
              
              if (aula != null) {
                return DataCell(
                  GestureDetector(
                    onLongPress: () => _removerAula(dia, horario),
                    onTap: () => _editarAula(aula),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      constraints: BoxConstraints(
                        minWidth: AppData.visualizacaoSemanal ? 80 : double.infinity,
                      ),
                      decoration: BoxDecoration(
                        color: aula.cor ?? Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            aula.materia,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (aula.professor.isNotEmpty)
                            Text(
                              aula.professor,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return const DataCell(Text('-'));
            }),
          ],
        );
      }).toList(),
    );
  }

  String? _obterDiaAtual() {
    final weekday = DateTime.now().weekday;
    switch (weekday) {
      case 1: return 'Segunda';
      case 2: return 'Terça';
      case 3: return 'Quarta';
      case 4: return 'Quinta';
      case 5: return 'Sexta';
      default: return null;
    }
  }

  String _abreviarDia(String dia) {
    return dia.substring(0, 3);
  }

  // NOVO: Tabela otimizada para vista de um único dia
  Widget _buildTabelaDiaUnico(String dia) {
    return Table(
      border: TableBorder.all(color: Colors.grey[300]!),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
      },
      children: [
        // Cabeçalho
        TableRow(
          decoration: BoxDecoration(color: Colors.deepPurple[50]),
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Horário',
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                dia,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        // Linhas de horários
        ...ClassesData.horarios.map((horario) {
          if (horario == 'INTERVALO') {
            return TableRow(
              decoration: BoxDecoration(color: Colors.grey[200]),
              children: [
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'INTERVALO',
                    style: TextStyle(fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text('-', textAlign: TextAlign.center),
                ),
              ],
            );
          }

          final aula = ClassesData.buscarAula(dia, horario);

          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  horario,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: aula != null
                    ? GestureDetector(
                        onLongPress: () => _removerAula(dia, horario),
                        onTap: () => _editarAula(aula),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: aula.cor ?? Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: aula.cor != null 
                                  ? (aula.cor!).withOpacity(0.5)
                                  : Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                aula.materia,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (aula.professor.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  aula.professor,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : const Text('-', textAlign: TextAlign.center),
              ),
            ],
          );
        }),
      ],
    );
  }
}