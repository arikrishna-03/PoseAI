import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/captured_photo.dart';

class GalleryRepository {
  Box? _box;

  Future<void> init() async {
    _box = await Hive.openBox(AppConstants.galleryBox);
  }

  List<CapturedPhoto> getCapturedPhotos() {
    if (_box == null) return [];
    final List<dynamic> raw = _box!.values.toList();
    final photos = raw.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return CapturedPhoto.fromJson(map);
    }).toList();

    // Sort newest first
    photos.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return photos;
  }

  Future<void> savePhoto(CapturedPhoto photo) async {
    await _box?.put(photo.id, photo.toJson());
  }

  Future<void> deletePhoto(String id) async {
    final raw = _box?.get(id);
    if (raw != null) {
      final map = Map<String, dynamic>.from(raw as Map);
      final photo = CapturedPhoto.fromJson(map);
      final file = File(photo.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _box?.delete(id);
  }
}
