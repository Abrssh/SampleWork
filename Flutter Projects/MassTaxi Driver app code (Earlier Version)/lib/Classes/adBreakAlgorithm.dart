import 'package:audio_record/Models/adAudio.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';

class AdCard {
  final String name;
  final String hash, uniqueName, tvAdId;
  final bool silent, loud, preProcessed, warning;
  bool guaranteed = false;
  int songIndex = -1;
  // used for spotsLeftLength function
  int played = 0;
  bool checked = false, disabled = false;
  //
  final double seir;
  // driver payment and system cut transaction IDs
  List<String> dpTransIDs = [], scTransIDs = [];
  // List<String> cm, ts, sp;
  // DateTime startDate, endDate, createdDate;
  // Map<String, List<dynamic>> listOfFrequency;
  // double adCardBalance;
  final int length, frequencyPerRoute, volumeDecrease;
  final double profit;

  AdCard(
      {this.name,
      this.hash,
      this.uniqueName,
      // this.cm,
      // this.ts,
      // this.sp,
      // this.startDate,
      // this.createdDate,
      // this.endDate,
      // this.listOfFrequency,
      this.length,
      this.profit,
      this.loud,
      this.preProcessed,
      this.silent,
      this.seir,
      this.tvAdId,
      this.volumeDecrease,
      this.warning,
      // this.adCardBalance,
      this.frequencyPerRoute});
}

class AdCompilation {
  String name;
  Map<String, double> listOfFrequency; // number[frequency,profitforAdbreak1,
  //profitforAdbreak2,profitforAdbreak3]
  List<int> totalLength;
  List<AdCard> listOfCard;
  DateTime startDate, endDate;
  int timeScore;
  List<String> cm, ts, sp;

  AdCompilation(
      {this.name,
      this.cm,
      this.ts,
      this.sp,
      this.startDate,
      this.endDate,
      this.timeScore,
      this.listOfCard,
      this.listOfFrequency,
      this.totalLength});
}

class CompilationForServe {
  final List<List<AdCard>> adbreakAdCards;
  final double pricePerSlot;
  final int adBreakNum, bufferLength;
  int totalAdLength = 0;
  double availableprofit = 0;
  final double lemz, hemz, pathEfficiency;
  final int pathEfficiencyRange, passengerSize, pathMaximumWaitTime;
  final String cmID, tsID, spID;
  // indicates number of missing ad cards
  // that was retrieved for the route
  // that the audio files dont exist on the
  // driver phone so this will prompt driver
  // to download or get the audio file from
  // other drivers/providers to increase their
  // profit and efficiency in retrieving ads
  // (because if you have a lot of missing ad
  // cards your data cost will increase and
  // the retrival process will be slower)
  int missingAds = 0;
  final String setup, pathName, tvID, driverID, systemAccountID, pathID;
  String routeID = "";
  final bool badSetup;
  final double calibrationValue;
  // final AdCompilation compilation;

  CompilationForServe(
      {this.adbreakAdCards,
      this.adBreakNum,
      this.totalAdLength,
      this.availableprofit,
      this.pricePerSlot,
      this.bufferLength,
      this.hemz,
      this.lemz,
      this.setup,
      this.pathName,
      this.pathID,
      this.badSetup,
      // this.compilation,
      this.cmID,
      this.tsID,
      this.spID,
      this.tvID,
      this.driverID,
      this.systemAccountID,
      this.calibrationValue,
      this.passengerSize,
      this.pathMaximumWaitTime,
      this.pathEfficiency,
      this.pathEfficiencyRange});
}

class AudioCheckData {
  final bool hashFailed; // final bool downloadAds;
  final List<AdCard> adCards;
  AudioCheckData({this.hashFailed, this.adCards});
}

class CompilationData {
  final int spotsLeft;
  final AdCompilation adCompilation;
  final bool remove;

  CompilationData({this.spotsLeft, this.adCompilation, this.remove});
}

