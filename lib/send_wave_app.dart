import 'dart:ffi';

import 'package:flutter/material.dart';

import 'ggwave_bindings.dart';

class SendWaveApp extends StatefulWidget {
  const SendWaveApp({super.key});

  @override
  State<SendWaveApp> createState() => _SendWaveAppState();
}

class _SendWaveAppState extends State<SendWaveApp> {
  late final GGwave _gGwave;
  int counter = 0;
  int inc = 1;
  late final int instance;
  int _encodedPayload = 0;
  int _decodedPayload = 0;
  final _payload = 'Hello World! tommy';
  // late final ffi.Pointer<GGwaveParamters> ggwaveParameters;
  late final ggwave_Parameters ggwaveParameters;
  Pointer<Void> waveForm = Pointer.fromAddress(1);

  @override
  void initState() {
    super.initState();

    _gGwave = GGwave(DynamicLibrary.open('libggwave.so'));
    ggwaveParameters = _gGwave.ggwave_getDefaultParameters();
    instance = _gGwave.ggwave_init(ggwaveParameters);

    print("instance: $instance");
  }

  @override
  void dispose() {
    _gGwave.ggwave_free(instance);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Pointer<Void> payloadBuffer = Pointer.fromAddress(_payload.hashCode);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Payload: $_payload',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                'encodedPayload: $_encodedPayload',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                'decodedPayload: $_decodedPayload',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        _decodedPayload = _gGwave.ggwave_decode(
                          instance,
                          waveForm,
                          waveForm.address,
                          payloadBuffer,
                        );
                        setState(() {});
                      },
                      child: const Text('Decode'),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        final encodedPayload = _gGwave.ggwave_encode(
                          instance,
                          payloadBuffer,
                          _payload.length,
                          ggwave_ProtocolId.GGWAVE_PROTOCOL_MT_FAST,
                          50,
                          waveForm,
                          1,
                        );
                        _encodedPayload = encodedPayload;
                        setState(() {});
                      },
                      child: const Text('Encode'),
                    ),
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
