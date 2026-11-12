import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/rider/controller/rider_provider.dart';
import 'package:foam_mobile/feature/rider/views/rider_registration_screen.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_sign_up_screen.dart';

class PartnerSelectionModal extends StatelessWidget {
  final VoidCallback? onSelectVendor;
  final VoidCallback? onSelectRider;

  const PartnerSelectionModal({
    super.key,
    this.onSelectVendor,
    this.onSelectRider,
  });

  // ── Brand tokens (from AppColors) ──
  static const _textPrimary = Color(0xFF212828);
  static const _textSecondary = Color(0xFF5A6868);
  static const _surface = Color(0xFFF6F8F8);
  static const _border = Color(0xFFE4E4E4);

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onSelectVendor,
    VoidCallback? onSelectRider,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) => PartnerSelectionModal(
        onSelectVendor: onSelectVendor,
        onSelectRider: onSelectRider,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    bool isLoggedIn = false;
    try {
      if (Hive.isBoxOpen('foam')) {
        final token = HiveClass.getToken();
        isLoggedIn = token.isNotEmpty;
      }
    } catch (_) {
      isLoggedIn = false;
    }

    bool isVendor = false;
    bool isRider = false;
    bool isRiderPending = false;

    if (isLoggedIn) {
      try {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final rider = Provider.of<RiderProvider>(context, listen: false);
        isVendor = auth.isVendor;
        isRider = rider.isRegistered || auth.isRider;
        isRiderPending = rider.isPending || auth.isRiderPending;
      } catch (_) {}
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ──
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.colorScheme.outlineVariant
                      : _border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // ── Header ──
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Partner with Foam',
                      style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isDark ? theme.colorScheme.onSurface : _textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark
                            ? theme.colorScheme.surfaceContainerHighest
                            : _surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: isDark
                            ? theme.colorScheme.onSurfaceVariant
                            : _textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choose a program to get started.',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: isDark
                        ? theme.colorScheme.onSurfaceVariant
                        : _textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Vendor Card ──
              _PartnerCard(
                icon: Icons.storefront_rounded,
                title: 'Laundry Business Partner',
                description:
                    'List your laundry store on Foam, receive customer orders, and get paid directly to your bank.',
                isActive: isVendor,
                statusLabel: isVendor ? 'Active' : null,
                ctaLabel: isVendor ? 'Open Vendor Portal' : 'Get Started',
                themeColor: themeColor,
                onTap: () {
                  Navigator.pop(context);
                  if (onSelectVendor != null) {
                    onSelectVendor!();
                  } else if (isLoggedIn) {
                    Provider.of<VendorProvider>(context, listen: false)
                        .checkAndNavigateToVendor(context);
                  } else {
                    Navigator.of(context, rootNavigator: true)
                        .pushNamed(VendorSignUpScreen.id);
                  }
                },
              ),

              const SizedBox(height: 12),

              // ── Rider Card ──
              _PartnerCard(
                icon: Icons.two_wheeler_rounded,
                title: 'Delivery Rider Partner',
                description:
                    'Deliver laundry between customers and stores. Flexible hours, instant earnings per trip.',
                isActive: isRider && !isRiderPending,
                statusLabel: isRider
                    ? (isRiderPending ? 'Pending' : 'Active')
                    : null,
                ctaLabel: isRider ? 'Open Rider Portal' : 'Get Started',
                themeColor: themeColor,
                onTap: () {
                  Navigator.pop(context);
                  if (onSelectRider != null) {
                    onSelectRider!();
                  } else if (isLoggedIn) {
                    Provider.of<RiderProvider>(context, listen: false)
                        .checkAndNavigateToRider(context);
                  } else {
                    Navigator.of(context, rootNavigator: true)
                        .pushNamed(RiderRegistrationScreen.id);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Extracted Card Widget ──
class _PartnerCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isActive;
  final String? statusLabel;
  final String ctaLabel;
  final VoidCallback onTap;
  final Color? themeColor;

  const _PartnerCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isActive,
    required this.statusLabel,
    required this.ctaLabel,
    required this.onTap,
    this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveThemeColor = themeColor ?? theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? theme.colorScheme.surface : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: effectiveThemeColor.withValues(alpha: 0.08),
        highlightColor: effectiveThemeColor.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? effectiveThemeColor.withValues(alpha: 0.4)
                  : (isDark
                      ? theme.colorScheme.outlineVariant
                      : PartnerSelectionModal._border),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon row ──
              Row(
                children: [
                  // Icon in theme color container
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: effectiveThemeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: effectiveThemeColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? theme.colorScheme.onSurface
                            : PartnerSelectionModal._textPrimary,
                      ),
                    ),
                  ),
                  if (statusLabel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? effectiveThemeColor.withValues(alpha: 0.12)
                            : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel!,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? effectiveThemeColor
                              : const Color(0xFFE65100),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Description ──
              Text(
                description,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: isDark
                      ? theme.colorScheme.onSurfaceVariant
                      : PartnerSelectionModal._textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),

              // ── CTA button ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: effectiveThemeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    ctaLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
