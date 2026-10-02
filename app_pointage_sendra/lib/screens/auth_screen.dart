import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../pointage_controller.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.controller});
  final PointageController controller;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _code = TextEditingController();
  bool _registering = false;
  bool _recovering = false;
  bool _codeSent = false;
  bool _verified = false;
  bool _showPassword = false;
  String? _localNotice;
  final _phoneFormatter = _SenegalPhoneFormatter();

  @override
  void dispose() {
    for (final controller in [_firstName, _lastName, _phone, _password, _confirm, _code]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Champ requis' : null;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_registering || _recovering) {
      if (!_verified) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vérifiez d’abord le code SMS.')));
        return;
      }
      if (_recovering) {
        await widget.controller.resetPassword(_digits, _password.text);
      } else {
        await widget.controller.register(firstName: _firstName.text, lastName: _lastName.text,
          phone: _digits, password: _password.text);
      }
    } else {
      await widget.controller.login(_digits, _password.text);
    }
  }

  String get _digits => _phone.text.replaceAll(RegExp(r'\D'), '');

  @override
  Widget build(BuildContext context) {
    final state = widget.controller;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SizedBox(height: 24),
                Image.asset('assets/sendra_pointage_logo.png', height: 120, fit: BoxFit.contain,
                  semanticLabel: 'Sendra Pointage'),
                const SizedBox(height: 24),
                SegmentedButton<bool>(
                  segments: const [ButtonSegment(value: false, label: Text('Se connecter')),
                    ButtonSegment(value: true, label: Text('S’inscrire'))],
                  selected: {_registering},
                  onSelectionChanged: state.busy ? null : (choice) => setState(() {
                    _registering = choice.first;
                    _recovering = false;
                    _codeSent = false;
                    _verified = false;
                    _localNotice = null;
                  }),
                ),
                const SizedBox(height: 22),
                Card(
                  elevation: 0,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _form,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Text(_recovering ? 'Retrouver votre compte' : (_registering ? 'Créer votre compte' : 'Bienvenue'),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_recovering
                            ? 'Vérifiez votre numéro par SMS, puis choisissez un nouveau mot de passe.'
                            : _registering
                            ? 'Vérifiez votre numéro par SMS, créez le compte, puis liez ce téléphone avec son empreinte ou Face ID avant la validation par votre responsable.'
                            : 'Connectez-vous avec le numéro utilisé pour votre compte Sendra.'),
                        const SizedBox(height: 24),
                        if (_registering) ...[
                          TextFormField(controller: _firstName, decoration: const InputDecoration(labelText: 'Prénom'), validator: _required,
                            textCapitalization: TextCapitalization.words),
                          const SizedBox(height: 14),
                          TextFormField(controller: _lastName, decoration: const InputDecoration(labelText: 'Nom'), validator: _required,
                            textCapitalization: TextCapitalization.words),
                          const SizedBox(height: 14),
                        ],
                        TextFormField(
                          controller: _phone, keyboardType: TextInputType.phone,
                          inputFormatters: [_phoneFormatter],
                          decoration: const InputDecoration(labelText: 'Téléphone', hintText: '77 123 45 67', prefixText: '+221 '),
                          validator: (_) => _digits.length == 9 ? null : 'Saisissez 9 chiffres.',
                          onChanged: (_) => setState(() { _verified = false; _codeSent = false; }),
                        ),
                        if (_registering || _recovering) ...[
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: state.busy || _digits.length != 9 ? null : () async {
                              if (_registering) {
                                final exists = await state.phoneExists(_digits);
                                if (!mounted || exists == null) return;
                                if (exists) {
                                  setState(() {
                                    _registering = false;
                                    _recovering = false;
                                    _codeSent = false;
                                    _verified = false;
                                    _localNotice = 'Ce numéro possède déjà un compte Sendra. Connectez-vous, puis demandez l’accès Pointage. Si vous avez oublié le mot de passe, utilisez « Mot de passe oublié ».';
                                  });
                                  return;
                                }
                              }
                              await state.sendCode(_digits);
                              if (mounted && state.error == null) setState(() => _codeSent = true);
                            },
                            icon: const Icon(Icons.sms_outlined),
                            label: Text(_codeSent ? 'Renvoyer le code' : 'Recevoir un code SMS'),
                          ),
                          if (_codeSent) ...[
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(child: TextFormField(controller: _code,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                                decoration: const InputDecoration(labelText: 'Code à 6 chiffres'),
                                onChanged: (_) => setState(() => _verified = false),
                              )),
                              const SizedBox(width: 10),
                              FilledButton(onPressed: state.busy || _code.text.length != 6 ? null : () async {
                                await state.verifyCode(_digits, _code.text);
                                if (mounted && state.error == null) setState(() => _verified = true);
                              }, child: Text(_verified ? 'Vérifié' : 'Vérifier')),
                            ]),
                          ],
                        ],
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password, obscureText: !_showPassword,
                          decoration: InputDecoration(labelText: 'Mot de passe', suffixIcon: IconButton(
                            tooltip: _showPassword ? 'Masquer' : 'Afficher',
                            icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          )),
                          validator: (value) => (value?.length ?? 0) >= ((_registering || _recovering) ? 8 : 1)
                              ? null : ((_registering || _recovering) ? 'Au moins 8 caractères.' : 'Champ requis'),
                        ),
                        if (_registering || _recovering) ...[
                          const SizedBox(height: 14),
                          TextFormField(controller: _confirm, obscureText: true,
                            decoration: const InputDecoration(labelText: 'Confirmer le mot de passe'),
                            validator: (value) => value == _password.text ? null : 'Les mots de passe diffèrent.'),
                        ],
                        const SizedBox(height: 22),
                        if (state.error != null) ...[
                          _Message(text: state.error!, isError: true), const SizedBox(height: 14),
                        ],
                        if (state.notice != null) ...[
                          _Message(text: state.notice!, isError: false), const SizedBox(height: 14),
                        ],
                        if (_localNotice != null) ...[
                          _Message(text: _localNotice!, isError: false), const SizedBox(height: 14),
                        ],
                        if (_registering && !_recovering) ...[
                          const Text('Après la création du compte, liez ce téléphone avec votre empreinte ou Face ID. Votre responsable vérifiera ensuite votre identité avant d’activer le pointage.',
                            style: TextStyle(color: Color(0xFF385A49))),
                        ],
                        FilledButton(
                          onPressed: state.busy ? null : _submit,
                          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                          child: state.busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(_recovering ? 'Enregistrer le mot de passe' : (_registering ? 'Créer le compte' : 'Se connecter')),
                        ),
                        if (!_registering) TextButton(
                          onPressed: state.busy ? null : () => setState(() {
                            _recovering = !_recovering;
                            _codeSent = false;
                            _verified = false;
                            _localNotice = null;
                          }),
                          child: Text(_recovering ? 'Revenir à la connexion' : 'Mot de passe oublié ?'),
                        ),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('La position est demandée uniquement lorsque vous pointez.',
                  textAlign: TextAlign.center),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.isError});
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: isError ? const Color(0xFFFFECE9) : const Color(0xFFE6F5EE),
      borderRadius: BorderRadius.circular(12)),
    child: Text(text, style: TextStyle(color: isError ? const Color(0xFF9F3124) : const Color(0xFF075B3E))),
  );
}

class _SenegalPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 9 ? digits.substring(0, 9) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (i == 2 || i == 5 || i == 7) buffer.write(' ');
      buffer.write(limited[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length));
  }
}
