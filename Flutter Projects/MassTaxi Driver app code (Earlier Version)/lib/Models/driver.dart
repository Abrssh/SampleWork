class Driver {
  final String phoneID,
      docID,
      name,
      systemAccountID,
      bankAccount,
      plateNumber,
      phoneNumber;
  var calibration;
  final List<String> mainRoutes;
  var potentialBalance, balance, totalProfit;
  final bool banned, status;
  final DateTime recentDailyDate;
  final int recentDailyStatus;
  final bool failedFix;

  Driver(
      {this.banned,
      this.status,
      this.phoneID,
      this.docID,
      this.systemAccountID,
      this.plateNumber,
      this.phoneNumber,
      this.bankAccount,
      this.mainRoutes,
      this.calibration,
      this.balance,
      this.name,
      this.recentDailyDate,
      this.recentDailyStatus,
      this.failedFix,
      this.totalProfit,
      this.potentialBalance});
}
