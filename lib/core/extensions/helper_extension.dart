import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

extension Uint8ListExtension on Uint8List {
  Pointer<Uint8> toPointer() {
    final data = calloc<Uint8>(length);
    final bytes = data.asTypedList(length);
    bytes.setAll(0, this);
    return data;
  }
}

extension ListUint8ListExtension on List<Uint8List> {
  Pointer<Uint8> toPointer() {
    final combinedDataPtr = calloc<Uint8>(totalSize);
    var offset = 0;
    for (final data in this) {
      final dataPtr = data.toPointer();
      final dataLength = data.length;
      combinedDataPtr.asTypedList(totalSize).setAll(offset,
          dataPtr.asTypedList(dataLength)); // copy data to combinedDataPtr
      offset += dataLength;
    }
    return combinedDataPtr;
  }

  bool get hasData {
    return true;
  }

  int get totalSize => fold<int>(0, (prev, element) => prev + element.length);
}
