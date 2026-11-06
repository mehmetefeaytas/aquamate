import 'package:flutter/material.dart';

/// Alt sayfa açılışları için özel geçiş rotası:
/// FadeTransition + SlideTransition kombinasyonu kullanır.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({required this.page})
    : super(
        transitionDuration: const Duration(milliseconds: 460),
        reverseTransitionDuration: const Duration(milliseconds: 380),
        opaque: true,
        barrierDismissible: true,
        pageBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) => page,
        transitionsBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child,
            ) {
              final CurvedAnimation curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              );
              return FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.08, 0.05),
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                ),
              );
            },
      );

  final Widget page;
}
