import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class JumpscareDialog extends StatefulWidget {
  const JumpscareDialog({super.key});

  @override
  State<JumpscareDialog> createState() => _JumpscareDialogState();
}

class _JumpscareDialogState extends State<JumpscareDialog>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Controlador de shake (tremedeira)
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    // Controlador de fade (aparecimento rápido)
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    );
    
    // Controlador de scale (zoom repentino)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.linear,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.bounceOut,
    ));

    // Iniciar animações de forma agressiva
    _fadeController.forward();
    _scaleController.forward();
    
    // Shake contínuo
    _startContinuousShake();
    
    // Tocar som no volume máximo
    _playJumpscareSound();
    
    // Vibração intensa
    _triggerIntenseVibration();
  }

  void _startContinuousShake() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _shakeController.repeat(reverse: true);
      }
    });
  }

  Future<void> _playJumpscareSound() async {
    try {
      // Aumentar volume do sistema ao máximo (se possível)
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      
      // TODO: Implementar áudio quando o pacote for adicionado
      // Por enquanto, vamos usar feedback visual intenso
      
    } catch (e) {
      print('Erro ao tocar som: $e');
    }
  }

  Future<void> _triggerIntenseVibration() async {
    try {
      // Vibração intensa e contínua se disponível
      for (int i = 0; i < 5; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        // TODO: Implementar vibração quando possível
      }
    } catch (e) {
      print('Erro na vibração: $e');
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Impede fechar o diálogo facilmente
        return false;
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: AnimatedBuilder(
          animation: Listenable.merge([_shakeController, _fadeController, _scaleController]),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                _shakeAnimation.value * (DateTime.now().millisecond % 2 == 0 ? 1 : -1),
                _shakeAnimation.value * (DateTime.now().millisecond % 2 == 0 ? -1 : 1),
              ),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    color: Colors.black.withOpacity(0.95),
                    child: Stack(
                      children: [
                        // Imagem Rasputin centralizada e gigante
                        Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: MediaQuery.of(context).size.height * 0.6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.8),
                                  blurRadius: 50,
                                  spreadRadius: 20,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'assets/images/rasputin.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.red,
                                    child: const Center(
                                      child: Text(
                                        'RASPUTIN',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        
                        // Texto piscando
                        Positioned(
                          top: 100,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: AnimatedBuilder(
                              animation: _fadeController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: 0.5 + (_fadeAnimation.value * 0.5),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white, width: 3),
                                    ),
                                    child: const Text(
                                      '⚠️ LUZ ACIMA DO IDEAL ⚠️',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black,
                                            blurRadius: 10,
                                            offset: Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        
                        // Botão de abaixar brilho (difícil de encontrar)
                        Positioned(
                          bottom: 50,
                          right: 20,
                          child: AnimatedBuilder(
                            animation: _fadeController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: 0.3 + (_fadeAnimation.value * 0.7),
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Fecha o jumpscare e abre diálogo normal
                                    Navigator.of(context).pop();
                                    _showNormalBrightnessDialog();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.withOpacity(0.8),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'ABAIXAR BRILHO',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showNormalBrightnessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Aviso de Brilho'),
        content: const Text(
          'A luz ambiente está acima do nível ideal para seus olhos. '
          'Recomendamos diminuir o brilho da tela para proteger sua visão.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ignorar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar controle de brilho
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Diminuir Brilho'),
          ),
        ],
      ),
    );
  }
}

// Função global para mostrar o jumpscare
void showJumpscareDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const JumpscareDialog(),
  );
}
