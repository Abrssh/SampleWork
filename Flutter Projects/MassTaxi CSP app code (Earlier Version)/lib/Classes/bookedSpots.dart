class BookedSpot {
  final String name, plateNumber, phoneNumber, phoneModel;
  final List<String> mainRoutes;
  final bool scheduled, registered;
  final String docID;
  BookedSpot(
      {this.name,
      this.plateNumber,
      this.phoneNumber,
      this.phoneModel,
      this.mainRoutes,
      this.docID,
      this.scheduled,
      this.registered});
}
