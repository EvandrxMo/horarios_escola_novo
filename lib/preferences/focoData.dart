import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/foco_session.dart';
import '../models/conquista.dart';
import '../models/meta_foco.dart';

class FocoData {
  static List<FocoSession> _sessoes = [];
  static List<Conquista> _conquistas = [];
  static MetaFoco? _metaAtual;
  static int _pontosTotais = 0;
  static int _streakDias = 0;
  static DateTime? _ultimoDiaEstudo;

  // Getters
  static List<FocoSession> get sessoes => List.unmodifiable(_sessoes);
  static List<Conquista> get conquistas => List.unmodifiable(_conquistas);
  static MetaFoco? get metaAtual => _metaAtual;
  static int get pontosTotais => _pontosTotais;

  static void definirMetaDiaria(int minutos) {
    if (_metaAtual != null) {
      _metaAtual = _metaAtual!.copyWith(
        metaDiariaMinutos: minutos,
        ultimaAtualizacao: DateTime.now(),
      );
      salvarMeta();
    }
  }

  static void definirMetaSemanal(int ciclos) {
    if (_metaAtual != null) {
      _metaAtual = _metaAtual!.copyWith(
        metaSemanalCiclos: ciclos,
        ultimaAtualizacao: DateTime.now(),
      );
      salvarMeta();
    }
  }
  static int get streakDias => _streakDias;
  static DateTime? get ultimoDiaEstudo => _ultimoDiaEstudo;

  // Inicializar dados
  static Future<void> inicializarDados() async {
    await _carregarSessoes();
    await _carregarConquistas();
    await _carregarMeta();
    await _carregarEstatisticas();
    
    // Inicializar conquistas se não existirem
    if (_conquistas.isEmpty) {
      _conquistas = Conquista.conquistasBase();
      await salvarConquistas();
    }
    
    // Inicializar meta se não existir
    if (_metaAtual == null) {
      _metaAtual = MetaFoco.criarPadrao();
      await salvarMeta();
    }
  }

  // Carregar sessões
  static Future<void> _carregarSessoes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessoesJson = prefs.getString('foco_sessoes') ?? '[]';
      final List<dynamic> sessoesList = json.decode(sessoesJson);
      
