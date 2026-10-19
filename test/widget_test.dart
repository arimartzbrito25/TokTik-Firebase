import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/presentation/providers/discover_provider.dart';
import 'package:toktok/presentation/screens/create/create_screen.dart';
import 'package:toktok/presentation/screens/home/home_shell.dart';

void main() {
  test('VideoPost marca imágenes correctamente', () {
    final imagePost = VideoPost(
      caption: 'Foto',
      videoUrl: 'https://example.com/a.jpg',
      mediaType: 'image',
    );
    final videoPost = VideoPost(
      caption: 'Clip',
      videoUrl: 'https://example.com/a.mp4',
    );

    expect(imagePost.isImage, isTrue);
    expect(videoPost.isImage, isFalse);
  });

  testWidgets('HomeShell muestra Feed, Crear y Perfil', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => DiscoverProvider(),
        child: const MaterialApp(home: HomeShell()),
      ),
    );

    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Crear'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets('CreateScreen lista las opciones de integración', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CreateScreen()),
    );

    expect(find.text('Cámara'), findsOneWidget);
    expect(find.text('Galería'), findsOneWidget);
    expect(find.text('Publicar con enlace'), findsOneWidget);
  });
}
