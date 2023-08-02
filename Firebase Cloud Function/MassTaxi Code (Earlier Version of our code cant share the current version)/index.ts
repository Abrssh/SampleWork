import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { firestore } from "firebase-admin";

admin.initializeApp();

export const taskRunner = functions
  .runWith({ memory: "128MB", timeoutSeconds: 60 })
  .pubsub.schedule("30 * * * *")
  .onRun(async (context) => {
    let promises = [];
    const pr1 = admin
      .firestore()
      .collection("systemOwner")
      .doc("")
      // trigger schedulerTrigger Function
      .update({ schedulerTrigger: admin.firestore.FieldValue.increment(1) });
    promises.push(pr1);
    return await Promise.all(promises);
  });

class AdCard {
  name: string;
  length: number;
  list_of_frequency: Map<string, number[]>; // number[frequency,profit]
  availableSetups: string[];
  frequency_per_route: number;
  created_date: Date;
  start_date: Date;
  end_date: Date;
  cm: string[];
  ts: string[];
  sp: string[];
  adCardBalance: number;
  activeForDate: boolean = false;
  sda: number;
  // multiplier:number;
  // frequency per route bias adjusted sda
  // newSda:number;
  timeScore: number;
  aalds: Map<string, number>;
  tascpd: TASCPD[];
  astcpd: ASTCPD[];
  active: boolean;
  //
  completed: boolean = false;
  adCardSetupID = "";
  //NEW (For notebook cloud functions)
  serveAmount = 0;
  status = 0;
  readyToComplete = false;
  //

  constructor(
    name: string,
    length: number,
    frequency_per_route: number,
    cm: string[],
    ts: string[],
    sp: string[],
    adCardBalance: number,
    createdDate: Date,
    startDate: Date,
    endDate: Date
  ) {
    this.name = name;
    this.length = length;
    this.frequency_per_route = frequency_per_route;
    this.list_of_frequency = new Map<string, number[]>();
    this.availableSetups = [];
    this.cm = cm;
    this.ts = ts;
    this.sp = sp;
    this.adCardBalance = adCardBalance;
    this.created_date = createdDate;
    this.start_date = startDate;
    this.end_date = endDate;
    this.sda = 0;
    // this.multiplier=1;
    // this.newSda=0;
    this.timeScore = 0;
    this.aalds = new Map();
    this.tascpd = [];
    this.astcpd = [];
    this.active = false;
  }
}

class TASCPD {
  date: Date;
  value: number;

  constructor(date: Date, value: number) {
    this.date = date;
    this.value = value;
  }
}

class Route {
  cm: string;
  ts: string;
  sp: string;
  path: string;

  constructor(cm: string, ts: string, sp: string, path: string) {
    this.cm = cm;
    this.ts = ts;
    this.sp = sp;
    this.path = path;
  }
}

class RouteAverage {
  cm: string;
  ts: string;
  sp: string;
  totalServeCapacity: number;
  totalAmountOfRoute: number;
  totalAdbrake: number;
  averageAdBrake: number;
  rfstpd: number;
  scstpd: number;
  scstppd: number;
  // date:Date;

  constructor(cm: string, ts: string, sp: string, totalrouteAmount: number) {
    this.cm = cm;
    this.ts = ts;
    this.sp = sp;
    this.totalAdbrake = 0;
    this.averageAdBrake = 0;
    this.totalServeCapacity = 0;
    this.totalAmountOfRoute = totalrouteAmount;
    this.rfstpd = 0;
    this.scstpd = 0;
    this.scstppd = 0;
    // this.date=new Date();
  }
}

class ASTCPD {
  trip: string;
  date: Date;
  value: number;

  constructor(trip: string, date: Date, value: number) {
    this.trip = trip;
    this.date = date;
    this.value = value;
  }
}

class AdCardServe {
  adCardname: string;
  astcpd: ASTCPD[];
  tascpd: TASCPD[];
  startDate: Date;
  endDate: Date;
  sda: number;
  aalds: Map<string, number>;
  relativeScstppd: Map<string, number>;

  constructor(adCardname: string, startDate: Date, endDate: Date) {
    this.adCardname = adCardname;
    this.astcpd = [];
    this.tascpd = [];
    this.startDate = startDate;
    this.endDate = endDate;
    this.sda = 0;
    this.aalds = new Map();
    this.relativeScstppd = new Map();
  }
}

class Setup {
  cm: string;
  ts: string;
  sp: string;
  startDate: Date;
  endDate: Date;
  scstpd: number;
  averageAdBrake: number;
  servable: boolean;
  adCards: AdCard[];

  constructor(
    cm: string,
    ts: string,
    sp: string,
    startDate: Date,
    endDate: Date
  ) {
    this.cm = cm;
    this.ts = ts;
    this.sp = sp;
    this.startDate = startDate;
    this.endDate = endDate;
    this.servable = true;
    this.scstpd = 1;
    this.averageAdBrake = 1;
    this.adCards = [];
  }
}

class AdSchedule {
  date: Date;
  cm: string;
  ts: string;
  sp: string;
  aastd: number;
  aalst: number;

  constructor(
    date: Date,
    cm: string,
    ts: string,
    sp: string,
    aastd: number,
    aalst: number
  ) {
    this.date = date;
    this.cm = cm;
    this.ts = ts;
    this.sp = sp;
    this.aastd = aastd;
    this.aalst = aalst;
  }
}

class TAA {
  date: Date;
  setupTotals: SetupTotal[];

  constructor(date: Date) {
    this.date = date;
    this.setupTotals = [];
  }
}

class SetupTotal {
  trip: string;
  totalAdspot: number;

  constructor(trip: string, totalAdspot: number) {
    this.trip = trip;
    this.totalAdspot = totalAdspot;
  }
}

class TempServe {
  availableAdcard: AdCard;
  freqAmount: number;
  pricePerAdSpot;
  adCardIndex: number;
  timeScoreValue: number;
  otherSetupsTrafficJam: boolean;
  freq_per_route: number;
  adLength: number;

  constructor(adcard: AdCard) {
    this.availableAdcard = adcard;
    this.freq_per_route = adcard.frequency_per_route;
    this.freqAmount = 0;
    this.adCardIndex = 0;
    this.pricePerAdSpot = 0;
    this.timeScoreValue = adcard.timeScore;
    this.adLength = adcard.length;
    this.otherSetupsTrafficJam = false;
  }
}

class LeftOverSpots {
  shareLeft: number;
  amountLeft: number;
  constructor(shareLeft: number, amountLeft: number) {
    this.shareLeft = shareLeft;
    this.amountLeft = amountLeft;
  }
}

// code to be added to daily job
// check if every Active card end date is not
// earlier than current date if its disable that ad card
// and trigger activeAdCardChanges
// check if daily value (daily image) of a driver is not empty if the
// driver had at least one route and there is no image, meaning driver
// didn't upload an image then change the status of all routes of the
// day the driver took to false and make the status of the transaction,
// approved var in transaction table, to failed and trigger
// adCardServedCalculation.

// TESTED
// Notebook to dos
export const ths = functions.https // .runWith({ memory: "2GB", timeoutSeconds: 200 })
  .onRequest(async (request, response) => {
    try {
      const transactionReturn = await admin
        .firestore()
        .runTransaction(async (trans: admin.firestore.Transaction) => {
          let promises = [];
          let systemAccountID: string = "vDUgx0686C6tiSIQCTi8";
          let routeID = "JwytNIrEN0O6iy3TOj87";
          let routeSetup =
            "eGGTsDKqsHyaxVPnON8Q-8Zx0uUOmjvuf4SX1yWtA-PH3sALEFw6EBHO9FjDK5";
          let routeSp = "PH3sALEFw6EBHO9FjDK5";
          let dpTransIds = [];
          // let listOfAdCardVal: AdCard[] = [];
          let adCardsetups: AdCard[] = [];
          let retrivedAds: Map<string, number> = new Map<string, number>();
          let valueMap: Map<string, number> = new Map();
          // const pr9 = trans
          //   .get(
          //     firestore()
          //       .collection("controller")
          //       .where("systemAccountId", "==", systemAccountID)
          //   )
          //   .then(
          //     (contoller) =>
          //       (valueMap = contoller.docs[0].get("valueMap") as Map<
          //         string,
          //         number
          //       >)
          //   );
          // promises.push(pr9);
          const cmReadPromise = trans
            .get(
              firestore()
                .collection("carModel")
                .where("systemAccountId", "==", systemAccountID)
            )
            .then(async (querySnapshot) => {
              querySnapshot.docs.forEach((element) => {
                // the value is percent in variables below
                valueMap.set(element.id + "c", element.get("percentage"));
              });
            });
          promises.push(cmReadPromise);
          const tsReadPromise = trans
            .get(
              firestore()
                .collection("timeSlot")
                .where("systemAccountId", "==", systemAccountID)
            )
            .then(async (querySnapshot) => {
              querySnapshot.docs.forEach((element) => {
                // the value is percent in variables below
                valueMap.set(element.id + "t", element.get("percentage"));
              });
            });
          promises.push(tsReadPromise);
          // let superPath:Map<string,number>=new Map();// <string(super path),number(ad break)
          const spReadPromise = trans
            .get(
              firestore()
                .collection("superPath")
                .where("systemAccountId", "==", systemAccountID)
            )
            .then(async (querySnapshot) => {
              querySnapshot.docs.forEach((element) => {
                valueMap.set(element.id + "s", element.get("price"));
              });
            });
          promises.push(spReadPromise);

          const pr1 = await trans
            .get(
              firestore()
                .collection("tempTransaction")
                .where("routeID", "==", routeID)
                .where("specificType", "==", 2)
                .where("cp", "==", false)
                .where("status", "==", 0)
            )
            .then(async (querSnap) => {
              // console.log("tempTrans: " + querSnap.docs.length);
              for (const element in querSnap.docs) {
                if (
                  Object.prototype.hasOwnProperty.call(querSnap.docs, element)
                ) {
                  const dpTrans = querSnap.docs[element];
                  let serveAmountExist = false;
                  if (dpTrans.get(routeSetup) != null) {
                    // console.log("entered");
                    serveAmountExist = true;
                  }
                  if (!retrivedAds.has(dpTrans.get("sender"))) {
                    // console.log("Sen: " + dpTrans.get("sender"));
                    // the value is not relevant
                    retrivedAds.set(dpTrans.get("sender"), 0);
                    const pr2 = await trans
                      .get(
                        firestore()
                          .collection("AdCardTemp")
                          .doc(dpTrans.get("sender"))
                      )
                      .then(async (element) => {
                        if (element.exists) {
                          // console.log("AdTemp: " + element.id);
                          let createdDate = element
                            .get("created_date")
                            .toDate();
                          let endDate: Date = element.get("end_date").toDate();
                          let startDate: Date = element
                            .get("start_date")
                            .toDate();

                          const pr3 = trans
                            .get(
                              firestore()
                                .collection("adCardSetup")
                                .where("adCardID", "==", element.id)
                            )
                            .then((adSetups) => {
                              // console.log("AdsetB: " + adSetups.docs.length);
                              adSetups.docs.forEach((adsetup) => {
                                var cml = adsetup.get("cm");
                                var tsl = adsetup.get("ts");
                                var spl = adsetup.get("sp");
                                let cmsl: string[] = [];
                                let tssl: string[] = [];
                                let spsl: string[] = [];
                                let spExist = false;
                                cml.forEach((cmlElem) => {
                                  cmsl.push(cmlElem);
                                });
                                tsl.forEach((tslElem) => {
                                  tssl.push(tslElem);
                                });
                                spl.forEach((splElem) => {
                                  // console.log("spEl: " + splElem + " "+routeSp);
                                  if (routeSp == splElem) {
                                    spExist = true;
                                    // console.log("Sp: " + spExist);
                                  }
                                  spsl.push(splElem);
                                });
                                // Date intialized because they are expected in the constructor
                                let adCardsetupTemp = new AdCard(
                                  element.id,
                                  element.get("length"),
                                  element.get("frequency_per_route"),
                                  cmsl,
                                  tsl,
                                  spsl,
                                  element.get("adCardBalance"),
                                  createdDate,
                                  startDate,
                                  endDate
                                );
                                if (serveAmountExist && spExist) {
                                  adCardsetupTemp.serveAmount =
                                    dpTrans.get(routeSetup);
                                  // console.log(
                                  //   "serAm: " + adCardsetupTemp.serveAmount
                                  // );
                                }
                                adCardsetupTemp.adCardSetupID = adsetup.id;
                                // NEW
                                adCardsetupTemp.status = element.get("status");
                                //
                                adCardsetups.push(adCardsetupTemp);
                              });
                            });
                          promises.push(pr3);
                        }
                        await Promise.all(promises);
                      });
                    await Promise.all(promises);
                    promises.push(pr2);
                  } else if (serveAmountExist) {
                    let breakLoop = false;
                    for (let i = 0; i < adCardsetups.length; i++) {
                      if (adCardsetups[i].name == dpTrans.get("sender")) {
                        for (let j = 0; j < adCardsetups[i].sp.length; j++) {
                          if (adCardsetups[i].sp[j] == routeSp) {
                            adCardsetups[i].serveAmount =
                              dpTrans.get(routeSetup);
                            breakLoop = true;
                            break;
                          }
                        }
                      }
                      if (breakLoop) {
                        break;
                      }
                    }
                  }
                  dpTransIds.push(dpTrans.id);
                }
              }
              // console.log("Pr: " + promises.length);
              await Promise.all(promises);
            });
          promises.push(pr1);
          await Promise.all(promises);
          dpTransIds.forEach((dpTransID) => {
            const pr5 = trans.update(
              firestore().collection("tempTransaction").doc(dpTransID),
              {
                cp: true,
              }
            );
            promises.push(pr5);
          });
          // console.log("wpr: " + valueMap.size.toString());
          adCardsetups = frequencyAssigner(valueMap, adCardsetups);
          // console.log("AdSet: " + adCardsetups.length);
          adCardsetups.forEach((adcardSetTemp) => {
            let availSetupExist =
              adcardSetTemp.availableSetups.length > 0 &&
              adcardSetTemp.status == 1;
            let pr3;
            if (adcardSetTemp.serveAmount > 0) {
              pr3 = trans.update(
                firestore()
                  .collection("adCardSetup")
                  .doc(adcardSetTemp.adCardSetupID),
                {
                  adCardBalance: adcardSetTemp.adCardBalance,
                  activeForDate: availSetupExist,
                  availableSetups: adcardSetTemp.availableSetups,
                  [routeSetup]: admin.firestore.FieldValue.increment(
                    adcardSetTemp.serveAmount
                  ),
                }
              );
              const pr4 = trans.update(
                firestore().collection("AdCardTemp").doc(adcardSetTemp.name),
                {
                  totalServedAmount: admin.firestore.FieldValue.increment(
                    adcardSetTemp.serveAmount
                  ),
                  // NEW
                  totalNumberOfAdsServed:
                    admin.firestore.FieldValue.increment(1),
                  //
                }
              );
              promises.push(pr4);
            } else {
              pr3 = trans.update(
                firestore()
                  .collection("adCardSetup")
                  .doc(adcardSetTemp.adCardSetupID),
                {
                  adCardBalance: adcardSetTemp.adCardBalance,
                  activeForDate: availSetupExist,
                  availableSetups: adcardSetTemp.availableSetups,
                }
              );
            }
            promises.push(pr3);
          });
          return await Promise.all(promises);
        });
      response.send("Transaction: " + transactionReturn);
    } catch (error) {
      response.send("Error: " + error);
    }
  });

// TESTED
export const the = functions.https.onRequest(async (request, response) => {
  try {
    const transactionReturn = await admin
      .firestore()
      .runTransaction(async (trans: admin.firestore.Transaction) => {
        let promises = [];
        let systemAccountID: string = "vDUgx0686C6tiSIQCTi8";
        let routeID = "JwytNIrEN0O6iy3TOj87";
        let routeSetup =
          "eGGTsDKqsHyaxVPnON8Q-8Zx0uUOmjvuf4SX1yWtA-PH3sALEFw6EBHO9FjDK5";
        let routeSp = "PH3sALEFw6EBHO9FjDK5";

        class TempAdCard {
          id: string;
          balanceAdd: number = 0;
          systemDeduct: number = 0;
          driverDeduct: number = 0;
          deductServe: boolean = false;
          servedDeductAmount: number = 0;
          constructor(id: string) {
            this.id = id;
          }
        }
        let valueMap: Map<string, number> = new Map();
        // const pr9 = trans
        //   .get(
        //     firestore()
        //       .collection("controller")
        //       .where("systemAccountId", "==", systemAccountID)
        //   )
        //   .then(
        //     (contoller) =>
        //       (valueMap = contoller.docs[0].get("valueMap") as Map<
        //         string,
        //         number
        //       >)
        //   );
        // promises.push(pr9);
        const cmReadPromise = trans
          .get(
            firestore()
              .collection("carModel")
              .where("systemAccountId", "==", systemAccountID)
          )
          .then(async (querySnapshot) => {
            querySnapshot.docs.forEach((element) => {
              // the value is percent in variables below
              valueMap.set(element.id + "c", element.get("percentage"));
            });
          });
        promises.push(cmReadPromise);
        const tsReadPromise = trans
          .get(
            firestore()
              .collection("timeSlot")
              .where("systemAccountId", "==", systemAccountID)
          )
          .then(async (querySnapshot) => {
            querySnapshot.docs.forEach((element) => {
              // the value is percent in variables below
              valueMap.set(element.id + "t", element.get("percentage"));
            });
          });
        promises.push(tsReadPromise);
        // let superPath:Map<string,number>=new Map();// <string(super path),number(ad break)
        const spReadPromise = trans
          .get(
            firestore()
              .collection("superPath")
              .where("systemAccountId", "==", systemAccountID)
          )
          .then(async (querySnapshot) => {
            querySnapshot.docs.forEach((element) => {
              valueMap.set(element.id + "s", element.get("price"));
            });
          });
        promises.push(spReadPromise);
        let transIds = [];
        let tempAdCards: TempAdCard[] = [];
        const pr1 = trans
          .get(
            firestore()
              .collection("tempTransaction")
              .where("routeID", "==", routeID)
              .where("cp", "==", false)
              .where("status", "==", 3)
          )
          .then(async (querSnap) => {
            for (const key in querSnap.docs) {
              if (Object.prototype.hasOwnProperty.call(querSnap.docs, key)) {
                const trans = querSnap.docs[key];
                let adCardID = trans.get("sender");
                let index = 0;
                let exist = false;
                // console.log("trans: " + trans.id);
                transIds.push(trans.id);
                for (let i = 0; i < tempAdCards.length; i++) {
                  if (tempAdCards[i].id == adCardID) {
                    exist = true;
                    index = i;
                    break;
                  }
                }
                let deduct = false,
                  serveAmount = 0;
                if (trans.get(routeSetup) != null) {
                  // console.log("Ent");
                  deduct = true;
                  serveAmount = trans.get(routeSetup);
                }
                // console.log(
                //   "Ex: " + exist + " => " + adCardID + " sa " + serveAmount
                // );
                if (exist) {
                  tempAdCards[index].balanceAdd += trans.get("amount");
                  if (!tempAdCards[index].deductServe) {
                    tempAdCards[index].deductServe = deduct;
                    tempAdCards[index].servedDeductAmount = serveAmount;
                  }
                  if (trans.get("specificType") == 2) {
                    tempAdCards[index].driverDeduct += trans.get("amount");
                  } else {
                    tempAdCards[index].systemDeduct += trans.get("amount");
                  }
                } else {
                  let tempAdcard = new TempAdCard(trans.get("sender"));
                  tempAdcard.balanceAdd += trans.get("amount");
                  tempAdcard.deductServe = deduct;
                  tempAdcard.servedDeductAmount = serveAmount;
                  if (trans.get("specificType") == 2) {
                    tempAdcard.driverDeduct += trans.get("amount");
                  } else {
                    tempAdcard.systemDeduct += trans.get("amount");
                  }
                  tempAdCards.push(tempAdcard);
                }
              }
            }
            // await Promise.all(promises);
          });
        promises.push(pr1);
        let mainPaymentAccountID: string;
        const pr3 = trans
          .get(
            firestore()
              .collection("mainPaymentAccount")
              .where("systemAccountId", "==", systemAccountID)
              .limit(1)
          )
          .then((mainPayAcc) => (mainPaymentAccountID = mainPayAcc.docs[0].id));
        promises.push(pr3);
        await Promise.all(promises);
        for (let i = 0; i < tempAdCards.length; i++) {
          if (tempAdCards[i].deductServe == true) {
            const pr5 = trans
              .get(
                firestore()
                  .collection("tempTransaction")
                  .where("routeID", "==", routeID)
                  .where("sender", "==", tempAdCards[i].id)
                  .where("specificType", "==", 2)
                  .where("status", "==", 0)
              )
              .then((querSnap) => {
                tempAdCards[i].deductServe = querSnap.docs.length == 0;
                // console.log("tmDs: " + tempAdCards[i].deductServe);
              });
            promises.push(pr5);
          }
        }
        await Promise.all(promises);
        // console.log("TemAdCar: " + tempAdCards.length);
        let adCardSetups: AdCard[] = [];
        for (let i = 0; i < tempAdCards.length; i++) {
          const pr6 = admin
            .firestore()
            .collection("AdCardTemp")
            .doc(tempAdCards[i].id)
            .get()
            .then(async (element) => {
              let createdDate = element.get("created_date").toDate();
              let endDate: Date = element.get("end_date").toDate();
              let startDate: Date = element.get("start_date").toDate();

              const pr7 = admin
                .firestore()
                .collection("adCardSetup")
                .where("adCardID", "==", element.id)
                .get()
                .then((adSetups) => {
                  adSetups.docs.forEach((adsetup) => {
                    let spExist = false;
                    var cml = adsetup.get("cm");
                    var tsl = adsetup.get("ts");
                    var spl = adsetup.get("sp");
                    let cmsl: string[] = [];
                    let tssl: string[] = [];
                    let spsl: string[] = [];
                    cml.forEach((cmlElem) => {
                      cmsl.push(cmlElem);
                    });
                    tsl.forEach((tslElem) => {
                      tssl.push(tslElem);
                    });
                    spl.forEach((splElem) => {
                      if (routeSp == splElem) {
                        spExist = true;
                      }
                      spsl.push(splElem);
                    });
                    // Date intialized because they are expected in the constructor
                    let adCardsetupTemp = new AdCard(
                      element.id,
                      element.get("length"),
                      element.get("frequency_per_route"),
                      cmsl,
                      tsl,
                      spsl,
                      element.get("adCardBalance") + tempAdCards[i].balanceAdd,
                      createdDate,
                      startDate,
                      endDate
                    );
                    if (tempAdCards[i].deductServe && spExist) {
                      adCardsetupTemp.serveAmount =
                        tempAdCards[i].servedDeductAmount;
                    }
                    adCardsetupTemp.adCardSetupID = adsetup.id;
                    adCardsetupTemp.completed = element.get("completed");
                    adCardsetupTemp.status = element.get("status");
                    adCardSetups.push(adCardsetupTemp);
                  });
                });
              promises.push(pr7);
              // await Promise.all(promises);
            });
          await Promise.all(promises);
          promises.push(pr6);
        }
        await Promise.all(promises);
        transIds.forEach((transId) => {
          const pr7 = trans.update(
            firestore().collection("tempTransaction").doc(transId),
            {
              cp: true,
            }
          );
          promises.push(pr7);
        });
        tempAdCards.forEach((tempAdCard) => {
          let driverDeduct = 0 - tempAdCard.driverDeduct;
          let systemDeduct = 0 - tempAdCard.systemDeduct;
          // console.log(
          //   "DD: " +
          //     driverDeduct +
          //     " SD: " +
          //     systemDeduct +
          //     " tempAd: " +
          //     tempAdCards[i].id +
          //     " - " +
          //     tempAdCards[i].servedDeductAmount +
          //     " ded: " +
          //     tempAdCards[i].deductServe
          // );
          const pr4 = trans.update(
            firestore()
              .collection("mainPaymentAccount")
              .doc(mainPaymentAccountID),
            {
              businessBalance: admin.firestore.FieldValue.increment(
                tempAdCard.balanceAdd
              ),
              driverBalance: admin.firestore.FieldValue.increment(driverDeduct),
              ownedBalance: admin.firestore.FieldValue.increment(systemDeduct),
            }
          );
          promises.push(pr4);
        });
        adCardSetups = frequencyAssigner(valueMap, adCardSetups);
        // console.log(
        //   "Ad sets: " + adCardSetups.length + " promise leng: " + promises.length
        // );
        adCardSetups.forEach((adCardSetup) => {
          let activeForDate =
            adCardSetup.availableSetups.length > 0 &&
            // !adCardSetup.completed && // (Unnecessary since
            // ad card will be completed only at night and if
            // ad card is being served its not completed)
            adCardSetup.status == 1;
          if (adCardSetup.serveAmount > 0) {
            let serveAmountDeduct = 0 - adCardSetup.serveAmount;
            const pr8 = trans.update(
              firestore()
                .collection("adCardSetup")
                .doc(adCardSetup.adCardSetupID),
              {
                [routeSetup]:
                  admin.firestore.FieldValue.increment(serveAmountDeduct),
                activeForDate: activeForDate,
                availableSetups: adCardSetup.availableSetups,
                adCardBalance: adCardSetup.adCardBalance,
              }
            );
            promises.push(pr8);
            const pr9 = trans.update(
              firestore().collection("AdCardTemp").doc(adCardSetup.name),
              {
                totalServedAmount:
                  admin.firestore.FieldValue.increment(serveAmountDeduct),
                totalNumberOfAdsServed:
                  admin.firestore.FieldValue.increment(-1),
                adCardBalance: adCardSetup.adCardBalance,
              }
            );
            promises.push(pr9);
          } else {
            const pr8 = trans.update(
              firestore()
                .collection("adCardSetup")
                .doc(adCardSetup.adCardSetupID),
              {
                adCardBalance: adCardSetup.adCardBalance,
                activeForDate: activeForDate,
                availableSetups: adCardSetup.availableSetups,
              }
            );
            promises.push(pr8);
            const pr9 = trans.update(
              firestore().collection("AdCardTemp").doc(adCardSetup.name),
              {
                adCardBalance: adCardSetup.adCardBalance,
              }
            );
            promises.push(pr9);
          }
        });
        return await Promise.all(promises);
      });
    response.send("Transaction: " + transactionReturn);
  } catch (error) {
    response.send("Err: " + error);
  }
});

