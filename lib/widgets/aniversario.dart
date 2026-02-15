import 'package:flutter/material.dart';
import 'dart:math';

class AniversarioAnimacao extends StatefulWidget {
  final String nome;
  final int idade;
  final VoidCallback onClose;

  const AniversarioAnimacao({
    super.key,
    required this.nome,
    required this.idade,
    required this.onClose,
  });

  @override
  State<AniversarioAnimacao> createState() => _AniversarioAnimacaoState();
}

class _AniversarioAnimacaoState extends State<AniversarioAnimacao>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final Random _random = Random();
  final int _numBaloes = 15;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _numBaloes,
      (index) => AnimationController(
        duration: Duration(milliseconds: 3000 + _random.nextInt(2000)),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 1.2, end: -0.2).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    // Inicia as animações com delay
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Color _getBalaoColor(int index) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Material(
      color: Colors.black.withOpacity(0.7),
      child: Stack(
        children: [
          // Balões animados
          ...List.generate(_numBaloes, (index) {
            final leftPosition = _random.nextDouble() * size.width;
            final balaoColor = _getBalaoColor(index);

            return AnimatedBuilder(
              animation: _animations[index],
              builder: (context, child) {
                return Positioned(
                  left: leftPosition,
                  top: _animations[index].value * size.height,
                  child: Transform.rotate(
                    angle: (_animations[index].value * 2 * pi) * 0.1,
                    child: _buildBalao(balaoColor),
                  ),
                );
              },
            );
          }),

          // Conteúdo central
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Emoji de festa
                const Text(
                  '🎉',
                  style: TextStyle(fontSize: 80),
                ),
                const SizedBox(height: 20),

                // Feliz Aniversário
                const Text(
                  'Feliz Aniversário!',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Nome
                Text(
                  widget.nome.split(' ').first,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Idade
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    '${widget.idade} anos! 🎂',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Botão fechar
                ElevatedButton(
                  onPressed: widget.onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Obrigado! 😊',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalao(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Balão
        Container(
          width: 50,
          height: 65,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 5,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 15,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        // Linha do balão
        Container(
          width: 2,
          height: 30,
          color: color.withOpacity(0.5),
        ),
      ],
    );
  }
}