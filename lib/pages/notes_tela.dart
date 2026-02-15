import 'package:flutter/material.dart';
import '../preferences/notesData.dart';
import '../preferences/classesData.dart';
import 'galeria_tela.dart';

class NotasPage extends StatefulWidget {
  const NotasPage({super.key});

  @override
  State<NotasPage> createState() => _NotasPageState();
}

class _NotasPageState extends State<NotasPage> {
  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    await NotasData.carregarNotas();
    setState(() {});
  }

  // Obter lista de matérias únicas cadastradas
  List<String> _obterMaterias() {
    final materias = <String>{};
    
    // Adiciona todas as matérias cadastradas em Classes
    for (var aula in ClassesData.aulas.values) {
      materias.add(aula.materia);
    }
    
    return materias.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final materias = _obterMaterias();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notas'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: materias.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma matéria cadastrada',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cadastre aulas na aba Horários\npara criar pastas de notas',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: materias.length,
              itemBuilder: (context, index) {
                final materia = materias[index];
                final quantidadeNotas = NotasData.contarNotasPorMateria(materia);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      child: const Icon(
                        Icons.folder,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      materia,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      quantidadeNotas == 0
                          ? 'Nenhuma foto'
                          : quantidadeNotas == 1
                              ? '1 foto'
                              : '$quantidadeNotas fotos',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final resultado = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GaleriaMateriaPage(
                            materia: materia,
                          ),
                        ),
                      );

                      // Atualiza a lista se houve mudanças
                      if (resultado == true) {
                        setState(() {});
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}