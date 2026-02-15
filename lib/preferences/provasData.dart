import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/prova_model.dart';

class ProvasData {
  // Lista de todas as provas
  static List<Prova> provas = [];

  // Adicionar ou atualizar prova
  static void adicionarProva(Prova prova) {
    // Remove prova existente com a mesma chave
    provas.removeWhere((p) => p.chave == prova.chave);
    // Adiciona a nova prova
    provas.add(prova);
    // Ordena por data
    provas.sort((a, b) => a.data.compareTo(b.data));
  }

  // Remover prova específica
  static void removerProva(String chave) {
    provas.removeWhere((p) => p.chave == chave);
  }

  // Limpar todas as provas
  static void limparTodasProvas() {
    provas.clear();
  }

  // Buscar provas por data
  static List<Prova> buscarProvasPorData(DateTime data) {
    return provas.where((prova) {
      return prova.data.year == data.year &&
          prova.data.month == data.month &&
          prova.data.day == data.day;
    }).toList();
  }

  // Verificar se existe prova na data
  static bool existeProvaNaData(DateTime data) {
    return provas.any((prova) {
      return prova.data.year == data.year &&
          prova.data.month == data.month &&
          prova.data.day == data.day;
    });
  }

  // Obter próxima prova
  static Prova? obterProximaProva() {
    final agora = DateTime.now();
    
    // Remove a parte de hora/minuto/segundo para comparação de data
    final hoje = DateTime(agora.year, agora.month, agora.day);
    
    // Filtra provas futuras ou de hoje
    final provasFuturas = provas.where((prova) {
      final dataProva = DateTime(prova.data.year, prova.data.month, prova.data.day);
      return dataProva.isAtSameMomentAs(hoje) || dataProva.isAfter(hoje);
    }).toList();

    if (provasFuturas.isEmpty) return null;

    // Ordena por data e retorna a primeira
    provasFuturas.sort((a, b) => a.data.compareTo(b.data));
    return provasFuturas.first;
  }

  // Salvar provas no SharedPreferences
  static Future<void> salvarProvas() async {
    final prefs = await SharedPreferences.getInstance();
    final provasJson = jsonEncode(
      provas.map((prova) => prova.toJson()).toList(),
    );
    await prefs.setString('provas', provasJson);
  }

  // Carregar provas do SharedPreferences
  static Future<void> carregarProvas() async {
    final prefs = await SharedPreferences.getInstance();
    final provasJson = prefs.getString('provas');

    if (provasJson != null && provasJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(provasJson);
        provas.clear();
        for (var item in decoded) {
          final prova = Prova.fromJson(item);
          provas.add(prova);
        }
        // Ordena por data
        provas.sort((a, b) => a.data.compareTo(b.data));
      } catch (e) {
        print('Erro ao carregar provas: $e');
        provas.clear();
      }
    }
  }

  // Obter todas as datas com provas (para marcar no calendário)
  static Set<DateTime> obterDatasComProvas() {
    return provas.map((prova) {
      return DateTime(prova.data.year, prova.data.month, prova.data.day);
    }).toSet();
  }
}