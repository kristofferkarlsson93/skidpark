import 'package:flutter/material.dart';

class GlideTestingIntroCard extends StatelessWidget {
  final ThemeData? theme;
  const GlideTestingIntroCard({Key? key, this.theme}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = theme ?? Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Card(
        color: themeData.colorScheme.surfaceContainerHighest,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: themeData.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.science,
                      color: themeData.colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Dina glidtester",
                          style: themeData.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Här kan du skapa och titta på glidtester. \nKlicka på + för att skapa ett nytt test",
                          style: themeData.textTheme.bodyMedium?.copyWith(
                            color: themeData.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showInfoDialog(context, themeData),
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text("Guide: Så utför du ett glidtest"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: themeData.colorScheme.primary,
                    side: BorderSide(
                      color: themeData.colorScheme.outline.withAlpha((0.3 * 255).toInt()),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        title: Row(
          children: [
            Icon(Icons.help_outline, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            const Text("Att utföra glidtest"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Appen hjälper dig att samla in sensordata under ditt åk, och pressenterar sedan data och analys",
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                "Steg för steg:",
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildStepTile(theme, "1", "Skapa ett nytt test via + knappen."),
              _buildStepTile(theme, "2", "Dra ett startstreck i snön vid en lämplig backe."),
              _buildStepTile(theme, "3", "Välj 'Nytt åk' och vilken skida du testar."),
              _buildStepTile(theme, "4", "Glid från stillastående vid strecket ner till stopp. Viktigt: Håll mobilen stilla."),
              _buildStepTile(theme, "5", "Upprepa för alla skidor du vill jämföra."),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTile(ThemeData theme, String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha((0.2 * 255).toInt()),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
