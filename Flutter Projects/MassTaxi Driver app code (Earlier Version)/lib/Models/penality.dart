class PenalityModel {
  String type, description, suspensionDate, returnDate;
  var suspensionLength;
  PenalityModel(
      {this.type,
      this.description,
      this.suspensionDate,
      this.returnDate,
      this.suspensionLength});
  defineType(String shortHandType) {
    if (shortHandType == "TPF") {
      type = "Two Phone Fraud";
      description = "Two or more drivers put their phone in one" +
          "transport vehicle to try and get paid.";
    } else if (shortHandType == "VF") {
      type = "Vehicle Fraud";
      description = "Trying to use the system in unregistered vechicle.";
    } else if (shortHandType == "AF") {
      type = "Audio Fraud";
      description = "Speaker was playing different audio in place of the Ad.";
    } else if (shortHandType == "VE") {
      type = "Vehicle Exit";
      description = "Exiting the vehicle before reporting";
    } else {
      type = "File Fraud";
      description = "The Ad file was corrupted or modified.";
    }
  }
}
