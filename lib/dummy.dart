import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:ggwave_flutter/core/core.dart';
import 'package:sound_stream/sound_stream.dart';

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
  final logs = <String>[];
  ffi.Pointer<ffi.Uint8> waveFormPointer = ffi.nullptr;
  late final Parameters parameters;

  bool _isRecording = false;
  bool _isPlaying = false;
  final RecorderStream _recorder = RecorderStream();
  final PlayerStream _player = PlayerStream();
  final List<Uint8List> _micChunks = [];
  late final TextEditingController _textEditingController;

  StreamSubscription? _recorderStatus;
  StreamSubscription? _playerStatus;
  StreamSubscription? _audioStream;

  @override
  void initState() {
    super.initState();

    _gGwave = GGwaveBridge(
      Platform.isAndroid
          ? ffi.DynamicLibrary.open('libggwave.so')
          : ffi.DynamicLibrary.process(),
    );
    // ffi.DynamicLibrary.open('libggwave.dylib');
    parameters = _gGwave.getDefaultParameters();
    parameters.sampleFormatInp = SampleFormat.sampleFormatI16.value;
    parameters.sampleFormatOut = SampleFormat.sampleFormatI16.value;
    instance = _gGwave.ggwaveInit(parameters);

    _textEditingController = TextEditingController();
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

    // _textEditingController.addListener(() {
    //   setState(() {});
    //   print("dd");
    // });
  }

  @override
  void dispose() {
    _gGwave.ggwaveFree(instance);
    calloc.free(waveFormPointer);

    _gGwave.ggwaveFree(instance);
    _recorderStatus?.cancel();
    _playerStatus?.cancel();
    _audioStream?.cancel();
    _textEditingController.dispose();
    super.dispose();
  }

  void decodeData(Pointer<Uint8> dataBuffer, int dataSize) {
    Pointer<ffi.Uint8> decoded = calloc<ffi.Uint8>(256);
    final response = _gGwave.ggwaveDecode(
      instance: instance,
      dataBuffer: dataBuffer.cast(),
      dataSize: 2 * dataSize,
      outputBuffer: decoded.cast(),
    );

    if (response != 0) {
      try {
        final output = decoded.cast<Uint8>().asTypedList(response);

        final result = output
            .map((codePoint) => String.fromCharCode(codePoint))
            .toList()
            .join("");
        logs.add('Data Decoded...$result');
        setState(() {});
      } catch (e) {
        print(e);
      }
    } else {
      print('Unable to decode data....');
    }
    _micChunks.clear();
    calloc.free(dataBuffer);
    calloc.free(decoded);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter your message'),
              const SizedBox(height: 5),
              TextField(
                controller: _textEditingController,
                minLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Enter payload',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final payloadPointer =
                            _textEditingController.text.toNativeUtf8();
                        logs.add('Encoding data...');
                        setState(() {});
                        final encodedPayload = _gGwave.ggwaveEncode(
                          instance: instance,
                          dataBuffer: payloadPointer.cast<Utf8>(),
                          dataSize: payloadPointer.length,
                          txProtocolId:
                              TxProtocolId.txProtocolAudibleFast.value,
                          volume: 100,
                          outputBuffer: waveFormPointer.cast(),
                          query: 1,
                        );
                        logs.add('Wave form encoing data...$encodedPayload');
                        waveFormPointer = calloc<ffi.Uint8>(encodedPayload);

                        ret = _gGwave.ggwaveEncode(
                          instance: instance,
                          dataBuffer: payloadPointer.cast<Utf8>(),
                          dataSize: payloadPointer.length,
                          txProtocolId:
                              TxProtocolId.txProtocolAudibleFast.value,
                          volume: 100,
                          outputBuffer: waveFormPointer.cast(),
                          query: 0,
                        );
                        logs.add('Data Size...$ret');
                        logs.add('Data Encoded...${2 * ret}');
                        final output =
                            waveFormPointer.cast<Uint8>().asTypedList(2 * ret);
                        await initAudio(output);
                        setState(() {});
                        calloc.free(payloadPointer);
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Send Message'),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _isRecording ? _recorder.stop : _recorder.start,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                      ),
                      child: Text(
                          _isRecording ? 'Stop Listening' : 'Start Listening'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: IconButton(
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
                  ),
                  Expanded(
                    child: IconButton(
                      iconSize: 40.0,
                      icon: const Icon(Icons.refresh),
                      onPressed: !_isRecording && _micChunks.isNotEmpty
                          ? () {
                              decodeData(
                                  _micChunks.toPointer(), _micChunks.totalSize);
                              // processData(waveFormPointer, ret);
                            }
                          : null,
                    ),
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