// TESTED
export const lateReportInitial = functions.https.onRequest(
  async (request, response) => {
    try {
      let promises = [];
      let systemAccountID = "vDUgx0686C6tiSIQCTi8",
        larid = "dummyID";
      let lrdocEx = false;
      let lrdoc = admin.firestore().collection("routeTest1").doc(larid);
      let routeChunk = 200;

      class TempRoute {
        routeID: string;
        startTime: Date;
        maxWaitTime: number;
        constructor(maxWaitTime: number, routeID: string, startTime: Date) {
          this.routeID = routeID;
          this.maxWaitTime = maxWaitTime;
          this.startTime = startTime;
        }
      }
      let tempRoutes: TempRoute[] = [];
      if (lrdocEx) {
        const pr2 = admin
          .firestore()
          .collection("routeTest1")
          .where("systemAccountId", "==", systemAccountID)
          .where("status", "==", 0)
          .orderBy(admin.firestore.FieldPath.documentId())
          .startAfter(lrdoc)
          .limit(routeChunk)
          .get()
          .then((routes) => {
            routes.docs.forEach((route) => {
              let startTimeStamp: admin.firestore.Timestamp =
                route.get("startTime");
              tempRoutes.push(
                new TempRoute(
                  route.get("maximumWaitTime"),
                  route.id,
                  startTimeStamp.toDate()
                )
              );
            });
          });
        promises.push(pr2);
      } else {
        // console.log("Entered");
        const pr2 = admin
          .firestore()
          .collection("routeTest1")
          .where("systemAccountId", "==", systemAccountID)
          .where("status", "==", 0)
          .orderBy(admin.firestore.FieldPath.documentId())
          .limit(routeChunk)
          .get()
          .then((routes) => {
            routes.docs.forEach((route) => {
              let startTimeStamp: admin.firestore.Timestamp =
                route.get("startTime");
              tempRoutes.push(
                new TempRoute(
                  route.get("maximumWaitTime"),
                  route.id,
                  startTimeStamp.toDate()
                )
              );
            });
          });
        promises.push(pr2);
      }
      await Promise.all(promises);
      let currentTime: Date = new Date();
      tempRoutes.forEach((element) => {
        let timeDiff = currentTime.getTime() - element.startTime.getTime();
        let waitTime = element.maxWaitTime * 60 * 1000;
        // console.log("TimeDiff: " + timeDiff + " waitTime: " + waitTime);
        if (timeDiff > waitTime) {
          const pr4 = admin
            .firestore()
            .collection("routeTest1")
            .doc(element.routeID)
            .update({
              // trigger late report function
              lr: admin.firestore.FieldValue.increment(1),
            });
          promises.push(pr4);
        }
      });
      await Promise.all(promises);
      if (routeChunk == tempRoutes.length) {
        // trigger lateReportInitial(this function) again
        // let lrid = tempRoutes[tempRoutes.length - 1].routeID;
      }
      let finalPromise = await Promise.all(promises);
      response.send("The result of the action is : " + finalPromise.length);
    } catch (error) {
      response.send("Err: " + error);
    }
  }
);

// TESTED
export const lateReport = functions.https.onRequest(
  async (request, response) => {
    try {
      let promises = [];
      let routeID = "xBHH5nS6ThdzxUcuLm2T";
      let weeklyRoutes = [0, 1];
      let totalRoutes = [0, 1];
      let pr1 = admin
        .firestore()
        .collection("routeTest1")
        .where("status", "==", 1)
        // .orderBy("startTime", "desc")
        .limit(1)
        .get()
        .then((route) => {
          if (!route.empty) {
            let tr = route.docs[0].get("totalRoutes");
            let wr = route.docs[0].get("weeklyRoutes");
            // console.log("tr " + tr[1] + " wr " + wr[1]);
            totalRoutes[0] += tr[0];
            totalRoutes[1] += tr[1];
            weeklyRoutes[0] += wr[0];
            weeklyRoutes[1] += wr[1];
          }
        });
      promises.push(pr1);
      await Promise.all(promises);
      let pr3 = admin
        .firestore()
        .collection("tempTransaction")
        .where("routeID", "==", routeID)
        .get()
        .then((transactions) => {
          transactions.docs.forEach((transction) => {
            const pr4 = admin
              .firestore()
              .collection("tempTransaction")
              .doc(transction.id)
              .update({
                cp: false,
                status: 3,
              });
            promises.push(pr4);
          });
        });
      promises.push(pr3);
      let pr2 = admin
        .firestore()
        .collection("routeTest1")
        .doc(routeID)
        .update({
          status: 1,
          weeklyRoutes: weeklyRoutes,
          totalRoutes: totalRoutes,
          profit: 0,
          imageStatus: 2,
          endTime: admin.firestore.Timestamp.now(),
          // trigger transaction handler end function
          the: admin.firestore.FieldValue.increment(1),
        });
      promises.push(pr2);
      let finalPromise = await Promise.all(promises);
      response.send("The result of the action is : " + finalPromise.length);
    } catch (error) {
      response.send("Err: " + error);
    }
  }
);

// TESTED
// should only be triggered if daily status becomes 1,3 or 4
export const thf = functions.https.onRequest(async (request, response) => {
  try {
    let promises = [];

    let driverID = "3C9pZWc9WvPhXRqMlB8p";
    let systemAccountID = "vDUgx0686C6tiSIQCTi8";
    let transIds: string[] = [],
      routeIds: string[] = [];
    let one_day = 24 * 60 * 60 * 1000;
    let thatDayProfit = 0,
      newDailyValue: [],
      daysSinceEpoch: number,
      removeIndex,
      checkFailed = false,
      alreadyProcessed = false,
      imageUrl = "";

    await admin.firestore().collection("driver").doc(driverID).update({
      finished: false,
    });

    let timeZoneName: string, timeZoneOffset: number;
    await admin
      .firestore()
      .collection("systemRequirementAccount")
      .doc(systemAccountID)
      .get()
      .then((sysReqAcc) => {
        timeZoneOffset = -sysReqAcc.get("timeZoneOffset");
        timeZoneName = sysReqAcc.get("timeZoneName");
      });

    let hours = Math.floor(timeZoneOffset / 60);
    let minutes = timeZoneOffset % 60;

    const pr1 = admin
      .firestore()
      .collection("driver")
      .doc(driverID)
      .get()
      .then(async (driver) => {
        let localPromise1 = [];
        let dailyValue: [] = driver.get("dailyValue");
        newDailyValue = dailyValue;
        for (let index = 0; index < dailyValue.length; index++) {
          const dailyMap = dailyValue[index] as Map<string, any>;
          // console.log(dailyMap["dailyStatus"]);
          // console.log(driver.data());
          if (
            dailyMap["dailyStatus"] == 1 ||
            dailyMap["dailyStatus"] == 3 ||
            dailyMap["dailyStatus"] == 4
          ) {
            if (dailyMap["dailyStatus"] != 1) {
              checkFailed = true;
            }
            imageUrl = dailyMap["imageUrl"];
            let dvdTimeStamp: admin.firestore.Timestamp = dailyMap["date"];
            let dailyValueDate = dvdTimeStamp.toDate();
            // console.log("Tz: " + timeZoneName + " " + hours + " " + minutes);

            dailyValueDate = convertTZ(dailyValueDate, timeZoneName);
            dailyValueDate.setUTCMonth(dailyValueDate.getMonth());
            dailyValueDate.setUTCDate(dailyValueDate.getDate());
            dailyValueDate.setUTCHours(hours, minutes, 0, 0);

            let nextDate = new Date(dailyValueDate.getTime() + one_day);
            console.log(
              "dailyValueDate: " + dailyValueDate + " NextDate: " + nextDate
            );

            const pr2 = admin
              .firestore()
              .collection("routeTest1")
              .where("driverID", "==", driverID)
              .where("imageStatus", "==", 0)
              .where(
                "startTime",
                ">=",
                admin.firestore.Timestamp.fromDate(dailyValueDate)
              )
              .where(
                "startTime",
                "<",
                admin.firestore.Timestamp.fromDate(nextDate)
              )
              .get()
              .then(async (routes) => {
                let localPromise2 = [];
                // console.log("routes: " + routes.docs.length);
                for (const key in routes.docs) {
                  if (Object.prototype.hasOwnProperty.call(routes.docs, key)) {
                    const route = routes.docs[key];
                    routeIds.push(route.id);
                    // console.log("Rid: " + route.id);
                    const pr3 = admin
                      .firestore()
                      .collection("tempTransaction")
                      .where("routeID", "==", route.id)
                      .get()
                      .then(async (transactions) => {
                        // console.log("Trans: " + transactions.docs.length);
                        transactions.forEach((transaction) => {
                          transIds.push(transaction.id);
                        });
                      });
                    localPromise2.push(pr3);
                    await Promise.all(localPromise2);
                  }
                }
              });
            localPromise1.push(pr2);
            await Promise.all(localPromise1);
            // daysSinceEpoch = Math.floor(dailyValueDate.getTime() / one_day);
            daysSinceEpoch = dailyValueDate.getTime() / one_day;
            console.log("deb: " + daysSinceEpoch);
            daysSinceEpoch *= 100;
            daysSinceEpoch = Math.floor(daysSinceEpoch);
            if (driver.get(daysSinceEpoch.toString()) != null) {
              thatDayProfit = driver.get(daysSinceEpoch.toString());
              // console.log("dea: " + daysSinceEpoch.toString());
            } else {
              alreadyProcessed = true;
            }
            removeIndex = index;
            break;
          }
        }
      });
    promises.push(pr1);
    await Promise.all(promises);
    if (newDailyValue.length > 1) {
      newDailyValue.splice(removeIndex, 1);
      if (imageUrl != "") {
        const bucket = admin.storage().bucket();
        let split: string[] = imageUrl.split("o/");
        let split1 = split[1].split("?");
        let path = split1[0];
        path = decodeURIComponent(path);
        const pr7 = bucket.file(path).delete();
        promises.push(pr7);
      }
    }
    let deductAmount = 0 - thatDayProfit;
    if (checkFailed) {
      thatDayProfit = 0;
    }
    console.log(
      "ThatDayProf: " +
        thatDayProfit +
        " Deduct: " +
        deductAmount +
        " RouteIds: " +
        routeIds.length +
        " " +
        transIds.length +
        " AlreadyProcessed: " +
        alreadyProcessed
    );
    console.log(routeIds);
    if (!alreadyProcessed) {
      const pr4 = admin
        .firestore()
        .collection("driver")
        .doc(driverID)
        .update({
          dailyValue: newDailyValue,
          balance: admin.firestore.FieldValue.increment(thatDayProfit),
          potentialBalance: admin.firestore.FieldValue.increment(deductAmount),
          totalProfit: admin.firestore.FieldValue.increment(thatDayProfit),
          [daysSinceEpoch.toString()]: admin.firestore.FieldValue.delete(),
        });
      promises.push(pr4);
    } else {
      const pr4 = admin.firestore().collection("driver").doc(driverID).update({
        dailyValue: newDailyValue,
      });
      promises.push(pr4);
    }

    transIds.forEach((trandId) => {
      if (checkFailed) {
        const pr5 = admin
          .firestore()
          .collection("tempTransaction")
          .doc(trandId)
          .update({
            cp: false,
            status: 3,
          });
        promises.push(pr5);
      } else {
        const pr5 = admin
          .firestore()
          .collection("tempTransaction")
          .doc(trandId)
          .update({
            status: 2,
          });
        promises.push(pr5);
      }
    });
    await Promise.all(promises);
    routeIds.forEach((routeId) => {
      if (checkFailed) {
        const pr6 = admin
          .firestore()
          .collection("routeTest1")
          .doc(routeId)
          .update({
            imageStatus: 2,
            the: admin.firestore.FieldValue.increment(1),
          });
        promises.push(pr6);
      } else {
        const pr6 = admin
          .firestore()
          .collection("routeTest1")
          .doc(routeId)
          .update({
            imageStatus: 1,
          });
        promises.push(pr6);
      }
    });
    const pr7 = admin.firestore().collection("driver").doc(driverID).update({
      finished: true,
    });
    promises.push(pr7);
    const finalPromise = await Promise.all(promises);
    response.send("The result of the action is : " + finalPromise.length);
  } catch (error) {
    response.send("Err: " + error);
  }
});

// TESTED
// needs to run at night before the day we are supposed to
// check for to know whether it can be served that day it
// should also be run after the end time has passed
export const dailyAdCardChecker = functions.https.onRequest(
  async (request, response) => {
    try {
      let promises = [];
      let systemAccountID: string = "vDUgx0686C6tiSIQCTi8",
        lastAdCardID = "dummyID";
      let adCardIds: string[] = [];
      let lastAdDocExist = false;
      let lastAdCardDoc = admin
        .firestore()
        .collection("AdCardTemp")
        .doc(lastAdCardID);
      let adCardChunk = 200;

      if (lastAdDocExist) {
        const readPromise = await admin
          .firestore()
          .collection("AdCardTemp")
          .where("systemAccountID", "==", systemAccountID)
          .where("completed", "==", false)
          .orderBy(admin.firestore.FieldPath.documentId())
          .startAfter(lastAdCardDoc)
          .limit(adCardChunk)
          .get()
          .then(async (querySnapshot) => {
            querySnapshot.docs.forEach(async (adCard) => {
              adCardIds.push(adCard.id);
            });
          });
        promises.push(readPromise);
      } else {
        const readPromise = await admin
          .firestore()
          .collection("AdCardTemp")
          .where("systemAccountID", "==", systemAccountID)
          .where("completed", "==", false)
          .orderBy(admin.firestore.FieldPath.documentId())
          .limit(adCardChunk)
          .get()
          .then(async (querySnapshot) => {
            querySnapshot.docs.forEach(async (adCard) => {
              adCardIds.push(adCard.id);
            });
          });
        promises.push(readPromise);
      }

      adCardIds.forEach((adCardID) => {
        const pr1 = admin
          .firestore()
          .collection("AdCardTemp")
          .doc(adCardID)
          .update({
            // trigger adCardCheck
            dac: admin.firestore.FieldValue.increment(1),
          });
        promises.push(pr1);
      });
      await Promise.all(promises);
      // trigger dailyAdCardChecker (this function) again
      if (adCardIds.length == adCardChunk) {
        // let ladCardID = adCardIds[adCardIds.length - 1];
      }
      const finalPromise = await Promise.all(promises);
      response.send("The result of the action is : " + finalPromise.length);
    } catch (error) {
      response.send("Err: " + error);
    }
  }
);

// TESTED
export const dailyDriverChecker = functions.https.onRequest(
  async (request, response) => {
    try {
      let promises = [];

      let systemAccountID = "vDUgx0686C6tiSIQCTi8",
        lastDriverID = "dummyID";
      let lastDriverDocExist = false;
      let lastDriverDoc = admin
        .firestore()
        .collection("driver")
        .doc(lastDriverID);

      // amount of Docs the cloud function can update
      // without timing out (intellectual guess)
      let driveChunk = 200;

      class TempDriver {
        driverID: string;
        tvID: string;
        routeID: string;
        dailyValues: any[];
        status: boolean;

        constructor(
          driverID: string,
          dailyValues: [],
          status: boolean,
          tvID: string,
          routeID: string
        ) {
          this.driverID = driverID;
          this.dailyValues = dailyValues;
          this.status = status;
          this.tvID = tvID;
          this.routeID = routeID;
        }
      }

      let timeZoneName = "",
        timeZoneOffset: number;
      let lwDateTimeStamp: admin.firestore.Timestamp;
      await admin
        .firestore()
        .collection("systemRequirementAccount")
        .doc(systemAccountID)
        .get()
        .then((systemAccount) => {
          lwDateTimeStamp = systemAccount.get("lwDate");
          timeZoneName = systemAccount.get("timeZoneName");
          timeZoneOffset = -systemAccount.get("timeZoneOffset");
        });

      let hours = Math.floor(timeZoneOffset / 60);
      let minutes = timeZoneOffset % 60;

      let one_day = 24 * 60 * 60 * 1000;
      let lwDate = lwDateTimeStamp.toDate();
      lwDate = convertTZ(lwDate, timeZoneName);
      lwDate.setUTCMonth(lwDate.getMonth());
      lwDate.setUTCDate(lwDate.getDate());
      lwDate.setUTCHours(hours, minutes, 0, 0);
      let currentDate: Date = new Date();
      currentDate = convertTZ(currentDate, timeZoneName);
      currentDate.setUTCMonth(currentDate.getMonth());
      currentDate.setUTCDate(currentDate.getDate());
      currentDate.setUTCHours(hours, minutes, 0, 0);
      // console.log("LwDate: " + lwDate + " cd: " + currentDate);
      let timeDiff = currentDate.getTime() - lwDate.getTime();
      timeDiff /= one_day;
      let tempDrivers: TempDriver[] = [];
      if (lastDriverDocExist) {
        const pr1 = admin
          .firestore()
          .collection("driver")
          .where("systemAccountId", "==", systemAccountID)
          .where("banned", "==", false)
          .orderBy(admin.firestore.FieldPath.documentId())
          .startAfter(lastDriverDoc)
          .limit(driveChunk)
          .get()
          .then(async (drivers) => {
            let localPromise3 = [];
            for (const key in drivers.docs) {
              if (Object.prototype.hasOwnProperty.call(drivers.docs, key)) {
                const driver = drivers.docs[key];
                // console.log(driver);
                const pr2 = admin
                  .firestore()
                  .collection("driver")
                  .doc(driver.id)
                  .get()
                  .then(async (driver) => {
                    let localPromise1 = [];
                    let dailyValue: [] = driver.get("dailyValue");
                    let status = driver.get("status");
                    if (!status) {
                      const pr3 = admin
                        .firestore()
                        .collection("penalities")
                        .where("driverID", "==", driver.id)
                        .where("status", "==", 0)
                        .limit(1)
                        .get()
                        .then(async (penality) => {
                          let localPromise2 = [];
                          if (penality.docs.length > 0) {
                            let rdTimestamp: admin.firestore.Timestamp =
                              penality.docs[0].get("returnDate");
                            let returnDate = rdTimestamp.toDate();
                            returnDate = convertTZ(returnDate, timeZoneName);
                            returnDate.setUTCMonth(returnDate.getMonth());
                            returnDate.setUTCDate(returnDate.getDate());
                            returnDate.setUTCHours(hours, minutes, 0, 0);
                            if (currentDate.getTime() >= returnDate.getTime()) {
                              const pr4 = admin
                                .firestore()
                                .collection("penalities")
                                .doc(penality.docs[0].id)
                                .update({ status: 1 });
                              localPromise2.push(pr4);
                              if (driver.get("plateNumber") != "") {
                                status = true;
                              }
                            }
                          }
                          let tvID = "",
                            routeID = "";
                          const pr6 = admin
                            .firestore()
                            .collection("transportVehicle")
                            .where("driverID", "==", driver.id)
                            .limit(1)
                            .get()
                            .then((tv) => {
                              if (!tv.empty) {
                                tvID = tv.docs[0].id;
                              }
                            });
                          localPromise2.push(pr6);
                          const pr7 = admin
                            .firestore()
                            .collection("routeTest1")
                            .where("driverID", "==", driver.id)
                            .where("status", "==", 1)
                            .orderBy("startTime", "desc")
                            .limit(1)
                            .get()
                            .then((route) => {
                              if (!route.empty) {
                                routeID = route.docs[0].id;
                              }
                            });
                          localPromise2.push(pr7);
                          await Promise.all(localPromise2);
                          tempDrivers.push(
                            new TempDriver(
                              driver.id,
                              dailyValue,
                              status,
                              tvID,
                              routeID
                            )
                          );
                        });
                      localPromise1.push(pr3);
                    } else {
                      let tvID = "",
                        routeID = "";
                      const pr6 = admin
                        .firestore()
                        .collection("transportVehicle")
                        .where("driverID", "==", driver.id)
                        .limit(1)
                        .get()
                        .then((tv) => {
                          if (!tv.empty) {
                            tvID = tv.docs[0].id;
                          }
                        });
                      localPromise1.push(pr6);
                      const pr7 = admin
                        .firestore()
                        .collection("routeTest1")
                        .where("driverID", "==", driver.id)
                        .where("status", "==", 1)
                        .orderBy("startTime", "desc")
                        .limit(1)
                        .get()
                        .then((route) => {
                          if (!route.empty) {
                            routeID = route.docs[0].id;
                          }
                        });
                      localPromise1.push(pr7);
                      await Promise.all(localPromise1);
                      tempDrivers.push(
                        new TempDriver(
                          driver.id,
                          dailyValue,
                          status,
                          tvID,
                          routeID
                        )
                      );
                    }
                    await Promise.all(localPromise1);
                  });
                localPromise3.push(pr2);
                await Promise.all(localPromise3);
              }
            }
          });
        promises.push(pr1);
      } else {
        const pr1 = admin
          .firestore()
          .collection("driver")
          .where("systemAccountId", "==", systemAccountID)
          .where("banned", "==", false)
          .orderBy(admin.firestore.FieldPath.documentId())
          .limit(driveChunk)
          .get()
          .then(async (drivers) => {
            let localPromise3 = [];
            for (const key in drivers.docs) {
              if (Object.prototype.hasOwnProperty.call(drivers.docs, key)) {
                const driver = drivers.docs[key];
                console.log(driver);
                const pr2 = admin
                  .firestore()
                  .collection("driver")
                  .doc(driver.id)
                  .get()
                  .then(async (driver) => {
                    let localPromise1 = [];
                    let dailyValue: [] = driver.get("dailyValue");
                    let status = driver.get("status");
                    if (!status) {
                      const pr3 = admin
                        .firestore()
                        .collection("penalities")
                        .where("driverID", "==", driver.id)
                        .where("status", "==", 0)
                        .limit(1)
                        .get()
                        .then(async (penality) => {
                          let localPromise2 = [];
                          if (penality.docs.length > 0) {
                            let rdTimestamp: admin.firestore.Timestamp =
                              penality.docs[0].get("returnDate");
                            let returnDate = rdTimestamp.toDate();
                            returnDate = convertTZ(returnDate, timeZoneName);
                            returnDate.setUTCMonth(returnDate.getMonth());
                            returnDate.setUTCDate(returnDate.getDate());
                            returnDate.setUTCHours(hours, minutes, 0, 0);
                            if (currentDate.getTime() >= returnDate.getTime()) {
                              const pr4 = admin
                                .firestore()
                                .collection("penalities")
                                .doc(penality.docs[0].id)
                                .update({ status: 1 });
                              localPromise2.push(pr4);
                              if (driver.get("plateNumber") != "") {
                                status = true;
                              }
                            }
                          }
                          let tvID = "",
                            routeID = "";
                          const pr6 = admin
                            .firestore()
                            .collection("transportVehicle")
                            .where("driverID", "==", driver.id)
                            .limit(1)
                            .get()
                            .then((tv) => {
                              if (!tv.empty) {
                                tvID = tv.docs[0].id;
                              }
                            });
                          localPromise2.push(pr6);
                          const pr7 = admin
                            .firestore()
                            .collection("routeTest1")
                            .where("driverID", "==", driver.id)
                            .where("status", "==", 1)
                            .orderBy("startTime", "desc")
                            .limit(1)
                            .get()
                            .then((route) => {
                              if (!route.empty) {
                                routeID = route.docs[0].id;
                              }
                            });
                          localPromise2.push(pr7);
                          await Promise.all(localPromise2);
                          tempDrivers.push(
                            new TempDriver(
                              driver.id,
                              dailyValue,
                              status,
                              tvID,
                              routeID
                            )
                          );
                        });
                      localPromise1.push(pr3);
                    } else {
                      let tvID = "",
                        routeID = "";
                      const pr6 = admin
                        .firestore()
                        .collection("transportVehicle")
                        .where("driverID", "==", driver.id)
                        .limit(1)
                        .get()
                        .then((tv) => {
                          if (!tv.empty) {
                            tvID = tv.docs[0].id;
                          }
                        });
                      localPromise1.push(pr6);
                      const pr7 = admin
                        .firestore()
                        .collection("routeTest1")
                        .where("driverID", "==", driver.id)
                        .where("status", "==", 1)
                        .orderBy("startTime", "desc")
                        .limit(1)
                        .get()
                        .then((route) => {
                          if (!route.empty) {
                            routeID = route.docs[0].id;
                          }
                        });
                      localPromise1.push(pr7);
                      await Promise.all(localPromise1);
                      tempDrivers.push(
                        new TempDriver(
                          driver.id,
                          dailyValue,
                          status,
                          tvID,
                          routeID
                        )
                      );
                    }
                    await Promise.all(localPromise1);
                  });
                localPromise3.push(pr2);
                await Promise.all(localPromise3);
              }
            }
          });
        promises.push(pr1);
      }
      await Promise.all(promises);
      // console.log("TempDrivers: " + tempDrivers.length);
      // console.log(tempDrivers);
      let yesterday = new Date(currentDate.getTime() - one_day);
      tempDrivers.forEach((tempDriver: TempDriver) => {
        console.log("TimeDiff: " + timeDiff + " rid: " + tempDriver.routeID);
        if (timeDiff >= 7 && tempDriver.routeID != "") {
          const pr8 = admin
            .firestore()
            .collection("routeTest1")
            .doc(tempDriver.routeID)
            .update({
              weeklyRoutes: [0, 0],
            });
          promises.push(pr8);
        }
        let array = [];
        for (const key in tempDriver.dailyValues) {
          if (
            Object.prototype.hasOwnProperty.call(tempDriver.dailyValues, key)
          ) {
            const element = tempDriver.dailyValues[key];
            array.push(element);
          }
        }
        const dailyMap: Map<string, any> = array[array.length - 1] as Map<
          string,
          any
        >;
        // console.log(dailyMap);
        let dvdTimeStamp: admin.firestore.Timestamp = dailyMap["date"];
        let recentDate = dvdTimeStamp.toDate();
        recentDate = convertTZ(dvdTimeStamp.toDate(), timeZoneName);
        recentDate.setUTCMonth(recentDate.getDate());
        recentDate.setUTCDate(recentDate.getDate());
        recentDate.setUTCHours(hours, minutes, 0, 0);
        console.log("recentDate: " + recentDate + " yesterday: " + yesterday);
        if (recentDate.getTime() >= yesterday.getTime()) {
          const pr5 = admin
            .firestore()
            .collection("driver")
            .doc(tempDriver.driverID)
            .update({
              status: tempDriver.status,
            });
          promises.push(pr5);
        } else {
          let addition: Map<string, any> = new Map<string, any>();
          addition["dailyStatus"] = 4;
          addition["date"] = admin.firestore.Timestamp.fromDate(yesterday);
          addition["imageUrl"] = "";
          addition["tvID"] = tempDriver.tvID;
          array.push(addition);
          let dailyValueJason = {};
          let keyCounter = 0;
          array.forEach((element) => {
            dailyValueJason[keyCounter] = {
              dailyStatus: element["dailyStatus"],
              date: element["date"],
              imageUrl: element["imageUrl"],
              tvID: element["tvID"],
            };
            keyCounter++;
          });
          // console.log(dailyValueJason);
          const pr5 = admin
            .firestore()
            .collection("driver")
            .doc(tempDriver.driverID)
            .update({
              // dailyValue: dailyValueJason,
              dailyValue: admin.firestore.FieldValue.arrayUnion(
                dailyValueJason[array.length - 1]
              ),
              failedFix: false,
              status: tempDriver.status,
              // trigger thf
              thf: admin.firestore.FieldValue.increment(1),
            });
          promises.push(pr5);
        }
      });
      await Promise.all(promises);
      // triggers this function (dailyDriverChecker) again
      if (tempDrivers.length == driveChunk) {
        // let ldriverID = tempDrivers[tempDrivers.length - 1].driverID;
      } else {
        if (timeDiff >= 7) {
          const pr9 = admin
            .firestore()
            .collection("systemRequirementAccount")
            .doc(systemAccountID)
            .update({
              lwDate: currentDate,
            });
          promises.push(pr9);
        }
      }
      const finalPromise = await Promise.all(promises);
      response.send("The result of the action is : " + finalPromise.length);
    } catch (error) {
      response.send("Err: " + error);
    }
  }
);

