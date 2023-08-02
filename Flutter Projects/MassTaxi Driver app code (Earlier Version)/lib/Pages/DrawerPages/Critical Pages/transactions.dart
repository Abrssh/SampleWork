import 'package:audio_record/Models/transaction.dart';
import 'package:audio_record/Service/databaseServ.dart';
import 'package:audio_record/Shared/loading.dart';
import 'package:flutter/material.dart';

class Transactions extends StatefulWidget {
  final double balanceIntheSystem, totalProfit;
  final String driverDocID;
  Transactions({this.balanceIntheSystem, this.totalProfit, this.driverDocID});
  @override
  _TransactionsState createState() => _TransactionsState();
}

class _TransactionsState extends State<Transactions> {
  bool loaded = false;
  List<TransactionModel> transactions = [];
  @override
  void initState() {
    DatabaseService().getTransactions(widget.driverDocID).then((value) {
      setState(() {
        transactions = value;
        loaded = true;
      });
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
          title: Row(
            children: [
              SizedBox(
                width: deviceWidth * 0.15,
              ),
              Text("Transactions")
            ],
          ),
        ),
        body: Column(
          children: [
            Container(
              color: Colors.blue[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      SizedBox(
                        height: deviceHeight * 0.015,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total Paid Amount:",
                            style: TextStyle(
                                fontSize: deviceWidth * 0.05,
                                fontWeight: FontWeight.w300),
                          ),
                          SizedBox(
                            width: deviceWidth * 0.01,
                          ),
                          Text(
                            widget.totalProfit < 10000000
                                ? widget.totalProfit.toString()
                                : widget.totalProfit.toStringAsExponential(4),
                            style: TextStyle(
                                fontSize: deviceWidth * 0.05,
                                fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: deviceHeight * 0.01,
                      ),
                      Text(
                        "UnPaid Amount",
                        style: TextStyle(
                            fontSize: deviceWidth * 0.09,
                            fontWeight: FontWeight.w300),
                      ),
                      SizedBox(
                        height: deviceHeight * 0.01,
                      ),
                      Text(
                        widget.balanceIntheSystem < 1000000000000
                            ? widget.balanceIntheSystem.toString()
                            : widget.balanceIntheSystem
                                .toStringAsExponential(8),
                        style: TextStyle(
                            fontSize: deviceWidth * 0.09,
                            fontWeight: FontWeight.w300),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              height: deviceHeight * 0.007,
            ),
            Text(
              "PAYMENTS",
              style: TextStyle(
                  fontSize: deviceWidth * 0.08, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: deviceHeight * 0.007,
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
              child: loaded
                  ? SingleChildScrollView(
                      child: Container(
                        height: deviceHeight * 0.645,
                        // color: Colors.amber,
                        child: Column(
                          children: [
                            Expanded(
                                child: ListView.builder(
                              itemCount: transactions.length,
                              itemBuilder: (context, index) {
                                double transactionAmount = double.parse(
                                    transactions[index].amount.toString());
                                return Card(
                                    elevation: 5,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Column(
                                            children: [
                                              Text(
                                                "Date",
                                                style: TextStyle(
                                                    fontSize:
                                                        deviceWidth * 0.07,
                                                    fontWeight:
                                                        FontWeight.w300),
                                              ),
                                              Text(
                                                transactions[index].date,
                                                style: TextStyle(
                                                    fontSize:
                                                        deviceWidth * 0.07,
                                                    fontWeight:
                                                        FontWeight.w300),
                                              )
                                            ],
                                          ),
                                          Column(
                                            children: [
                                              Text(
                                                "Amount",
                                                style: TextStyle(
                                                    fontSize:
                                                        deviceWidth * 0.07,
                                                    fontWeight:
                                                        FontWeight.w300),
                                              ),
                                              Text(
                                                transactionAmount < 100000000
                                                    ? transactionAmount
                                                        .toStringAsFixed(2)
                                                    : transactionAmount
                                                        .toStringAsExponential(
                                                            4),
                                                style: TextStyle(
                                                    fontSize:
                                                        deviceWidth * 0.07,
                                                    fontWeight:
                                                        FontWeight.w300),
                                              )
                                            ],
                                          ),
                                          // Row(
                                          //   children: [
                                          //     Text(
                                          //       "Type: ",
                                          //       style: TextStyle(
                                          //           fontSize: deviceWidth * 0.07,
                                          //           fontWeight: FontWeight.w300),
                                          //     ),
                                          //     Text(
                                          //       "External",
                                          //       style: TextStyle(
                                          //           fontSize: deviceWidth * 0.09,
                                          //           fontWeight: FontWeight.w400),
                                          //     )
                                          //   ],
                                          // )
                                        ],
                                      ),
                                    ));
                              },
                            ))
                          ],
                        ),
                      ),
                    )
                  : Center(
                      child: Loading(),
                    ),
            )
          ],
        ));
  }
}
