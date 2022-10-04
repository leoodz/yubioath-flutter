/*
 * Copyright (C) 2022 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:yubico_authenticator/app/views/device_button.dart';
import 'package:yubico_authenticator/app/views/keys.dart' as app_keys;
import 'package:yubico_authenticator/app/views/keys.dart';
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/management/views/keys.dart';

import 'android/util.dart' as android_test_util;
import 'approved_yubikeys.dart';
import 'desktop/util.dart' as desktop_test_util;

const shortestWaitMs = 10;
const shortWaitMs = 50;
const longWaitMs = 200;
const veryLongWaitS = 10; // seconds

/// information about YubiKey as seen by the app
String? yubiKeyName;
String? yubiKeyFirmware;
String? yubiKeySerialNumber;
bool collectedYubiKeyInformation = false;

extension AppWidgetTester on WidgetTester {
  Future<void> shortestWait() async {
    await pump(const Duration(milliseconds: shortestWaitMs));
  }

  Future<void> shortWait() async {
    await pump(const Duration(milliseconds: shortWaitMs));
  }

  Future<void> longWait() async {
    await pump(const Duration(milliseconds: longWaitMs));
  }

  Future<void> veryLongWait() async {
    await pump(const Duration(seconds: veryLongWaitS));
  }

  /// waits up to [timeOutSec] seconds evaluating whether [Finder] f is
  /// visible
  Future<Finder> waitForFinder(Finder f, [int timeOutSec = 20]) async {
    int delayMs = 500;
    int elapsedTime = 0;

    var evaluated = f.evaluate();
    while (evaluated.isEmpty && elapsedTime < timeOutSec * 1000) {
      await pump(Duration(milliseconds: delayMs));
      elapsedTime += delayMs;
      evaluated = f.evaluate();
    }

    if (evaluated.isEmpty) {
      testLog(false, 'Failed to find ${f.description} in $timeOutSec seconds.');
    }

    return f;
  }

  Finder findDeviceButton() {
    return find.byType(DeviceButton).hitTestable();
  }

  /// Taps the device button
  Future<void> tapDeviceButton() async {
    await tap(findDeviceButton());
    await pump(const Duration(milliseconds: 500));
  }

  /// Drawer helpers
  bool hasDrawer() => scaffoldGlobalKey.currentState!.hasDrawer;

  /// Open drawer
  Future<void> openDrawer() async {
    if (hasDrawer()) {
      scaffoldGlobalKey.currentState!.openDrawer();
      await pump(const Duration(milliseconds: 500));
    }
  }

  /// Close drawer
  Future<void> closeDrawer() async {
    if (hasDrawer()) {
      scaffoldGlobalKey.currentState!.closeDrawer();
      await pump(const Duration(milliseconds: 500));
    }
  }

  /// Is drawer opened?
  /// If there is no drawer say it is open (all items are available)
  bool isDrawerOpened() =>
      hasDrawer() == false || scaffoldGlobalKey.currentState!.isDrawerOpen;

  /// Management screen
  Future<void> openManagementScreen() async {
    if (!isDrawerOpened()) {
      await openDrawer();
    }

    await tap(find.byKey(managementAppDrawer));
    await pump(const Duration(milliseconds: 500));

    expect(find.byKey(screenKey), findsOneWidget);
  }

  Future<void> startUp([Map<dynamic, dynamic> startUpParams = const {}]) async {
    var result = isAndroid == true
        ? await android_test_util.startUp(this, startUpParams)
        : await desktop_test_util.startUp(this, startUpParams);

    await collectYubiKeyInformation();

    if (!approvedYubiKeys.contains(yubiKeySerialNumber)) {
      testLog(false,
          'The connected key is refused by the tests: $yubiKeySerialNumber');
      expect(approvedYubiKeys.contains(yubiKeySerialNumber), equals(true));
    }

    return result;
  }

  void testLog(bool quiet, String message) {
    if (!quiet) {
      printToConsole(message);
    }
  }

  /// get key information
  Future<void> collectYubiKeyInformation() async {
    if (collectedYubiKeyInformation) {
      return;
    }

    await tapDeviceButton();

    var deviceInfo = find.byKey(app_keys.deviceInfoListTile);
    if (deviceInfo.evaluate().isNotEmpty) {
      ListTile lt = deviceInfo.evaluate().single.widget as ListTile;
      yubiKeyName = (lt.title as Text).data;
      var subtitle = (lt.subtitle as Text?)?.data;

      if (subtitle != null) {
        RegExpMatch? match = RegExp(r'S/N: (?<SN>\d.*) F/W: (?<FW>\d\.\d\.\d)')
            .firstMatch(subtitle);
        if (match != null) {
          yubiKeySerialNumber = match.namedGroup('SN');
          yubiKeyFirmware = match.namedGroup('FW');
        } else {
          match = RegExp(r'F/W: (?<FW>\d\.\d\.\d)').firstMatch(subtitle);
          if (match != null) {
            yubiKeyFirmware = match.namedGroup('FW');
          }
        }
      }
    }

    // close the opened menu
    await tapAt(const Offset(0, 0));
    await longWait();

    testLog(false,
        'Connected YubiKey: $yubiKeySerialNumber/$yubiKeyFirmware - $yubiKeyName');

    if (!approvedYubiKeys.contains(yubiKeySerialNumber)) {
      if (yubiKeySerialNumber == null) {
        expect(approvedYubiKeys.contains(yubiKeySerialNumber), equals(true),
            reason: 'No YubiKey connected');
      } else {
        expect(approvedYubiKeys.contains(yubiKeySerialNumber), equals(true),
            reason:
                'YubiKey with S/N $yubiKeySerialNumber is not approved for integration tests.');
      }
    }

    collectedYubiKeyInformation = true;
  }
}

@isTest
void appTest(
  String description,
  WidgetTesterCallback callback, {
  bool? skip,
  Map startUpParams = const {},
}) {
  testWidgets(description, (WidgetTester tester) async {
    await tester.startUp(startUpParams);
    await callback(tester);
  });
}
