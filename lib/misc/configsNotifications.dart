import 'package:flutter/material.dart';
import '../preferences/appData.dart';
import '../services/notificationsService.dart';

class ConfiguracoesNotificacoesDialog extends StatefulWidget {
  final bool primeiroAcesso;

  const ConfiguracoesNotificacoesDialog({
    super.key,
    this.primeiroAcesso = false,
  });

  @override
  State<ConfiguracoesNotificacoesDialog> createState() =>
      _ConfiguracoesNotificacoesDialogState();
}

class _ConfiguracoesNotificacoesDialogState
    extends State<ConfiguracoesNotificacoesDialog> {
  late bool _notificacoesAtivas;
  late int _diasAntes;
  late int _intervaloLembrete;

  @override
  void initState() {
    super.initState();
    _notificacoesAtivas = AppData.notificacoesAtivas;
    _diasAntes = AppData.diasAntesProva;
    _intervaloLembrete = AppData.intervaloLembrete;
  }

  Future<void> _salvarConfiguracoes() async {
  AppData.notificacoesAtivas = _notificacoesAtivas;
  AppData.diasAntesProva = _diasAntes;
  AppData.intervaloLembrete = _intervaloLembrete;
  AppData.primeiroAcessoProvas = false;
  await AppData.salvarDados();

  if (_notificacoesAtivas) {
    // Solicita permissões
    final permissao = await NotificacoesService.solicitarPermissoes();

    if (permissao) {
      // Reagenda todas as notificações
      // Aqui você precisaria iterar sobre as provas
      // Exemplo: provas.forEach((p) => NotificacoesService.agendarNotificacoesProva(p));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Notificações configuradas com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Permissão de notificações negada'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  } else {
    // Cancela todas as notificações
    await NotificacoesService.cancelarTodasNotificacoes();
  }

  if (mounted) {
    Navigator.of(context).pop(true);
  }
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.notifications_active, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Notificações de Provas'),
                if (widget.primeiroAcesso)
                  Text(
                    'Configure como quer ser notificado',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Switch de ativar/desativar
            SwitchListTile(
              title: const Text('Ativar notificações'),
              subtitle: const Text('Receber lembretes sobre provas'),
              value: _notificacoesAtivas,
              onChanged: (value) {
                setState(() {
                  _notificacoesAtivas = value;
                });
              },
              activeColor: Colors.deepPurple,
            ),
            
            const Divider(),
            
            // Dias antes da prova
            if (_notificacoesAtivas) ...[
              const SizedBox(height: 16),
              Text(
                'Notificar com antecedência',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  children: [
                    RadioListTile<int>(
                      title: const Text('No dia da prova'),
                      value: 0,
                      groupValue: _diasAntes,
                      onChanged: (value) {
                        setState(() {
                          _diasAntes = value!;
                        });
                      },
                      activeColor: Colors.deepPurple,
                    ),
                    RadioListTile<int>(
                      title: const Text('1 dia antes'),
                      subtitle: const Text('Recomendado'),
                      value: 1,
                      groupValue: _diasAntes,
                      onChanged: (value) {
                        setState(() {
                          _diasAntes = value!;
                        });
                      },
                      activeColor: Colors.deepPurple,
                    ),
                    RadioListTile<int>(
                      title: const Text('2 dias antes'),
                      value: 2,
                      groupValue: _diasAntes,
                      onChanged: (value) {
                        setState(() {
                          _diasAntes = value!;
                        });
                      },
                      activeColor: Colors.deepPurple,
                    ),
                    RadioListTile<int>(
                      title: const Text('3 dias antes'),
                      value: 3,
                      groupValue: _diasAntes,
                      onChanged: (value) {
                        setState(() {
                          _diasAntes = value!;
                        });
                      },
                      activeColor: Colors.deepPurple,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Intervalo de lembretes
              Text(
                'Repetir lembrete',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  children: [
                    RadioListTile<int>(
                      title: const Text('Não repetir'),
                      subtitle: const Text('Apenas uma notificação'),
                      value: 0,
                      groupValue: _intervaloLembrete,
                      onChanged: (value) {
                        setState(() {
                          _intervaloLembrete = value!;
                        });
                      },
                      activeColor: Colors.deepPurple,
                    ),
                    RadioListTile<int>(
                      title: const Text('A cada 30 minutos'),
                      value: 30,
                      groupValue: _intervaloLembrete,
                      onChanged: (value) {
                        setState(() {
                          _intervaloLembrete = value!;
                        });
                      },
                      activeColor: Colors.deepPurple,
                    ),
                    RadioListTile<int>(
                      title: const Text('A cada 1 hora'),
                      value: 60,
                      groupValue: _intervaloLembrete,
                      onChanged: (value) {
                        setState(() {
                          _intervaloLembrete = value!;
                        });
                      },
                      activeColor: Colors.deepPurple,
                    ),
                    RadioListTile<int>(
                      title: const Text('A cada 2 horas'),
                      value: 120,
                      groupValue: _intervaloLembrete,
                      onChanged: (value) {
                        setState(() {
                          _intervaloLembrete = value!;
                        });
                      },
                      activeColor: Colors.deepPurple,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Aviso sobre lembretes
              if (_intervaloLembrete > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, 
                        color: Colors.blue.shade700, 
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lembretes serão enviados até a hora da prova',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        if (!widget.primeiroAcesso)
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
        ElevatedButton(
          onPressed: _salvarConfiguracoes,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.primeiroAcesso ? 'Começar' : 'Salvar'),
        ),
      ],
    );
  }
}