import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../preferences/appData.dart';
import '../preferences/classesData.dart';
import '../preferences/provasData.dart';
import '../preferences/tarefasData.dart';
import '../preferences/notesData.dart';
import '../preferences/moodData.dart';

class BackupRestoreReport {
  final bool success;
  final bool partial;
  final String? origem;
  final List<String> restaurados;
  final List<String> pulados;
  final List<String> falharam;

  const BackupRestoreReport({
    required this.success,
    required this.partial,
    required this.origem,
    required this.restaurados,
    required this.pulados,
    required this.falharam,
  });
}

class BackupService {
  static const String _backupFileName = 'horarios_escola_backup.json';
  static const String _backupFolderName = 'HorariosEscolaBackup';
  static const String _secureBackupKey = 'horarios_escola_backup_secure_v1';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
  
  // Lista múltiplos diretórios de backup para redundância.
  static Future<List<Directory>> _getBackupDirectories() async {
    final paths = <String>{};

    final docs = await getApplicationDocumentsDirectory();
    paths.add(p.join(docs.path, _backupFolderName));

    if (Platform.isIOS) {
      // iOS: persistência principal via Keychain; arquivo local como redundância.
      return _createDirectories(paths);
    }

    if (Platform.isAndroid) {
      // Android: tenta também locais externos para sobreviver melhor à reinstalação.
      try {
        final downloads = await getDownloadsDirectory();
        if (downloads != null) {
          paths.add(p.join(downloads.path, _backupFolderName));
        }
      } catch (_) {}

      paths.add('/storage/emulated/0/Download/$_backupFolderName');

      try {
        final external = await getExternalStorageDirectory();
        if (external != null) {
          paths.add(p.join(external.path, _backupFolderName));
        }
      } catch (_) {}
    }

    return _createDirectories(paths);
  }

  static Future<List<Directory>> _createDirectories(Set<String> paths) async {
    final dirs = <Directory>[];
    for (final path in paths) {
      try {
        final dir = Directory(path);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        dirs.add(dir);
      } catch (_) {
        // ignora diretórios inacessíveis
      }
    }
    return dirs;
  }

  static Future<List<File>> _getBackupFiles() async {
    final dirs = await _getBackupDirectories();
    return dirs.map((dir) => File(p.join(dir.path, _backupFileName))).toList();
  }

  // Verifica se existe um backup
  static Future<bool> existeBackup() async {
    try {
      final latest = await _readLatestValidBackup();
      return latest != null;
    } catch (e) {
      return false;
    }
  }

  // Obtém informações do backup (data de criação, tamanho)
  static Future<Map<String, dynamic>?> getBackupInfo() async {
    try {
      final latest = await _readLatestValidBackup();
      if (latest == null) return null;

      final data = latest['data'] as Map<String, dynamic>;
      final size = latest['size'] as int;
      final origin = latest['origin'] as String;

      return {
        'dataCriacao': _extractBackupDate(data),
        'tamanho': size,
        'versao': data['versao'] ?? '1.0.0',
        'nomeUsuario': data['appData']?['nome'] ?? 'Desconhecido',
        'dataBackup': data['dataBackup'] ?? 'Desconhecida',
        'origem': origin,
      };
    } catch (e) {
      return null;
    }
  }

  // Cria backup completo de todos os dados
  static Future<bool> criarBackup() async {
    try {
      final backupData = _buildBackupData();
      final backupJson = jsonEncode(backupData);

      return _persistBackupJson(backupJson);
    } catch (e) {
      debugPrint('❌ Erro ao criar backup: $e');
      return false;
    }
  }

