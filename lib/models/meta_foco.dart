import 'package:uuid/uuid.dart';

class MetaFoco {
  final String id;
  final int metaDiariaMinutos;
  final int metaSemanalCiclos;
  final int progressoHoje;
  final int progressoSemanal;
  final DateTime dataCriacao;
  final DateTime? ultimaAtualizacao;
  final bool ativa;

  MetaFoco({
    required this.id,
    required this.metaDiariaMinutos,
    required this.metaSemanalCiclos,
    this.progressoHoje = 0,
    this.progressoSemanal = 0,
    required this.dataCriacao,
    this.ultimaAtualizacao,
    this.ativa = true,
  });

  // Factory para criar metas padrão
  factory MetaFoco.criarPadrao() {
    final agora = DateTime.now();
    return MetaFoco(
      id: const Uuid().v4(),
      metaDiariaMinutos: 120, // 2 horas por dia
      metaSemanalCiclos: 20,  // 20 ciclos por semana
      dataCriacao: agora,
      ultimaAtualizacao: agora,
    );
  }

  // Factory para metas personalizadas
  factory MetaFoco.criarPersonalizada({
    required int metaDiariaMinutos,
    required int metaSemanalCiclos,
  }) {
    final agora = DateTime.now();
    return MetaFoco(
      id: const Uuid().v4(),
      metaDiariaMinutos: metaDiariaMinutos,
      metaSemanalCiclos: metaSemanalCiclos,
      dataCriacao: agora,
      ultimaAtualizacao: agora,
    );
  }

  // Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'metaDiariaMinutos': metaDiariaMinutos,
      'metaSemanalCiclos': metaSemanalCiclos,
      'progressoHoje': progressoHoje,
      'progressoSemanal': progressoSemanal,
      'dataCriacao': dataCriacao.toIso8601String(),
      'ultimaAtualizacao': ultimaAtualizacao?.toIso8601String(),
      'ativa': ativa,
    };
  }

  // Criar do JSON
  factory MetaFoco.fromJson(Map<String, dynamic> json) {
    return MetaFoco(
      id: json['id'],
      metaDiariaMinutos: json['metaDiariaMinutos'],
      metaSemanalCiclos: json['metaSemanalCiclos'],
      progressoHoje: json['progressoHoje'] ?? 0,
      progressoSemanal: json['progressoSemanal'] ?? 0,
      dataCriacao: DateTime.parse(json['dataCriacao']),
      ultimaAtualizacao: json['ultimaAtualizacao'] != null 
          ? DateTime.parse(json['ultimaAtualizacao']) 
          : null,
      ativa: json['ativa'] ?? true,
    );
  }

  // Copiar com alterações
  MetaFoco copyWith({
    int? metaDiariaMinutos,
    int? metaSemanalCiclos,
    int? progressoHoje,
    int? progressoSemanal,
    DateTime? ultimaAtualizacao,
    bool? ativa,
  }) {
    return MetaFoco(
      id: id,
      metaDiariaMinutos: metaDiariaMinutos ?? this.metaDiariaMinutos,
      metaSemanalCiclos: metaSemanalCiclos ?? this.metaSemanalCiclos,
      progressoHoje: progressoHoje ?? this.progressoHoje,
      progressoSemanal: progressoSemanal ?? this.progressoSemanal,
      dataCriacao: dataCriacao,
      ultimaAtualizacao: ultimaAtualizacao ?? this.ultimaAtualizacao,
      ativa: ativa ?? this.ativa,
    );
  }

  // Progresso diário em percentual
  double get progressoDiarioPercentual {
    if (metaDiariaMinutos == 0) return 0.0;
    return (progressoHoje / metaDiariaMinutos).clamp(0.0, 1.0);
  }

  // Progresso semanal em percentual
  double get progressoSemanalPercentual {
    if (metaSemanalCiclos == 0) return 0.0;
    return (progressoSemanal / metaSemanalCiclos).clamp(0.0, 1.0);
  }

  // Verificar se meta diária foi alcançada
  bool get metaDiariaAlcancada => progressoHoje >= metaDiariaMinutos;

  // Verificar se meta semanal foi alcançada
  bool get metaSemanalAlcancada => progressoSemanal >= metaSemanalCiclos;

  // Tempo restante para meta diária
  int get tempoRestanteDiario {
    final restante = metaDiariaMinutos - progressoHoje;
    return restante < 0 ? 0 : restante;
  }

  // Ciclos restantes para meta semanal
  int get ciclosRestantesSemanais {
    final restante = metaSemanalCiclos - progressoSemanal;
    return restante < 0 ? 0 : restante;
  }

  // Formatação do progresso diário
  String get progressoDiarioFormatado {
    final horas = progressoHoje ~/ 60;
    final minutos = progressoHoje % 60;
    
    if (horas > 0) {
      return '${horas}h ${minutos}min / ${metaDiariaMinutos}min';
    }
    return '${minutos}min / ${metaDiariaMinutos}min';
  }

  // Formatação do progresso semanal
  String get progressoSemanalFormatado {
    return '$progressoSemanal / $metaSemanalCiclos ciclos';
  }

  // Resetar progresso diário (chamar no início do dia)
  MetaFoco resetarProgressoDiario() {
    return copyWith(
      progressoHoje: 0,
      ultimaAtualizacao: DateTime.now(),
    );
  }

  // Resetar progresso semanal (chamar no início da semana)
  MetaFoco resetarProgressoSemanal() {
    return copyWith(
      progressoSemanal: 0,
      ultimaAtualizacao: DateTime.now(),
    );
  }

  // Adicionar progresso diário
  MetaFoco adicionarProgressoDiario(int minutos) {
    return copyWith(
      progressoHoje: progressoHoje + minutos,
      ultimaAtualizacao: DateTime.now(),
    );
  }

  // Adicionar progresso semanal
  MetaFoco adicionarProgressoSemanal(int ciclos) {
    return copyWith(
      progressoSemanal: progressoSemanal + ciclos,
      ultimaAtualizacao: DateTime.now(),
    );
  }
}
