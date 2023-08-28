import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:ggwave_flutter/core/core.dart';

class UnableToDecodeDataException implements Exception {
  UnableToDecodeDataException(this.message);
  final String message;

  @override
  String toString() {
    return message.toString();
  }
}

class GGwaveService {
  GGwaveService._({
    required GGwaveBridge gGwaveBridge,
  }) : _gGwaveBridge = gGwaveBridge {
    _instance = initGGwave();
    print("called!!!!");
  }

  static final GGwaveService instance = GGwaveService._(
    gGwaveBridge: GGwaveBridge(
      Platform.isAndroid
          ? ffi.DynamicLibrary.open('libggwave.so')
          : ffi.DynamicLibrary.process(),
    ),
  );

  final GGwaveBridge _gGwaveBridge;
  late final int _instance;

  String? decodeData(ffi.Pointer<ffi.Uint8> dataBuffer, int dataSize) {
    ffi.Pointer<ffi.Uint8> decoded = calloc<ffi.Uint8>(256);
    final response = _gGwaveBridge.ggwaveDecode(
      instance: _instance,
      dataBuffer: dataBuffer.cast(),
      dataSize: 2 * dataSize,
      outputBuffer: decoded.cast(),
    );

    if (response != 0) {
      try {
        final output = decoded.cast<ffi.Uint8>().asTypedList(response);

        final result = output
            .map((codePoint) => String.fromCharCode(codePoint))
            .toList()
            .join("");
        print("result: $result");
        return result;
      } catch (e) {
        return null;
      } finally {
        calloc.free(decoded);
      }
    }
    calloc.free(decoded);
    return null;
  }

  (ffi.Pointer<ffi.Uint8>, Uint8List) encodeData({
    required ffi.Pointer<Utf8> payloadPointer,
    required int txProtocolId,
    required int volume,
  }) {
    final encodedPayload = _gGwaveBridge.ggwaveEncode(
      instance: _instance,
      dataBuffer: payloadPointer.cast<Utf8>(),
      dataSize: payloadPointer.length,
      txProtocolId: txProtocolId,
      volume: volume,
      outputBuffer: ffi.nullptr,
      query: 1,
    );
    ffi.Pointer<ffi.Uint8> outputBufferPointer =
        calloc<ffi.Uint8>(encodedPayload);

    int ret = _gGwaveBridge.ggwaveEncode(
      instance: _instance,
      dataBuffer: payloadPointer.cast<Utf8>(),
      dataSize: payloadPointer.length,
      txProtocolId: txProtocolId,
      volume: volume,
      outputBuffer: outputBufferPointer.cast(),
      query: 0,
    );
    final outputData =
        outputBufferPointer.cast<ffi.Uint8>().asTypedList(2 * ret);
    return (outputBufferPointer, outputData);
  }

  int initGGwave() {
    final parameters = defaultParameters;
    parameters.sampleFormatInp = SampleFormat.sampleFormatI16.value;
    parameters.sampleFormatOut = SampleFormat.sampleFormatI16.value;
    final instance = _gGwaveBridge.ggwaveInit(parameters);
    return instance;
  }

  void freeGGwave() {
    _gGwaveBridge.ggwaveFree(_instance);
  }

  Parameters get defaultParameters => _gGwaveBridge.getDefaultParameters();
}
