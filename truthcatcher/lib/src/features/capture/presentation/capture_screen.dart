import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../certificate/application/certificate_providers.dart';
import '../domain/capture_draft.dart';

/// Écran caméra : capture (ou import galerie), calcule le hash, dérive le
/// matricule, **l'incruste sur la photo**, récupère heure de confiance + GPS,
/// puis ouvre l'écran de confirmation.
class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  CameraController? _controller;
  late final Future<void> _initFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _initFuture = _setupCamera();
  }

  Future<void> _setupCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('Aucune caméra disponible sur cet appareil.');
    }
    final controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller.initialize();
    if (!mounted) return;
    setState(() => _controller = controller);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// Pipeline commun : hash → matricule → stamp → brouillon → confirmation.
  Future<void> _processAndGo(Uint8List originalBytes) async {
    final hashService = ref.read(hashServiceProvider);
    final sha256Hex = hashService.sha256Hex(originalBytes);
    final capturedAt = await ref.read(trustedTimeServiceProvider).now();
    final matricule = hashService.deriveMatricule(
      sha256Hex: sha256Hex,
      capturedAt: capturedAt,
    );
    final fix = await ref.read(locationServiceProvider).currentFixOrSimulated();

    // Incrustation du matricule sur la photo (filigrane visible).
    final stampedBytes = await ref.read(stampServiceProvider).stamp(
          bytes: originalBytes,
          matricule: matricule,
          capturedAt: capturedAt,
          location: fix.label,
        );
    final stampedPath = await _saveJpg(stampedBytes);

    final draft = CaptureDraft(
      imagePath: stampedPath,
      bytes: originalBytes, // le hash de preuve porte sur l'image ORIGINALE
      sha256Hex: sha256Hex,
      capturedAt: capturedAt,
      latitude: fix.latitude,
      longitude: fix.longitude,
      accuracy: fix.accuracy,
      locationLabel: fix.label,
    );

    if (!mounted) return;
    context.push('/preview', extra: draft);
  }

  Future<String> _saveJpg(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/tc_${DateTime.now().microsecondsSinceEpoch}.jpg');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _busy) return;
    setState(() => _busy = true);
    try {
      final shot = await controller.takePicture();
      await _processAndGo(await shot.readAsBytes());
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2400,
      );
      if (picked == null) return;
      await _processAndGo(await picked.readAsBytes());
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Erreur : $e')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Capturer une preuve'),
      ),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          final controller = _controller;
          final cameraReady = !snapshot.hasError && controller != null;
          return Stack(
            fit: StackFit.expand,
            children: [
              if (cameraReady)
                CameraPreview(controller)
              else
                _CameraUnavailable(error: snapshot.error),
              if (_busy)
                ColoredBox(
                  color: AppColors.primaryDark.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _RoundIcon(
                        icon: Icons.photo_library_outlined,
                        onTap: _busy ? null : _pickFromGallery,
                      ),
                      const SizedBox(width: 28),
                      _ShutterButton(
                        busy: _busy,
                        onTap: cameraReady ? _capture : null,
                      ),
                      const SizedBox(width: 28),
                      const SizedBox(width: 52), // équilibre visuel
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CameraUnavailable extends StatelessWidget {
  const _CameraUnavailable({this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              color: Colors.white54,
              size: 56,
            ),
            const SizedBox(height: 16),
            const Text(
              'Caméra indisponible.\nUtilisez la galerie pour la démo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white30, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.18),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: const Icon(Icons.camera, color: Colors.white, size: 40),
      ),
    );
  }
}
