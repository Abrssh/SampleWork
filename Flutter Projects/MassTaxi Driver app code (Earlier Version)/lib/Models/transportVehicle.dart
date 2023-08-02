class TransportVehicle {
  final String plateNumber, systemAccountId, tvDocID, carModelID, imageUrl;
  final bool speakerQuality, engineSoundPollution;
  var speakerPosition;

  TransportVehicle(
      {this.plateNumber,
      this.engineSoundPollution,
      this.systemAccountId,
      this.imageUrl,
      this.speakerPosition,
      this.speakerQuality,
      this.carModelID,
      this.tvDocID});
}
