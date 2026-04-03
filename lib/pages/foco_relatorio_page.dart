import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../preferences/focoData.dart';
import '../services/notificationsService.dart';

class FocoRelatorioPage extends StatefulWidget {
  const FocoRelatorioPage({super.key});

  @override
  State<FocoRelatorioPage> createState() => _FocoRelatorioPageState();
}

class _FocoRelatorioPageState extends State<FocoRelatorioPage> {
  List<int> _loadDiarioDosUltimosDias(int dias) {
    final hoje = DateTime.now();
    final result = <int>[];

    for (int i = 0; i < dias; i++) {
      final dia = hoje.subtract(Duration(days: i));
      final totalMinutos = FocoData.getSessoesDoDia(dia)
          .where((s) => s.concluida)
          .fold<int>(0, (sum, s) => sum + s.duracaoMinutos);
      result.add(totalMinutos);
    }

    return result.reversed.toList();
  }

  Map<String, int> _loadPorMateriaSemana() {
    final sessoes = FocoData.getSessoesDaSemana(DateTime.now())
        .where((s) => s.concluida)
        .toList();

    final Map<String, int> mapa = {};
    for (var sessao in sessoes) {
      final materia = sessao.materia ?? 'Sem Matéria';
      mapa[materia] = (mapa[materia] ?? 0) + sessao.duracaoMinutos;
    }
    return mapa;
  }

  double _calcularMediaDiaria(int dias) {
    final diario = _loadDiarioDosUltimosDias(dias);
    if (diario.isEmpty) return 0.0;
    final soma = diario.reduce((a, b) => a + b);
    return soma / dias;
  }

  double _calcularMediaSessaoSemana() {
    final sessoes = FocoData.getSessoesDaSemana(DateTime.now())
        .where((s) => s.concluida)
        .toList();
    if (sessoes.isEmpty) return 0.0;
    final soma = sessoes.fold<int>(0, (sum, s) => sum + s.duracaoMinutos);
    return soma / sessoes.length;
  }

  Future<List<File>> _loadRelatoriosGerados() async {
    final dir = await getApplicationDocumentsDirectory();
    final arquivos = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.pdf'))
        .toList();

    arquivos.sort((a, b) => b.path.compareTo(a.path));
    return arquivos;
  }

  Widget _buildLegendaPorMateria(Map<String, int> porMateria) {
    final colors = [
      Colors.deepPurple,
      Colors.green,
      Colors.orange,
      Colors.blue,
      Colors.red,
      Colors.teal,
      Colors.brown,
      Colors.pink,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: porMateria.entries.toList().asMap().entries.map((entry) {
        final index = entry.key;
        final materia = entry.value.key;
        final tempo = entry.value.value;
        return Chip(
          avatar: CircleAvatar(backgroundColor: colors[index % colors.length]),
          label: Text('$materia: ${_formatMinutos(tempo)}'),
        );
      }).toList(),
    );
  }

