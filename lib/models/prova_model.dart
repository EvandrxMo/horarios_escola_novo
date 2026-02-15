import 'package:flutter/material.dart';

class Prova {
  final String materia;
  final DateTime data;
  final String horario;
  final String conteudo;
  final Color? cor;
  final int? diasAntesLembrete; // Quantos dias antes avisar
  final bool lembretesDiarios; // Se deve notificar diariamente

  Prova({
    required this.materia,
    required this.data,
    required this.horario,
    required this.conteudo,
    this.cor,
    this.diasAntesLembrete,
    this.lembretesDiarios = false,
  });

  // Converter para JSON para salvar no SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'materia': materia,
      'data': data.toIso8601String(),
      'horario': horario,
      'conteudo': conteudo,
      'cor': cor?.value,
      'diasAntesLembrete': diasAntesLembrete,
      'lembretesDiarios': lembretesDiarios,
    };
  }

  // Criar Prova a partir de JSON
  factory Prova.fromJson(Map<String, dynamic> json) {
    return Prova(
      materia: json['materia'] as String,
      data: DateTime.parse(json['data'] as String),
      horario: json['horario'] as String,
      conteudo: json['conteudo'] as String,
      cor: json['cor'] != null ? Color(json['cor'] as int) : null,
      diasAntesLembrete: json['diasAntesLembrete'] as int?,
      lembretesDiarios: json['lembretesDiarios'] as bool? ?? false,
    );
  }

  // Chave única para identificar a prova (data + horário)
  String get chave => '${data.toIso8601String()}-$horario';

  // Formatar data para exibição
  String get dataFormatada {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year;
    return '$dia/$mes/$ano';
  }

  // Nome do dia da semana
  String get diaSemana {
    const dias = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
    return dias[data.weekday - 1];
  }
}