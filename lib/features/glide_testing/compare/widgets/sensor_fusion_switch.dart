import 'package:flutter/material.dart';
import '../../../../common/shared_widgets/styled_switch_list_tile.dart';

class SensorFusionToggle extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onChanged;

  const SensorFusionToggle({
    super.key,
    required this.isActive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StyledSwitchListTile(
      title: 'Sensorfusion',
      value: isActive,
      onChanged: onChanged,
      secondary: IconButton(
        icon: const Icon(Icons.info_outlined),
        color: theme.colorScheme.primary,
        tooltip: "Mer information",
        onPressed: () => _showInfoDialog(context, theme),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        title: const Text('Om Sensorfusion'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sensorfusion slår ihop data från GPS och accelerometer för att ge mjukare och mer exakta kurvor. För att detta ska fungera måste sensorerna förstå vad som är framåt och vad som är rörelse.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              Text(
                'Hur du bär telefonen',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Det finns två sätt att göra detta på:',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),

              _buildIconRow(
                theme,
                Icons.verified,
                'Bäst precision: Montera telefonen stadigt, t.ex. med kardborre på pjäxan eller skidan',
              ),

              _buildIconRow(
                theme,
                Icons.handshake_outlined,
                'Hålla i handen: Det fungerar tack vare avancerade filter, men kräver att du håller stilla. Undvik yviga rörelser, att ändra vinkel eller justera greppet under glidmomentet.',
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Viktigt! Oavsett hur du gör:',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildIconRow(
                      theme,
                      Icons.screen_lock_portrait,
                      'Skärmen ska peka uppåt.',
                    ),
                    _buildIconRow(
                      theme,
                      Icons.arrow_upward,
                      'Överkanten (selfiekameran) MÅSTE peka framåt i åkriktningen.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'Ingen data går förlorad',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Appen spelar alltid in all rådata. Detta är endast ett filter. Om du märker att grafen ser konstig ut i efterhand (t.ex. om du råkade vifta med handen) kan du slå av sensorfusionen då.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Jag förstår'),
          ),
        ],
      ),
    );
  }

  Widget _buildIconRow(ThemeData theme, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
