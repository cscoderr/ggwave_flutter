import 'dart:ffi';

final class Parameters extends Struct {
  @Int()
  external int payloadLength;

  @Float()
  external double sampleRateInp;

  @Float()
  external double sampleRateOut;

  @Int()
  external int samplesPerFrame;

  @Float()
  external double soundMarkerThreshold;

  @Int32()
  external int sampleFormatInp;

  @Int32()
  external int sampleFormatOut;
}
