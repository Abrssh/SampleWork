import 'dart:async';

import 'package:audio_record/Models/adAudio.dart';
import 'package:audio_record/Service/cloudStorageServ.dart';
import 'package:audio_record/Service/databaseServ.dart';
import 'package:audio_record/Shared/loading.dart';
import 'package:flutter/material.dart';

class AdAudioFiles extends StatefulWidget {
  final String systemAccountId, driverID;
  final List<String> mainRoutes;
  AdAudioFiles({this.systemAccountId, this.mainRoutes, this.driverID});
  @override
  _AdAudioFilesState createState() => _AdAudioFilesState();
}

class _AdAudioFilesState extends State<AdAudioFiles> {
  List<AdAudio> adAudios = [];
  bool loaded = false, allDocRetrived = false, downloadAllPressed = false;
  Timer timer;
  @override
  void initState() {
    DatabaseService()
        .getAdDocs(
            widget.systemAccountId, widget.mainRoutes, false, widget.driverID)
        .then((value) async {
      if (mounted) {
        adAudios = value;
        for (var item in value) {
          await item.getStandardAudio(item.uniqueName);
        }
        loaded = true;
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    final deviceHeight = deviceSize.height;
    final deviceWidth = deviceSize.width;
    return Scaffold(
      appBar: AppBar(
        title: Text("Ads"),
        centerTitle: true,
        actions: [
          IconButton(
              icon: Icon(Icons.download_sharp),
              onPressed: (loaded && !downloadAllPressed)
                  ? () async {
                      for (var item in adAudios) {
                        if (!item.downloaded) {
                          item.downloading = true;
                        }
                      }
                      setState(() {
                        downloadAllPressed = true;
                      });
                      for (var item in adAudios) {
                        if (!item.downloaded) {
                          bool result = await CloudStorageService()
                              .downloadAudio(item.audioUrl, item.uniqueName);

                          if (result) {
                            await item.getStandardAudio(item.uniqueName);
                            setState(() {});
                          }
                        }
                      }
                    }
                  : null),
          IconButton(
              icon: Icon(Icons.all_inclusive),
              onPressed: allDocRetrived
                  ? null
                  : () {
                      DatabaseService()
                          .getAdDocs(widget.systemAccountId, widget.mainRoutes,
                              true, widget.driverID)
                          .then((value) async {
                        // print("Val: " + value.length.toString());
                        setState(() {
                          loaded = false;
                        });
                        adAudios = value;
                        allDocRetrived = true;
                        for (var item in value) {
                          await item.getStandardAudio(item.uniqueName);
                        }
                        loaded = true;
                        setState(() {});
                      });
                    }),
          IconButton(
              icon: Icon(Icons.replay_outlined),
              onPressed: () async {
                for (var item in adAudios) {
                  await item.getStandardAudio(item.uniqueName);
                }
              })
        ],
      ),
      body: loaded
          ? SingleChildScrollView(
              child: Container(
                height: deviceHeight * 0.87,
                child: Column(
                  children: [
                    Expanded(
                        child: ListView.builder(
                      itemCount: adAudios.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Card(
                            elevation: 5,
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    adAudios[index].name.length < 22
                                        ? adAudios[index].name
                                        : adAudios[index].name.substring(0, 22),
                                    style:
                                        TextStyle(fontSize: deviceWidth * 0.05),
                                  ),
                                  adAudios[index].downloading
                                      ? adAudios[index].downloaded
                                          ? adAudios[index].processed
                                              ? Container(
                                                  height: deviceHeight * 0.06,
                                                  child: Center(
                                                    child: Text(
                                                      "PROCCESSED",
                                                      style: TextStyle(
                                                          fontSize:
                                                              deviceWidth *
                                                                  0.05),
                                                    ),
                                                  ))
                                              : Container(
                                                  height: deviceHeight * 0.06,
                                                  child: Center(
                                                    child: Text(
                                                      "Unproccessed",
                                                      style: TextStyle(
                                                          fontSize:
                                                              deviceWidth *
                                                                  0.05),
                                                    ),
                                                  ))
                                          : Container(
                                              height: deviceHeight * 0.06,
                                              child: Center(
                                                child: Text(
                                                  "Downloading...",
                                                  style: TextStyle(
                                                      fontSize:
                                                          deviceWidth * 0.05),
                                                ),
                                              ))
                                      : adAudios[index].downloaded
                                          ? adAudios[index].processed
                                              ? Container(
                                                  height: deviceHeight * 0.06,
                                                  child: Center(
                                                    child: Text(
                                                      "PROCCESSED",
                                                      style: TextStyle(
                                                          fontSize:
                                                              deviceWidth *
                                                                  0.05),
                                                    ),
                                                  ))
                                              : Container(
                                                  height: deviceHeight * 0.06,
                                                  child: Center(
                                                    child: Text(
                                                      "Unproccessed",
                                                      style: TextStyle(
                                                          fontSize:
                                                              deviceWidth *
                                                                  0.05),
                                                    ),
                                                  ))
                                          : ElevatedButton.icon(
                                              onPressed: adAudios[index]
                                                      .downloading
                                                  ? null
                                                  : () async {
                                                      setState(() {
                                                        adAudios[index]
                                                            .downloading = true;
                                                      });
                                                      bool result =
                                                          await CloudStorageService()
                                                              .downloadAudio(
                                                                  adAudios[
                                                                          index]
                                                                      .audioUrl,
                                                                  adAudios[
                                                                          index]
                                                                      .uniqueName);

                                                      if (result) {
                                                        await adAudios[index]
                                                            .getStandardAudio(
                                                                adAudios[index]
                                                                    .uniqueName);
                                                        setState(() {});
                                                      }
                                                    },
                                              icon: Icon(Icons.file_download),
                                              label: Text("Download"))
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ))
                  ],
                ),
              ),
            )
          : Center(
              child: Loading(),
            ),
    );
  }
}