// TESTED
export const adCardCompleted = functions.https.onRequest(
  async (request, response) => {
    try {
      let promises = [];
      let adCardID = "zzObgBAi7qwICOCSB84y";
      let adAudioID = "YaU9kHziIBwl4HxCpvIe";
      let deleted = false;
      // let endDate = new Date();
      let businessID = "DGKIusAT0KMFc14WR5SC4fRftPD2",
        systemAccountID = "vDUgx0686C6tiSIQCTi8";
      let refund = 25; // adCardBalance
      let ltvAdID = "dummyID",
        lastAdSetID = "dummyID";
      let ladSetDoc = admin
        .firestore()
        .collection("adCardSetup")
        .doc(lastAdSetID);
      let ltvAdDoc = admin.firestore().collection("tvAD").doc(ltvAdID);
      let ltvEx = false,
        ladsEx = false;

      // amount of Docs the cloud function can delete
      // without timing out (intellectual guess)
      let tvAdChunkAmount = 200,
        adCardSetupChunkAmount = 200;

      let adCardSetupIds = [];
      if (ladsEx) {
        const pr1 = admin
          .firestore()
          .collection("adCardSetup")
          .where("adCardID", "==", adCardID)
          .orderBy(admin.firestore.FieldPath.documentId())
          .startAfter(ladSetDoc)
          .limit(adCardSetupChunkAmount)
          .get()
          .then((adCardSetups) => {
            adCardSetups.forEach((adCardSetup) => {
              adCardSetupIds.push(adCardSetup.id);
            });
          });
        promises.push(pr1);
      } else {
        const pr1 = admin
          .firestore()
          .collection("adCardSetup")
          .where("adCardID", "==", adCardID)
          .limit(adCardSetupChunkAmount)
          .get()
          .then((adCardSetups) => {
            // console.log(
            //   "AdCardSet: " + adCardSetups.docs.length + " " + adCardID
            // );
            adCardSetups.forEach((adCardSetup) => {
              adCardSetupIds.push(adCardSetup.id);
            });
          });
        promises.push(pr1);
      }

      let tvAdIDs = [],
        tvIds = [];
      if (ltvEx) {
        const pr2 = admin
          .firestore()
          .collection("tvAD")
          .where("adCardID", "==", adCardID)
          .orderBy(admin.firestore.FieldPath.documentId())
          .startAfter(ltvAdDoc)
          .limit(tvAdChunkAmount)
          .get()
          .then((tvAds) => {
            tvAds.forEach((tvAd) => {
              tvAdIDs.push(tvAd.id);
              if (tvAd.get("silent") == true) {
                tvIds.push(tvAd.get("tvID"));
              }
            });
          });
        promises.push(pr2);
      } else {
        const pr2 = admin
          .firestore()
          .collection("tvAD")
          .where("adCardID", "==", adCardID)
          .orderBy(admin.firestore.FieldPath.documentId())
          .limit(tvAdChunkAmount)
          .get()
          .then((tvAds) => {
            tvAds.forEach((tvAd) => {
              tvAdIDs.push(tvAd.id);
              if (tvAd.get("silent") == true) {
                tvIds.push(tvAd.get("tvID"));
              }
            });
          });
        promises.push(pr2);
      }

      if (!deleted) {
        // let newDate = new Date();
        // if (newDate.getTime() > endDate.getTime()) {
        //   newDate = endDate;
        // }
        const pr4 = admin
          .firestore()
          .collection("business")
          .doc(businessID)
          .update({
            balance: admin.firestore.FieldValue.increment(refund),
          });
        promises.push(pr4);
        const pr5 = admin
          .firestore()
          .collection("tempTransaction")
          .doc()
          .create({
            amount: refund,
            reciever: businessID,
            sender: adCardID,
            specificType: 4,
            status: 2,
            systemAccountId: systemAccountID,
            timestamp: admin.firestore.Timestamp.now(),
            type: true,
          });
        promises.push(pr5);
        let audioUrl = "";
        const pr1 = admin
          .firestore()
          .collection("AdAudioTest")
          .doc(adAudioID)
          .get()
          .then((adAudio) => {
            audioUrl = adAudio.get("audioUrl");
          });
        promises.push(pr1);
        await Promise.all(promises);
        const bucket = admin.storage().bucket();
        let split: string[] = audioUrl.split("o/");
        let split1 = split[1].split("?");
        let path = split1[0];
        path = decodeURIComponent(path);
        const pr7 = bucket.file(path).delete();
        promises.push(pr7);
        const pr8 = admin
          .firestore()
          .collection("AdAudioTest")
          .doc(adAudioID)
          .delete();
        promises.push(pr8);
      }
      if (deleted) {
        await Promise.all(promises);
      }
      // console.log("AdSetups and tvs");
      // console.log(adCardSetupIds);
      // console.log(tvIDs);
      adCardSetupIds.forEach((adCardSetupID) => {
        const pr3 = admin
          .firestore()
          .collection("adCardSetup")
          .doc(adCardSetupID)
          .update({
            activeForDate: false,
            availableSetups: admin.firestore.FieldValue.delete(),
            completed: true,
          });
        promises.push(pr3);
      });
      tvAdIDs.forEach((tvAdId) => {
        const pr3 = admin.firestore().collection("tvAD").doc(tvAdId).delete();
        promises.push(pr3);
      });
      tvIds.forEach((tvID) => {
        const pr4 = admin
          .firestore()
          .collection("transportVehicle")
          .doc(tvID)
          .update({
            silentAdNumber: admin.firestore.FieldValue.increment(-1),
          });
        promises.push(pr4);
      });
      await Promise.all(promises);
      // this indicates there might be more tvAds
      // not retrieved which means not deleted
      if (
        tvAdIDs.length == tvAdChunkAmount ||
        adCardSetupIds.length == adCardSetupChunkAmount
      ) {
        if (tvAdIDs.length > 0 && adCardSetupIds.length > 0) {
          const pr6 = admin
            .firestore()
            .collection("AdCardTemp")
            .doc(adCardID)
            .update({
              deleted: true,
              lastTvID: tvAdIDs[tvAdIDs.length - 1],
              lastAdSetID: adCardSetupIds[adCardSetupIds.length - 1],
              // trigger ad card completed function
              acc: admin.firestore.FieldValue.increment(1),
            });
          promises.push(pr6);
        } else if (tvAdIDs.length > 0) {
          const pr6 = admin
            .firestore()
            .collection("AdCardTemp")
            .doc(adCardID)
            .update({
              deleted: true,
              lastTvID: tvAdIDs[tvAdIDs.length - 1],
              // trigger ad card completed function
              acc: admin.firestore.FieldValue.increment(1),
            });
          promises.push(pr6);
        } else if (adCardSetupIds.length > 0) {
          const pr6 = admin
            .firestore()
            .collection("AdCardTemp")
            .doc(adCardID)
            .update({
              deleted: true,
              lastAdSetID: adCardSetupIds[adCardSetupIds.length - 1],
              // trigger ad card completed function
              acc: admin.firestore.FieldValue.increment(1),
            });
          promises.push(pr6);
        }
      }
      const finalPromise = await Promise.all(promises);
      response.send("The result of the action is : " + finalPromise.length);
    } catch (error) {
      response.send("Err: " + error);
    }
  }
);

// TESTED
export const maxLengChanged = functions.https.onRequest(
  async (request, response) => {
    try {
      let promises = [];
      let systemAccountID = "vDUgx0686C6tiSIQCTi8",
        lastAdId = "dummyID";
      let lastAdExist = false;
      let lastAdDoc = admin.firestore().collection("AdCardTemp").doc(lastAdId);
      let newLength = 8;
      let adChunk = 20;

      // so that carModel, super path and timeSlot deletion
      // dont get triggered
      // change cmspDeletionFinished in controller to false
      let adCardIds = [];
      if (lastAdExist) {
        const pr1 = admin
          .firestore()
          .collection("AdCardTemp")
          .where("systemAccountID", "==", systemAccountID)
          .where("length", ">", newLength)
          .orderBy("length", "asc")
          .startAfter(lastAdDoc)
          .limit(adChunk)
          .get()
          .then((adCards) => {
            adCards.docs.forEach((adCard) => {
              adCardIds.push(adCard.id);
            });
          });
        promises.push(pr1);
      } else {
        const pr1 = admin
          .firestore()
          .collection("AdCardTemp")
          .where("systemAccountID", "==", systemAccountID)
          .where("length", ">", newLength)
          .orderBy("length", "asc")
          .limit(adChunk)
          .get()
          .then((adCards) => {
            adCards.docs.forEach((adCard) => {
              adCardIds.push(adCard.id);
            });
          });
        promises.push(pr1);
      }
      await Promise.all(promises);

      adCardIds.forEach((adCardID) => {
        const pr2 = admin
          .firestore()
          .collection("AdCardTemp")
          .doc(adCardID)
          .update({
            // completed: true,
            // end_date: admin.firestore.Timestamp.now(),
            // // trigger ad card completed function
            // acc: admin.firestore.FieldValue.increment(1),
            readyToComplete: true,
          });
        promises.push(pr2);
      });
      await Promise.all(promises);
      if (adCardIds.length == adChunk) {
        // trigger maxLengChanged again
        // let lastAid = adCardIds[adCardIds.length - 1];
      } else {
        let timeSpanIds = [];
        const pr3 = admin
          .firestore()
          .collection("timeSpan")
          .where("systemAccountId", "==", systemAccountID)
          .get()
          .then((timeSpans) => {
            timeSpans.forEach((timeSpan) => {
              timeSpanIds.push(timeSpan.id);
            });
          });
        promises.push(pr3);
        await Promise.all(promises);
        timeSpanIds.forEach((timeSpanID) => {
          const pr4 = admin
            .firestore()
            .collection("timeSpan")
            .doc(timeSpanID)
            .update({
              // trigger pathAdjust function
              pa: admin.firestore.FieldValue.increment(1),
            });
          promises.push(pr4);
        });
        // change cmspDeletionFinished in controller to true
      }
      const finalPromise = await Promise.all(promises);
      response.send("The result of the action is : " + finalPromise.length);
    } catch (error) {
      response.send("Err: " + error);
    }
  }
);

// Need to add readyToComplete to AdCardTemp to test this again
// TESTED
export const adCardCheck = functions.https.onRequest(
  async (request, response) => {
    try {
      let promises = [];
      let systemAccountID: string = "vDUgx0686C6tiSIQCTi8";
      let adCardID = "OFKZXTsLbybu9eCDo9mv",
        lastAdSetID = "dummyID";
      let lastAdSetDocExist = false;
      let lastAdSetDoc = admin
        .firestore()
        .collection("adCardSetup")
        .doc(lastAdSetID);

      // amount of Docs the cloud function can delete
      // without timing out (intellectual guess)
      let adCardSetChunk = 200;
      let adCard: AdCard;

      let timeZoneOffset: number;
      let timeZoneName: string;

      await admin
        .firestore()
        .collection("systemRequirementAccount")
        .doc(systemAccountID)
        .get()
        .then((sysReqAcc) => {
          timeZoneOffset = -sysReqAcc.get("timeZoneOffset");
          timeZoneName = sysReqAcc.get("timeZoneName");
        });

      let hours = Math.floor(timeZoneOffset / 60);
      let minutes = timeZoneOffset % 60;

      let one_day = 24 * 60 * 60 * 1000;
      let currentDate = new Date();
      currentDate = convertTZ(currentDate, timeZoneName);
      currentDate.setUTCMonth(currentDate.getMonth());
      currentDate.setUTCDate(currentDate.getDate());
      currentDate.setUTCHours(hours, minutes, 0, 0);
      // currentDate.setHours(0, 0, 0, 0);
      let currentDayIndays = currentDate.getTime() / one_day;
      // console.log(
      //   "Currrent Date: " +
      //     currentDate +
      //     " InDays: " +
      //     currentDayIndays +
      //     " tz: " +
      //     timeZoneOffset.toString()
      // );
      class AdCardSetup {
        adCardID: string;
        adCardSetupID: string;
        // availableSetupsExist: boolean;
        constructor(adCardID: string, adCardSetupID: string) {
          this.adCardID = adCardID;
          this.adCardSetupID = adCardSetupID;
        }
      }
      class TempAdCard {
        adCardID: string;
        adCardSetups: AdCardSetup[] = [];
        activeForDate: boolean;
        readyToCompelete: boolean;
        completed: boolean;
        unprocessedTransactionExist: boolean;
        timeScore: number;
        endDate: Date;
        // refund: number;
        constructor(adCardID: string, endDate: Date) {
          this.adCardID = adCardID;
          this.endDate = endDate;
          // this.refund = refund;
        }
      }

      let valueMap: Map<string, number> = new Map();
      // const pr9 =
      //   admin
      //     .firestore()
      //     .collection("controller")
      //     .where("systemAccountId", "==", systemAccountID)
      //     .get().then((contoller) => valueMap = contoller.docs[0].get("valueMap") as Map<string, number>);
      // promises.push(pr9);
      let cmReadPromise = admin
        .firestore()
        .collection("carModel")
        .where("systemAccountId", "==", systemAccountID)
        .get()
        .then(async (querySnapshot) => {
          querySnapshot.docs.forEach((element) => {
            // the value is percent in variables below
            valueMap.set(element.id + "c", element.get("percentage"));
          });
        });
      promises.push(cmReadPromise);
      let tsReadPromise = admin
        .firestore()
        .collection("timeSlot")
        .where("systemAccountId", "==", systemAccountID)
        .get()
        .then(async (querySnapshot) => {
          querySnapshot.docs.forEach((element) => {
            // the value is percent in variables below
            valueMap.set(element.id + "t", element.get("percentage"));
          });
        });
      promises.push(tsReadPromise);
      // let superPath:Map<string,number>=new Map();// <string(super path),number(ad break)
      let spReadPromise = admin
        .firestore()
        .collection("superPath")
        .where("systemAccountId", "==", systemAccountID)
        .get()
        .then(async (querySnapshot) => {
          querySnapshot.docs.forEach((element) => {
            valueMap.set(element.id + "s", element.get("price"));
            // superPath.set(element.id,element.get("averageAdBrake"))
          });
        });
      promises.push(spReadPromise);

      // We dont really need to use AdCard class here we could have
      // used a new class which only contains the fields we want
      // but we used ad card to not write a new code
      const readPromise = admin
        .firestore()
        .collection("AdCardTemp")
        .doc(adCardID)
        .get()
        .then(async (element) => {
          var cm = element.get("cm");
          var ts = element.get("ts");
          var sp = element.get("sp");
          let cms: string[] = [];
          let tss: string[] = [];
          let sps: string[] = [];

          let createdDate = element.get("created_date").toDate();
          let endDate: Date = element.get("end_date").toDate();
          let startDate: Date = element.get("start_date").toDate();
          // To make sure every ad card has the same time set
          // according to their timeZone
          startDate = convertTZ(startDate, timeZoneName);
          endDate = convertTZ(endDate, timeZoneName);
          // console.log(
          //   "ed2: " +
          //     endDate +
          //     " " +
          //     startDate +
          //     " edDa2: " +
          //     endDate.getDate() +
          //     " " +
          //     " => " +
          //     endDate.getUTCDate() +
          //     " " +
          //     startDate.getDate() +
          //     " => " +
          //     startDate.getUTCDate()
          // );
          endDate.setUTCMonth(endDate.getMonth());
          endDate.setUTCDate(endDate.getDate());
          startDate.setUTCMonth(startDate.getMonth());
          startDate.setUTCDate(startDate.getDate());

          startDate.setUTCHours(hours, minutes, 0, 0);
          endDate.setUTCHours(hours, minutes, 0, 0);
          // startDate.setHours(0, 0, 0, 0);
          // endDate.setHours(0, 0, 0, 0);

          cm.forEach((element) => {
            cms.push(element);
          });
          ts.forEach((element) => {
            tss.push(element);
          });
          sp.forEach((element) => {
            sps.push(element);
          });

          adCard = new AdCard(
            element.id,
            element.get("length"),
            element.get("frequency_per_route"),
            cms,
            tss,
            sps,
            element.get("adCardBalance"),
            createdDate,
            startDate,
            endDate
          );
          adCard.status = element.get("status");
          // NEW
          adCard.readyToComplete = element.get("readyToComplete");
          //
        });
      promises.push(readPromise);
      await Promise.all(promises);

      adCard = singlefrequencyAssigner(valueMap, adCard);
      // console.log("AdCard");
      // console.log(adCard);
      // console.log("AvailSetupLeng: " + adCard.availableSetups.length);
      if (adCard.availableSetups.length > 0 && !adCard.readyToComplete) {
        adCard.completed = false;
      } else {
        adCard.completed = true;
      }

      let startDateIndays = adCard.start_date.getTime() / one_day;
      let endDateIndays = adCard.end_date.getTime() / one_day;
      // console.log(
      //   "StartDate: " + adCard.start_date + " EndDate: " + adCard.end_date
      // );
      // console.log("StInDa: " + startDateIndays + " EnInda: " + endDateIndays);
      adCard.timeScore = currentDate.getTime() - adCard.created_date.getTime();
      if (
        startDateIndays <= currentDayIndays &&
        currentDayIndays <= endDateIndays &&
        // NEW
        adCard.status == 1
        //
      ) {
        adCard.activeForDate = true;
      }
      if (currentDayIndays > endDateIndays) {
        adCard.completed = true;
      }

      let tempAdCard = new TempAdCard(
        adCard.name,
        adCard.end_date
        // adCard.adCardBalance
      );
      tempAdCard.activeForDate = adCard.activeForDate;
      tempAdCard.completed = adCard.completed;
      tempAdCard.timeScore = adCard.timeScore;
      if (lastAdSetDocExist) {
        const pr1 = admin
          .firestore()
          .collection("adCardSetup")
          .where("adCardID", "==", adCard.name)
          .orderBy(admin.firestore.FieldPath.documentId())
          .startAfter(lastAdSetDoc)
          .limit(adCardSetChunk)
          .get()
          .then(async (querySnapShot) => {
            querySnapShot.forEach(async (adCardSetup) => {
              // let availableSetups: [] = adCardSetup.get("availableSetups");
              let tempAdCardSetup = new AdCardSetup(
                adCard.name,
                adCardSetup.id
              );
              // if (availableSetups.length > 0) {
              //   tempAdCardSetup.availableSetupsExist = true;
              // } else {
              //   tempAdCardSetup.availableSetupsExist = false;
              // }
              tempAdCard.adCardSetups.push(tempAdCardSetup);
            });
          });
        promises.push(pr1);
      } else {
        const pr1 = admin
          .firestore()
          .collection("adCardSetup")
          .where("adCardID", "==", adCard.name)
          .orderBy(admin.firestore.FieldPath.documentId())
          .limit(adCardSetChunk)
          .get()
          .then(async (querySnapShot) => {
            querySnapShot.forEach(async (adCardSetup) => {
              // let availableSetups: [] = adCardSetup.get("availableSetups");
              let tempAdCardSetup = new AdCardSetup(
                adCard.name,
                adCardSetup.id
              );
              // if (availableSetups.length > 0) {
              //   tempAdCardSetup.availableSetupsExist = true;
              // } else {
              //   tempAdCardSetup.availableSetupsExist = false;
              // }
              tempAdCard.adCardSetups.push(tempAdCardSetup);
            });
          });
        promises.push(pr1);
      }
      const pr4 = admin
        .firestore()
        .collection("tempTransaction")
        .where("sender", "==", adCardID)
        .where("status", "in", [0, 1])
        .limit(1)
        .get()
        .then((unProcTrans) => {
          if (unProcTrans.docs.length > 0) {
            tempAdCard.unprocessedTransactionExist = true;
          } else {
            tempAdCard.unprocessedTransactionExist = false;
          }
        });
      promises.push(pr4);
      await Promise.all(promises);
      // console.log("TempAdCard");
      // console.log(tempAdCard);

      // if (!tempAdCard.completed) {
      //   tempAdCard.completed = true;
      //   for (let index = 0; index < tempAdCard.adCardSetups.length; index++) {
      //     const adCardSetup = tempAdCard.adCardSetups[index];
      //     if (adCardSetup.availableSetupsExist) {
      //       tempAdCard.completed = false;
      //       break;
      //     }
      //   }
      // }
      if (tempAdCard.completed && tempAdCard.unprocessedTransactionExist) {
        tempAdCard.completed = false;
      }

      if (tempAdCard.completed) {
        const pr2 = admin
          .firestore()
          .collection("AdCardTemp")
          .doc(tempAdCard.adCardID)
          .update({
            completed: true,
            end_date: admin.firestore.Timestamp.now(),
            // trigger ad card completed function
            acc: admin.firestore.FieldValue.increment(1),
          });
        promises.push(pr2);
      } else {
        tempAdCard.adCardSetups.forEach((adCardSetup) => {
          const pr3 = admin
            .firestore()
            .collection("adCardSetup")
            .doc(adCardSetup.adCardSetupID)
            .update({
              timeScore: tempAdCard.timeScore,
              activeForDate: tempAdCard.activeForDate,
            });
          promises.push(pr3);
        });
      }
      await Promise.all(promises);
      if (
        tempAdCard.adCardSetups.length == adCardSetChunk &&
        !tempAdCard.completed
      ) {
        const pr6 = admin
          .firestore()
          .collection("AdCardTemp")
          .doc(adCardID)
          .update({
            lastDocID:
              tempAdCard.adCardSetups[tempAdCard.adCardSetups.length - 1]
                .adCardSetupID,
            // trigger adCardCheck (this function again)
            dac: admin.firestore.FieldValue.increment(1),
          });
        promises.push(pr6);
      }
      const finalPromise = await Promise.all(promises);
      response.send("The result of the action is : " + finalPromise.length);
    } catch (error) {
      response.send("Err: " + error);
    }
  }
);

