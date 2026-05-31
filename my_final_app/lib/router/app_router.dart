import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/listing.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_provider.dart';
import '../screen/change_password_screen.dart';
import '../screen/complete_profile_screen.dart';
import '../screen/edit_profile_screen.dart';
import '../screen/forgot_password_screen.dart';
import '../screen/listing_detail_screen.dart';
import '../screen/login_screen.dart';
import '../screen/main_navigation_screen.dart';
import '../screen/post_item_screen.dart';
import '../screen/register_screen.dart';
import '../screen/verify_email_screen.dart';
import 'router_refresh_notifier.dart';

part 'app_router.g.dart';

const _authOnlyPaths = {
  '/login',
  '/register',
  '/forgot-password',
  '/verify-email',
  '/complete-profile',
};

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  final notifier = ref.watch(routerRefreshNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authData = ref.read(authNotifierProvider);
      final status = authData.status;
      final loc = state.uri.toString();

      if (status == AuthStatus.initializing) {
        return loc == '/' ? null : '/';
      }

      if (status == AuthStatus.unauthenticated) {
        const allowed = {'/login', '/register', '/forgot-password'};
        return allowed.contains(loc) ? null : '/login';
      }

      if (status == AuthStatus.emailUnverified) {
        return loc == '/verify-email' ? null : '/verify-email';
      }

      if (status == AuthStatus.profileIncomplete) {
        return loc == '/complete-profile' ? null : '/complete-profile';
      }

      // authenticated
      if (_authOnlyPaths.contains(loc)) {
        return '/home';
      }
      if (loc == '/') {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (context, state) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainNavigationScreen(),
      ),
      GoRoute(
        path: '/listing/:id',
        builder: (context, state) =>
            ListingDetailScreen(listingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/post-item',
        builder: (context, state) =>
            PostItemScreen(existing: state.extra as Listing?),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
    ],
  );
}
