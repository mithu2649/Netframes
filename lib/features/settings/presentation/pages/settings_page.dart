import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netframes/features/settings/presentation/bloc/theme_bloc.dart';
import 'package:netframes/features/settings/presentation/bloc/theme_event.dart';
import 'package:netframes/features/settings/presentation/bloc/theme_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          if (state is ThemeInitial) {
            return const Center(
              child: CircularProgressIndicator(),
            ); // Show loading for initial state
          } else if (state is ThemeLoaded) {
            final List<Color> accentColors = [
              Colors.deepPurple,
              Colors.blue,
              Colors.green,
              Colors.red,
              Colors.orange,
            ];
            Color? selectedAccentColor = accentColors.firstWhere(
              (color) => color.value == state.accentColor.value,
              orElse: () => Colors.deepPurple, // Fallback if color not found
            );

            return ListView(
              children: [
                const Text(
                  'Debugging Text: Settings Page Loaded',
                ), // Added for debugging
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: state.themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    context.read<ThemeBloc>().add(
                      ThemeChanged(value ? ThemeMode.dark : ThemeMode.light),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Accent Color'),
                  trailing: DropdownButton<Color>(
                    value: selectedAccentColor,
                    onChanged: (Color? newColor) {
                      if (newColor != null) {
                        context.read<ThemeBloc>().add(
                          AccentColorChanged(newColor),
                        );
                      }
                    },
                    items: accentColors.map<DropdownMenuItem<Color>>((
                      Color value,
                    ) {
                      return DropdownMenuItem<Color>(
                        value: value,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: value,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          }
          return Container(); // Fallback for unhandled states
        },
      ),
    );
  }
}
