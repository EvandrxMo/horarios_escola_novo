import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:async';
import '../preferences/appData.dart';
import '../preferences/classesData.dart';
import '../preferences/provasData.dart';
import '../preferences/moodData.dart';
import '../services/sptransService.dart';
import '../models/onibus_model.dart';
import '../widgets/aniversario.dart';
import '../widgets/brilho_noturno.dart';
import '../widgets/mood_detector_dialog.dart';
import 'classes_tela.dart';
import 'provas_tela.dart';
import 'onibus_detalhes_tela.dart';
import 'tarefas_tela.dart';
import 'notes_tela.dart';
import 'mood_tracker_tela.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _paginaAtual = 0;
  
  final List<Widget> _paginas = [
    const HomeContent(),
    const ClassesPage(),
    const ProvasPage(),
    const TarefasPage(),
    const NotasPage(),
    const MoodTrackerPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _paginas[_paginaAtual],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _paginaAtual,
        onTap: (index) {
          setState(() {
            _paginaAtual = index;
          });
        },
        selectedItemColor: Colors.deepPurple,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Aulas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Provas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt),
            label: 'Tarefas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note),
            label: 'Notas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mood),
            label: 'Humor',
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final SPTransService _onibusService = SPTransService();
  PrevisaoOnibus? _proximoOnibus;
  bool _carregandoOnibus = false;
  Timer? _timerOnibus;
  bool _aniversarioJaMostrado = false;
  bool _mostrarIda = true; // true = ida, false = volta
  
  // Códigos das paradas
  static const String _paradaIda = '390000299';
  static const String _paradaVolta = '706304';
  static const String _linha = '917H-10';

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _buscarProximoOnibus();
    _verificarAniversario();
    _verificarMoodDoDia();
    // Atualiza a previsão do ônibus a cada 30 segundos
    _timerOnibus = Timer.periodic(const Duration(seconds: 30), (timer) {
      _buscarProximoOnibus();
    });
  }

  @override
  void dispose() {
    _timerOnibus?.cancel();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    await AppData.carregarDados();
    await ClassesData.carregarAulas();
    await ProvasData.carregarProvas();
    await MoodData.carregarMoods();
    setState(() {});
    _verificarAniversario();
  }

  Future<void> _buscarProximoOnibus() async {
    if (!mounted) return;
    
    setState(() {
      _carregandoOnibus = true;
    });

    try {
      final parada = _mostrarIda ? _paradaIda : _paradaVolta;
      final previsoes = await _onibusService.buscarPrevisao(parada, _linha);
      
      if (!mounted) return;
      
      setState(() {
        _proximoOnibus = previsoes.isNotEmpty ? previsoes.first : null;
        _carregandoOnibus = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _proximoOnibus = null;
        _carregandoOnibus = false;
      });
    }
  }

  void _alternarDirecao() {
    setState(() {
      _mostrarIda = !_mostrarIda;
    });
    _buscarProximoOnibus();
  }

  void _verificarAniversario() {
    // Só mostra uma vez por sessão
    if (_aniversarioJaMostrado) return;
    
    // Verifica se hoje é aniversário
    if (AppData.isAniversarioHoje && AppData.idade != null) {
      _aniversarioJaMostrado = true;
      
      // Mostra a animação após um pequeno delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AniversarioAnimacao(
              nome: AppData.nome,
              idade: AppData.idade!,
              onClose: () => Navigator.of(context).pop(),
            ),
          );
        }
      });
    }
  }

  Future<void> _verificarMoodDoDia() async {
    // Aguarda um pouco para não conflitar com o aniversário
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    final isPrimeiraAbertura = await MoodData.isPrimeiraAberturaDoDia();
    
    if (isPrimeiraAbertura) {
      // Registra a abertura
      await MoodData.registrarAbertura();
      
      // Mostra o mood detector
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const MoodDetectorDialog(),
        ).then((_) {
          // Atualiza a tela após selecionar o mood
          setState(() {});
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final proximaAula = ClassesData.obterProximaAula();
    final proximaProva = ProvasData.obterProximaProva();
    final moodHoje = MoodData.getMoodHoje();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Início'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Widget de brilho
            const BrilhoNoturnoWidget(),
            
            // Header com foto e saudação
            Row(
              children: [
                // Foto de perfil
                if (AppData.fotoPath != null)
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: FileImage(File(AppData.fotoPath!)),
                  )
                else
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[300],
                    child: const Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.grey,
                    ),
                  ),
                const SizedBox(width: 16),
                
                // Saudação
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _obterSaudacao(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        AppData.nome.split(' ').first, // Primeiro nome
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${AppData.ano} ${AppData.turma}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Mood de hoje
                if (moodHoje != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: moodHoje.mood.cor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: moodHoje.mood.cor.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Image.asset(
                          moodHoje.mood.imagePath,
                          width: 35,
                          height: 35,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hoje',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),

            // Card da próxima aula
            const Text(
              'Próxima aula',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            if (proximaAula != null)
              Card(
                elevation: 2,
                color: proximaAula.cor ?? Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: proximaAula.cor != null 
                        ? (proximaAula.cor!).withOpacity(0.5) 
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.school,
                            color: proximaAula.cor != null 
                                ? Colors.black87 
                                : Colors.deepPurple,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              proximaAula.materia,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (proximaAula.professor.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 16, color: Colors.black54),
                            const SizedBox(width: 4),
                            Text(
                              proximaAula.professor,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.black54),
                          const SizedBox(width: 4),
                          Text(
                            '${proximaAula.diaSemana}, ${proximaAula.horario}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey[400]),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Nenhuma aula cadastrada',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 32),

            // Card da próxima prova
            const Text(
              'Próxima prova',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            if (proximaProva != null)
              Card(
                elevation: 2,
                color: proximaProva.cor ?? Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: proximaProva.cor != null 
                        ? (proximaProva.cor!).withOpacity(0.5) 
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.assignment,
                            color: proximaProva.cor != null 
                                ? Colors.black87 
                                : Colors.deepPurple,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              proximaProva.materia,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.black54),
                          const SizedBox(width: 4),
                          Text(
                            '${proximaProva.dataFormatada} - ${proximaProva.horario}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      if (proximaProva.conteudo.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Conteúdo:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          proximaProva.conteudo,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey[400]),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Nenhuma prova cadastrada',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 32),

            // Card do próximo ônibus
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Próximo ônibus',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Botão de alternância Ida/Volta
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (!_mostrarIda) _alternarDirecao();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _mostrarIda ? Colors.deepPurple : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: _mostrarIda ? Colors.white : Colors.black54,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Ida',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: _mostrarIda ? FontWeight.bold : FontWeight.normal,
                                  color: _mostrarIda ? Colors.white : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (_mostrarIda) _alternarDirecao();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: !_mostrarIda ? Colors.deepPurple : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.arrow_back,
                                size: 16,
                                color: !_mostrarIda ? Colors.white : Colors.black54,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Volta',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: !_mostrarIda ? FontWeight.bold : FontWeight.normal,
                                  color: !_mostrarIda ? Colors.white : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnibusDetalhesPage(),
                  ),
                );
              },
              child: Card(
                elevation: 2,
                color: _proximoOnibus?.cor.withOpacity(0.1) ?? Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _proximoOnibus?.cor ?? Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _carregandoOnibus
                      ? const Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Buscando previsão...'),
                          ],
                        )
                      : _proximoOnibus != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.directions_bus,
                                      color: _proximoOnibus!.cor,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Linha ${_proximoOnibus!.linha}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            _mostrarIda ? 'Ida' : 'Volta',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _proximoOnibus!.cor,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _proximoOnibus!.tempoFormatado,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.place, size: 16, color: Colors.black54),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Ponto ${_mostrarIda ? _paradaIda : _paradaVolta}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Row(
                                  children: [
                                    Icon(Icons.touch_app, size: 14, color: Colors.black54),
                                    SizedBox(width: 4),
                                    Text(
                                      'Toque para ver mais detalhes',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.grey[400]),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Nenhuma previsão disponível',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _obterSaudacao() {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Bom dia,';
    if (hora < 18) return 'Boa tarde,';
    return 'Boa noite,';
  }
}