Map<int, List<String>> adBreakAssignForDriver(
    AdCompilation compilation, int maximumLengthForOneAdbreak, bool remove) {
  if (remove) {
    for (var i = 0; i < compilation.listOfCard.length; i++) {
      if (compilation.listOfCard[i].disabled) {
        // print("Ad remov: " + compilation.listOfCard[i].name);
        compilation.listOfCard.removeAt(i);
        i--;
      }
    }
  }
  int tl1 = 0, tl2 = 0, tl3 = 0;
  int maa1 = 1 * maximumLengthForOneAdbreak;
  bool abf1 = false, abf2 = false, abf3 = false;
  bool jump1 = false, jump2 = false, skip = false;
  Map<int, List<String>> adBreakAdcards = new Map();
  List<String> firstAdCards = [], secondAdCards = [], thirdAdCards = [];
  for (int i = 0; i < compilation.listOfCard.length; i++) {
    if (compilation.listOfCard[i].frequencyPerRoute >= 1 && !abf1) {
      if (tl1 < maa1) {
        var remaining1 = maa1 - tl1;
        if (compilation.listOfCard[i].length <= remaining1) {
          tl1 += compilation.listOfCard[i].length;
          firstAdCards.add(compilation.listOfCard[i].name);
        } else {
          jump1 = true;
          if (compilation.listOfCard[i].frequencyPerRoute == 2) {
            skip = true;
          }
        }
      } else if (tl1 == maa1) {
        abf1 = true;
      }
    }
    if ((compilation.listOfCard[i].frequencyPerRoute >= 2 && !abf2) ||
        (compilation.listOfCard[i].frequencyPerRoute == 1 && abf1 && !abf2) ||
        (jump1 && !abf2)) {
      if (jump1) {
        jump1 = false;
      }
      if (tl2 < maa1) {
        var remaining2 = maa1 - tl2;
        if (compilation.listOfCard[i].length <= remaining2) {
          tl2 += compilation.listOfCard[i].length;
          secondAdCards.add(compilation.listOfCard[i].name);
        } else {
          jump2 = true;
        }
      } else if (tl2 == maa1) {
        abf2 = true;
      }
    }
    if ((compilation.listOfCard[i].frequencyPerRoute == 3 && !abf3) ||
        (compilation.listOfCard[i].frequencyPerRoute == 2 &&
            (abf1 || skip) &&
            !abf3) ||
        (abf2 && !abf3) ||
        (jump2 && !abf3) ||
        (jump1 && !abf3)) {
      if (jump2) {
        jump2 = false;
      }
      if (jump1) {
        jump1 = false;
      }
      if (skip) {
        skip = false;
      }
      if (tl3 < maa1) {
        var remaining3 = maa1 - tl3;
        if (compilation.listOfCard[i].length <= remaining3) {
          tl3 += compilation.listOfCard[i].length;
          thirdAdCards.add(compilation.listOfCard[i].name);
        }
      } else if (tl3 == maa1) {
        abf3 = true;
      }
    }
    if (jump1) {
      jump1 = false;
    }
    if (jump2) {
      jump2 = false;
    }
  }
  adBreakAdcards[0] = firstAdCards;
  adBreakAdcards[1] = secondAdCards;
  adBreakAdcards[2] = thirdAdCards;
  return adBreakAdcards;
}

