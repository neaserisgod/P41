import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../../../app/state/session_controller.dart';
import 'setup_admin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.accountName,
    required this.rememberedAccounts,
    required this.onLoadLocalUsers,
    required this.onLocalPinLogin,
    required this.onLogin,
    this.errorMessage,
  });

  final String accountName;
  final List<RememberedAccount> rememberedAccounts;
  final Future<List<LocalAccessUser>> Function(String email) onLoadLocalUsers;
  final Future<bool> Function({
    required String email,
    required String userId,
    required String pin,
  }) onLocalPinLogin;
  final Future<bool> Function({
    required String email,
    required String password,
  }) onLogin;
  final String? errorMessage;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _isSubmitting = false;
  String? _selectedEmail;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final error = _error ?? widget.errorMessage;

    return AccessScaffold(
      eyebrow: widget.accountName,
      title: 'Entrá y seguí vendiendo.',
      subtitle: 'Accedé al local, revisá stock y abrí caja sin vueltas.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Abrir cuenta',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: palette.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.rememberedAccounts.isEmpty
                ? 'Usá una cuenta nueva para este equipo.'
                : 'Entrá directo con una cuenta guardada o cargá otra.',
            style: TextStyle(
              fontSize: 13,
              color: palette.textMuted,
            ),
          ),
          if (widget.rememberedAccounts.isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.surfaceMuted.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: palette.border.withValues(alpha: 0.9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cuentas de este equipo',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: palette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth > 390 ? 2 : 1;
                      final cardWidth = columns == 1
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 12) / 2;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final account in widget.rememberedAccounts)
                            SizedBox(
                              width: cardWidth,
                              child: _RememberedAccountCard(
                                account: account,
                                selected: account.email == _selectedEmail,
                                onTap: () async {
                                  setState(() {
                                    _selectedEmail = account.email;
                                    _emailController.text = account.email;
                                    _error = null;
                                  });
                                  final users = await widget.onLoadLocalUsers(account.email);
                                  if (!mounted || !context.mounted || users.isEmpty) {
                                    return;
                                  }
                                  final success = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => _LocalPinAccessDialog(
                                      account: account,
                                      users: users,
                                      onSubmit: ({required userId, required pin}) {
                                        return widget.onLocalPinLogin(
                                          email: account.email,
                                          userId: userId,
                                          pin: pin,
                                        );
                                      },
                                    ),
                                  );
                                  if (!mounted) {
                                    return;
                                  }
                                  if (success == false && widget.errorMessage == null) {
                                    setState(() {
                                      _error = 'No se pudo ingresar con PIN.';
                                    });
                                  }
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          if (widget.rememberedAccounts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Expanded(child: Divider(color: palette.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'agregar o validar otra cuenta',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: palette.textMuted,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: palette.border)),
                ],
              ),
            ),
          AccessInputField(controller: _emailController, label: 'Email'),
          const SizedBox(height: 12),
          AccessInputField(
            controller: _passwordController,
            label: 'Clave',
            obscureText: true,
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                error,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: palette.danger,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      setState(() {
                        _isSubmitting = true;
                        _error = null;
                      });
                      var ok = false;
                      try {
                        ok = await widget.onLogin(
                          email: _emailController.text.trim(),
                          password: _passwordController.text.trim(),
                        );
                      } catch (_) {
                        ok = false;
                      }
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        _isSubmitting = false;
                        if (!ok && widget.errorMessage == null) {
                          _error = 'Credenciales invalidas';
                        }
                      });
                    },
              style: FilledButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _isSubmitting ? 'Ingresando...' : 'Ingresar',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RememberedAccountCard extends StatelessWidget {
  const _RememberedAccountCard({
    required this.account,
    required this.selected,
    required this.onTap,
  });

  final RememberedAccount account;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SizedBox(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? palette.accentSoft.withValues(alpha: 0.82) : const Color(0xFFF5F8F8),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? palette.accent : palette.border,
                width: selected ? 1.3 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selected ? palette.accent : palette.accentSoft,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    account.initials,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : palette.warning,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  account.accountName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: palette.textStrong,
                  ),
                ),
                const SizedBox(height: 3),
                Expanded(
                  child: Text(
                  account.email,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.2,
                    color: palette.textMuted,
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocalPinAccessDialog extends StatefulWidget {
  const _LocalPinAccessDialog({
    required this.account,
    required this.users,
    required this.onSubmit,
  });

  final RememberedAccount account;
  final List<LocalAccessUser> users;
  final Future<bool> Function({
    required String userId,
    required String pin,
  }) onSubmit;

  @override
  State<_LocalPinAccessDialog> createState() => _LocalPinAccessDialogState();
}

class _LocalPinAccessDialogState extends State<_LocalPinAccessDialog> {
  final TextEditingController _pinController = TextEditingController();
  String? _selectedUserId;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedUserId = widget.users.first.id;
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        width: 520,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.account.accountName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: palette.textStrong,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Elegí usuario y escribí el PIN.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: 18),
              ...widget.users.map(
                (user) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedUserId = user.id;
                        _error = null;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedUserId == user.id
                            ? palette.accentSoft.withValues(alpha: 0.82)
                            : const Color(0xFFF5F8F8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedUserId == user.id ? palette.accent : palette.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: palette.accentSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              user.initials,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: palette.warning,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: palette.textStrong,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.role,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              AccessInputField(
                controller: _pinController,
                label: 'PIN',
                obscureText: true,
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: palette.danger,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            final navigator = Navigator.of(context);
                            setState(() {
                              _isSubmitting = true;
                              _error = null;
                            });
                            final ok = await widget.onSubmit(
                              userId: _selectedUserId ?? '',
                              pin: _pinController.text.trim(),
                            );
                            if (!mounted) {
                              return;
                            }
                            if (ok) {
                              navigator.pop(true);
                              return;
                            }
                            setState(() {
                              _isSubmitting = false;
                              _error = 'PIN inválido.';
                            });
                          },
                    child: Text(_isSubmitting ? 'Ingresando...' : 'Entrar con PIN'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
