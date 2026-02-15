import 'dart:io';
import 'package:flutter/material.dart';
import '../models/notes_model.dart';
import '../preferences/notesData.dart';

class VisualizarFotoPage extends StatefulWidget {
  final Nota nota;

  const VisualizarFotoPage({super.key, required this.nota});

  @override
  State<VisualizarFotoPage> createState() => _VisualizarFotoPageState();
}

class _VisualizarFotoPageState extends State<VisualizarFotoPage> {
  bool _mostrarInfo = false;
  final _legendaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _legendaController.text = widget.nota.legenda;
  }

  @override
  void dispose() {
    _legendaController.dispose();
    super.dispose();
  }

  // Editar legenda
  void _editarLegenda() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar legenda'),
        content: TextField(
          controller: _legendaController,
          decoration: const InputDecoration(
            hintText: 'Digite uma legenda...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await NotasData.atualizarLegenda(
                widget.nota.id,
                _legendaController.text.trim(),
              );
              
              setState(() {
                widget.nota.legenda = _legendaController.text.trim();
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Legenda atualizada!')),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.nota.caminhoImagem);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.nota.materia),
        actions: [
          IconButton(
            icon: Icon(_mostrarInfo ? Icons.info : Icons.info_outline),
            onPressed: () {
              setState(() {
                _mostrarInfo = !_mostrarInfo;
              });
            },
            tooltip: 'Ver informações',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editarLegenda,
            tooltip: 'Editar legenda',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Foto em fullscreen
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(
                file,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 80,
                          color: Colors.white54,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Erro ao carregar imagem',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Painel de informações (aparece quando clicar no ícone)
          if (_mostrarInfo)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.9),
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Data e hora
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatarDataHora(widget.nota.timestamp),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    // Legenda
                    if (widget.nota.legenda.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          Icon(
                            Icons.label,
                            color: Colors.white70,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Legenda:',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.nota.legenda,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],

                    // Botão editar legenda
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _editarLegenda,
                        icon: const Icon(Icons.edit, size: 18),
                        label: Text(
                          widget.nota.legenda.isEmpty 
                              ? 'Adicionar legenda' 
                              : 'Editar legenda'
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatarDataHora(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year;
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$ano às $hora:$minuto';
  }
}