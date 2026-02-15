import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../preferences/notesData.dart';
import '../models/notes_model.dart';
import 'foto_view_tela.dart';

class GaleriaMateriaPage extends StatefulWidget {
  final String materia;

  const GaleriaMateriaPage({super.key, required this.materia});

  @override
  State<GaleriaMateriaPage> createState() => _GaleriaMateriaPageState();
}

class _GaleriaMateriaPageState extends State<GaleriaMateriaPage> {
  final ImagePicker _picker = ImagePicker();
  List<Nota> _notas = [];

  @override
  void initState() {
    super.initState();
    _carregarNotas();
  }

  void _carregarNotas() {
    setState(() {
      _notas = NotasData.obterNotasPorMateria(widget.materia);
    });
  }

  // Adicionar foto da câmera
  Future<void> _adicionarFotoCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image != null) {
      await _salvarFoto(image);
    }
  }

  // Adicionar foto da galeria
  Future<void> _adicionarFotoGaleria() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image != null) {
      await _salvarFoto(image);
    }
  }

  // Salvar foto no diretório do app
  Future<void> _salvarFoto(XFile image) async {
    try {
      // Obtém o diretório de documentos do app
      final Directory appDir = await getApplicationDocumentsDirectory();
      
      // Cria pasta para notas se não existir
      final Directory notasDir = Directory('${appDir.path}/notas');
      if (!await notasDir.exists()) {
        await notasDir.create(recursive: true);
      }

      // Gera nome único para a foto
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension =path.extension(image.path).isNotEmpty? path.extension(image.path): '.jpg';
      final String novoNome = 'nota_$timestamp$extension';
      final String caminhoDestino = '${notasDir.path}/$novoNome';

      // Copia a foto para o diretório do app
      final File imagemOriginal = File(image.path);
      await imagemOriginal.copy(caminhoDestino);

      // Cria objeto Nota
      final nota = Nota(
        id: timestamp,
        materia: widget.materia,
        caminhoImagem: caminhoDestino,
        timestamp: DateTime.now(),
        legenda: '',
      );

      // Adiciona e salva
      NotasData.adicionarNota(nota);
      await NotasData.salvarNotas();

      _carregarNotas();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto adicionada!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar foto: $e')),
      );
    }
  }

  // Deletar foto
  Future<void> _deletarFoto(Nota nota) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar foto?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        // Deleta o arquivo
        final file = File(nota.caminhoImagem);
        if (await file.exists()) {
          await file.delete();
        }

        // Remove da lista
        NotasData.removerNota(nota.id);
        await NotasData.salvarNotas();

        _carregarNotas();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto deletada')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao deletar foto: $e')),
        );
      }
    }
  }

  // Mostrar opções de adicionar foto
  void _mostrarOpcoesAdicionar() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.deepPurple),
              title: const Text('Tirar foto'),
              onTap: () {
                Navigator.pop(context);
                _adicionarFotoCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.deepPurple),
              title: const Text('Escolher da galeria'),
              onTap: () {
                Navigator.pop(context);
                _adicionarFotoGaleria();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.grey),
              title: const Text('Cancelar'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true); // Retorna true para atualizar a lista anterior
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.materia),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: _notas.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhuma foto ainda',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toque no + para adicionar',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _notas.length,
                itemBuilder: (context, index) {
                  final nota = _notas[index];
                  final file = File(nota.caminhoImagem);

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: InkWell(
                      onTap: () async {
                        final resultado = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VisualizarFotoPage(nota: nota),
                          ),
                        );

                        if (resultado == true) {
                          _carregarNotas();
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            // Thumbnail da foto
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                file,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Informações
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatarData(nota.timestamp),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatarHora(nota.timestamp),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (nota.legenda.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      nota.legenda,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Botão deletar
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deletarFoto(nota),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _mostrarOpcoesAdicionar,
          backgroundColor: Colors.deepPurple,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year;
    return '$dia/$mes/$ano';
  }

  String _formatarHora(DateTime data) {
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
  }
}