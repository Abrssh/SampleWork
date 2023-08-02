import 'package:csp_app/Classes/AD_data.dart';
import 'package:flutter/material.dart';

class AdStats extends StatelessWidget {
  final List<AdData> savedStats;

  const AdStats({Key key, this.savedStats}) : super(key: key);

  Widget ADSpot(AdData adspot) {
    return !adspot.silence
        ? Container(
            color: Colors.grey[200],
            padding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
            margin: EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text("AD-${adspot.adnumber}",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(
                      width: 20,
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Column(
                            children: [
                              Text("Average DB"),
                              Text(
                                adspot.recordedAverage.toStringAsFixed(3),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: 20,
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
            ))
        : SizedBox(
            height: 0,
          );
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
            itemCount: savedStats.length,
            itemBuilder: (BuildContext context, int index) {
              return ADSpot(savedStats[index]);
            },
          ),
        ),
      ),
    );
  }
}
