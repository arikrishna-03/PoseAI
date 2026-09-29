import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';

class PoseStorageService {
  Box? _favoritesBox;
  Box? _recentsBox;

  Future<void> init() async {
    _favoritesBox = await Hive.openBox(AppConstants.favoritesBox);
    _recentsBox = await Hive.openBox(AppConstants.recentsBox);
  }

  Set<String> getFavoriteIds() {
    if (_favoritesBox == null) return {};
    final list = _favoritesBox!.get('favorite_ids', defaultValue: <String>[]);
    return Set<String>.from(list);
  }

  Future<void> toggleFavorite(String poseId) async {
    final favorites = getFavoriteIds();
    if (favorites.contains(poseId)) {
      favorites.remove(poseId);
    } else {
      favorites.add(poseId);
    }
    await _favoritesBox?.put('favorite_ids', favorites.toList());
  }

  bool isFavorite(String poseId) {
    return getFavoriteIds().contains(poseId);
  }

  List<String> getRecentPoseIds() {
    if (_recentsBox == null) return [];
    final list = _recentsBox!.get('recent_ids', defaultValue: <String>[]);
    return List<String>.from(list);
  }

  Future<void> addRecentPose(String poseId) async {
    final recents = getRecentPoseIds();
    recents.remove(poseId); // remove duplicate
    recents.insert(0, poseId); // add to top
    if (recents.length > 20) {
      recents.removeLast(); // keep last 20
    }
    await _recentsBox?.put('recent_ids', recents);
  }
}
