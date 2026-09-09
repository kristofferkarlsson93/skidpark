import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../common/shared_widgets/app_brand_title.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  final String _developerEmail = "minskidpark@gmail.com";

  Future<void> _sendEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: _developerEmail,
      query: 'subject=Feedback SkidPark Beta',
    );

    try {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kunde inte öppna mail-appen.")),
        );
      }
    }
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _developerEmail));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Adressen kopierad: $_developerEmail'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const AppBrandTitle()),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Mer', style: theme.textTheme.titleLarge),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "BETA-VERSION",
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                "Har du frågor eller hittat en bugg?",
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 12),

              _ContactActions(
                onSendEmail: () => _sendEmail(context),
                onCopyEmail: () => _copyToClipboard(context),
              ),

              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh.withAlpha(
                    (0.5 * 255).toInt(),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.save_alt,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Exportera glidtest',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vill du bifoga data i en buggrapport? Inne på varje glidtest kan du klicka på menyn (tre prickar) för att exportera all rådata.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha((0.1 * 255).toInt()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withAlpha((0.3 * 255).toInt()),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Om precision & mätning',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Denna app använder mobilens inbyggda GPS och accelerometer. Mätvärden kan påverkas av telefonmodell, väder och placering.\n\nSkidPark är ett verktyg för att hitta trender och skillnader, men ska ses som ett komplement till – och inte en ersättning för – traditionell känsla och testning.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactActions extends StatelessWidget {
  const _ContactActions({required this.onSendEmail, required this.onCopyEmail});

  final VoidCallback onSendEmail;
  final VoidCallback onCopyEmail;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final useStackedLayout = constraints.maxWidth < 340 || textScale > 1.2;
        final emailButton = FilledButton.icon(
          onPressed: onSendEmail,
          icon: const Icon(Icons.send_rounded, size: 18),
          label: Text(
            useStackedLayout ? 'Maila oss' : 'Maila minskidpark@gmail.com',
          ),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            visualDensity: VisualDensity.compact,
          ),
        );
        final copyButton = TextButton(
          onPressed: onCopyEmail,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            visualDensity: VisualDensity.compact,
          ),
          child: const Text('Kopiera adress'),
        );

        if (useStackedLayout) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [emailButton, const SizedBox(height: 4), copyButton],
          );
        }

        return Row(
          children: [
            Expanded(flex: 4, child: emailButton),
            const SizedBox(width: 8),
            copyButton,
          ],
        );
      },
    );
  }
}
