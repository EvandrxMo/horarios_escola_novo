import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../preferences/provasData.dart';
import '../models/prova_model.dart';
import '../services/notificationsService.dart';
import 'package:intl/date_symbol_data_local.dart';

class ProvasPage extends StatefulWidget {
  const ProvasPage({super.key});

  @override
  State<ProvasPage> createState() => _ProvasPageState();
}

class _ProvasPageState extends State<ProvasPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR', null);
    NotificacoesService.inicializar();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    await ProvasData.carregarProvas();
    setState(() {});
  }

  // Mostrar lista de todas as provas
  void _mostrarListaProvas() {
    if (ProvasData.provas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma prova cadastrada')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Provas Cadastradas'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: ProvasData.provas.length,
            itemBuilder: (context, index) {
              final prova = ProvasData.provas[index];
              return Card(
                color: prova.cor ?? Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(
                    prova.materia,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${prova.dataFormatada} - ${prova.horario}'),
                      if (prova.conteudo.isNotEmpty)
                        Text(
                          prova.conteudo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      if (prova.diasAntesLembrete != null && prova.diasAntesLembrete! > 0)
                        Row(
                          children: [
                            const Icon(Icons.notifications_active, size: 12, color: Colors.deepPurple),
                            const SizedBox(width: 4),
                            Text(
                              prova.lembretesDiarios 
                                ? 'Lembretes diários (${prova.diasAntesLembrete} dias antes)'
                                : 'Lembrete ${prova.diasAntesLembrete} dia(s) antes',
                              style: const TextStyle(fontSize: 11, color: Colors.deepPurple),
                            ),
                          ],
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.pop(context);
                          _editarProva(prova);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          Navigator.pop(context);
                          _removerProva(prova.chave);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // Adicionar nova prova
  void _adicionarProva({DateTime? dataSelecionada}) {
    final materiaController = TextEditingController();
    final horarioController = TextEditingController();
    final conteudoController = TextEditingController();
    DateTime dataProva = dataSelecionada ?? DateTime.now();
    Color? corSelecionada;
    int? diasAntesLembrete;
    bool lembretesDiarios = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nova Prova'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campo Matéria
                TextField(
                  controller: materiaController,
                  decoration: const InputDecoration(
                    labelText: 'Matéria',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Seletor de Data
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Data da Prova'),
                  subtitle: Text(
                    '${dataProva.day.toString().padLeft(2, '0')}/${dataProva.month.toString().padLeft(2, '0')}/${dataProva.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final data = await showDatePicker(
                      context: context,
                      initialDate: dataProva,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (data != null) {
                      setDialogState(() {
                        dataProva = data;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),

                // Campo Horário
                TextField(
                  controller: horarioController,
                  decoration: const InputDecoration(
                    labelText: 'Horário (ex: 14:00)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Campo Conteúdo
                TextField(
                  controller: conteudoController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Conteúdo',
                    border: OutlineInputBorder(),
                    hintText: 'Digite os tópicos que cairão na prova',
                  ),
                ),
                const SizedBox(height: 16),

                // Seletor de cor
                const Text('Cor (opcional):', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildCorOption(null, corSelecionada, setDialogState, (cor) => corSelecionada = cor),
                    ...[
                      Colors.red[300]!,
                      Colors.blue[300]!,
                      Colors.green[300]!,
                      Colors.yellow[300]!,
                      Colors.purple[300]!,
                      Colors.orange[300]!,
                      Colors.pink[300]!,
                      Colors.teal[300]!,
                    ].map((cor) => _buildCorOption(cor, corSelecionada, setDialogState, (c) => corSelecionada = c)),
                  ],
                ),
                const SizedBox(height: 20),

                const Divider(),
                const SizedBox(height: 12),

                // Configurações de Notificação
                Row(
                  children: [
                    const Icon(Icons.notifications_active, color: Colors.deepPurple, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Lembretes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Dias antes do lembrete
                const Text(
                  'Começar a lembrar com antecedência:',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildDiasChip(null, diasAntesLembrete, setDialogState, (dias) => diasAntesLembrete = dias),
                    _buildDiasChip(1, diasAntesLembrete, setDialogState, (dias) => diasAntesLembrete = dias),
                    _buildDiasChip(2, diasAntesLembrete, setDialogState, (dias) => diasAntesLembrete = dias),
                    _buildDiasChip(3, diasAntesLembrete, setDialogState, (dias) => diasAntesLembrete = dias),
                    _buildDiasChip(5, diasAntesLembrete, setDialogState, (dias) => diasAntesLembrete = dias),
                    _buildDiasChip(7, diasAntesLembrete, setDialogState, (dias) => diasAntesLembrete = dias),
                  ],
                ),
                const SizedBox(height: 16),

                // Lembretes diários
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Lembrete diário'),
                  subtitle: Text(
                    diasAntesLembrete != null && diasAntesLembrete! > 0
                        ? 'Notificar todos os dias desde $diasAntesLembrete dia(s) antes'
                        : 'Notificar todos os dias até a prova',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: lembretesDiarios,
                  enabled: diasAntesLembrete != null && diasAntesLembrete! > 0,
                  onChanged: (value) {
                    setDialogState(() {
                      lembretesDiarios = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (materiaController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, insira a matéria')),
                  );
                  return;
                }

                if (horarioController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, insira o horário')),
                  );
                  return;
                }

                final prova = Prova(
                  materia: materiaController.text.trim(),
                  data: dataProva,
                  horario: horarioController.text.trim(),
                  conteudo: conteudoController.text.trim(),
                  cor: corSelecionada,
                  diasAntesLembrete: diasAntesLembrete,
                  lembretesDiarios: lembretesDiarios,
                );

                ProvasData.adicionarProva(prova);
                await ProvasData.salvarProvas();

                // Agendar notificações
                if (diasAntesLembrete != null && diasAntesLembrete! > 0) {
                  await NotificacoesService.solicitarPermissoes();
                  await NotificacoesService.agendarNotificacoesProva(prova);
                }

                setState(() {});
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      diasAntesLembrete != null && diasAntesLembrete! > 0
                          ? 'Prova adicionada! Lembretes configurados.'
                          : 'Prova adicionada!',
                    ),
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  // Editar prova existente
  void _editarProva(Prova provaOriginal) {
    final materiaController = TextEditingController(text: provaOriginal.materia);
    final horarioController = TextEditingController(text: provaOriginal.horario);
    final conteudoController = TextEditingController(text: provaOriginal.conteudo);
    DateTime dataProva = provaOriginal.data;
    Color? corSelecionada = provaOriginal.cor;
    int? diasAntesLembrete = provaOriginal.diasAntesLembrete;
    bool lembretesDiarios = provaOriginal.lembretesDiarios;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Prova'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: materiaController,
                  decoration: const InputDecoration(
                    labelText: 'Matéria',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Data da Prova'),
                  subtitle: Text(
                    '${dataProva.day.toString().padLeft(2, '0')}/${dataProva.month.toString().padLeft(2, '0')}/${dataProva.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final data = await showDatePicker(
                      context: context,
                      initialDate: dataProva,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (data != null) {
                      setDialogState(() {
                        dataProva = data;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: horarioController,
                  decoration: const InputDecoration(
                    labelText: 'Horário',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: conteudoController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Conteúdo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Cor (opcional):', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildCorOption(null, corSelecionada, setDialogState, (cor) => corSelecionada = cor),
                    ...[
                      Colors.red[300]!,
                      Colors.blue[300]!,
                      Colors.green[300]!,
                      Colors.yellow[300]!,
                      Colors.purple[300]!,
                      Colors.orange[300]!,
                      Colors.pink[300]!,
                      Colors.teal[300]!,
                    ].map((cor) => _buildCorOption(cor, corSelecionada, setDialogState, (c) => corSelecionada = c)),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),

                // Configurações de Notificação
                Row(
                  children: [
                    const Icon(Icons.notifications_active, color: Colors.deepPurple, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Lembretes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Começar a lembrar com antecedência:',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildDiasChip(null, diasAntesLembrete, setDialogState, (dias) => diasAntesLembrete = dias),
                    _buildDiasChip(1, diasAntesLembrete, setDialogState, (dias) => diasAntesLembrete = dias),
                    _buildDiasChip(2, diasAntesLembrete, setDialogState, (dias) => diasAntesLembrete = dias),
                    _buildDiasChip(3, diasAntesLembrete, setDialogState, (dias) => diasAntesLembrete = dias),
                    _buildDiasChip(5, diasAntesLembrete, setDialogState, (dias) => diasAntesLembrete = dias),
                    _buildDiasChip(7, diasAntesLembrete, setDialogState, (dias) => diasAntesLembrete = dias),
                  ],
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Lembrete diário'),
                  subtitle: Text(
                    diasAntesLembrete != null && diasAntesLembrete! > 0
                        ? 'Notificar todos os dias desde $diasAntesLembrete dia(s) antes'
                        : 'Notificar todos os dias até a prova',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: lembretesDiarios,
                  enabled: diasAntesLembrete != null && diasAntesLembrete! > 0,
                  onChanged: (value) {
                    setDialogState(() {
                      lembretesDiarios = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (materiaController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, insira a matéria')),
                  );
                  return;
                }

                // Cancela notificações antigas
                await NotificacoesService.cancelarNotificacoesProva(provaOriginal.chave);

                // Remove a prova antiga
                ProvasData.removerProva(provaOriginal.chave);

                // Adiciona a prova atualizada
                final provaAtualizada = Prova(
                  materia: materiaController.text.trim(),
                  data: dataProva,
                  horario: horarioController.text.trim(),
                  conteudo: conteudoController.text.trim(),
                  cor: corSelecionada,
                  diasAntesLembrete: diasAntesLembrete,
                  lembretesDiarios: lembretesDiarios,
                );

                ProvasData.adicionarProva(provaAtualizada);
                await ProvasData.salvarProvas();

                // Agenda novas notificações
                if (diasAntesLembrete != null && diasAntesLembrete! > 0) {
                  await NotificacoesService.solicitarPermissoes();
                  await NotificacoesService.agendarNotificacoesProva(provaAtualizada);
                }

                setState(() {});
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Prova atualizada!')),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para selecionar cor
  Widget _buildCorOption(Color? cor, Color? corAtual, StateSetter setState, Function(Color?) onSelect) {
    final selecionada = (cor == null && corAtual == null) || (cor != null && cor == corAtual);

    return GestureDetector(
      onTap: () => setState(() => onSelect(cor)),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cor ?? Colors.white,
          border: Border.all(
            color: selecionada ? Colors.deepPurple : Colors.grey[300]!,
            width: selecionada ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: cor == null
            ? const Center(
                child: Icon(Icons.close, size: 20, color: Colors.grey),
              )
            : null,
      ),
    );
  }

  // Widget para selecionar dias de antecedência
  Widget _buildDiasChip(int? dias, int? diasSelecionados, StateSetter setState, Function(int?) onSelect) {
    final selecionado = dias == diasSelecionados;
    final label = dias == null ? 'Sem lembrete' : dias == 1 ? '1 dia' : '$dias dias';

    return FilterChip(
      label: Text(label),
      selected: selecionado,
      onSelected: (value) {
        setState(() => onSelect(value ? dias : null));
      },
      selectedColor: Colors.deepPurple.withOpacity(0.2),
      checkmarkColor: Colors.deepPurple,
    );
  }

  // Remover prova
  void _removerProva(String chave) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover prova?'),
        content: const Text('Deseja remover esta prova?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      // Cancela notificações
      await NotificacoesService.cancelarNotificacoesProva(chave);
      
      setState(() {
        ProvasData.removerProva(chave);
      });
      await ProvasData.salvarProvas();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prova removida')),
      );
    }
  }

  // Limpar todas as provas
  void _limparTodasProvas() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar todas as provas?'),
        content: const Text('Esta ação irá remover TODAS as provas cadastradas. Não é possível desfazer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar tudo'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      // Cancela todas as notificações
      await NotificacoesService.cancelarTodasNotificacoes();
      
      setState(() {
        ProvasData.limparTodasProvas();
      });
      await ProvasData.salvarProvas();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todas as provas foram removidas')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provasDoDia = _selectedDay != null
        ? ProvasData.buscarProvasPorData(_selectedDay!)
        : <Prova>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provas'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _mostrarListaProvas,
            tooltip: 'Ver todas as provas',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _limparTodasProvas,
            tooltip: 'Limpar todas',
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendário
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: CalendarStyle(
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
              markerMargin: const EdgeInsets.symmetric(horizontal: 1),
              todayDecoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;
                
                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      events.length > 3 ? 3 : events.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.deepPurple,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            eventLoader: (day) {
              return ProvasData.buscarProvasPorData(day);
            },
          ),
          const Divider(height: 1),
          
          // Lista de provas do dia selecionado
          Expanded(
            child: provasDoDia.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_note,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedDay == null
                              ? 'Selecione uma data no calendário'
                              : 'Nenhuma prova neste dia',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_selectedDay != null) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _adicionarProva(dataSelecionada: _selectedDay),
                            icon: const Icon(Icons.add),
                            label: const Text('Adicionar prova'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provasDoDia.length,
                    itemBuilder: (context, index) {
                      final prova = provasDoDia[index];
                      return Card(
                        color: prova.cor ?? Colors.white,
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _editarProva(prova),
                          onLongPress: () => _removerProva(prova.chave),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.school, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        prova.materia,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 16, color: Colors.black54),
                                    const SizedBox(width: 4),
                                    Text(
                                      prova.horario,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                if (prova.conteudo.isNotEmpty) ...[
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
                                    prova.conteudo,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                                if (prova.diasAntesLembrete != null && prova.diasAntesLembrete! > 0) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.notifications_active, size: 14, color: Colors.deepPurple),
                                      const SizedBox(width: 4),
                                      Text(
                                        prova.lembretesDiarios 
                                          ? 'Lembretes diários (${prova.diasAntesLembrete} dias antes)'
                                          : 'Lembrete ${prova.diasAntesLembrete} dia(s) antes',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _adicionarProva(),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}