import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'dart:math';

class BrilhoNoturnoWidget extends StatefulWidget {
  const BrilhoNoturnoWidget({super.key});

  @override
  State<BrilhoNoturnoWidget> createState() => _BrilhoNoturnoWidgetState();
}

class _BrilhoNoturnoWidgetState extends State<BrilhoNoturnoWidget>
    with TickerProviderStateMixin {
  double _brilhoAtual = 0.5;
  bool _mostrarAviso = false;
  bool _avisoFoiFechado = false;
  bool _jumpscarePronto = false;
  late AnimationController _shakeController;
  late AnimationController _flashController;

  @override
  void initState() {
    super.initState();
    
    // Animações para jumpscare
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // JUMPSCARE: Aparece entre 7-10 segundos após abrir o app
    final delaySegundos = 7 + Random().nextInt(4); // 7 a 10 segundos
    Future.delayed(Duration(seconds: delaySegundos), () {
      if (mounted) {
        _verificarBrilhoParaJumpscare();
      }
    });

    // TESTE: Verifica a cada 4 minutos
    Future.delayed(const Duration(minutes: 4), () {
      if (mounted) {
        _verificarBrilho();
      }
    });
  }

  Future<void> _verificarBrilhoParaJumpscare() async {
    try {
      final brilho = await ScreenBrightness().current;
      setState(() {
        _brilhoAtual = brilho;
        _verificarSeDeveMostrarJumpscare();
      });
    } catch (e) {
      // Se der erro ao pegar o brilho, não faz nada
    }
  }

  Future<void> _verificarBrilho() async {
    try {
      final brilho = await ScreenBrightness().current;
      setState(() {
        _brilhoAtual = brilho;
        _verificarSeDeveMostrarJumpscare();
      });
    } catch (e) {
      // Se der erro ao pegar o brilho, não faz nada
    }

    // Continua verificando a cada 4 minutos
    Future.delayed(const Duration(minutes: 4), () {
      if (mounted) {
        _verificarBrilho();
      }
    });
  }

  void _verificarSeDeveMostrarJumpscare() {
    final agora = DateTime.now();
    final hora = agora.hour;
    
    // Considera "noite" das 19h às 6h
    final eNoite = hora >= 19 || hora < 6;
    
    // Considera brilho alto acima de 60%
    final brilhoAlto = _brilhoAtual > 0.6;
    
    if (eNoite && brilhoAlto && !_avisoFoiFechado && !_jumpscarePronto) {
      _mostrarJumpscare();
    }
  }

  Future<void> _mostrarJumpscare() async {
    setState(() {
      _jumpscarePronto = true;
    });

    // Inicia animações do jumpscare
    _shakeController.forward();
    _flashController.forward();

    // Mostra o diálogo após o efeito
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _mostrarAviso = true;
        });
      }
    });

    // Para as animações depois
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _shakeController.reverse();
        _flashController.reverse();
      }
    });
  }

  Future<void> _reduzirBrilho() async {
    try {
      await ScreenBrightness().setScreenBrightness(0.3);
      setState(() {
        _brilhoAtual = 0.3;
        _mostrarAviso = false;
        _avisoFoiFechado = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Brilho ajustado! Seus olhos agradecem 👀'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Erro ao ajustar brilho
    }
  }

  void _fecharAviso() {
    setState(() {
      _mostrarAviso = false;
      _avisoFoiFechado = true;
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_mostrarAviso) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_shakeController, _flashController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _shakeController.value * 10 * (Random().nextDouble() - 0.5),
            _shakeController.value * 10 * (Random().nextDouble() - 0.5),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: _flashController.value > 0.5 
                  ? Colors.red.withOpacity(0.8) 
                  : Colors.transparent,
            ),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.zero,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.shade900,
                      Colors.black,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.8),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.6),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botão fechar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: _fecharAviso,
                          icon: const Icon(Icons.close, color: Colors.white),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    
                    // Imagem Rasputin - JUMPSCARE
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(75),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.8),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.8),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(75),
                        child: Image.asset(
                          'assets/images/rasputin.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Título de alerta
                    const Text(
                      '🚨 LUZ ACIMA DO IDEAL! 🚨',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    
                    // Mensagem
                    Text(
                      'São ${DateTime.now().hour}h e o brilho está em ${(_brilhoAtual * 100).toInt()}%!\n\nISSO VAI FERRAR SEUS OLHOS! 👀',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    
                    // Aviso de saúde
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Luz azul à noite destrói seu sono e sua visão!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Botões
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _fecharAviso,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'IGNORAR RISCO',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _reduzirBrilho,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'SALVAR OLHOS (30%)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}