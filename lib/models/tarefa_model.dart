import 'package:flutter/material.dart';

enum PrioridadeTarefa {
  urgente,
  media,
  baixa;

  String get nome {
    switch (this) {
      case PrioridadeTarefa.urgente:
        return 'Urgente';
      case PrioridadeTarefa.media:
        return 'Média';
      case PrioridadeTarefa.baixa:
        return 'Baixa';
    }
  }

  Color get cor {
    switch (this) {
      case PrioridadeTarefa.urgente:
        return Colors.red;
      case PrioridadeTarefa.media:
        return Colors.orange;
      case PrioridadeTarefa.baixa:
        return Colors.green;
    }
  }

  IconData get icone {
    switch (this) {
      case PrioridadeTarefa.urgente:
        return Icons.flag;
      case PrioridadeTarefa.media:
        return Icons.flag;
      case PrioridadeTarefa.baixa:
        return Icons.flag;
    }
  }
}

class Tarefa {
  final String id;
  final String nome;
  final DateTime? data;
  final PrioridadeTarefa prioridade;
  bool concluida;

  Tarefa({
    required this.id,
    required this.nome,
    this.data,
    required this.prioridade,
    this.concluida = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'data': data?.toIso8601String(),
      'prioridade': prioridade.index,
      'concluida': concluida,
    };
  }

  factory Tarefa.fromJson(Map<String, dynamic> json) {
    return Tarefa(
      id: json['id'] as String,
      nome: json['nome'] as String,
      data: json['data'] != null ? DateTime.parse(json['data'] as String) : null,
      prioridade: PrioridadeTarefa.values[json['prioridade'] as int],
      concluida: json['concluida'] as bool? ?? false,
    );
  }

  // Formatar data para exibição
  String get dataFormatada {
    if (data == null) return 'Sem data';
    final dia = data!.day.toString().padLeft(2, '0');
    final mes = data!.month.toString().padLeft(2, '0');
    final ano = data!.year;
    return '$dia/$mes/$ano';
  }

  // Criar cópia com alterações
  Tarefa copyWith({
    String? id,
    String? nome,
    DateTime? data,
    PrioridadeTarefa? prioridade,
    bool? concluida,
  }) {
    return Tarefa(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      data: data ?? this.data,
      prioridade: prioridade ?? this.prioridade,
      concluida: concluida ?? this.concluida,
    );
  }
}