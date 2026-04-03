class Conquista {
  final String id;
  final String titulo;
  final String descricao;
  final String icone; // Emoji ou nome do ícone
  final int pontosRecompensa;
  final String tipo; // 'ciclo', 'streak', 'tempo', 'materia'
  final DateTime? desbloqueadaEm;
  final bool desbloqueada;
  final int progressoAtual;
  final int progressoMaximo;

  Conquista({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.pontosRecompensa,
    required this.tipo,
    this.desbloqueadaEm,
    this.desbloqueada = false,
    this.progressoAtual = 0,
    required this.progressoMaximo,
  });

  // Lista de conquistas disponíveis
  static List<Conquista> conquistasBase() {
    return [
      // Conquistas de Ciclo
      Conquista(
        id: 'primeiro_ciclo',
        titulo: 'Primeiro Ciclo',
        descricao: 'Complete seu primeiro ciclo de 25 minutos',
        icone: '🎯',
        pontosRecompensa: 50,
        tipo: 'ciclo',
        progressoMaximo: 1,
      ),
      
      Conquista(
        id: 'foco_maquina',
        titulo: 'Foco Máquina',
        descricao: 'Complete 7 dias seguidos de estudo',
        icone: '🔥',
        pontosRecompensa: 200,
        tipo: 'streak',
        progressoMaximo: 7,
      ),
      
      Conquista(
        id: 'maratonista',
        titulo: 'Maratonista',
        descricao: 'Complete 4 ciclos sem parar',
        icone: '⚡',
        pontosRecompensa: 150,
        tipo: 'ciclo',
        progressoMaximo: 4,
      ),
      
      // Conquistas de Tempo
      Conquista(
        id: 'hora_foco',
        titulo: 'Hora de Foco',
        descricao: 'Estude por 60 minutos no total',
        icone: '⏰',
        pontosRecompensa: 100,
        tipo: 'tempo',
        progressoMaximo: 60,
      ),
      
      Conquista(
        id: 'mestre_tempo',
        titulo: 'Mestre do Tempo',
        descricao: 'Estude por 5 horas no total',
        icone: '⌚',
        pontosRecompensa: 300,
        tipo: 'tempo',
        progressoMaximo: 300,
      ),
      
      // Conquistas de Matéria
      Conquista(
        id: 'mestre_materia',
        titulo: 'Mestre da Matéria',
        descricao: 'Estude 10 horas na mesma matéria',
        icone: '📚',
        pontosRecompensa: 250,
        tipo: 'materia',
        progressoMaximo: 600, // 10 horas = 600 minutos
      ),
      
      Conquista(
        id: 'poliglota',
        titulo: 'Políglota',
        descricao: 'Estude em 5 matérias diferentes',
        icone: '🌍',
        pontosRecompensa: 180,
        tipo: 'materia',
        progressoMaximo: 5,
      ),
      
      // Conquistas de Streak
      Conquista(
        id: 'semanista',
        titulo: 'Semanista',
        descricao: 'Mantenha streak por 7 dias',
        icone: '📅',
        pontosRecompensa: 120,
        tipo: 'streak',
        progressoMaximo: 7,
      ),
      
      Conquista(
        id: 'mensal',
        titulo: 'Comprometido',
        descricao: 'Mantenha streak por 30 dias',
        icone: '🗓️',
        pontosRecompensa: 500,
        tipo: 'streak',
        progressoMaximo: 30,
      ),
    ];
  }

  // Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'icone': icone,
      'pontosRecompensa': pontosRecompensa,
      'tipo': tipo,
      'desbloqueadaEm': desbloqueadaEm?.toIso8601String(),
      'desbloqueada': desbloqueada,
      'progressoAtual': progressoAtual,
      'progressoMaximo': progressoMaximo,
    };
  }

  // Criar do JSON
  factory Conquista.fromJson(Map<String, dynamic> json) {
    return Conquista(
      id: json['id'],
      titulo: json['titulo'],
      descricao: json['descricao'],
      icone: json['icone'],
      pontosRecompensa: json['pontosRecompensa'],
      tipo: json['tipo'],
      desbloqueadaEm: json['desbloqueadaEm'] != null 
          ? DateTime.parse(json['desbloqueadaEm']) 
          : null,
      desbloqueada: json['desbloqueada'] ?? false,
      progressoAtual: json['progressoAtual'] ?? 0,
      progressoMaximo: json['progressoMaximo'],
    );
  }

  // Copiar com alterações
  Conquista copyWith({
    DateTime? desbloqueadaEm,
    bool? desbloqueada,
    int? progressoAtual,
  }) {
    return Conquista(
      id: id,
      titulo: titulo,
      descricao: descricao,
      icone: icone,
      pontosRecompensa: pontosRecompensa,
      tipo: tipo,
      desbloqueadaEm: desbloqueadaEm ?? this.desbloqueadaEm,
      desbloqueada: desbloqueada ?? this.desbloqueada,
      progressoAtual: progressoAtual ?? this.progressoAtual,
      progressoMaximo: progressoMaximo,
    );
  }

  // Progresso em percentual
  double get progressoPercentual {
    if (progressoMaximo == 0) return 0.0;
    return (progressoAtual / progressoMaximo).clamp(0.0, 1.0);
  }

  // Verificar se foi desbloqueada agora
  bool get foiDesbloqueadaAgora => desbloqueada && desbloqueadaEm != null;

  // Progresso formatado
  String get progressoFormatado => '$progressoAtual/$progressoMaximo';
}
