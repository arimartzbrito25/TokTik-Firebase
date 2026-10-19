import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktok/infrastructure/services/media_upload_service.dart';
import 'package:toktok/presentation/providers/discover_provider.dart';
import 'package:toktok/presentation/screens/create/media_filter_screen.dart';

/// Publicar con URL pública — no requiere Firebase Storage.
class UrlPublishScreen extends StatefulWidget {
  const UrlPublishScreen({super.key});

  @override
  State<UrlPublishScreen> createState() => _UrlPublishScreenState();
}

class _UrlPublishScreenState extends State<UrlPublishScreen> {
  final _urlController = TextEditingController(
    text:
        'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
  );
  final _service = MediaUploadService();
  bool _isVideo = true;
  bool _busy = false;

  Future<void> _continueToFilters() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MediaFilterScreen(
          remoteUrl: url,
          isVideo: _isVideo,
        ),
      ),
    );
  }

  Future<void> _seedSamples() async {
    if (_busy) return;
    setState(() => _busy = true);
    final discover = context.read<DiscoverProvider>();
    try {
      int count;
      try {
        count = await _service.seedSampleVideos();
      } catch (_) {
        count = discover.seedLocalDemoVideos();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Se agregaron $count videos de demo al feed.')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111512),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111512),
        foregroundColor: Colors.white,
        title: const Text('Publicar con enlace'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Pega una URL pública de video o imagen. '
              'Después eliges el filtro y publicas.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'URL del media',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'https://...',
                hintStyle: TextStyle(color: Colors.white38),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Es un video',
                style: TextStyle(color: Colors.white),
              ),
              value: _isVideo,
              onChanged: _busy ? null : (v) => setState(() => _isVideo = v),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : _continueToFilters,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Continuar a filtros'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : _seedSamples,
              icon: const Icon(Icons.library_add_outlined),
              label: const Text('Cargar 3 videos de ejemplo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
