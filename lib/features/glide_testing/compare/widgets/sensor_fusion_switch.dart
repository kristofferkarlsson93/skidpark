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
                'Under ett teståk spelar appen in data från olika sensorer. Vissa sensorer är väldigt känsliga för rörelser. När du aktiverar Sensorfusion slås datan från alla sensorer ihop. Detta ger de mest tillförlitliga siffrorna och kurvorna',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Krav för korrekt data',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'För att kunna lita på datan från alla känsliga sensorer måste telefonen ligga stilla i förhållande till skidan. Om du tex håller telefonen i handen kommer datan att ljuga.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              _buildIconRow(
                theme,
                Icons.layers,
                'Telefonen ska sitta stadigt (t.ex. kardborre på pjäxa/skida eller mot låret i fartställning).',
              ),
              _buildIconRow(
                  theme, Icons.screen_lock_portrait, 'Skärmen ska peka uppåt.'),
              _buildIconRow(
                theme,
                Icons.arrow_upward,
                'Överkanten (selfiekameran) ska peka framåt i åkriktningen.',
              ),
              const SizedBox(height: 8),
              Text(
                'Kan du inte montera telefonen enligt ovan så är det bättre att slå av sensorfusionen. Då förlitar sig appen på GPS, vilket är mer tillförlitligt om datan är brusig.',
                style: theme.textTheme.bodyMedium,
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
                'Appen spelar alltid in all rådata oavsett hur denna knapp står. Detta är endast ett analysfilter som styr vilken data används.',
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
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}