import 'package:flutter/material.dart';

import '../../app/wallet_theme.dart';

Color? returnColor(int gainCents) => switch (gainCents) {
  > 0 => WalletColors.accent,
  < 0 => WalletColors.loss,
  _ => null,
};
