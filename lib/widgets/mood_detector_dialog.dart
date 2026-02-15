import 'package:flutter/material.dart';
import '../models/mood_model.dart';
import '../preferences/moodData.dart';

class MoodDetectorDialog extends StatefulWidget {
  const MoodDetectorDialog({super.key});

  @override
  State<MoodDetectorDialog> createState() => _MoodDetectorDialogState();
}

class _MoodDetectorDialogState extends State<MoodDetectorDialog>
    with SingleTickerProviderStateMixin {
  Mood? _moodSelecionado;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _salvarMood() async {
    if (_moodSelecionado != null) {
      await MoodData.salvarMood(_moodSelecionado!);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
              maxWidth: 400,
            ),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.deepPurple.shade50,
                  Colors.white,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícone de topo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mood,
                    size: 40,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Título
                const Text(
                  'Como você está hoje?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selecione o emoji que melhor representa seu humor',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Grid de emojis com scroll
                Flexible(
                  child: SingleChildScrollView(
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: Mood.moods.length,
                      itemBuilder: (context, index) {
                        final mood = Mood.moods[index];
                        final isSelected = _moodSelecionado == mood;
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _moodSelecionado = mood;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? mood.cor.withOpacity(0.2)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? mood.cor : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: mood.cor.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Imagem no lugar do emoji
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        mood.imagePath,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          // Fallback para emoji se a imagem não carregar
                                          return Center(
                                            child: Text(
                                              mood.emoji,
                                              style: TextStyle(
                                                fontSize: isSelected ? 40 : 36,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Nome do mood
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                    mood.nome,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? mood.cor
                                          : Colors.grey.shade600,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Botão de confirmar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _moodSelecionado != null ? _salvarMood : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _moodSelecionado?.cor ?? Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: _moodSelecionado != null ? 4 : 0,
                    ),
                    child: Text(
                      _moodSelecionado != null
                          ? 'Confirmar ${_moodSelecionado!.nome}'
                          : 'Selecione um humor',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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