// ignore_for_file: no_leading_underscores_for_local_identifiers, non_constant_identifier_names

import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';

import '../ggwave_bindings.dart';

class GGwaveBridge {
  GGwaveBridge(ffi.DynamicLibrary nativeApiLib) : _nativeApiLib = nativeApiLib;
  final ffi.DynamicLibrary _nativeApiLib;

  int ggwaveInit(ggwave_Parameters paramters) {
    final init = _nativeApiLib
        .lookup<ffi.NativeFunction<ffi.Int32 Function(ggwave_Parameters)>>(
            'ggwave_init');
    final ggwabeFun = init.asFunction<int Function(ggwave_Parameters)>();
    return ggwabeFun(paramters);
  }

  void ggwaveFree(int instance) {
    final ggwave_free =
        _nativeApiLib.lookup<ffi.NativeFunction<ffi.Void Function(ffi.Int32)>>(
            'ggwave_free');
    final ggwaveFreeFun = ggwave_free.asFunction<void Function(int)>();
    return ggwaveFreeFun(instance);
  }

  ggwave_Parameters getDefaultParameters() {
    final defaultParameters =
        _nativeApiLib.lookup<ffi.NativeFunction<ggwave_Parameters Function()>>(
            'ggwave_getDefaultParameters');
    final getDefaultParametersFunc =
        defaultParameters.asFunction<ggwave_Parameters Function()>();
    return getDefaultParametersFunc();
  }

  int ggwaveEncode({
    required int instance,
    required ffi.Pointer<Utf8> dataBuffer,
    required int dataSize,
    required int txProtocolId,
    required int volume,
    required ffi.Pointer<Utf8> outputBuffer,
    required int query,
  }) {
    late final ggwave_encode = _nativeApiLib.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
                ggwave_Instance,
                ffi.Pointer<Utf8>,
                ffi.Int,
                ffi.Int32,
                ffi.Int,
                ffi.Pointer<Utf8>,
                ffi.Int)>>('ggwave_encode');
    final ggwaveEncodeFunc = ggwave_encode.asFunction<
        int Function(
            int, ffi.Pointer<Utf8>, int, int, int, ffi.Pointer<Utf8>, int)>();
    return ggwaveEncodeFunc(instance, dataBuffer, dataSize, txProtocolId,
        volume, outputBuffer, query);
  }

  int ggwaveDecode({
    required int instance,
    required ffi.Pointer<Utf8> dataBuffer,
    required int dataSize,
    required ffi.Pointer<Utf8> outputBuffer,
  }) {
    final _ggwave_decode = _nativeApiLib.lookup<
        ffi.NativeFunction<
            ffi.Int Function(ffi.Int, ffi.Pointer<Utf8>, ffi.Int,
                ffi.Pointer<Utf8>)>>('ggwave_decode');
    final _ggwaveDecodeFun = _ggwave_decode.asFunction<
        int Function(int, ffi.Pointer<Utf8>, int, ffi.Pointer<Utf8>)>();
    return _ggwaveDecodeFun(instance, dataBuffer, dataSize, outputBuffer);
  }
}
