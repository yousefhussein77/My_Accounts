import 'package:my_accounts/core/utils/app_error.dart';
import 'package:my_accounts/core/utils/app_validators.dart';
import 'package:my_accounts/domain/models/debt_transaction.dart';
import 'package:my_accounts/domain/models/money_currency.dart';
import 'package:my_accounts/presentation/shared/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

Future<void> showTransactionFormSheet(BuildContext context, {String? personId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TransactionForm(initialPersonId: personId),
  );
}

class _TransactionForm extends ConsumerStatefulWidget {
  const _TransactionForm({this.initialPersonId});
  final String? initialPersonId;

  @override
  ConsumerState<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<_TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  DebtTransactionType _type = DebtTransactionType.debt;
  MoneyCurrency _currency = MoneyCurrency.yer;
  String? _personId;

  @override
  void initState() {
    super.initState();
    _personId = widget.initialPersonId;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(debtControllerProvider).valueOrNull;
    final people = data?.people ?? [];
    _personId ??= people.isEmpty ? null : people.first.person.id;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 8,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.sizeOf(context).height * 0.35,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'عملية جديدة',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 14),
                if (people.isEmpty)
                  const Text('أضف شخصًا أولًا قبل تسجيل العملية.')
                else ...[
                  DropdownButtonFormField<String>(
                    value: _personId,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(LucideIcons.user),
                      labelText: 'الشخص',
                    ),
                    items: people
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.person.id,
                            child: Text(item.person.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _personId = value),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<DebtTransactionType>(
                    segments: const [
                      ButtonSegment(
                        value: DebtTransactionType.debt,
                        label: Text('عليك'),
                        icon: Icon(LucideIcons.arrowUpRight),
                      ),
                      ButtonSegment(
                        value: DebtTransactionType.payment,
                        label: Text('لك'),
                        icon: Icon(LucideIcons.arrowDownLeft),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (value) =>
                        setState(() => _type = value.first),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(LucideIcons.badgeDollarSign),
                      labelText: 'المبلغ',
                    ),
                    validator: AppValidators.amount,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<MoneyCurrency>(
                    value: _currency,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(LucideIcons.coins),
                      labelText: 'العملة',
                    ),
                    items: MoneyCurrency.values
                        .map(
                          (currency) => DropdownMenuItem(
                            value: currency,
                            child: Text(currency.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _currency = value ?? MoneyCurrency.yer),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _note,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(LucideIcons.stickyNote),
                      labelText: 'ملاحظة (اختياري)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate() || _personId == null) {
                        return;
                      }
                      try {
                        await ref.read(debtControllerProvider.notifier).addTransaction(
                              personId: _personId!,
                              type: _type,
                              amount: double.parse(_amount.text.trim()),
                              currency: _currency,
                              title: _type == DebtTransactionType.debt ? 'عليك' : 'لك',
                              note: _note.text.trim(),
                            );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم تسجيل العملية')),
                        );
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppError.message(error))),
                        );
                      }
                    },
                    icon: const Icon(LucideIcons.save),
                    label: const Text('حفظ العملية'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
