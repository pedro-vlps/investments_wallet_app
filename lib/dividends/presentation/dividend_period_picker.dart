import 'package:flutter/material.dart';

import '../domain/dividend_period.dart';

class DividendPeriodPicker extends StatelessWidget {
  const DividendPeriodPicker({
    required this.value,
    required this.onChanged,
    required this.label,
    this.extendedPeriods = false,
    super.key,
  });
  final DividendPeriod value;
  final ValueChanged<DividendPeriod> onChanged;
  final String label;
  final bool extendedPeriods;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: SizedBox(
      width: 240,
      child: DropdownButton<DividendPeriod>(
        isExpanded: true,
        value: value,
        items: DividendPeriod.values
            .where(
              (p) =>
                  extendedPeriods ||
                  (p != DividendPeriod.twoYears &&
                      p != DividendPeriod.fiveYears),
            )
            .map(
              (p) => DropdownMenuItem(
                value: p,
                child: Text(
                  p.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (period) {
          if (period != null) onChanged(period);
        },
      ),
    ),
  );
}
