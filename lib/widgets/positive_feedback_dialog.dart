import 'package:flutter/material.dart';

class PositiveFeedbackDialog extends StatefulWidget {
  const PositiveFeedbackDialog({super.key});

  @override
  State<PositiveFeedbackDialog> createState() => _PositiveFeedbackDialogState();
}

class _PositiveFeedbackDialogState extends State<PositiveFeedbackDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animações
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // Iniciar animações
    _scaleController.forward();
    _fadeController.forward();
    
    // Tocar som de sucesso (se disponível)
    _playSuccessSound();
  }

  Future<void> _playSuccessSound() async {
    try {
      // TODO: Implementar som quando o pacote audioplayers for adicionado
      // Por enquanto, apenas vibrar se disponível
    } catch (e) {
      // Se não tiver som, continua sem som
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedback = _getRandomFeedback();
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Imagem
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.asset(
                      feedback.imagePath,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Frase motivacional
                Text(
                  feedback.phrase,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Subtítulo
                Text(
                  'Continue assim! 💪',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Botão de fechar
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text('Obrigado!'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

FeedbackData _getRandomFeedback() {
  final feedbacks = [
    FeedbackData(
      imagePath: 'assets/images/giulie.png',
      phrase: 'Excelente trabalho! 🎉',
    ),
    FeedbackData(
      imagePath: 'assets/images/judite.png',
      phrase: 'Você é incrível! ⭐',
    ),
    FeedbackData(
      imagePath: 'assets/images/luna.png',
      phrase: 'Missão cumprida! 🚀',
    ),
    FeedbackData(
      imagePath: 'assets/images/mel.png',
      phrase: 'Parabéns! Continue assim! 💖',
    ),
    FeedbackData(
      imagePath: 'assets/images/sury.png',
      phrase: 'Arrasou! 🌟',
    ),
    FeedbackData(
      imagePath: 'assets/images/tevez.png',
      phrase: 'Muito bem! Você consegue! 🎯',
    ),
  ];
  
  feedbacks.shuffle();
  return feedbacks.first;
}

class FeedbackData {
  final String imagePath;
  final String phrase;

  FeedbackData({
    required this.imagePath,
    required this.phrase,
  });
}

// Função global para mostrar o feedback
void showPositiveFeedback(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const PositiveFeedbackDialog(),
  );
}
