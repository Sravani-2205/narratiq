import 'package:flutter/material.dart';
import '../../app/routes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _SectionHeader('Playback'),
          ListTile(
            leading: const Icon(Icons.record_voice_over, color: Color(0xFF6B4EFF)),
            title: const Text('Voice Settings'),
            subtitle: const Text('Accents, naturalisation, pronunciation'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, AppRoutes.voiceSettings),
          ),
          const Divider(indent: 16, endIndent: 16),
          _SectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Color(0xFF6B4EFF)),
            title: const Text('Narratiq'),
            subtitle: const Text('Version 1.0.0 · Built with Flutter'),
          ),
          ListTile(
            leading: const Icon(Icons.code, color: Color(0xFF6B4EFF)),
            title: const Text('Open Source'),
            subtitle: const Text('Free forever · No ads · No subscriptions'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }
}
