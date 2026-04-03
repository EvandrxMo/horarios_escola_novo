import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/primeira_tela.dart';
import 'pages/home_tela.dart';
import 'preferences/appData.dart';
import 'services/backup_service.dart';
import 'widgets/backup_restore_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AppData.carregarDados();
  } catch (e, s) {
    debugPrint('Erro ao carregar AppData: $e\n$s');
  }

  runApp(const MeuApp());
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  // ValueNotifier para controlar mudanças de tema
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
    AppData.modoEscuro ? ThemeMode.dark : ThemeMode.light,
  );

  // Método estático para atualizar o tema de qualquer lugar
  static void atualizarTema() {
    themeModeNotifier.value = AppData.modoEscuro ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'App Escolar',
          debugShowCheckedModeBanner: false,
          
          // Configuração de localização
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('pt', 'BR'),
            Locale('en', 'US'),
          ],
          locale: const Locale('pt', 'BR'),
          
          // Tema claro
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.white,
            cardTheme: const CardThemeData(
              color: Colors.white,
              elevation: 2,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: Colors.deepPurple,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
            ),
          ),
          
          // Tema escuro
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardTheme: const CardThemeData(
              color: Color(0xFF1E1E1E),
              elevation: 2,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(0xFF1E1E1E),
              selectedItemColor: Colors.deepPurple,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
            ),
          ),
          
          // Define qual tema usar
          themeMode: themeMode,
          
          home: const VerificadorPrimeiroAcesso(),
        );
      },
    );
  }
}

class VerificadorPrimeiroAcesso extends StatefulWidget {
  const VerificadorPrimeiroAcesso({super.key});

  @override
  State<VerificadorPrimeiroAcesso> createState() => _VerificadorPrimeiroAcessoState();
}

class _VerificadorPrimeiroAcessoState extends State<VerificadorPrimeiroAcesso> {
  bool? _primeiroAcesso;
  bool? _existeBackup;

  @override
  void initState() {
    super.initState();
    _verificarPrimeiroAcesso();
    // Comentado temporariamente para evitar crash na inicialização
    // _iniciarJumpscare();
  }

  Future<void> _verificarPrimeiroAcesso() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nome = prefs.getString('nome');
      final existeBackup = await BackupService.existeBackup();

      setState(() {
        _primeiroAcesso = (nome == null || nome.isEmpty);
        _existeBackup = existeBackup;
      });
    } catch (e, s) {
      debugPrint('Erro em _verificarPrimeiroAcesso: $e\n$s');
      setState(() {
        _primeiroAcesso = true; // assume primeiro acesso em caso de problema
        _existeBackup = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Enquanto verifica, mostra loading
    if (_primeiroAcesso == null || _existeBackup == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Se for primeiro acesso E existir backup, mostra diálogo de restauração
    if (_primeiroAcesso! && _existeBackup!) {
      return FutureBuilder<bool>(
        future: _mostrarDialogoRestauracao(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          // Se restaurou com sucesso, vai para home, senão vai para cadastro
          return snapshot.data == true ? const HomePage() : const PrimeiraTela();
        },
      );
    }

    // Se for primeiro acesso, mostra a tela de cadastro
    // Senão, vai direto para a home
    return _primeiroAcesso! ? const PrimeiraTela() : const HomePage();
  }

  Future<bool> _mostrarDialogoRestauracao() async {
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Não fecha clicando fora
      builder: (context) => const BackupRestoreDialog(),
    );
    
    return resultado ?? false;
  }
}