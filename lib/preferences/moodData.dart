import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mood_model.dart';

class MoodData {
  static const String _keyMoods = 'moods';
  static const String _keyUltimaAbertura = 'ultima_abertura';
  
  static List<MoodRegistro> _registros = [];

  static List<MoodRegistro> get registros => _registros;

  // Verifica se é a primeira abertura do dia
  static Future<bool> isPrimeiraAberturaDoDia() async {
    final prefs = await SharedPreferences.getInstance();
    final ultimaAberturaStr = prefs.getString(_keyUltimaAbertura);
    
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
    
    if (ultimaAberturaStr == null) {
      return true;
    }
    
    final ultimaAbertura = DateTime.parse(ultimaAberturaStr);
    final ultimaSemHora = DateTime(
      ultimaAbertura.year,
      ultimaAbertura.month,
      ultimaAbertura.day,
    );
    
    return hojeSemHora.isAfter(ultimaSemHora);
  }

  // Registra a abertura do app
  static Future<void> registrarAbertura() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUltimaAbertura, DateTime.now().toIso8601String());
  }

  // Carrega os registros salvos
  static Future<void> carregarMoods() async {
    final prefs = await SharedPreferences.getInstance();
    final moodsJson = prefs.getString(_keyMoods);
    
    if (moodsJson != null) {
      final List<dynamic> lista = json.decode(moodsJson);
      _registros = lista.map((item) => MoodRegistro.fromJson(item)).toList();
      
      // Ordena por data decrescente
      _registros.sort((a, b) => b.data.compareTo(a.data));
    }
  }

  // Salva um novo mood
  static Future<void> salvarMood(Mood mood) async {
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
    
    // Remove registro do dia se já existir
    _registros.removeWhere((r) {
      final dataSemHora = DateTime(r.data.year, r.data.month, r.data.day);
      return dataSemHora.isAtSameMomentAs(hojeSemHora);
    });
    
    // Adiciona novo registro
    _registros.insert(
      0,
      MoodRegistro(data: hojeSemHora, mood: mood),
    );
    
    // Salva no SharedPreferences
    await _salvarNoStorage();
  }

  static Future<void> _salvarNoStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final moodsJson = json.encode(
      _registros.map((r) => r.toJson()).toList(),
    );
    await prefs.setString(_keyMoods, moodsJson);
  }

  // Obtém o mood de hoje
  static MoodRegistro? getMoodHoje() {
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
    
    try {
      return _registros.firstWhere((r) {
        final dataSemHora = DateTime(r.data.year, r.data.month, r.data.day);
        return dataSemHora.isAtSameMomentAs(hojeSemHora);
      });
    } catch (e) {
      return null;
    }
  }

  // Obtém registros dos últimos N dias
  static List<MoodRegistro> getRegistrosUltimosDias(int dias) {
    final agora = DateTime.now();
    final limite = agora.subtract(Duration(days: dias));
    
    return _registros.where((r) => r.data.isAfter(limite)).toList();
  }

  // Obtém registros da semana atual
  static List<MoodRegistro> getRegistrosSemana() {
    final agora = DateTime.now();
    final inicioSemana = agora.subtract(Duration(days: agora.weekday - 1));
    final inicioSemanaData = DateTime(
      inicioSemana.year,
      inicioSemana.month,
      inicioSemana.day,
    );
    
    return _registros.where((r) => r.data.isAfter(inicioSemanaData) || 
                                    r.data.isAtSameMomentAs(inicioSemanaData)).toList();
  }

  // Obtém registros do mês atual
  static List<MoodRegistro> getRegistrosMes() {
    final agora = DateTime.now();
    final inicioMes = DateTime(agora.year, agora.month, 1);
    
    return _registros.where((r) => r.data.isAfter(inicioMes) || 
                                    r.data.isAtSameMomentAs(inicioMes)).toList();
  }

  // Obtém registros do ano atual
  static List<MoodRegistro> getRegistrosAno() {
    final agora = DateTime.now();
    final inicioAno = DateTime(agora.year, 1, 1);
    
    return _registros.where((r) => r.data.isAfter(inicioAno) || 
                                    r.data.isAtSameMomentAs(inicioAno)).toList();
  }

  // Calcula a média de humor para um período
  static double? calcularMedia(List<MoodRegistro> registros) {
    if (registros.isEmpty) return null;
    
    final soma = registros.fold<int>(0, (sum, r) => sum + r.mood.valor);
    return soma / registros.length;
  }
}