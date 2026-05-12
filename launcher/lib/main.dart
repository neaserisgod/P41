import 'package:flutter/material.dart';

import 'src/p41_bootstrap_app.dart';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(P41BootstrapApp(updateMode: args.contains('--update')));
}