// listens to timeSpan document
// TESTED
export const timeSpanEdit = functions.https.onRequest(
  async (request, response) => {
    try {
      let promises = [];
      let systemAccountID = "vDUgx0686C6tiSIQCTi8",
        timeSpanID = "NzgZgPpIIxwHTP9QZNmv",
        lastPathId = "dummyID";
      let lastPathDocExist = false;
      let lastPathDoc = admin.firestore().collection("path").doc(lastPathId);
      let pathChunk = 200;
      let timeSpanLeng = 22;
      let beforeWaitTime = 30,
        afterWaitTime = 65;
      let beforeBufferLeng = 12,
        afterBufferLeng = 13;
      let bufferLengChange = false,
        waitTimeChange = false;

      // when function starts change finished to false

      class TempPath {
        pathID: string;
        initialTime: number;
        constructor(pathID: string, initialTime: number) {
          this.pathID = pathID;
          this.initialTime = initialTime;
        }
      }

      let tempPaths: TempPath[] = [];
      if (beforeBufferLeng != afterBufferLeng || bufferLengChange) {
        let bufferLength = afterBufferLeng,
          length = timeSpanLeng,
          maximumLengPerAdBrake = 8;
        const pr1 = admin
          .firestore()
          .collection("systemRequirementAccount")
          .doc(systemAccountID)
          .get()
          .then(
            (systemAccount) =>
              (maximumLengPerAdBrake = systemAccount.get(
                "adBrakeMaximumLength"
              ))
          );
        promises.push(pr1);
        if (lastPathDocExist) {
          const pr2 = admin
            .firestore()
            .collection("path")
            .where("timeSpanID", "==", timeSpanID)
            .orderBy(admin.firestore.FieldPath.documentId())
            .startAfter(lastPathDoc)
            .limit(pathChunk)
            .get()
            .then((paths) => {
              paths.forEach((path) => {
                tempPaths.push(new TempPath(path.id, path.get("initialTime")));
              });
            });
          promises.push(pr2);
        } else {
          const pr2 = admin
            .firestore()
            .collection("path")
            .where("timeSpanID", "==", timeSpanID)
            .orderBy(admin.firestore.FieldPath.documentId())
            .limit(pathChunk)
            .get()
            .then((paths) => {
              paths.forEach((path) => {
                tempPaths.push(new TempPath(path.id, path.get("initialTime")));
              });
            });
          promises.push(pr2);
        }
        await Promise.all(promises);
        maximumLengPerAdBrake *= 30;
        bufferLength *= 60;
        length *= 60;
        let rast = bufferLength + maximumLengPerAdBrake;
        tempPaths.forEach((tempPath) => {
          let tempLength = length;
          let initialTime = tempPath.initialTime * 60;
          if (tempLength < initialTime + maximumLengPerAdBrake) {
            const pr3 = admin
              .firestore()
              .collection("path")
              .doc(tempPath.pathID)
              .update({
                maximumAmountOfAdBrake: 1,
                maximumWaitTime: afterWaitTime,
              });
            promises.push(pr3);
          } else {
            tempLength -= initialTime + maximumLengPerAdBrake;
            let maxAdBrake = Math.floor(tempLength / rast);
            maxAdBrake++;
            if (maxAdBrake > 3) {
              maxAdBrake = 3;
            }
            // console.log(
            //   "Length: " +
            //     tempLength +
            //     " " +
            //     initialTime +
            //     " " +
            //     maximumLengPerAdBrake +
            //     " rast " +
            //     rast +
            //     " " +
            //     maxAdBrake
            // );
            const pr3 = admin
              .firestore()
              .collection("path")
              .doc(tempPath.pathID)
              .update({
                maximumAmountOfAdBrake: maxAdBrake,
                maximumWaitTime: afterWaitTime,
              });
            promises.push(pr3);
          }
        });
      } else if (beforeWaitTime != afterWaitTime || waitTimeChange) {
        if (lastPathDocExist) {
          const pr2 = admin
            .firestore()
            .collection("path")
            .where("timeSpanID", "==", timeSpanID)
            .orderBy(admin.firestore.FieldPath.documentId())
            .startAfter(lastPathDoc)
            .limit(pathChunk)
            .get()
            .then((paths) => {
              paths.forEach((path) => {
                tempPaths.push(new TempPath(path.id, path.get("initialTime")));
              });
            });
          promises.push(pr2);
        } else {
          const pr2 = admin
            .firestore()
            .collection("path")
            .where("timeSpanID", "==", timeSpanID)
            .orderBy(admin.firestore.FieldPath.documentId())
            .limit(pathChunk)
            .get()
            .then((paths) => {
              paths.forEach((path) => {
                tempPaths.push(new TempPath(path.id, path.get("initialTime")));
              });
            });
          promises.push(pr2);
        }
        await Promise.all(promises);
        tempPaths.forEach((tempPath) => {
          const pr3 = admin
            .firestore()
            .collection("path")
            .doc(tempPath.pathID)
            .update({ maximumWaitTime: afterWaitTime });
          promises.push(pr3);
        });
      }
      await Promise.all(promises);
      if (tempPaths.length == pathChunk) {
        // update waitTimeChange and bufferLengChange of the document
        if (beforeBufferLeng != afterBufferLeng) {
          // bufferLengChange = true; // bufferLengChange will also update maximumWaitTime
        } else if (beforeWaitTime != afterWaitTime) {
          // waitTimeChange = true;
        }
        // let lastPid = tempPaths[tempPaths.length - 1].pathID;
        // trigger timeSpanEdit(this function) again
      } else {
        // update waitTimeChange and bufferLengChange of the document
        // waitTimeChange = false;
        // bufferLengChange = false;
        // mark it as finished by changing finished to true
      }
      const finalPromise = await Promise.all(promises);
      response.send("The result of the action is : " + finalPromise.length);
    } catch (error) {
      response.send("Err: " + error);
    }
  }
);

// TESTED
// listens to timeSpan doc
export const pathAdjust = functions.https.onRequest(
  async (request, response) => {
    try {
      let promises = [];
      let systemAccountID = "vDUgx0686C6tiSIQCTi8",
        timeSpanID = "NzgZgPpIIxwHTP9QZNmv",
        lastPathId = "dummyID";
      let lastPathDocExist = false;
      let lastPathDoc = admin.firestore().collection("path").doc(lastPathId);
      let pathChunk = 200;
      let bufferLength = 12,
        length = 22,
        maximumLengPerAdBrake = 8;

      class TempPath {
        pathID: string;
        initialTime: number;
        constructor(pathID: string, initialTime: number) {
          this.pathID = pathID;
          this.initialTime = initialTime;
        }
      }

      let tempPaths: TempPath[] = [];
      const pr1 = admin
        .firestore()
        .collection("systemRequirementAccount")
        .doc(systemAccountID)
        .get()
        .then(
          (systemAccount) =>
            (maximumLengPerAdBrake = systemAccount.get("adBrakeMaximumLength"))
        );
      promises.push(pr1);
      if (lastPathDocExist) {
        const pr2 = admin
          .firestore()
          .collection("path")
          .where("timeSpanID", "==", timeSpanID)
          .orderBy(admin.firestore.FieldPath.documentId())
          .startAfter(lastPathDoc)
          .limit(pathChunk)
          .get()
          .then((paths) => {
            paths.forEach((path) => {
              tempPaths.push(new TempPath(path.id, path.get("initialTime")));
            });
          });
        promises.push(pr2);
      } else {
        const pr2 = admin
          .firestore()
          .collection("path")
          .where("timeSpanID", "==", timeSpanID)
          .orderBy(admin.firestore.FieldPath.documentId())
          .limit(pathChunk)
          .get()
          .then((paths) => {
            paths.forEach((path) => {
              tempPaths.push(new TempPath(path.id, path.get("initialTime")));
            });
          });
        promises.push(pr2);
      }
      await Promise.all(promises);
      maximumLengPerAdBrake *= 30;
      bufferLength *= 60;
      length *= 60;
      let rast = bufferLength + maximumLengPerAdBrake;
      // console.log("Temp paths: " + tempPaths.length);

      tempPaths.forEach((tempPath) => {
        let tempLength = length;
        let initialTime = tempPath.initialTime * 60;
        if (tempLength < initialTime + maximumLengPerAdBrake) {
          const pr3 = admin
            .firestore()
            .collection("path")
            .doc(tempPath.pathID)
            .update({
              maximumAmountOfAdBrake: 1,
            });
          promises.push(pr3);
        } else {
          tempLength -= initialTime + maximumLengPerAdBrake;
          let maxAdBrake = Math.floor(tempLength / rast);
          maxAdBrake++;
          if (maxAdBrake > 3) {
            maxAdBrake = 3;
          }
          // console.log(
          //   "Length: " + tempLength + " rast " + rast + " " + maxAdBrake
          // );
          const pr3 = admin
            .firestore()
            .collection("path")
            .doc(tempPath.pathID)
            .update({
              maximumAmountOfAdBrake: maxAdBrake,
            });
          promises.push(pr3);
        }
      });
      await Promise.all(promises);
      // trigger pathAdjust(this function) again
      if (tempPaths.length == pathChunk) {
        // let lastPid = tempPaths[tempPaths.length - 1].pathID;
      }
      const finalPromise = await Promise.all(promises);
      response.send("The result of the action is : " + finalPromise.length);
    } catch (error) {
      response.send("Err: " + error);
    }
  }
);

// listents to systemReqAccount table but to a variable
// called tvStatusController
// TESTED
export const tvStatusChange = functions.https.onRequest(
  async (request, response) => {
    try {
      let promises = [];
      let systemAccountID = "vDUgx0686C6tiSIQCTi8",
        lastTvID = "dummyID";
      let lastTvExist = false;
      let lastTvDoc = admin
        .firestore()
        .collection("transportVehicle")
        .doc(lastTvID);
      let tvChunk = 1000;

      // so that carModel, super path and timeSlot deletion
      // dont get triggered
      // change cmspDeletionFinished in controller to false
      let newStatus = false;

      let tvIDs: string[] = [];
      if (lastTvExist) {
        const pr1 = admin
          .firestore()
          .collection("transportVehicle")
          .where("systemAccountId", "==", systemAccountID)
          .orderBy(admin.firestore.FieldPath.documentId())
          .startAfter(lastTvDoc)
          .limit(tvChunk)
          .get()
          .then((tvs) => {
            tvs.forEach((tv) => {
              tvIDs.push(tv.id);
            });
          });
        promises.push(pr1);
      } else {
        const pr1 = admin
          .firestore()
          .collection("transportVehicle")
          .where("systemAccountId", "==", systemAccountID)
          .orderBy(admin.firestore.FieldPath.documentId())
          .limit(tvChunk)
          .get()
          .then((tvs) => {
            tvs.forEach((tv) => {
              tvIDs.push(tv.id);
            });
          });
        promises.push(pr1);
      }
      await Promise.all(promises);

      tvIDs.forEach((tvID) => {
        const pr2 = admin
          .firestore()
          .collection("transportVehicle")
          .doc(tvID)
          .update({
            status: newStatus,
          });
        promises.push(pr2);
      });
      await Promise.all(promises);
      // trigger tvStatusChange(this function) again
      if (tvIDs.length == tvChunk) {
        // let lastPid = tvIDs[tvIDs.length - 1];
      } else {
        // change cmspDeletionFinished in controller to true
      }
      const finalPromise = await Promise.all(promises);
      response.send("The result of the action is : " + finalPromise.length);
    } catch (error) {
      response.send("Err: " + error);
    }
  }
);

// listens to controller for changes in superPathID
// TESTED
export const superPathDelete = functions.https.onRequest(
  async (request, response) => {
    try {
      let promises = [];
      let superPathID = "YXXiFH1f7ni6l5qNyQK9",
        systemAccountId = "vDUgx0686C6tiSIQCTi8",
        lastpathId = "dummyID",
        lastAdID = "dummyID",
        lastRaID = "dummyID";
      let lastPaDoc = admin.firestore().collection("path").doc(lastpathId);
      let lastAdDoc = admin.firestore().collection("AdCardTemp").doc(lastAdID);
      let lastRaDoc = admin
        .firestore()
        .collection("routeAverages")
        .doc(lastRaID);
      let lPaEx = false,
        ladEx = false,
        laRaEx = false;
      let pathChunk = 200,
        adCardChunk = 200,
        // raChunk has to be much lower than the above
        // chunks as it includes 4500 route averages
        // data in one document
        raChunk = 50;

      // change cmspDeletionFinished in controller to false

      let pathIDs = [],
        adCardIDs = [],
        notCompletedAdCardIds = [];
      // NEW
      class RouteAverageChunk {
        raChunkId: string;
        routeaverages: RouteAverage[];
        constructor(raChunkId: string, routeaverages: RouteAverage[]) {
          this.raChunkId = raChunkId;
          this.routeaverages = routeaverages;
        }
      }
      let routeAverageChunks: RouteAverageChunk[] = [];
      //
      if (lPaEx) {
        const pr1 = admin
          .firestore()
          .collection("path")
          .where("superPathID", "==", superPathID)
          .orderBy(admin.firestore.FieldPath.documentId())
          .startAfter(lastPaDoc)
          .limit(pathChunk)
          .get()
          .then((paths) => {
            paths.forEach((path) => {
              pathIDs.push(path.id);
            });
          });
        promises.push(pr1);
      } else {
        const pr1 = admin
          .firestore()
          .collection("path")
          .where("superPathID", "==", superPathID)
          .orderBy(admin.firestore.FieldPath.documentId())
          .limit(pathChunk)
          .get()
          .then((paths) => {
            paths.forEach((path) => {
              pathIDs.push(path.id);
            });
          });
        promises.push(pr1);
      }
      if (ladEx) {
        const pr2 = admin
          .firestore()
          .collection("AdCardTemp")
          .where("completed", "==", false)
          .where("sp", "array-contains", superPathID)
          .orderBy(admin.firestore.FieldPath.documentId())
          .startAfter(lastAdDoc)
          .limit(adCardChunk)
          .get()
          .then((adCards) => {
            adCards.forEach((adCard) => {
              let sp: any[] = adCard.get("sp") as [];
              if (sp.length == 1) {
                adCardIDs.push(adCard.id);
              } else {
                notCompletedAdCardIds.push(adCard.id);
              }
            });
          });
        promises.push(pr2);
      } else {
        const pr2 = admin
          .firestore()
          .collection("AdCardTemp")
          .where("completed", "==", false)
          .where("sp", "array-contains", superPathID)
          .orderBy(admin.firestore.FieldPath.documentId())
          .limit(adCardChunk)
          .get()
          .then((adCards) => {
            adCards.forEach((adCard) => {
              let sp: any[] = adCard.get("sp") as [];
              if (sp.length == 1) {
                adCardIDs.push(adCard.id);
              } else {
                notCompletedAdCardIds.push(adCard.id);
              }
            });
          });
        promises.push(pr2);
      }
      // NEW
      if (laRaEx) {
        let avgRoutePromise = admin
          .firestore()
          .collection("routeAverages")
          .where("systemAccountId", "==", systemAccountId)
          .orderBy(admin.firestore.FieldPath.documentId())
          .startAfter(lastRaDoc)
          .limit(raChunk)
          .get()
          .then((querySnapshot) => {
            querySnapshot.docs.forEach((element) => {
              let averageRoutes: RouteAverage[] = [];
              let ras: any[] = element.get("routeAverages");
              ras.forEach((ra) => {
                let averageRoute = new RouteAverage(
                  ra.cm,
                  ra.ts,
                  ra.sp,
                  ra.totalAmountOfRoute
                );
                averageRoute.scstpd = ra.scstpd;
                averageRoute.scstppd = ra.scstppd;
                averageRoute.rfstpd = ra.rfstpd;
                averageRoute.averageAdBrake = ra.averageAdBrake;
                averageRoutes.push(averageRoute);
              });
              routeAverageChunks.push(
                new RouteAverageChunk(element.id, averageRoutes)
              );
            });
          });
        promises.push(avgRoutePromise);
      } else {
        let avgRoutePromise = admin
          .firestore()
          .collection("routeAverages")
          .where("systemAccountId", "==", systemAccountId)
          .orderBy(admin.firestore.FieldPath.documentId())
          .limit(raChunk)
          .get()
          .then((querySnapshot) => {
            querySnapshot.docs.forEach((element) => {
              let averageRoutes: RouteAverage[] = [];
              let ras: any[] = element.get("routeAverages");
              ras.forEach((ra) => {
                let averageRoute = new RouteAverage(
                  ra.cm,
                  ra.ts,
                  ra.sp,
                  ra.totalAmountOfRoute
                );
                averageRoute.scstpd = ra.scstpd;
                averageRoute.scstppd = ra.scstppd;
                averageRoute.rfstpd = ra.rfstpd;
                averageRoute.averageAdBrake = ra.averageAdBrake;
                averageRoutes.push(averageRoute);
              });
              routeAverageChunks.push(
                new RouteAverageChunk(element.id, averageRoutes)
              );
            });
          });
        promises.push(avgRoutePromise);
      }
      // NEW
      await Promise.all(promises);
      // console.log(pathIDs);
      // console.log(raIDs);
      pathIDs.forEach((pathID) => {
        const pr4 = admin.firestore().collection("path").doc(pathID).delete();
        promises.push(pr4);
      });
      adCardIDs.forEach((adCardID) => {
        const pr5 = admin
          .firestore()
          .collection("AdCardTemp")
          .doc(adCardID)
          .update({
            // completed: true,
            // end_date: admin.firestore.Timestamp.now(),
            // // trigger ad card completed function
            // acc: admin.firestore.FieldValue.increment(1),
            readyToComplete: true,
          });
        promises.push(pr5);
      });
      notCompletedAdCardIds.forEach((adCardID) => {
        const pr7 = admin
          .firestore()
          .collection("AdCardTemp")
          .doc(adCardID)
          .update({
            spToRemove: superPathID,
            // trigger removeCarModel function
            reSpTr: admin.firestore.FieldValue.increment(1),
          });
        promises.push(pr7);
      });
      // NEW
      routeAverageChunks.forEach((routeAverageChunk) => {
        let array = [];
        for (
          let index = 0;
          index < routeAverageChunk.routeaverages.length;
          index++
        ) {
          const routeAverage = routeAverageChunk.routeaverages[index];
          if (routeAverage.sp != superPathID) {
            array.push({
              cm: routeAverage.cm,
              ts: routeAverage.ts,
              sp: routeAverage.sp,
              totalAmountOfRoute: routeAverage.totalAmountOfRoute,
              averageAdBrake: routeAverage.averageAdBrake,
              rfstpd: routeAverage.rfstpd,
              scstpd: routeAverage.scstpd,
              scstppd: routeAverage.scstppd,
            });
          }
        }
        const pr6 = admin
          .firestore()
          .collection("routeAverages")
          .doc(routeAverageChunk.raChunkId)
          .update({
            routeAverages: array,
          });
        promises.push(pr6);
      });
      //
      await Promise.all(promises);
      // trigger this function again
      if (
        routeAverageChunks.length == raChunk ||
        pathIDs.length == pathChunk ||
        adCardIDs.length == adCardChunk
      ) {
        if (
          routeAverageChunks.length > 0 &&
          pathIDs.length > 0 &&
          adCardIDs.length > 0
        ) {
          // let lastRaID = routeAverageChunks[routeAverageChunks.length - 1].raChunkId;
          // let pid = pathIDs[pathIDs.length - 1];
          // let lastAcID = adCardIDs[adCardIDs.length - 1];
        } else if (routeAverageChunks.length > 0 && pathIDs.length > 0) {
          // let lastRaID = routeAverageChunks[routeAverageChunks.length - 1].raChunkId;
          // let pid = pathIDs[pathIDs.length - 1];
        } else if (routeAverageChunks.length > 0 && adCardIDs.length > 0) {
          // let lastRaID = routeAverageChunks[routeAverageChunks.length - 1].raChunkId;
          // let lastAcID = adCardIDs[adCardIDs.length - 1];
        } else if (pathIDs.length > 0 && adCardIDs.length > 0) {
          // let pid = pathIDs[pathIDs.length - 1];
          // let lastAcID = adCardIDs[adCardIDs.length - 1];
        } else if (routeAverageChunks.length > 0) {
          // let lastRaID = routeAverageChunks[routeAverageChunks.length - 1].raChunkId;
        } else if (pathIDs.length > 0) {
          // let pid = pathIDs[pathIDs.length - 1];
        } else if (adCardIDs.length > 0) {
          // let lastAcID = adCardIDs[adCardIDs.length - 1];
        }
      } else {
        // change cmspDeletionFinished in controller to true
      }
      const finalPromise = await Promise.all(promises);
      response.send("The result of the action is : " + finalPromise.length);
    } catch (error) {
      response.send("Err: " + error);
    }
  }
);

// listens to controller for changes in carModelID
// TESTED
export const carModelDelete = functions.https.onRequest(
  async (request, response) => {
    try {
      let promises = [];
      let carModelID = "eGGTsDKqsHyaxVPnON8Q",
        systemAccountId = "vDUgx0686C6tiSIQCTi8",
        lastTvID = "dummyID",
        lastAdID = "dummyID",
        lastRaID = "dummyID";
      let lastTvDoc = admin
        .firestore()
        .collection("transportVehicle")
        .doc(lastTvID);
      let lastAdDoc = admin.firestore().collection("AdCardTemp").doc(lastAdID);
      let lastRaDoc = admin
        .firestore()
        .collection("routeAverages")
        .doc(lastRaID);
      let ltvEx = false,
        ladEx = false,
        laRaEx = false;
      let tvChunk = 200,
        adCardChunk = 200,
        // raChunk has to be much lower than the above
        // chunks as it includes 4500 route averages
        // data in one document
        raChunk = 50;

      // change cmspDeletionFinished in controller to false

      let tvIDs = [],
        // driverIDs = [],
        adCardIDs = [],
        notCompletedAdCardIds = [];
      // NEW
      class RouteAverageChunk {
        raChunkId: string;
        routeaverages: RouteAverage[];
        constructor(raChunkId: string, routeaverages: RouteAverage[]) {
          this.raChunkId = raChunkId;
          this.routeaverages = routeaverages;
        }
      }
      let routeAverageChunks: RouteAverageChunk[] = [];
      //
      if (ltvEx) {
        const pr1 = admin
          .firestore()
          .collection("transportVehicle")
          .where("carModelID", "==", carModelID)
          .orderBy(admin.firestore.FieldPath.documentId())
          .startAfter(lastTvDoc)
          .limit(tvChunk)
          .get()
          .then((tvs) => {
            tvs.forEach((tv) => {
              tvIDs.push(tv.id);
              // driverIDs.push(tv.get("driverID"));
            });
          });
        promises.push(pr1);
      } else {
        const pr1 = admin
          .firestore()
          .collection("transportVehicle")
          .where("carModelID", "==", carModelID)
          .orderBy(admin.firestore.FieldPath.documentId())
          .limit(tvChunk)
          .get()
          .then((tvs) => {
            tvs.forEach((tv) => {
              tvIDs.push(tv.id);
              // driverIDs.push(tv.get("driverID"));
            });
          });
        promises.push(pr1);
      }
      if (ladEx) {
        const pr2 = admin
          .firestore()
          .collection("AdCardTemp")
          .where("completed", "==", false)
          .where("cm", "array-contains", carModelID)
          .orderBy(admin.firestore.FieldPath.documentId())
          .startAfter(lastAdDoc)
          .limit(adCardChunk)
          .get()
          .then((adCards) => {
            adCards.forEach((adCard) => {
              let cm: any[] = adCard.get("cm") as [];
              if (cm.length == 1) {
                adCardIDs.push(adCard.id);
              } else {
                notCompletedAdCardIds.push(adCard.id);
              }
            });
          });
        promises.push(pr2);
      } else {
        const pr2 = admin
          .firestore()
          .collection("AdCardTemp")
          .where("completed", "==", false)
          .where("cm", "array-contains", carModelID)
          .orderBy(admin.firestore.FieldPath.documentId())
          .limit(adCardChunk)
          .get()
          .then((adCards) => {
            adCards.forEach((adCard) => {
              let cm: any[] = adCard.get("cm") as [];
              // console.log("CmLeng: " + cm.length);
              // console.log(cm);
              if (cm.length == 1) {
                adCardIDs.push(adCard.id);
              } else {
                notCompletedAdCardIds.push(adCard.id);
              }
            });
          });
        promises.push(pr2);
      }
      // NEW
      if (laRaEx) {
        let avgRoutePromise = admin
          .firestore()
          .collection("routeAverages")
          .where("systemAccountId", "==", systemAccountId)
          .orderBy(admin.firestore.FieldPath.documentId())
          .startAfter(lastRaDoc)
          .limit(raChunk)
          .get()
          .then((querySnapshot) => {
            querySnapshot.docs.forEach((element) => {
              let averageRoutes: RouteAverage[] = [];
              let ras: any[] = element.get("routeAverages");
              ras.forEach((ra) => {
                let averageRoute = new RouteAverage(
                  ra.cm,
                  ra.ts,
                  ra.sp,
                  ra.totalAmountOfRoute
                );
                averageRoute.scstpd = ra.scstpd;
                averageRoute.scstppd = ra.scstppd;
                averageRoute.rfstpd = ra.rfstpd;
                averageRoute.averageAdBrake = ra.averageAdBrake;
                averageRoutes.push(averageRoute);
              });
              routeAverageChunks.push(
                new RouteAverageChunk(element.id, averageRoutes)
              );
            });
          });
        promises.push(avgRoutePromise);
      } else {
        let avgRoutePromise = admin
          .firestore()
          .collection("routeAverages")
          .where("systemAccountId", "==", systemAccountId)
          .orderBy(admin.firestore.FieldPath.documentId())
          .limit(raChunk)
          .get()
          .then((querySnapshot) => {
            querySnapshot.docs.forEach((element) => {
              let averageRoutes: RouteAverage[] = [];
              let ras: any[] = element.get("routeAverages");
              ras.forEach((ra) => {
                let averageRoute = new RouteAverage(
                  ra.cm,
                  ra.ts,
                  ra.sp,
                  ra.totalAmountOfRoute
                );
                averageRoute.scstpd = ra.scstpd;
                averageRoute.scstppd = ra.scstppd;
                averageRoute.rfstpd = ra.rfstpd;
                averageRoute.averageAdBrake = ra.averageAdBrake;
                averageRoutes.push(averageRoute);
              });
              routeAverageChunks.push(
                new RouteAverageChunk(element.id, averageRoutes)
              );
            });
          });
        promises.push(avgRoutePromise);
      }
      //
      await Promise.all(promises);

      tvIDs.forEach((tvID) => {
        const pr4 = admin
          .firestore()
          .collection("transportVehicle")
          .doc(tvID)
          .update({
            // trigger tvDelete function
            tvDel: admin.firestore.FieldValue.increment(1),
          });
        promises.push(pr4);
      });
      adCardIDs.forEach((adCardID) => {
        const pr5 = admin
          .firestore()
          .collection("AdCardTemp")
          .doc(adCardID)
          .update({
            // completed: true,
            // end_date: admin.firestore.Timestamp.now(),
            // // trigger ad card completed function
            // acc: admin.firestore.FieldValue.increment(1),
            readyToComplete: true,
          });
        promises.push(pr5);
      });
      notCompletedAdCardIds.forEach((adCardID) => {
        const pr7 = admin
          .firestore()
          .collection("AdCardTemp")
          .doc(adCardID)
          .update({
            cmToRemove: carModelID,
            // trigger removeCarModel function
            reCmTr: admin.firestore.FieldValue.increment(1),
          });
        promises.push(pr7);
      });
      // NEW
      routeAverageChunks.forEach((routeAverageChunk) => {
        let array = [];
        for (
          let index = 0;
          index < routeAverageChunk.routeaverages.length;
          index++
        ) {
          const routeAverage = routeAverageChunk.routeaverages[index];
          if (routeAverage.cm != carModelID) {
            array.push({
              cm: routeAverage.cm,
              ts: routeAverage.ts,
              sp: routeAverage.sp,
              totalAmountOfRoute: routeAverage.totalAmountOfRoute,
              averageAdBrake: routeAverage.averageAdBrake,
              rfstpd: routeAverage.rfstpd,
              scstpd: routeAverage.scstpd,
              scstppd: routeAverage.scstppd,
            });
          }
        }
        const pr6 = admin
          .firestore()
          .collection("routeAverages")
          .doc(routeAverageChunk.raChunkId)
          .update({
            routeAverages: array,
          });
        promises.push(pr6);
      });
      //
      await Promise.all(promises);
      // trigger this function again
      if (
        routeAverageChunks.length == raChunk ||
        tvIDs.length == tvChunk ||
        adCardIDs.length == adCardChunk
      ) {
        if (
          routeAverageChunks.length > 0 &&
          tvIDs.length > 0 &&
          adCardIDs.length > 0
        ) {
          // let lastRaID = routeAverageChunks[routeAverageChunks.length - 1].raChunkId;
          // let lastTvID = tvIDs[tvIDs.length - 1];
          // let lastAcID = adCardIDs[adCardIDs.length - 1];
        } else if (routeAverageChunks.length > 0 && tvIDs.length > 0) {
          // let lastRaID = routeAverageChunks[routeAverageChunks.length - 1].raChunkId;
          // let lastTvID = tvIDs[tvIDs.length - 1];
        } else if (routeAverageChunks.length > 0 && adCardIDs.length > 0) {
          // let lastRaID = routeAverageChunks[routeAverageChunks.length - 1].raChunkId;
          // let lastAcID = adCardIDs[adCardIDs.length - 1];
        } else if (tvIDs.length > 0 && adCardIDs.length > 0) {
          // let lastTvID = tvIDs[tvIDs.length - 1];
          // let lastAcID = adCardIDs[adCardIDs.length - 1];
        } else if (routeAverageChunks.length > 0) {
          // let lastRaID = routeAverageChunks[routeAverageChunks.length - 1].raChunkId;
        } else if (tvIDs.length > 0) {
          // let lastTvID = tvIDs[tvIDs.length - 1];
        } else if (adCardIDs.length > 0) {
          // let lastAcID = adCardIDs[adCardIDs.length - 1];
        }
      } else {
        // change cmspDeletionFinished in controller to true
      }
      const finalPromise = await Promise.all(promises);
      response.send("The result of the action is : " + finalPromise.length);
    } catch (error) {
      response.send("Err: " + error);
    }
  }
);

