enum TxProtocolId {
  txProtocolAudibleNormal(0, "Normal"),
  txProtocolAudibleFast(1, "Fast"),
  txProtocolAudibleFastest(2, "Fastest"),
  txProtocolAudibleUltraNormal(3, "Ultra Normal"),
  txProtocolAudibleUltraFast(4, "Ultra Fast"),
  txProtocolAudibleUltraFatest(5, "Ultra Fastest"),
  txProtocolAudibleDtNormal(6, "DT Normal"),
  txProtocolAudibleDtFast(7, "DT Fast"),
  txProtocolAudibleDtFastest(8, "DT Fastest");

  const TxProtocolId(this.value, this.text);

  final int value;
  final String text;
}
