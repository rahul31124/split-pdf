import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../views/delete_pages_screen.dart';
import '../views/image_to_pdf_screen.dart';
import '../views/lock_pdf_screen.dart';
import '../views/merge_pdf_screen.dart';
import '../views/splash_screen.dart';
import '../views/home_screen.dart';
import '../views/split_pdf_screen.dart';
import '../views/compress_pdf_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/split-pdf', builder: (context, state) => const SplitPdfScreen()),
      GoRoute(path: '/compress-pdf', builder: (context, state) => const CompressPdfScreen()),
      GoRoute(path: '/merge-pdf', builder: (context, state) => const MergePdfScreen()),
      GoRoute(path: '/lock-pdf', builder: (context, state) => const LockPdfScreen()),
      GoRoute(path: '/image-pdf', builder: (context, state) => const ImageToPdfScreen()),
      GoRoute(path: '/delete-pdf', builder: (context, state) => const DeletePagesScreen()),
    ],
  );
});