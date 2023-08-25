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

  int ggwaveFree(int instance) {
    final ggwave_free =
        _nativeApiLib.lookup<ffi.NativeFunction<ffi.Int32 Function(ffi.Int32)>>(
            'ggwave_free');
    final ggwaveFreeFun = ggwave_free.asFunction<int Function(int)>();
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
    required ffi.Pointer<Utf8> payloadBuffer,
    required int payloadSize,
    required int protocolId,
    required int volume,
    required ffi.Pointer<ffi.Void> waveformBuffer,
    required int query,
  }) {
    late final _ggwave_encodePtr = _nativeApiLib.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
                ggwave_Instance,
                ffi.Pointer<Utf8>,
                ffi.Int,
                ffi.Int32,
                ffi.Int,
                ffi.Pointer<ffi.Void>,
                ffi.Int)>>('ggwave_encode');
    final _ggwaveEncodeFun = _ggwave_encodePtr.asFunction<
        int Function(int, ffi.Pointer<Utf8>, int, int, int,
            ffi.Pointer<ffi.Void>, int)>();
    return _ggwaveEncodeFun(instance, payloadBuffer, payloadSize, protocolId,
        volume, waveformBuffer, query);
  }
}