CompilationData spotsLeftLength(
    int maximumLengthPerAdbreak,
    int adBreakPerRoute,
    Map<int, List<String>> adBreakAdcards,
    AdCompilation compilation) {
  // print("Compilation leng: " + compilation.listOfCard.length.toString());
  int preProcessedAds = 0, silentAds = 0;
  for (var item in compilation.listOfCard) {
    // to reset gurantee,played,checked and disabled everytime
    // this function runs
    item.guaranteed = false;
    item.played = 0;
    item.checked = false;
    // item.disabled = true;
  }
  int pureLength = 0;
  adBreakAdcards.forEach((key, value) {
    value.forEach((element) {
      for (var item in compilation.listOfCard) {
        if (item.name == element) {
          if (key < adBreakPerRoute) {
            item.played++;
            if (item.preProcessed && !item.silent) {
              preProcessedAds += item.length;
            } else if (item.preProcessed && item.silent) {
              silentAds += item.length;
            }
            pureLength += item.length;
          }
          item.disabled = false;
          break;
        }
      }
    });
  });
  bool remove = false;
  // print("PureLeng: " +
  //     pureLength.toString() +
  //     " spotAvail: " +
  //     (maximumLengthPerAdbreak * adBreakPerRoute).toString());
  if (pureLength >= maximumLengthPerAdbreak * adBreakPerRoute) {
    remove = true;
  }
  int guaranteeSpot = preProcessedAds ~/ 2;
  int unprocessedGuarantee =
      guaranteeSpot >= silentAds ? guaranteeSpot - silentAds : -1;
  // print("PreProcessed and Not silent: " +
  //     preProcessedAds.toString() +
  //     " Silent: " +
  //     silentAds.toString());
  // print("Guarantee Spot: " +
  //     guaranteeSpot.toString() +
  //     " Unprocessed Guarantee: " +
  //     unprocessedGuarantee.toString());
  List<int> spotsOccupied = [];
  adBreakAdcards.forEach((key, value) {
    int spotOccupied = 0;
    value.forEach((element) {
      for (var item in compilation.listOfCard) {
        if (item.name == element) {
          if (unprocessedGuarantee < 0) {
            if (item.preProcessed && item.silent && !item.checked) {
              // less strict version (doesnt require every play of the
              // Ad to be guranteed by two processed Ad/Ads play)
              // if (guaranteeSpot >= item.length) {
              if (guaranteeSpot >= (item.length * item.played)) {
                guaranteeSpot -= item.length * item.played;
                // less strict version
                // guaranteeSpot -= item.length;
                spotOccupied += item.length;
                item.guaranteed = true;
                item.checked = true;
              } else {
                item.disabled = true;
              }
            }
            if (!item.disabled) {
              spotOccupied += item.length;
            }
          } else {
            if (!item.preProcessed &&
                unprocessedGuarantee >= (item.length * item.played) &&
                !item.checked) {
              item.guaranteed = true;
              item.checked = true;
              unprocessedGuarantee -= item.length * item.played;
            } else if (item.preProcessed && item.silent) {
              item.guaranteed = true;
            }
            spotOccupied += item.length;
          }
          break;
        }
      }
    });
    spotsOccupied.add(spotOccupied);
  });

  int spotsLeft = 0;
  for (var i = 0; i < adBreakPerRoute; i++) {
    if (maximumLengthPerAdbreak > spotsOccupied[i]) {
      int freeSpot = maximumLengthPerAdbreak - spotsOccupied[i];
      spotsLeft += freeSpot;
      // print("I: " + i.toString() + " Free spot: " + freeSpot.toString());
    }
  }
  // print(
  //     "Spots left: " + spotsLeft.toString() + " remove: " + remove.toString());
  return CompilationData(
      spotsLeft: spotsLeft, adCompilation: compilation, remove: remove);
}

