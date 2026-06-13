import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/app_version.dart';

class UpdateDialog extends StatefulWidget {
  const UpdateDialog({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
    required this.updateActionLabel,
    required this.showDownloadProgress,
    required this.onUpdateNow,
    required this.onClosed,
  });

  final String currentVersion;
  final AppVersion latestVersion;
  final String updateActionLabel;
  final bool showDownloadProgress;
  final Future<void> Function(void Function(double progress) onProgress)
  onUpdateNow;
  final VoidCallback onClosed;

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0;
  String? _errorMessage;

  bool get _canClose => !widget.latestVersion.forceUpdate && !_isDownloading;

  @override
  Widget build(BuildContext context) {
    final percent = (_progress * 100).clamp(0, 100).round();

    return PopScope(
      canPop: _canClose,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          widget.onClosed();
        }
      },
      child: AlertDialog(
        title: const Text('Có phiên bản mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phiên bản hiện tại: ${widget.currentVersion}'),
            Text('Phiên bản mới: ${widget.latestVersion.version}'),
            const SizedBox(height: 14),
            Text(
              widget.latestVersion.message.isEmpty
                  ? 'Bản cập nhật mới đã sẵn sàng.'
                  : widget.latestVersion.message,
            ),
            if (_isDownloading && widget.showDownloadProgress) ...[
              const SizedBox(height: 18),
              const Text('Đang tải bản cập nhật...'),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: _progress == 0 ? null : _progress),
              const SizedBox(height: 8),
              Text('$percent%'),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
        actions: [
          if (!widget.latestVersion.forceUpdate)
            TextButton(
              onPressed: _isDownloading
                  ? null
                  : () {
                      widget.onClosed();
                      Get.back<void>();
                    },
              child: const Text('Để sau'),
            ),
          FilledButton(
            onPressed: _isDownloading ? null : _downloadAndOpen,
            child: Text(widget.updateActionLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAndOpen() async {
    setState(() {
      _isDownloading = true;
      _progress = 0;
      _errorMessage = null;
    });

    try {
      await widget.onUpdateNow((progress) {
        if (!mounted) {
          return;
        }
        setState(() => _progress = progress);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Không thể thực hiện cập nhật: $error';
        _isDownloading = false;
      });
    }
  }
}
