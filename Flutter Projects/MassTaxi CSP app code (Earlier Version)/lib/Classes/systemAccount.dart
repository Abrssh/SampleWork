class SystemRequirementAccount {
  final String docID, name;
  final int timeZoneOffset;
  final DateTime allowedStartingTime, allowedEndingTime;
  SystemRequirementAccount(
      {this.docID,
      this.name,
      this.timeZoneOffset,
      this.allowedStartingTime,
      this.allowedEndingTime});
}
