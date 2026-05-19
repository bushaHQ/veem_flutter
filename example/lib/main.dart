// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:veem_flutter/veem_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // In a real app, your clientId comes from a build-time env / dart-define.
  // Per-customer credentials (accountId, sessionSecret) are fetched from
  // your backend, not hardcoded.
  await Veem.initialize(
    const VeemConfig(
      environment: VeemEnvironment.sandbox,
      clientId: 'YOUR_VEEM_CLIENT_ID',
      enableLogging: true,
      enableWebViewDebugging: true,
    ),
  );

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veem Flutter Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0076F7)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _lastFundingId;
  String? _lastDisplayName;
  String? _lastError;

  // In production, your backend calls Veem's search-customer-by-email
  // endpoint and returns these to your app. Hardcoded here for the
  // example only.
  CardPluginConfig _buildConfig() {
    return const CardPluginConfig(
      accountId: 391558,
      sessionSecret: 'replace-with-session-secret-from-your-backend',
      referenceId: 'example_order_001',
      preset: CardPreset(amount: 500, currencyCode: 'USD'),
      headerText: 'Add your payment card',
    );
  }

  Future<void> _presentModal() async {
    final result = await Veem.card
        .present(context, config: _buildConfig(), title: 'Add card');

    if (!mounted) return;

    setState(() {
      _lastError = null;
      _lastFundingId = null;
      _lastDisplayName = null;
    });

    switch (result) {
      case CardPluginCompleted(:final userInputs):
        setState(() {
          _lastFundingId = userInputs.paymentMethod.fundingMethod.id.toString();
          _lastDisplayName = userInputs.paymentMethod.displayName;
        });
      case CardPluginErrored(:final error):
        setState(() => _lastError = '${error.code.name}: ${error.message}');
      case CardPluginExited():
    }
  }

  void _openEmbeddedScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EmbeddedExampleScreen(config: _buildConfig()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Veem Flutter — Example')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: _presentModal,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Present card plugin (modal)'),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _openEmbeddedScreen,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Open embedded card plugin'),
              ),
            ),
            const SizedBox(height: 32),
            if (_lastFundingId != null)
              _ResultCard(
                title: 'Card added',
                body:
                    'Funding id: $_lastFundingId\nDisplay: ${_lastDisplayName ?? "—"}',
                color: Colors.green.shade50,
              ),
            if (_lastError != null)
              _ResultCard(
                title: 'Error',
                body: _lastError!,
                color: Colors.red.shade50,
              ),
          ],
        ),
      ),
    );
  }
}

class EmbeddedExampleScreen extends StatelessWidget {
  const EmbeddedExampleScreen({required this.config, super.key});

  final CardPluginConfig config;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Embedded card plugin')),
      body: VeemCardPlugin(
        config: config,
        onCompleted: (event) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Completed: funding id ${event.userInputs.paymentMethod.fundingMethod.id}',
              ),
            ),
          );
          Navigator.of(context).pop();
        },
        onExited: () => Navigator.of(context).pop(),
        onErrored: (err) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${err.message}')),
          );
        },
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.title,
    required this.body,
    required this.color,
  });

  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(body),
        ],
      ),
    );
  }
}
