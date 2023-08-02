import 'package:audio_record/Classes/location_data.dart';
import 'package:audio_record/Classes/recorded_data.dart';
import 'package:audio_record/main.dart';
import 'package:sort/sort.dart';
import 'dart:math';

class RouteData {
  int adnumber;
  int adbreak;
  int sequence;
  String adname;
  double averageSpeed;
  double median;
  double enterQuarterRange;
  double topSpeed;
  List<Acceleration> upwardAccelerations;
  List<Acceleration> downwardAccelerations;
  int duration = 0;
  List<double> speeds;
  double oneAcc;
  double averageDownwardAcc;
  double averageUpwardAcc;
  double score;
  double totalOneAccs = 0;
  int count = 0;
  String status;
  bool silence = false;
  Acceleration topAcceleration;
  double recordedAverage = 0;
  int up01 = 0;
  int up12 = 0;
  int up23 = 0;
  int up34 = 0;
  int up4a = 0;
  int positions;
  static int lms = 11;
  static int hms = 13;
  static int vhms = 16;
  static int cutoff = 7;
  static int aCount = 2;
  static List<int> adDurations = [];
  static List<DateTime> adEndingTimes = [];
  int strike = 0;
  List<Acceleration> importantAccelerations;
  String reason;
  static Map<int, LocationData> lastSpots = Map();
  static List<RecordedData> recordedAverages = [];
  static DateTime adFirstTime;
  static List<RouteData> finalAdStats = [];

  static Future<bool> saveAdFinals() async {
    bool returnbool = false;
    final prefs = await AppMain.mainPrefs;
    List<String> adfinals = prefs.getStringList('ad_finals');
    if (adfinals == null) {
      adfinals = [];
    }
    adfinals.add(DateTime.now().toString());
    print("SAVE AD ENDING");
    returnbool = await prefs.setStringList("ad_finals", adfinals);
    return returnbool;
  }

  static Future<bool> saveFirstAdTime() async {
    bool returnbool = false;
    final prefs = await AppMain.mainPrefs;
    returnbool = await prefs.setString("first_ad", DateTime.now().toString());
    print("FIRST ADD SAVED $returnbool");
    return returnbool;
  }

  static Future<DateTime> getFirstAdTime() async {
    try {
      final prefs = await AppMain.mainPrefs;
      return DateTime.parse(prefs.getString("first_ad"));
    } catch (e) {
      return null;
    }
  }

