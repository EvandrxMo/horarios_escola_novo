import 'package:flutter/material.dart';
import '../preferences/classesData.dart';
import '../preferences/appData.dart';
import '../widgets/modern_schedule_view.dart';

class ClassesModernPage extends StatefulWidget {
  const ClassesModernPage({super.key});

  @override
  State<ClassesModernPage> createState() => _ClassesModernPageState();
}

class _ClassesModernPageState extends State<ClassesModernPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aulas'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          // Botão para alternar visualização
          IconButton(
            icon: Icon(
              AppData.visualizacaoSemanal ? Icons.view_day : Icons.view_week,
            ),
            onPressed: _alternarVisualizacao,
            tooltip: AppData.visualizacaoSemanal 
                ? 'Ver por dia' 
                : 'Ver semana',
          ),
        ],
      ),
      body: AppData.visualizacaoSemanal 
          ? _buildVisualizacaoSemanal()
          : const ModernScheduleView(),
    );
  }

  Widget _buildVisualizacaoSemanal() {
    return Container(
      color: Colors.grey.shade50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header informativo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Grade Semanal',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Todas as aulas da semana',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ClassesData.aulas.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Tabela semanal
            _buildTabelaSemanal(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabelaSemanal() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Cabeçalho da tabela
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                // Célula vazia para alinhamento
                Container(
                  width: 80,
                  height: 40,
                ),
                ...ClassesData.horarios.map((horario) => Expanded(
                  child: Center(
                    child: Text(
                      horario,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )),
              ],
            ),
          ),
          
          // Linhas da tabela
          ...ClassesData.diasSemana.map((dia) => _buildLinhaDia(dia)),
        ],
      ),
    );
  }

  Widget _buildLinhaDia(String dia) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Célula do dia
          Container(
            width: 80,
            height: 50,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _abreviarDia(dia),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_contarAulasDoDia(dia)} aulas',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Células das aulas
          ...ClassesData.horarios.map((horario) => Expanded(
            child: _buildCelulaAula(dia, horario),
          )),
        ],
      ),
    );
  }

  Widget _buildCelulaAula(String dia, String horario) {
    final aula = ClassesData.buscarAula(dia, horario);
    
    if (aula == null) {
      return Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
        ),
      );
    }
    
    return Container(
      height: 50,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: aula.cor,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: (aula.cor ?? Colors.white).withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _editarAula(aula),
        onLongPress: () => _mostrarOpcoesAula(aula),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                aula.materia,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: _getContrastColor(aula.cor ?? Colors.white),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                aula.professor,
                style: TextStyle(
                  fontSize: 8,
                  color: _getContrastColor(aula.cor ?? Colors.white).withOpacity(0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _abreviarDia(String dia) {
    switch (dia) {
      case 'Segunda': return 'SEG';
      case 'Terça': return 'TER';
      case 'Quarta': return 'QUA';
      case 'Quinta': return 'QUI';
      case 'Sexta': return 'SEX';
      default: return dia.substring(0, 3).toUpperCase();
    }
  }

  int _contarAulasDoDia(String dia) {
    return ClassesData.aulas.entries
        .where((entry) => entry.key.startsWith('$dia-'))
        .length;
  }

  Color _getContrastColor(Color cor) {
    // Calcula luminosidade para decidir se usa texto claro ou escuro
    final luminosity = (0.299 * cor.red + 0.587 * cor.green + 0.114 * cor.blue) / 255;
    return luminosity > 0.5 ? Colors.black : Colors.white;
  }

  void _editarAula(aula) {
    // TODO: Implementar edição de aula
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editando: ${aula.materia}')),
    );
  }

  void _mostrarOpcoesAula(aula) {
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
                    '${aula.diaSemana} • ${aula.horario}',
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
                          _editarAula(aula);
                        },
                      ),
                      _buildOptionButton(
                        icon: Icons.share,
                        label: 'Compartilhar',
                        color: Colors.green,
                        onTap: () {
                          Navigator.pop(context);
                          _compartilharAula(aula);
                        },
                      ),
                      _buildOptionButton(
                        icon: Icons.delete,
                        label: 'Remover',
                        color: Colors.red,
                        onTap: () {
                          Navigator.pop(context);
                          _confirmarRemocaoAula(aula);
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

  void _compartilharAula(aula) {
    // TODO: Implementar compartilhamento
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Compartilhando: ${aula.materia}')),
    );
  }

  void _confirmarRemocaoAula(aula) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover aula?'),
        content: Text('Deseja remover a aula "${aula.materia}" (${aula.diaSemana} às ${aula.horario})?'),
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
