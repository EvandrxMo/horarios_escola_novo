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
            'Toque no + para adicionar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAulaDialog() {
    // TODO: Implementar diálogo de adicionar aula
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
    );
  }

  void _editAula(Aula aula) {
    // TODO: Implementar edição de aula
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editando: ${aula.materia}')),
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
