import 'dart:ffi' as ffi;
import 'dart:ffi';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wave_send_flutter/core/ggwave_bridge.dart';

import 'ggwave_bindings.dart';

class SendWaveLocal extends StatefulWidget {
  const SendWaveLocal({super.key});

  @override
  State<SendWaveLocal> createState() => _SendWaveLocalState();
}

class _SendWaveLocalState extends State<SendWaveLocal> {
  late final GGwaveBridge _gGwave;
  int counter = 0;
  int inc = 1;
  late final int instance;
  final int _encodedPayload = 0;
  final int _decodedPayload = 0;
  int ret = 0;
  final _payload = 'test';
  final logs = <String>[];
  // late final ffi.Pointer<GGwaveParamters> ggwaveParameters;
  late final ggwave_Parameters ggwaveParameters;
  ffi.Pointer<ffi.Void> waveForm = ffi.Pointer.fromAddress(0);
  PlayerController controller = PlayerController();
  List<double> waveformData = [];

  @override
  void initState() {
    super.initState();

    _gGwave = GGwaveBridge(ffi.DynamicLibrary.open('libggwave.so'));
    ggwaveParameters = _gGwave.getDefaultParameters();
    ggwaveParameters.sampleFormatInp =
        ggwave_SampleFormat.GGWAVE_SAMPLE_FORMAT_I16;
    ggwaveParameters.sampleFormatOut =
        ggwave_SampleFormat.GGWAVE_SAMPLE_FORMAT_I16;
    instance = _gGwave.ggwaveInit(ggwaveParameters);

    print("instance: $instance");
    initAudio();
  }

  Future<void> initAudio() async {
    final appDirectory = await getApplicationDocumentsDirectory();

    final file = File('${appDirectory.path}/plucky.mp3');
    await file.writeAsBytes(
        (await rootBundle.load('assets/plucky.mp3')).buffer.asUint8List());

    waveformData = await controller.extractWaveformData(
      path: file.path,
      noOfSamples: 100,
    );
    await controller.preparePlayer(
      path: file.path,
      shouldExtractWaveform: true,
      noOfSamples: 100,
      volume: 1.0,
    );
  }

  @override
  void dispose() {
    _gGwave.ggwaveFree(instance);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ffi.Pointer<ffi.Void> payloadBuffer =
        ffi.Pointer.fromAddress(_payload.hashCode);
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
                      onPressed: () {},
                      child: const Text('Decode'),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        logs.add('Encoding data...');
                        await controller.startPlayer(
                            finishMode: FinishMode.stop);
                        setState(() {});
                        final payloadPointer = calloc<ffi.Char>(
                            waveformData.length + 1); // +1 if null-terminated.
                        for (int index = 0; index < _payload.length; index++) {
                          payloadPointer[index] = _payload[index].codeUnitAt(0);
                        }
                        final encodedPayload = _gGwave.ggwaveEncode(
                          instance: instance,
                          payloadBuffer: _payload.toNativeUtf8(),
                          payloadSize: _payload.length,
                          protocolId: ggwave_ProtocolId.GGWAVE_PROTOCOL_MT_FAST,
                          volume: 50,
                          waveformBuffer: ffi.Pointer<ffi.Void>.fromAddress(
                              waveformData.hashCode),
                          query: 1,
                        );
                        // print(payloadBuffer.toDartString());
                        logs.add('Wave form encoing data...$encodedPayload');

                        ret = _gGwave.ggwaveEncode(
                          instance: instance,
                          payloadBuffer: Pointer.fromAddress(0),
                          payloadSize: _payload.length,
                          protocolId: ggwave_ProtocolId.GGWAVE_PROTOCOL_MT_FAST,
                          volume: 10,
                          waveformBuffer: ffi.Pointer<ffi.Void>.fromAddress(
                              waveformData.hashCode),
                          query: 0,
                        );
                        logs.add('Data Encoded...$ret');
                        setState(() {});
                        calloc.free(payloadPointer);
                        _gGwave.ggwaveFree(instance);
                      },
                      child: const Text('Encode'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...logs
                  .map((e) => Text(
                        e,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.red),
                      ))
                  .toList(),
            ],
          ),
        ),
      ),
    );
  }
}
