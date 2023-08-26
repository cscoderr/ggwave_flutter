import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

class GGwaveAudioPlayer {
  static const int sampleRate = 48000;
  final AudioPlayer _audioPlayer;
  // final PlaybackListener _listener;
  // final int _numSamples;
  final Uint8List _buffer;

  GGwaveAudioPlayer(Uint8List samples)
      : _buffer = samples,
        _audioPlayer = AudioPlayer() {
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
  }

  bool get playing => _audioPlayer.state == PlayerState.playing;

  Future<void> startPlayback() async {
    if (_audioPlayer.state == PlayerState.playing) return;

    // int bufferSize = await _audioPlayer.getDuration();

    await _audioPlayer.setSource(BytesSource(_buffer));

    _audioPlayer.setVolume(1.0);
  }

  void stopPlayback() async {
    if (_audioPlayer.state == PlayerState.playing) {
      await _audioPlayer.stop();
    }
  }

  void play(List<int> samples) {
    if (_audioPlayer.state != PlayerState.playing) return;

    final buffer = Uint8List.fromList(samples);
    _audioPlayer.resume();
    _audioPlayer.play(BytesSource(buffer));
  }
}

class PlaybackListener {
  void onProgress(int progress) {}
  void onCompletion() {}
}