CompilationForServe returnCompForServe(
    Map<int, List<String>> adBreakAdCards,
    AdCompilation compilation,
    int pathAdBreakNum,
    int bufferLength,
    int missingAds,
    String cmID,
    String tsID,
    String spID,
    double lemz,
    double hemz,
    String tvID,
    String driverID,
    String systemAccountID,
    double pricePerSlot,
    String pathName,
    String pathID,
    bool badSetup,
    double calibrationValue,
    double pathEffic,
    int pathEfficRang,
    int pathMaximumWaitTime,
    int passengerSize) {
  List<List<AdCard>> adBreakCards = [];
  double profit = 0;
  int adBreakNum = 0;
  int totalAdLength = 0;
  // print("Compleng: " + compilation.listOfCard.length.toString());
  // print("Compleng2: " + adBreakAdCards.length.toString());
  adBreakAdCards.forEach((key, value) {
    List<AdCard> adCards = [];
    int spotOccupied = 0;
    if (key < pathAdBreakNum) {
      value.forEach((element) {
        for (var item in compilation.listOfCard) {
          if (item.name == element) {
            if (!item.disabled) {
              adCards.add(item);
              profit += item.profit;
              spotOccupied += item.length;
              // print("name: " + item.name + " " + item.profit.toString());
              // print("name: " +
              //     item.name +
              //     " Length: " +
              //     item.length.toString() +
              //     " PreProcessed: " +
              //     item.preProcessed.toString() +
              //     " Silent: " +
              //     item.silent.toString() +
              //     " Guaranteed: " +
              //     item.guaranteed.toString());
            }
            break;
          }
        }
      });
    }
    totalAdLength += spotOccupied;
    if (spotOccupied > 0) {
      adBreakNum++;
    }
    adBreakCards.add(adCards);
  });
  if (adBreakNum > pathAdBreakNum) {
    adBreakNum = pathAdBreakNum;
  }
  // print("Ad brake num: " + adBreakNum.toString());
  CompilationForServe compilationForServe = new CompilationForServe(
      adbreakAdCards: adBreakCards,
      adBreakNum: adBreakNum,
      lemz: lemz,
      hemz: hemz,
      cmID: cmID,
      tsID: tsID,
      spID: spID,
      setup: cmID + "-" + tsID + "-" + spID,
      pathName: pathName,
      pathID: pathID,
      badSetup: badSetup,
      tvID: tvID,
      driverID: driverID,
      systemAccountID: systemAccountID,
      calibrationValue: calibrationValue,
      // compilation: compilation,
      pathEfficiency: pathEffic,
      pathEfficiencyRange: pathEfficRang,
      pathMaximumWaitTime: pathMaximumWaitTime,
      passengerSize: passengerSize,
      pricePerSlot: pricePerSlot,
      totalAdLength: totalAdLength,
      availableprofit: profit,
      bufferLength: bufferLength);
  compilationForServe.missingAds = missingAds;
  return compilationForServe;
}

Future<AudioCheckData> audioCheck(List<AdCard> adCards) async {
  List<SongInfo> songs;
  FlutterAudioQuery audioQuery = FlutterAudioQuery();
  AdAudio adAudio = new AdAudio();
  songs = await audioQuery.getSongs();
  songs.sort((a, b) => a.displayName.compareTo(b.displayName));
  // print("First : " + songs[0].displayName + " " + songs[0].title);
  bool hashFailed = false;

  for (var i = 0; i < songs.length; i++) {
    for (var item in adCards) {
      if (item.uniqueName == songs[i].title) {
        // print("Ad name: " +
        //     item.uniqueName +
        //     " => " +
        //     songs[i].title +
        //     " ind: " +
        //     i.toString());
        item.songIndex = i;
        String hashValue = await adAudio.calculateMD5(songs[i].filePath);
        // since dagims method can assign the hash in lower or upper case
        // we capitalize both of them so we can be sure the comparison
        // is case insensitive
        String capitalizedHashValue = hashValue.toUpperCase();
        String capitalizedHash = item.hash.toUpperCase();
        // print("Hash check " + capitalizedHash + " " + capitalizedHashValue);
        if (capitalizedHash != capitalizedHashValue) {
          hashFailed = true;
        }
        break;
      }
    }
    if (hashFailed) {
      break;
    }
  }
  // for (var i = 0; i < adCards.length; i++) {
  //   if (adCards[i].songIndex == -1) {
  //     downloadAds = true;
  //     adCards.removeAt(i);
  //     i--;
  //   }
  // }
  return AudioCheckData(hashFailed: hashFailed, adCards: adCards);
}
