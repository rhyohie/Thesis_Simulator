import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'state/app_controller.dart';

class SimulatorApp extends StatefulWidget {
  const SimulatorApp({super.key, this.autoConnect = true});

  /// Tests pass false so no network call is made on start-up.
  final bool autoConnect;

  @override
  State<SimulatorApp> createState() => _SimulatorAppState();
}

class _SimulatorAppState extends State<SimulatorApp> {
  late final AppController _controller = AppController();

  @override
  void initState() {
    super.initState();
    if (widget.autoConnect) {
      _controller.connect();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cacao Pod Model Simulator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D5B)),
        useMaterial3: true,
      ),
      home: HomeScreen(controller: _controller),
    );
  }
}
