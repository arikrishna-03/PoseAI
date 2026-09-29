import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../data/gallery_repository.dart';
import '../domain/captured_photo.dart';

class PhotoViewScreen extends StatelessWidget {
  final CapturedPhoto photo;

  const PhotoViewScreen({super.key, required this.photo});

  @override
  Widget build(BuildContext context) {
    final file = File(photo.filePath);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Share
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () {
              Share.shareXFiles([XFile(photo.filePath)], text: 'Captured with PoseMuse! Pose: ${photo.poseName}');
            },
          ),
          // Delete
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 3.5,
              child: Center(
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          // Bottom Info Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            color: AppColors.darkSurface,
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        photo.poseName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMMM d, yyyy • h:mm a').format(photo.timestamp),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.matchColor(photo.matchScore).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.matchColor(photo.matchScore)),
                    ),
                    child: Text(
                      '${(photo.matchScore * 100).toInt()}% Match',
                      style: TextStyle(
                        color: AppColors.matchColor(photo.matchScore),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Delete Photo?'),
        content: const Text('This photo will be permanently deleted.'),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: AppColors.errorRed)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final repo = GalleryRepository();
              await repo.init();
              await repo.deletePhoto(photo.id);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }
}
