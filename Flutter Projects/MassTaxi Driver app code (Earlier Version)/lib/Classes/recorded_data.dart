import 'package:audio_record/main.dart';

class RecordedData {
  String name;
  double average;
  String id;

  RecordedData({this.name, this.average, this.id});

  @override
  String toString() {
    // Converts Recorded Data into various forms of String
    return "$name;;;$id;;;$average";
  }

  // Converts Various Types of Location Data to String
  static RecordedData fromString({String ldString}) {
    List<String> ldList = ldString.split(';;;');
    return RecordedData(
        name: ldList[0], id: ldList[1], average: double.parse(ldList[2]));
  }

  // Save Average Recorded Data
  static Future<bool> saveAverage(RecordedData data) async {
    bool returnbool = false;
    final prefs = await AppMain.mainPrefs;
    List<String> progresstillnow = prefs.getStringList('recorded_data');
    if (progresstillnow == null) {
      progresstillnow = [];
    }
    if (progresstillnow.length > 0) {
      RecordedData lastdata =
          RecordedData.fromString(ldString: progresstillnow.last);
      if (lastdata.id == data.id && lastdata.name == data.name) {
        //print("DUPLICATED RECORDED DATA: $data");
        return false;
      }
    }
    progresstillnow.add(data.toString());
    returnbool = await prefs.setStringList("recorded_data", progresstillnow);
    print("SAVE RECORDED DATA: $data ");
    return returnbool;
  }

  // Get Average Recorded Data
  static Future<List<RecordedData>> getAverageRecordings() async {
    try {
      final prefs = await AppMain.mainPrefs;
      List<RecordedData> recordedAverages = [];
      prefs.getStringList("recorded_data").forEach((strdata) {
        //print("RECORDINGS : " + strdata);
        recordedAverages.add(RecordedData.fromString(ldString: strdata));
      });
      print("RECORDED DATA: " + recordedAverages.toString());
      return recordedAverages;
    } catch (e) {
      return null;
    }
  }
}
