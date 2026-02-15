import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/mood_model.dart';
import '../preferences/moodData.dart';
import 'package:intl/intl.dart';

class MoodTrackerPage extends StatefulWidget {
  const MoodTrackerPage({super.key});

  @override
  State<MoodTrackerPage> createState() => _MoodTrackerPageState();
}

class _MoodTrackerPageState extends State<MoodTrackerPage> {
  String _periodoSelecionado = 'Semana'; // Semana, Mês, Ano

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    await MoodData.carregarMoods();
    setState(() {});
  }

  List<MoodRegistro> _getRegistrosPeriodo() {
    switch (_periodoSelecionado) {
      case 'Semana':
        return MoodData.getRegistrosSemana();
      case 'Mês':
        return MoodData.getRegistrosMes();
      case 'Ano':
        return MoodData.getRegistrosAno();
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final registros = _getRegistrosPeriodo();
    final media = MoodData.calcularMedia(registros);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rastreador de Humor'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seletor de período
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildPeriodoButton('Semana'),
                  _buildPeriodoButton('Mês'),
                  _buildPeriodoButton('Ano'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Card de estatísticas
            if (registros.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Registros',
                      registros.length.toString(),
                      Icons.calendar_today,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCardWithImage(
                      'Média',
                      media ?? 0,
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Gráfico de linha
              const Text(
                'Evolução do humor',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 250,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: _buildGrafico(registros),
              ),
              const SizedBox(height: 24),

              // Distribuição de humor
              const Text(
                'Distribuição de humor',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDistribuicao(registros),
              const SizedBox(height: 24),

              // Histórico
              const Text(
                'Histórico',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildHistorico(registros),
            ] else
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Icon(
                      Icons.mood_bad,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum registro neste período',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodoButton(String periodo) {
    final isSelected = _periodoSelecionado == periodo;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _periodoSelecionado = periodo;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            periodo,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color cor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: cor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardWithImage(String label, double media, IconData icon, Color cor) {
    final mood = media > 0 && media <= 6 ? Mood.moods[media.round() - 1] : null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: cor, size: 28),
          const SizedBox(height: 8),
          if (mood != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                mood.imagePath,
                width: 40,
                height: 40,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Text(
                    mood.emoji,
                    style: const TextStyle(fontSize: 32),
                  );
                },
              ),
            )
          else
            const Text(
              '—',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
      ),
    );
  }

  Widget _buildGrafico(List<MoodRegistro> registros) {
    if (registros.isEmpty) {
      return const Center(child: Text('Sem dados'));
    }

    // Ordena os registros por data crescente para o gráfico
    final registrosOrdenados = List<MoodRegistro>.from(registros)
      ..sort((a, b) => a.data.compareTo(b.data));

    final spots = registrosOrdenados.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.mood.valor.toDouble(),
      );
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                if (value < 1 || value > 6) return const SizedBox.shrink();
                final mood = Mood.moods[value.toInt() - 1];
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      mood.imagePath,
                      width: 30,
                      height: 30,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          mood.emoji,
                          style: const TextStyle(fontSize: 16),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= registrosOrdenados.length) {
                  return const Text('');
                }
                final data = registrosOrdenados[index].data;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('dd/MM').format(data),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 7,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.deepPurple,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final mood = registrosOrdenados[index].mood;
                return FlDotCirclePainter(
                  radius: 6,
                  color: mood.cor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.deepPurple.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistribuicao(List<MoodRegistro> registros) {
    final distribuicao = <int, int>{};
    
    for (var registro in registros) {
      distribuicao[registro.mood.valor] = 
          (distribuicao[registro.mood.valor] ?? 0) + 1;
    }

    return Column(
      children: Mood.moods.map((mood) {
        final count = distribuicao[mood.valor] ?? 0;
        final percentage = registros.isEmpty ? 0.0 : (count / registros.length);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  mood.imagePath,
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Text(
                      mood.emoji,
                      style: const TextStyle(fontSize: 24),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          mood.nome,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$count (${(percentage * 100).toStringAsFixed(0)}%)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(mood.cor),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistorico(List<MoodRegistro> registros) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: registros.length,
      itemBuilder: (context, index) {
        final registro = registros[index];
        final mood = registro.mood;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: mood.cor.withOpacity(0.3)),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: mood.cor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  mood.imagePath,
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Text(
                      mood.emoji,
                      style: const TextStyle(fontSize: 24),
                    );
                  },
                ),
              ),
            ),
            title: Text(
              mood.nome,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              DateFormat('dd/MM/yyyy - EEEE', 'pt_BR').format(registro.data),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Icon(
              Icons.circle,
              color: mood.cor,
              size: 12,
            ),
          ),
        );
      },
    );
  }
}