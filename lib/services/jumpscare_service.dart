import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/jumpscare_dialog.dart';

class JumpscareService {
  static Timer? _jumpscareTimer;
  static bool _hasTriggeredToday = false;
  static const String _lastTriggerKey = 'last_jumpscare_date';

  // Inicia o timer para o jumpscare
  static void startJumpscareTimer(BuildContext context) {
    // Verifica se já foi acionado hoje
    if (_hasTriggeredToday) return;

    // Cancela timer anterior se existir
    _jumpscareTimer?.cancel();

    // Tempo aleatório entre 7 e 10 segundos
    final randomDelay = Random().nextInt(4) + 7; // 7, 8, 9 ou 10 segundos
    
    _jumpscareTimer = Timer(Duration(seconds: randomDelay), () {
      if (!_hasTriggeredToday && context.mounted) {
        _triggerJumpscare(context);
      }
    });
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
      print('Erro ao salvar data do jumpscare: $e');
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
      print('Erro ao verificar data do jumpscare: $e');
      _hasTriggeredToday = false;
    }
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
