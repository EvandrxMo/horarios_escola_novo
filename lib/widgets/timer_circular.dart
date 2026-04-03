import 'package:flutter/material.dart';
import '../services/pomodoro_service.dart';

class TimerCircular extends StatelessWidget {
  final PomodoroService pomodoro;
  final double tamanho;
  final double espessura;

  const TimerCircular({
    super.key,
    required this.pomodoro,
    this.tamanho = 250.0,
    this.espessura = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Círculo de fundo
          SizedBox(
            width: tamanho,
            height: tamanho,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: espessura,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[300]!),
            ),
          ),
          
          // Círculo de progresso
          SizedBox(
            width: tamanho,
            height: tamanho,
            child: CircularProgressIndicator(
              value: pomodoro.progressoPercentual,
              strokeWidth: espessura,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(pomodoro.corEstado),
            ),
          ),
          
          // Conteúdo central
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Tempo
              Text(
                pomodoro.tempoFormatado,
                style: TextStyle(
                  fontSize: tamanho * 0.19, // 48px para 250px
                  fontWeight: FontWeight.bold,
                  color: pomodoro.corEstado,
                  fontFamily: 'monospace',
                ),
              ),
              SizedBox(height: tamanho * 0.032), // 8px para 250px
              
              // Título do estado
              Text(
                pomodoro.tituloEstado,
                style: TextStyle(
                  fontSize: tamanho * 0.072, // 18px para 250px
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: tamanho * 0.016), // 4px para 250px
              
              // Descrição do estado
              Text(
                pomodoro.descricaoEstado,
                style: TextStyle(
                  fontSize: tamanho * 0.056, // 14px para 250px
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MiniTimerCircular extends StatelessWidget {
  final PomodoroService pomodoro;
  final double tamanho;

  const MiniTimerCircular({
    super.key,
    required this.pomodoro,
    this.tamanho = 80.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Círculo de fundo
          SizedBox(
            width: tamanho,
            height: tamanho,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 4.0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[300]!),
            ),
          ),
          
          // Círculo de progresso
          SizedBox(
            width: tamanho,
            height: tamanho,
            child: CircularProgressIndicator(
              value: pomodoro.progressoPercentual,
              strokeWidth: 4.0,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(pomodoro.corEstado),
            ),
          ),
          
          // Tempo central
          Text(
            pomodoro.tempoFormatado,
            style: TextStyle(
              fontSize: tamanho * 0.15, // 12px para 80px
              fontWeight: FontWeight.bold,
              color: pomodoro.corEstado,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
