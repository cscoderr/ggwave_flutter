import 'dart:async';
import 'dart:ffi' as ffi;
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
  int ret = 0;
  ffi.Pointer<ffi.Uint8> outputBufferPointer = ffi.nullptr;
  ffi.Pointer<ffi.Uint8> payloadPointer = ffi.nullptr;

  bool _isRecording = false;
  bool _isPlaying = false;
  TxProtocolId txProtocolId = TxProtocolId.txProtocolAudibleFastest;
  final RecorderStream _recorder = RecorderStream();
  final PlayerStream _player = PlayerStream();
  final List<Uint8List> _micChunks = [];
  late final TextEditingController _inputDataController;
  late final TextEditingController _outputDataController;

  StreamSubscription? _recorderStatus;
  StreamSubscription? _playerStatus;
  StreamSubscription? _audioStream;

  @override
  void initState() {
    super.initState();

    _inputDataController = TextEditingController();
    _outputDataController = TextEditingController();
    initPlugin();

    _inputDataController.addListener(() {
      setState(() {});
      print("dd");
    });
  }

  Future<void> initAudio(Uint8List bytes) async {
    _player.writeChunk(bytes);
    print("byteee ${bytes.length}");
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
        if (mounted) {
          setState(() {});
        }
        print("not zero ${_micChunks.totalSize}");
        if (_micChunks.totalSize > 12) {
          final response = GGwaveService.instance
              .decodeData(_micChunks.toPointer(), _micChunks.totalSize);
          if (response != null) {
            _outputDataController.text = response;
            if (mounted) {
              setState(() {});
            }
          }
        }
      }
    });

    _playerStatus = _player.status.listen((status) {
      if (mounted) {
        setState(() {
          _isPlaying = status == SoundStreamStatus.Playing;
        });
      }
    });

    await Future.wait([
      _recorder.initialize(sampleRate: 48000),
      _player.initialize(sampleRate: 48000),
    ]);
  }

  @override
  void dispose() {
    calloc.free(outputBufferPointer);
    calloc.free(payloadPointer);
    GGwaveService.instance.freeGGwave();
    _recorderStatus?.cancel();
    _playerStatus?.cancel();
    _audioStream?.cancel();
    _inputDataController.dispose();
    _outputDataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GGwave Flutter'),
        backgroundColor: Theme.of(context).primaryColor,
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tx Protocol'),
              const SizedBox(height: 5),
              DropdownButton(
                value: txProtocolId.value,
                items: TxProtocolId.values
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.value,
                        child: Text(e.text),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    txProtocolId = TxProtocolId.values
                        .firstWhere((element) => element.value == value);
                  });
                },
                style: Theme.of(context).textTheme.titleMedium,
                isExpanded: true,
              ),
              const SizedBox(height: 20),
              const Text('Enter your message'),
              const SizedBox(height: 5),
              TextField(
                controller: _inputDataController,
                maxLines: 5,
                enabled: !_isRecording,
                decoration: const InputDecoration(
                  hintText: 'Enter payload',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _inputDataController.text.isNotEmpty && !_isRecording
                    ? () async {
                        final payloadPointer =
                            _inputDataController.text.toNativeUtf8();
                        final (outputBuffer, rett) = GGwaveService.instance
                            .encodeData(payloadPointer, txProtocolId.value);
                        final output = outputBuffer
                            .cast<ffi.Uint8>()
                            .asTypedList(2 * rett);

                        setState(() {
                          ret = rett;
                          outputBufferPointer = outputBuffer;
                        });
                        await initAudio(output);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                  fixedSize: Size(MediaQuery.sizeOf(context).width, 50),
                ),
                child: const Text('Send Message'),
              ),
              const SizedBox(height: 20),
              const Text('Received message'),
              const SizedBox(height: 5),
              TextField(
                controller: _outputDataController,
                maxLines: 5,
                enabled: false,
                style: Theme.of(context).textTheme.titleMedium,
                decoration: const InputDecoration(
                  hintText: 'Listening...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isRecording
                    ? _recorder.stop
                    : () {
                        _micChunks.clear();
                        _outputDataController.clear();
                        _recorder.start();
                      },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: _isRecording ? Colors.red : Colors.blue,
                  fixedSize: Size(MediaQuery.sizeOf(context).width, 50),
                ),
                child:
                    Text(_isRecording ? 'Stop Listening' : 'Start Listening'),
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
                      onPressed: () async {
                        if (_isPlaying) {
                          await _player.stop();
                        }
                        // decodeData(
                        //     _micChunks.toPointer(), _micChunks.totalSize);
                        // processData(waveFormPointer, ret);
                        // final response = GGwaveService.instance.decodeData(
                        //   waveFormPointer,
                        //   ret,
                        // );
                        final response = GGwaveService.instance.decodeData(
                            _micChunks.toPointer(), _micChunks.totalSize);
                        if (response != null) {
                          _outputDataController.text = response;
                          setState(() {});
                        }
                      },
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
