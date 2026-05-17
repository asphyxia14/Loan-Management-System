import 'package:flutter/cupertino.dart';

import '../widgets/app_section_card.dart';

class ConnectionPanel extends StatefulWidget {
  const ConnectionPanel({
    super.key,
    required this.apiBaseUrlController,
    required this.hostController,
    required this.portController,
    required this.databaseController,
    required this.usernameController,
    required this.passwordController,
    required this.isConnecting,
    required this.onConnect,
  });

  final TextEditingController apiBaseUrlController;
  final TextEditingController hostController;
  final TextEditingController portController;
  final TextEditingController databaseController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool isConnecting;
  final VoidCallback onConnect;

  @override
  State<ConnectionPanel> createState() => _ConnectionPanelState();
}

class _ConnectionPanelState extends State<ConnectionPanel> {
  bool _showGuide = true;

  Widget _field(
    TextEditingController controller,
    String placeholder, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      obscureText: obscureText,
      keyboardType: keyboardType,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.systemGrey4.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool useTwoColumns = constraints.maxWidth >= 800;

          final Widget connectionForm = AppSectionCard(
            title: 'Connect to Backend and SQL Server',
            subtitle:
                'Desktop: http://127.0.0.1:8080. Android emulator: http://10.0.2.2:8080.',
            icon: CupertinoIcons.link,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _field(widget.apiBaseUrlController, 'Backend API URL'),
                const SizedBox(height: 12),
                _field(widget.hostController, 'SQL Host'),
                const SizedBox(height: 12),
                _field(
                  widget.portController,
                  'SQL Port',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _field(widget.databaseController, 'SQL Database'),
                const SizedBox(height: 12),
                _field(widget.usernameController, 'SQL Username'),
                const SizedBox(height: 12),
                _field(
                  widget.passwordController,
                  'SQL Password',
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.topLeft,
                  child: CupertinoButton.filled(
                    onPressed: widget.isConnecting ? null : widget.onConnect,
                    child: widget.isConnecting
                        ? const CupertinoActivityIndicator()
                        : const Text('Connect to SQL Server'),
                  ),
                ),
              ],
            ),
          );

          final Widget quickGuide = AppSectionCard(
            title: 'Connection Guide',
            icon: CupertinoIcons.info_circle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  '1. Ensure your Node.js backend is running (npm start).',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  '2. Enter the backend URL (usually http://127.0.0.1:8080).',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  '3. Provide your SQL Server credentials (host, port, user, password).',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  '4. If the database does not exist, the backend will attempt to create it using the provided credentials.',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      _showGuide = !_showGuide;
                    });
                  },
                  child: const Text('Toggle Advanced Info'),
                ),
                if (_showGuide)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'For local Docker setups, use host: 127.0.0.1 and port: 1433. Ensure the SQL user has permission to CREATE DATABASE if it doesn\'t exist.',
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          );

          if (useTwoColumns) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 3, child: connectionForm),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: quickGuide),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              connectionForm,
              const SizedBox(height: 16),
              quickGuide,
            ],
          );
        },
      ),
    );
  }
}
