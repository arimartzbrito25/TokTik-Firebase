import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:toktok/presentation/screens/camera/media_preview_screen.dart';

enum CaptureMode { photo, video }

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  CaptureMode _mode = CaptureMode.photo;
  bool _isInitializing = true;
  bool _isRecording = false;
  bool _isBusy = false;
  String? _errorMessage;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initializeController(_selectedCameraIndex);
    }
  }

  Future<bool> _requestPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
    final micGranted = statuses[Permission.microphone]?.isGranted ?? false;

    if (!cameraGranted) {
      setState(() {
        _errorMessage =
            'Se necesita permiso de cámara para capturar fotos y videos.';
        _isInitializing = false;
      });
      return false;
    }

    if (_mode == CaptureMode.video && !micGranted) {
      setState(() {
        _errorMessage =
            'Se necesita permiso de micrófono para grabar videos con audio.';
        _isInitializing = false;
      });
      return false;
    }

    return true;
  }

  Future<void> _setupCamera() async {
    final granted = await _requestPermissions();
    if (!granted) return;

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No se encontró ninguna cámara en este dispositivo.';
          _isInitializing = false;
        });
        return;
      }
      await _initializeController(0);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al iniciar la cámara: $e';
        _isInitializing = false;
      });
    }
  }

  Future<void> _initializeController(int cameraIndex) async {
    if (_cameras.isEmpty) return;

    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    final previous = _controller;
    _controller = null;
    await previous?.dispose();

    final controller = CameraController(
      _cameras[cameraIndex],
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _selectedCameraIndex = cameraIndex;
        _isInitializing = false;
      });
    } catch (e) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No se pudo inicializar la cámara: $e';
        _isInitializing = false;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isRecording || _isBusy) return;
    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initializeController(nextIndex);
  }

  Future<String> _buildOutputPath(String extension) async {
    final directory = await getTemporaryDirectory();
    final fileName =
        'cruz_${DateTime.now().millisecondsSinceEpoch}.$extension';
    return path.join(directory.path, fileName);
  }

  Future<void> _takePhoto() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isBusy ||
        _isRecording) {
      return;
    }

    setState(() => _isBusy = true);

    try {
      final photo = await controller.takePicture();
      final savedPath = await _buildOutputPath('jpg');
      await File(photo.path).copy(savedPath);

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MediaPreviewScreen(
            filePath: savedPath,
            isVideo: false,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al capturar la foto: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _toggleVideoRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isBusy) {
      return;
    }

    if (_isRecording) {
      setState(() => _isBusy = true);
      try {
        final video = await controller.stopVideoRecording();
        _recordingTimer?.cancel();
        setState(() {
          _isRecording = false;
          _recordingDuration = Duration.zero;
        });

        final savedPath = await _buildOutputPath('mp4');
        await File(video.path).copy(savedPath);

        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MediaPreviewScreen(
              filePath: savedPath,
              isVideo: true,
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al detener la grabación: $e')),
        );
      } finally {
        if (mounted) setState(() => _isBusy = false);
      }
      return;
    }

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se necesita el micrófono para grabar video.'),
        ),
      );
      return;
    }

    setState(() => _isBusy = true);
    try {
      await controller.startVideoRecording();
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar la grabación: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _onCapturePressed() async {
    if (_mode == CaptureMode.photo) {
      await _takePhoto();
    } else {
      await _toggleVideoRecording();
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_errorMessage != null) {
      return _ErrorView(
        message: _errorMessage!,
        onRetry: _setupCamera,
        onOpenSettings: openAppSettings,
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: Text(
          'Cámara no disponible',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: 1 / controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RoundIconButton(
                icon: Icons.arrow_back,
                onPressed: _isRecording
                    ? null
                    : () => Navigator.of(context).pop(),
              ),
              if (_isRecording)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, color: Colors.white, size: 10),
                      const SizedBox(width: 8),
                      Text(
                        _formatDuration(_recordingDuration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox(width: 48),
              _RoundIconButton(
                icon: Icons.cameraswitch_outlined,
                onPressed: _cameras.length > 1 && !_isRecording
                    ? _switchCamera
                    : null,
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 28,
          child: Column(
            children: [
              if (!_isRecording) _ModeSelector(
                mode: _mode,
                onChanged: (mode) {
                  if (_isBusy) return;
                  setState(() => _mode = mode);
                },
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _isBusy ? null : _onCapturePressed,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _isRecording ? 78 : 72,
                  height: _isRecording ? 78 : 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: Colors.transparent,
                  ),
                  alignment: Alignment.center,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _isRecording ? 28 : 58,
                    height: _isRecording ? 28 : 58,
                    decoration: BoxDecoration(
                      color: _mode == CaptureMode.video || _isRecording
                          ? Colors.red
                          : Colors.white,
                      borderRadius: BorderRadius.circular(
                        _isRecording ? 6 : 30,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _mode == CaptureMode.photo
                    ? 'Toca para capturar foto'
                    : (_isRecording
                        ? 'Toca para detener la grabación'
                        : 'Toca para grabar video'),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final CaptureMode mode;
  final ValueChanged<CaptureMode> onChanged;

  const _ModeSelector({
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ModeChip(
          label: 'Foto',
          selected: mode == CaptureMode.photo,
          onTap: () => onChanged(CaptureMode.photo),
        ),
        const SizedBox(width: 12),
        _ModeChip(
          label: 'Video',
          selected: mode == CaptureMode.video,
          onTap: () => onChanged(CaptureMode.video),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _RoundIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off, color: Colors.white54, size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
          TextButton(
            onPressed: onOpenSettings,
            child: const Text(
              'Abrir ajustes',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Volver',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