  String _formatMinutos(int minutos) {
    final h = minutos ~/ 60;
    final m = minutos % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  Widget _buildDailyBarChart(List<int> diarios) {
    if (diarios.isEmpty) {
      return const Center(child: Text('Sem dados de estudos nos últimos 7 dias'));
    }

    final maxValue = (diarios.reduce((a, b) => a > b ? a : b) + 10).clamp(10, 9999);
    final barGroups = diarios.asMap().entries.map((entry) {
      final index = entry.key;
      final value = entry.value.toDouble();
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(toY: value, color: Colors.deepPurpleAccent, width: 16, borderRadius: BorderRadius.circular(4))
        ],
      );
    }).toList();

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxValue.toDouble(),
          barGroups: barGroups,
          alignment: BarChartAlignment.spaceBetween,
          gridData: FlGridData(show: true, horizontalInterval: maxValue / 5),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, meta) {
                  final dia = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text('${dia.day}/${dia.month}', style: TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 30),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
        ),
      ),
    );
  }

  Widget _buildMateriaPieChart(Map<String, int> porMateria) {
    if (porMateria.isEmpty) {
      return const Center(child: Text('Sem sessões concluídas para matéria nesta semana.'));
    }

    final cores = [
      Colors.deepPurple,
      Colors.green,
      Colors.orange,
      Colors.blue,
      Colors.red,
      Colors.teal,
      Colors.brown,
      Colors.pink,
    ];

    final total = porMateria.values.fold<int>(0, (s, v) => s + v);

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 36,
          sections: porMateria.entries.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final min = entry.value.value;
            final percent = total > 0 ? (min / total * 100) : 0;
            return PieChartSectionData(
              color: cores[index % cores.length],
              value: min.toDouble(),
              title: '${percent.toStringAsFixed(0)}%',
              radius: 60,
              titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, List<int> diarios, Map<String, int> porMateria, double mediaDiaria, double mediaSessao, int totalSemana) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Relatório de Estudo', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.Text('Total semanal: ${_formatMinutos(totalSemana)}', style: pw.TextStyle(fontSize: 16)),
            pw.Text('Média diária (7 dias): ${mediaDiaria.toStringAsFixed(2)} min', style: pw.TextStyle(fontSize: 16)),
            pw.Text('Média por sessão (semana atual): ${mediaSessao.toStringAsFixed(2)} min', style: pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 12),
            pw.Text('Dados últimos 7 dias:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Table.fromTextArray(
              headers: ['Dia', 'Tempo'],
              data: List.generate(diarios.length, (index) {
                final dia = DateTime.now().subtract(Duration(days: 6 - index));
                return ['${dia.day}/${dia.month}', _formatMinutos(diarios[index])];
              }),
            ),
            pw.SizedBox(height: 12),
            pw.Text('Por matéria (semana atual):', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Table.fromTextArray(
              headers: ['Matéria', 'Tempo'],
              data: porMateria.entries.map((e) => [e.key, _formatMinutos(e.value)]).toList(),
            ),
          ],
        ),
      ),
    );

    final pdfData = await doc.save();

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final nomeArquivo = 'relatorio_estudo_$timestamp.pdf';
    final caminhoArquivo = '${dir.path}/$nomeArquivo';
    final arquivo = File(caminhoArquivo);

    await arquivo.writeAsBytes(pdfData);

    // Mostra a opção de impressão/salvamento e também notifica
    await Printing.layoutPdf(onLayout: (format) async => pdfData);

    await NotificacoesService.mostrarNotificacaoDownload(caminhoArquivo);

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF gerado em $nomeArquivo. Notificação enviada.'),
        action: SnackBarAction(
          label: 'Abrir',
          onPressed: () async {
            await OpenFile.open(caminhoArquivo);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final diarios = _loadDiarioDosUltimosDias(7);
    final porMateria = _loadPorMateriaSemana();
    final mediaDiaria = _calcularMediaDiaria(7);
    final mediaSessao = _calcularMediaSessaoSemana();
    final totalSemana = diarios.fold<int>(0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        title: Text('Relatório de Estudo'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Relatório de Estudo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => _exportPdf(context, diarios, porMateria, mediaDiaria, mediaSessao, totalSemana),
                  icon: Icon(Icons.picture_as_pdf),
                  label: Text('Exportar PDF'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Carga horária diária (últimos 7 dias)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildDailyBarChart(diarios),
            const SizedBox(height: 16),
            Text('Resumo geral', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Carga semanal total: ${_formatMinutos(totalSemana)}'),
                    SizedBox(height: 4),
                    Text('Média diária (7 dias): ${(mediaDiaria / 60).toStringAsFixed(1)}h'),
                    SizedBox(height: 4),
                    Text('Média por sessão (semana atual): ${mediaSessao.toStringAsFixed(1)} min'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Distribuição por matéria (semana atual)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildMateriaPieChart(porMateria),
            const SizedBox(height: 12),
            _buildLegendaPorMateria(porMateria),
            const SizedBox(height: 16),
            if (porMateria.isEmpty)
              const Text('Nenhuma sessão concluída nesta semana ainda.'),
            ...porMateria.entries
                .toList()
                .map((e) => ListTile(
                      title: Text(e.key),
                      trailing: Text(_formatMinutos(e.value)),
                    ))
                .toList(),
            const SizedBox(height: 20),
            Text('Relatórios gerados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<List<File>>(
              future: _loadRelatoriosGerados(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final arquivos = snapshot.data ?? [];
                if (arquivos.isEmpty) {
                  return const Text('Nenhum relatório PDF gerado ainda.');
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: arquivos.length,
                  itemBuilder: (context, index) {
                    final arquivo = arquivos[index];
                    final nome = arquivo.path.split('/').last;
                    return ListTile(
                      leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                      title: Text(nome),
                      subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(arquivo.lastModifiedSync())),
                      trailing: IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () => OpenFile.open(arquivo.path),
                      ),
                      onTap: () => OpenFile.open(arquivo.path),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            Text('Observações', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Alvo: manter média diária de estudo alinhada à meta. Evitar picos > 6h em um dia.'),
          ],
        ),
      ),
    );
  }
}
