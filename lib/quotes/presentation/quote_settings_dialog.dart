import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/quote_credentials.dart';

class QuoteSettingsDialog extends StatefulWidget {
  const QuoteSettingsDialog({required this.credentials, super.key});
  final QuoteCredentials credentials;
  @override
  State<QuoteSettingsDialog> createState() => _QuoteSettingsDialogState();
}

class _QuoteSettingsDialogState extends State<QuoteSettingsDialog> {
  final _token = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = true;
  bool _configured = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final configured = await widget.credentials.readAccessToken() != null;
      if (mounted) setState(() => _configured = configured);
    } on QuoteCredentialException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    await _change(() => widget.credentials.saveAccessToken(_token.text));
  }

  Future<void> _change(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) Navigator.pop(context);
    } on QuoteCredentialException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Configurar cotações'),
    content: SizedBox(
      width: 460,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Use sua chave de acesso da brapi. Ela será guardada no armazenamento seguro deste dispositivo, separada do banco e dos relatórios.',
              ),
              const SizedBox(height: 12),
              if (_busy) const LinearProgressIndicator(),
              Text(
                _configured
                    ? 'Uma chave já está configurada. Preencha abaixo somente para substituí-la.'
                    : 'Nenhuma chave configurada.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _token,
                enabled: !_busy,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'Chave de acesso brapi',
                ),
                validator: (value) {
                  try {
                    validateQuoteAccessToken(value ?? '');
                    return null;
                  } on QuoteCredentialException catch (error) {
                    return error.message;
                  }
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Depois de salvar, clique em Atualizar cotações. Ao trocar de computador, configure a chave novamente. Os limites e atrasos dependem do seu plano.',
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      if (_configured)
        TextButton(
          onPressed: _busy
              ? null
              : () => _change(widget.credentials.deleteAccessToken),
          child: const Text('Remover chave'),
        ),
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _busy ? null : _save,
        child: const Text('Salvar'),
      ),
    ],
  );
}
