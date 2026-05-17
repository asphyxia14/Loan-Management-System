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
        color: CupertinoColors.systemGrey5,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CupertinoColors.separator),
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
                  'SQL Password (Docker MSSQL_SA_PASSWORD)',
                  obscureText: true,
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.topLeft,
                  child: CupertinoButton.filled(
                    onPressed: widget.isConnecting ? null : widget.onConnect,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (widget.isConnecting) ...<Widget>[
                          const CupertinoActivityIndicator(),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.isConnecting
                              ? 'Connecting...'
                              : 'Connect and Initialize Schema',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );

          final Widget quickGuideContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('1. Start the backend server in the backend folder.'),
              const SizedBox(height: 8),
              const Text(
                '2. Confirm SQL Server is running and port 1433 is open.',
              ),
              const SizedBox(height: 8),
              const Text('3. Use the exact SA password from your Docker setup.'),
              const SizedBox(height: 8),
              const Text(
                '4. Keep database name as PQRCooperative unless customized.',
              ),
            ],
          );

          final Widget quickGuide = AppSectionCard(
            title: 'Quick Start',
            subtitle: 'Use this checklist if connection fails.',
            icon: CupertinoIcons.check_mark_circled,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _showGuide
                  ? quickGuideContent
                  : const Text('Quick tips hidden.'),
            ),
          );

          if (useTwoColumns) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 3, child: connectionForm),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Text(
                            'Quick Start',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              setState(() {
                                _showGuide = !_showGuide;
                              });
                            },
                            child: Icon(
                              _showGuide
                                  ? CupertinoIcons.chevron_up
                                  : CupertinoIcons.chevron_down,
                              size: 18,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      quickGuide,
                    ],
                  ),
                ),
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
