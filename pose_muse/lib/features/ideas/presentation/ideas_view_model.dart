import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/image_downsampler.dart';
import '../data/ideas_api_service.dart';
import '../domain/photo_idea.dart';

final ideasApiServiceProvider = Provider<IdeasApiService>((ref) {
  return IdeasApiService();
});

final ideasViewModelProvider = StateNotifierProvider<IdeasViewModel, IdeasViewState>((ref) {
  final api = ref.watch(ideasApiServiceProvider);
  return IdeasViewModel(api);
});

enum IdeasStatus {
  idle,
  scanning,
  success,
  offline,
  rateLimited,
  error,
}

class IdeasViewState {
  final IdeasStatus status;
  final String scanningMessage;
  final PhotoIdeasResponse? response;
  final List<PhotoIdea> ideas;
  final PhotoIdea? selectedIdea;
  final List<String> likedIdeaTitles;
  final List<String> dislikedIdeaTitles;
  final List<String> preferredStyles;
  final String? errorMessage;

  const IdeasViewState({
    this.status = IdeasStatus.idle,
    this.scanningMessage = 'Analyzing scene...',
    this.response,
    this.ideas = const [],
    this.selectedIdea,
    this.likedIdeaTitles = const [],
    this.dislikedIdeaTitles = const [],
    this.preferredStyles = const ['candid', 'fashion', 'fun'],
    this.errorMessage,
  });

  IdeasViewState copyWith({
    IdeasStatus? status,
    String? scanningMessage,
    PhotoIdeasResponse? response,
    List<PhotoIdea>? ideas,
    PhotoIdea? selectedIdea,
    List<String>? likedIdeaTitles,
    List<String>? dislikedIdeaTitles,
    List<String>? preferredStyles,
    String? errorMessage,
  }) {
    return IdeasViewState(
      status: status ?? this.status,
      scanningMessage: scanningMessage ?? this.scanningMessage,
      response: response ?? this.response,
      ideas: ideas ?? this.ideas,
      selectedIdea: selectedIdea ?? this.selectedIdea,
      likedIdeaTitles: likedIdeaTitles ?? this.likedIdeaTitles,
      dislikedIdeaTitles: dislikedIdeaTitles ?? this.dislikedIdeaTitles,
      preferredStyles: preferredStyles ?? this.preferredStyles,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class IdeasViewModel extends StateNotifier<IdeasViewState> {
  final IdeasApiService _apiService;
  Box? _prefsBox;
  Box? _cacheBox;
  Timer? _messageTimer;

  static const List<String> _rotatingMessages = [
    'Reading the light & shadows...',
    'Spotting architectural props...',
    'Analyzing outfits & color palette...',
    'Composing creative photo ideas...',
    'Directing custom pose angles...',
  ];

  IdeasViewModel(this._apiService) : super(const IdeasViewState()) {
    _init();
  }

  Future<void> _init() async {
    _prefsBox = await Hive.openBox(AppConstants.preferencesBox);
    _cacheBox = await Hive.openBox(AppConstants.cachedIdeasBox);

    final liked = List<String>.from(_prefsBox?.get('liked_titles', defaultValue: <String>[]) ?? []);
    final disliked = List<String>.from(_prefsBox?.get('disliked_titles', defaultValue: <String>[]) ?? []);
    final styles = List<String>.from(_prefsBox?.get('styles', defaultValue: ['candid', 'fashion', 'fun']) ?? []);

    // Load last cached ideas if present
    final cachedJson = _cacheBox?.get('last_ideas');
    PhotoIdeasResponse? cachedResponse;
    List<PhotoIdea> cachedIdeas = [];
    if (cachedJson != null) {
      try {
        final map = Map<String, dynamic>.from(cachedJson as Map);
        cachedResponse = PhotoIdeasResponse.fromJson(map);
        cachedIdeas = cachedResponse.ideas;
      } catch (_) {}
    }

    state = state.copyWith(
      likedIdeaTitles: liked,
      dislikedIdeaTitles: disliked,
      preferredStyles: styles,
      response: cachedResponse,
      ideas: cachedIdeas,
      selectedIdea: cachedIdeas.isNotEmpty ? cachedIdeas.first : null,
      status: cachedIdeas.isNotEmpty ? IdeasStatus.success : IdeasStatus.idle,
    );
  }

  Future<void> scanAndGenerateIdeas({
    required String photoPath,
    required int peopleCountHint,
  }) async {
    state = state.copyWith(
      status: IdeasStatus.scanning,
      scanningMessage: _rotatingMessages[0],
      errorMessage: null,
    );

    int msgIndex = 0;
    _messageTimer?.cancel();
    _messageTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      msgIndex = (msgIndex + 1) % _rotatingMessages.length;
      state = state.copyWith(scanningMessage: _rotatingMessages[msgIndex]);
    });

    try {
      // Downsample snapshot frame to max 768px long side, JPEG ~70%
      final base64Image = await ImageDownsampler.processImageForVisionAi(photoPath);

      final response = await _apiService.generateIdeas(
        imageBase64: base64Image,
        peopleCountHint: peopleCountHint,
        preferredStyles: state.preferredStyles,
        likedIdeas: state.likedIdeaTitles,
        dislikedIdeas: state.dislikedIdeaTitles,
      );

      _messageTimer?.cancel();

      // Cache fresh ideas
      await _cacheBox?.put('last_ideas', response.toJson());

      state = state.copyWith(
        status: IdeasStatus.success,
        response: response,
        ideas: response.ideas,
        selectedIdea: response.ideas.isNotEmpty ? response.ideas.first : null,
      );
    } on OfflineException catch (e) {
      _messageTimer?.cancel();
      state = state.copyWith(
        status: IdeasStatus.offline,
        errorMessage: e.message,
      );
    } on RateLimitException catch (e) {
      _messageTimer?.cancel();
      state = state.copyWith(
        status: IdeasStatus.rateLimited,
        errorMessage: e.message,
      );
    } catch (e) {
      _messageTimer?.cancel();
      state = state.copyWith(
        status: IdeasStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void selectIdea(PhotoIdea idea) {
    state = state.copyWith(selectedIdea: idea);
  }

  Future<void> rateIdea(String ideaId, bool isLiked) async {
    final updatedIdeas = state.ideas.map((i) {
      if (i.id == ideaId) {
        return i.copyWith(isLiked: isLiked);
      }
      return i;
    }).toList();

    final targetIdea = state.ideas.firstWhere((i) => i.id == ideaId);
    final title = targetIdea.title;

    final liked = List<String>.from(state.likedIdeaTitles);
    final disliked = List<String>.from(state.dislikedIdeaTitles);

    if (isLiked) {
      liked.add(title);
      disliked.remove(title);
    } else {
      disliked.add(title);
      liked.remove(title);
    }

    await _prefsBox?.put('liked_titles', liked);
    await _prefsBox?.put('disliked_titles', disliked);

    state = state.copyWith(
      ideas: updatedIdeas,
      likedIdeaTitles: liked,
      dislikedIdeaTitles: disliked,
      selectedIdea: state.selectedIdea?.id == ideaId
          ? state.selectedIdea?.copyWith(isLiked: isLiked)
          : state.selectedIdea,
    );
  }

  void updatePreferredStyles(List<String> styles) {
    state = state.copyWith(preferredStyles: styles);
    _prefsBox?.put('styles', styles);
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }
}
