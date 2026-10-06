import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/repositories/notification_repository.dart';
import '../models/app_config.dart';
import '../utils/constants.dart';

/// Opens the store listing; shared by the blocking screen and the prompt.
Future<void> openStore(AppConfig config) async {
  try {
    var url = config.storeUrl;
    if (url.isEmpty) {
      // A push may carry no store_url; fall back to the server config.
      final fresh = await NotificationRepository()
          .fetchAppConfig(Platform.isIOS ? 'ios' : 'android');
      url = fresh.storeUrl;
    }
    if (url.isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
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

/// Dismissable, branded prompt for an optional update (installed version is
/// below `latest_version` but not below the minimum and not forced).
Future<void> showUpdatePrompt(BuildContext context, AppConfig config) async {
  String? installed;
  try {
    installed = (await PackageInfo.fromPlatform()).version;
  } catch (_) {}
  if (!context.mounted) return;
  return showDialog<void>(
    context: context,
    builder: (ctx) => _UpdatePromptDialog(config: config, installed: installed),
  );
}

class _UpdatePromptDialog extends StatelessWidget {
  const _UpdatePromptDialog({required this.config, this.installed});
  final AppConfig config;
  final String? installed;

  @override
  Widget build(BuildContext context) {
    final message = config.updateMessage.isNotEmpty
        ? config.updateMessage
        : 'A new version of Sahulat Ghar Tak is available with the latest '
            'improvements and fixes.';
    return Dialog(
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Brand header, matching the forced-update screen.
          Container(
            width: double.infinity,
            height: 120,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A84FF), Color(0xFF016EE3), kPrimaryColor],
              ),
            ),
            child: Center(
              child: Container(
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                ),
                child: Image.asset('assets/icon/app_logo_transparent.png',
                    fit: BoxFit.contain),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Update available',
                    style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827))),
                const SizedBox(height: 8),
                Text(message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14.5, color: Colors.grey[700], height: 1.4)),
                if (installed != null && config.latestVersion.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _VersionPill(label: 'v$installed', highlighted: false),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward_rounded,
                            size: 18, color: kAccentColor),
                      ),
                      _VersionPill(
                          label: 'v${config.latestVersion}', highlighted: true),
                    ],
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: kProminentFilledButtonStyle(const Color(0xFF016EE3)),
                    onPressed: () {
                      Navigator.of(context).pop();
                      openStore(config);
                    },
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Update now'),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Maybe later',
                      style: TextStyle(color: Colors.grey[600])),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionPill extends StatelessWidget {
  const _VersionPill({required this.label, required this.highlighted});
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: highlighted
              ? kAccentColor.withValues(alpha: 0.12)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: highlighted
                    ? const Color(0xFF0F8F82)
                    : const Color(0xFF6B7280))),
      );
}
