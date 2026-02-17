import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/prova_model.dart';

class NotificacoesService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _inicializado = false;

  // Inicializar o serviço de notificações
  static Future<void> inicializar() async {
    if (_inicializado) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.local);
    

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _inicializado = true;
  }

  static Future<bool> solicitarPermissoes() async {
  // ANDROID
  final androidPlugin = _notifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  if (androidPlugin != null) {
    final granted = await androidPlugin.requestNotificationsPermission();
    return granted ?? false;
  }

  // IOS
  final iosPlugin = _notifications
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

  if (iosPlugin != null) {
    final granted = await iosPlugin.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return granted ?? false;
  }

  return false;
}

  // Agendar notificações para uma prova
  static Future<void> agendarNotificacoesProva(Prova prova) async {
    if (!_inicializado) await inicializar();

    // Cancela notificações anteriores desta prova
    await cancelarNotificacoesProva(prova.chave);

    // Se não tem configuração de lembrete, não agenda
    if (prova.diasAntesLembrete == null || prova.diasAntesLembrete! <= 0) {
      return;
    }

    final dataProva = DateTime(
      prova.data.year,
      prova.data.month,
      prova.data.day,
      9, // Notifica às 9h
      0,
    );

    // Se a data da prova já passou, não agenda
    if (dataProva.isBefore(DateTime.now())) {
      return;
    }

    if (prova.lembretesDiarios) {
      // Notificações diárias desde X dias antes até o dia anterior
      for (int i = prova.diasAntesLembrete!; i > 0; i--) {
        final dataNotificacao = dataProva.subtract(Duration(days: i));

        // Só agenda se a data ainda não passou
        if (dataNotificacao.isAfter(DateTime.now())) {
          final id = _gerarIdNotificacao(prova.chave, i);
          final mensagem = _gerarMensagem(prova.materia, i);

          await _agendarNotificacao(
            id: id,
            titulo: 'Lembrete de Prova',
            corpo: mensagem,
            dataHora: dataNotificacao,
          );
        }
      }
    } else {
      // Apenas uma notificação X dias antes
      final dataNotificacao = dataProva.subtract(Duration(days: prova.diasAntesLembrete!));

      if (dataNotificacao.isAfter(DateTime.now())) {
        final id = _gerarIdNotificacao(prova.chave, prova.diasAntesLembrete!);
        final mensagem = _gerarMensagem(prova.materia, prova.diasAntesLembrete!);

        await _agendarNotificacao(
          id: id,
          titulo: 'Lembrete de Prova',
          corpo: mensagem,
          dataHora: dataNotificacao,
        );
      }
    }
  }

  // Agendar uma notificação específica
  static Future<void> _agendarNotificacao({
    required int id,
    required String titulo,
    required String corpo,
    required DateTime dataHora,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'provas_channel',
      'Lembretes de Provas',
      channelDescription: 'Notificações para lembrar de provas',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzDataHora = tz.TZDateTime.from(dataHora, tz.local);

    await _notifications.zonedSchedule(
    id,
    titulo,
    corpo,
    tzDataHora,
    details,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );
  }

  // Cancelar notificações de uma prova
  static Future<void> cancelarNotificacoesProva(String chaveProva) async {
    // Cancela notificações de até 30 dias antes (máximo possível)
    for (int i = 1; i <= 30; i++) {
      final id = _gerarIdNotificacao(chaveProva, i);
      await _notifications.cancel(id);
    }
  }

  // Cancelar todas as notificações
  static Future<void> cancelarTodasNotificacoes() async {
    await _notifications.cancelAll();
  }

  // Gerar ID único para notificação
  static int _gerarIdNotificacao(String chaveProva, int diasAntes) {
    // Usa hash da chave + dias antes para gerar um ID único
    final hash = chaveProva.hashCode.abs();
    return (hash % 100000) * 100 + diasAntes;
  }

  // Gerar mensagem baseada em quantos dias faltam
  static String _gerarMensagem(String materia, int diasFaltando) {
    if (diasFaltando == 0) {
      return 'Hoje é dia da prova de $materia!';
    } else if (diasFaltando == 1) {
      return 'Amanhã é a prova de $materia! Estude bem! 📚';
    } else {
      return 'Faltam $diasFaltando dias para a prova de $materia. Prepare-se! 📖';
    }
  }

  // Mostrar notificação imediata (para testes)
  static Future<void> mostrarNotificacaoTeste() async {
    if (!_inicializado) await inicializar();

    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Teste',
      channelDescription: 'Canal de teste',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999,
      'Teste de Notificação',
      'As notificações estão funcionando! 🎉',
      details,
    );
  }
}