// TESTED
export const removeCarModel = functions.https.onRequest(
  async (request, response) => {
    try {
      let promises = [];
      let adCardID = "zzObgBAi7qwICOCSB84y";
      let cmIDtoRemove = "jv9eucidBRZooQe9h0ov";

      let adCardSetupIds = [];
      const pr1 = admin
        .firestore()
        .collection("adCardSetup")
        .where("adCardID", "==", adCardID)
        .get()
        .then((adCardSetups) => {
          adCardSetups.forEach((adCardSetup) => {
            adCardSetupIds.push(adCardSetup.id);
          });
        });
      promises.push(pr1);
      await Promise.all(promises);
      // const pr2 = admin
      //   .firestore()
      //   .collection("AdCardTemp")
      //   .doc(adCardID)
      //   .update({
      //     cmToRemove: "",
      //   });
      // promises.push(pr2);
      adCardSetupIds.forEach((adCardSetupID) => {
        const pr3 = admin
          .firestore()
          .collection("adCardSetup")
          .doc(adCardSetupID)
          .update({
            cm: admin.firestore.FieldValue.arrayRemove(cmIDtoRemove),
          });
        promises.push(pr3);
      });
      const finalPromise = await Promise.all(promises);
      response.send("The result of the action is : " + finalPromise.length);
    } catch (error) {
      response.send("Err: " + error);
    }
  }
);

// TESTED
export const removeSuperPath = functions.https.onRequest(
  async (request, response) => {
    try {
      let promises = [];
      let adCardID = "zzObgBAi7qwICOCSB84y";
      let spIDtoRemove = "PH3sALEFw6EBHO9FjDK5";

      let adCardSetupIds = [];
      const pr1 = admin
        .firestore()
        .collection("adCardSetup")
        .where("adCardID", "==", adCardID)
        .get()
        .then((adCardSetups) => {
          adCardSetups.forEach((adCardSetup) => {
            adCardSetupIds.push(adCardSetup.id);
          });
        });
      promises.push(pr1);
      await Promise.all(promises);
      // const pr2 = admin
      //   .firestore()
      //   .collection("AdCardTemp")
      //   .doc(adCardID)
      //   .update({
      //     spToRemove: "",
      //   });
      // promises.push(pr2);
      adCardSetupIds.forEach((adCardSetupID) => {
        const pr3 = admin
          .firestore()
          .collection("adCardSetup")
          .doc(adCardSetupID)
          .update({
            sp: admin.firestore.FieldValue.arrayRemove(spIDtoRemove),
          });
        promises.push(pr3);
      });
      const finalPromise = await Promise.all(promises);
      response.send("The result of the action is : " + finalPromise.length);
    } catch (error) {
      response.send("Err: " + error);
    }
  }
);

// TESTED
// listens to tv document
export const tvDelete = functions.https.onRequest(async (request, response) => {
  try {
    let promises = [];
    let tvID = "8ur6VNmeL8uxvmo4X5Vj",
      driverID = "URabyddO1vV3zSKxF5yp",
      lastTvAdID = "dummyID";
    let tvAdChunk = 200;
    let lastTvAdDocExist = false;
    let lastTvAdDoc = admin.firestore().collection("tvAD").doc(lastTvAdID);

    let tvAdIds = [];
    if (lastTvAdDocExist) {
      const pr1 = admin
        .firestore()
        .collection("tvAD")
        .where("tvID", "==", tvID)
        .orderBy(admin.firestore.FieldPath.documentId())
        .startAfter(lastTvAdDoc)
        .limit(tvAdChunk)
        .get()
        .then((tvAds) => {
          tvAds.forEach((tvAd) => {
            tvAdIds.push(tvAd.id);
          });
        });
      promises.push(pr1);
    } else {
      const pr1 = admin
        .firestore()
        .collection("tvAD")
        .where("tvID", "==", tvID)
        .orderBy(admin.firestore.FieldPath.documentId())
        .limit(tvAdChunk)
        .get()
        .then((tvAds) => {
          tvAds.forEach((tvAd) => {
            tvAdIds.push(tvAd.id);
          });
        });
      promises.push(pr1);
    }
    await Promise.all(promises);
    tvAdIds.forEach((tvAdId) => {
      const pr2 = admin.firestore().collection("tvAD").doc(tvAdId).delete();
      promises.push(pr2);
    });
    await Promise.all(promises);
    // trigger tvDelete (this function) again
    if (tvAdIds.length == tvAdChunk) {
      const pr3 = admin
        .firestore()
        .collection("transportVehicle")
        .doc(tvID)
        .update({
          lastDocID: tvAdIds[tvAdIds.length - 1],
          // trigger tvDelete function
          tvDel: admin.firestore.FieldValue.increment(1),
        });
      promises.push(pr3);
    } else {
      const pr4 = admin
        .firestore()
        .collection("transportVehicle")
        .doc(tvID)
        .delete();
      promises.push(pr4);
      const pr5 = admin.firestore().collection("driver").doc(driverID).update({
        plateNumber: "",
        status: false,
      });
      promises.push(pr5);
    }
    const finalPromise = await Promise.all(promises);
    response.send("The result of the action is : " + finalPromise.length);
  } catch (error) {
    response.send("Err: " + error);
  }
});

// TESTED
// expected: old timeSlot documents are deleted
export const timeSlotsDelete = functions.https.onRequest(
  async (request, response) => {
    try {
      let promises = [];
      let systemAccountID = "ta",
        lastRaID = "dummyID",
        lastAdCardID = "dummyID";
      let raChunk = 200,
        adCardChunk = 200;
      let lastAdCardDocExist = false,
        lastRaDocExist = false;
      let lastRaDoc = firestore().collection("routeAverages").doc(lastRaID);
      let lastAdCardDoc = firestore()
        .collection("AdCardTemp")
        .doc(lastAdCardID);

      let raIds = [],
        adCardIds = [];
      if (lastRaDocExist) {
        const pr1 = admin
          .firestore()
          .collection("routeAverages")
          .where("systemAccountId", "==", systemAccountID)
          .orderBy(admin.firestore.FieldPath.documentId())
          .startAfter(lastRaDoc)
          .limit(raChunk)
          .get()
          .then((routeAverages) => {
            routeAverages.forEach((routeAverage) => {
              raIds.push(routeAverage.id);
            });
          });
        promises.push(pr1);
      } else {
        const pr1 = admin
          .firestore()
          .collection("routeAverages")
          .where("systemAccountId", "==", systemAccountID)
          .orderBy(admin.firestore.FieldPath.documentId())
          .limit(raChunk)
          .get()
          .then((routeAverages) => {
            routeAverages.forEach((routeAverage) => {
              raIds.push(routeAverage.id);
            });
          });
        promises.push(pr1);
      }
      if (lastAdCardDocExist) {
        const pr2 = admin
          .firestore()
          .collection("AdCardTemp")
          .where("systemAccountID", "==", systemAccountID)
          .orderBy(admin.firestore.FieldPath.documentId())
          .startAfter(lastAdCardDoc)
          .limit(adCardChunk)
          .get()
          .then((adCards) => {
            adCards.forEach((adCard) => {
              adCardIds.push(adCard.id);
            });
          });
        promises.push(pr2);
      } else {
        const pr2 = admin
          .firestore()
          .collection("AdCardTemp")
          .where("systemAccountID", "==", systemAccountID)
          .orderBy(admin.firestore.FieldPath.documentId())
          .limit(adCardChunk)
          .get()
          .then((adCards) => {
            adCards.forEach((adCard) => {
              adCardIds.push(adCard.id);
            });
          });
        promises.push(pr2);
      }
      await Promise.all(promises);
      raIds.forEach((raID) => {
        const pr3 = admin
          .firestore()
          .collection("routeAverages")
          .doc(raID)
          .delete();
        promises.push(pr3);
      });
      adCardIds.forEach((adCardID) => {
        const pr4 = admin
          .firestore()
          .collection("AdCardTemp")
          .doc(adCardID)
          .update({
            // completed: true,
            // end_date: admin.firestore.Timestamp.now(),
            // // trigger ad card completed function
            // acc: admin.firestore.FieldValue.increment(1),
            readyToComplete: true,
          });
        promises.push(pr4);
      });
      await Promise.all(promises);
      if (raIds.length == raChunk || adCardIds.length == adCardChunk) {
        if (raIds.length > 0 && adCardIds.length > 0) {
          // let lastRaDocID = raIds[raIds.length - 1];
          // let lastAdCardDocID = adCardIds[adCardIds.length - 1];
        } else if (adCardIds.length > 0) {
          // let lastAdCardDocID = adCardIds[adCardIds.length - 1];
        } else if (raIds.length > 0) {
          // let lastRaDocID = raIds[raIds.length - 1];
        }
        // trigger timeSlotDelete(this function) again
      } else {
        // mark as finished (by assinging timeSlotDeleteMonitor variable a value of 4) when this
        // function finish. So dagim can create new timeslots and routeAverages. When dagim tiggers
        // this he should assign timeSlotDeleteMonitor variable a value of 2 so he can wait until it
        // becomes 4(which means this function finished).
      }
      const finalPromise = await Promise.all(promises);
      response.send("The result of the action is : " + finalPromise.length);
    } catch (error) {
      response.send("Err: " + error);
    }
  }
);

// TESTED
// listens to controller
export const priceChange = functions.https.onRequest(
  async (request, response) => {
    try {
      let promises = [];
      let systemAccountID = "vDUgx0686C6tiSIQCTi8",
        lastDocID = "dummyID";
      let adCardSetChunk = 200;
      let lastDoc = admin.firestore().collection("adCardSetup").doc(lastDocID);
      let lastDocExist = false;

      // update priceChangeFinished to false

      // let valueMap: Map<string, number> = after.valueMap;

      let valueMap: Map<string, number> = new Map();
      let cmReadPromise = admin
        .firestore()
        .collection("carModel")
        .where("systemAccountId", "==", systemAccountID)
        .get()
        .then(async (querySnapshot) => {
          querySnapshot.docs.forEach((element) => {
            // the value is percent in variables below
            valueMap.set(element.id + "c", element.get("percentage"));
          });
        });
      promises.push(cmReadPromise);
      let tsReadPromise = admin
        .firestore()
        .collection("timeSlot")
        .where("systemAccountId", "==", systemAccountID)
        .get()
        .then(async (querySnapshot) => {
          querySnapshot.docs.forEach((element) => {
            // the value is percent in variables below
            valueMap.set(element.id + "t", element.get("percentage"));
          });
        });
      promises.push(tsReadPromise);
      let spReadPromise = admin
        .firestore()
        .collection("superPath")
        .where("systemAccountId", "==", systemAccountID)
        .get()
        .then(async (querySnapshot) => {
          querySnapshot.docs.forEach((element) => {
            valueMap.set(element.id + "s", element.get("price"));
          });
        });
      promises.push(spReadPromise);

      let listOfAdCardVal: AdCard[] = [];
      if (lastDocExist) {
        const readPromise = admin
          .firestore()
          .collection("adCardSetup")
          .where("systemAccountId", "==", systemAccountID)
          .where("completed", "==", false)
          .orderBy(admin.firestore.FieldPath.documentId())
          .startAfter(lastDoc)
          .limit(adCardSetChunk)
          .get()
          .then(async (querySnapshot) => {
            querySnapshot.docs.forEach(async (element) => {
              var cm = element.get("cm");
              var ts = element.get("ts");
              var sp = element.get("sp");
              let cms: string[] = [];
              let tss: string[] = [];
              let sps: string[] = [];

              cm.forEach((element) => {
                cms.push(element);
              });
              ts.forEach((element) => {
                tss.push(element);
              });
              sp.forEach((element) => {
                sps.push(element);
              });
              listOfAdCardVal.push(
                new AdCard(
                  element.id,
                  element.get("length"),
                  element.get("frequency_per_route"),
                  cms,
                  tss,
                  sps,
                  element.get("adCardBalance"),
                  // date value not useful for this function
                  new Date(),
                  new Date(),
                  new Date()
                )
              );
            });
          });
        promises.push(readPromise);
      } else {
        const readPromise = admin
          .firestore()
          .collection("adCardSetup")
          .where("systemAccountId", "==", systemAccountID)
          .where("completed", "==", false)
          .orderBy(admin.firestore.FieldPath.documentId())
          .limit(adCardSetChunk)
          .get()
          .then(async (querySnapshot) => {
            querySnapshot.docs.forEach(async (element) => {
              var cm = element.get("cm");
              var ts = element.get("ts");
              var sp = element.get("sp");
              let cms: string[] = [];
              let tss: string[] = [];
              let sps: string[] = [];

              cm.forEach((element) => {
                cms.push(element);
              });
              ts.forEach((element) => {
                tss.push(element);
              });
              sp.forEach((element) => {
                sps.push(element);
              });
              listOfAdCardVal.push(
                new AdCard(
                  element.id,
                  element.get("length"),
                  element.get("frequency_per_route"),
                  cms,
                  tss,
                  sps,
                  element.get("adCardBalance"),
                  // date value not useful for this function
                  new Date(),
                  new Date(),
                  new Date()
                )
              );
            });
          });
        promises.push(readPromise);
      }
      await Promise.all(promises);
      listOfAdCardVal = frequencyAssigner(valueMap, listOfAdCardVal);
      listOfAdCardVal.forEach((adCardval) => {
        // console.log("adCardVal: " + adCardval.name);
        const pr1 = admin
          .firestore()
          .collection("adCardSetup")
          .doc(adCardval.name)
          .update({
            availableSetups: adCardval.availableSetups,
          });
        promises.push(pr1);
      });
      await Promise.all(promises);
      // trigger priceChange(this function) again
      if (listOfAdCardVal.length == adCardSetChunk) {
        // assign last doc used to startAfter in the
        // next invocation of this function
        // let lastDocID = listOfAdCardVal[listOfAdCardVal.length - 1];
      } else {
        // update priceChangeFinished to true
      }
      const finalPromise = await Promise.all(promises);
      response.send("The result of the action is : " + finalPromise.length);
    } catch (error) {
      response.send("Err: " + error);
    }
  }
);

// TESTED
export const percentageLimiterChange = functions.https.onRequest(
  async (request, response) => {
    try {
      let promises = [];
      let systemAccountID = "vDUgx0686C6tiSIQCTi8";
      let newPercentageLimiter = 70;
      let maximumAllowedForCm = 100 - newPercentageLimiter;

      let cmIds = [];
      let cmReadPromise = admin
        .firestore()
        .collection("carModel")
        .where("systemAccountId", "==", systemAccountID)
        .get()
        .then(async (querySnapshot) => {
          querySnapshot.docs.forEach((element) => {
            let percent = element.get("percentage");
            if (percent > maximumAllowedForCm) {
              cmIds.push(element.id);
            }
          });
        });
      promises.push(cmReadPromise);
      let tsIds = [];
      let tsReadPromise = admin
        .firestore()
        .collection("timeSlot")
        .where("systemAccountId", "==", systemAccountID)
        .get()
        .then(async (querySnapshot) => {
          querySnapshot.docs.forEach((element) => {
            let percent = element.get("percentage");
            if (percent > newPercentageLimiter) {
              tsIds.push(element.id);
            }
          });
        });
      promises.push(tsReadPromise);
      await Promise.all(promises);
      cmIds.forEach((cmID) => {
        const pr1 = admin.firestore().collection("carModel").doc(cmID).update({
          percentage: maximumAllowedForCm,
        });
        promises.push(pr1);
      });
      tsIds.forEach((tsId) => {
        const pr2 = admin.firestore().collection("timeSlot").doc(tsId).update({
          percentage: newPercentageLimiter,
        });
        promises.push(pr2);
      });
      const finalPromise = await Promise.all(promises);
      response.send("The result of the action is : " + finalPromise.length);
    } catch (error) {
      response.send("Err: " + error);
    }
  }
);

// triggered everytime cm created, updated or deleted
// TESTED
export const cmChange = functions.https.onRequest(async (request, response) => {
  try {
    let promises = [];
    const transactionReturn = await admin
      .firestore()
      .runTransaction(async (trans: admin.firestore.Transaction) => {
        let cmID = "cmTest",
          systemAccountId = "vDUgx0686C6tiSIQCTi8";
        let percentage = 35;
        let mapValue: Map<string, number> = new Map<string, number>();
        let newMap = {};
        let controllerID = "";
        let type = 0; // o is create/update while 1 is delete
        let controller = await trans.get(
          admin
            .firestore()
            .collection("controller")
            .where("systemAccountId", "==", systemAccountId)
        );
        mapValue = controller.docs[0].get("valueMap") as Map<string, number>;
        controllerID = controller.docs[0].id;
        for (let [key, value] of Object.entries(mapValue)) {
          newMap[key] = value;
        }
        console.log(mapValue);
        if (type == 0) {
          newMap[cmID + "c"] = percentage;
        } else {
          removeKeyStartsWith(newMap, cmID + "c");
        }
        const pr2 = trans.update(
          admin.firestore().collection("controller").doc(controllerID),
          {
            valueMap: newMap,
          }
        );
        promises.push(pr2);
        return await Promise.all(promises);
      });
    response.send("The result of the action is : " + transactionReturn);
  } catch (error) {
    response.send("Err: " + error);
  }
});

// triggered everytime ts created, updated or deleted
// TESTED
export const tsChange = functions.https.onRequest(async (request, response) => {
  try {
    let promises = [];
    const transactionReturn = await admin
      .firestore()
      .runTransaction(async (trans: admin.firestore.Transaction) => {
        let tsID = "tsTest",
          systemAccountId = "vDUgx0686C6tiSIQCTi8";
        let percentage = 45;
        let mapValue: Map<string, number> = new Map<string, number>();
        let newMap = {};
        let controllerID = "";
        let type = 0; // o is create/update while 1 is delete
        let controller = await trans.get(
          admin
            .firestore()
            .collection("controller")
            .where("systemAccountId", "==", systemAccountId)
        );
        mapValue = controller.docs[0].get("valueMap") as Map<string, number>;
        controllerID = controller.docs[0].id;
        for (let [key, value] of Object.entries(mapValue)) {
          newMap[key] = value;
        }
        console.log(mapValue);
        if (type == 0) {
          newMap[tsID + "t"] = percentage;
        } else {
          removeKeyStartsWith(newMap, tsID + "t");
        }
        const pr2 = trans.update(
          admin.firestore().collection("controller").doc(controllerID),
          {
            valueMap: newMap,
          }
        );
        promises.push(pr2);
        return await Promise.all(promises);
      });
    response.send("The result of the action is : " + transactionReturn);
  } catch (error) {
    response.send("Err: " + error);
  }
});

// triggered everytime sp created, updated or deleted
// TESTED
export const spChange = functions.https.onRequest(async (request, response) => {
  try {
    let promises = [];
    const transactionReturn = await admin
      .firestore()
      .runTransaction(async (trans: admin.firestore.Transaction) => {
        let spID = "spTest",
          systemAccountId = "vDUgx0686C6tiSIQCTi8";
        let price = 0.45;
        let mapValue: Map<string, number> = new Map<string, number>();
        let newMap = {};
        let controllerID = "";
        let type = 1; // o is create/update while 1 is delete
        let controller = await trans.get(
          admin
            .firestore()
            .collection("controller")
            .where("systemAccountId", "==", systemAccountId)
        );
        mapValue = controller.docs[0].get("valueMap") as Map<string, number>;
        controllerID = controller.docs[0].id;
        for (let [key, value] of Object.entries(mapValue)) {
          newMap[key] = value;
        }
        console.log(mapValue);
        if (type == 0) {
          newMap[spID + "s"] = price;
        } else {
          removeKeyStartsWith(newMap, spID + "s");
        }
        const pr2 = trans.update(
          admin.firestore().collection("controller").doc(controllerID),
          {
            valueMap: newMap,
          }
        );
        promises.push(pr2);
        return await Promise.all(promises);
      });
    response.send("The result of the action is : " + transactionReturn);
  } catch (error) {
    response.send("Err: " + error);
  }
});

