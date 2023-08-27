import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:sound_stream/sound_stream.dart';
import 'package:wave_send_flutter/core/core.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final GGwaveBridge _gGwave;
  int counter = 0;
  late final int instance;
  int ret = 0;
  final _payload = 'This is the.';
  final logs = <String>[];
  ffi.Pointer<ffi.Uint8> waveFormPointer = ffi.nullptr;
  late final Parameters parameters;
  late final Pointer<Utf8> payloadPointer;
  bool _isRecording = false;
  bool _isPlaying = false;
  final RecorderStream _recorder = RecorderStream();
  final PlayerStream _player = PlayerStream();
  final List<Uint8List> _micChunks = [];

  StreamSubscription? _recorderStatus;
  StreamSubscription? _playerStatus;
  StreamSubscription? _audioStream;

  @override
  void initState() {
    super.initState();

    _gGwave = GGwaveBridge(ffi.DynamicLibrary.open('libggwave.so'));
    parameters = _gGwave.getDefaultParameters();
    parameters.sampleFormatInp = SampleFormat.sampleFormatI16.value;
    parameters.sampleFormatOut = SampleFormat.sampleFormatI16.value;
    instance = _gGwave.ggwaveInit(parameters);
    payloadPointer = _payload.toNativeUtf8();
    initPlugin();
  }

  Future<void> initAudio(Uint8List bytes) async {
    _player.writeChunk(bytes);
    // await _player.initialize(sampleRate: 48000);
    await _player.start();
  }

  Future<void> initPlugin() async {
    _recorderStatus = _recorder.status.listen((status) {
      if (mounted) {
        setState(() {
          _isRecording = status == SoundStreamStatus.Playing;
        });
      }
    });

    _audioStream = _recorder.audioStream.listen((data) {
      if (_micChunks.length <= 256) {
        _micChunks.add(data);
      }
      setState(() {});
    });

    _playerStatus = _player.status.listen((status) {
      if (mounted) {
        setState(() {
          _isPlaying = status == SoundStreamStatus.Playing;
        });
        print("listening");
        print(status == SoundStreamStatus.Playing);
      }
    });

    await Future.wait([
      _recorder.initialize(sampleRate: 48000),
      _player.initialize(sampleRate: 48000),
    ]);
  }

  @override
  void dispose() {
    _gGwave.ggwaveFree(instance);
    calloc.free(waveFormPointer);
    calloc.free(payloadPointer);
    _gGwave.ggwaveFree(instance);
    _recorderStatus?.cancel();
    _playerStatus?.cancel();
    _audioStream?.cancel();
    super.dispose();
  }

  void processData(Pointer<Uint8> dataBuffer, int dataSize) {
    Pointer<ffi.Uint8> decoded = calloc<ffi.Uint8>(256);
    final response = _gGwave.ggwaveDecode(
      instance: instance,
      dataBuffer: dataBuffer.cast(),
      dataSize: 2 * dataSize,
      outputBuffer: decoded.cast(),
    );

    if (response != 0) {
      print(response);
      try {
        final output = decoded.cast<Uint8>().asTypedList(response);
        print(output);

        final result = output
            .map((codePoint) => String.fromCharCode(codePoint))
            .toList()
            .join("");
        print(result);
        logs.add('Data Decoded...$result');
        setState(() {});
      } catch (e) {
        print(e);
      }
    } else {
      print('Unable to decode data....');
    }
    calloc.free(dataBuffer);
    calloc.free(decoded);
  }

  void decodeData() {
    Pointer<ffi.Uint8> decoded = calloc<ffi.Uint8>(256);
    ret = _gGwave.ggwaveDecode(
      instance: instance,
      dataBuffer: waveFormPointer.cast(),
      dataSize: 2 * ret,
      outputBuffer: decoded.cast(),
    );

    final output = decoded.cast<Uint8>().asTypedList(ret);

    final result = output
        .map((codePoint) => String.fromCharCode(codePoint))
        .toList()
        .join("");
    logs.add('Data Decoded...$result');

    setState(() {});
    calloc.free(decoded);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Payload: $_payload',
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => processData(waveFormPointer, ret),
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
                        setState(() {});
                        final encodedPayload = _gGwave.ggwaveEncode(
                          instance: instance,
                          dataBuffer: payloadPointer.cast<Utf8>(),
                          dataSize: payloadPointer.length,
                          txProtocolId:
                              TxProtocolId.txProtocolAudibleFast.value,
                          volume: 25,
                          outputBuffer: waveFormPointer.cast(),
                          query: 1,
                        );
                        logs.add('Wave form encoing data...$encodedPayload');
                        waveFormPointer = calloc<ffi.Uint8>(encodedPayload);

                        ret = _gGwave.ggwaveEncode(
                          instance: instance,
                          dataBuffer: payloadPointer.cast<Utf8>(),
                          dataSize: _payload.length,
                          txProtocolId:
                              TxProtocolId.txProtocolAudibleFast.value,
                          volume: 25,
                          outputBuffer: waveFormPointer.cast(),
                          query: 0,
                        );
                        logs.add('Data Size...$ret');
                        logs.add('Data Encoded...${2 * ret}');
                        final output =
                            waveFormPointer.cast<Uint8>().asTypedList(2 * ret);
                        await initAudio(output);
                        setState(() {});
                      },
                      child: const Text('Encode'),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  IconButton(
                    iconSize: 40.0,
                    icon: Icon(_isRecording ? Icons.mic_off : Icons.mic),
                    onPressed: _isRecording ? _recorder.stop : _recorder.start,
                  ),
                  IconButton(
                    iconSize: 40.0,
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: _isPlaying
                        ? _player.stop
                        : () async {
                            _player.start();
                            if (_micChunks.isNotEmpty) {
                              for (var chunk in _micChunks) {
                                await _player.writeChunk(chunk);
                              }
                              // _micChunks.clear();
                            }
                          },
                  ),
                  IconButton(
                    iconSize: 40.0,
                    icon: const Icon(Icons.refresh),
                    onPressed: !_isRecording && _micChunks.isNotEmpty
                        ? () {
                            processData(
                                _micChunks.toPointer(), _micChunks.totalSize);
                          }
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final newLogs = logs.reversed.toList();
                    return Text(
                      newLogs[index],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.primaries[
                              Random().nextInt(Colors.primaries.length)]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
