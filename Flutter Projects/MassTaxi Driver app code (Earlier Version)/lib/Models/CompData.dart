class CompAdCardData {
  final String audioUniqueName, adCardDocID, hash;
  CompAdCardData({this.audioUniqueName, this.adCardDocID, this.hash});
}

class CompData {
  final List<CompAdCardData> listOfAdCards;
  final double profit;
  final int adBreakNum;
  CompData({this.listOfAdCards, this.profit, this.adBreakNum});
}