// TESTED
export const createReportData = functions.https.onRequest(
  async (request, response) => {
    try {
      let promises = [];
      let one_day = 24 * 60 * 60 * 1000;
      let systemAccountId = "vDUgx0686C6tiSIQCTi8";
      let timeZoneName, timeZoneOffset;
      await admin
        .firestore()
        .collection("systemRequirementAccount")
        .doc(systemAccountId)
        .get()
        .then((sysReqAcc) => {
          timeZoneOffset = -sysReqAcc.get("timeZoneOffset");
          timeZoneName = sysReqAcc.get("timeZoneName");
        });
      let hours = Math.floor(timeZoneOffset / 60);
      let minutes = timeZoneOffset % 60;

      class RouteClass {
        tsId: string;
        spId: string;
        // startTime: Date;
        // endTime: Date;
        numberOfAdServed: number;
        numberOfAvailableAds: number;
        failed: boolean;
        profit: number;
        constructor(
          tsId: string,
          spId: string,
          // startTime: Date,
          // endTime: Date,
          numberOfAdServed: number,
          numberOfAvailableAds: number,
          failed: boolean,
          profit: number
        ) {
          this.tsId = tsId;
          // this.startTime = startTime;
          // this.endTime = endTime;
          this.numberOfAdServed = numberOfAdServed;
          this.numberOfAvailableAds = numberOfAvailableAds;
          this.failed = failed;
          this.profit = profit;
          this.spId = spId;
        }
      }
      class TimeSlotClass {
        tsId: string;
        startTime: Date;
        endTime: Date;
        numberOfAdServed: number = 0;
        numberOfAvailableAdSpots: number = 0;
        numberOfFailedRoute: number = 0;
        numberOfSuccessfullRoute: number = 0;
        totalProfit: number = 0;
        constructor(tsId: string, startTime: Date, endTime: Date) {
          this.tsId = tsId;
          this.startTime = startTime;
          this.endTime = endTime;
        }
      }
      class SuperPathClass {
        spId: string;
        destination: string;
        numberOfAdServed: number = 0;
        numberOfAvailableAdSpots: number = 0;
        numberOfFailedRoute: number = 0;
        numberOfSuccessfullRoute: number = 0;
        totalProfit: number = 0;
        constructor(spId: string, destination: string) {
          this.spId = spId;
          this.destination = destination;
        }
      }

      let routeClasses: RouteClass[] = [];
      let timeSlotClasses: TimeSlotClass[] = [],
        superPathClasses: SuperPathClass[] = [];
      let currentDate: Date = new Date();
      currentDate = convertTZ(currentDate, timeZoneName);
      currentDate.setUTCMonth(currentDate.getMonth());
      currentDate.setUTCDate(currentDate.getDate());
      currentDate.setUTCHours(hours, minutes, 0, 0);
      let yesterday = new Date(currentDate.getTime() - one_day);
      console.log("Cd: " + currentDate + " yesterday: " + yesterday);
      const pr1 = admin
        .firestore()
        .collection("routeTest1")
        .where("systemAccountId", "==", systemAccountId)
        .where("startTime", ">=", firestore.Timestamp.fromDate(yesterday))
        .get()
        .then((routes) => {
          routes.docs.forEach((route) => {
            let imageStatus = route.get("imageStatus");
            let failed = imageStatus == 2;
            routeClasses.push(
              new RouteClass(
                route.get("ts"),
                route.get("sp"),
                route.get("numberOfAdServed"),
                route.get("numberOfAvailableAds"),
                failed,
                route.get("profit")
              )
            );
          });
        });
      promises.push(pr1);
      const pr2 = admin
        .firestore()
        .collection("timeSlot")
        .where("systemAccountId", "==", systemAccountId)
        .get()
        .then((timeSlots) => {
          timeSlots.docs.forEach((timeSlot) => {
            timeSlotClasses.push(
              new TimeSlotClass(
                timeSlot.id,
                timeSlot.get("startTime").toDate(),
                timeSlot.get("endTime").toDate()
              )
            );
          });
        });
      promises.push(pr2);
      const pr3 = admin
        .firestore()
        .collection("superPath")
        .where("systemAccountId", "==", systemAccountId)
        .get()
        .then((superPaths) => {
          superPaths.docs.forEach((superPath) => {
            superPathClasses.push(
              new SuperPathClass(superPath.id, superPath.get("destination"))
            );
          });
        });
      promises.push(pr3);
      await Promise.all(promises);
      let timeSlotArrays = [],
        superPathArrays = [];
      timeSlotClasses.forEach((timeSlotClass) => {
        routeClasses.forEach((routeClass) => {
          if (timeSlotClass.tsId == routeClass.tsId) {
            timeSlotClass.numberOfAdServed += routeClass.numberOfAdServed;
            timeSlotClass.numberOfAvailableAdSpots +=
              routeClass.numberOfAvailableAds;
            if (routeClass.failed) {
              timeSlotClass.numberOfFailedRoute += 1;
            } else {
              timeSlotClass.numberOfSuccessfullRoute += 1;
            }
            timeSlotClass.totalProfit += routeClass.profit;
          }
        });
        timeSlotArrays.push({
          startTime: firestore.Timestamp.fromDate(timeSlotClass.startTime),
          endTime: firestore.Timestamp.fromDate(timeSlotClass.endTime),
          numberOfAdServed: timeSlotClass.numberOfAdServed,
          numberOfAvailableAdSpots: timeSlotClass.numberOfAvailableAdSpots,
          numberOfFailedRoutes: timeSlotClass.numberOfFailedRoute,
          numberOfSuccessfullRoutes: timeSlotClass.numberOfSuccessfullRoute,
          totalProfit: timeSlotClass.totalProfit,
        });
      });
      superPathClasses.forEach((superPathClass) => {
        routeClasses.forEach((routeClass) => {
          if (superPathClass.spId == routeClass.spId) {
            superPathClass.numberOfAdServed += routeClass.numberOfAdServed;
            superPathClass.numberOfAvailableAdSpots +=
              routeClass.numberOfAvailableAds;
            if (routeClass.failed) {
              superPathClass.numberOfFailedRoute += 1;
            } else {
              superPathClass.numberOfSuccessfullRoute += 1;
            }
            superPathClass.totalProfit += routeClass.profit;
          }
        });
        superPathArrays.push({
          destination: superPathClass.destination,
          numberOfAdServed: superPathClass.numberOfAdServed,
          numberOfAvailableAdSpots: superPathClass.numberOfAvailableAdSpots,
          numberOfFailedRoutes: superPathClass.numberOfFailedRoute,
          numberOfSuccessfullRoutes: superPathClass.numberOfSuccessfullRoute,
          totalProfit: superPathClass.totalProfit,
        });
      });
      const pr4 = admin
        .firestore()
        .collection("timeSlotReportData")
        .doc()
        .create({
          date: firestore.Timestamp.fromDate(yesterday),
          timeSlots: timeSlotArrays,
          systemAccountId: systemAccountId,
        });
      promises.push(pr4);
      const pr5 = admin
        .firestore()
        .collection("superPathReportData")
        .doc()
        .create({
          date: firestore.Timestamp.fromDate(yesterday),
          superPaths: superPathArrays,
          systemAccountId: systemAccountId,
        });
      promises.push(pr5);
      // superPathClasses.forEach((superPathClass) => {
      //   const pr5 = admin
      //     .firestore()
      //     .collection("superPathReportData")
      //     .doc()
      //     .create({
      //       date: firestore.Timestamp.fromDate(yesterday),
      //       destination: superPathClass.destination,
      //       numberOfAdServed: superPathClass.numberOfAdServed,
      //       numberOfAvailableAdSpots: superPathClass.numberOfAvailableAdSpots,
      //       numberOfFailedRoutes: superPathClass.numberOfFailedRoute,
      //       numberOfSuccessfullRoutes: superPathClass.numberOfSuccessfullRoute,
      //       totalProfit: superPathClass.totalProfit,
      //       systemAccountId: systemAccountId,
      //     });
      //   promises.push(pr5);
      // });
      const finalPromise = await Promise.all(promises);
      response.send("The result of the action is : " + finalPromise.length);
    } catch (error) {
      response.send("Err: " + error);
    }
  }
);

// TESTED
// should listen to systemRequirementAccount thirtyMinuteCheck field
export const thirtyMinuteCheck = functions.https.onRequest(
  async (request, response) => {
    try {
      let promises = [];
      let one_day = 24 * 60 * 60 * 1000;
      let systemAccountID = "vDUgx0686C6tiSIQCTi8";
      let timeZoneName, timeZoneOffset, ractDays, actDays;
      await admin
        .firestore()
        .collection("systemRequirementAccount")
        .doc(systemAccountID)
        .get()
        .then((sysReqAcc) => {
          timeZoneOffset = -sysReqAcc.get("timeZoneOffset");
          timeZoneName = sysReqAcc.get("timeZoneName");
          ractDays = sysReqAcc.get("ractDays");
          actDays = sysReqAcc.get("actDays");
        });
      let hours = Math.floor(timeZoneOffset / 60);
      let minutes = timeZoneOffset % 60;

      // trigger lateReportInitial
      let currentDate: Date = new Date();
      currentDate = convertTZ(currentDate, timeZoneName);
      if (currentDate.getHours() == 2) {
        // trigger dailyAdCardChecker
        // trigger cleanAudioFiles
      }
      if (currentDate.getHours() == 3) {
        // trigger timeSlotUpdater
        // check raip and asip
        const pr5 = admin
          .firestore()
          .collection("controller")
          .where("systemAccountId", "==", systemAccountID)
          .limit(1)
          .get()
          .then((controller) => {
            let raipDate: admin.firestore.Timestamp =
              controller.docs[0].get("raipDate");
            let asipDate: admin.firestore.Timestamp =
              controller.docs[0].get("asipDate");
            let raipAddedDate = new Date(
              raipDate.toMillis() + ractDays * one_day
            );
            let asipAddedDate = new Date(
              asipDate.toMillis() + actDays * one_day
            );
            let timeAdjustedCurrentDate = new Date(currentDate.getTime());
            timeAdjustedCurrentDate = convertTZ(
              timeAdjustedCurrentDate,
              timeZoneName
            );
            timeAdjustedCurrentDate.setUTCMonth(
              timeAdjustedCurrentDate.getMonth()
            );
            timeAdjustedCurrentDate.setUTCDate(
              timeAdjustedCurrentDate.getDate()
            );
            timeAdjustedCurrentDate.setUTCHours(hours, minutes, 0, 0);
            raipAddedDate = convertTZ(raipAddedDate, timeZoneName);
            raipAddedDate.setUTCMonth(raipAddedDate.getMonth());
            raipAddedDate.setUTCDate(raipAddedDate.getDate());
            raipAddedDate.setUTCHours(hours, minutes, 0, 0);
            asipAddedDate = convertTZ(asipAddedDate, timeZoneName);
            asipAddedDate.setUTCMonth(asipAddedDate.getMonth());
            asipAddedDate.setUTCDate(asipAddedDate.getDate());
            asipAddedDate.setUTCHours(hours, minutes, 0, 0);
            // console.log(
            //   "cd: " +
            //     timeAdjustedCurrentDate +
            //     " rp: " +
            //     raipAddedDate +
            //     " ap: " +
            //     asipAddedDate
            // );
            if (timeAdjustedCurrentDate.getTime() >= raipAddedDate.getTime()) {
              const pr6 = admin
                .firestore()
                .collection("controller")
                .doc(controller.docs[0].id)
                .update({
                  raipController: admin.firestore.FieldValue.increment(1),
                });
              promises.push(pr6);
            } else if (
              timeAdjustedCurrentDate.getTime() >= asipAddedDate.getTime()
            ) {
              const pr6 = admin
                .firestore()
                .collection("controller")
                .doc(controller.docs[0].id)
                .update({
                  asipController: admin.firestore.FieldValue.increment(1),
                });
              promises.push(pr6);
            }
          });
        promises.push(pr5);
      }
      if (currentDate.getHours() == 4) {
        // trigger dailyDriverChecker
        // trigger createReportData
      }
      const finalPromise = await Promise.all(promises);
      response.send(
        "The result of the action is : " +
          currentDate.getHours() +
          " fp: " +
          finalPromise.length
      );
    } catch (error) {
      response.send("Err: " + error);
    }
  }
);

// TESTED
// should listen to systemOwner doc schedulerTrigger field
export const schedulerTrigger = functions.https.onRequest(
  async (request, response) => {
    try {
      let promises = [];
      let lastSystemAccountID = "dummyID";
      let lastSystemAccountDocExist = false;
      let lastSystemAccountDoc = admin
        .firestore()
        .collection("systemRequirementAccount")
        .doc(lastSystemAccountID);
      let systemAccountChunk = 200;
      let systemAccountIds = [];

      if (lastSystemAccountDocExist) {
        const pr1 = admin
          .firestore()
          .collection("systemRequirementAccount")
          // .where("deleted", "==", false)
          .orderBy(admin.firestore.FieldPath.documentId())
          .startAfter(lastSystemAccountDoc)
          .limit(systemAccountChunk)
          .get()
          .then((systemAccounts) => {
            systemAccounts.docs.forEach((systemAccount) => {
              systemAccountIds.push(systemAccount.id);
            });
          });
        promises.push(pr1);
      } else {
        const pr1 = admin
          .firestore()
          .collection("systemRequirementAccount")
          // .where("deleted", "==", false)
          .orderBy(admin.firestore.FieldPath.documentId())
          .limit(systemAccountChunk)
          .get()
          .then((systemAccounts) => {
            systemAccounts.docs.forEach((systemAccount) => {
              systemAccountIds.push(systemAccount.id);
            });
          });
        promises.push(pr1);
      }
      await Promise.all(promises);
      systemAccountIds.forEach((systemAccountID) => {
        const pr2 = admin
          .firestore()
          .collection("systemRequirementAccount")
          .doc(systemAccountID)
          .update({
            thirtyMinuteCheck: admin.firestore.FieldValue.increment(1),
          });
        promises.push(pr2);
      });
      if (systemAccountIds.length == systemAccountChunk) {
        if (systemAccountIds.length > 0) {
          // let lastSystemAccountID = systemAccountIds[systemAccountIds.length - 1];
          // trigger schedulerTrigger (this function) again
        } else {
          // trigger schedulerTrigger (this function) again
        }
      }
      const finalPromise = await Promise.all(promises);
      response.send("The result of the action is : " + finalPromise.length);
    } catch (error) {
      response.send("Err: " + error);
    }
  }
);

// TESTED
// needs to be added to onControllerChange
export const cleanAudioFiles = functions
  .runWith({ memory: "1GB", timeoutSeconds: 60 })
  .https.onRequest(async (request, response) => {
    try {
      let systemAccountID = "vDUgx0686C6tiSIQCTi8";
      let promises = [];
      let audioUrls = [];
      let deleteLimit = 100;
      let triggerAgain = false;
      let newArray = [];
      let audioFileTrashID = "";
      let pr1 = admin
        .firestore()
        .collection("audioFilesTrash")
        .where("systemAccountId", "==", systemAccountID)
        .limit(1)
        .get()
        .then((afts) => {
          audioFileTrashID = afts.docs[0].id;
          afts.forEach((aft) => {
            if (aft.get("array").length > deleteLimit) {
              triggerAgain = true;
            }
            newArray = newArray.concat(aft.get("array"));
            let deleteAmount = 0;
            // console.log("NEaRR: " + newArray.length);
            for (let index = 0; index < aft.get("array").length; index++) {
              const audioUrl = aft.get("array")[index];
              if (index < deleteLimit) {
                audioUrls.push(audioUrl);
                deleteAmount++;
                // console.log("DeleteAmount: " + deleteAmount);
              } else {
                break;
              }
            }
            newArray.splice(0, deleteAmount);
          });
        });
      promises.push(pr1);
      await Promise.all(promises);
      const bucket = admin.storage().bucket();
      audioUrls.forEach((audioUrl) => {
        let split: string[] = audioUrl.split("o/");
        let split1 = split[1].split("?");
        let path = split1[0];
        path = decodeURIComponent(path);
        // console.log("Path: " + path);
        const pr7 = bucket.file(path).delete();
        promises.push(pr7);
      });
      let pr2 = admin
        .firestore()
        .collection("audioFilesTrash")
        .doc(audioFileTrashID)
        .update({
          array: newArray,
        });
      promises.push(pr2);
      await Promise.all(promises);
      if (triggerAgain) {
        // triggerAgain
        // console.log("Trigger Again: " + triggerAgain);
      }
      const finalPromise = await Promise.all(promises);
      response.send("The result of the action is : " + finalPromise.length);
    } catch (error) {
      response.send("Err: " + error);
    }
  });

export const tf3 = functions
  .runWith({ memory: "2GB", timeoutSeconds: 200 })
  .https.onRequest(async (request, response) => {
    try {
      let lastDoc = admin
        .firestore()
        .collection("routeTest1")
        .doc("h8nJ4HbrRmATaZdTIcTY");
      let promises = [];
      let amount = 0;
      const pr1 = admin
        .firestore()
        .collection("routeTest1")
        .orderBy(admin.firestore.FieldPath.documentId())
        .startAfter(lastDoc)
        .get()
        .then((value) => {
          amount = value.docs.length;
          console.log(
            "First: " +
              value.docs[0].id +
              " Last " +
              value.docs[value.docs.length - 1].id
          );
        });
      promises.push(pr1);
      const finalPromise = await Promise.all(promises);
      response.send(
        "The result of the action is : " + finalPromise.length + " " + amount
      );
    } catch (error) {
      response.send("Err: " + error);
    }
  });

export const tf2 = functions
  .runWith({ memory: "2GB", timeoutSeconds: 200 })
  .https.onRequest(async (request, response) => {
    try {
      let promises = [];
      let systemAccountID = "vDUgx0686C6tiSIQCTi8";
      let adCardSetIds = [],
        adCardTempIds = [];
      let cm: string[] = ["eGGTsDKqsHyaxVPnON8Q", "jv9eucidBRZooQe9h0ov"];
      let ts: string[] = ["8Zx0uUOmjvuf4SX1yWtA", "9EXWua49PX26M15Jy8ao"];
      let sp: string[] = ["PH3sALEFw6EBHO9FjDK5", "YXXiFH1f7ni6l5qNyQK9"];
      const pr1 = admin
        .firestore()
        .collection("AdCardTemp")
        .where("systemAccountID", "==", systemAccountID)
        .get()
        .then((adCardTemps) => {
          adCardTemps.forEach((adCardTemp) => {
            adCardTempIds.push(adCardTemp.id);
          });
        });
      promises.push(pr1);
      await Promise.all(promises);
      adCardTempIds.forEach((adCardTempID) => {
        const pr2 = admin
          .firestore()
          .collection("adCardSetup")
          .where("adCardID", "==", adCardTempID)
          .get()
          .then((adCardSets) => {
            adCardSets.forEach((adCardSet) => {
              adCardSetIds.push(adCardSet.id);
            });
          });
        promises.push(pr2);
      });
      await Promise.all(promises);
      adCardSetIds.forEach((adCardSetID) => {
        const pr3 = admin
          .firestore()
          .collection("adCardSetup")
          .doc(adCardSetID)
          .update({
            completed: false,
            cm: cm,
            ts: ts,
            sp: sp,
          });
        promises.push(pr3);
      });
      const finalPromise = await Promise.all(promises);
      response.send("The result of the action is : " + finalPromise.length);
    } catch (error) {
      response.send("Err: " + error);
    }
  });

export const tf4 = functions.firestore
  .document("systemAccount/{wildCard}")
  .onUpdate(async (change, contex) => {
    try {
      let promises = [];
      const after = change.after.data();
      const before = change.before.data();
      const docID = change.before.id;
      console.log("Data: " + before);
      if (before.sm != after.sm) {
        let counter = 0;
        const pr2 = admin
          .firestore()
          .collection("systemAccount")
          .doc(docID)
          .get()
          .then((val) => {
            counter = val.get("counter");
          });
        promises.push(pr2);
        await Promise.all(promises);
        if (counter < 3) {
          counter++;
          const pr2 = admin
            .firestore()
            .collection("systemAccount")
            .doc(docID)
            .update({
              counter: counter,
              sm: admin.firestore.FieldValue.increment(1),
            });
          promises.push(pr2);
        }
      }
      const promiseValues = await Promise.all(promises);
      console.log("Run");
      return promiseValues;
    } catch (error) {
      console.log("error is : " + error);
      return error;
    }
  });

export const tf5 = functions
  .runWith({ memory: "2GB", timeoutSeconds: 200 })
  .https.onRequest(async (request, response) => {
    try {
      let promises = [];
      let tempTransIds = [],
        routeIds = [];
      const pr1 = admin
        .firestore()
        .collection("routeTest1")
        .get()
        .then((routes) => {
          routes.forEach((route) => {
            routeIds.push(route.id);
          });
        });
      promises.push(pr1);
      const pr2 = admin
        .firestore()
        .collection("tempTransaction")
        .limit(3000)
        .get()
        .then((tempTrans) => {
          tempTrans.forEach((tempTran) => {
            tempTransIds.push(tempTran.id);
          });
        });
      promises.push(pr2);
      await Promise.all(promises);
      console.log(
        "transLeng: " + tempTransIds.length + " routeLeng: " + routeIds.length
      );
      tempTransIds.forEach((transId) => {
        const pr3 = admin
          .firestore()
          .collection("tempTransaction")
          .doc(transId)
          .update({
            tf5: false,
          });
        promises.push(pr3);
      });
      routeIds.forEach((routeID) => {
        const pr3 = admin
          .firestore()
          .collection("routeTest1")
          .doc(routeID)
          .update({
            tf5: false,
          });
        promises.push(pr3);
      });
      const finalPromise = await Promise.all(promises);
      response.send("The result of the action is : " + finalPromise.length);
    } catch (error) {
      response.send("Err: " + error);
    }
  });

export const tf6 = functions
  .runWith({ memory: "2GB", timeoutSeconds: 200 })
  .https.onRequest(async (request, response) => {
    try {
      let promises = [];
      let systemAccountId = "vDUgx0686C6tiSIQCTi8";
      let routeAverages: RouteAverage[] = [];
      const pr1 = admin
        .firestore()
        .collection("routeAverages")
        .where("systemAccountId", "==", systemAccountId)
        .get()
        .then((value) => {
          value.docs.forEach((docSnaps) => {
            let ras: any[] = docSnaps.get("routeAverages");
            ras.forEach((ra) => {
              let averageRoute = new RouteAverage(
                ra.cm,
                ra.ts,
                ra.sp,
                ra.totalAmountOfRoute
              );
              averageRoute.scstpd = ra.scstpd;
              averageRoute.scstppd = ra.scstppd;
              averageRoute.rfstpd = ra.rfstpd;
              averageRoute.averageAdBrake = ra.averageAdBrake;
              routeAverages.push(averageRoute);
            });
          });
        });
      promises.push(pr1);
      await Promise.all(promises);
      routeAverages.forEach((ra) => {
        console.log(ra);
      });
      const finalPromise = await Promise.all(promises);
      response.send("The result of the action is : " + finalPromise.length);
    } catch (error) {
      response.send("Err: " + error);
    }
  });

export const tf7 = functions
  .runWith({ memory: "2GB", timeoutSeconds: 200 })
  .https.onRequest(async (request, response) => {
    try {
      let promises = [];
      let systemAccountId = "vDUgx0686C6tiSIQCTi8",
        superPathID = "YXXiFH1f7ni6l5qNyQK9";
      class RouteAverageChunk {
        raChunkId: string;
        routeaverages: RouteAverage[];
        constructor(raChunkId: string, routeaverages: RouteAverage[]) {
          this.raChunkId = raChunkId;
          this.routeaverages = routeaverages;
        }
      }
      let routeAverageChunks: RouteAverageChunk[] = [];
      let avgRoutePromise = admin
        .firestore()
        .collection("routeAverages")
        .where("systemAccountId", "==", systemAccountId)
        .orderBy(admin.firestore.FieldPath.documentId())
        .get()
        .then((querySnapshot) => {
          querySnapshot.docs.forEach((element) => {
            let averageRoutes: RouteAverage[] = [];
            let ras: any[] = element.get("routeAverages");
            ras.forEach((ra) => {
              let averageRoute = new RouteAverage(
                ra.cm,
                ra.ts,
                ra.sp,
                ra.totalAmountOfRoute
              );
              averageRoute.scstpd = ra.scstpd;
              averageRoute.scstppd = ra.scstppd;
              averageRoute.rfstpd = ra.rfstpd;
              averageRoute.averageAdBrake = ra.averageAdBrake;
              averageRoutes.push(averageRoute);
            });
            routeAverageChunks.push(
              new RouteAverageChunk(element.id, averageRoutes)
            );
          });
        });
      promises.push(avgRoutePromise);
      await Promise.all(promises);
      routeAverageChunks.forEach((routeAverageChunk) => {
        let array = [];
        for (
          let index = 0;
          index < routeAverageChunk.routeaverages.length;
          index++
        ) {
          const routeAverage = routeAverageChunk.routeaverages[index];
          if (routeAverage.sp != superPathID) {
            array.push({
              cm: routeAverage.cm,
              ts: routeAverage.ts,
              sp: routeAverage.sp,
              totalAmountOfRoute: routeAverage.totalAmountOfRoute,
              averageAdBrake: routeAverage.averageAdBrake,
              rfstpd: routeAverage.rfstpd,
              scstpd: routeAverage.scstpd,
              scstppd: routeAverage.scstppd,
            });
          }
        }
        const pr6 = admin
          .firestore()
          .collection("routeAverages")
          .doc(routeAverageChunk.raChunkId)
          .update({
            routeAverages: array,
          });
        promises.push(pr6);
      });
      const finalPromise = await Promise.all(promises);
      response.send("The result of the action is : " + finalPromise.length);
    } catch (error) {
      response.send("Err: " + error);
    }
  });

