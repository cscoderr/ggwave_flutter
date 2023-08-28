import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:ggwave_flutter/core/core.dart';
import 'package:record/record.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //Sample rate
  final int sampleRate = 48000;

  //Output buffer pointer for the decoded data
  ffi.Pointer<ffi.Uint8> outputBufferPointer = ffi.nullptr;

  //Payload pointer for the encoded data
  ffi.Pointer<ffi.Uint8> payloadPointer = ffi.nullptr;

  // Flag to check if the recording is in progress
  bool _isRecording = false;

  //Protocol id
  TxProtocolId txProtocolId = TxProtocolId.txProtocolAudibleFastest;

  //Audio Recorder instance
  final _recorder = AudioRecorder();

  //Flutter sound player instance
  final FlutterSoundPlayer _mPlayer = FlutterSoundPlayer();

  //List of the recorded chunks
  final List<Uint8List> _micChunks = [];

  //Encoded sound volume
  int volume = 25;

  //input text editiing controller
  late final TextEditingController _inputDataController;

  //output text editiing controller
  late final TextEditingController _outputDataController;

  //record subscription
  StreamSubscription<Uint8List>? _recoderSubscription;

  @override
  void initState() {
    super.initState();
    _inputDataController = TextEditingController();
    _outputDataController = TextEditingController();
    _initPlayer();
    _inputDataController.addListener(() {
      setState(() {});
    });
  }

  //Function to initialize the data buffer player
  Future<void> _initPlayer() async {
    await _mPlayer.openPlayer();
  }

  //Function to start recording
  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      try {
        _isRecording = true;
        setState(() {});
        final stream = await _recorder.startStream(
          RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: sampleRate,
            numChannels: 1,
            // bitRate: 4 * 1024,
          ),
        );

        _recoderSubscription = stream.listen((event) {
          _micChunks.add(event);
          setState(() {});
          if (_micChunks.hasMinimumBytes()) {
            final response = GGwaveService.instance
                .decodeData(_micChunks.toPointer(), _micChunks.totalSize);
            if (response != null) {
              _recorder.stop();
              _outputDataController.text =
                  response.isNotEmpty ? response : 'Unable to decode';
              _isRecording = false;
              setState(() {});
              _recoderSubscription?.cancel();
            }
          }
        });
      } catch (e) {
        print(e);
        _isRecording = true;
        setState(() {});
      }
    }
  }

  //Function to start playing the encoded data
  Future<void> _startPlayer(Uint8List outputData) async {
    await _mPlayer.startPlayer(
      fromDataBuffer: outputData,
      sampleRate: sampleRate,
      codec: Codec.pcm16,
    );
  }

  @override
  void dispose() {
    calloc.free(outputBufferPointer);
    calloc.free(payloadPointer);
    GGwaveService.instance.freeGGwave();
    _recorder.dispose();
    _recoderSubscription?.cancel();
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
              const Text('Volume'),
              Slider.adaptive(
                value: volume / 100,
                onChanged: (value) {
                  volume = (value * 100).toInt();
                  setState(() {});
                },
              ),
              const SizedBox(height: 20),
              const Text('Enter your message'),
              const SizedBox(height: 5),
              TextField(
                controller: _inputDataController,
                maxLines: 5,
                enabled: !_isRecording,
                decoration: const InputDecoration(
                  hintText: 'Enter your message',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _inputDataController.text.isNotEmpty && !_isRecording
                    ? () async {
                        final payloadPointer =
                            _inputDataController.text.toNativeUtf8();
                        final (outputBuffer, outputData) =
                            GGwaveService.instance.encodeData(
                          payloadPointer: payloadPointer,
                          txProtocolId: txProtocolId.value,
                          volume: volume,
                        );

                        setState(() {
                          outputBufferPointer = outputBuffer;
                        });
                        if (_mPlayer.isPlaying) {
                          _mPlayer.stopPlayer();
                        }
                        _startPlayer(outputData);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Theme.of(context).primaryColor,
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
                onPressed: () async {
                  final isRecording = await _recorder.isRecording();
                  if (isRecording || _isRecording) {
                    await _recorder.stop();
                  } else {
                    _micChunks.clear();
                    _outputDataController.clear();
                    _startRecording();
                  }
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: _isRecording
                      ? Colors.red
                      : Theme.of(context).colorScheme.secondary,
                  fixedSize: Size(MediaQuery.sizeOf(context).width, 50),
                ),
                child:
                    Text(_isRecording ? 'Stop Listening' : 'Start Listening'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
