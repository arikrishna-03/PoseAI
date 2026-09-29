import 'package:go_router/go_router.dart';
import '../../features/camera/presentation/camera_screen.dart';
import '../../features/gallery/presentation/gallery_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/presentation/permission_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/permissions',
      builder: (context, state) => const PermissionScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const CameraScreen(),
    ),
    GoRoute(
      path: '/gallery',
      builder: (context, state) => const GalleryScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
