import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/tarefa_model.dart';

class TarefasData {
  static List<Tarefa> tarefas = [];

  // Adicionar tarefa
  static void adicionarTarefa(Tarefa tarefa) {
    tarefas.add(tarefa);
    _ordenarTarefas();
  }

  // Remover tarefa
  static void removerTarefa(String id) {
    tarefas.removeWhere((t) => t.id == id);
  }

  // Alternar conclusão da tarefa
  static void toggleConclusao(String id) {
    final index = tarefas.indexWhere((t) => t.id == id);
    if (index != -1) {
      tarefas[index].concluida = !tarefas[index].concluida;
    }
  }

  // Editar tarefa
  static void editarTarefa(Tarefa tarefaAtualizada) {
    final index = tarefas.indexWhere((t) => t.id == tarefaAtualizada.id);
    if (index != -1) {
      tarefas[index] = tarefaAtualizada;
      _ordenarTarefas();
    }
  }

  // Limpar todas as tarefas
  static void limparTodasTarefas() {
    tarefas.clear();
  }

  // Limpar tarefas concluídas
  static void limparTarefasConcluidas() {
    tarefas.removeWhere((t) => t.concluida);
  }

  // Ordenar tarefas
  static void _ordenarTarefas() {
    tarefas.sort((a, b) {
      // 1. Tarefas não concluídas primeiro
      if (a.concluida != b.concluida) {
        return a.concluida ? 1 : -1;
      }

      // 2. Prioridade (urgente -> média -> baixa)
      if (a.prioridade != b.prioridade) {
        return a.prioridade.index.compareTo(b.prioridade.index);
      }

      // 3. Data (tarefas com data primeiro, ordenadas por data)
      if (a.data != null && b.data != null) {
        return a.data!.compareTo(b.data!);
      }
      if (a.data != null) return -1;
      if (b.data != null) return 1;

      // 4. Nome alfabético
      return a.nome.compareTo(b.nome);
    });
  }

  // Obter tarefas agrupadas por data
  static Map<String, List<Tarefa>> obterTarefasAgrupadas() {
    final Map<String, List<Tarefa>> agrupadas = {};
    
    for (var tarefa in tarefas) {
      final chave = tarefa.data != null ? tarefa.dataFormatada : 'Sem data';
      
      if (!agrupadas.containsKey(chave)) {
        agrupadas[chave] = [];
      }
      agrupadas[chave]!.add(tarefa);
    }
    
    return agrupadas;
  }

  // Salvar tarefas
  static Future<void> salvarTarefas() async {
    final prefs = await SharedPreferences.getInstance();
    final tarefasJson = jsonEncode(
      tarefas.map((tarefa) => tarefa.toJson()).toList(),
    );
    await prefs.setString('tarefas', tarefasJson);
  }

  // Carregar tarefas
  static Future<void> carregarTarefas() async {
    final prefs = await SharedPreferences.getInstance();
    final tarefasJson = prefs.getString('tarefas');

    if (tarefasJson != null && tarefasJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(tarefasJson);
        tarefas.clear();
        for (var item in decoded) {
          final tarefa = Tarefa.fromJson(item);
          tarefas.add(tarefa);
        }
        _ordenarTarefas();
      } catch (e) {
        print('Erro ao carregar tarefas: $e');
        tarefas.clear();
      }
    }
  }

  // Estatísticas
  static int get totalTarefas => tarefas.length;
  static int get tarefasConcluidas => tarefas.where((t) => t.concluida).length;
  static int get tarefasPendentes => tarefas.where((t) => !t.concluida).length;
  static int get tarefasUrgentes => tarefas.where((t) => 
    !t.concluida && t.prioridade == PrioridadeTarefa.urgente
  ).length;
}