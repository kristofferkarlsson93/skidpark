import 'package:flutter/material.dart';

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
    return SwitchListTile(
      contentPadding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
      title: Text(
        'Sensor fusion',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight:
              FontWeight.w500,
        ),
      ),
      activeThumbColor: theme.colorScheme.primaryContainer,
      activeTrackColor: theme.colorScheme.primary,
      inactiveThumbColor: theme.colorScheme.onSurfaceVariant,
      inactiveTrackColor: Colors.transparent,
      trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return null;
        }
        return theme.colorScheme.onSurfaceVariant;
      }),
      thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
        if (states.contains(WidgetState.selected)) {
          return Icon(
            Icons.check,
            size: 16,
            color: theme.colorScheme.onPrimaryContainer,
          );
        }
        return Icon(Icons.close, size: 16, color: theme.colorScheme.surface);
      }),
      value: isActive,
      onChanged: onChanged,
      secondary: IconButton(
        icon: const Icon(Icons.info_outlined),
        color: theme.colorScheme.primary,
        tooltip: "Mer information",
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              title: const Text('Sensor Fusion'),
              content: const Text(
                'Appen samlar in data från flera olika sensorer för att mäta ett åk. Vissa sensorer är väldigt känsliga för små rörelser. \n\n'
                'Genom att aktivera sensor-fusionsläget slår du ihop datan från alla sensorer och får de mest exakta värdena och mest tillförlitliga kurvorna. \n\n'
                'MEN - Detta kräver att du kan montera din telefon på ett stadigt och korrekt sätt. Kan du inte göra detta rekommenderas att ha detta läge avstängt.\n\n'
                'Att montera korrekt:\n'
                '- Telefonen ska ha skärmen uppåt, och den främre kortsidan (där selfie-kameran sitter) i åkriktningen\n'
                '- Telefonen ska monteras så att den är så stilla som möjligt. Tex på ditt lår i fartställning, eller på din skida eller pjäxa\n\n'
                'OBS: Vikten av ovanstående kan inte nog understrykas. För att kunna lita på datan krävs nogrannhet i dessa punkter.',

              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Jag förstår'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
