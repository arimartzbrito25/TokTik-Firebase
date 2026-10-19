import 'package:flutter/material.dart';
import 'package:toktok/presentation/screens/camera/camera_screen.dart';
import 'package:toktok/presentation/screens/create/url_publish_screen.dart';
import 'package:toktok/presentation/screens/gallery/gallery_upload_screen.dart';
import 'package:toktok/presentation/screens/images/image_filter_screen.dart';

/// Hub para crear contenido. Integra cámara, galería y filtros. — Diego Baños
class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111512),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111512),
        foregroundColor: Colors.white,
        title: const Text('Crear'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '¿Qué quieres publicar?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Flujo: media → filtros → publicar',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          _CreateOption(
            icon: Icons.photo_camera_outlined,
            title: 'Cámara',
            subtitle: 'Capturar → filtros → publicar',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CameraScreen(),
                ),
              );
            },
          ),
          _CreateOption(
            icon: Icons.link,
            title: 'Publicar con enlace',
            subtitle: 'Pega una URL o carga videos demo',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const UrlPublishScreen(),
                ),
              );
            },
          ),
          _CreateOption(
            icon: Icons.photo_library_outlined,
            title: 'Galería',
            subtitle: 'Subir imagen o video desde tu galería',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const GalleryUploadScreen(),
                ),
              );
            },
          ),
          _CreateOption(
            icon: Icons.filter_vintage_outlined,
            title: 'Probar filtros (opcional)',
            subtitle: 'Sandbox de filtros de imagen',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ImageFilterScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CreateOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CreateOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFF1B201D),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white54),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
