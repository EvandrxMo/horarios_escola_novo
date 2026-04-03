import 'package:flutter/material.dart';
import '../services/backup_service.dart';
import '../preferences/appData.dart';

class BackupRestoreDialog extends StatefulWidget {
  const BackupRestoreDialog({super.key});

  @override
  State<BackupRestoreDialog> createState() => _BackupRestoreDialogState();
}

class _BackupRestoreDialogState extends State<BackupRestoreDialog> {
  Map<String, dynamic>? _backupInfo;
  bool _isLoading = true;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _carregarInfoBackup();
  }

  Future<void> _carregarInfoBackup() async {
    final info = await BackupService.getBackupInfo();
    setState(() {
      _backupInfo = info;
      _isLoading = false;
    });
  }

  Future<void> _restaurarBackup() async {
    setState(() {
      _isRestoring = true;
    });

    try {
      final sucesso = await BackupService.restaurarBackup();
      
      if (sucesso) {
        // Recarrega os dados do AppData após restauração
        await AppData.carregarDados();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dados restaurados com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Retorna true para indicar sucesso
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao restaurar backup'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
      }
    }
  }

  Future<void> _ignorarBackup() async {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.restore, color: Colors.deepPurple),
          SizedBox(width: 8),
          Text('Backup Encontrado'),
        ],
      ),
      content: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _backupInfo != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Encontramos um backup anterior:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 16),
                    _buildInfoRow('Nome:', _backupInfo!['nomeUsuario']),
                    _buildInfoRow('Data do backup:', _formatarData(_backupInfo!['dataBackup'])),
                    _buildInfoRow('Versão:', _backupInfo!['versao']),
                    _buildInfoRow('Tamanho:', _formatarTamanho(_backupInfo!['tamanho'])),
                    SizedBox(height: 16),
                    Text(
                      'Deseja restaurar seus dados?',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                )
              : Text('Nenhum backup encontrado.'),
      actions: [
        if (_backupInfo != null) ...[
          TextButton(
            onPressed: _isRestoring ? null : _ignorarBackup,
            child: Text('Ignorar'),
          ),
          ElevatedButton(
            onPressed: _isRestoring ? null : _restaurarBackup,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: _isRestoring
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('Restaurar'),
          ),
        ] else ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  String _formatarData(String dataStr) {
    try {
      final data = DateTime.parse(dataStr);
      return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dataStr;
    }
  }

  String _formatarTamanho(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
