import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../preferences/appData.dart';
import '../preferences/classesData.dart';
import '../preferences/provasData.dart';
import '../preferences/tarefasData.dart';
import '../preferences/notesData.dart';
import '../preferences/moodData.dart';

class BackupService {
  static const String _backupFileName = 'horarios_escola_backup.json';
  
  // Obtém o diretório de documentos compartilhado (persiste após desinstalação)
  static Future<Directory> get _backupDirectory async {
    if (Platform.isIOS) {
      // No iOS, ApplicationDocumentsDirectory é compartilhado e persiste
      return getApplicationDocumentsDirectory();
    } else {
      // No Android, usa diretório externo se disponível
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        return Directory(directory.path).parent;
      }
      // Fallback para diretório de documentos
      return getApplicationDocumentsDirectory();
    }
  }

  // Verifica se existe um backup
  static Future<bool> existeBackup() async {
    try {
      final directory = await _backupDirectory;
      final backupFile = File('${directory.path}/$_backupFileName');
      return await backupFile.exists();
    } catch (e) {
      return false;
    }
  }

  // Obtém informações do backup (data de criação, tamanho)
  static Future<Map<String, dynamic>?> getBackupInfo() async {
    try {
      final directory = await _backupDirectory;
      final backupFile = File('${directory.path}/$_backupFileName');
      
      if (!await backupFile.exists()) return null;
      
      final stat = await backupFile.stat();
      final content = await backupFile.readAsString(encoding: utf8);
      final data = jsonDecode(content);
      
      return {
        'dataCriacao': stat.modified,
        'tamanho': stat.size,
        'versao': data['versao'] ?? '1.0.0',
        'nomeUsuario': data['appData']['nome'] ?? 'Desconhecido',
        'dataBackup': data['dataBackup'] ?? 'Desconhecida',
      };
    } catch (e) {
      return null;
    }
  }

  // Cria backup completo de todos os dados
  static Future<bool> criarBackup() async {
    try {
      final directory = await _backupDirectory;
      debugPrint('💾 Criando backup em: ${directory.path}/$_backupFileName');
      
      final backupFile = File('${directory.path}/$_backupFileName');
      
      // Coleta todos os dados
      final backupData = {
        'versao': '1.0.0',
        'dataBackup': DateTime.now().toIso8601String(),
        'platform': Platform.operatingSystem,
        'appData': _getAppData(),
        'classesData': _getClassesData(),
        'provasData': _getProvasData(),
        'tarefasData': _getTarefasData(),
        'notesData': _getNotesData(),
        'moodData': _getMoodData(),
      };
      
      // Salva como JSON
      await backupFile.writeAsString(
        jsonEncode(backupData),
        encoding: utf8,
      );
      
      final fileSize = await backupFile.length();
      debugPrint('✅ Backup criado com sucesso! (${(fileSize / 1024).toStringAsFixed(2)} KB)');
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao criar backup: $e');
      return false;
    }
  }

  // Restaura dados do backup
  static Future<bool> restaurarBackup() async {
    try {
      debugPrint('🔄 Iniciando restauração de backup...');
      final directory = await _backupDirectory;
      final backupFile = File('${directory.path}/$_backupFileName');
      
      if (!await backupFile.exists()) {
        debugPrint('❌ Arquivo de backup não encontrado');
        return false;
      }
      
      final content = await backupFile.readAsString(encoding: utf8);
      final backupData = jsonDecode(content);
      
      debugPrint('📦 Restaurando AppData...');
      await _restoreAppData(backupData['appData']);
      
      debugPrint('📚 Restaurando Classes...');
      await _restoreClassesData(backupData['classesData']);
      
      debugPrint('✏️ Restaurando Provas...');
      await _restoreProvasData(backupData['provasData']);
      
      debugPrint('✅ Restaurando Tarefas...');
      await _restoreTarefasData(backupData['tarefasData']);
      
      debugPrint('📷 Restaurando Notas...');
      await _restoreNotesData(backupData['notesData']);
      
      debugPrint('😊 Restaurando Humor...');
      await _restoreMoodData(backupData['moodData']);
      
      debugPrint('✅ Backup restaurado com sucesso!');
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao restaurar backup: $e');
      return false;
    }
  }

  // Deleta o backup atual
  static Future<bool> deletarBackup() async {
    try {
      final directory = await _backupDirectory;
      final backupFile = File('${directory.path}/$_backupFileName');
      
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
      
      return true;
    } catch (e) {
      debugPrint('Erro ao deletar backup: $e');
      return false;
    }
  }

  // Métodos privados para coletar dados
  static Map<String, dynamic> _getAppData() {
    return {
      'nome': AppData.nome,
      'ra': AppData.ra,
      'ano': AppData.ano,
      'turma': AppData.turma,
      'fotoPath': AppData.fotoPath,
      'dataNascimento': AppData.dataNascimento?.toIso8601String(),
      'visualizacaoSemanal': AppData.visualizacaoSemanal,
      'modoEscuro': AppData.modoEscuro,
      'notificacoesAtivas': AppData.notificacoesAtivas,
      'diasAntesProva': AppData.diasAntesProva,
      'intervaloLembrete': AppData.intervaloLembrete,
      'primeiroAcessoProvas': AppData.primeiroAcessoProvas,
    };
  }

  static Map<String, dynamic> _getClassesData() {
    return {
      'aulas': ClassesData.aulas.map((key, aula) => MapEntry(key, aula.toJson())),
    };
  }

  static Map<String, dynamic> _getProvasData() {
    return {
      'provas': ProvasData.provas.map((prova) => prova.toJson()).toList(),
    };
  }

  static Map<String, dynamic> _getTarefasData() {
    return {
      'tarefas': TarefasData.tarefas.map((tarefa) => tarefa.toJson()).toList(),
    };
  }

  static Map<String, dynamic> _getNotesData() {
    return {
      'notas': NotasData.notas.map((nota) => nota.toJson()).toList(),
    };
  }

  static Map<String, dynamic> _getMoodData() {
    return {
      'moodEntries': MoodData.registros.map((entry) => entry.toJson()).toList(),
    };
  }

  // Métodos privados para restaurar dados
  static Future<void> _restoreAppData(Map<String, dynamic> data) async {
    AppData.nome = data['nome'] ?? '';
    AppData.ra = data['ra'] ?? '';
    AppData.ano = data['ano'] ?? '1°';
    AppData.turma = data['turma'] ?? '';
    AppData.fotoPath = data['fotoPath'];
    
    if (data['dataNascimento'] != null) {
      AppData.dataNascimento = DateTime.parse(data['dataNascimento']);
    }
    
    AppData.visualizacaoSemanal = data['visualizacaoSemanal'] ?? true;
    AppData.modoEscuro = data['modoEscuro'] ?? false;
    AppData.notificacoesAtivas = data['notificacoesAtivas'] ?? true;
    AppData.diasAntesProva = data['diasAntesProva'] ?? 1;
    AppData.intervaloLembrete = data['intervaloLembrete'] ?? 60;
    AppData.primeiroAcessoProvas = data['primeiroAcessoProvas'] ?? true;
    
    await AppData.salvarDados();
  }

  static Future<void> _restoreClassesData(Map<String, dynamic>? data) async {
    try {
      if (data == null || data['aulas'] == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      final aulasList = data['aulas'] as Map<String, dynamic>;
      
      // Converte de volta para JSON array
      final aulasJson = jsonEncode(aulasList.values.toList());
      await prefs.setString('aulas', aulasJson);
      
      // Recarrega ClassesData
      await ClassesData.carregarAulas();
      debugPrint('✅ Classes restauradas: ${aulasList.length} aulas');
    } catch (e) {
      debugPrint('❌ Erro ao restaurar Classes: $e');
    }
  }

  static Future<void> _restoreProvasData(Map<String, dynamic>? data) async {
    try {
      if (data == null || data['provas'] == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      final provasList = data['provas'] as List<dynamic>;
      
      final provasJson = jsonEncode(provasList);
      await prefs.setString('provas', provasJson);
      
      // Recarrega ProvasData
      await ProvasData.carregarProvas();
      debugPrint('✅ Provas restauradas: ${provasList.length} provas');
    } catch (e) {
      debugPrint('❌ Erro ao restaurar Provas: $e');
    }
  }

  static Future<void> _restoreTarefasData(Map<String, dynamic>? data) async {
    try {
      if (data == null || data['tarefas'] == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      final tarefasList = data['tarefas'] as List<dynamic>;
      
      final tarefasJson = jsonEncode(tarefasList);
      await prefs.setString('tarefas', tarefasJson);
      
      // Recarrega TarefasData
      await TarefasData.carregarTarefas();
      debugPrint('✅ Tarefas restauradas: ${tarefasList.length} tarefas');
    } catch (e) {
      debugPrint('❌ Erro ao restaurar Tarefas: $e');
    }
  }

  static Future<void> _restoreNotesData(Map<String, dynamic>? data) async {
    try {
      if (data == null || data['notas'] == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      final notasList = data['notas'] as List<dynamic>;
      
      final notasJson = jsonEncode(notasList);
      await prefs.setString('notas', notasJson);
      
      // Recarrega NotasData
      await NotasData.carregarNotas();
      debugPrint('✅ Notas restauradas: ${notasList.length} notas');
    } catch (e) {
      debugPrint('❌ Erro ao restaurar Notas: $e');
    }
  }

  static Future<void> _restoreMoodData(Map<String, dynamic>? data) async {
    try {
      if (data == null || data['moodEntries'] == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      final moodList = data['moodEntries'] as List<dynamic>;
      
      final moodJson = jsonEncode(moodList);
      await prefs.setString('moods', moodJson);
      
      // Recarrega MoodData
      await MoodData.carregarMoods();
      debugPrint('✅ Registros de humor restaurados: ${moodList.length} registros');
    } catch (e) {
      debugPrint('❌ Erro ao restaurar Mood: $e');
    }
  }
}
