import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

/// A full-screen, high-fidelity animated loader overlay.
/// Use during long async operations such as authentication, profile hydration,
/// account verification, or initial app bootstrap.
class AppFullScreenLoader {
  static bool _isOpen = false;

  /// Show the full-screen loader modal
  static void show(
    BuildContext context, {
    String message = 'Please wait...',
    String? subtitle,
  }) {
    if (_isOpen) return;
    _isOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 36),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A), // Dark slate brand background
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: const Color(0xFF00A3FF).withValues(alpha: 0.15),
                      blurRadius: 40,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated spinner around brand logo
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF00A3FF).withValues(alpha: 0.1),
                            ),
                          ),
                          LoadingAnimationWidget.threeArchedCircle(
                            color: const Color(0xFF00A3FF),
                            size: 64,
                          ),
                          Image.asset(
                            'assets/images/logo.png',
                            width: 28,
                            height: 28,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.local_laundry_service_rounded,
                              color: Color(0xFF00A3FF),
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Primary message
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),

                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFF94A3B8),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ).then((_) {
      _isOpen = false;
    });
  }

  /// Hide the loader modal safely
  static void hide(BuildContext context) {
    if (_isOpen) {
      _isOpen = false;
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  /// Whether the loader modal is currently visible
  static bool get isOpen => _isOpen;
}
