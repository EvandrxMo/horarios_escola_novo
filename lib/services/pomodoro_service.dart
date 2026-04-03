import 'dart:async';
import 'package:flutter/material.dart';
import '../models/foco_session.dart';
import '../models/conquista.dart';
import '../models/meta_foco.dart';
import '../preferences/focoData.dart';

enum EstadoPomodoro {
  parado,
  estudando,
  pausaCurta,
  pausaLonga,
  concluido,
}

class PomodoroService extends ChangeNotifier {
  static const int _duracaoEstudo = 25; // minutos
  static const int _duracaoPausaCurta = 5; // minutos
  static const int _duracaoPausaLonga = 15; // minutos
  static const int _ciclosParaPausaLonga = 4;

  EstadoPomodoro _estado = EstadoPomodoro.parado;
  int _segundosRestantes = _duracaoEstudo * 60;
  int _cicloAtual = 0;
  int _ciclosCompletos = 0;
  Timer? _timer;
  FocoSession? _sessaoAtual;
  String? _materiaSelecionada;
  bool _notificacoesBloqueadas = false;

  String? _mensagemMeta;
  String? _avisoSaude;
  bool _metaJahAlcancada = false;

  bool get notificacoesBloqueadas => _notificacoesBloqueadas;
  String? get mensagemMeta => _mensagemMeta;
  String? get avisoSaude => _avisoSaude;

  // Getters
  EstadoPomodoro get estado => _estado;
  int get segundosRestantes => _segundosRestantes;
  int get cicloAtual => _cicloAtual;
  int get ciclosCompletos => _ciclosCompletos;
  bool get estaEmExecucao => _timer != null && _timer!.isActive;
  FocoSession? get sessaoAtual => _sessaoAtual;
  String? get materiaSelecionada => _materiaSelecionada;
  List<Conquista> get conquistas => FocoData.getConquistasDesbloqueadas();

  // Getters formatados
  MetaFoco? get metaAtual => FocoData.metaAtual;
  int get metaDiariaMinutos => FocoData.metaAtual?.metaDiariaMinutos ?? 120;
  int get progressoDiarioMinutos => FocoData.metaAtual?.progressoHoje ?? 0;
  int get limiteSaudavelMinutos => 360;
  bool get metaDiariaAlcancada => FocoData.metaAtual?.metaDiariaAlcancada ?? false;
  bool get excedeuLimiteSaudavel => progressoDiarioMinutos > limiteSaudavelMinutos;

