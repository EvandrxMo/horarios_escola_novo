import 'package:flutter/material.dart';

class Mood {
  final String emoji;
  final String imagePath;
  final String nome;
  final Color cor;
  final int valor; // 1-6, sendo 1 = pior e 6 = melhor

  const Mood({
    required this.emoji,
    required this.imagePath,
    required this.nome,
    required this.cor,
    required this.valor,
  });

  static const List<Mood> moods = [
    Mood(
      emoji: '😢',
      imagePath: 'assets/images/mel.png',
      nome: 'Triste',
      cor: Color(0xFF3B82F6), // Azul
      valor: 1,
    ),
    Mood(
      emoji: '😔',
      imagePath: 'assets/images/luna.png',
      nome: 'Cansada',
      cor: Color(0xFF6366F1), // Índigo
      valor: 2,
    ),
    Mood(
      emoji: '😐',
      imagePath: 'assets/images/sury.png',
      nome: 'Brava',
      cor: Color(0xFF8B5CF6), // Roxo
      valor: 3,
    ),
    Mood(
      emoji: '🙂',
      imagePath: 'assets/images/judite.png',
      nome: 'Bem',
      cor: Color(0xFFFBBF24), // Amarelo
      valor: 4,
    ),
    Mood(
      emoji: '😊',
      imagePath: 'assets/images/giulie.png',
      nome: 'Muito Bem',
      cor: Color(0xFFF97316), // Laranja
      valor: 5,
    ),
    Mood(
      emoji: '😄',
      imagePath: 'assets/images/tevez.png',
      nome: 'Apenas Tevez',
      cor: Color(0xFFEF4444), // Vermelho (alegria)
      valor: 6,
    ),
  ];

  // Widget helper para exibir a imagem com fallback
  Widget buildImage({double size = 40, BoxFit fit = BoxFit.contain}) {
    return Image.asset(
      imagePath,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Fallback para emoji se imagem não carregar
        return Text(
          emoji,
          style: TextStyle(fontSize: size * 0.8),
        );
      },
    );
  }

  Map<String, dynamic> toJson() => {
    'emoji': emoji,
    'nome': nome,
    'valor': valor,
  };

  static Mood fromJson(Map<String, dynamic> json) {
    return moods.firstWhere(
      (m) => m.valor == json['valor'],
      orElse: () => moods[2], // Neutro como padrão
    );
  }
}

class MoodRegistro {
  final DateTime data;
  final Mood mood;

  MoodRegistro({
    required this.data,
    required this.mood,
  });

  Map<String, dynamic> toJson() => {
    'data': data.toIso8601String(),
    'mood': mood.toJson(),
  };

  static MoodRegistro fromJson(Map<String, dynamic> json) {
    return MoodRegistro(
      data: DateTime.parse(json['data']),
      mood: Mood.fromJson(json['mood']),
    );
  }
}