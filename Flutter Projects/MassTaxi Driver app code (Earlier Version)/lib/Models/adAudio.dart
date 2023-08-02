import 'dart:io';

import 'package:audio_record/Service/databaseServ.dart';
import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:crypto/crypto.dart' as cry;

class AdAudio {
  final String uniqueName, audioUrl, name, hash, adCardID, tvDocID;
  bool downloaded = false, downloading = false, processed = false;
  AdAudio(
      {this.uniqueName,
      this.audioUrl,
      this.name,
      this.hash,
      this.adCardID,
      this.tvDocID});

  FlutterAudioQuery audioQuery = FlutterAudioQuery();
  List<SongInfo> audios;

  Future getStandardAudio(String standardAudioName) async {
    Directory downDirectory = await DownloadsPathProvider.downloadsDirectory;
    List<String> urlSplit = audioUrl.split(".");
    String split2 = urlSplit[urlSplit.length - 1];
    List<String> fileFormat = split2.split("?");
    bool fileExist = await File(
            downDirectory.path + "/" + standardAudioName + "." + fileFormat[0])
        .exists();
    if (fileExist) {
      downloaded = true;
      // print("file");
    }
    audios = await audioQuery.searchSongs(query: standardAudioName);
    if (audios.isNotEmpty) {
      // for (var item in audios) {
      //   print("q" + standardAudioName + "items: " + item.filePath);
      // }
      if (audios[0].title == uniqueName) {
        downloaded = true;
        processed = true;
        bool tvAdExist = await DatabaseService().tvAdExist(adCardID, tvDocID);
        if (!tvAdExist) {
          DatabaseService()
              .createTvAd(adCardID, uniqueName, name, tvDocID, hash);
        }
        print("proces");
      }
      // print("audios: " + audios[0].filePath + "query: " + standardAudioName);
      // calculateMD5(audios[0].filePath).then((value) =>
      //     print("name: " + audios[0].duration + " pal val: " + value));
    }
    //  else {
    //   print("deny");
    // }
  }

  Future<String> calculateMD5(String filePath) async {
    final fileStream = File(filePath).openRead();
    final checksum = (await cry.md5.bind(fileStream).first).toString();
    return checksum;
  }
}
