import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

import 'package:app_links/app_links.dart';

void main() {
  runApp(
    const ProviderScope(
      child: TernakKuApp(),
    ),
  );
}

class TernakKuApp extends ConsumerStatefulWidget { // Ubah ke ConsumerStatefulWidget
  const TernakKuApp({super.key});
  @override
  ConsumerState<TernakKuApp> createState() => _TernakKuAppState();
}

class _TernakKuAppState extends ConsumerState<TernakKuApp> {
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _handleIncomingLinks();
  }

  void _handleIncomingLinks() async {
    // 1. Tangkap link saat aplikasi baru dibuka
    final uri = await _appLinks.getInitialLink();
    if (uri != null) _processUri(uri);

    // 2. Tangkap link saat aplikasi sedang berjalan di background
    _appLinks.uriLinkStream.listen((uri) {
      _processUri(uri);
    });
  }

  void _processUri(Uri uri) {
    // Gunakan ref.read untuk push path dari URI ke goRouter
    // Contoh: ternakku://reset-password?token=abc
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(goRouter);
      // uri.scheme => ternakku
      // uri.host   => reset-password
      // uri.path   => ""
      // uri.query  => token=...
      final fullPath = '/${uri.host}?${uri.query}';
      router.go(fullPath);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouter);
    
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'TernakKu',
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}