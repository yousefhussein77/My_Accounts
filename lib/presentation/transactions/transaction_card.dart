import 'package:my_accounts/core/utils/formatters.dart';
import 'package:my_accounts/domain/models/debt_transaction.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TransactionCard extends StatelessWidget {
  const TransactionCard({
    required this.transaction,
    required this.personName,
    super.key,
  });

  final DebtTransaction transaction;
  final String personName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDebt = transaction.type == DebtTransactionType.debt;
    final color = isDebt ? colors.error : colors.primary;
    final label = isDebt ? 'عليك' : 'لك';
    final dueDate = transaction.dueDate;
    final isOverdue = transaction.isOverdue;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withAlpha((.13 * 255).clamp(0, 255).toInt()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isDebt ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    personName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  if (isDebt && dueDate != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isOverdue
                              ? LucideIcons.alertCircle
                              : LucideIcons.calendarClock,
                          size: 14,
                          color: isOverdue
                              ? colors.error
                              : colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            isOverdue
                                ? 'متأخرة منذ ${AppFormatters.date(dueDate)}'
                                : 'تستحق في ${AppFormatters.date(dueDate)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: isOverdue
                                      ? colors.error
                                      : colors.onSurfaceVariant,
                                  fontWeight: isOverdue
                                      ? FontWeight.w700
                                      : null,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              AppFormatters.money(transaction.amount, transaction.currency),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
