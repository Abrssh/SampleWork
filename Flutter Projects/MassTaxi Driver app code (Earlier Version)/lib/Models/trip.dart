class TripModel {
  final String pathName, date, startTime, endTime;
  var adServed,
      numberOfAvailableAds,
      profit,
      availableProfit,
      status,
      imageStatus;
  List<dynamic> weeklyRoutes, totalRoutes;

  TripModel(
      {this.pathName,
      this.date,
      this.startTime,
      this.adServed,
      this.numberOfAvailableAds,
      this.endTime,
      this.profit,
      this.availableProfit,
      this.weeklyRoutes,
      this.totalRoutes,
      this.imageStatus,
      this.status});
}
