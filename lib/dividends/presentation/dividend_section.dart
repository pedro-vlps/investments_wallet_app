import 'package:flutter/material.dart';

import '../../app/wallet_theme.dart';

class DividendSection extends StatelessWidget {
  const DividendSection({
    required this.title,
    required this.filter,
    required this.child,
    super.key,
  });
  final String title;
  final Widget filter;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: WalletColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: WalletColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final heading = Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            );
            return constraints.maxWidth < 600
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [heading, const SizedBox(height: 12), filter],
                  )
                : Row(
                    children: [
                      Expanded(child: heading),
                      filter,
                    ],
                  );
          },
        ),
        const SizedBox(height: 20),
        child,
      ],
    ),
  );
}
