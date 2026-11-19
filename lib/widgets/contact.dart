import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'common.dart';

String _digits(String phone) => phone.replaceAll(RegExp(r'[^\d+]'), '');

Future<void> _launch(BuildContext context, Uri uri, String failMessage) async {
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) showSnack(context, failMessage, error: true);
  } catch (_) {
    if (context.mounted) showSnack(context, failMessage, error: true);
  }
}

Future<void> callPhone(BuildContext context, String phone) async {
  if (phone.trim().isEmpty) return showSnack(context, 'No phone number available', error: true);
  await _launch(context, Uri(scheme: 'tel', path: _digits(phone)), 'Could not open the dialer');
}

/// Opens WhatsApp chat. Ten-digit numbers are assumed to be Indian (+91).
Future<void> openWhatsApp(BuildContext context, String phone, {String? message}) async {
  if (phone.trim().isEmpty) return showSnack(context, 'No phone number available', error: true);
  var digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 10) digits = '91$digits';
  final uri = Uri.https('wa.me', '/$digits', {if (message != null && message.isNotEmpty) 'text': message});
  await _launch(context, uri, 'Could not open WhatsApp');
}

Future<void> sendEmail(BuildContext context, String email) async {
  if (email.trim().isEmpty) return;
  await _launch(context, Uri(scheme: 'mailto', path: email.trim()), 'Could not open email app');
}

Future<void> copyText(BuildContext context, String text, {String label = 'Copied'}) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) showSnack(context, label);
}

/// [Call]  [WhatsApp] button pair from the design.
class ContactButtons extends StatelessWidget {
  const ContactButtons({super.key, required this.phone, this.whatsappMessage});
  final String phone;
  final String? whatsappMessage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(label: 'Call', icon: Icons.call_outlined, style: AppButtonStyle.outline, height: 50, onPressed: () => callPhone(context, phone)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            label: 'WhatsApp',
            icon: Icons.chat_outlined,
            style: AppButtonStyle.whatsapp,
            height: 50,
            onPressed: () => openWhatsApp(context, phone, message: whatsappMessage),
          ),
        ),
      ],
    );
  }
}
