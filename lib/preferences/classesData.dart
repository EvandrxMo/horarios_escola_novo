import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/aula_model.dart';

class ClassesData {
  // Mapa de aulas: chave = 'DiaSemana-Horario', valor = Aula
  static Map<String, Aula> aulas = {};

  // Dias da semana
  static const List<String> diasSemana = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
  ];

  // Horários
  static const List<String> horarios = [
    '7:10',
    '8:10',
    '8:40',
    '9:00',
    'INTERVALO',
    '10:10',
    '11:10',
    '12:00',
  ];

  // Adicionar ou atualizar aula
  static void adicionarAula(Aula aula) {
    aulas[aula.chave] = aula;
  }

  // Remover aula específica
  static void removerAula(String diaSemana, String horario) {
    final chave = '$diaSemana-$horario';
    aulas.remove(chave);
  }

  // Limpar todas as aulas
  static void limparTodasAulas() {
    aulas.clear();
  }

  // Buscar aula por dia e horário
  static Aula? buscarAula(String diaSemana, String horario) {
    final chave = '$diaSemana-$horario';
    return aulas[chave];
  }

  // Verificar se existe aula no horário
  static bool existeAula(String diaSemana, String horario) {
    final chave = '$diaSemana-$horario';
    return aulas.containsKey(chave);
  }

  // Salvar aulas no SharedPreferences
  static Future<void> salvarAulas() async {
    final prefs = await SharedPreferences.getInstance();
    final aulasJson = jsonEncode(
      aulas.values.map((aula) => aula.toJson()).toList(),
    );
    await prefs.setString('aulas', aulasJson);
  }

  // Carregar aulas do SharedPreferences
  static Future<void> carregarAulas() async {
    final prefs = await SharedPreferences.getInstance();
    final aulasJson = prefs.getString('aulas');

    if (aulasJson != null && aulasJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(aulasJson);
        aulas.clear();
        for (var item in decoded) {
          final aula = Aula.fromJson(item);
          aulas[aula.chave] = aula;
        }
      } catch (e) {
        print('Erro ao carregar aulas: $e');
        aulas.clear();
      }
    }
  }

  // Obter próxima aula baseada no dia e hora atual
  static Aula? obterProximaAula() {
    final agora = DateTime.now();
    final diaAtual = _obterDiaSemana(agora.weekday);
    final horaAtual = '${agora.hour}:${agora.minute.toString().padLeft(2, '0')}';

    // Se não for dia de aula (sábado/domingo), retorna null
    if (diaAtual == null) return null;

    // Procura a próxima aula no dia atual
    for (var horario in horarios) {
      if (horario == 'INTERVALO') continue;
      
      final aula = buscarAula(diaAtual, horario);
      if (aula != null && _horarioMaiorOuIgual(horario, horaAtual)) {
        return aula;
      }
    }

    // Se não encontrou no dia atual, procura no próximo dia
    final indexDiaAtual = diasSemana.indexOf(diaAtual);
    for (int i = indexDiaAtual + 1; i < diasSemana.length; i++) {
      for (var horario in horarios) {
        if (horario == 'INTERVALO') continue;
        
        final aula = buscarAula(diasSemana[i], horario);
        if (aula != null) return aula;
      }
    }

    // Se não encontrou nesta semana, pega a primeira aula da próxima semana
    for (var dia in diasSemana) {
      for (var horario in horarios) {
        if (horario == 'INTERVALO') continue;
        
        final aula = buscarAula(dia, horario);
        if (aula != null) return aula;
      }
    }

    return null;
  }

  // Converte weekday (1-7) para nome do dia
  static String? _obterDiaSemana(int weekday) {
    switch (weekday) {
      case 1: return 'Segunda';
      case 2: return 'Terça';
      case 3: return 'Quarta';
      case 4: return 'Quinta';
      case 5: return 'Sexta';
      default: return null; // Sábado e Domingo
    }
  }

  // Compara se horario1 >= horario2
  static bool _horarioMaiorOuIgual(String horario1, String horario2) {
    final h1 = horario1.split(':');
    final h2 = horario2.split(':');
    
    final hora1 = int.parse(h1[0]);
    final min1 = int.parse(h1[1]);
    final hora2 = int.parse(h2[0]);
    final min2 = int.parse(h2[1]);

    if (hora1 > hora2) return true;
    if (hora1 == hora2 && min1 >= min2) return true;
    return false;
  }
}