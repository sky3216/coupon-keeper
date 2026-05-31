import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/scan_item.dart';
import '../theme/app_theme.dart';

class SourceImagePreview extends StatelessWidget {
  const SourceImagePreview({required this.source, super.key});

  final ScanItem source;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '선택한 쿠폰 이미지 확대해서 보기',
      button: true,
      child: InkWell(
        onTap: () => _showViewer(context),
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: _SourceImage(source: source),
                ),
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Tooltip(
                    message: '이미지 확대',
                    child: Icon(Icons.zoom_in, color: AppTheme.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showViewer(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: AppTheme.viewerBackground,
      builder: (context) {
        return Dialog.fullscreen(
          backgroundColor: AppTheme.viewerBackground,
          child: Semantics(
            label: '선택한 쿠폰 이미지 전체 화면',
            child: Stack(
              fit: StackFit.expand,
              children: [
                InteractiveViewer(
                  child: Center(child: _SourceImage(source: source)),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: SafeArea(
                    child: IconButton(
                      tooltip: '이미지 확대 보기 닫기',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SourceImage extends StatelessWidget {
  const _SourceImage({required this.source});

  final ScanItem source;

  @override
  Widget build(BuildContext context) {
    final sourceRef = source.platformSourceRef;
    final uri = sourceRef == null ? null : Uri.tryParse(sourceRef);
    if (uri?.scheme == 'file') {
      return Image.file(File.fromUri(uri!), fit: BoxFit.contain);
    }
    return const Center(
      child: Icon(
        Icons.image_outlined,
        size: 48,
        color: AppTheme.textSecondary,
      ),
    );
  }
}
