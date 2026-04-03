import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
      
      return true;
    } catch (e) {
      debugPrint('Erro ao criar backup: $e');
      return false;
    }
  }

  // Restaura dados do backup
  static Future<bool> restaurarBackup() async {
    try {
      final directory = await _backupDirectory;
      final backupFile = File('${directory.path}/$_backupFileName');
      
      if (!await backupFile.exists()) return false;
      
      final content = await backupFile.readAsString(encoding: utf8);
      final backupData = jsonDecode(content);
      
      // Restaura AppData
      await _restoreAppData(backupData['appData']);
      
      // Restaura outros dados
      await _restoreClassesData(backupData['classesData']);
      await _restoreProvasData(backupData['provasData']);
      await _restoreTarefasData(backupData['tarefasData']);
      await _restoreNotesData(backupData['notesData']);
      await _restoreMoodData(backupData['moodData']);
      
      return true;
    } catch (e) {
      debugPrint('Erro ao restaurar backup: $e');
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

  static Future<void> _restoreClassesData(Map<String, dynamic> data) async {
    // Implementar restauração de classesData quando necessário
    // Isso exigirá modificar classesData.dart para ter método de restauração
  }

  static Future<void> _restoreProvasData(Map<String, dynamic> data) async {
    // Implementar restauração de provasData quando necessário
    // Isso exigirá modificar provasData.dart para ter método de restauração
  }

  static Future<void> _restoreTarefasData(Map<String, dynamic> data) async {
    // Implementar restauração de tarefasData quando necessário
    // Isso exigirá modificar tarefasData.dart para ter método de restauração
  }

  static Future<void> _restoreNotesData(Map<String, dynamic> data) async {
    // Implementar restauração de notesData quando necessário
    // Isso exigirá modificar notesData.dart para ter método de restauração
  }

  static Future<void> _restoreMoodData(Map<String, dynamic> data) async {
    // Implementar restauração de moodData quando necessário
    // Isso exigirá modificar moodData.dart para ter método de restauração
  }
}
