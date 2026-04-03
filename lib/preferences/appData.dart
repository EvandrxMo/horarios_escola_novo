import 'package:shared_preferences/shared_preferences.dart';
import '../services/backup_service.dart';

class AppData {
  // ======================
  // Dados do usuário
  // ======================
  static String nome = '';
  static String ra = '';
  static String ano = '1°';
  static String turma = '';
  static String? fotoPath;
  static DateTime? dataNascimento;

  // ======================
  // Preferências visuais
  // ======================
  static bool visualizacaoSemanal = true;
  static bool modoEscuro = false;

  // ======================
  // 🔔 Preferências de NOTIFICAÇÃO
  // ======================
  static bool notificacoesAtivas = true;
  static int diasAntesProva = 1;
  static int intervaloLembrete = 60; // minutos
  static bool primeiroAcessoProvas = true;

  // ======================
  // Salvar dados
  // ======================
  static Future<void> salvarDados() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('nome', nome);
    await prefs.setString('ra', ra);
    await prefs.setString('ano', ano);
    await prefs.setString('turma', turma.toUpperCase());

    await prefs.setBool('visualizacaoSemanal', visualizacaoSemanal);
    await prefs.setBool('modoEscuro', modoEscuro);

    await prefs.setBool('notificacoesAtivas', notificacoesAtivas);
    await prefs.setInt('diasAntesProva', diasAntesProva);
    await prefs.setInt('intervaloLembrete', intervaloLembrete);
    await prefs.setBool('primeiroAcessoProvas', primeiroAcessoProvas);

    if (fotoPath != null) {
      await prefs.setString('fotoPath', fotoPath!);
    }

    if (dataNascimento != null) {
      await prefs.setString(
        'dataNascimento',
        dataNascimento!.toIso8601String(),
      );
    }

    // Criar backup automático após salvar dados
    await BackupService.criarBackup();
  }

  // ======================
  // Carregar dados
  // ======================
  static Future<void> carregarDados() async {
    final prefs = await SharedPreferences.getInstance();

    nome = prefs.getString('nome') ?? '';
    ra = prefs.getString('ra') ?? '';
    ano = prefs.getString('ano') ?? '1°';
    turma = prefs.getString('turma') ?? '';
    fotoPath = prefs.getString('fotoPath');

    visualizacaoSemanal = prefs.getBool('visualizacaoSemanal') ?? true;
    modoEscuro = prefs.getBool('modoEscuro') ?? false;

    notificacoesAtivas = prefs.getBool('notificacoesAtivas') ?? true;
    diasAntesProva = prefs.getInt('diasAntesProva') ?? 1;
    intervaloLembrete = prefs.getInt('intervaloLembrete') ?? 60;
    primeiroAcessoProvas = prefs.getBool('primeiroAcessoProvas') ?? true;

    final dataNascStr = prefs.getString('dataNascimento');
    if (dataNascStr != null) {
      dataNascimento = DateTime.parse(dataNascStr);
    }
  }

  // ======================
  // Limpar dados
  // ======================
  static Future<void> limparDados() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    nome = '';
    ra = '';
    ano = '1°';
    turma = '';
    fotoPath = null;
    dataNascimento = null;

    visualizacaoSemanal = true;
    modoEscuro = false;

    notificacoesAtivas = true;
    diasAntesProva = 1;
    intervaloLembrete = 60;
    primeiroAcessoProvas = true;
  }

  // ======================
  // Utilidades
  // ======================
  static bool get isAniversarioHoje {
    if (dataNascimento == null) return false;
    final hoje = DateTime.now();
    return hoje.day == dataNascimento!.day &&
        hoje.month == dataNascimento!.month;
  }

  static int? get idade {
    if (dataNascimento == null) return null;
    final hoje = DateTime.now();
    int idade = hoje.year - dataNascimento!.year;

    if (hoje.month < dataNascimento!.month ||
        (hoje.month == dataNascimento!.month &&
            hoje.day < dataNascimento!.day)) {
      idade--;
    }

    return idade;
  }
}
