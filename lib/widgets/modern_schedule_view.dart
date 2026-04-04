import 'package:flutter/material.dart';
import '../models/aula_model.dart';
import '../preferences/classesData.dart';
import 'modern_schedule_card.dart';

class ModernScheduleView extends StatefulWidget {
  const ModernScheduleView({super.key});

  @override
  State<ModernScheduleView> createState() => _ModernScheduleViewState();
}

class _ModernScheduleViewState extends State<ModernScheduleView> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _diasSemana = [
    'Segunda', 'Terça', 'Quarta', 
    'Quinta', 'Sexta', 'Sábado', 'Domingo'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Header com tabs
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Colors.deepPurple,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 12,
              ),
              tabs: _diasSemana.map((dia) => Tab(text: dia.substring(0, 3))).toList(),
            ),
          ),
          
          // Conteúdo das tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _diasSemana.asMap().entries.map((entry) {
                final index = entry.key;
                final dia = entry.value;
                return _buildDaySchedule(dia, index);
              }).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAulaDialog,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar Aula'),
      ),
    );
  }

  Widget _buildDaySchedule(String dia, int diaIndex) {
    final aulasDoDia = ClassesData.obterAulasDoDia(dia);
    
    if (aulasDoDia.isEmpty) {
      return _buildEmptyDay(dia);
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ModernScheduleHeader(
            diaSemana: dia,
            totalAulas: aulasDoDia.length,
          ),
          
          // Lista de aulas do dia
          ...aulasDoDia.map((aula) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ModernScheduleCard(
              aula: aula,
              onTap: () => _editAula(aula),
              onLongPress: () => _showAulaOptions(aula),
            ),
          )),

          // Botão para adicionar aula neste dia
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddAulaDialogForDay(dia),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Aula'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
          ),
          
          const SizedBox(height: 100), // Espaço para o FAB
        ],
      ),
    );
  }

  Widget _buildEmptyDay(String dia) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma aula para $dia',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no botão abaixo para adicionar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddAulaDialogForDay(dia),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Primeira Aula'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAulaDialog() {
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

                if (horariosRecorrentes.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Selecione pelo menos um horário')),
                  );
                  return;
                }

                // Adiciona a aula para todos os horários selecionados
                for (var dia in horariosRecorrentes.keys) {
                  for (var horario in horariosRecorrentes[dia]!) {
                    final aula = Aula(
                      materia: materiaController.text.trim(),
                      professor: professorController.text.trim(),
                      diaSemana: dia,
                      horario: horario,
                      cor: corSelecionada,
                    );
                    ClassesData.adicionarAula(aula);
                  }
                }

                await ClassesData.salvarAulas();
                Navigator.pop(context);
                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Aula "${materiaController.text}" adicionada com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAulaDialogForDay(String diaFoco) {
    final materiaController = TextEditingController();
    final professorController = TextEditingController();
    Color? corSelecionada;
    final horariosRecorrentes = <String>{};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Adicionar Aula para $diaFoco'),
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

                // Seleção de horários APENAS para este dia
                const Text('Selecione os horários:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Column(
                  children: ClassesData.horarios
                      .where((h) => h != 'INTERVALO')
                      .map((horario) {
                    final jaTemAula = ClassesData.existeAula(diaFoco, horario);
                    final estaSelecionado = horariosRecorrentes.contains(horario);

                    return CheckboxListTile(
                      title: Text(horario),
                      subtitle: jaTemAula ? const Text('Já possui aula', style: TextStyle(color: Colors.orange, fontSize: 11)) : null,
                      value: estaSelecionado,
                      dense: true,
                      onChanged: (valor) {
                        setDialogState(() {
                          if (valor == true) {
                            horariosRecorrentes.add(horario);
                          } else {
                            horariosRecorrentes.remove(horario);
                          }
                        });
                      },
                    );
                  }).toList(),
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

                if (horariosRecorrentes.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Selecione pelo menos um horário')),
                  );
                  return;
                }

                // Adiciona a aula para os horários selecionados neste dia
                for (var horario in horariosRecorrentes) {
                  final aula = Aula(
                    materia: materiaController.text.trim(),
                    professor: professorController.text.trim(),
                    diaSemana: diaFoco,
                    horario: horario,
                    cor: corSelecionada,
                  );
                  ClassesData.adicionarAula(aula);
                }

                await ClassesData.salvarAulas();
                Navigator.pop(context);
                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Aula "${materiaController.text}" adicionada com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _editAula(Aula aulaOriginal) {
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

                final novaAula = Aula(
                  materia: materiaController.text.trim(),
                  professor: professorController.text.trim(),
                  diaSemana: aulaOriginal.diaSemana,
                  horario: aulaOriginal.horario,
                  cor: corSelecionada,
                );

                ClassesData.removerAula(aulaOriginal.diaSemana, aulaOriginal.horario);
                ClassesData.adicionarAula(novaAula);
                await ClassesData.salvarAulas();

                Navigator.pop(context);
                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Aula "${materiaController.text}" atualizada!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorOption(
    Color? cor,
    Color? corSelecionada,
    StateSetter setDialogState,
    Function(Color?) onSelect,
  ) {
    final isSelected = cor == corSelecionada;
    
    if (cor == null) {
      return InkWell(
        onTap: () {
          setDialogState(() => onSelect(null));
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
              width: isSelected ? 3 : 1,
            ),
          ),
          child: Center(
            child: Text(
              '∅',
              style: TextStyle(
                color: isSelected ? Colors.deepPurple : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () {
        setDialogState(() => onSelect(cor));
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cor,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: isSelected ? 3 : 0,
          ),
        ),
      ),
    );
  }

  void _showAulaOptions(Aula aula) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    aula.materia,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${aula.horario} • ${aula.professor}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildOptionButton(
                        icon: Icons.edit,
                        label: 'Editar',
                        color: Colors.blue,
                        onTap: () {
                          Navigator.pop(context);
                          _editAula(aula);
                        },
                      ),
                      _buildOptionButton(
                        icon: Icons.share,
                        label: 'Compartilhar',
                        color: Colors.green,
                        onTap: () {
                          Navigator.pop(context);
                          _shareAula(aula);
                        },
                      ),
                      _buildOptionButton(
                        icon: Icons.delete,
                        label: 'Remover',
                        color: Colors.red,
                        onTap: () {
                          Navigator.pop(context);
                          _confirmRemoveAula(aula);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  void _shareAula(Aula aula) {
    // TODO: Implementar compartilhamento
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Compartilhando: ${aula.materia}')),
    );
  }

  void _confirmRemoveAula(Aula aula) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover aula?'),
        content: Text('Deseja remover a aula "${aula.materia}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ClassesData.removerAula(aula.diaSemana, aula.horario);
              ClassesData.salvarAulas();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Aula removida')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}