  // Debug: cria um backup de dados "antigos" e limpa dados locais para testar restauração.
  static Future<bool> debugPrepararCenarioHeranca() async {
    try {
      final now = DateTime.now();
      final provaDate = now.add(const Duration(days: 2));

      final backupData = {
        'versao': '0.9.0-debug',
        'dataBackup': now.toIso8601String(),
        'platform': 'legacy-debug',
        'appData': {
          'nome': 'Usuario Antigo',
          'ra': '202600123',
          'ano': '3°',
          'turma': 'B',
          'fotoPath': null,
          'dataNascimento': DateTime(2008, 8, 12).toIso8601String(),
          'visualizacaoSemanal': true,
          'modoEscuro': false,
          'notificacoesAtivas': true,
          'diasAntesProva': 2,
          'intervaloLembrete': 60,
          'primeiroAcessoProvas': false,
        },
        'classesData': {
          'aulas': {
            'Segunda-7:10': {
              'materia': 'Matematica',
              'professor': 'Prof. Carlos',
              'diaSemana': 'Segunda',
              'horario': '7:10',
              'cor': 4294198070,
            },
            'Quarta-10:10': {
              'materia': 'Historia',
              'professor': 'Profa. Ana',
              'diaSemana': 'Quarta',
              'horario': '10:10',
              'cor': 4294944000,
            },
          },
        },
        'provasData': {
          'provas': [
            {
              'materia': 'Fisica',
              'data': provaDate.toIso8601String(),
              'horario': '09:00',
              'conteudo': 'Cinematica e Dinamica',
              'cor': 4280391411,
              'diasAntesLembrete': 2,
              'lembretesDiarios': true,
            },
          ],
        },
        'tarefasData': {
          'tarefas': [
            {
              'id': 'debug-tarefa-1',
              'nome': 'Revisar lista de matematica',
              'data': now.add(const Duration(days: 1)).toIso8601String(),
              'prioridade': 0,
              'materia': 'Matematica',
              'concluida': false,
            },
          ],
        },
        // Evita depender de arquivo local de imagem no cenário de teste.
        'notesData': {
          'notas': [],
        },
        'moodData': {
          'moodEntries': [
            {
              'data': DateTime(now.year, now.month, now.day)
                  .toIso8601String(),
              'mood': {
                'emoji': '😊',
                'nome': 'Muito Bem',
                'valor': 5,
              },
            },
          ],
        },
      };

      final backupJson = jsonEncode(backupData);
      final backupSaved = await _persistBackupJson(backupJson);
      if (!backupSaved) return false;

      await AppData.limparDados();
      ClassesData.aulas.clear();
      ProvasData.provas.clear();
      TarefasData.tarefas.clear();
      NotasData.notas.clear();
      MoodData.registros.clear();

      debugPrint('🧪 Cenário de herança preparado (backup antigo + app limpo).');
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao preparar cenário de herança: $e');
      return false;
    }
  }

  static Future<bool> _persistBackupJson(String backupJson) async {
    try {
      final isValid = _decodeAndValidateBackup(backupJson) != null;
      if (!isValid) {
        debugPrint('❌ Backup não persistido: JSON inválido');
        return false;
      }

      // Backup persistente no Keychain (sobrevive reinstalação no iOS)
      bool secureSaved = false;
      try {
        await _secureStorage.write(key: _secureBackupKey, value: backupJson);
        secureSaved = true;
      } catch (e) {
        debugPrint('⚠️ Falha ao salvar no armazenamento seguro: $e');
      }

      final files = await _getBackupFiles();
      int fileWrites = 0;
      for (final backupFile in files) {
        try {
          await backupFile.writeAsString(
            backupJson,
            encoding: utf8,
          );
          fileWrites++;
          debugPrint('💾 Backup salvo em: ${backupFile.path}');
        } catch (e) {
          debugPrint('⚠️ Falha ao salvar backup em ${backupFile.path}: $e');
        }
      }

      final totalBytes = utf8.encode(backupJson).length;
      final ok = secureSaved || fileWrites > 0;
      if (ok) {
        debugPrint(
          '✅ Backup criado com sucesso! '
          '(fontes: seguro=${secureSaved ? 'ok' : 'falhou'}, arquivos=$fileWrites, ${(totalBytes / 1024).toStringAsFixed(2)} KB)',
        );
      }
      return ok;
    } catch (e) {
      debugPrint('❌ Erro ao persistir backup: $e');
      return false;
    }
  }

  // Restaura dados do backup
  static Future<bool> restaurarBackup() async {
    final report = await restaurarBackupComRelatorio();
    return report.success;
  }

