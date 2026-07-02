import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: TernakKuApp(),
    ),
  );
}

class TernakKuApp extends ConsumerWidget {
  const TernakKuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouter);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'TernakKu',
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}