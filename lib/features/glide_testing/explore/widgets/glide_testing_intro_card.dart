import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class GlideTestingIntroCard extends StatelessWidget {
  const GlideTestingIntroCard({
    super.key,
    required this.onCreateTest,
    this.onLongPressGuide,
  });

  final VoidCallback onCreateTest;
  final VoidCallback? onLongPressGuide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF45405F)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF242037), Color(0xFF191A22)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GLIDTESTER FÖR LÄNGDSKIDÅKARE',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Bättre underlag för dagens skidval.',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 28,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Jämför dina skidor med upprepade glidåk. Granska kurvor och '
              'datakvalitet – du gör själv bedömningen.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onCreateTest,
                child: const Text('Skapa mitt första test'),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _showGuide(context),
                onLongPress: kDebugMode ? onLongPressGuide : null,
                icon: const Icon(Icons.info_outline_rounded, size: 19),
                label: const Text('Så gör du ett glidtest'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGuide(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Så gör du ett glidtest'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SkidPark samlar in sensordata under åket och gör det möjligt '
                'att jämföra flera glidåk.',
              ),
              SizedBox(height: 20),
              _GuideStep(number: 1, text: 'Skapa ett test.'),
              _GuideStep(
                number: 2,
                text: 'Markera en tydlig startpunkt i en lämplig backe.',
              ),
              _GuideStep(number: 3, text: 'Välj Nytt åk och rätt skida.'),
              _GuideStep(
                number: 4,
                text:
                    'Glid från stillastående till stopp. Håll mobilen stilla '
                    'med kortsidan framåt.',
              ),
              _GuideStep(
                number: 5,
                text: 'Upprepa åket med skidorna du vill jämföra.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stäng'),
          ),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$number',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
