import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  HEADER — custom app bar for MainScreen
// ─────────────────────────────────────────────

class MainHeader extends StatelessWidget implements PreferredSizeWidget {
  /// The user's name (e.g. "Quaisse").
  final String userName;

  /// Optional small subtitle line below the name.
  final String subtitle;

  /// Called when the profile avatar is tapped.
  final VoidCallback? onProfileTap;

  const MainHeader({
    super.key,
    required this.userName,
    this.subtitle = 'Welcome back',
    this.onProfileTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(90);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Left: greeting ──────────────────────────────
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0D0D0D),
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                      children: [
                        const TextSpan(text: 'Hello, '),
                        TextSpan(text: userName),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF888888),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // ── Right: profile avatar ───────────────────────
            GestureDetector(
              onTap: onProfileTap,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE8E8E8),
                  border: Border.all(
                    color: const Color(0xFFD0D0D0),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF555555),
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
