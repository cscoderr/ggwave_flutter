import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class UnableToRecordException implements Exception {
  const UnableToRecordException();
}

class GGwaveSound {
  GGwaveSound({
    FlutterSoundPlayer? mPlayer,
    AudioRecorder? recorder,
  })  : _mPlayer = (mPlayer ?? FlutterSoundPlayer())..openPlayer(),
        _recorder = recorder ?? AudioRecorder();

  static const int sampleRate = 48000;

  //Audio Recorder instance
  final AudioRecorder _recorder;

  //Flutter sound player instance
  final FlutterSoundPlayer _mPlayer;

  //Function to start recording
  Future<Stream<Uint8List>> startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (hasPermission) {
      try {
        final stream = await _recorder.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: sampleRate,
            numChannels: 1,
            // bitRate: 4 * 1024,
          ),
        );
        return stream;
      } catch (e) {
        throw const UnableToRecordException();
      }
    } else {
      throw const UnableToRecordException();
    }
  }

  //Function to stop recording
  Future<void> stopRecording() async {
    await _recorder.stop();
  }

  //Function to start playing the encoded data
  Future<void> startPlayer(Uint8List outputData) async {
    await _mPlayer.startPlayer(
      fromDataBuffer: outputData,
      sampleRate: sampleRate,
      codec: Codec.pcm16,
    );
  }

  Future<void> stopPlayer() async {
    await _mPlayer.stopPlayer();
  }

  Future<void> requestPermission() async {
    final permissionStatus = await Permission.microphone.request();
    if (permissionStatus != PermissionStatus.granted) {
      print("Permission not granted");
    }
  }

  bool get isPlaying => _mPlayer.isPlaying;

  Future<bool> isRecording() async => _recorder.isRecording();

  void dispose() {
    _mPlayer.closePlayer();
    _recorder.dispose();
  }
}
