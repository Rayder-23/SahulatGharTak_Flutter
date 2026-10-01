import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_config.dart';
import '../utils/constants.dart';

/// Opens the store listing; shared by the blocking screen and the prompt.
Future<void> openStore(AppConfig config) async {
  if (config.storeUrl.isEmpty) return;
  try {
    await launchUrl(Uri.parse(config.storeUrl),
        mode: LaunchMode.externalApplication);
  } catch (_) {}
}

/// Non-dismissable screen shown when the installed version is below the
/// server's minimum (or a forced update is pending).
class UpdateRequiredScreen extends StatelessWidget {
  final AppConfig config;
  const UpdateRequiredScreen({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final message = config.updateMessage.isNotEmpty
        ? config.updateMessage
        : 'A new version of Sahulat Ghar Tak is required to continue.';
    return PopScope(
      canPop: false,
      child: Scaffold(
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
                  Text(message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 15, color: Colors.grey[700], height: 1.4)),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: kProminentFilledButtonStyle(kPrimaryColor),
                      onPressed: () => openStore(config),
                      child: const Text('Update now'),
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

/// Dismissable prompt for an optional update.
Future<void> showUpdatePrompt(BuildContext context, AppConfig config) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Update available'),
      content: Text(config.updateMessage.isNotEmpty
          ? config.updateMessage
          : 'A new version of Sahulat Ghar Tak is available.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Later')),
        FilledButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            openStore(config);
          },
          child: const Text('Update'),
        ),
      ],
    ),
  );
}
