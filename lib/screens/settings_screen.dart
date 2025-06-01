import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;
  String selectedLanguage = 'id';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Mode Gelap'),
              value: isDarkMode,
              onChanged: (value) {
                setState(() {
                  isDarkMode = value;
                });
                // TODO: Integrasikan dengan provider/theme logic
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Bahasa:'),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: selectedLanguage,
                  items: const [
                    DropdownMenuItem(
                      value: 'id',
                      child: Text('Bahasa Indonesia'),
                    ),
                    DropdownMenuItem(
                      value: 'en',
                      child: Text('English'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedLanguage = value!;
                    });
                    // TODO: Integrasikan dengan provider/locale logic
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
