import 'package:flutter/material.dart';

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

class _UpdateBlockScreen extends StatelessWidget {
  const _UpdateBlockScreen(this.block);
  final UpdateBlock block;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                        color: kPrimaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.system_update_rounded,
                        size: 48, color: kPrimaryColor),
                  ),
                  const SizedBox(height: 24),
                  const Text('Update required',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Text(
                    'A new version of Sahulat Ghar Tak (${block.requiredVersion}) '
                    'is available. Please update to keep using the app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15, color: Colors.grey[700], height: 1.4),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: kProminentFilledButtonStyle(kPrimaryColor),
                      onPressed: block.openStore,
                      child: const Text('Update Now'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
