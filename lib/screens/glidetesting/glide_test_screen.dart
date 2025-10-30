import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/database/repository/glide_test_repository.dart';
import 'package:skidpark/screens/glidetesting/run_recording_screen.dart';

class GlideTestScreen extends StatelessWidget {
  final int glideTestId;

  const GlideTestScreen({super.key, required this.glideTestId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glideTestRepository = context.read<GlideTestRepository>();
    return StreamBuilder(
      stream: glideTestRepository.watchTestById(this.glideTestId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final glideTest = snapshot.data!;
        return Scaffold(
          appBar: AppBar(title: Text(glideTest.title)),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final hasPermission = await _handleLocationPermission(context);
              if (!hasPermission) return;
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (context) =>
                        RunRecorderScreen(glideTestId: glideTestId),
                  ),
                );
              }
            },
            icon: Icon(Icons.play_circle_outline),
            label: Text("Spela in teståk"),
          ),
          body: Center(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    InkWell(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: theme.colorScheme.surfaceContainer,
                            child: Icon(
                              Icons.edit_note_sharp,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text("Testinfo"),
                        ],
                      ),
                    ),
                    InkWell(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: theme.colorScheme.surfaceContainer,
                            child: SvgPicture.asset(
                              'assets/icons/ski_icon.svg',
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(
                                theme.colorScheme.onSurface,
                                BlendMode.srcIn,
                              ),
                              semanticsLabel: 'Skis icon',
                            ),
                          ),
                          SizedBox(height: 4),
                          Text("Skidor"),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Divider(color: theme.colorScheme.onSurfaceVariant),
                ),
                Container(
                  child: Text("Teståk", style: theme.textTheme.headlineSmall),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _handleLocationPermission(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Platstjänster är inaktiverade. Aktivera GPS och försök igen.',
          ),
        ),
      );
      return false;
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        if (!context.mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Behörighet till platsdata nekades.')),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Behörighet är permanent nekad. Du måste ändra detta i app-inställningarna.',
          ),
        ),
      );
      return false;
    }

    return true;
  }
}