  static Future<BackupRestoreReport> restaurarBackupComRelatorio() async {
    try {
      debugPrint('🔄 Iniciando restauração de backup...');

      final latest = await _readLatestValidBackup();
      if (latest == null) {
        debugPrint('❌ Nenhum backup válido encontrado');
        return const BackupRestoreReport(
          success: false,
          partial: false,
          origem: null,
          restaurados: [],
          pulados: [],
          falharam: ['backup'],
        );
      }

      final backupData = latest['data'] as Map<String, dynamic>;
      final origem = latest['origin']?.toString();
      debugPrint('📦 Restaurando a partir de: $origem');

      final restaurados = <String>[];
      final pulados = <String>[];
      final falharam = <String>[];

      Future<void> tentarRestaurar({
        required String secao,
        required dynamic data,
        required Future<bool> Function(dynamic data) restore,
      }) async {
        if (data == null) {
          pulados.add(secao);
          return;
        }

        final ok = await restore(data);
        if (ok) {
          restaurados.add(secao);
        } else {
          falharam.add(secao);
        }
      }

      await tentarRestaurar(
        secao: 'appData',
        data: backupData['appData'],
        restore: (data) => _restoreAppData(data as Map<String, dynamic>?),
      );

      await tentarRestaurar(
        secao: 'classesData',
        data: backupData['classesData'],
        restore: (data) => _restoreClassesData(data as Map<String, dynamic>?),
      );

      await tentarRestaurar(
        secao: 'provasData',
        data: backupData['provasData'],
        restore: (data) => _restoreProvasData(data as Map<String, dynamic>?),
      );

      await tentarRestaurar(
        secao: 'tarefasData',
        data: backupData['tarefasData'],
        restore: (data) => _restoreTarefasData(data as Map<String, dynamic>?),
      );

      await tentarRestaurar(
        secao: 'notesData',
        data: backupData['notesData'],
        restore: (data) => _restoreNotesData(data as Map<String, dynamic>?),
      );

      await tentarRestaurar(
        secao: 'moodData',
        data: backupData['moodData'],
        restore: (data) => _restoreMoodData(data as Map<String, dynamic>?),
      );

      final success = restaurados.isNotEmpty;
      final partial = success && falharam.isNotEmpty;
      debugPrint('✅ Restauração finalizada: restaurados=${restaurados.length}, falhas=${falharam.length}, pulados=${pulados.length}');

      return BackupRestoreReport(
        success: success,
        partial: partial,
        origem: origem,
        restaurados: restaurados,
        pulados: pulados,
        falharam: falharam,
      );
    } catch (e) {
      debugPrint('❌ Erro ao restaurar backup: $e');
      return const BackupRestoreReport(
        success: false,
        partial: false,
        origem: null,
        restaurados: [],
        pulados: [],
        falharam: ['fatal'],
      );
    }
  }

