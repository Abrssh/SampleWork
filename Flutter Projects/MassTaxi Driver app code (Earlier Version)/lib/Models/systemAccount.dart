class SystemRequirementAccount {
  final String docID, name;
  final int timeZoneOffset;
  final DateTime allowedStartingTime, allowedEndingTime;
  final bool tvStatus;
  SystemRequirementAccount(
      {this.docID,
      this.name,
      this.tvStatus,
      this.timeZoneOffset,
      this.allowedStartingTime,
      this.allowedEndingTime});
}
