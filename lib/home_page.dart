import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:ggwave_flutter/core/core.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //Output buffer pointer for the decoded data
  ffi.Pointer<ffi.Uint8> outputBufferPointer = ffi.nullptr;

  final int _maxChunkSize = 50000;

  // Flag to check if the recording is in progress
  bool _isRecording = false;

  //Protocol id
  TxProtocolId txProtocolId = TxProtocolId.txProtocolAudibleFastest;

  late GGwaveService _ggwaveService;

  late final GGwaveSound _ggWaveSound;

  //Encoded sound volume
  int volume = 25;

  //List of the recorded chunks
  final List<Uint8List> _micChunks = [];

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
    _ggwaveService = GGwaveService.instance;
    _ggWaveSound = GGwaveSound();
    _inputDataController.addListener(() {
      setState(() {});
    });
    _requestPermission();
  }

  void _requestPermission() {
    _ggWaveSound.requestPermission();
  }

  Future<void> _startRecording() async {
    try {
      //TODO: _ggWaveSound.startRecording() stream is not working well
      final stream = await _ggWaveSound.startRecording();
      _recoderSubscription = stream.listen((event) {
        _micChunks.add(event);
        print("listening!!!!");
        if (_micChunks.hasMinimumBytes()) {
          print("decode!!!!");
          final response = _ggwaveService.decodeData(
              _micChunks.toPointer(), _micChunks.totalSize);
          if (response != null) {
            final output = response.isNotEmpty ? response : 'Unable to decode';
            _outputDataController.text = output;
            _isRecording = false;
            _micChunks.clear();
            if (mounted) {
              setState(() {});
            }
            _ggWaveSound.stopRecording();
            _recoderSubscription?.cancel();
          }
        } else if (_micChunks.totalSize >= _maxChunkSize) {
          _outputDataController.text = 'Unable to decode';
          _isRecording = false;
          _micChunks.clear();
          setState(() {});
          _ggWaveSound.stopRecording();
          _recoderSubscription?.cancel();
        }
      });
    } on UnableToRecordException {
      _outputDataController.text = 'Unable to record';
      _isRecording = false;
      _micChunks.clear();
      setState(() {});
    }
  }

  @override
  void dispose() {
    calloc.free(outputBufferPointer);
    _ggwaveService.freeGGwave();
    _ggWaveSound.dispose();
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
                onPressed: _isInputDataValid ? () => _handleEncode() : null,
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
                onPressed: () => _handleDecode(),
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

  bool get _isInputDataValid =>
      _inputDataController.text.isNotEmpty && !_isRecording;

  //Function to handle the encoding of the data
  Future<void> _handleEncode() async {
    final payloadPointer = _inputDataController.text.toNativeUtf8();
    final (outputBuffer, outputData) = _ggwaveService.encodeData(
      payloadPointer: payloadPointer,
      txProtocolId: txProtocolId.value,
      volume: volume,
    );

    setState(() {
      outputBufferPointer = outputBuffer;
    });
    if (_ggWaveSound.isPlaying) {
      _ggWaveSound.stopPlayer();
    }
    await _ggWaveSound.startPlayer(outputData);
    calloc.free(payloadPointer);
  }

  //Function to handle the decoding of the data
  Future<void> _handleDecode() async {
    if (_isRecording) {
      await _ggWaveSound.stopRecording();
      _isRecording = false;
      setState(() {});
    } else {
      _ggWaveSound.stopRecording();
      _micChunks.clear();
      _outputDataController.clear();
      _isRecording = true;
      setState(() {});
      _startRecording();
    }
  }
}
