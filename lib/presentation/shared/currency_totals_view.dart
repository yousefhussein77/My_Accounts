import 'package:my_accounts/core/utils/formatters.dart';
import 'package:my_accounts/domain/models/money_currency.dart';
import 'package:flutter/material.dart';

class CurrencyTotalsView extends StatelessWidget {
  const CurrencyTotalsView({
    required this.totals,
    this.color,
    this.compact = false,
    this.showDirection = false,
    super.key,
  });

  final Map<MoneyCurrency, double> totals;
  final Color? color;
  final bool compact;
  final bool showDirection;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final activeEntries = MoneyCurrency.values
        .map((currency) => MapEntry(currency, totals[currency] ?? 0))
        .where((entry) => entry.value != 0)
        .toList();
    final entries = activeEntries.isEmpty
        ? [const MapEntry(MoneyCurrency.yer, 0.0)]
        : activeEntries;

    return Wrap(
      spacing: compact ? 6 : 8,
      runSpacing: compact ? 6 : 8,
      children: entries.map((entry) {
        final valueColor = _entryColor(colors, entry.value);
        return _CurrencyTotalChip(
          currency: entry.key,
          amount: entry.value.abs(),
          color: color ?? valueColor,
          compact: compact,
          direction: showDirection ? _directionLabel(entry.value) : null,
        );
      }).toList(),
    );
  }

  Color _entryColor(ColorScheme colors, double value) {
    if (!showDirection || value == 0) {
      return colors.primary;
    }
    return value > 0 ? colors.error : colors.primary;
  }

  String? _directionLabel(double value) {
    if (value > 0) return 'عليه';
    if (value < 0) return 'له';
    return null;
  }
}

class _CurrencyTotalChip extends StatelessWidget {
  const _CurrencyTotalChip({
    required this.currency,
    required this.amount,
    required this.color,
    required this.compact,
    required this.direction,
  });

  final MoneyCurrency currency;
  final double amount;
  final Color color;
  final bool compact;
  final String? direction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 38),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 7 : 9,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha((.10 * 255).clamp(0, 255).toInt()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withAlpha((.22 * 255).clamp(0, 255).toInt()),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 28 : 32,
            height: compact ? 28 : 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withAlpha((.16 * 255).clamp(0, 255).toInt()),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              currency.symbol,
              style: textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(width: compact ? 7 : 9),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppFormatters.amount(amount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (compact ? textTheme.labelLarge : textTheme.titleMedium)
                    ?.copyWith(color: color, fontWeight: FontWeight.w900),
              ),
              Text(
                direction == null
                    ? currency.label
                    : '$direction - ${currency.label}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
