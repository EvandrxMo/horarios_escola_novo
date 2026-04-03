import 'package:uuid/uuid.dart';

class FocoSession {
  final String id;
  final DateTime inicio;
  final DateTime? fim;
  final int duracaoMinutos;
  final String? materia;
  final int ciclosCompletos;
  final int pontosGanhos;
  final bool concluida;

  FocoSession({
    required this.id,
    required this.inicio,
    this.fim,
    required this.duracaoMinutos,
    this.materia,
    this.ciclosCompletos = 0,
    this.pontosGanhos = 0,
    this.concluida = false,
  });

  // Factory para criar nova sessão
  factory FocoSession.criar({String? materia}) {
    final agora = DateTime.now();
    return FocoSession(
      id: const Uuid().v4(),
      inicio: agora,
      duracaoMinutos: 0,
      materia: materia,
    );
  }

  // Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inicio': inicio.toIso8601String(),
      'fim': fim?.toIso8601String(),
      'duracaoMinutos': duracaoMinutos,
      'materia': materia,
      'ciclosCompletos': ciclosCompletos,
      'pontosGanhos': pontosGanhos,
      'concluida': concluida,
    };
  }

  // Criar do JSON
  factory FocoSession.fromJson(Map<String, dynamic> json) {
    return FocoSession(
      id: json['id'],
      inicio: DateTime.parse(json['inicio']),
      fim: json['fim'] != null ? DateTime.parse(json['fim']) : null,
      duracaoMinutos: json['duracaoMinutos'] ?? 0,
      materia: json['materia'],
      ciclosCompletos: json['ciclosCompletos'] ?? 0,
      pontosGanhos: json['pontosGanhos'] ?? 0,
      concluida: json['concluida'] ?? false,
    );
  }

  // Copiar com alterações
  FocoSession copyWith({
    DateTime? fim,
    int? duracaoMinutos,
    String? materia,
    int? ciclosCompletos,
    int? pontosGanhos,
    bool? concluida,
  }) {
    return FocoSession(
      id: id,
      inicio: inicio,
      fim: fim ?? this.fim,
      duracaoMinutos: duracaoMinutos ?? this.duracaoMinutos,
      materia: materia ?? this.materia,
      ciclosCompletos: ciclosCompletos ?? this.ciclosCompletos,
      pontosGanhos: pontosGanhos ?? this.pontosGanhos,
      concluida: concluida ?? this.concluida,
    );
  }

  // Duração formatada
  String get duracaoFormatada {
    final horas = duracaoMinutos ~/ 60;
    final minutos = duracaoMinutos % 60;
    
    if (horas > 0) {
      return '${horas}h ${minutos}min';
    }
    return '${minutos}min';
  }

  // Verificar se está em andamento
  bool get estaEmAndamento => !concluida && fim == null;
}