  String get tempoFormatado {
    final minutos = _segundosRestantes ~/ 60;
    final segundos = _segundosRestantes % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  double get progressoPercentual {
    int duracaoTotal;
    switch (_estado) {
      case EstadoPomodoro.estudando:
        duracaoTotal = _duracaoEstudo * 60;
        break;
      case EstadoPomodoro.pausaCurta:
        duracaoTotal = _duracaoPausaCurta * 60;
        break;
      case EstadoPomodoro.pausaLonga:
        duracaoTotal = _duracaoPausaLonga * 60;
        break;
      default:
        duracaoTotal = _duracaoEstudo * 60;
    }
    
    if (duracaoTotal == 0) return 0.0;
    return 1.0 - (_segundosRestantes / duracaoTotal);
  }

  String get tituloEstado {
    switch (_estado) {
      case EstadoPomodoro.estudando:
        return '📚 Foco';
      case EstadoPomodoro.pausaCurta:
        return '☕ Pasa Curta';
      case EstadoPomodoro.pausaLonga:
        return '🛌 Pausa Longa';
      case EstadoPomodoro.concluido:
        return '✅ Concluído';
      default:
        return '▶️ Pronto';
    }
  }

  String get descricaoEstado {
    switch (_estado) {
      case EstadoPomodoro.estudando:
        return 'Concentre-se no estudo';
      case EstadoPomodoro.pausaCurta:
        return 'Relaxe um pouco';
      case EstadoPomodoro.pausaLonga:
        return 'Descanse bem';
      case EstadoPomodoro.concluido:
        return 'Ótimo trabalho!';
      default:
        return 'Comece seu ciclo';
    }
  }

  Color get corEstado {
    switch (_estado) {
      case EstadoPomodoro.estudando:
        return Colors.red;
      case EstadoPomodoro.pausaCurta:
        return Colors.green;
      case EstadoPomodoro.pausaLonga:
        return Colors.blue;
      case EstadoPomodoro.concluido:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // Iniciar ou pausar
  void iniciarOuPausar() {
    if (_timer != null && _timer!.isActive) {
      pausar();
    } else {
      iniciar();
    }
  }

  // Iniciar timer
  void iniciar() {
    _notificacoesBloqueadas = true;

    if (_estado == EstadoPomodoro.parado) {
      // Iniciar novo ciclo de estudo
      _estado = EstadoPomodoro.estudando;
      _segundosRestantes = _duracaoEstudo * 60;
      _cicloAtual++;
      
      // Criar nova sessão
      _sessaoAtual = FocoSession.criar(materia: _materiaSelecionada);
    } else if (_estado == EstadoPomodoro.concluido) {
      // Reiniciar para novo ciclo
      _estado = EstadoPomodoro.estudando;
      _segundosRestantes = _duracaoEstudo * 60;
      _cicloAtual++;
      
      _sessaoAtual = FocoSession.criar(materia: _materiaSelecionada);
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_segundosRestantes > 0) {
        _segundosRestantes--;
        
        // Atualizar sessão atual
        if (_sessaoAtual != null && _estado == EstadoPomodoro.estudando) {
          final minutosEstudados = (_duracaoEstudo * 60 - _segundosRestantes) ~/ 60;
          _sessaoAtual = _sessaoAtual!.copyWith(
            duracaoMinutos: minutosEstudados,
            materia: _materiaSelecionada,
          );
        }
        
        notifyListeners();
      } else {
        _finalizarFaseAtual();
      }
    });
    
    notifyListeners();
  }

  // Pausar timer
  void pausar() {
    _timer?.cancel();
    _notificacoesBloqueadas = false;
    notifyListeners();
  }

  // Parar completamente
  void parar() {
    _timer?.cancel();
    _notificacoesBloqueadas = false;
    _timer?.cancel();
    
    // Salvar sessão se estiver em estudo
    if (_sessaoAtual != null && _estado == EstadoPomodoro.estudando) {
      final minutosEstudados = (_duracaoEstudo * 60 - _segundosRestantes) ~/ 60;
      if (minutosEstudados > 0) {
        _sessaoAtual = _sessaoAtual!.copyWith(
          duracaoMinutos: minutosEstudados,
          concluida: true,
          pontosGanhos: minutosEstudados, // 1 ponto por minuto
          fim: DateTime.now(),
        );
        
        FocoData.adicionarSessao(_sessaoAtual!);
        FocoData.salvarTudo();
      }
    }
    
    _timer = null;
    _estado = EstadoPomodoro.parado;
    _segundosRestantes = _duracaoEstudo * 60;
    _sessaoAtual = null;
    
    notifyListeners();
  }

  // Pular para próxima fase
  void pular() {
    _timer?.cancel();
    _finalizarFaseAtual();
  }

  // Finalizar fase atual
  void _finalizarFaseAtual() {
    _timer?.cancel();
    _notificacoesBloqueadas = false;
    
    switch (_estado) {
      case EstadoPomodoro.estudando:
        // Finalizar ciclo de estudo
        if (_sessaoAtual != null) {
          _sessaoAtual = _sessaoAtual!.copyWith(
            duracaoMinutos: _duracaoEstudo,
            concluida: true,
            pontosGanhos: _duracaoEstudo + 50, // 25 min + bônus de ciclo
            fim: DateTime.now(),
          );
          
          FocoData.adicionarSessao(_sessaoAtual!);
          FocoData.salvarTudo();
        }
        
        _ciclosCompletos++;
        
        // Determinar próxima fase
        if (_ciclosCompletos % _ciclosParaPausaLonga == 0) {
          // Pausa longa
          _estado = EstadoPomodoro.pausaLonga;
          _segundosRestantes = _duracaoPausaLonga * 60;
        } else {
          // Pausa curta
          _estado = EstadoPomodoro.pausaCurta;
          _segundosRestantes = _duracaoPausaCurta * 60;
        }
        break;
        
      case EstadoPomodoro.pausaCurta:
        // Voltar para estudo
        _estado = EstadoPomodoro.estudando;
        _segundosRestantes = _duracaoEstudo * 60;
        _cicloAtual++;
        _sessaoAtual = FocoSession.criar(materia: _materiaSelecionada);
        break;
        
      case EstadoPomodoro.pausaLonga:
        // Finalizar sessão completa
        _estado = EstadoPomodoro.concluido;
        _segundosRestantes = 0;
        _sessaoAtual = null;
        break;
        
      default:
        _estado = EstadoPomodoro.parado;
        _segundosRestantes = _duracaoEstudo * 60;
        break;
    }
    
    _atualizarMensagensMetaSaude();
    notifyListeners();
  }

  void _atualizarMensagensMetaSaude() {
    final meta = FocoData.metaAtual;
    if (meta == null) return;

    if (meta.metaDiariaAlcancada && !_metaJahAlcancada) {
      _mensagemMeta = '🏆 Meta diária atingida! Parabéns!';
      _metaJahAlcancada = true;
    } else if (!meta.metaDiariaAlcancada) {
      _mensagemMeta = null;
      _metaJahAlcancada = false;
    }

    if (meta.progressoHoje > limiteSaudavelMinutos) {
      _avisoSaude = '⚠️ Atenção: você ultrapassou ${limiteSaudavelMinutos ~/ 60} h de estudo hoje.';
    } else {
      _avisoSaude = null;
    }
  }

  void definirMetaDiaria(int minutos) {
    FocoData.definirMetaDiaria(minutos);
    _atualizarMensagensMetaSaude();
    notifyListeners();
  }

  void definirMetaSemanal(int ciclos) {
    FocoData.definirMetaSemanal(ciclos);
    notifyListeners();
  }

  // Selecionar matéria
  void selecionarMateria(String? materia) {
    _materiaSelecionada = materia;
    
    // Atualizar sessão atual se estiver em estudo
    if (_sessaoAtual != null && _estado == EstadoPomodoro.estudando) {
      _sessaoAtual = _sessaoAtual!.copyWith(materia: materia);
    }
    
    notifyListeners();
  }

  // Resetar tudo
  void resetar() {
    parar();
    _cicloAtual = 0;
    _ciclosCompletos = 0;
    _materiaSelecionada = null;
    notifyListeners();
  }

  // Obter estatísticas da sessão atual
  Map<String, dynamic> get estatisticasSessaoAtual {
    if (_sessaoAtual == null) return {};
    
    return {
      'materia': _sessaoAtual!.materia ?? 'Sem matéria',
      'cicloAtual': _cicloAtual,
      'ciclosCompletos': _ciclosCompletos,
      'tempoEstudado': _sessaoAtual!.duracaoMinutos,
      'pontosGanhos': _sessaoAtual!.pontosGanhos,
    };
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