      _sessoes = sessoesList
          .map((json) => FocoSession.fromJson(json))
          .toList();
    } catch (e) {
      _sessoes = [];
    }
  }

  // Carregar conquistas
  static Future<void> _carregarConquistas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conquistasJson = prefs.getString('foco_conquistas') ?? '[]';
      final List<dynamic> conquistasList = json.decode(conquistasJson);
      
      _conquistas = conquistasList
          .map((json) => Conquista.fromJson(json))
          .toList();
    } catch (e) {
      _conquistas = [];
    }
  }

  // Carregar meta
  static Future<void> _carregarMeta() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metaJson = prefs.getString('foco_meta');
      
      if (metaJson != null) {
        _metaAtual = MetaFoco.fromJson(json.decode(metaJson));
      }
    } catch (e) {
      _metaAtual = null;
    }
  }

  // Carregar estatísticas
  static Future<void> _carregarEstatisticas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _pontosTotais = prefs.getInt('foco_pontos_totais') ?? 0;
      _streakDias = prefs.getInt('foco_streak_dias') ?? 0;
      
      final ultimoDiaStr = prefs.getString('foco_ultimo_dia');
      if (ultimoDiaStr != null) {
        _ultimoDiaEstudo = DateTime.parse(ultimoDiaStr);
      }
    } catch (e) {
      _pontosTotais = 0;
      _streakDias = 0;
      _ultimoDiaEstudo = null;
    }
  }

  // Salvar sessões
  static Future<void> salvarSessoes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessoesJson = json.encode(
        _sessoes.map((sessao) => sessao.toJson()).toList(),
      );
      await prefs.setString('foco_sessoes', sessoesJson);
    } catch (e) {
      // Erro ao salvar sessões
    }
  }

  // Salvar conquistas
  static Future<void> salvarConquistas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conquistasJson = json.encode(
        _conquistas.map((conquista) => conquista.toJson()).toList(),
      );
      await prefs.setString('foco_conquistas', conquistasJson);
    } catch (e) {
      // Erro ao salvar conquistas
    }
  }

  // Salvar meta
  static Future<void> salvarMeta() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_metaAtual != null) {
        await prefs.setString('foco_meta', json.encode(_metaAtual!.toJson()));
      }
    } catch (e) {
      // Erro ao salvar meta
    }
  }

  // Salvar estatísticas
  static Future<void> salvarEstatisticas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('foco_pontos_totais', _pontosTotais);
      await prefs.setInt('foco_streak_dias', _streakDias);
      
      if (_ultimoDiaEstudo != null) {
        await prefs.setString('foco_ultimo_dia', _ultimoDiaEstudo!.toIso8601String());
      }
    } catch (e) {
      // Erro ao salvar estatísticas
    }
  }

  // Adicionar nova sessão
  static void adicionarSessao(FocoSession sessao) {
    _sessoes.add(sessao);
    _atualizarEstatisticasSessao(sessao);
    _verificarConquistas(sessao);
  }

  // Atualizar sessão existente
  static void atualizarSessao(FocoSession sessaoAtualizada) {
    final index = _sessoes.indexWhere((s) => s.id == sessaoAtualizada.id);
    if (index != -1) {
      _sessoes[index] = sessaoAtualizada;
      _atualizarEstatisticasSessao(sessaoAtualizada);
      _verificarConquistas(sessaoAtualizada);
    }
  }

  // Atualizar estatísticas com base na sessão
  static void _atualizarEstatisticasSessao(FocoSession sessao) {
    if (sessao.concluida) {
      _pontosTotais += sessao.pontosGanhos;
      
      // Atualizar streak
      final hoje = DateTime.now();
      final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
      
      if (_ultimoDiaEstudo == null) {
        _streakDias = 1;
        _ultimoDiaEstudo = hojeSemHora;
      } else {
        final diferencaDias = hojeSemHora.difference(_ultimoDiaEstudo!).inDays;
        
        if (diferencaDias == 0) {
          // Mesmo dia - não altera streak
        } else if (diferencaDias == 1) {
          // Dia seguinte - incrementa streak
          _streakDias++;
          _ultimoDiaEstudo = hojeSemHora;
        } else {
          // Quebrou o streak - reinicia
          _streakDias = 1;
          _ultimoDiaEstudo = hojeSemHora;
        }
      }
      
      // Atualizar meta
      if (_metaAtual != null) {
        _metaAtual = _metaAtual!.adicionarProgressoDiario(sessao.duracaoMinutos);
        _metaAtual = _metaAtual!.adicionarProgressoSemanal(sessao.ciclosCompletos);
      }
    }
  }

  // Verificar conquistas desbloqueadas
  static void _verificarConquistas(FocoSession sessao) {
    for (int i = 0; i < _conquistas.length; i++) {
      final conquista = _conquistas[i];
      if (!conquista.desbloqueada) {
        final conquistaDesbloqueada = _verificarConquistaIndividual(conquista, sessao);
        if (conquistaDesbloqueada != null) {
          _conquistas[i] = conquistaDesbloqueada;
          _pontosTotais += conquistaDesbloqueada.pontosRecompensa;
        }
      }
    }
  }

  // Verificar conquista individual
  static Conquista? _verificarConquistaIndividual(Conquista conquista, FocoSession sessao) {
    switch (conquista.tipo) {
      case 'ciclo':
        if (sessao.ciclosCompletos >= conquista.progressoMaximo) {
          return conquista.copyWith(
            desbloqueada: true,
            desbloqueadaEm: DateTime.now(),
            progressoAtual: conquista.progressoMaximo,
          );
        }
        break;
        
      case 'tempo':
        final tempoTotal = _sessoes
            .where((s) => s.concluida)
            .fold<int>(0, (sum, s) => sum + s.duracaoMinutos);
        
        if (tempoTotal >= conquista.progressoMaximo) {
          return conquista.copyWith(
            desbloqueada: true,
            desbloqueadaEm: DateTime.now(),
            progressoAtual: tempoTotal,
          );
        }
        break;
        
      case 'streak':
        if (_streakDias >= conquista.progressoMaximo) {
          return conquista.copyWith(
            desbloqueada: true,
            desbloqueadaEm: DateTime.now(),
            progressoAtual: _streakDias,
          );
        }
        break;
        
      case 'materia':
        if (conquista.id == 'mestre_materia') {
          // Verificar tempo total por matéria
          final tempoPorMateria = <String, int>{};
          for (final s in _sessoes.where((s) => s.concluida && s.materia != null)) {
            tempoPorMateria[s.materia!] = (tempoPorMateria[s.materia!] ?? 0) + s.duracaoMinutos;
          }
          
          final maxTempoMateria = tempoPorMateria.values.fold(0, (max, tempo) => tempo > max ? tempo : max);
          if (maxTempoMateria >= conquista.progressoMaximo) {
            return conquista.copyWith(
              desbloqueada: true,
              desbloqueadaEm: DateTime.now(),
              progressoAtual: maxTempoMateria,
            );
          }
        } else if (conquista.id == 'poliglota') {
          // Verificar matérias diferentes estudadas
          final materiasEstudadas = _sessoes
              .where((s) => s.concluida && s.materia != null)
              .map((s) => s.materia!)
              .toSet()
              .length;
          
          if (materiasEstudadas >= conquista.progressoMaximo) {
            return conquista.copyWith(
              desbloqueada: true,
              desbloqueadaEm: DateTime.now(),
              progressoAtual: materiasEstudadas,
            );
          }
        }
        break;
    }
    
    return null;
  }

  // Salvar todos os dados
  static Future<void> salvarTudo() async {
    await Future.wait([
      salvarSessoes(),
      salvarConquistas(),
      salvarMeta(),
      salvarEstatisticas(),
    ]);
  }

  // Obter sessões do dia
  static List<FocoSession> getSessoesDoDia(DateTime dia) {
    final diaAlvo = DateTime(dia.year, dia.month, dia.day);
    final proximoDia = diaAlvo.add(const Duration(days: 1));
    
    return _sessoes.where((sessao) {
      return sessao.inicio.isAfter(diaAlvo.subtract(const Duration(microseconds: 1))) &&
             sessao.inicio.isBefore(proximoDia);
    }).toList();
  }

  // Obter sessões da semana
  static List<FocoSession> getSessoesDaSemana(DateTime data) {
    final inicioSemana = data.subtract(Duration(days: data.weekday - 1));
    final fimSemana = inicioSemana.add(const Duration(days: 7));
    
    return _sessoes.where((sessao) {
      return sessao.inicio.isAfter(inicioSemana.subtract(const Duration(microseconds: 1))) &&
             sessao.inicio.isBefore(fimSemana);
    }).toList();
  }

  // Obter conquistas desbloqueadas
  static List<Conquista> getConquistasDesbloqueadas() {
    return _conquistas.where((c) => c.desbloqueada).toList();
  }
}
