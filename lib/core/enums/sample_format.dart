enum SampleFormat {
  sampleFormatundefined(0),
  sampleFormatU8(1),
  sampleFormatI8(2),
  sampleFormatU16(3),
  sampleFormatI16(4),
  sampleFormatF32(5);

  const SampleFormat(this.value);

  final int value;
}
