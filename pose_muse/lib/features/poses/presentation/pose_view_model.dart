import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/pose_repository.dart';
import '../data/pose_storage_service.dart';
import '../domain/pose_category.dart';
import '../domain/pose_model.dart';

final poseStorageServiceProvider = Provider<PoseStorageService>((ref) {
  return PoseStorageService();
});

final poseRepositoryProvider = Provider<PoseRepository>((ref) {
  final storage = ref.watch(poseStorageServiceProvider);
  return PoseRepository(storage);
});

final poseViewModelProvider = StateNotifierProvider<PoseViewModel, PoseViewState>((ref) {
  final repo = ref.watch(poseRepositoryProvider);
  final storage = ref.watch(poseStorageServiceProvider);
  return PoseViewModel(repo, storage);
});

class PoseViewState {
  final List<PoseModel> allPoses;
  final List<PoseModel> filteredPoses;
  final PoseCategory selectedCategory;
  final String searchQuery;
  final PoseModel? currentSelectedPose;
  final Set<String> favoriteIds;
  final int detectedPeopleCount;
  final bool isLoading;

  const PoseViewState({
    this.allPoses = const [],
    this.filteredPoses = const [],
    this.selectedCategory = PoseCategory.all,
    this.searchQuery = '',
    this.currentSelectedPose,
    this.favoriteIds = const {},
    this.detectedPeopleCount = 1,
    this.isLoading = true,
  });

  PoseViewState copyWith({
    List<PoseModel>? allPoses,
    List<PoseModel>? filteredPoses,
    PoseCategory? selectedCategory,
    String? searchQuery,
    PoseModel? currentSelectedPose,
    Set<String>? favoriteIds,
    int? detectedPeopleCount,
    bool? isLoading,
  }) {
    return PoseViewState(
      allPoses: allPoses ?? this.allPoses,
      filteredPoses: filteredPoses ?? this.filteredPoses,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      currentSelectedPose: currentSelectedPose ?? this.currentSelectedPose,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      detectedPeopleCount: detectedPeopleCount ?? this.detectedPeopleCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PoseViewModel extends StateNotifier<PoseViewState> {
  final PoseRepository _repository;
  final PoseStorageService _storageService;

  PoseViewModel(this._repository, this._storageService) : super(const PoseViewState()) {
    init();
  }

  Future<void> init() async {
    await _storageService.init();
    final poses = await _repository.getAllPoses();
    final favs = _storageService.getFavoriteIds();

    final defaultPose = poses.isNotEmpty ? poses.first : null;

    state = state.copyWith(
      allPoses: poses,
      filteredPoses: poses,
      currentSelectedPose: defaultPose,
      favoriteIds: favs,
      isLoading: false,
    );
  }

  void selectCategory(PoseCategory category) {
    state = state.copyWith(selectedCategory: category);
    _applyFilters();
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void updateDetectedPeopleCount(int count) {
    if (count != state.detectedPeopleCount) {
      state = state.copyWith(detectedPeopleCount: count);
      // Auto-suggest category if user has 'All' selected
      if (state.selectedCategory == PoseCategory.all) {
        _applyFilters();
      }
    }
  }

  void selectPose(PoseModel pose) {
    state = state.copyWith(currentSelectedPose: pose);
    _storageService.addRecentPose(pose.id);
  }

  Future<void> toggleFavorite(String poseId) async {
    await _storageService.toggleFavorite(poseId);
    final favs = _storageService.getFavoriteIds();
    state = state.copyWith(favoriteIds: favs);
  }

  bool isFavorite(String poseId) {
    return state.favoriteIds.contains(poseId);
  }

  void _applyFilters() {
    final query = state.searchQuery.toLowerCase().trim();
    final category = state.selectedCategory;

    var filtered = state.allPoses.where((pose) {
      final matchesCategory = (category == PoseCategory.all) || (pose.category == category);
      if (!matchesCategory) return false;

      if (query.isEmpty) return true;
      final inName = pose.name.toLowerCase().contains(query);
      final inDesc = pose.description.toLowerCase().contains(query);
      final inTags = pose.tags.any((t) => t.toLowerCase().contains(query));
      return inName || inDesc || inTags;
    }).toList();

    // Prioritize poses matching current detected people count
    if (state.detectedPeopleCount > 1 && category == PoseCategory.all && query.isEmpty) {
      filtered.sort((a, b) {
        final aMatchesPeople = a.peopleCount == state.detectedPeopleCount ? 1 : 0;
        final bMatchesPeople = b.peopleCount == state.detectedPeopleCount ? 1 : 0;
        return bMatchesPeople.compareTo(aMatchesPeople);
      });
    }

    state = state.copyWith(filteredPoses: filtered);
  }
}
