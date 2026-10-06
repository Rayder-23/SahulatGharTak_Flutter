import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/app_config.dart';
import '../screens/update_required_screen.dart';
import '../utils/constants.dart';
import '../utils/update_block.dart';

/// Wraps the app's navigator and covers it with a non-dismissable "Update now"
/// screen while [UpdateBlock.isBlocked]. Used as the `MaterialApp.builder`, so
/// it sits above every route, dialog-free and unreachable by back navigation.
class UpdateBlockHost extends StatefulWidget {
  const UpdateBlockHost(
      {super.key, required this.block, required this.navigatorKey, this.child});
  final UpdateBlock block;
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget? child;

  @override
  State<UpdateBlockHost> createState() => _UpdateBlockHostState();
}

class _UpdateBlockHostState extends State<UpdateBlockHost> {
  UpdateBlock get block => widget.block;
  Widget? get child => widget.child;

  @override
  void initState() {
    super.initState();
    block.addListener(_maybeShowPrompt);
  }

  @override
  void dispose() {
    block.removeListener(_maybeShowPrompt);
    super.dispose();
  }

  /// Shows a queued non-forced "Update available" dialog above the navigator.
  void _maybeShowPrompt() {
    final prompt = block.takePrompt();
    if (prompt == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = widget.navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      showUpdatePrompt(
        ctx,
        AppConfig(
          minimumRequiredVersion: '0.0.0',
          latestVersion: prompt.version,
          forceUpdate: false,
          storeUrl: prompt.storeUrl,
          updateMessage: prompt.message ?? '',
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: block,
      builder: (context, _) => Stack(
        children: [
          if (child != null) child!,
          if (block.isBlocked)
            Positioned.fill(child: _UpdateBlockScreen(block)),
        ],
      ),
    );
  }
}

const _kBrandBlue = Color(0xFF016EE3);

class _UpdateBlockScreen extends StatefulWidget {
  const _UpdateBlockScreen(this.block);
  final UpdateBlock block;

  @override
  State<_UpdateBlockScreen> createState() => _UpdateBlockScreenState();
}

class _UpdateBlockScreenState extends State<_UpdateBlockScreen> {
  String? _installed;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _installed = info.version);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final block = widget.block;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _kBrandBlue,
        body: Stack(
          children: [
            // Brand gradient backdrop with soft decorative discs.
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A84FF), _kBrandBlue, kPrimaryColor],
                  ),
                ),
              ),
            ),
            const Positioned(top: -70, right: -50, child: _Disc(240, 0.08)),
            const Positioned(top: 150, left: -80, child: _Disc(170, 0.06)),
            const Positioned(top: 210, right: 56, child: _Disc(10, 0.7)),
            Column(
              children: [
                const Expanded(
                  flex: 11,
                  child: SafeArea(
                    bottom: false,
                    child: Center(child: _HeroBadge()),
                  ),
                ),
                Expanded(
                  flex: 14,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(28, 32, 28, 20 + bottomInset),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(36)),
                      boxShadow: [
                        BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 30,
                            offset: Offset(0, -8)),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: kSecondaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('UPDATE REQUIRED',
                                style: TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 1.4,
                                    fontWeight: FontWeight.w800,
                                    color: kSecondaryColor)),
                          ),
                          const SizedBox(height: 14),
                          const Text('A fresh version is ready',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 26,
                                  height: 1.15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF111827))),
                          const SizedBox(height: 10),
                          Text(
                            'To keep requesting services and tracking '
                            'bookings, please update Sahulat Ghar Tak. '
                            'It only takes a moment.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 15,
                                height: 1.45,
                                color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 22),
                          _VersionTrack(
                              installed: _installed,
                              required: block.requiredVersion),
                          const SizedBox(height: 26),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: kProminentFilledButtonStyle(_kBrandBlue)
                                  .copyWith(
                                      padding: const WidgetStatePropertyAll(
                                          EdgeInsets.symmetric(vertical: 18))),
                              onPressed: block.openStore,
                              icon: const Icon(Icons.download_rounded),
                              label: const Text('Update Now'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            Platform.isIOS
                                ? 'Opens the App Store'
                                : 'Opens Google Play',
                            style: TextStyle(
                                fontSize: 12.5, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 150.ms).slideY(
                        begin: 0.08, end: 0, curve: Curves.easeOutCubic),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc(this.size, this.opacity);
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: opacity)),
      );
}

/// Logo tile with two pulsing halo rings and a small "update" badge.
class _HeroBadge extends StatelessWidget {
  const _HeroBadge();

  @override
  Widget build(BuildContext context) {
    Widget ring(double size, double alpha) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: alpha)),
          ),
        );
    return SizedBox(
      width: 230,
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ring(230, 0.18).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
              begin: const Offset(0.94, 0.94),
              end: const Offset(1.04, 1.04),
              duration: 2200.ms,
              curve: Curves.easeInOut),
          ring(180, 0.28).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
              begin: const Offset(1.03, 1.03),
              end: const Offset(0.95, 0.95),
              duration: 2200.ms,
              curve: Curves.easeInOut),
          Container(
            width: 140,
            height: 140,
            padding: const EdgeInsets.all(14),
            // The logo is a white mark, so it sits on a translucent glass
            // tile over the blue instead of a white one.
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35), width: 1.5),
            ),
            child: Image.asset('assets/icon/app_logo_transparent.png',
                fit: BoxFit.contain),
          ).animate().scale(
              begin: const Offset(0.7, 0.7),
              duration: 550.ms,
              curve: Curves.easeOutBack),
          Positioned(
            right: 38,
            bottom: 44,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kAccentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(Icons.arrow_upward_rounded,
                  color: Colors.white, size: 24),
            ).animate().scale(
                delay: 350.ms, duration: 450.ms, curve: Curves.elasticOut),
          ),
        ],
      ),
    );
  }
}

/// `v1.0.4 -> v1.0.7`: where the user is and where they need to be.
class _VersionTrack extends StatelessWidget {
  const _VersionTrack({required this.installed, required this.required});
  final String? installed;
  final String? required;

  @override
  Widget build(BuildContext context) {
    Widget pill(String label, String? v, Color bg, Color fg) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                        color: fg.withValues(alpha: 0.7))),
                const SizedBox(height: 2),
                Text(v == null || v.isEmpty ? '-' : 'v$v',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800, color: fg)),
              ],
            ),
          ),
        );
    return Row(
      children: [
        pill('YOURS', installed, const Color(0xFFF3F4F6),
            const Color(0xFF6B7280)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.arrow_forward_rounded, color: kAccentColor),
        ),
        pill('LATEST', required, kAccentColor.withValues(alpha: 0.12),
            const Color(0xFF0F8F82)),
      ],
    );
  }
}
