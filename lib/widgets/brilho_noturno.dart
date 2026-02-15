import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';

class BrilhoNoturnoWidget extends StatefulWidget {
  const BrilhoNoturnoWidget({super.key});

  @override
  State<BrilhoNoturnoWidget> createState() => _BrilhoNoturnoWidgetState();
}

class _BrilhoNoturnoWidgetState extends State<BrilhoNoturnoWidget> {
  double _brilhoAtual = 0.5;
  bool _mostrarAviso = false;
  bool _avisoFoiFechado = false;

  @override
  void initState() {
    super.initState();
    _verificarBrilho();
  }

  Future<void> _verificarBrilho() async {
    try {
      final brilho = await ScreenBrightness().current;
      setState(() {
        _brilhoAtual = brilho;
        _verificarSeDeveAvisar();
      });
    } catch (e) {
      // Se der erro ao pegar o brilho, não faz nada
    }

    // Verifica a cada 10 segundos
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _verificarBrilho();
      }
    });
  }

  void _verificarSeDeveAvisar() {
    final agora = DateTime.now();
    final hora = agora.hour;
    
    // Considera "noite" das 19h às 6h
    final eNoite = hora >= 19 || hora < 6;
    
    // Considera brilho alto acima de 60%
    final brilhoAlto = _brilhoAtual > 0.6;
    
    setState(() {
      _mostrarAviso = eNoite && brilhoAlto && !_avisoFoiFechado;
    });
  }

  Future<void> _reduzirBrilho() async {
    try {
      await ScreenBrightness().setScreenBrightness(0.3);
      setState(() {
        _brilhoAtual = 0.3;
        _mostrarAviso = false;
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
  Widget build(BuildContext context) {
    if (!_mostrarAviso) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade800,
            Colors.red.shade700,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
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
          
          // Imagem Sury sem fundo - SEM CÍRCULO
          Image.asset(
            'assets/images/sury.png',
            width: 90,
            height: 90,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 12),
          
          // Título
          const Text(
            'Opa! Tá muito claro aí!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Mensagem
          Text(
            'São ${DateTime.now().hour}h e o brilho da sua tela está em ${(_brilhoAtual * 100).toInt()}%.\n\nIsso pode prejudicar sua visão! 👀',
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Informação extra
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Exposição à luz azul à noite pode atrapalhar seu sono',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
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
                    'Ignorar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _reduzirBrilho,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Ajustar (30%)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}