  static Future<List<DateTime>> getAdEndings() async {
    try {
      final prefs = await AppMain.mainPrefs;
      List<String> adfinals = prefs.getStringList("ad_finals");
      List<DateTime> decoratedAdFinals = [];
      adfinals.forEach((adfinal) {
        decoratedAdFinals.add(DateTime.parse(adfinal));
      });
      adEndingTimes = decoratedAdFinals;
      return decoratedAdFinals;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> generateAdDurations() async {
    RouteData.adDurations = [];
    if (adFirstTime != null) {
      try {
        List<DateTime> adEndings = await RouteData.getAdEndings();
        print("AD ENDINGS $adEndings");
        for (int i = 0; i < adEndings.length; i++) {
          int duration = 0;
          if (i == 0) {
            duration = (adEndings[0].millisecondsSinceEpoch -
                    adFirstTime.millisecondsSinceEpoch) ~/
                1000;
          } else {
            duration = ((adEndings[i].millisecondsSinceEpoch -
                        adEndings[i - 1].millisecondsSinceEpoch) ~/
                    1000) +
                -2;
          }
          RouteData.adDurations.add(duration);
        }
        print("AD DURATIONS: ${RouteData.adDurations}");
        return true;
      } catch (e) {
        print("AD DURATIONS ERROR: $e");
        return false;
      }
    } else {
      return false;
    }
  }

  static Future<List<RouteData>> generateRouteData(
      List<LocationData> savedLocs) async {
    print("COMPLETEE SAVED : " + savedLocs.length.toString());
    Map<int, RouteData> adStats = Map();
    Map<int, List<RouteData>> adStatsPerBreak = Map();
    recordedAverages = await RecordedData.getAverageRecordings();
    //adFirstTime = await getFirstAdTime();
    //await generateAdDurations();
    // Map<int, List<PausedStat>> pausedStats =
    //     await PausedStat.generatePausedStats();
    List<LocationData> savedForEachAd = [];
    int ad = 0;
    var rng = new Random();
    for (LocationData ld in savedLocs) {
      if (ld.name != null) {
        print('COMPLETEE FOR ' + ld.name + "${rng.nextInt(1000)}");

        List<String> templ = ld.name.split('#*#');
        if (templ.length == 7) {
          int checkad = int.parse(templ[1]);
          int oldad = int.parse(templ[2]);
          if (ad == 0) {
            ad = checkad;
          }
          if (checkad == ad || oldad == ad) {
            savedForEachAd.add(ld);
          }
          if (checkad > ad) {
            adStats[ad] = adResults(ad, savedForEachAd, lastSpots[ad - 1]);
            ad = checkad;
            savedForEachAd = [];
            savedForEachAd.add(ld);
          }
        }
      }
    }

    if (ad > 0 && savedForEachAd.length > 0) {
      adStats[ad] = adResults(ad, savedForEachAd, lastSpots[ad - 1]);
      //print("Finally AD STATS FOR $ad : $adStats");
    }
    // if (pausedStats != null) {
    //   pausedStats.forEach((ad, p) {
    //     int sum = 0;
    //     pausedStats[ad].forEach((pofa) {
    //       if (pofa.duration != null) {
    //         sum += pofa.duration;
    //       }
    //     });
    //     adStats[ad].duration -= sum;
    //   });
    // }

    //adStats.forEach((k, v) => finalAdStats.add(v));

    List<RouteData> breaks = [];
    if (adStats.length >= 2) {
      for (int adn = 2; adn <= adStats.length; adn++) {
        if (adStats[adn] != null && adStats[adn - 1] != null) {
          print(
              "SILENCE FOR ${adn - 1} - ${adStats[adn - 1].adnumber} --- ${adStats[adn].adnumber}");
          RouteData adta =
              silenceResults(adn - 1, adStats[adn - 1], adStats[adn]);
          adta.adbreak = adStats[adn - 1].adbreak;
          adta.adname = adStats[adn - 1].adname;
          adta.sequence = adStats[adn - 1].sequence;
          print(
              "COMPLETEE SILENCE CALCULATED FOR ${adta.adnumber} : ${adta.adbreak} : ${adta.sequence} : ${adta.status}");
          breaks.add(adta);
        } else {
          RouteData adta = RouteData();
          adta.adnumber = adn - 1;

          adta.adbreak = adStats[adn - 1].adbreak;
          adta.adname = adStats[adn - 1].adname;
          adta.sequence = adStats[adn - 1].sequence;
          adta.status = 'N/A';
          breaks.add(adta);
          print(
              "COMPLETEE SILENCE NULL FOR ${adta.adnumber} : ${adta.adbreak} : ${adta.sequence}");
        }
      }
    }
    finalAdStats = [];
    for (int adn = 0; adn < adStats.length; adn++) {
      if (adStats[adn + 1] == null) {
        RouteData adta = RouteData();
        adta.adnumber = adn + 1;
        adta.status = 'N/A';
        finalAdStats.add(adta);
      } else {
        finalAdStats.add(adStats[adn + 1]);
      }
      print(
          "ADVERTS DATA-- $adn : ${breaks.length} ${finalAdStats.last.adnumber} ");
      if (adn < breaks.length) {
        if (breaks[adn] == null) {
          if (adStats.length == adn + 1) {
            continue;
          }
          RouteData breakk = RouteData();
          breakk.adnumber = adn;
          breakk.status = 'N/A';
          breakk.silence = true;
          finalAdStats.add(breakk);
        } else {
          breaks[adn].silence = true;
          finalAdStats.add(breaks[adn]);
        }
      }

      print("DATA-- ----------------- ${finalAdStats.length}");
    }
    finalAdStats.forEach((element) {
      if (!element.silence) {
        print(
            "ORG AD-${element.adnumber}-${element.adbreak}-${element.sequence}-${element.adname}-${element.status}");
      } else {
        print(
            "ORG ST-${element.adnumber}-${element.adbreak}-${element.sequence}-${element.adname}-${element.status}");
      }
    });

    finalAdStats.forEach((element) {
      String name = element.silence ? "ST" : "AD";
      recordedAverages.forEach((average) {
        if (int.parse(average.id.split('#*#')[0]) == element.adnumber &&
            average.name == name) {
          element.recordedAverage = average.average;
        }
      });
      print(
          "FINAL COMPLETEE FOR ${element.silence ? 'ST' : 'AD'} ${element.adname} : ${element.status}  : ${element.recordedAverage}");
      if (adStatsPerBreak[element.adbreak] != null) {
        adStatsPerBreak[element.adbreak].add(element);
      } else {
        adStatsPerBreak[element.adbreak] = [element];
      }
    });
    adStatsPerBreak.forEach((key, value) {
      print("AD BREAK $key : COMPONENTS ${value.length}");
    });

    // for (int adn = 0; adn < adStats.length; adn++) {
    //   if (adStats[adn + 1] == null) {
    //     RouteData adta = RouteData();
    //     adta.adnumber = adn + 1;
    //     adta.status = 'N/A';
    //     finalAdStats.add(adta);
    //   } else {
    //     finalAdStats.add(adStats[adn + 1]);
    //   }
    // }

    return finalAdStats;
  }

  static RouteData silenceResults(
      int adnumber, RouteData old, RouteData current) {
    RouteData ad = RouteData();
    ad.adnumber = adnumber;
    ad.silence = true;
    ad.reason = "";
    double oldspeed = 0;
    ad.enterQuarterRange = 0;
    print("SILENCE FOR $adnumber - OLD SPEEDS LENGTH: ${old.speeds.length}");
    print(
        "SILENCE FOR $adnumber - CURRENT SPEEDS LENGTH: ${current.speeds.length}");
    if (old.speeds.length > 1 && current.speeds.length >= 1) {
      if (old.speeds.last != current.speeds.first) {
        oldspeed = old.speeds.last;
        ad.oneAcc = current.speeds.first - old.speeds.last;
        ad.median = (current.speeds.first + old.speeds.last) / 2;
      } else {
        oldspeed = old.speeds[old.speeds.length - 2];
        ad.oneAcc = current.speeds.first - old.speeds[old.speeds.length - 2];
        ad.median =
            (current.speeds.first + old.speeds[old.speeds.length - 2]) / 2;
      }
      if (ad.oneAcc > 3) {
        if (oldspeed < cutoff) {
          if (ad.status == null) {
            ad.status = 'Disturbed';
          }
          ad.reason += "Up 3a Recorded; ";
        }
      } else if (ad.oneAcc > 1) {
        if (oldspeed > cutoff) {
          if (ad.status == null) {
            ad.status = 'Disturbed';
          }
          ad.reason += "Speed More than $cutoff; ";
        }
      }

      if (ad.median > lms) {
        if (ad.status == null) {
          ad.status = 'Disturbed';
        }
        ad.reason += 'Median is > $lms; ';
      }

      if (ad.oneAcc >= 0) {
        ad.topSpeed = current.speeds.first;
      } else {
        ad.topSpeed = oldspeed;
      }

      if (ad.topSpeed > cutoff) {
        if (ad.status == null) {
          ad.status = 'Disturbed';
        }
        ad.reason += 'Top Speed > $cutoff ';
      }

      if (ad.status == null) {
        ad.status = 'Pure';
      }
    } else {
      ad.oneAcc = null;
      ad.reason = null;
      ad.median = null;
      ad.status = 'N/A';
      ad.enterQuarterRange = null;
    }

    return ad;
  }

  static RouteData adResults(
    int adnumber,
    List<LocationData> adLocs,
    LocationData old,
  ) {
    RouteData ad = RouteData();

    if (RouteData.adDurations != null) {
      if (RouteData.adDurations.length >= adnumber) {
        ad.duration = RouteData.adDurations[adnumber - 1];
      }
    }
    ad.upwardAccelerations = [];
    ad.downwardAccelerations = [];
    ad.importantAccelerations = [];

    ad.speeds = [];
    ad.median = 0;
    ad.enterQuarterRange = 0;
    ad.topAcceleration = Acceleration(value: 0, u: 0, time: 0);
    double totalSpeed = 0;

    ad.reason = "";
    print("AD E: $adnumber");
    print("AD E: $old");

    print("LOCATIONS FOR $adnumber : $adLocs");
    if (adLocs.length >= 2) {
      ad.positions = adLocs.length;
      // double totalOneAccs = 0;
      // int count = 0;

      ad.topSpeed = adLocs[0].speed;
      ad.speeds.add(adLocs[0].speed);
      for (int i = 1; i < adLocs.length; i++) {
        print("ad loc: " + adLocs[i].toString());
        totalSpeed += adLocs[i].speed;
        ad.speeds.add(adLocs[i].speed);
        Acceleration acc = Acceleration.generateAcc(adLocs[i - 1], adLocs[i]);
        if (adLocs[i].speed > ad.topSpeed) {
          ad.topSpeed = adLocs[i].speed;
        }
        if (acc.value > 1) {
          ad.totalOneAccs += acc.value;
          ad.count += 1;
        }
        if (acc.value > 0) {
          if (acc.value > 4) {
            if (acc.u > cutoff) {
              if (ad.status == null) {
                ad.status = 'Disturbed';
              }
              ad.reason += "Up 4a Recorded; ";
            } else {
              ad.importantAccelerations
                  .add(Acceleration.formatedAcceleration(acc));
            }
            ad.up4a += 1;
          } else if (acc.value > 3) {
            if (acc.u > cutoff) {
              if (ad.status == null) {
                ad.status = 'Disturbed';
              }
              ad.reason += "Up 3-4a Recorded; ";
            } else {
              ad.importantAccelerations
                  .add(Acceleration.formatedAcceleration(acc));
            }
            ad.up34 += 1;
          } else if (acc.value > 2) {
            if (acc.u > cutoff) {
              ad.importantAccelerations
                  .add(Acceleration.formatedAcceleration(acc));
            }
            ad.up23 += 1;
          } else if (acc.value > 1) {
            if (acc.u > cutoff) {
              ad.importantAccelerations
                  .add(Acceleration.formatedAcceleration(acc));
            }
            ad.up12 += 1;
          } else {
            ad.up01 += 1;
          }
          print("TOTAL: ${ad.totalOneAccs} : COUNT: ${ad.count}");
          if (ad.upwardAccelerations.length != 0) {
            if (acc.value > ad.topAcceleration.value) {
              ad.topAcceleration = acc;
            }
          } else {
            ad.topAcceleration = acc;
          }
          ad.upwardAccelerations.add(Acceleration.formatedAcceleration(acc));
        }
      }

      totalSpeed += adLocs[0].speed;
      ad.averageSpeed = totalSpeed / ad.positions;
      try {
        if (ad.count > 0) {
          ad.score = ad.totalOneAccs / ad.count;
        } else {
          ad.score = null;
        }
      } catch (e) {
        ad.score = null;
      }
      ad.speeds.quickSort();
      int medianIndex = 0;
      try {
        if (ad.speeds.length > 2) {
          medianIndex = ad.speeds.length ~/ 2;
          if (ad.speeds.length % 2 == 0) {
            ad.median = (ad.speeds[((ad.speeds.length ~/ 2))] +
                    ad.speeds[((ad.speeds.length ~/ 2) - 1)]) /
                2;
          }
          ad.median = ad.speeds[((ad.speeds.length ~/ 2))];
        } else {
          ad.median = ad.speeds[0];
        }
      } catch (e) {
        ad.median = null;
      }
      try {
        if (ad.speeds.length > 2) {
          List<double> firsthalf = [];
          List<double> secondhalf = [];
          if (ad.speeds.length % 2 == 0) {
            firsthalf = ad.speeds.sublist(0, medianIndex - 1);
            secondhalf = ad.speeds.sublist(medianIndex + 1);
          } else {
            firsthalf = ad.speeds.sublist(0, medianIndex);
            secondhalf = ad.speeds.sublist(medianIndex + 1);
          }
          double fh, sh = 0;
          if (firsthalf.length <= 2) {
            fh = firsthalf[0];
          } else {
            if (firsthalf.length % 2 == 0) {
              fh = (firsthalf[((firsthalf.length ~/ 2))] +
                      firsthalf[((firsthalf.length ~/ 2) - 1)]) /
                  2;
            } else {
              fh = firsthalf[((firsthalf.length ~/ 2))];
            }
          }
          if (secondhalf.length <= 2) {
            sh = secondhalf[0];
          } else {
            if (secondhalf.length % 2 == 0) {
              sh = (secondhalf[((secondhalf.length ~/ 2))] +
                      secondhalf[((secondhalf.length ~/ 2) - 1)]) /
                  2;
            } else {
              sh = secondhalf[((secondhalf.length ~/ 2))];
            }
          }
          ad.enterQuarterRange = sh - fh;
        } else {
          ad.enterQuarterRange = ad.speeds[ad.speeds.length - 1] - ad.speeds[0];
        }
      } catch (e) {
        ad.enterQuarterRange = null;
      }
      if (ad.status == null) {
        if (ad.importantAccelerations.length == 0 || ad.duration > 20) {
          if (ad.importantAccelerations.length >= RouteData.aCount) {
            if (ad.status == null) {
              ad.status = 'Disturbed';
            }
            ad.reason += '${ad.importantAccelerations.length} Important Acc; ';
          }
        } else {
          if (ad.importantAccelerations.length >= 1) {
            if (ad.status == null) {
              ad.status = 'Disturbed';
            }
            ad.reason += '${ad.importantAccelerations.length} Important Acc; ';
          }
        }

        if (ad.enterQuarterRange != null) {
          if (ad.enterQuarterRange > cutoff) {
            if (ad.median > vhms) {
              if (ad.status == null) {
                ad.status = 'Disturbed';
              }
              ad.reason += 'IQR is > $cutoff; ';
            }
          } else if (ad.enterQuarterRange > 2) {
            if (ad.median > hms) {
              if (ad.status == null) {
                ad.status = 'Disturbed';
              }
              ad.reason += 'IQR is > 2; ';
            }
          } else {
            if (ad.median > lms) {
              if (ad.status == null) {
                ad.status = 'Disturbed';
              }
              ad.reason += 'IQR is < 2; ';
            }
          }
        }
      }
      ad.adnumber = adnumber;
      List<String> adname = adLocs[0].name.split('#*#');
      ad.adbreak = int.parse(adname[3]);
      ad.adname = adname[5];
      ad.sequence = int.parse(adname[4]);

      if (ad.status == null) {
        if (ad.topSpeed < 10 &&
            ad.importantAccelerations.length == 0 &&
            ad.up34 == 0 &&
            ad.up23 == 0 &&
            ad.up4a == 0) {
          ad.status = 'Pure';
          ad.reason = null;
        }
      }
      if (ad.status == null) {
        ad.status = 'Clean';
        ad.reason = null;
      }
      lastSpots[adnumber] = adLocs.last;

      ad.speeds = [];
      adLocs.forEach((lc) {
        ad.speeds.add(lc.speed);
      });
      print("COMPLETEE FOR $adnumber, LAST SPOTS : $lastSpots");
      return ad;
    } else {
      ad.up01 = null;
      ad.up12 = null;
      ad.up23 = null;
      ad.up34 = null;
      ad.up4a = null;
      ad.reason = null;
      ad.topAcceleration = null;
      ad.importantAccelerations = null;
      ad.averageSpeed = null;
      ad.adnumber = adnumber;
      List<String> adname = adLocs[0].name.split('#*#');
      ad.adbreak = int.parse(adname[3]);
      ad.adname = adname[5];
      ad.sequence = int.parse(adname[4]);
      ad.averageDownwardAcc = null;
      ad.score = null;
      ad.enterQuarterRange = null;
      ad.median = null;
      ad.averageUpwardAcc = null;
      ad.status = 'N/A';
      ad.speeds = [];
      return ad;
    }
  }
}

class Acceleration {
  double u;
  double time;
  double value;
  Acceleration({this.value, this.u, this.time});
  static Acceleration generateAcc(LocationData u, LocationData v) {
    return Acceleration(
        value: v.speed - u.speed,
        u: u.speed,
        time: (v.timestamp.millisecondsSinceEpoch -
                u.timestamp.millisecondsSinceEpoch) /
            1000);
  }

  static Acceleration formatedAcceleration(Acceleration p) {
    p.value = double.parse(p.value.toStringAsFixed(3));
    return p;
  }

  @override
  String toString() {
    if (this.value == null) {
      return "-";
    } else {
      return "(${double.parse(this.value.toStringAsFixed(3))}::${double.parse(this.u.toStringAsFixed(3))}::${double.parse(this.time.toStringAsFixed(3))})";
    }
  }
}

class PausedStat {
  int ad;
  int pnum;
  int duration;
  DateTime start;
  DateTime end;
  PausedStat({this.pnum, this.ad, this.start, this.end}) {
    if (this.end == null) {
      this.duration = null;
    } else {
      this.duration =
          (end.millisecondsSinceEpoch - start.millisecondsSinceEpoch) ~/ 1000;
    }
  }

  static Future<bool> savePausePlay(String pp) async {
    final prefs = await AppMain.mainPrefs;
    List<String> progresstillnow = prefs.getStringList('paused_locations');
    if (progresstillnow == null) {
      progresstillnow = [];
    }
    progresstillnow.add(pp);
    if (await prefs.setStringList("paused_locations", progresstillnow)) {
      print("PAUSED LOCATION $pp");
      return true;
    } else {
      return false;
    }
  }

  static PausedStat fromData(List<String> stringPausedStat) {
    print("PAUSED LOCATION :  $stringPausedStat");
    if (stringPausedStat.length == 2) {
      List<String> paused = stringPausedStat[0].split('--');
      List<String> played = stringPausedStat[1].split('--');
      if (paused.length == 3 && played.length == 3) {
        if (paused[0] == played[0] && paused[1] == played[1]) {
          return PausedStat(
              ad: int.parse(paused[0]),
              pnum: int.parse(paused[1]),
              start: DateTime.parse(paused[2]),
              end: DateTime.parse(played[2]));
        } else {
          return PausedStat(
              ad: int.parse(paused[0]),
              pnum: int.parse(paused[1]),
              start: DateTime.parse(paused[2]),
              end: null);
        }
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  static Future<Map<int, List<PausedStat>>> generatePausedStats() async {
    Map<int, List<PausedStat>> pausedStats = {};
    final prefs = await AppMain.mainPrefs;
    List<String> pausedLocations = prefs.getStringList('paused_locations');
    print("RETREIVED PAUSED LOCATION $pausedLocations");
    try {
      if (pausedLocations != null) {
        if (pausedLocations.length == 1) {
          // PausedStat single = PausedStat.fromData([pausedLocations[0]]);
          // pausedStats[single.ad] = [single];
        } else {
          for (int i = 1; i < pausedLocations.length; i++) {
            PausedStat couple = PausedStat.fromData(
                [pausedLocations[i - 1], pausedLocations[i]]);
            if (pausedStats[couple.ad] != null) {
              pausedStats[couple.ad].add(couple);
            } else {
              pausedStats[couple.ad] = [couple];
            }
          }
        }
      }
      return pausedStats;
    } catch (e) {
      print("PAUSED LOCATION $e");
      return null;
    }
  }
}
