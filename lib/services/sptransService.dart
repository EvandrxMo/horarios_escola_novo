import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/onibus_model.dart';

class SPTransService {
  final String _token =
      '6bce0694d0acd33ab322bbd6653d5ecf28d98e8af1f3d0dc5d6d06715b2d7ba4';

  final String _baseUrl = 'https://api.olhovivo.sptrans.com.br/v2.1';

  /// Headers com cookie de sessão
  final Map<String, String> _headers = {};

  /// Controle de validade do cookie
  DateTime? _ultimaAutenticacao;

  /// =========================
  /// SINGLETON
  /// =========================
  static final SPTransService _instance = SPTransService._internal();
  factory SPTransService() => _instance;
  SPTransService._internal();

  /// =========================
  /// AUTENTICAÇÃO
  /// =========================
  Future<bool> autenticar() async {
    // Reaproveita cookie por até 50 minutos
    if (_ultimaAutenticacao != null &&
        DateTime.now().difference(_ultimaAutenticacao!).inMinutes < 50 &&
        _headers.containsKey('cookie')) {
      return true;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/Login/Autenticar?token=$_token'),
      );

      if (response.statusCode == 200 && response.body == 'true') {
        final rawCookie = response.headers['set-cookie'];
        if (rawCookie != null) {
          _headers
            ..clear()
            ..['cookie'] = rawCookie.split(';').first;

          _ultimaAutenticacao = DateTime.now();
          return true;
        }
      }

      // Falhou → limpa tudo
      _headers.clear();
      _ultimaAutenticacao = null;
      return false;
    } catch (_) {
      _headers.clear();
      _ultimaAutenticacao = null;
      return false;
    }
  }

  /// =========================
  /// BUSCAR PREVISÃO
  /// =========================
  Future<List<PrevisaoOnibus>> buscarPrevisao(
    String codigoPonto,
    String nomeLinhaFiltro,
  ) async {
    final logado = await autenticar();
    if (!logado) return [];

    try {
      final url = Uri.parse(
        '$_baseUrl/Previsao/Parada?codigoParada=$codigoPonto',
      );

      final response = await http.get(url, headers: _headers);

      // Cookie expirou (comum no iOS)
      if (response.statusCode == 401) {
        _headers.clear();
        _ultimaAutenticacao = null;

        final relogado = await autenticar();
        if (!relogado) return [];

        final retry = await http.get(url, headers: _headers);
        if (retry.statusCode != 200) return [];

        return _parsePrevisao(retry.body, nomeLinhaFiltro);
      }

      if (response.statusCode == 200) {
        return _parsePrevisao(response.body, nomeLinhaFiltro);
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  /// =========================
  /// PARSE DEFENSIVO
  /// =========================
  List<PrevisaoOnibus> _parsePrevisao(
    String body,
    String nomeLinhaFiltro,
  ) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return [];

      final p = decoded['p'];
      if (p is! Map) return [];

      final l = p['l'];
      if (l is! List) return [];

      final List<PrevisaoOnibus> resultados = [];

      for (final linha in l) {
        if (linha is! Map) continue;

        final codigoLinha = linha['c']?.toString() ?? '';
        if (!codigoLinha.contains(nomeLinhaFiltro)) continue;

        final vs = linha['vs'];
        if (vs is! List) continue;

        for (final veiculo in vs) {
          if (veiculo is! Map) continue;

          try {
            resultados.add(
              PrevisaoOnibus.fromJson(
                Map<String, dynamic>.from(veiculo),
                codigoLinha,
              ),
            );
          } catch (_) {
            // ignora veículo inválido
          }
        }
      }

      // Mais próximo primeiro
      resultados.sort(
        (a, b) => a.tempoChegada.compareTo(b.tempoChegada),
      );

      return resultados;
    } catch (_) {
      return [];
    }
  }
}