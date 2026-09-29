import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/intro_slides_screen.dart';
import '../../features/onboarding/presentation/language_select_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/terms_screen.dart';
import '../../features/profile/presentation/profile_wizard_screen.dart';
import '../../features/home/presentation/main_layout_screen.dart';
import '../../features/shortlist/presentation/shortlist_screen.dart';
import '../../features/settings/presentation/blocked_users_screen.dart';
import '../../features/chat/presentation/conversations_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.isAuthenticated != next.isAuthenticated ||
          previous?.isLoading != next.isLoading ||
          previous?.user != next.user) {
        notifyListeners();
      }
    });
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authProvider);

      if (authState.isLoading) {
        return null;
      }

      final isAuth = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/intro' ||
          state.matchedLocation == '/language' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/terms' ||
          state.matchedLocation == '/verify-email';

      if (!isAuth && !isLoggingIn && state.matchedLocation != '/') {
        return '/intro';
      }

      if (isAuth) {
        final user = authState.user;
        if (user != null && user.isAdmin) {
          if (state.matchedLocation == '/login' ||
              state.matchedLocation == '/register' ||
              state.matchedLocation == '/intro' ||
              state.matchedLocation == '/') {
            return '/admin/dashboard';
          }
        } else if (user != null && !user.emailVerified) {
          if (state.matchedLocation != '/verify-email') {
            return '/verify-email';
          }
        } else if (isLoggingIn || state.matchedLocation == '/') {
          return '/home';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/intro',
        builder: (context, state) => const IntroSlidesScreen(),
      ),
      GoRoute(
        path: '/language',
        builder: (context, state) => const LanguageSelectScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: '/profile-wizard',
        builder: (context, state) => const ProfileWizardScreen(),
      ),
      GoRoute(
        path: '/shortlist',
        builder: (context, state) => const ShortlistScreen(),
      ),
      GoRoute(
        path: '/blocked-users',
        builder: (context, state) => const BlockedUsersScreen(),
      ),
      GoRoute(
        path: '/conversations',
        builder: (context, state) => const ConversationsScreen(),
      ),
      GoRoute(
        path: '/chat/:conversationId',
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId'] ?? '';
          final extra = (state.extra as Map<String, dynamic>?) ?? {};
          return ChatScreen(
            conversationId: conversationId,
            extraData: extra,
          );
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainLayoutScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Admin Dashboard')),
          body: const Center(child: Text('Welcome Admin! (Phase 7 Admin Module Scaffold)')),
        ),
      ),
    ],
  );
});
