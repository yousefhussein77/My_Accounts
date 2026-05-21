import 'package:my_accounts/core/utils/formatters.dart';
import 'package:my_accounts/domain/models/person_summary.dart';
import 'package:my_accounts/presentation/shared/currency_totals_view.dart';
import 'package:my_accounts/presentation/shared/status_pill.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PersonSummaryCard extends StatelessWidget {
  const PersonSummaryCard({
    required this.summary,
    required this.onTap,
    super.key,
  });

  final PersonSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final String statusLabel;
    final Color statusColor;
    final IconData statusIcon;
    if (summary.isSettled) {
      statusLabel = 'مسدد';
      statusColor = colors.primary;
      statusIcon = LucideIcons.checkCircle2;
    } else if (summary.hasMixedDirection) {
      statusLabel = 'مختلط';
      statusColor = colors.secondary;
      statusIcon = LucideIcons.scale;
    } else if (summary.hasDebt) {
      statusLabel = 'عليه';
      statusColor = colors.error;
      statusIcon = LucideIcons.badgeDollarSign;
    } else {
      statusLabel = 'له';
      statusColor = colors.primary;
      statusIcon = LucideIcons.badgeDollarSign;
    }

    final progress = summary.singleCurrencyProgress;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      summary.person.name.characters.first,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.person.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          summary.person.phone.isEmpty
                              ? 'بدون رقم هاتف'
                              : summary.person.phone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  CurrencyTotalsView(
                    totals: summary.balanceByCurrency,
                    compact: true,
                    showDirection: true,
                  ),
                  StatusPill(
                    label: statusLabel,
                    color: statusColor,
                    icon: statusIcon,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: colors.surfaceContainerHighest.withAlpha(
                    (.55 * 255).clamp(0, 255).toInt(),
                  ),
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                summary.lastActivity == null
                    ? 'لا توجد عمليات بعد'
                    : 'آخر نشاط: ${AppFormatters.date(summary.lastActivity!)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
