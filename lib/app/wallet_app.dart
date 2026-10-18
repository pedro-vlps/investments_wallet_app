import 'package:flutter/material.dart';

import 'portfolio_bootstrap.dart';
import 'wallet_theme.dart';

class WalletApp extends StatelessWidget {
  const WalletApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Local Wallet',
    debugShowCheckedModeBanner: false,
    theme: buildWalletTheme(),
    darkTheme: buildWalletTheme(),
    themeMode: ThemeMode.dark,
    home: const PortfolioBootstrap(),
  );
}
