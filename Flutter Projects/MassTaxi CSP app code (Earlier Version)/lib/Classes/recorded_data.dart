import 'package:csp_app/main.dart';

class RecordedData {
  String name;
  double average;
  int counter;

  RecordedData({this.name, this.average, this.counter});

  @override
  String toString() {
    // Converts Recorded Data into various forms of String
    return "$name;$counter;$average";
  }

  // Converts Various Types of Location Data to String
  static RecordedData fromString({String ldString}) {
    List<String> ldList = ldString.split(';');
    return RecordedData(
        name: ldList[0],
        counter: int.parse(ldList[1]),
        average: double.parse(ldList[2]));
  }

  // Save Average Recorded Data
  static Future<bool> saveAverage(RecordedData data) async {
    bool returnbool = false;
    final prefs = await AppMain.mainPrefs;
    List<String> progresstillnow = prefs.getStringList('recorded_data');
    if (progresstillnow == null) {
      progresstillnow = [];
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
        recordedAverages.add(RecordedData.fromString(ldString: strdata));
      });
      print("RECORDED DATA: " + recordedAverages.toString());
      return recordedAverages;
    } catch (e) {
      return null;
    }
  }
}
