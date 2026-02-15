import 'package:flutter/material.dart';

class PrevisaoOnibus {
  final String linha;
  final String prefixo;
  final String horarioChegada;
  final int tempoChegada;
  final bool acessivel;
  final double? latitude;
  final double? longitude;

  PrevisaoOnibus({
    required this.linha,
    required this.prefixo,
    required this.horarioChegada,
    required this.tempoChegada,
    required this.acessivel,
    this.latitude,
    this.longitude,
  });

  /// Aceita Map<dynamic, dynamic> SEM quebrar
  factory PrevisaoOnibus.fromJson(
    Map<dynamic, dynamic> json,
    String codigoLinha,
  ) {
    final Map<String, dynamic> data =
        json.map((key, value) => MapEntry(key.toString(), value));

    final String horario = data['t']?.toString() ?? '0';
    int segundos = 0;

    // Caso venha como HH:MM
    if (horario.contains(':')) {
      try {
        final partes = horario.split(':');
        final horaChegada = int.parse(partes[0]);
        final minutoChegada = int.parse(partes[1]);

        final agora = DateTime.now();
        var chegada = DateTime(
          agora.year,
          agora.month,
          agora.day,
          horaChegada,
          minutoChegada,
        );

        if (chegada.isBefore(agora)) {
          chegada = chegada.add(const Duration(days: 1));
        }

        segundos = chegada.difference(agora).inSeconds;
      } catch (_) {
        segundos = 0;
      }
    } else {
      // Caso venha como segundos
      segundos = int.tryParse(horario) ?? 0;
    }

    return PrevisaoOnibus(
      linha: codigoLinha,
      prefixo: data['p']?.toString() ?? '',
      horarioChegada: horario,
      tempoChegada: segundos,
      acessivel: data['a'] == true,
      latitude: _toDouble(data['py']),
      longitude: _toDouble(data['px']),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  String get tempoFormatado {
    if (tempoChegada < 60) return 'Chegando';

    final minutos = tempoChegada ~/ 60;

    if (minutos < 60) return '$minutos min';

    final horas = minutos ~/ 60;
    final resto = minutos % 60;
    return '${horas}h ${resto}min';
  }

  String get tempoLongo {
    if (tempoChegada < 60) return 'Chegando agora';

    final minutos = tempoChegada ~/ 60;

    if (minutos == 1) return '1 minuto';
    if (minutos < 60) return '$minutos minutos';

    final horas = minutos ~/ 60;
    final resto = minutos % 60;

    if (resto == 0) {
      return horas == 1 ? '1 hora' : '$horas horas';
    }

    return '$horas h $resto min';
  }

  Color get cor {
    if (tempoChegada < 180) return Colors.red;
    if (tempoChegada < 600) return Colors.orange;
    return Colors.green;
  }
}
