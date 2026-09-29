import 'dart:convert';
import 'package:flutter/services.dart';
import '../domain/pose_category.dart';
import '../domain/pose_model.dart';
import 'pose_storage_service.dart';

class PoseRepository {
  final PoseStorageService _storageService;
  List<PoseModel> _cachedPoses = [];

  PoseRepository(this._storageService);

  Future<List<PoseModel>> getAllPoses() async {
    if (_cachedPoses.isNotEmpty) return _cachedPoses;

    try {
      final jsonString = await rootBundle.loadString('assets/poses/poses.json');
      final List<dynamic> list = json.decode(jsonString);
      _cachedPoses = list.map((item) => PoseModel.fromJson(item)).toList();
    } catch (e) {
      // Fallback empty list if error
      _cachedPoses = [];
    }
    return _cachedPoses;
  }

  Future<List<PoseModel>> getPosesByCategory(PoseCategory category) async {
    final all = await getAllPoses();
    if (category == PoseCategory.all) return all;
    return all.where((p) => p.category == category).toList();
  }

  Future<List<PoseModel>> getPosesForPeopleCount(int peopleCount) async {
    final all = await getAllPoses();
    if (peopleCount <= 1) {
      return all.where((p) => p.peopleCount == 1).toList();
    } else if (peopleCount == 2) {
      return all.where((p) => p.peopleCount == 2).toList();
    } else {
      return all.where((p) => p.peopleCount >= 3).toList();
    }
  }

  Future<List<PoseModel>> getFavoritePoses() async {
    final all = await getAllPoses();
    final favIds = _storageService.getFavoriteIds();
    return all.where((p) => favIds.contains(p.id)).toList();
  }

  Future<List<PoseModel>> getRecentPoses() async {
    final all = await getAllPoses();
    final recentIds = _storageService.getRecentPoseIds();
    final Map<String, PoseModel> poseMap = {for (var p in all) p.id: p};

    final List<PoseModel> result = [];
    for (final id in recentIds) {
      if (poseMap.containsKey(id)) {
        result.add(poseMap[id]!);
      }
    }
    return result;
  }

  Future<List<PoseModel>> searchPoses(String query, {PoseCategory? category}) async {
    final all = await getAllPoses();
    final q = query.toLowerCase().trim();

    return all.where((pose) {
      final matchesCategory = category == null || category == PoseCategory.all || pose.category == category;
      if (!matchesCategory) return false;

      if (q.isEmpty) return true;
      final inName = pose.name.toLowerCase().contains(q);
      final inDesc = pose.description.toLowerCase().contains(q);
      final inTags = pose.tags.any((t) => t.toLowerCase().contains(q));
      return inName || inDesc || inTags;
    }).toList();
  }
}
