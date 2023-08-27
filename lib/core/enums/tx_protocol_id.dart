enum TxProtocolId {
  txProtocolAudibleNormal(0),
  txProtocolAudibleFast(1),
  txProtocolAudibleFastest(2),
  txProtocolAudibleUltraNormal(3),
  txProtocolAudibleUltraFast(4),
  txProtocolAudibleUltraFatest(5),
  txProtocolAudibleDtNormal(6),
  txProtocolAudibleDtFast(7),
  txProtocolAudibleDtFastest(8);

  const TxProtocolId(this.value);

  final int value;
}
