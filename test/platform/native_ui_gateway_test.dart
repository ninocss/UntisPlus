import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/platform/native_ui_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('untisplus/ui-test');
  const gateway = NativeUiGateway(channel: channel);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('installApk keeps the native method and payload stable', () async {
    MethodCall? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          received = call;
          return 'opened';
        });

    expect(await gateway.installApk('C:/Downloads/untis.apk'), 'opened');
    expect(received?.method, 'installApk');
    expect(received?.arguments, {'path': 'C:/Downloads/untis.apk'});
  });

  test('assistant callback normalizes an empty native prompt', () async {
    String? received = 'not-called';
    gateway.registerAssistantOpenHandler((prompt) => received = prompt);

    final completer = Completer<ByteData?>();
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          channel.name,
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('openAssistant', '  '),
          ),
          completer.complete,
        );
    await completer.future;

    expect(received, isNull);
  });
}
