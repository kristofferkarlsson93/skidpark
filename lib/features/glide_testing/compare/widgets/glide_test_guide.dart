import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/input/hands_free_controls_factory.dart';

class GuideInstructions extends StatelessWidget {
  const GuideInstructions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _GuideStep(
          number: 1,
          title: 'Använd samma backe och startplats',
          description: 'Försök hålla samma kroppsställning under åken och telefonen på liknande sätt.',
        ),
        const _GuideStep(
          number: 2,
          title: 'Spela in ett åk',
          description: 'Tryck på Nytt åk, välj skida och starta inspelningen. Glid utan att staka. Stoppa och spara när åket är klart.',
        ),
        const _GuideStep(
          number: 3,
          title: 'Gör flera åk med varje skidpar',
          description: 'Flera åk med samma skidor hjälper dig att bedöma hur mycket resultaten varierar.',
        ),
      ],
    );
  }
}

class _GuideStep extends StatelessWidget {
  final int number;
  final String title;
  final String description;

  const _GuideStep({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 19),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text('$number.', style: theme.textTheme.bodyMedium),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GuideDetails extends StatelessWidget {
  const GuideDetails({super.key});

  @override
  Widget build(BuildContext context) {
    final controls = context.read<HandsFreeControlsFactory>();
    final instructions = controls.instructions;
    return Column(
      children: [
        const _GuideSection(
          title: 'Jämför åken',
          children: [
            _GuideParagraph(
              title: 'Översikt',
              text: 'Grafen visar hastighet över beräknad sträcka. Tryck på en åkrad för att markera dess kurva. Tryck eller dra i grafen för att läsa av.',
            ),
            _GuideParagraph(
              title: 'Välj åk att visa',
              text: 'Reglageknappen öppnar sidopanelen. Där väljer du vilka åk som visas och om du vill se enskilda åk eller medel per skida. Samma val gäller i båda analysvyerna.',
            ),
            _GuideParagraph(
              title: 'Simulerad släppunkt',
              text: 'Här räknas kurvorna om för jämförelse från en vald punkt. Flytta linjen med reglaget och tryck på Analysera från punkten.\n\nDet är en beräknad jämförelse. Resultatet visar inte säkert hur två skidåkare skulle ha glidit bredvid varandra.',
            ),
            _GuideParagraph(
              title: 'Bedöm variationen',
              text: 'Jämför skillnaden mellan skidorna med variationen mellan flera åk på samma skidor. Om åken med samma skidor skiljer sig mycket åt är det svårare att bedöma små skillnader mellan skidparen.',
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (controls.isSupported)
          _GuideSection(
            title: 'Styr med vantar',
            children: [
              _GuideParagraph(title: 'I testet', text: instructions.openRun),
              _GuideParagraph(
                title: 'I skidvalet',
                text: '${instructions.selectSki}\n\n${instructions.confirmSki}',
              ),
              _GuideParagraph(
                title: 'Under inspelningen',
                text: instructions.stopLabel != null
                    ? 'Tryck kort på ${instructions.stopLabel} för att stoppa och spara åket.'
                    : 'Gesterna är avstängda under åket. Åket sparas automatiskt vid stopp. Du kan också trycka på Spara.',
              ),
            ],
          ),
      ],
    );
  }
}

class _GuideSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _GuideSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final border = RoundedRectangleBorder(
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(10),
    );
    return ExpansionTile(
      key: PageStorageKey('guide-$title'),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      shape: border,
      collapsedShape: border,
      childrenPadding: const EdgeInsets.fromLTRB(13, 0, 13, 8),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _GuideParagraph extends StatelessWidget {
  final String? title;
  final String text;

  const _GuideParagraph({this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: theme.textTheme.titleSmall),
            const SizedBox(height: 5),
          ],
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
