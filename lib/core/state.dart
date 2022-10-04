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

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
final isAndroid = Platform.isAndroid;

// This must be initialized before use, in main.dart.
final prefProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

abstract class ApplicationStateNotifier<T>
    extends StateNotifier<AsyncValue<T>> {
  ApplicationStateNotifier() : super(const AsyncValue.loading());

  @protected
  Future<void> updateState(Future<T> Function() guarded) async {
    final result = await AsyncValue.guard(guarded);
    if (mounted) {
      state = result;
    }
  }

  @protected
  void setData(T value) {
    if (mounted) {
      state = AsyncValue.data(value);
    }
  }
}
