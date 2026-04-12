import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../widgets/jumpscare_dialog.dart';

class JumpscareService {
  static Timer? _jumpscareTimer;
  static bool _hasTriggeredToday = false;
  static const String _lastTriggerKey = 'last_jumpscare_date';
  static bool _modoAgressivo = true;

  static bool get modoAgressivo => _modoAgressivo;

  static void setModoAgressivo(bool value) {
    _modoAgressivo = value;
  }

  // Inicia o timer para o jumpscare
  static void startJumpscareTimer(BuildContext context) {
    // Verifica se já foi acionado hoje
    if (_hasTriggeredToday) return;

    // Cancela timer anterior se existir
    _jumpscareTimer?.cancel();

    // Perfil agressivo mantém checagem frequente; moderado poupa bateria.
    final randomDelay = _modoAgressivo
      ? (Random().nextInt(4) + 7) // 7..10s
      : (Random().nextInt(121) + 60); // 60..180s
    
    _jumpscareTimer = Timer(Duration(seconds: randomDelay), () {
      if (!_hasTriggeredToday && context.mounted) {
        _verificarCondicoesJumpscare(context);
      }
    });
  }

  // Verifica as condições para o jumpscare
  static Future<void> _verificarCondicoesJumpscare(BuildContext context) async {
    try {
      final now = DateTime.now();
      final hora = now.hour;
      final minuto = now.minute;
      
      // Janela de ativação: 22:30 até 04:30 (atravessa meia-noite)
      final dentroJanelaNoturna =
          (hora > 22 || (hora == 22 && minuto >= 30)) ||
          (hora < 4 || (hora == 4 && minuto <= 30));

      if (!dentroJanelaNoturna) {
        // Fora da janela, agenda nova checagem
        if (!context.mounted) return;
        startJumpscareTimer(context);
        return;
      }

      // Verifica o brilho da tela
      try {
        final brightness = await ScreenBrightness.instance.current;
        // brightness varia de 0.0 a 1.0
        final brightnessPercentage = brightness * 100;

        if (brightnessPercentage <= 75) {
          // Brilho abaixo de 75%, não aciona jumpscare
          if (!context.mounted) return;
          startJumpscareTimer(context);
          return;
        }
      } catch (e) {
        debugPrint('Erro ao obter brilho: $e');
        // Se não conseguir obter brilho, não aciona jumpscare
        if (!context.mounted) return;
        startJumpscareTimer(context);
        return;
      }

      // Se chegou aqui, todas as condições foram atendidas
      if (!context.mounted) return;
      _triggerJumpscare(context);
    } catch (e) {
      debugPrint('Erro ao verificar condições do jumpscare: $e');
      if (!context.mounted) return;
      startJumpscareTimer(context);
    }
  }

  static Future<void> runCheckNow(BuildContext context) async {
    await _verificarCondicoesJumpscare(context);
  }

  // Aciona o jumpscare
  static void _triggerJumpscare(BuildContext context) {
    // Marca que foi acionado hoje
    _hasTriggeredToday = true;
    _saveLastTriggerDate();
    
    // Mostra o jumpscare
    showJumpscareDialog(context);
  }

  // Salva a data do último acionamento
  static Future<void> _saveLastTriggerDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastTriggerKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Erro ao salvar data do jumpscare: $e');
    }
  }

  // Verifica se já foi acionado hoje
  static Future<void> checkLastTriggerDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastTriggerStr = prefs.getString(_lastTriggerKey);
      
      if (lastTriggerStr != null) {
        final lastTrigger = DateTime.parse(lastTriggerStr);
        final now = DateTime.now();
        
        // Verifica se foi acionado no mesmo dia
        if (lastTrigger.year == now.year && 
            lastTrigger.month == now.month && 
            lastTrigger.day == now.day) {
          _hasTriggeredToday = true;
        } else {
          // Se é um novo dia, reseta o flag
          _hasTriggeredToday = false;
        }
      }
    } catch (e) {
      debugPrint('Erro ao verificar data do jumpscare: $e');
      _hasTriggeredToday = false;
    }
  }

  static Future<Map<String, String>> getDebugInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final hora = now.hour;
    final minuto = now.minute;
    final dentroJanelaNoturna =
        (hora > 22 || (hora == 22 && minuto >= 30)) ||
        (hora < 4 || (hora == 4 && minuto <= 30));

    final lastTrigger = prefs.getString(_lastTriggerKey) ?? 'nunca';
    return {
      'modo': _modoAgressivo ? 'Agressivo (7-10s)' : 'Moderado (60-180s)',
      'janela': dentroJanelaNoturna ? 'Dentro da janela' : 'Fora da janela',
      'acionouHoje': _hasTriggeredToday ? 'Sim' : 'Não',
      'ultimoDisparo': lastTrigger,
    };
  }

  // Para o timer (chamar ao fechar o app)
  static void stopTimer() {
    _jumpscareTimer?.cancel();
    _jumpscareTimer = null;
  }

  // Reseta o flag (para testes)
  static void resetFlag() {
    _hasTriggeredToday = false;
  }

  // Força o jumpscare (para testes)
  static void forceJumpscare(BuildContext context) {
    _jumpscareTimer?.cancel();
    _triggerJumpscare(context);
  }
}
