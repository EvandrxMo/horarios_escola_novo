class Nota {
  final String id;
  final String materia; // Nome da matéria
  final String caminhoImagem; // Caminho da foto no celular
  final DateTime timestamp; // Data/hora que a foto foi tirada
  String legenda; // Legenda editável

  Nota({
    required this.id,
    required this.materia,
    required this.caminhoImagem,
    required this.timestamp,
    this.legenda = '',
  });

  // Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'materia': materia,
      'caminhoImagem': caminhoImagem,
      'timestamp': timestamp.toIso8601String(),
      'legenda': legenda,
    };
  }

  // Criar Nota a partir de JSON
  factory Nota.fromJson(Map<String, dynamic> json) {
    return Nota(
      id: json['id'] as String,
      materia: json['materia'] as String,
      caminhoImagem: json['caminhoImagem'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      legenda: json['legenda'] as String? ?? '',
    );
  }
}