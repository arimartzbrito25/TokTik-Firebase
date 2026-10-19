import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../infrastructure/media_upload_service.dart';

class GalleryUploadScreen extends StatefulWidget {
  const GalleryUploadScreen({super.key});

  @override
  State<GalleryUploadScreen> createState() => _GalleryUploadScreenState();
}

class _GalleryUploadScreenState extends State<GalleryUploadScreen> {
  final MediaUploadService _uploadService = MediaUploadService();
  File? _selectedFile;
  bool _isVideo = false;
  bool _isUploading = false;
  final TextEditingController _captionController = TextEditingController();

  Future<void> _selectMedia(bool isVideo) async {
    final XFile? file = await _uploadService.pickFromGallery(isVideo: isVideo);
    if (file != null) {
      setState(() {
        _selectedFile = File(file.path);
        _isVideo = isVideo;
      });
    }
  }

  Future<void> _uploadMedia() async {
    if (_selectedFile == null) return;

    setState(() => _isUploading = true);

    String folder = _isVideo ? 'videos' : 'images';
    String? mediaUrl = await _uploadService.uploadToStorage(_selectedFile!, folder);

    if (mediaUrl != null) {
      await _uploadService.savePostToFirestore(
        mediaUrl: mediaUrl,
        caption: _captionController.text,
        isVideo: _isVideo,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Publicación cargada exitosamente en Firebase!')),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al subir el archivo.')),
        );
      }
    }

    setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subir desde Galería')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _selectMedia(false),
                    icon: const Icon(Icons.image),
                    label: const Text('Imagen'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _selectMedia(true),
                    icon: const Icon(Icons.videocam),
                    label: const Text('Video'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_selectedFile != null) ...[
                Text('Seleccionado: ${_selectedFile!.path.split('/').last}'),
                const SizedBox(height: 15),
                TextField(
                  controller: _captionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción del post',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                _isUploading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _uploadMedia,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        child: const Text('Subir a Firebase'),
                      ),
              ] else
                const Text('Selecciona una imagen o video de tu galería'),
            ],
          ),
        ),
      ),
    );
  }
}