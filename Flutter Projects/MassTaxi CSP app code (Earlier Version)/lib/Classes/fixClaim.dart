class FixClaim {
  final String createdDate, phoneNumber, plateNumber, type, docID;
  final bool urgent, scheduled;

  FixClaim(
      {this.createdDate,
      this.phoneNumber,
      this.plateNumber,
      this.type,
      this.docID,
      this.scheduled,
      this.urgent});
}
