import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home/home_screen.dart';
import '../features/tracks/track_list_screen.dart';
import '../features/player/player_screen.dart';
import '../data/models/models.dart';
import '../core/theme.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return Scaffold(
          backgroundColor: AppTheme.deepBlack,
          body: Stack(children: [child, const PlayerPanel()]),
        );
      },
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const HomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
          routes: [
            GoRoute(
              path: 'series/:id',
              name: 'tracks',
              pageBuilder: (context, state) {
                final seriesId = state.pathParameters['id']!;
                final series = state.extra as Series?;
                return CustomTransitionPage(
                  key: state.pageKey,
                  child: TrackListScreen(seriesId: seriesId, series: series),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        final tween = Tween(
                          begin: begin,
                          end: end,
                        ).chain(CurveTween(curve: Curves.easeInOutCubic));
                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                );
              },
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/player',
      name: 'player',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const PlayerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: Curves.easeInOutCubic));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    ),
  ],
);
