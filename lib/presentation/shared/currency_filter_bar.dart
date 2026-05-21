import 'package:flutter/material.dart';
import 'package:my_accounts/domain/models/money_currency.dart';

class CurrencyFilterBar extends StatelessWidget {
  const CurrencyFilterBar({
    required this.selectedCurrency,
    required this.currencyCounts,
    required this.totalCount,
    required this.onSelected,
    super.key,
  });

  final MoneyCurrency? selectedCurrency;
  final Map<MoneyCurrency, int> currencyCounts;
  final int totalCount;
  final ValueChanged<MoneyCurrency?> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChipButton(
            label: 'الكل ($totalCount)',
            selected: selectedCurrency == null,
            onTap: () => onSelected(null),
            color: colors.primary,
          ),
          const SizedBox(width: 8),
          ...MoneyCurrency.values.map(
            (currency) => Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: _FilterChipButton(
                label: _currencyLabel(currency),
                selected: selectedCurrency == currency,
                onTap: () => onSelected(currency),
                color: colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _currencyLabel(MoneyCurrency currency) {
    final count = currencyCounts[currency] ?? 0;
    return '${currency.symbol} ${currency.label} ($count)';
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? color.withAlpha((.13 * 255).clamp(0, 255).toInt())
          : colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? color : colors.outlineVariant,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? color : colors.onSurface,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
