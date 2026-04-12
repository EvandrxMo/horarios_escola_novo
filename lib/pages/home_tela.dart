import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../preferences/appData.dart';
import '../preferences/classesData.dart';
import '../preferences/provasData.dart';
import '../preferences/moodData.dart';
import '../services/sptransService.dart';
import '../services/jumpscare_service.dart';
import '../services/backup_service.dart';
import '../services/remote_messaging_service.dart';
import '../models/onibus_model.dart';
import '../widgets/aniversario.dart';
import '../widgets/brilho_noturno.dart';
import '../widgets/mood_detector_dialog.dart';
import '../widgets/backup_restore_dialog.dart';
import 'classes_modern_tela.dart' as classes;
import 'provas_tela.dart';
import 'onibus_detalhes_tela.dart';
import 'tarefas_tela.dart';
import 'notes_tela.dart';
import 'mood_tracker_tela.dart';
import 'foco_page.dart';
import 'foco_relatorio_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _paginaAtual = 0;
  
  final List<Widget> _paginas = [
    const HomeContent(),
    const classes.ClassesModernPage(),
    const ProvasPage(),
    const TarefasPage(),
    const NotasPage(),
    const MoodTrackerPage(),
    const FocoRelatorioPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _paginaAtual < _paginas.length ? _paginas[_paginaAtual] : _paginas[0],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _paginaAtual < _paginas.length ? _paginaAtual : 0,
        onTap: (index) {
          if (index < 0 || index >= _paginas.length) return;
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
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Relatório',
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
  RemoteInAppBanner? _remoteBanner;
  String? _lastForegroundBannerId;
  bool _carregandoOnibus = false;
  Timer? _timerOnibus;
  bool _aniversarioJaMostrado = false;
  bool _mostrarIda = true; // true = ida, false = volta
  
  // Códigos das paradas
  static const String _paradaIda = '390000299';
  static const String _paradaVolta = '706304';
  static const String _linha = '917H-10';

  String _obterSaudacao() {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Bom dia,';
    if (hora < 18) return 'Boa tarde,';
    return 'Boa noite,';
  }

  @override
  void initState() {
    super.initState();
    RemoteMessagingService.inAppBannerNotifier.addListener(_onRemoteBannerChanged);
    _carregarBannerRemotoPendente();
    _carregarDados();
    _buscarProximoOnibus();
    _verificarAniversario();
    _verificarMoodDoDia();
    _iniciarJumpscare();
    // Atualiza a previsão do ônibus a cada 30 segundos
    _timerOnibus = Timer.periodic(const Duration(seconds: 30), (timer) {
      _buscarProximoOnibus();
    });
  }

  Future<void> _carregarBannerRemotoPendente() async {
    final banner = await RemoteMessagingService.loadPendingBanner();
    if (!mounted || banner == null) return;

    setState(() {
      _remoteBanner = banner;
    });

    await _mostrarBannerEmPrimeiroPlanoSeNecessario(banner);
  }

  void _onRemoteBannerChanged() {
    final banner = RemoteMessagingService.inAppBannerNotifier.value;
    if (!mounted || banner == null) return;

    setState(() {
      _remoteBanner = banner;
    });

    _mostrarBannerEmPrimeiroPlanoSeNecessario(banner);
  }

  Future<void> _mostrarBannerEmPrimeiroPlanoSeNecessario(
    RemoteInAppBanner banner,
  ) async {
    if (!banner.openInForeground) return;
    if (_lastForegroundBannerId == banner.id) return;

    _lastForegroundBannerId = banner.id;
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(banner.title),
        content: Text(banner.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );

    await RemoteMessagingService.markBannerAsViewed(banner.id);
  }

  Future<void> _dispensarBannerRemoto() async {
    await RemoteMessagingService.dismissPendingBanner();
    if (!mounted) return;
    setState(() {
      _remoteBanner = null;
    });
  }

  Future<void> _iniciarJumpscare() async {
    await JumpscareService.checkLastTriggerDate();
    if (!mounted) return;
    JumpscareService.startJumpscareTimer(context);
  }

  Future<void> _abrirPainelTesteRasputin() async {
    final infoInicial = await JumpscareService.getDebugInfo();
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        Map<String, String> info = infoInicial;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> atualizarInfo() async {
              final novoInfo = await JumpscareService.getDebugInfo();
              setSheetState(() {
                info = novoInfo;
              });
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Painel de Teste Rasputin (Debug)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text('Modo: ${info['modo']}'),
                  Text('Janela: ${info['janela']}'),
                  Text('Acionou hoje: ${info['acionouHoje']}'),
                  Text('Último disparo: ${info['ultimoDisparo']}'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            JumpscareService.setModoAgressivo(
                              !JumpscareService.modoAgressivo,
                            );
                            await atualizarInfo();
                          },
                          child: const Text('Alternar Modo'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            JumpscareService.resetFlag();
                            await atualizarInfo();
                          },
                          child: const Text('Resetar Hoje'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await JumpscareService.runCheckNow(context);
                            await atualizarInfo();
                          },
                          child: const Text('Checar Agora'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            JumpscareService.forceJumpscare(context);
                          },
                          child: const Text('Forçar Rasputin'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await BackupService.debugPrepararCenarioHeranca();
                        if (!context.mounted) return;

                        if (!ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('❌ Falha ao preparar teste de herança'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        Navigator.of(context).pop();

                        if (!mounted) return;
                        await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const BackupRestoreDialog(),
                        );
                      },
                      icon: const Icon(Icons.restore_page),
                      label: const Text('Testar Herança de Dados Antigos'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _timerOnibus?.cancel();
    RemoteMessagingService.inAppBannerNotifier.removeListener(
      _onRemoteBannerChanged,
    );
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
    final hoje = DateTime.now();
    final eFimDeSemana =
        hoje.weekday == DateTime.saturday || hoje.weekday == DateTime.sunday;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Início'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'Teste Rasputin (Debug)',
              icon: const Icon(Icons.bug_report),
              onPressed: _abrirPainelTesteRasputin,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Widget de jumpscare do Rasputin
            const BrilhoNoturnoWidget(),

            if (_remoteBanner != null) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade400, width: 1.2),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagem ou ícone
                    if (_remoteBanner!.imageUrl != null && _remoteBanner!.imageUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Image.network(
                            _remoteBanner!.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.amber.shade200,
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.amber.shade800,
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.amber.shade200,
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.amber.shade800,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      )
                    else
                      Icon(Icons.campaign, color: Colors.amber.shade800),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _remoteBanner!.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _remoteBanner!.body,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Dispensar aviso',
                      onPressed: _dispensarBannerRemoto,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            ],
            
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
                      color: moodHoje.mood.cor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: moodHoje.mood.cor.withValues(alpha: 0.5),
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
            
            if (eFimDeSemana)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.beach_access, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Sem aula hoje, pode descansar! 🌴 😎 👍',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (proximaAula != null)
              Card(
                elevation: 2,
                color: proximaAula.cor ?? Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: proximaAula.cor != null 
                        ? (proximaAula.cor!).withValues(alpha: 0.5) 
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
                        ? (proximaProva.cor!).withValues(alpha: 0.5) 
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
                color: _proximoOnibus?.cor.withValues(alpha: 0.1) ?? Colors.white,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const FocoPage()),
          );
        },
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.timer),
        label: const Text('Modo Foco'),
        tooltip: 'Iniciar Modo Foco',
      ),
    );
  }
}