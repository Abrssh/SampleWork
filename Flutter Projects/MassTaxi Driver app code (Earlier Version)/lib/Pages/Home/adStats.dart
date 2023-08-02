import 'package:audio_record/Classes/final_stat.dart';
import 'package:audio_record/Classes/route_data.dart';
import 'package:flutter/material.dart';

class AdStats extends StatelessWidget {
  final FinalStat savedStats;

  const AdStats({Key key, this.savedStats}) : super(key: key);

  Widget ADSpot(RouteData adspot) {
    return Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
        margin: EdgeInsets.symmetric(vertical: 10),
        child: !adspot.silence
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                          "AD-${adspot.adnumber}\n${adspot.adname.length > 8 ? adspot.adname.substring(0, 7) : adspot.adname}",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Column(
                              children: [
                                Text("Rec"),
                                Text(
                                  adspot.recordedAverage.toInt().toString(),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Column(
                              children: [
                                Text("Pos"),
                                Text(
                                  adspot.positions != null
                                      ? adspot.positions.toString()
                                      : '-',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Column(
                              children: [
                                Text("Status"),
                                Text(
                                  adspot.status,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  adspot.reason != null
                      ? adspot.reason != ""
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text("Reason"),
                                Text(
                                  adspot.reason,
                                ),
                              ],
                            )
                          : SizedBox(
                              height: 0,
                            )
                      : SizedBox(
                          height: 0,
                        ),
                ],
              )
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(
                  children: [
                    Text(
                        "ST-${adspot.adnumber}\n${adspot.adname.length > 8 ? adspot.adname.substring(0, 7) : adspot.adname}",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Column(
                            children: [
                              Text("Rec"),
                              Text(
                                adspot.recordedAverage.toInt().toString(),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Column(
                            children: [
                              Text("Status"),
                              Text(
                                adspot.status,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                adspot.reason != null
                    ? adspot.reason != ""
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text("Reason"),
                              Text(
                                adspot.reason,
                              ),
                            ],
                          )
                        : SizedBox(
                            height: 0,
                          )
                    : SizedBox(
                        height: 0,
                      ),
              ]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("AD Stats"),
      ),
      body: SafeArea(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 15, vertical: 0),
          child: ListView.builder(
            itemCount: savedStats.components.length,
            itemBuilder: (BuildContext context, int index) {
              return ADSpot(savedStats.components[index]);
            },
          ),
        ),
      ),
    );
  }
}