// TESTED but useful only for test
export const createAdCard = functions
  .runWith({ memory: "2GB", timeoutSeconds: 200 })
  .https.onRequest(async (request, response) => {
    try {
      let cm: string[] = ["eGGTsDKqsHyaxVPnON8Q", "jv9eucidBRZooQe9h0ov"];
      let ts: string[] = ["8Zx0uUOmjvuf4SX1yWtA", "9EXWua49PX26M15Jy8ao"];
      let sp: string[] = ["PH3sALEFw6EBHO9FjDK5", "YXXiFH1f7ni6l5qNyQK9"];
      let adAudioIds: string[] = [
        "3Dyl0rgaiiZDfPWsofus",
        "9aetwgFjUSKwk6HXIvFJ",
        "HY69OxX0o2bbIX7N4Cjp",
        "Hwbu36Z6AbvRjn2WdKy8",
        "LoKIlR8UWjdFFCWdxcEE",
        "MPmGPC6gkzT5Y0RaAcyQ",
        "N2tDCLkh1c16sjflbWy0",
        "NP1ZDzVzLMJx6LL16FWg",
        "RRMopDIF7acB3Pii4sOK",
        "T9zl3s3B4NBo3PaMK5OZ",
        "eldj25LDdIrIOiVcfqgn",
        "jnZaMYtvOmbgV6SroCq2",
        "pCFky8OdpIV8rdwv4A0c",
        "usDH6QNXYCKiTpV4MHv1",
        "xc10LdnY1WWNmdNQajxc",
      ];
      let audioLengths: number[] = [
        2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 2, 1, 2,
      ];
      let listOfAdCard: AdCard[] = generateAdCard(
        adAudioIds.length,
        cm,
        ts,
        sp
      );
      const promises = [];
      let valueMap: Map<string, number> = new Map();
      // the value is percent in variables below
      valueMap.set("eGGTsDKqsHyaxVPnON8Q" + "c", 0);
      valueMap.set("jv9eucidBRZooQe9h0ov" + "c", 20);
      valueMap.set("8Zx0uUOmjvuf4SX1yWtA" + "t", 15);
      valueMap.set("9EXWua49PX26M15Jy8ao" + "t", 0);
      // the value is profit per length (30sec) below
      valueMap.set("PH3sALEFw6EBHO9FjDK5" + "s", 0.75);
      valueMap.set("YXXiFH1f7ni6l5qNyQK9" + "s", 0.68);
      let adCardSetup: AdCard[] = [];
      let counter = 0;
      let idMap = {};
      await listOfAdCard.forEach(async (element) => {
        element.length = audioLengths[counter];
        let adCardsSetups = adSetupCreation(element, 4);
        adCardSetup = adCardSetup.concat(adCardsSetups);
        // let mapAsJson={};
        // element.list_of_frequency.forEach((value:number[],key:string)=>{
        //   mapAsJson[key]=value;
        // });
        const p = admin.firestore().collection("AdCardTemp").doc();
        const pro = p.create({
          name: element.name,
          length: audioLengths[counter],
          // list_of_frequency:mapAsJson,
          frequency_per_route: element.frequency_per_route,
          created_date: element.created_date,
          start_date: element.start_date,
          end_date: element.end_date,
          cm: element.cm,
          ts: element.ts,
          sp: element.sp,
          completed: false,
          adCardBalance: element.adCardBalance,
          adAudioID: adAudioIds[counter],
          // sda:element.sda,
          // aalds:element.aalds,
          // tascpd:element.tascpd
          systemAccountID: "vDUgx0686C6tiSIQCTi8",
        });
        promises.push(pro);
        idMap[element.name] = p.id;
        // console.log("Id: "+idMap[element.name]);
        counter++;
      });
      const promiseValues = await Promise.all(promises);
      let newProm = [];
      adCardSetup = frequencyAssigner(valueMap, adCardSetup);
      for (let j = 0; j < adCardSetup.length; j++) {
        // let mapAsJson={};
        // adCardSetup[j].list_of_frequency.forEach((value:number[],key:string)=>{
        //   mapAsJson[key]=value;
        // });
        // console.log("na "+adCardSetup[j].name+"Id "+idMap[adCardSetup[j].name]);
        const p = admin.firestore().collection("adCardSetup").doc().create({
          adCardID: idMap[adCardSetup[j].name],
          availableSetups: adCardSetup[j].availableSetups,
          activeForDate: true,
          adCardBalance: adCardSetup[j].adCardBalance,
          timeScore: adCardSetup[j].timeScore,
          // "list_of_frequency":mapAsJson,
          length: adCardSetup[j].length,
          frequency_per_route: adCardSetup[j].frequency_per_route,
        });
        newProm.push(p);
      }
      const promVal = await Promise.all(newProm);
      response.send(
        "The result of the action is : " +
          promiseValues.length.toString() +
          " seC " +
          promVal.length
      );
    } catch (error) {
      console.error();
      response.status(500).send("error message : " + error);
    }
  });

// TESTED but useful only for test
export const createRoutes = functions.https.onRequest(
  async (request, response) => {
    try {
      let cm: string[] = ["eGGTsDKqsHyaxVPnON8Q", "jv9eucidBRZooQe9h0ov"];
      let ts: string[] = ["8Zx0uUOmjvuf4SX1yWtA", "9EXWua49PX26M15Jy8ao"];
      let sp: string[] = ["PH3sALEFw6EBHO9FjDK5", "YXXiFH1f7ni6l5qNyQK9"];
      let paths: string[] = ["UTV4kbcGSF6FN3153QK3", "kRFlIlw1NLr2PWSKagNO"];

      let routes: Route[] = [];

      for (let i = 0; i < 70; i++) {
        let cmRandomNum = randomIntFromInterval(0, cm.length - 1);
        let tsRandmNum = randomIntFromInterval(0, ts.length - 1);
        let spRandomNum = randomIntFromInterval(0, sp.length - 1);
        routes.push(
          new Route(
            cm[cmRandomNum],
            ts[tsRandmNum],
            sp[spRandomNum],
            paths[spRandomNum]
          )
        );
      }
      console.log("routes: " + routes.length.toString());

      const promises = [];
      routes.forEach(async (element) => {
        let date = new Date(
          2021,
          randomIntFromInterval(10, 11),
          randomIntFromInterval(1, 24)
        );
        let p = admin
          .firestore()
          .collection("routeTest")
          .doc()
          .create({
            cm: element.cm,
            ts: element.ts,
            sp: element.sp,
            path: element.path,
            systemAccountId: "vDUgx0686C6tiSIQCTi8",
            startTime: admin.firestore.Timestamp.fromDate(date),
          });
        // console.log("date: "+date.toDateString());
        // const p=admin.firestore().collection("routeTest").doc("XYbipQ6HraexFTgutEce").get();
        promises.push(p);
      });
      const promiseValues = await Promise.all(promises);
      response.send(
        "The result of the action is : " + promiseValues.length.toString()
      );
    } catch (error) {
      console.error();
      response.status(500).send("error message : " + error);
    }
  }
);

// TESTED
// MAKE SURE WHEN THESE FUNCTIONS ARE DEPLOYED THEY HAVE THE NECCESSARY MEMORY
// AND DURATION(TIME) TO DO THEIR JOBS PROPERLY CONSIDERING THEY MIGHT NEED
// LARGE TIME AND CLOCKSPEED WHEN WE HAVE MANY AD CARDS AND CHECK IF RETRIES
// ARE ENABLED (MAKE THEM IDOMPOTENT to bullet proof the back end)
export const onControllerChange = functions.firestore
  .document("controller/{wildCard}")
  .onUpdate(async (change, contex) => {
    try {
      const promises = [];
      const after = change.after.data();
      const before = change.before.data();
      // TESTED
      if (after.raipController != before.raipController) {
        let systemAccountID: string = after.systemAccountId; // this will be used to identify the region
        let raipDate: admin.firestore.Timestamp = after.raipDate;

        // NEW
        let timeZoneName, timeZoneOffset;
        //

        let adSpotperAdbrake: number = 8;

        await admin
          .firestore()
          .collection("systemRequirementAccount")
          .doc(systemAccountID)
          .get()
          .then((docSnap) => {
            adSpotperAdbrake = docSnap.get("adBrakeMaximumLength");
            timeZoneName = docSnap.get("timeZoneName");
            timeZoneOffset = -docSnap.get("timeZoneOffset");
          });

        let hours = Math.floor(timeZoneOffset / 60);
        let minutes = timeZoneOffset % 60;

        let paths: Map<string, number> = new Map(); // <string(super path),number(ad break)
        let spReadPromise = admin
          .firestore()
          .collection("path")
          .where("systemAccountId", "==", systemAccountID)
          .get()
          .then(async (querySnapshot) => {
            querySnapshot.docs.forEach((element) => {
              paths.set(element.id, element.get("maximumAmountOfAdBrake"));
            });
          });
        promises.push(spReadPromise);

        let routes: Route[] = [];
        let routeReadPromise = admin
          .firestore()
          .collection("routeTest")
          .where("systemAccountId", "==", systemAccountID)
          .where("startTime", ">", raipDate)
          .get()
          .then((querySnapshot) => {
            querySnapshot.docs.forEach((element) => {
              routes.push(
                new Route(
                  element.get("cm"),
                  element.get("ts"),
                  element.get("sp"),
                  element.get("path")
                  // use this instead of the above
                  // element.get("pathID")
                )
              );
            });
          });
        promises.push(routeReadPromise);

        let one_day = 24 * 60 * 60 * 1000;
        let cd = new Date();
        let rpDate = raipDate.toDate();
        rpDate = convertTZ(rpDate, timeZoneName);
        rpDate.setUTCMonth(rpDate.getMonth());
        rpDate.setUTCDate(rpDate.getDate());
        rpDate.setUTCHours(hours, minutes, 0, 0);
        cd = convertTZ(cd, timeZoneName);
        cd.setUTCMonth(cd.getMonth());
        cd.setUTCDate(cd.getDate());
        cd.setUTCHours(hours, minutes, 0, 0);
        let ractDays: number = cd.getTime() - rpDate.getTime();
        ractDays = Math.floor(ractDays / one_day);

        let deletePromise = admin
          .firestore()
          .collection("routeAverages")
          .where("systemAccountId", "==", systemAccountID)
          .get()
          .then(async (querySnapshot) => {
            querySnapshot.docs.forEach(async (element) => {
              const p = admin
                .firestore()
                .collection("routeAverages")
                .doc(element.id)
                .delete();
              promises.push(p);
            });
          });
        promises.push(deletePromise);
        await Promise.all(promises);

        let averageRoutes: RouteAverage[] = raip(
          routes,
          paths,
          ractDays,
          adSpotperAdbrake
        );
        let currentDate = admin.firestore.Timestamp.now();
        let averageRoutesChunk: RouteAverage[][] = chunk(averageRoutes, 4500);
        averageRoutesChunk.forEach(async (raChunk) => {
          let array = [];
          raChunk.forEach((element) => {
            array.push({
              cm: element.cm,
              ts: element.ts,
              sp: element.sp,
              totalAmountOfRoute: element.totalAmountOfRoute,
              averageAdBrake: element.averageAdBrake,
              rfstpd: element.rfstpd,
              scstpd: element.scstpd,
              scstppd: element.scstppd,
            });
          });
          const p = admin.firestore().collection("routeAverages").doc().create({
            routeAverages: array,
            systemAccountId: systemAccountID,
          });
          promises.push(p);
        });
        await Promise.all(promises);
        // updates the calculation date of the RAIP
        // REMINDER: the deployed function updates controller Doc
        const p = admin
          .firestore()
          .collection("controller")
          .doc(change.after.id)
          .update({
            raipDate: currentDate,
            asipController: admin.firestore.FieldValue.increment(1),
          });
        promises.push(p);
      } // TESTED
      else if (after.asipController != before.asipController) {
        let systemAccountID: string = after.systemAccountId; // this will be used to identify the region

        // let valueMap: Map<string, number> = after.valueMap;

        let valueMap: Map<string, number> = new Map();
        let cmReadPromise = admin
          .firestore()
          .collection("carModel")
          .where("systemAccountId", "==", systemAccountID)
          .get()
          .then(async (querySnapshot) => {
            querySnapshot.docs.forEach((element) => {
              // the value is percent in variables below
              valueMap.set(element.id + "c", element.get("percentage"));
            });
          });
        promises.push(cmReadPromise);
        let tsReadPromise = admin
          .firestore()
          .collection("timeSlot")
          .where("systemAccountId", "==", systemAccountID)
          .get()
          .then(async (querySnapshot) => {
            querySnapshot.docs.forEach((element) => {
              // the value is percent in variables below
              valueMap.set(element.id + "t", element.get("percentage"));
            });
          });
        promises.push(tsReadPromise);

        // let superPath:Map<string,number>=new Map();// <string(super path),number(ad break)
        let spReadPromise = admin
          .firestore()
          .collection("superPath")
          .where("systemAccountId", "==", systemAccountID)
          .get()
          .then(async (querySnapshot) => {
            querySnapshot.docs.forEach((element) => {
              valueMap.set(element.id + "s", element.get("price"));
              // superPath.set(element.id,element.get("averageAdBrake"))
            });
          });
        promises.push(spReadPromise);

        let timeZoneOffset: number;
        let timeZoneName: string;

        await admin
          .firestore()
          .collection("systemRequirementAccount")
          .doc(systemAccountID)
          .get()
          .then((sysReqAcc) => {
            timeZoneOffset = -sysReqAcc.get("timeZoneOffset");
            timeZoneName = sysReqAcc.get("timeZoneName");
          });

        let hours = Math.floor(timeZoneOffset / 60);
        let minutes = timeZoneOffset % 60;

        let listOfAdCardVal: AdCard[] = [];

        const readPromise = admin
          .firestore()
          .collection("AdCardTemp")
          .where("systemAccountID", "==", systemAccountID)
          .where("completed", "==", false)
          .get()
          .then(async (querySnapshot) => {
            querySnapshot.docs.forEach(async (element) => {
              var cm = element.get("cm");
              var ts = element.get("ts");
              var sp = element.get("sp");
              let cms: string[] = [];
              let tss: string[] = [];
              let sps: string[] = [];

              let createdDate = element.get("created_date").toDate();
              let endDate: Date = element.get("end_date").toDate();
              let startDate: Date = element.get("start_date").toDate();

              startDate = convertTZ(startDate, timeZoneName);
              endDate = convertTZ(endDate, timeZoneName);

              startDate.setUTCMonth(startDate.getMonth());
              startDate.setUTCDate(startDate.getDate());
              endDate.setUTCMonth(endDate.getMonth());
              endDate.setUTCDate(endDate.getDate());

              startDate.setUTCHours(hours, minutes, 0, 0);
              endDate.setUTCHours(hours, minutes, 0, 0);

              cm.forEach((element) => {
                cms.push(element);
              });
              ts.forEach((element) => {
                tss.push(element);
              });
              sp.forEach((element) => {
                sps.push(element);
              });
              listOfAdCardVal.push(
                new AdCard(
                  element.id,
                  element.get("length"),
                  element.get("frequency_per_route"),
                  cms,
                  tss,
                  sps,
                  element.get("adCardBalance"),
                  createdDate,
                  startDate,
                  endDate
                )
              );
            });
          });
        promises.push(readPromise);

        // let setupMap:Map<string,[number,number]>=new Map();

        let averageRoutes: RouteAverage[] = [];
        let avgRoutePromise = admin
          .firestore()
          .collection("routeAverages")
          .where("systemAccountId", "==", systemAccountID)
          .get()
          .then((querySnapshot) => {
            querySnapshot.docs.forEach((element) => {
              let ras: any[] = element.get("routeAverages");
              ras.forEach((ra) => {
                let averageRoute = new RouteAverage(
                  ra.cm,
                  ra.ts,
                  ra.sp,
                  ra.totalAmountOfRoute
                );
                averageRoute.scstpd = ra.scstpd;
                averageRoute.scstppd = ra.scstppd;
                averageRoute.rfstpd = ra.rfstpd;
                averageRoute.averageAdBrake = ra.averageAdBrake;
                averageRoutes.push(averageRoute);
              });
              // let setup=element.get("cm")+element.get("ts")+element.get("sp");
              // let adBrakeNum=superPath.get(element.get("sp"));
              // setupMap.set(setup,[averageRoute.scstppd,averageRoute.averageAdBrake]);
            });
          });
        promises.push(avgRoutePromise);
        await Promise.all(promises);
        listOfAdCardVal = frequencyAssigner(valueMap, listOfAdCardVal);
        let currentDate = admin.firestore.Timestamp.now();

        let deletePromise = admin
          .firestore()
          .collection("AdScheduleTest")
          .where("systemAccountId", "==", systemAccountID)
          .get()
          .then(async (querySnapshot) => {
            querySnapshot.docs.forEach(async (element) => {
              const p = admin
                .firestore()
                .collection("AdScheduleTest")
                .doc(element.id)
                .delete();
              promises.push(p);
            });
          });
        promises.push(deletePromise);

        let adSpotperAdbrake = 8;
        let systemAccPromise = admin
          .firestore()
          .collection("systemRequirementAccount")
          .doc(systemAccountID)
          .get()
          .then((docSnap) => {
            adSpotperAdbrake = docSnap.get("adBrakeMaximumLength");
          });
        promises.push(systemAccPromise);
        await Promise.all(promises);
        // let adSchedules=asip(averageRoutes,listOfAdCardVal,hours,minutes,timeZoneName,adSpotperAdbrake);
        let adSchedules = asip(
          averageRoutes,
          listOfAdCardVal,
          hours,
          minutes,
          timeZoneName,
          adSpotperAdbrake,
          valueMap
        );

        let adScheduleChunks: AdSchedule[][] = chunk(adSchedules[0], 5000);
        adScheduleChunks.forEach(async (element) => {
          let mapAsJson = {};
          let keyCounter = 0;
          element.forEach((adsc) => {
            mapAsJson[keyCounter] = {
              aalst: adsc.aalst,
              aastd: adsc.aastd,
              cm: adsc.cm,
              ts: adsc.ts,
              sp: adsc.sp,
              date: adsc.date,
            };
            keyCounter++;
          });
          const p = admin
            .firestore()
            .collection("AdScheduleTest")
            .doc()
            .create({
              adSchedules: mapAsJson,
              systemAccountId: systemAccountID,
            });
          promises.push(p);
        });

        adSchedules[1].forEach(async (element) => {
          let tascpdMap = {};
          // THIS CODE IS USEFUL TO WRITE ASTCPD IF WE DECIDE TO IN THE FUTURE
          // await admin.firestore().collection("adCardAstcpd").where("adCardID","==",
          // element.name).get().then((query)=>{
          //   query.docs.forEach(async(adCardAstcpd)=>{
          //     await admin.firestore().collection("adCardAstcpd").
          //     doc(adCardAstcpd.id).delete();
          //   });
          // });
          // let astcpdChunks:ASTCPD[][]=chunk(element.astcpd,5000);
          // astcpdChunks.forEach(async(astcpdChunk)=>{
          //   let astcpdMap={}
          //   let astcounter=0;
          //   astcpdChunk.forEach((astcpdVal)=>{
          //     astcpdMap[astcounter]={
          //       date:astcpdVal.date,
          //       trip:astcpdVal.trip,
          //       value:astcpdVal.value,
          //     }
          //     astcounter++;
          //   });
          //   await admin.firestore().collection("adCardAstcpd").doc().create({
          //     adCardID:element.name,
          //     astcpd:astcpdMap
          //   });
          // })
          let tasCounter = 0;
          element.tascpd.forEach((tascpdVal) => {
            tascpdMap[tasCounter] = {
              date: tascpdVal.date,
              value: tascpdVal.value,
            };
            tasCounter++;
          });
          const p = admin
            .firestore()
            .collection("AdCardTemp")
            .doc(element.name)
            .update({
              sda: element.sda,
              tascpd: tascpdMap,
            });
          promises.push(p);
        });
        await Promise.all(promises);
        const p = admin
          .firestore()
          .collection("controller")
          .doc(change.after.id)
          .update({
            asipDate: currentDate,
            // asipIdent:contex.eventId
          });
        promises.push(p);
      } else if (after.timeSlotController != before.timeSlotController) {
        let currentDate = new Date();
        currentDate.setUTCHours(0, 0, 0, 0);
        let timeSlotDate: firestore.Timestamp = after.timeSlotDate;
        if (currentDate.getTime() > timeSlotDate.toDate().getTime()) {
          let systemAccountID: string = after.systemAccountId;
          let one_day = 1000 * 24 * 60 * 60;
          class TempTimeSlot {
            timeSlotID: string;
            startTime: Date;
            endTime: Date;
            constructor(timeSlotID: string, startTime: Date, endTime: Date) {
              this.timeSlotID = timeSlotID;
              this.startTime = startTime;
              this.endTime = endTime;
            }
          }
          let tempTimeSlots: TempTimeSlot[] = [];
          const pr1 = admin
            .firestore()
            .collection("timeSlot")
            .where("systemAccountId", "==", systemAccountID)
            .get()
            .then((timeSlots) => {
              timeSlots.forEach((timeSlot) => {
                let stTimeStamp: admin.firestore.Timestamp =
                  timeSlot.get("startTime");
                let edTimeStamp: admin.firestore.Timestamp =
                  timeSlot.get("endTime");
                tempTimeSlots.push(
                  new TempTimeSlot(
                    timeSlot.id,
                    new Date(stTimeStamp.toDate().getTime() + one_day),
                    new Date(edTimeStamp.toDate().getTime() + one_day)
                  )
                );
              });
            });
          promises.push(pr1);
          await Promise.all(promises);
          tempTimeSlots.forEach((tempTimeSlot) => {
            const pr2 = admin
              .firestore()
              .collection("timeSlot")
              .doc(tempTimeSlot.timeSlotID)
              .update({
                startTime: tempTimeSlot.startTime,
                endTime: tempTimeSlot.endTime,
              });
            promises.push(pr2);
          });
          const p = admin
            .firestore()
            .collection("controller")
            .doc(change.after.id)
            .update({
              timeSlotDate: admin.firestore.Timestamp.fromDate(currentDate),
            });
          promises.push(p);
        }
      }
      const promiseValues = await Promise.all(promises);
      return promiseValues;
    } catch (error) {
      // console.log("error is : " + error);
      return error;
    }
  });

function randomIntFromInterval(min: number, max: number): number {
  // min and max included
  return Math.floor(Math.random() * (max - min + 1) + min);
}

function convertTZ(date: Date, tzString: string) {
  return new Date(
    (typeof date === "string" ? new Date(date) : date).toLocaleString("en-US", {
      timeZone: tzString,
    })
  );
}

function generateAdCard(
  cardAmount: number,
  cm: string[],
  ts: string[],
  sp: string[]
): AdCard[] {
  let listOfAdCardVal: AdCard[] = [];
  for (let index = 0; index < cardAmount; index++) {
    // let cmRandomNum=randomIntFromInterval(0,cm.length-1);
    // let tsRandmNum=randomIntFromInterval(0,ts.length-1);
    // let spRandomNum=randomIntFromInterval(0,sp.length-1);
    listOfAdCardVal.push(
      new AdCard(
        index.toString(),
        randomIntFromInterval(1, 3),
        randomIntFromInterval(1, 3),
        cm,
        ts,
        sp,
        randomIntFromInterval(50, 300),
        new Date(
          2021,
          randomIntFromInterval(5, 7),
          randomIntFromInterval(1, 26)
        ),
        new Date(
          2021,
          randomIntFromInterval(9, 10),
          randomIntFromInterval(1, 26)
        ),
        new Date(
          2021,
          randomIntFromInterval(11, 12),
          randomIntFromInterval(1, 26)
        )
      )
    );
  }
  return listOfAdCardVal;
}

function chunk(arr: any, len: number): any {
  var chunks = [],
    i = 0,
    n = arr.length;

  while (i < n) {
    chunks.push(arr.slice(i, (i += len)));
  }

  return chunks;
}

function removeKeyStartsWith(obj, letter) {
  Object.keys(obj).forEach(function (key) {
    //if(key[0]==letter) delete obj[key];////without regex
    if (key.match("^" + letter)) delete obj[key]; //with regex
  });
}

// RAIP
function raip(
  routes: Route[],
  pathPair: Map<string, number>,
  ractDays: number,
  adSpotperAdbrake: number
): RouteAverage[] {
  let routeAverages: RouteAverage[] = [];
  for (let i = 0; i < routes.length; i++) {
    let exist = false;
    for (let j = 0; j < routeAverages.length; j++) {
      if (
        routes[i].cm == routeAverages[j].cm &&
        routes[i].ts == routeAverages[j].ts &&
        routes[i].sp == routeAverages[j].sp
      ) {
        let routeServeAmount = pathPair.get(routes[i].path);
        routeAverages[j].totalAdbrake += routeServeAmount;
        routeServeAmount *= adSpotperAdbrake;
        routeAverages[j].totalServeCapacity += routeServeAmount;
        routeAverages[j].totalAmountOfRoute++;
        exist = true;
        break;
      }
    }
    if (exist == false) {
      let routeAverage = new RouteAverage(
        routes[i].cm,
        routes[i].ts,
        routes[i].sp,
        1
      );
      let routeServeAmount = pathPair.get(routes[i].path);
      routeAverage.totalAdbrake += routeServeAmount;
      routeServeAmount *= adSpotperAdbrake;
      routeAverage.totalServeCapacity += routeServeAmount;
      routeAverages.push(routeAverage);
    }
  }
  let tsc: number = 0;
  for (let i = 0; i < routeAverages.length; i++) {
    routeAverages[i].averageAdBrake = Number.parseFloat(
      (
        routeAverages[i].totalAdbrake / routeAverages[i].totalAmountOfRoute
      ).toFixed(2)
    );
    routeAverages[i].rfstpd = Math.round(
      routeAverages[i].totalAmountOfRoute / ractDays
    );
    routeAverages[i].scstpd = Math.round(
      routeAverages[i].totalServeCapacity / ractDays
    );
    tsc += routeAverages[i].scstpd;
  }
  for (let i = 0; i < routeAverages.length; i++) {
    let num = routeAverages[i].scstpd / tsc;
    routeAverages[i].scstppd = num * 100;
    routeAverages[i].scstppd = Number.parseFloat(
      routeAverages[i].scstppd.toFixed(2)
    );
  }
  return routeAverages;
}

