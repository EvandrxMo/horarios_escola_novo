import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../models/notes_model.dart';

class NotasData {
  // Lista de todas as notas
  static List<Nota> notas = [];

  // Adicionar nota
  static void adicionarNota(Nota nota) {
    notas.add(nota);
  }

  // Remover nota
  static void removerNota(String id) {
    notas.removeWhere((nota) => nota.id == id);
  }

  // Buscar notas de uma matéria específica
  static List<Nota> obterNotasPorMateria(String materia) {
    return notas.where((nota) => nota.materia == materia).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Mais recentes primeiro
  }

  // Obter lista de matérias que têm notas
  static List<String> obterMateriasComNotas() {
    final materias = <String>{};
    for (var nota in notas) {
      materias.add(nota.materia);
    }
    return materias.toList()..sort();
  }

  // Remover todas as notas de uma matéria
  static Future<void> removerNotasDaMateria(String materia) async {
    // Remove as fotos do dispositivo
    final notasDaMateria = obterNotasPorMateria(materia);
    for (var nota in notasDaMateria) {
      try {
        final file = File(nota.caminhoImagem);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Erro ao deletar foto: $e');
      }
    }

    // Remove do array
    notas.removeWhere((nota) => nota.materia == materia);
    await salvarNotas();
  }

  // Atualizar legenda de uma nota
  static Future<void> atualizarLegenda(String id, String novaLegenda) async {
    final nota = notas.firstWhere((n) => n.id == id);
    nota.legenda = novaLegenda;
    await salvarNotas();
  }

  // Salvar notas no SharedPreferences
  static Future<void> salvarNotas() async {
    final prefs = await SharedPreferences.getInstance();
    final notasJson = jsonEncode(
      notas.map((nota) => nota.toJson()).toList(),
    );
    await prefs.setString('notas', notasJson);
  }

  // Carregar notas do SharedPreferences
  static Future<void> carregarNotas() async {
    final prefs = await SharedPreferences.getInstance();
    final notasJson = prefs.getString('notas');

    if (notasJson != null && notasJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(notasJson);
        notas.clear();
        for (var item in decoded) {
          final nota = Nota.fromJson(item);
          
          // Verifica se a foto ainda existe no dispositivo
          final file = File(nota.caminhoImagem);
          if (await file.exists()) {
            notas.add(nota);
          }
        }
      } catch (e) {
        print('Erro ao carregar notas: $e');
        notas.clear();
      }
    }
  }

  // Contar quantas notas tem uma matéria
  static int contarNotasPorMateria(String materia) {
    return notas.where((nota) => nota.materia == materia).length;
  }
}