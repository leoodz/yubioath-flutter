import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/shortcuts.dart';
import '../../app/views/app_failure_page.dart';
import '../../app/views/app_loading_screen.dart';
import '../../app/views/app_page.dart';
import '../../app/views/graphics.dart';
import '../../app/views/message_page.dart';
import '../../theme.dart';
import '../models.dart';
import '../state.dart';
import 'account_list.dart';
import 'add_account_page.dart';
import 'manage_password_dialog.dart';
import 'reset_dialog.dart';

class OathScreen extends ConsumerWidget {
  final DevicePath devicePath;
  const OathScreen(this.devicePath, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(oathStateProvider(devicePath)).when(
          loading: () => AppPage(
            title: const Text('Authenticator'),
            centered: true,
            child: const AppLoadingScreen(),
          ),
          error: (error, _) => AppFailurePage(
            title: const Text('Authenticator'),
            cause: error,
          ),
          data: (oathState) => oathState.locked
              ? _LockedView(devicePath, oathState)
              : _UnlockedView(devicePath, oathState),
        );
  }
}

class _LockedView extends ConsumerWidget {
  final DevicePath devicePath;
  final OathState oathState;

  const _LockedView(this.devicePath, this.oathState);

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppPage(
        title: const Text('Authenticator'),
        actions: [
          OutlinedButton.icon(
            label: const Text('Options'),
            icon: const Icon(Icons.tune),
            onPressed: () {
              showBottomMenu(context, [
                MenuAction(
                  text: 'Manage password',
                  icon: const Icon(Icons.password),
                  action: (context) {
                    showBlurDialog(
                      context: context,
                      builder: (context) =>
                          ManagePasswordDialog(devicePath, oathState),
                    );
                  },
                ),
                MenuAction(
                  text: 'Reset OATH',
                  icon: const Icon(Icons.delete),
                  action: (context) {
                    showBlurDialog(
                      context: context,
                      builder: (context) => ResetDialog(devicePath),
                    );
                  },
                ),
              ]);
            },
          ),
        ],
        child: Column(
          children: [
            _UnlockForm(
              devicePath,
              keystore: oathState.keystore,
            ),
          ],
        ),
      );
}

class _UnlockedView extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final OathState oathState;

  const _UnlockedView(this.devicePath, this.oathState);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _UnlockedViewState();
}

class _UnlockedViewState extends ConsumerState<_UnlockedView> {
  late FocusNode searchFocus;
  late TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchFocus = FocusNode();
    searchController = TextEditingController(text: ref.read(searchProvider));
  }

  @override
  void dispose() {
    searchFocus.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = ref.watch(credentialListProvider(widget.devicePath)
        .select((value) => value?.isEmpty == true));
    if (isEmpty) {
      return MessagePage(
        title: const Text('Authenticator'),
        graphic: noAccounts,
        header: 'No accounts',
        actions: _buildActions(context, true),
      );
    }
    return Actions(
      actions: {
        SearchIntent: CallbackAction(onInvoke: (_) {
          searchController.selection = TextSelection(
              baseOffset: 0, extentOffset: searchController.text.length);
          searchFocus.requestFocus();
          return null;
        }),
      },
      child: AppPage(
        title: Focus(
          canRequestFocus: false,
          onKeyEvent: (node, event) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              node.focusInDirection(TraversalDirection.down);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Builder(builder: (context) {
            return TextFormField(
              key: const Key('search_accounts'),
              controller: searchController,
              focusNode: searchFocus,
              style: Theme.of(context).textTheme.titleSmall,
              decoration: const InputDecoration(
                hintText: 'Search accounts',
                isDense: true,
                prefixIcon: Icon(Icons.search_outlined),
                prefixIconConstraints: BoxConstraints(
                  minHeight: 30,
                  minWidth: 30,
                ),
                border: InputBorder.none,
              ),
              onChanged: (value) {
                ref.read(searchProvider.notifier).setFilter(value);
              },
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (value) {
                Focus.of(context).focusInDirection(TraversalDirection.down);
              },
            );
          }),
        ),
        actions: _buildActions(context, false),
        child: AccountList(widget.devicePath, widget.oathState),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context, bool isEmpty) {
    return [
      OutlinedButton.icon(
        style: isEmpty ? AppTheme.primaryOutlinedButtonStyle(context) : null,
        label: const Text('Add account'),
        icon: const Icon(Icons.person_add_alt_1),
        onPressed: () {
          showBlurDialog(
            context: context,
            builder: (context) => OathAddAccountPage(
              widget.devicePath,
              widget.oathState,
              openQrScanner: Platform.isAndroid,
            ),
          );
        },
      ),
      OutlinedButton.icon(
        label: const Text('Options'),
        icon: const Icon(Icons.tune),
        onPressed: () {
          showBottomMenu(context, [
            MenuAction(
              text:
                  widget.oathState.hasKey ? 'Manage password' : 'Set password',
              icon: const Icon(Icons.password),
              action: (context) {
                showBlurDialog(
                  context: context,
                  builder: (context) =>
                      ManagePasswordDialog(widget.devicePath, widget.oathState),
                );
              },
            ),
            MenuAction(
              text: 'Reset OATH',
              icon: const Icon(Icons.delete),
              action: (context) {
                showBlurDialog(
                  context: context,
                  builder: (context) => ResetDialog(widget.devicePath),
                );
              },
            ),
          ]);
        },
      ),
    ];
  }
}

class _UnlockForm extends ConsumerStatefulWidget {
  final DevicePath _devicePath;
  final KeystoreState keystore;
  const _UnlockForm(this._devicePath, {required this.keystore});

  @override
  ConsumerState<_UnlockForm> createState() => _UnlockFormState();
}

class _UnlockFormState extends ConsumerState<_UnlockForm> {
  final _passwordController = TextEditingController();
  bool _remember = false;
  bool _passwordIsWrong = false;
  bool _isObscure = true;

  void _submit() async {
    setState(() {
      _passwordIsWrong = false;
    });
    final result = await ref
        .read(oathStateProvider(widget._devicePath).notifier)
        .unlock(_passwordController.text, remember: _remember);
    if (!mounted) return;
    if (!result.first) {
      setState(() {
        _passwordIsWrong = true;
        _passwordController.clear();
      });
    } else if (_remember && !result.second) {
      showMessage(context, 'Failed to remember password');
    }
  }

  @override
  Widget build(BuildContext context) {
    final keystoreFailed = widget.keystore == KeystoreState.failed;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 18.0, right: 18, top: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the OATH password for your YubiKey',
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                autofocus: true,
                obscureText: _isObscure,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Password',
                  errorText: _passwordIsWrong ? 'Wrong password' : null,
                  helperText: '', // Prevents resizing when errorText shown
                  prefixIcon: const Icon(Icons.password_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                  ),
                ),
                onChanged: (_) => setState(() {
                  _passwordIsWrong = false;
                }), // Update state on change
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8.0),
        keystoreFailed
            ? const ListTile(
                leading: Icon(Icons.warning_amber_rounded),
                title: Text('OS Keystore unavailable'),
                dense: true,
                minLeadingWidth: 0,
              )
            : CheckboxListTile(
                title: const Text('Remember password'),
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                value: _remember,
                onChanged: (value) {
                  setState(() {
                    _remember = value ?? false;
                  });
                },
              ),
        Padding(
          padding: const EdgeInsets.only(top: 12.0, right: 18.0, bottom: 4.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _passwordController.text.isNotEmpty ? _submit : null,
              child: const Text('Unlock'),
            ),
          ),
        ),
      ],
    );
  }
}