// TESTED
function frequencyAssigner(
  valueMapVar: Map<string, number>,
  cardList: AdCard[]
): AdCard[] {
  let cd = new Date();
  for (let i: number = 0; i < cardList.length; i++) {
    cardList[i].timeScore = cd.getTime() - cardList[i].created_date.getTime();
    for (let j: number = 0; j < cardList[i].cm.length; j++) {
      for (let k: number = 0; k < cardList[i].ts.length; k++) {
        for (let l: number = 0; l < cardList[i].sp.length; l++) {
          // the pluses are useful because when we assign the
          // cm, ts and sp value we add those letters
          let cPercent = valueMapVar.get(cardList[i].cm[j] + "c");
          let tPercent = valueMapVar.get(cardList[i].ts[k] + "t");
          let superPathPrice = valueMapVar.get(cardList[i].sp[l] + "s");
          if (cPercent != null && tPercent != null && superPathPrice != null) {
            let cDeductable = cPercent * superPathPrice;
            cDeductable /= 100;
            let tDeductable = tPercent * superPathPrice;
            tDeductable /= 100;
            let finalValue = superPathPrice - cDeductable - tDeductable;
            finalValue *= cardList[i].length;
            let specificFrequency = cardList[i].adCardBalance / finalValue;
            specificFrequency = Math.floor(specificFrequency);
            if (specificFrequency > 0) {
              cardList[i].availableSetups.push(
                cardList[i].cm[j] +
                  "-" +
                  cardList[i].ts[k] +
                  "-" +
                  cardList[i].sp[l]
              );
            }
            // just add the strings together so we can use it as a key
            cardList[i].list_of_frequency.set(
              cardList[i].cm[j] + cardList[i].ts[k] + cardList[i].sp[l],
              [specificFrequency, parseFloat(finalValue.toFixed(3))]
            );
          }
        }
      }
    }
  }
  return cardList;
}

// TESTED
function singlefrequencyAssigner(
  valueMapVar: Map<string, number>,
  card: AdCard
): AdCard {
  for (let j: number = 0; j < card.cm.length; j++) {
    for (let k: number = 0; k < card.ts.length; k++) {
      for (let l: number = 0; l < card.sp.length; l++) {
        // the pluses are useful because when we assign the
        // cm, ts and sp value we add those letters
        let cPercent = valueMapVar.get(card.cm[j] + "c");
        let tPercent = valueMapVar.get(card.ts[k] + "t");
        let superPathPrice = valueMapVar.get(card.sp[l] + "s");
        if (cPercent != null && tPercent != null && superPathPrice != null) {
          let cDeductable = cPercent * superPathPrice;
          cDeductable /= 100;
          let tDeductable = tPercent * superPathPrice;
          tDeductable /= 100;
          let finalValue = superPathPrice - cDeductable - tDeductable;
          finalValue *= card.length;
          let specificFrequency = card.adCardBalance / finalValue;
          specificFrequency = Math.floor(specificFrequency);
          if (specificFrequency > 0) {
            card.availableSetups.push(
              card.cm[j] + "-" + card.ts[k] + "-" + card.sp[l]
            );
          }
          // just add the strings together so we can use it as a key
          card.list_of_frequency.set(card.cm[j] + card.ts[k] + card.sp[l], [
            specificFrequency,
            parseFloat(finalValue.toFixed(3)),
          ]);
        }
      }
    }
  }
  return card;
}

// ASIP
// TESTED
function newAdScheduleCreation(
  setups: Setup[],
  adCardServes: AdCardServe[],
  routeAverages: RouteAverage[]
): AdSchedule[] {
  let adSchedules: AdSchedule[] = [];
  let taaStartDate: Date = new Date(),
    taaEndDate: Date = new Date();
  let taas: TAA[] = [];

  for (let i = 0; i < setups.length; i++) {
    if (i == 0) {
      taaStartDate = setups[i].startDate;
      taaEndDate = setups[i].endDate;
    }
    if (setups[i].startDate.getTime() < taaStartDate.getTime()) {
      taaStartDate = setups[i].startDate;
    }
    if (setups[i].endDate.getTime() > taaEndDate.getTime()) {
      taaEndDate = setups[i].endDate;
    }
  }
  var one_day = 1000 * 60 * 60 * 24;
  let difference = taaEndDate.getTime() - taaStartDate.getTime();
  difference = difference / one_day;
  difference = Math.round(difference);
  for (let i = 0; i <= difference; i++) {
    let day = taaStartDate.getTime();
    let addition = i * one_day;
    day += addition;
    let date = new Date(day);
    let taa = new TAA(date);
    for (let j = 0; j < adCardServes.length; j++) {
      if (
        date >= adCardServes[j].startDate &&
        date <= adCardServes[j].endDate
      ) {
        for (let k = 0; k < adCardServes[j].astcpd.length; k++) {
          if (
            date.getFullYear() ==
              adCardServes[j].astcpd[k].date.getFullYear() &&
            date.getMonth() == adCardServes[j].astcpd[k].date.getMonth() &&
            date.getDate() == adCardServes[j].astcpd[k].date.getDate()
          ) {
            let exist = false;
            let index = 0;
            let adSpots = adCardServes[j].astcpd[k].value;
            for (let l = 0; l < taa.setupTotals.length; l++) {
              if (adCardServes[j].astcpd[k].trip == taa.setupTotals[l].trip) {
                exist = true;
                index = l;
                break;
              }
            }
            if (exist == true) {
              taa.setupTotals[index].totalAdspot += adSpots;
            } else {
              taa.setupTotals.push(
                new SetupTotal(adCardServes[j].astcpd[k].trip, adSpots)
              );
            }
          }
        }
      }
    }
    taas.push(taa);
  }
  // console.log("taas: "+taas.length)
  for (let i = 0; i < taas.length; i++) {
    for (let j = 0; j < taas[i].setupTotals.length; j++) {
      // console.log("taas: "+taas[i].date+" setup: "+taas[i].setupTotals[j].trip+
      // " adSpots: "+taas[i].setupTotals[j].totalAdspot);
      for (let k = 0; k < routeAverages.length; k++) {
        let trip =
          routeAverages[k].cm +
          "-" +
          routeAverages[k].ts +
          "-" +
          routeAverages[k].sp;
        if (taas[i].setupTotals[j].trip == trip) {
          let aastd = taas[i].setupTotals[j].totalAdspot;
          let alst = routeAverages[k].scstpd - aastd;
          alst = Math.round(alst);
          aastd = Math.round(aastd);
          let adSchedule = new AdSchedule(
            taas[i].date,
            routeAverages[k].cm,
            routeAverages[k].ts,
            routeAverages[k].sp,
            aastd,
            alst
          );
          adSchedules.push(adSchedule);
        }
      }
    }
  }
  return adSchedules;
}

// TESTED
function newAssignServeLength(
  adCardServes: AdCardServe[],
  listOfAdCards: AdCard[]
): AdCard[] {
  let adCards: AdCard[] = [];
  for (let i = 0; i < adCardServes.length; i++) {
    for (let j = 0; j < listOfAdCards.length; j++) {
      if (adCardServes[i].adCardname == listOfAdCards[j].name) {
        listOfAdCards[j].sda = adCardServes[i].tascpd.length;
        listOfAdCards[j].tascpd = adCardServes[i].tascpd;
        listOfAdCards[j].astcpd = adCardServes[i].astcpd;
        adCards.push(listOfAdCards[j]);
        listOfAdCards.splice(j, 1);
        break;
      }
    }
  }
  return adCards;
}

// TESTED
function newAdScheduleAssignment(
  listOfAdCards: AdCard[],
  routeAverages: RouteAverage[],
  hour: number,
  minute: number,
  timezoneName: string,
  maximumadSpotPerAdBreak: number,
  valueMapVar: Map<string, number>
): [AdCardServe[], Setup[]] {
  let adCardServes: AdCardServe[] = [];
  let setups: Setup[] = [];

  var one_day = 1000 * 60 * 60 * 24;
  let currentDate = new Date();
  currentDate = convertTZ(currentDate, timezoneName);
  currentDate.setUTCMonth(currentDate.getMonth());
  currentDate.setUTCDate(currentDate.getDate());
  currentDate.setUTCHours(hour, minute, 0, 0);

  //
  let sdDate = new Date();
  let edDate = new Date();

  sdDate = convertTZ(sdDate, timezoneName);
  sdDate.setUTCMonth(sdDate.getMonth());
  sdDate.setUTCDate(sdDate.getDate());
  sdDate.setUTCHours(hour, minute, 0, 0);

  edDate = convertTZ(edDate, timezoneName);
  edDate.setUTCMonth(edDate.getMonth());
  edDate.setUTCDate(edDate.getDate());
  edDate.setUTCHours(hour, minute, 0, 0);

  let first = false;
  //

  for (let i = 0; i < listOfAdCards.length; i++) {
    let newStartDate: Date = new Date();
    newStartDate.setTime(listOfAdCards[i].start_date.getTime());

    let startCurrentDifference =
      listOfAdCards[i].start_date.getTime() - currentDate.getTime();
    startCurrentDifference = startCurrentDifference / one_day;
    startCurrentDifference = Math.round(startCurrentDifference);

    if (startCurrentDifference < 0) {
      newStartDate.setTime(currentDate.getTime());
    }

    //
    if (!first || newStartDate.getTime() < sdDate.getTime()) {
      sdDate.setTime(newStartDate.getTime());
      if (!first) {
        first = true;
      }
    }
    if (listOfAdCards[i].end_date.getTime() > edDate.getTime()) {
      edDate.setTime(listOfAdCards[i].end_date.getTime());
    }
    //

    for (let j = 0; j < listOfAdCards[i].cm.length; j++) {
      for (let k = 0; k < listOfAdCards[i].ts.length; k++) {
        for (let l = 0; l < listOfAdCards[i].sp.length; l++) {
          let exist = false;
          let index = 0;
          for (let m = 0; m < setups.length; m++) {
            if (
              setups[m].cm == listOfAdCards[i].cm[j] &&
              setups[m].ts == listOfAdCards[i].ts[k] &&
              setups[m].sp == listOfAdCards[i].sp[l]
            ) {
              index = m;
              exist = true;
              break;
            }
          }
          if (exist == false) {
            let setup = new Setup(
              listOfAdCards[i].cm[j],
              listOfAdCards[i].ts[k],
              listOfAdCards[i].sp[l],
              newStartDate,
              listOfAdCards[i].end_date
            );

            let routeAverageExist = false;
            for (let p = 0; p < routeAverages.length; p++) {
              let routeSetup =
                routeAverages[p].cm + routeAverages[p].ts + routeAverages[p].sp;
              let setupTrip = setup.cm + setup.ts + setup.sp;
              if (routeSetup == setupTrip) {
                setup.scstpd = routeAverages[p].scstpd;
                setup.averageAdBrake = routeAverages[p].averageAdBrake;
                routeAverageExist = true;
                break;
              }
            }
            //
            setup.servable = routeAverageExist;
            setup.adCards.push(listOfAdCards[i]);
            setups.push(setup);
            //
          } else {
            if (setups[index].servable) {
              if (newStartDate.getTime() < setups[index].startDate.getTime()) {
                setups[index].startDate.setTime(newStartDate.getTime());
              }
              if (
                listOfAdCards[i].end_date.getTime() >
                setups[index].endDate.getTime()
              ) {
                setups[index].endDate.setTime(
                  listOfAdCards[i].end_date.getTime()
                );
              }
              setups[index].adCards.push(listOfAdCards[i]);
            }
          }
        }
      }
    }
  }

  for (let u = 0; u < setups.length; u++) {
    if (!setups[u].servable) {
      setups.splice(u, 1);
      u -= 1;
    }
  }

  // console.log("ed "+edDate+" Sd "+sdDate)
  let difference = edDate.getTime() - sdDate.getTime();
  difference = difference / one_day;
  difference = Math.round(difference);

  // console.log("set len "+setups.length+" diff "+difference);

  for (let j = 0; j <= difference; j++) {
    let day = sdDate.getTime();
    let addition = j * one_day;
    day += addition;
    let date = new Date(day);
    for (let i = 0; i < setups.length; i++) {
      if (
        setups[i].startDate.getTime() <= date.getTime() &&
        setups[i].endDate.getTime() >= date.getTime()
      ) {
        let scstpd = setups[i].scstpd;
        let averageAdBrake = setups[i].averageAdBrake;
        let tempServes: TempServe[] = [];
        for (let k = 0; k < setups[i].adCards.length; k++) {
          let startDifference =
            setups[i].adCards[k].start_date.getTime() - date.getTime();
          startDifference = startDifference / one_day;
          startDifference = Math.round(startDifference);
          let endDifference =
            setups[i].adCards[k].end_date.getTime() - date.getTime();
          endDifference = endDifference / one_day;
          endDifference = Math.round(endDifference);
          setups[i].adCards[k] = singlefrequencyAssigner(
            valueMapVar,
            setups[i].adCards[k]
          );
          let freqAmount = setups[i].adCards[k].list_of_frequency.get(
            setups[i].cm + setups[i].ts + setups[i].sp
          );
          // console.log("freq "+freqAmount);
          if (
            freqAmount != null &&
            startDifference <= 0 &&
            endDifference >= 0
          ) {
            if (freqAmount[0] > 0) {
              // console.log("ad "+setups[i].adCards[k].name);
              let tempServe = new TempServe(setups[i].adCards[k]);
              tempServe.adCardIndex = k;
              tempServe.freqAmount =
                freqAmount[0] * setups[i].adCards[k].length;
              tempServe.pricePerAdSpot =
                freqAmount[1] / setups[i].adCards[k].length;
              tempServes.push(tempServe);
            }
          }
        }
        tempServes.sort((a, b) => b.freq_per_route - a.freq_per_route);
        tempServes.sort((a, b) => b.adLength - a.adLength);
        tempServes.sort((a, b) => b.timeScoreValue - a.timeScoreValue);

        // if(tempServes.length>0){
        //   console.log("Temp serve leng "+tempServes.length);
        //   for(let t=0;t<tempServes.length;t++){
        //     console.log("Temp "+tempServes[t].availableAdcard.name+" "+tempServes[t].pricePerAdSpot);
        //   }
        // }

        let serveShareLeft: number = 100;
        let leftOvers: LeftOverSpots[] = [];
        for (let m = 0; m < tempServes.length; m++) {
          // console.log("m: "+m+" date: "+date+" "+setups[i].adCards.length);
          let exist = false;
          let index = 0;
          for (let n = 0; n < adCardServes.length; n++) {
            if (
              tempServes[m].availableAdcard.name == adCardServes[n].adCardname
            ) {
              exist = true;
              index = n;
              break;
            }
          }
          let properEnter = false;
          if (exist == false) {
            let newStartDate: Date = new Date();
            newStartDate.setTime(
              tempServes[m].availableAdcard.start_date.getTime()
            );

            let startCurrentDifference =
              tempServes[m].availableAdcard.start_date.getTime() -
              currentDate.getTime();
            startCurrentDifference = startCurrentDifference / one_day;
            startCurrentDifference = Math.round(startCurrentDifference);

            if (startCurrentDifference < 0) {
              newStartDate.setTime(currentDate.getTime());
            }
            let adCardServ = new AdCardServe(
              tempServes[m].availableAdcard.name,
              newStartDate,
              tempServes[m].availableAdcard.end_date
            );
            let astcpd = 0;
            let perc100 = 0;
            if (serveShareLeft > 0) {
              //
              properEnter = true;
              let lengthPerc =
                (tempServes[m].adLength * 100) /
                (averageAdBrake * maximumadSpotPerAdBreak);
              let newFreqPerRoute = 1;
              if (tempServes[m].freq_per_route > averageAdBrake) {
                newFreqPerRoute = averageAdBrake;
              }
              let percOutOf100 =
                (newFreqPerRoute * tempServes[m].adLength * 100) /
                (averageAdBrake * maximumadSpotPerAdBreak);
              if (percOutOf100 >= serveShareLeft) {
                if (lengthPerc <= serveShareLeft) {
                  let freqLeft = Math.floor(serveShareLeft / lengthPerc);
                  percOutOf100 = lengthPerc * freqLeft;
                } else {
                  percOutOf100 = 0;
                }
              }
              perc100 = percOutOf100;
              serveShareLeft -= percOutOf100;
              astcpd = (percOutOf100 / 100) * scstpd;
              //
            }
            //
            if (astcpd < tempServes[m].freqAmount && leftOvers.length != 0) {
              let lengthPerc =
                (tempServes[m].adLength * 100) /
                (averageAdBrake * maximumadSpotPerAdBreak);
              let newFreqPerRoute = 1;
              if (tempServes[m].freq_per_route > averageAdBrake) {
                newFreqPerRoute = averageAdBrake;
              }
              let percOutOf100 =
                (newFreqPerRoute * tempServes[m].adLength * 100) /
                (averageAdBrake * maximumadSpotPerAdBreak);
              for (let t = 0; t < leftOvers.length; t++) {
                if (percOutOf100 >= leftOvers[t].shareLeft) {
                  if (lengthPerc <= leftOvers[t].shareLeft) {
                    let freqLeft = Math.floor(
                      leftOvers[t].shareLeft / lengthPerc
                    );
                    percOutOf100 = lengthPerc * freqLeft;
                  } else {
                    percOutOf100 = 0;
                  }
                }
                let shareFromLeftOver =
                  (percOutOf100 * 100) / leftOvers[t].shareLeft;
                let amountTaken =
                  (shareFromLeftOver / 100) * leftOvers[t].amountLeft;
                astcpd += amountTaken;
                if (astcpd >= tempServes[m].freqAmount) {
                  let prevAstcpd = astcpd - amountTaken;
                  let diffr = Math.abs(prevAstcpd - tempServes[m].freqAmount);
                  amountTaken = diffr;
                  leftOvers[t].amountLeft -= amountTaken;
                  astcpd = tempServes[m].freqAmount;
                  break;
                }
                if (shareFromLeftOver == 100) {
                  leftOvers.splice(t, 1);
                  t -= 1;
                } else {
                  leftOvers[t].shareLeft -= percOutOf100;
                  leftOvers[t].amountLeft -= amountTaken;
                }
              }
            }
            //
            astcpd = Math.floor(astcpd);
            if (astcpd > tempServes[m].freqAmount && properEnter) {
              let amountLeft = astcpd - tempServes[m].freqAmount;
              astcpd = tempServes[m].freqAmount;
              leftOvers.push(new LeftOverSpots(perc100, amountLeft));
            }
            adCardServ.astcpd.push(
              new ASTCPD(
                setups[i].cm + "-" + setups[i].ts + "-" + setups[i].sp,
                date,
                astcpd
              )
            );
            adCardServ.tascpd.push(new TASCPD(date, astcpd));
            adCardServes.push(adCardServ);
            let balanceDeduct = astcpd * tempServes[m].pricePerAdSpot;
            // if(m==0){
            //   console.log("Setu "+setups[i].cm+setups[i].ts+setups[i].sp);
            //   console.log("Freq am "+tempServes[m].freqAmount+" ast "+astcpd);
            //   console.log("ad N: "+setups[i].adCards[tempServes[m].adCardIndex].name+" prevBal "+
            //   setups[i].adCards[tempServes[m].adCardIndex].adCardBalance+" balDed "+balanceDeduct);
            //   console.log("SerSha: "+serveShareLeft);
            // }
            setups[i].adCards[tempServes[m].adCardIndex].adCardBalance -=
              balanceDeduct;
          } else {
            let astcpd = 0;
            let perc100 = 0;
            if (serveShareLeft > 0) {
              //
              properEnter = true;
              let lengthPerc =
                (tempServes[m].adLength * 100) /
                (averageAdBrake * maximumadSpotPerAdBreak);
              let newFreqPerRoute = 1;
              if (tempServes[m].freq_per_route > averageAdBrake) {
                newFreqPerRoute = averageAdBrake;
              }
              let percOutOf100 =
                (newFreqPerRoute * tempServes[m].adLength * 100) /
                (averageAdBrake * maximumadSpotPerAdBreak);
              if (percOutOf100 >= serveShareLeft) {
                if (lengthPerc <= serveShareLeft) {
                  let freqLeft = Math.floor(serveShareLeft / lengthPerc);
                  percOutOf100 = lengthPerc * freqLeft;
                } else {
                  percOutOf100 = 0;
                }
              }
              perc100 = percOutOf100;
              serveShareLeft -= percOutOf100;
              astcpd = (percOutOf100 / 100) * scstpd;
              //
            }
            //
            if (astcpd < tempServes[m].freqAmount && leftOvers.length != 0) {
              let lengthPerc =
                (tempServes[m].adLength * 100) /
                (averageAdBrake * maximumadSpotPerAdBreak);
              let newFreqPerRoute = 1;
              if (tempServes[m].freq_per_route > averageAdBrake) {
                newFreqPerRoute = averageAdBrake;
              }
              let percOutOf100 =
                (newFreqPerRoute * tempServes[m].adLength * 100) /
                (averageAdBrake * maximumadSpotPerAdBreak);
              for (let t = 0; t < leftOvers.length; t++) {
                if (percOutOf100 >= leftOvers[t].shareLeft) {
                  if (lengthPerc <= leftOvers[t].shareLeft) {
                    let freqLeft = Math.floor(
                      leftOvers[t].shareLeft / lengthPerc
                    );
                    percOutOf100 = lengthPerc * freqLeft;
                  } else {
                    percOutOf100 = 0;
                  }
                }
                let shareFromLeftOver =
                  (percOutOf100 * 100) / leftOvers[t].shareLeft;
                let amountTaken =
                  (shareFromLeftOver / 100) * leftOvers[t].amountLeft;
                astcpd += amountTaken;
                if (astcpd >= tempServes[m].freqAmount) {
                  let prevAstcpd = astcpd - amountTaken;
                  let diffr = Math.abs(prevAstcpd - tempServes[m].freqAmount);
                  amountTaken = diffr;
                  leftOvers[t].amountLeft -= amountTaken;
                  astcpd = tempServes[m].freqAmount;
                  break;
                }
                if (shareFromLeftOver == 100) {
                  leftOvers.splice(t, 1);
                  t -= 1;
                } else {
                  leftOvers[t].shareLeft -= percOutOf100;
                  leftOvers[t].amountLeft -= amountTaken;
                }
              }
            }
            //
            astcpd = Math.floor(astcpd);
            if (astcpd > tempServes[m].freqAmount && properEnter) {
              let amountLeft = astcpd - tempServes[m].freqAmount;
              astcpd = tempServes[m].freqAmount;
              leftOvers.push(new LeftOverSpots(perc100, amountLeft));
            }
            adCardServes[index].astcpd.push(
              new ASTCPD(
                setups[i].cm + "-" + setups[i].ts + "-" + setups[i].sp,
                date,
                astcpd
              )
            );
            let exist = false;
            for (let q = 0; q < adCardServes[index].tascpd.length; q++) {
              let tascpd = adCardServes[index].tascpd[q];
              let difference = tascpd.date.getTime() - date.getTime();
              difference = difference / one_day;
              difference = Math.round(difference);
              if (difference == 0) {
                tascpd.value += astcpd;
                adCardServes[index].tascpd[q].value = tascpd.value;
                exist = true;
                break;
              }
            }
            if (exist == false) {
              adCardServes[index].tascpd.push(new TASCPD(date, astcpd));
            }

            let balanceDeduct = astcpd * tempServes[m].pricePerAdSpot;
            // if(m==0){
            //   console.log("Setu "+setups[i].cm+setups[i].ts+setups[i].sp);
            //   console.log("Freq am "+tempServes[m].freqAmount+" ast "+astcpd);
            //   console.log("ad N: "+setups[i].adCards[tempServes[m].adCardIndex].name+" prevBal"+
            //   setups[i].adCards[tempServes[m].adCardIndex].adCardBalance+" balDed "+balanceDeduct);
            //   console.log("SerSha: "+serveShareLeft);
            // }
            setups[i].adCards[tempServes[m].adCardIndex].adCardBalance -=
              balanceDeduct;
          }
        }
      }
    }
  }
  return [adCardServes, setups];
}

// TESTED
function asip(
  averageRoutes: RouteAverage[],
  listOfAdCards: AdCard[],
  hour: number,
  minute: number,
  timezoneName: string,
  maximumadSpotPerAdBreak: number,
  valueMapVar: Map<string, number>
): [AdSchedule[], AdCard[]] {
  let adAndSetup = newAdScheduleAssignment(
    listOfAdCards,
    averageRoutes,
    hour,
    minute,
    timezoneName,
    maximumadSpotPerAdBreak,
    valueMapVar
  );

  listOfAdCards = newAssignServeLength(adAndSetup[0], listOfAdCards);

  let adSchedules = newAdScheduleCreation(
    adAndSetup[1],
    adAndSetup[0],
    averageRoutes
  );
  return [adSchedules, listOfAdCards];
}

// FOR DAGIM
// Returns an adcard with the setups dividved, when you give it the main ad card
// and setup limit per doc then you need to run frequency assigner for each
// ad card (which is going to be used as adcardSetup) returned to get
// available setups of the ad card (adCardSetup)
function adSetupCreation(adCard: AdCard, setupLimitPerDoc: number): AdCard[] {
  let sp: string[] = adCard.sp;
  let spLimit = 1;
  if (adCard.cm.length * adCard.ts.length < setupLimitPerDoc) {
    spLimit = Math.floor(
      setupLimitPerDoc / (adCard.cm.length * adCard.ts.length)
    );
  }
  let sps: string[][] = chunk(sp, spLimit);
  let adCards: AdCard[] = [];
  for (let i = 0; i < sps.length; i++) {
    adCards.push(
      new AdCard(
        adCard.name,
        adCard.length,
        adCard.frequency_per_route,
        adCard.cm,
        adCard.ts,
        sps[i],
        adCard.adCardBalance,
        adCard.created_date,
        adCard.start_date,
        adCard.end_date
      )
    );
  }
  return adCards;
}
