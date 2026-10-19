import 'package:flutter/material.dart';

import '../domain/tax_month.dart';
import 'tax_controller.dart';
import 'tax_money_field.dart';

class TaxEntryDialog extends StatefulWidget {
  const TaxEntryDialog({
    required this.controller,
    this.month,
    this.opening = false,
    super.key,
  });
  final TaxController controller;
  final TaxMonth? month;
  final bool opening;

  @override
  State<TaxEntryDialog> createState() => _TaxEntryDialogState();
}

class _TaxEntryDialogState extends State<TaxEntryDialog> {
  final _form = GlobalKey<FormState>();
  late final List<TextEditingController> _fields;
  late final TextEditingController _notes;
  late int _month;
  bool _confirmed = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final opening = widget.controller.data.opening;
    final values = widget.opening
        ? [
            opening?.commonLoss ?? 0,
            opening?.dayTradeLoss ?? 0,
            opening?.fundLoss ?? 0,
            opening?.smallDarf ?? 0,
          ]
        : (widget.month?.values ?? List<int>.filled(9, 0));
    _fields = values
        .map((v) => TextEditingController(text: taxMoneyInput(v)))
        .toList();
    _notes = TextEditingController(text: widget.month?.notes ?? '');
    _month =
        widget.month?.month ??
        (widget.controller.year == widget.controller.clock().year
            ? widget.controller.clock().month
            : 1);
  }

  @override
  void dispose() {
    for (final field in _fields) {
      field.dispose();
    }
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_confirmed || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final values = [
        for (var i = 0; i < _fields.length; i++)
          parseTaxMoney(
            _fields[i].text,
            signed: !widget.opening && i >= 1 && i <= 4,
          ),
      ];
      final year = widget.controller.year;
      if (!widget.opening &&
          DateTime(year, _month).isAfter(
            DateTime(
              widget.controller.clock().year,
              widget.controller.clock().month,
            ),
          )) {
        throw const FormatException(
          'Não registre apurações de meses futuros. Use o planejamento.',
        );
      }
      bool saved;
      if (widget.opening) {
        final opening = TaxOpening(
          year: year,
          commonLoss: values[0],
          dayTradeLoss: values[1],
          fundLoss: values[2],
          smallDarf: values[3],
        );
        opening.validate();
        saved = await widget.controller.saveOpening(opening);
      } else {
        final month = TaxMonth(
          year: year,
          month: _month,
          stockSales: values[0],
          stockResult: values[1],
          otherCommonResult: values[2],
          dayTradeResult: values[3],
          fundResult: values[4],
          commonWithheld: values[5],
          dayTradeWithheld: values[6],
          fundWithheld: values[7],
          paid: values[8],
          notes: _notes.text.trim(),
        );
        month.validate();
        saved = await widget.controller.saveMonth(month);
      }
      if (!mounted) return;
      if (saved) {
        Navigator.pop(context);
      } else {
        setState(() => _error = widget.controller.error);
      }
    } on FormatException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.opening
        ? [
            'Prejuízo comum de anos anteriores',
            'Prejuízo day trade de anos anteriores',
            'Prejuízo FII de anos anteriores',
            'DARF abaixo de R\$ 10 a transportar',
          ]
        : [
            'Vendas brutas de ações comuns elegíveis',
            'Resultado líquido dessas ações',
            'Resultado líquido comum de ETFs de renda variável e BDRs',
            'Resultado líquido day trade (exceto FIIs)',
            'Resultado líquido FII (comum e day trade)',
            'IRRF efetivo — operações comuns',
            'IRRF efetivo — day trade',
            'IRRF efetivo — FIIs',
            'Principal DARF deste mês informado como pago',
          ];
    return AlertDialog(
      title: Text(
        widget.opening
            ? 'Saldos em 1º de janeiro'
            : 'Registrar apuração mensal',
      ),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.opening
                      ? 'Informe os prejuízos fiscais comprovados e ainda não compensados. Confirme zero se não houver saldo. IRRF não é transportado automaticamente entre anos.'
                      : 'Consolide todas as corretoras do mesmo CPF. Use resultados já líquidos de custos dedutíveis, com prejuízo negativo. Exclua Tesouro, ETFs de renda fixa, derivativos e operações fora de bolsa. Não use o lucro de cotação da carteira.',
                ),
                if (!widget.opening) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _month,
                    decoration: const InputDecoration(labelText: 'Mês'),
                    items: [
                      for (var m = 1; m <= 12; m++)
                        DropdownMenuItem(
                          value: m,
                          child: Text('$m/${widget.controller.year}'),
                        ),
                    ],
                    onChanged: widget.month != null || _saving
                        ? null
                        : (value) {
                            if (value != null) setState(() => _month = value);
                          },
                  ),
                  if (widget.month == null)
                    const Text(
                      'Um registro existente no mesmo mês será substituído pelos valores informados.',
                    ),
                ],
                for (var i = 0; i < labels.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TaxMoneyField(
                      label: labels[i],
                      controller: _fields[i],
                      signed: !widget.opening && i >= 1 && i <= 4,
                    ),
                  ),
                if (!widget.opening)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextFormField(
                      controller: _notes,
                      maxLength: 2000,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notas / referências dos comprovantes',
                      ),
                    ),
                  ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _confirmed,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _confirmed = value ?? false),
                  title: const Text(
                    'Conferi os valores com as notas e informes, inclusive os saldos zero.',
                  ),
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving || !_confirmed ? null : _save,
          child: Text(_saving ? 'Salvando…' : 'Salvar'),
        ),
      ],
    );
  }
}
