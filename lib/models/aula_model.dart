import 'package:flutter/material.dart';

class Aula {
  final String materia;
  final String professor;
  final String diaSemana; // 'Segunda', 'Terça', etc
  final String horario; // '7:00', '7:50', etc
  final Color? cor; // Opcional, se null = branco

  Aula({
    required this.materia,
    required this.professor,
    required this.diaSemana,
    required this.horario,
    this.cor,
  });

  // Converter para JSON para salvar no SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'materia': materia,
      'professor': professor,
      'diaSemana': diaSemana,
      'horario': horario,
      'cor': cor?.value, // Salva o valor int da cor
    };
  }

  // Criar Aula a partir de JSON
  factory Aula.fromJson(Map<String, dynamic> json) {
    return Aula(
      materia: json['materia'] as String,
      professor: json['professor'] as String,
      diaSemana: json['diaSemana'] as String,
      horario: json['horario'] as String,
      cor: json['cor'] != null ? Color(json['cor'] as int) : null,
    );
  }

  // Chave única para identificar a aula (dia + horário)
  String get chave => '$diaSemana-$horario';
}