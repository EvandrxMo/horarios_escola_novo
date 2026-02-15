import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../preferences/appData.dart';
import 'home_tela.dart';

class PrimeiraTela extends StatefulWidget {
  const PrimeiraTela({super.key});

  @override
  State<PrimeiraTela> createState() => _PrimeiraTelaState();
}

class _PrimeiraTelaState extends State<PrimeiraTela> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _raController = TextEditingController();
  final _turmaController = TextEditingController();
  
  String _anoSelecionado = '1°';
  File? _imagemSelecionada;
  DateTime? _dataNascimento;
  final ImagePicker _picker = ImagePicker();

  // Lista de anos
  final List<String> _anos = ['1°', '2°', '3°'];

  // Função para selecionar foto
  Future<void> _selecionarFoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _imagemSelecionada = File(image.path);
      });
    }
  }

  // Função para selecionar data de nascimento
  Future<void> _selecionarData() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2010, 1, 1), // Data inicial sugerida
      firstDate: DateTime(1990, 1, 1), // Mínimo: 1990
      lastDate: DateTime.now(), // Máximo: hoje
      locale:  Locale('pt', 'BR'),
      helpText: 'Selecione sua data de nascimento',
      cancelText: 'Cancelar',
      confirmText: 'OK',
    );

    if (picked != null) {
      setState(() {
        _dataNascimento = picked;
      });
    }
  }

  // Função para salvar e ir para home
  Future<void> _salvarEContinuar() async {
    if (_formKey.currentState!.validate()) {
      // Salva os dados
      AppData.nome = _nomeController.text.trim();
      AppData.ra = _raController.text.trim();
      AppData.ano = _anoSelecionado;
      AppData.turma = _turmaController.text.trim().toUpperCase();
      AppData.fotoPath = _imagemSelecionada?.path;
      AppData.dataNascimento = _dataNascimento;

      await AppData.salvarDados();

      // Navega para a home
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _raController.dispose();
    _turmaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Título
                const Text(
                  'Bem-vindo!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vamos configurar seu perfil',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Foto de perfil
                Center(
                  child: GestureDetector(
                    onTap: _selecionarFoto,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: _imagemSelecionada != null
                              ? FileImage(_imagemSelecionada!)
                              : null,
                          child: _imagemSelecionada == null
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Foto opcional',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Campo Nome
                TextFormField(
                  controller: _nomeController,
                  decoration: InputDecoration(
                    labelText: 'Nome completo',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, insira seu nome';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo RA
                TextFormField(
                  controller: _raController,
                  decoration: InputDecoration(
                    labelText: 'RA',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, insira seu RA';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo Data de Nascimento
                GestureDetector(
                  onTap: _selecionarData,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Data de nascimento (opcional)',
                        hintText: _dataNascimento == null 
                            ? 'Toque para selecionar' 
                            : '${_dataNascimento!.day.toString().padLeft(2, '0')}/${_dataNascimento!.month.toString().padLeft(2, '0')}/${_dataNascimento!.year}',
                        prefixIcon: const Icon(Icons.cake_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      controller: TextEditingController(
                        text: _dataNascimento == null 
                            ? '' 
                            : '${_dataNascimento!.day.toString().padLeft(2, '0')}/${_dataNascimento!.month.toString().padLeft(2, '0')}/${_dataNascimento!.year}',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Ano e Turma na mesma linha
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dropdown Ano
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _anoSelecionado,
                        decoration: InputDecoration(
                          labelText: 'Ano',
                          prefixIcon: const Icon(Icons.school_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _anos.map((ano) {
                          return DropdownMenuItem(
                            value: ano,
                            child: Text(ano),
                          );
                        }).toList(),
                        onChanged: (valor) {
                          setState(() {
                            _anoSelecionado = valor!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Campo Turma
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _turmaController,
                        decoration: InputDecoration(
                          labelText: 'Turma',
                          hintText: 'A',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          counterText: '', // Remove o contador "1/1"
                        ),
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        onChanged: (value) {
                          // Garante que sempre seja maiúscula
                          _turmaController.value = TextEditingValue(
                            text: value.toUpperCase(),
                            selection: _turmaController.selection,
                          );
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Obrigatório';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Botão Continuar
                ElevatedButton(
                  onPressed: _salvarEContinuar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}