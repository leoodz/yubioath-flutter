import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/shortcuts.dart';
import '../../app/state.dart';
import '../models.dart';
import '../state.dart';
import 'account_dialog.dart';
import 'account_mixin.dart';

class AccountView extends ConsumerWidget with AccountMixin {
  @override
  final OathCredential credential;
  AccountView(this.credential, {super.key});

  Color _iconColor(int shade) {
    final colors = [
      Colors.red[shade],
      Colors.pink[shade],
      Colors.purple[shade],
      Colors.deepPurple[shade],
      Colors.indigo[shade],
      Colors.blue[shade],
      Colors.lightBlue[shade],
      Colors.cyan[shade],
      Colors.teal[shade],
      Colors.green[shade],
      Colors.lightGreen[shade],
      Colors.lime[shade],
      Colors.yellow[shade],
      Colors.amber[shade],
      Colors.orange[shade],
      Colors.deepOrange[shade],
      Colors.brown[shade],
      Colors.grey[shade],
      Colors.blueGrey[shade],
    ];
    return colors[label.hashCode % colors.length]!;
  }

  List<PopupMenuItem> _buildPopupMenu(BuildContext context, WidgetRef ref) {
    return buildActions(context, ref).map((e) {
      final action = e.action;
      return PopupMenuItem(
        enabled: action != null,
        onTap: () {
          // As soon as onTap returns, the Navigator is popped,
          // closing the topmost item. Since we sometimes open new dialogs in
          // the action, make sure that happens *after* the pop.
          Timer(Duration.zero, () {
            action?.call(context);
          });
        },
        child: ListTile(
          leading: e.icon,
          title: Text(e.text),
          enabled: action != null,
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = getCode(ref);
    final expired = code == null ||
        (credential.oathType == OathType.totp &&
            ref.watch(expiredProvider(code.validTo)));
    final calculateReady = code == null ||
        credential.oathType == OathType.hotp ||
        (credential.touchRequired && expired);

    void triggerCopy() async {
      if (calculateReady) {
        await calculateCode(
          context,
          ref,
        );
      }
      await ref.read(withContextProvider)(
        (context) async {
          copyToClipboard(context, ref);
        },
      );
    }

    final darkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onSecondaryTapDown: (details) {
        showMenu(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx,
            0,
          ),
          items: _buildPopupMenu(context, ref),
        );
      },
      child: Actions(
        actions: {
          CopyIntent: CallbackAction(onInvoke: (_) {
            triggerCopy();
            return null;
          }),
        },
        child: LayoutBuilder(builder: (context, constraints) {
          final showAvatar = constraints.maxWidth >= 315;
          return ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            onTap: () {
              showBlurDialog(
                context: context,
                builder: (context) => AccountDialog(credential),
              );
            },
            onLongPress: triggerCopy,
            leading: showAvatar
                ? CircleAvatar(
                    foregroundColor: darkMode ? Colors.black : Colors.white,
                    backgroundColor: _iconColor(darkMode ? 300 : 400),
                    child: Text(
                      (credential.issuer ?? credential.name)
                          .characters
                          .first
                          .toUpperCase(),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w300),
                    ),
                  )
                : null,
            title: Text(
              title,
              overflow: TextOverflow.fade,
              maxLines: 1,
              softWrap: false,
            ),
            subtitle: subtitle != null
                ? Text(
                    subtitle!,
                    overflow: TextOverflow.fade,
                    maxLines: 1,
                    softWrap: false,
                  )
                : null,
            trailing: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                color: CardTheme.of(context).color,
                borderRadius: const BorderRadius.all(Radius.circular(30.0)),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
                child: DefaultTextStyle.merge(
                  style: Theme.of(context).textTheme.bodyLarge,
                  child: buildCodeView(ref),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
