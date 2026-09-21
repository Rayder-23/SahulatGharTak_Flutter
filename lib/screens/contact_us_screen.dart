import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/constants.dart';
import '../widgets/app_toast.dart';
import '../widgets/auth_card_scaffold.dart';

class ContactUsScreen extends StatelessWidget {
  static const routeName = '/contact-us';

  static const phone1Display = '0313-5355770';
  static const phone1Digits = '03135355770';
  static const phone1WhatsApp = '923135355770';

  static const phone2Display = '0325-5763450';
  static const phone2Digits = '03255763450';
  static const phone2WhatsApp = '923255763450';

  static const email = 'sahulatghartak@gmail.com';

  /// Official WhatsApp brand green.
  static const whatsAppGreen = Color(0xFF25D366);

  const ContactUsScreen({super.key});

  Future<void> _launch(
    BuildContext context,
    Uri uri,
    String failMessage,
  ) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      showAppToast(context, failMessage, type: AppToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthCardScaffold(
      title: 'Contact Us',
      subtitle: 'Reach Sahulat Ghar Tak support',
      avatarIcon: Icons.support_agent_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PhoneContactTile(
            label: 'Contact us at',
            displayNumber: phone1Display,
            onCall: () => _launch(
              context,
              Uri(scheme: 'tel', path: phone1Digits),
              'Could not start a call.',
            ),
            onWhatsApp: () => _launch(
              context,
              Uri.parse('https://wa.me/$phone1WhatsApp'),
              'Could not open WhatsApp.',
            ),
          ),
          const SizedBox(height: 12),
          _PhoneContactTile(
            label: 'Contact us at',
            displayNumber: phone2Display,
            onCall: () => _launch(
              context,
              Uri(scheme: 'tel', path: phone2Digits),
              'Could not start a call.',
            ),
            onWhatsApp: () => _launch(
              context,
              Uri.parse('https://wa.me/$phone2WhatsApp'),
              'Could not open WhatsApp.',
            ),
          ),
          const SizedBox(height: 12),
          _EmailContactTile(
            email: email,
            onTap: () => _launch(
              context,
              Uri(scheme: 'mailto', path: email),
              'Could not open email.',
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneContactTile extends StatelessWidget {
  final String label;
  final String displayNumber;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  const _PhoneContactTile({
    required this.label,
    required this.displayNumber,
    required this.onCall,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kPrimaryColor.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onCall,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.phone_outlined,
                            color: kPrimaryColor),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              displayNumber,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Tooltip(
              message: 'WhatsApp',
              child: Material(
                color: ContactUsScreen.whatsAppGreen,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onWhatsApp,
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(Icons.chat, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmailContactTile extends StatelessWidget {
  final String email;
  final VoidCallback onTap;

  const _EmailContactTile({
    required this.email,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kPrimaryColor.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.email_outlined, color: kPrimaryColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email Address',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}
