import 'package:flutter/material.dart';
import '../models/aula_model.dart';

class ModernScheduleCard extends StatelessWidget {
  final Aula aula;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ModernScheduleCard({
    super.key,
    required this.aula,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 97,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: _buildGradient(),
              boxShadow: [
                BoxShadow(
                  color: (aula.cor ?? Colors.deepPurple).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Indicador de horário
                  Container(
                    width: 4,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Conteúdo principal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Horário
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            aula.horario,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 6),
                        
                        // Matéria e Professor
                        Text(
                          aula.materia,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 2),
                        
                        Text(
                          aula.professor,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Ícone da matéria
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getSubjectIcon(aula.materia),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient _buildGradient() {
    final baseColor = aula.cor ?? Colors.deepPurple;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor,
        _darkenColor(baseColor, 0.3),
      ],
      stops: const [0.0, 1.0],
    );
  }

  Color _darkenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  IconData _getSubjectIcon(String materia) {
    final materiaLower = materia.toLowerCase();
    
    if (materiaLower.contains('mat') || materiaLower.contains('cálculo')) {
      return Icons.calculate;
    } else if (materiaLower.contains('port') || materiaLower.contains('redação')) {
      return Icons.menu_book;
    } else if (materiaLower.contains('hist')) {
      return Icons.history_edu;
    } else if (materiaLower.contains('geo')) {
      return Icons.public;
    } else if (materiaLower.contains('bio')) {
      return Icons.biotech;
    } else if (materiaLower.contains('quím') || materiaLower.contains('qui')) {
      return Icons.science;
    } else if (materiaLower.contains('fís')) {
      return Icons.bolt;
    } else if (materiaLower.contains('ing') || materiaLower.contains('ingl')) {
      return Icons.language;
    } else if (materiaLower.contains('ed') || materiaLower.contains('edu')) {
      return Icons.sports_soccer;
    } else if (materiaLower.contains('art')) {
      return Icons.palette;
    } else if (materiaLower.contains('mús') || materiaLower.contains('mus')) {
      return Icons.music_note;
    } else {
      return Icons.school;
    }
  }
}

class ModernScheduleHeader extends StatelessWidget {
  final String diaSemana;
  final int totalAulas;

  const ModernScheduleHeader({
    super.key,
    required this.diaSemana,
    required this.totalAulas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade400,
            Colors.deepPurple.shade600,
          ],
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
          Icon(
            Icons.calendar_today,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  diaSemana,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$totalAulas aulas',
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
              totalAulas.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