  // Deleta o backup atual
  static Future<bool> deletarBackup() async {
    try {
      await _secureStorage.delete(key: _secureBackupKey);

      final files = await _getBackupFiles();
      for (final backupFile in files) {
        if (await backupFile.exists()) {
          await backupFile.delete();
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Erro ao deletar backup: $e');
      return false;
    }
  }

  static Map<String, dynamic> _buildBackupData() {
    return {
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
  }

  static Future<Map<String, dynamic>?> _readLatestValidBackup() async {
    final candidates = <Map<String, dynamic>>[];

    // Candidato 1: armazenamento seguro
    try {
      final secureContent = await _secureStorage.read(key: _secureBackupKey);
      final secureData =
          secureContent == null ? null : _decodeAndValidateBackup(secureContent);
      if (secureData != null) {
        candidates.add({
          'data': secureData,
          'origin': Platform.isIOS
              ? 'Keychain iOS (persistente)'
              : 'Secure Storage',
          'size': utf8.encode(secureContent!).length,
        });
      }
    } catch (_) {}

    // Candidatos 2..N: arquivos em múltiplos diretórios
    final files = await _getBackupFiles();
    for (final file in files) {
      try {
        if (!await file.exists()) continue;
        final content = await file.readAsString(encoding: utf8);
        final data = _decodeAndValidateBackup(content);
        if (data == null) continue;
        final stat = await file.stat();
        candidates.add({
          'data': data,
          'origin': 'Arquivo (${file.path})',
          'size': stat.size,
        });
      } catch (_) {
        // ignora arquivo inválido/inacessível
      }
    }

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      final dateA = _extractBackupDate(a['data'] as Map<String, dynamic>);
      final dateB = _extractBackupDate(b['data'] as Map<String, dynamic>);
      return dateB.compareTo(dateA);
    });

    return candidates.first;
  }

  static Map<String, dynamic>? _decodeAndValidateBackup(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) return null;

      final appData = decoded['appData'];
      if (appData is! Map<String, dynamic>) return null;

      return decoded;
    } catch (_) {
      return null;
    }
  }

  static DateTime _extractBackupDate(Map<String, dynamic> data) {
    final dateRaw = data['dataBackup'];
    if (dateRaw is String) {
      final parsed = DateTime.tryParse(dateRaw);
      if (parsed != null) return parsed;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
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
  static Future<bool> _restoreAppData(Map<String, dynamic>? data) async {
    if (data == null) return false;
    try {
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
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao restaurar AppData: $e');
      return false;
    }
  }

  static Future<bool> _restoreClassesData(Map<String, dynamic>? data) async {
    try {
      if (data == null || data['aulas'] == null) return false;
      
      final prefs = await SharedPreferences.getInstance();
      final aulasList = data['aulas'] as Map<String, dynamic>;
      
      // Converte de volta para JSON array
      final aulasJson = jsonEncode(aulasList.values.toList());
      await prefs.setString('aulas', aulasJson);
      
      // Recarrega ClassesData
      await ClassesData.carregarAulas();
      debugPrint('✅ Classes restauradas: ${aulasList.length} aulas');
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao restaurar Classes: $e');
      return false;
    }
  }

  static Future<bool> _restoreProvasData(Map<String, dynamic>? data) async {
    try {
      if (data == null || data['provas'] == null) return false;
      
      final prefs = await SharedPreferences.getInstance();
      final provasList = data['provas'] as List<dynamic>;
      
      final provasJson = jsonEncode(provasList);
      await prefs.setString('provas', provasJson);
      
      // Recarrega ProvasData
      await ProvasData.carregarProvas();
      debugPrint('✅ Provas restauradas: ${provasList.length} provas');
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao restaurar Provas: $e');
      return false;
    }
  }

  static Future<bool> _restoreTarefasData(Map<String, dynamic>? data) async {
    try {
      if (data == null || data['tarefas'] == null) return false;
      
      final prefs = await SharedPreferences.getInstance();
      final tarefasList = data['tarefas'] as List<dynamic>;
      
      final tarefasJson = jsonEncode(tarefasList);
      await prefs.setString('tarefas', tarefasJson);
      
      // Recarrega TarefasData
      await TarefasData.carregarTarefas();
      debugPrint('✅ Tarefas restauradas: ${tarefasList.length} tarefas');
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao restaurar Tarefas: $e');
      return false;
    }
  }

  static Future<bool> _restoreNotesData(Map<String, dynamic>? data) async {
    try {
      if (data == null || data['notas'] == null) return false;
      
      final prefs = await SharedPreferences.getInstance();
      final notasList = data['notas'] as List<dynamic>;
      
      final notasJson = jsonEncode(notasList);
      await prefs.setString('notas', notasJson);
      
      // Recarrega NotasData
      await NotasData.carregarNotas();
      debugPrint('✅ Notas restauradas: ${notasList.length} notas');
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao restaurar Notas: $e');
      return false;
    }
  }

  static Future<bool> _restoreMoodData(Map<String, dynamic>? data) async {
    try {
      if (data == null || data['moodEntries'] == null) return false;
      
      final prefs = await SharedPreferences.getInstance();
      final moodList = data['moodEntries'] as List<dynamic>;
      
      final moodJson = jsonEncode(moodList);
      await prefs.setString('moods', moodJson);
      
      // Recarrega MoodData
      await MoodData.carregarMoods();
      debugPrint('✅ Registros de humor restaurados: ${moodList.length} registros');
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao restaurar Mood: $e');
      return false;
    }
  }
}
