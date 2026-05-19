import 'package:debt_ledger_app/core/utils/app_error.dart';
import 'package:debt_ledger_app/core/utils/app_validators.dart';
import 'package:debt_ledger_app/domain/models/debt_person.dart';
import 'package:debt_ledger_app/presentation/shared/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

Future<void> showPersonFormSheet(BuildContext context, {DebtPerson? person}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PersonForm(person: person),
  );
}

class _PersonForm extends ConsumerStatefulWidget {
  const _PersonForm({this.person});

  final DebtPerson? person;

  @override
  ConsumerState<_PersonForm> createState() => _PersonFormState();
}

class _PersonFormState extends ConsumerState<_PersonForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.person?.name);
    _phone = TextEditingController(text: widget.person?.phone);
    _note = TextEditingController(text: widget.person?.note);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            minHeight: MediaQuery.sizeOf(context).height * 0.25,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.person == null ? 'إضافة شخص' : 'تعديل الشخص',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(LucideIcons.user),
                    labelText: 'الاسم',
                  ),
                  validator: AppValidators.name,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(LucideIcons.phone),
                    labelText: 'رقم الهاتف',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _note,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(LucideIcons.stickyNote),
                    labelText: 'ملاحظة',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    try {
                      await ref.read(debtControllerProvider.notifier).savePerson(
                            id: widget.person?.id,
                            name: _name.text.trim(),
                            phone: _phone.text.trim(),
                            note: _note.text.trim(),
                          );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم حفظ الشخص')),
                      );
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppError.message(error))),
                      );
                    }
                  },
                  icon: const Icon(LucideIcons.save),
                  label: const Text('حفظ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
