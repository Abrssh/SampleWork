import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

import { Network, OpenSeaStreamClient } from '@opensea/stream-js';
import { WebSocket } from 'ws';
import { Browser } from "puppeteer";
const puppeteer = require("puppeteer");

const client = new OpenSeaStreamClient({
  network: Network.TESTNET,
  token: 'openseaApiKey',
  connectOptions: {
    transport: WebSocket
  }
});


admin.initializeApp();


//    🔴 Opensea DataStream 
export const task5 = functions.
    runWith({
        memory: "8GB", timeoutSeconds: 540,
        serviceAccount:"stock-up-crypto@appspot.gserviceaccount.com"
    }).pubsub.schedule("0 */3 * * *").onRun(async () => {
        try {
            let promises = [];
            await client.connect();
            let firstVal = "*", secondVal = "boredapeyatchclub";
            // await admin
            //     .firestore()
            //     .collection("abrCollection")
            //     .doc("ihrPZABGW0O9VpDtkfbJ")
            //     .get()
            //     .then((value) => {
            //         firstVal = value.get("firstVal");
            //         secondVal = value.get("secondVal");
            //     });
            let azukiJson = {}, boredApeJson = {};
            let boredApeCounter = 0;
            await client.onItemSold(firstVal, (event) => {
                // console.log("Event: " + event.payload);
                // console.log(event.payload);
                // console.log(event.sent_at);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                if (Object.prototype.hasOwnProperty.call(azukiJson,
                    event.payload.collection.slug)) {
                    let temp:string = azukiJson[event.payload.collection.slug];
                    temp += JSON.stringify(map);
                    azukiJson[event.payload.collection.slug] = temp;
                } else {
                    azukiJson[event.payload.collection.slug] = JSON.stringify(map);
                }
            });
            await client.onItemListed(firstVal, async (event) => {
                // await console.log("Event2: " + event);
                // console.log("Ev: "+ event.payload["collection"]["slug"]);
                // console.log(event.sent_at);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                if (Object.prototype.hasOwnProperty.call(azukiJson,
                    event.payload.collection.slug)) {
                    let temp:string = azukiJson[event.payload.collection.slug];
                    temp += JSON.stringify(map);
                    azukiJson[event.payload.collection.slug] = temp;
                } else {
                    azukiJson[event.payload.collection.slug] = JSON.stringify(map);
                }
            });
            await client.onItemCancelled(firstVal, (event) => {
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                if (Object.prototype.hasOwnProperty.call(azukiJson,
                    event.payload.collection.slug)) {
                    let temp:string = azukiJson[event.payload.collection.slug];
                    temp += JSON.stringify(map);
                    azukiJson[event.payload.collection.slug] = temp;
                } else {
                    azukiJson[event.payload.collection.slug] = JSON.stringify(map);
                }
            });
            client.onTraitOffer(firstVal, (event) => {
                // console.log("Event 4: " + event);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                if (Object.prototype.hasOwnProperty.call(azukiJson,
                    event.payload.collection.slug)) {
                    let temp:string = azukiJson[event.payload.collection.slug];
                    temp += JSON.stringify(map);
                    azukiJson[event.payload.collection.slug] = temp;
                } else {
                    azukiJson[event.payload.collection.slug] = JSON.stringify(map);
                }
            });
            client.onItemMetadataUpdated(firstVal, (event) => {
                // console.log("Event 4: " + event);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                if (Object.prototype.hasOwnProperty.call(azukiJson,
                    event.payload.collection.slug)) {
                    let temp:string = azukiJson[event.payload.collection.slug];
                    temp += JSON.stringify(map);
                    azukiJson[event.payload.collection.slug] = temp;
                } else {
                    azukiJson[event.payload.collection.slug] = JSON.stringify(map);
                }
            });
            client.onItemReceivedBid(firstVal, (event) => {
                // console.log("Event 4: " + event);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                if (Object.prototype.hasOwnProperty.call(azukiJson,
                    event.payload.collection.slug)) {
                    let temp:string = azukiJson[event.payload.collection.slug];
                    temp += JSON.stringify(map);
                    azukiJson[event.payload.collection.slug] = temp;
                } else {
                    azukiJson[event.payload.collection.slug] = JSON.stringify(map);
                }
            });
            client.onItemReceivedOffer(firstVal, (event) => {
                // console.log("Event 4: " + event);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                if (Object.prototype.hasOwnProperty.call(azukiJson,
                    event.payload.collection.slug)) {
                    let temp:string = azukiJson[event.payload.collection.slug];
                    temp += JSON.stringify(map);
                    azukiJson[event.payload.collection.slug] = temp;
                } else {
                    azukiJson[event.payload.collection.slug] = JSON.stringify(map);
                }
            });
            client.onItemTransferred(firstVal, (event) => {
                // console.log("Event 4: " + event);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                if (Object.prototype.hasOwnProperty.call(azukiJson,
                    event.payload.collection.slug)) {
                    let temp:string = azukiJson[event.payload.collection.slug];
                    temp += JSON.stringify(map);
                    azukiJson[event.payload.collection.slug] = temp;
                } else {
                    azukiJson[event.payload.collection.slug] = JSON.stringify(map);
                }
            });
            client.onCollectionOffer(firstVal, (event) => {
                // console.log("Event 4: " + event);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                if (Object.prototype.hasOwnProperty.call(azukiJson,
                    event.payload.collection.slug)) {
                    let temp:string = azukiJson[event.payload.collection.slug];
                    temp += JSON.stringify(map);
                    azukiJson[event.payload.collection.slug] = temp;
                } else {
                    azukiJson[event.payload.collection.slug] = JSON.stringify(map);
                }
            });
            await client.onItemSold(secondVal, (event) => {
                // console.log("Event 444: " + event);
                // console.log(event.payload);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                boredApeJson[boredApeCounter] = JSON.stringify(map);
                boredApeCounter++;
            });
            await client.onItemListed(secondVal, async (event) => {
                // console.log("Event 444: " + event);
                // console.log(event.payload);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                boredApeJson[boredApeCounter] = JSON.stringify(map);
                boredApeCounter++;
            });
            await client.onItemCancelled(secondVal, (event) => {
                // console.log("Event 4: " + event);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                boredApeJson[boredApeCounter] = JSON.stringify(map);
                boredApeCounter++;
            });
            client.onTraitOffer(secondVal, (event) => {
                // console.log("Event 444: " + event);
                // console.log(event.payload);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                boredApeJson[boredApeCounter] = JSON.stringify(map);
                boredApeCounter++;
            });
            client.onItemMetadataUpdated(secondVal, (event) => {
                // console.log("Event 444: " + event);
                // console.log(event.payload);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                boredApeJson[boredApeCounter] = JSON.stringify(map);
                boredApeCounter++;
            });
            client.onItemReceivedBid(secondVal, (event) => {
                // console.log("Event 4: " + event);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                boredApeJson[boredApeCounter] = JSON.stringify(map);
                boredApeCounter++;
            });
            client.onItemReceivedOffer(secondVal, (event) => {
                // console.log("Event 4: " + event);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                boredApeJson[boredApeCounter] = JSON.stringify(map);
                boredApeCounter++;
            });
            client.onItemTransferred(secondVal, (event) => {
                // console.log("Event 4: " + event);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                boredApeJson[boredApeCounter] = JSON.stringify(map);
                boredApeCounter++;
            });
            client.onCollectionOffer(secondVal, (event) => {
                // console.log("Event 4: " + event);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                boredApeJson[boredApeCounter] = JSON.stringify(map);
                boredApeCounter++;
            });
            await sleep(300000);
            // let finalString = JSON.stringify(azukiJson);
            // let finalString2 = JSON.stringify(boredApeJson);
            client.disconnect();
            const bucket = admin.storage().bucket();
            let date = new Date();
            let dateString = date.getDate() + "-" + date.getMonth() + "-" + date.getFullYear();
            for (const key in azukiJson) {
                if (Object.prototype.hasOwnProperty.call(azukiJson, key)) {
                    const element = azukiJson[key];
                    let finalString = JSON.stringify(element);
                    let file1 = bucket.file("abrFolder/OpenSea/" + key + "/" + dateString +
                        "_"+date.getTime()+ ".json");
                    let pr1 = file1.save(finalString).then(() => console.log("Uploaded Successfully"));
                    promises.push(pr1);
                }
            }
            // let file2 = bucket.file("abrFolder/OpenSea/" + secondVal + "/" + dateString +
            //     "_"+date.getTime() + ".json");
            // let pr2 = file2.save(finalString2).then(() => console.log("Uploaded Successfully2"));
            // promises.push(pr2);
            await Promise.all(promises);
            // response.send("F: " + finalString + " " + finalString2+" "+secondVal);
            return null;
        }
        catch (error) {
            console.log("Error: " + error);
            return error;
            // response.send("E: " + error);
        }
    });

export const task5Test = functions
    .runWith({
        memory: "8GB", timeoutSeconds: 540,
        serviceAccount:"stock-up-crypto@appspot.gserviceaccount.com"
    })
    .firestore.document("abrCollection5/{wildCard}").onWrite(async (change) => {
            try {
                await client.connect();
                // let promises = [];
                let firstVal = "azuki", secondVal = "boredapeyatchclub";
                await admin
                    .firestore()
                    .collection("abrCollection")
                    .doc("ihrPZABGW0O9VpDtkfbJ")
                    .get()
                    .then((value) => {
                        firstVal = value.get("firstVal");
                        secondVal = value.get("secondVal");
                    });
                let azukiJson = {}, boredApeJson = {};
                let azukiCounter = 0, boredApeCounter = 0;
                await client.onItemSold(firstVal, (event) => {
                    // console.log("Event: " + event.payload);
                    console.log(event.payload);
                    console.log(event.sent_at);
                    let map = {};
                    map[0] = event.event_type;
                    map[1] = event.payload;
                    map[2] = event.sent_at;
                    azukiJson[azukiCounter] = JSON.stringify(map);
                    azukiCounter++;
                });
                await client.onItemListed(firstVal, async (event) => {
                    // await console.log("Event2: " + event);
                    console.log(event.payload);
                    console.log(event.sent_at);
                    let map = {};
                    map[0] = event.event_type;
                    map[1] = event.payload;
                    map[2] = event.sent_at;
                    azukiJson[azukiCounter] = JSON.stringify(map);
                    azukiCounter++;
                });
                await client.onItemCancelled(firstVal, (event) => {
                    let map = {};
                    map[0] = event.event_type;
                    map[1] = event.payload;
                    map[2] = event.sent_at;
                    azukiJson[azukiCounter] = JSON.stringify(map);
                    azukiCounter++;
                });
                client.onTraitOffer(firstVal, (event) => {
                    // console.log("Event 4: " + event);
                    let map = {};
                    map[0] = event.event_type;
                    map[1] = event.payload;
                    map[2] = event.sent_at;
                    azukiJson[azukiCounter] = JSON.stringify(map);
                    azukiCounter++;
                });
                client.onItemMetadataUpdated(firstVal, (event) => {
                    // console.log("Event 4: " + event);
                    let map = {};
                    map[0] = event.event_type;
                    map[1] = event.payload;
                    map[2] = event.sent_at;
                    azukiJson[azukiCounter] = JSON.stringify(map);
                    azukiCounter++;
                });
                client.onItemReceivedBid(firstVal, (event) => {
                    // console.log("Event 4: " + event);
                    let map = {};
                    map[0] = event.event_type;
                    map[1] = event.payload;
                    map[2] = event.sent_at;
                    azukiJson[azukiCounter] = JSON.stringify(map);
                    azukiCounter++;
                });
                client.onItemReceivedOffer(firstVal, (event) => {
                    // console.log("Event 4: " + event);
                    let map = {};
                    map[0] = event.event_type;
                    map[1] = event.payload;
                    map[2] = event.sent_at;
                    azukiJson[azukiCounter] = JSON.stringify(map);
                    azukiCounter++;
                });
                client.onItemTransferred(firstVal, (event) => {
                    // console.log("Event 4: " + event);
                    let map = {};
                    map[0] = event.event_type;
                    map[1] = event.payload;
                    map[2] = event.sent_at;
                    azukiJson[azukiCounter] = JSON.stringify(map);
                    azukiCounter++;
                });
                client.onCollectionOffer(firstVal, (event) => {
                    // console.log("Event 4: " + event);
                    let map = {};
                    map[0] = event.event_type;
                    map[1] = event.payload;
                    map[2] = event.sent_at;
                    azukiJson[azukiCounter] = JSON.stringify(map);
                    azukiCounter++;
                });
                await client.onItemSold(secondVal, (event) => {
                    // console.log("Event 4: " + event);
                    let map = {};
                    map[0] = event.event_type;
                    map[1] = event.payload;
                    map[2] = event.sent_at;
                    boredApeJson[boredApeCounter] = JSON.stringify(map);
                    boredApeCounter++;
                });
                await client.onItemListed(secondVal, async (event) => {
                    // console.log("Event 4: " + event);
                    let map = {};
                    map[0] = event.event_type;
                    map[1] = event.payload;
                    map[2] = event.sent_at;
                    boredApeJson[boredApeCounter] = JSON.stringify(map);
                    boredApeCounter++;
                });
                await client.onItemCancelled(secondVal, (event) => {
                    // console.log("Event 4: " + event);
                    let map = {};
                    map[0] = event.event_type;
                    map[1] = event.payload;
                    map[2] = event.sent_at;
                    boredApeJson[boredApeCounter] = JSON.stringify(map);
                    boredApeCounter++;
                });
                client.onTraitOffer(secondVal, (event) => {
                    // console.log("Event 4: " + event);
                    let map = {};
                    map[0] = event.event_type;
                    map[1] = event.payload;
                    map[2] = event.sent_at;
                    boredApeJson[boredApeCounter] = JSON.stringify(map);
                    boredApeCounter++;
                });
                client.onItemMetadataUpdated(secondVal, (event) => {
                    // console.log("Event 4: " + event);
                    let map = {};
                    map[0] = event.event_type;
                    map[1] = event.payload;
                    map[2] = event.sent_at;
                    boredApeJson[boredApeCounter] = JSON.stringify(map);
                    boredApeCounter++;
                });
                client.onItemReceivedBid(secondVal, (event) => {
                    // console.log("Event 4: " + event);
                    let map = {};
                    map[0] = event.event_type;
                    map[1] = event.payload;
                    map[2] = event.sent_at;
                    boredApeJson[boredApeCounter] = JSON.stringify(map);
                    boredApeCounter++;
                });
                client.onItemReceivedOffer(secondVal, (event) => {
                    // console.log("Event 4: " + event);
                    let map = {};
                    map[0] = event.event_type;
                    map[1] = event.payload;
                    map[2] = event.sent_at;
                    boredApeJson[boredApeCounter] = JSON.stringify(map);
                    boredApeCounter++;
                });
                client.onItemTransferred(secondVal, (event) => {
                    // console.log("Event 4: " + event);
                    let map = {};
                    map[0] = event.event_type;
                    map[1] = event.payload;
                    map[2] = event.sent_at;
                    boredApeJson[boredApeCounter] = JSON.stringify(map);
                    boredApeCounter++;
                });
                client.onCollectionOffer(secondVal, (event) => {
                    // console.log("Event 4: " + event);
                    let map = {};
                    map[0] = event.event_type;
                    map[1] = event.payload;
                    map[2] = event.sent_at;
                    boredApeJson[boredApeCounter] = JSON.stringify(map);
                    boredApeCounter++;
                });
                await sleep(300000);
                let finalString = JSON.stringify(azukiJson);
                let finalString2 = JSON.stringify(boredApeJson);
                client.disconnect();
                const bucket = admin.storage().bucket();
                let date = new Date();
                let dateString = date.getDate() + "-" + date.getMonth() + "-" + date.getFullYear();
                let file1 = bucket.file("abrFolder/OpenSea/" + firstVal + "/" + dateString + ".json");
                let file2 = bucket.file("abrFolder/OpenSea/" + secondVal + "/" + dateString + ".json");
                await file1.save(finalString).then(() => console.log("Uploaded Successfully"));
                await file2.save(finalString2).then(() => console.log("Uploaded Successfully2"));
                return null;
            }
            catch (error) {
                console.log("Error: " + error);
                return error;
            }
    });

export const task4Trigger = functions
    .runWith({
        memory: "8GB", timeoutSeconds: 540,
    })
    .https.onRequest(async (request, response) => {
        try {
            let promises = [];
            await client.connect();
            let firstVal = "azuki", secondVal = "boredapeyatchclub";
            await admin
                .firestore()
                .collection("abrCollection")
                .doc("ihrPZABGW0O9VpDtkfbJ")
                .get()
                .then((value) => {
                    firstVal = value.get("firstVal");
                    secondVal = value.get("secondVal");
                });
            let azukiJson = {}, boredApeJson = {};
            let boredApeCounter = 0;
            await client.onItemSold(firstVal, (event) => {
                // console.log("Event: " + event.payload);
                // console.log(event.payload);
                // console.log(event.sent_at);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                if (Object.prototype.hasOwnProperty.call(azukiJson,
                    event.payload.collection.slug)) {
                    let temp:string = azukiJson[event.payload.collection.slug];
                    temp += JSON.stringify(map);
                    azukiJson[event.payload.collection.slug] = temp;
                } else {
                    azukiJson[event.payload.collection.slug] = JSON.stringify(map);
                }
            });
            await client.onItemListed(firstVal, async (event) => {
                // await console.log("Event2: " + event);
                // console.log("Ev: "+ event.payload["collection"]["slug"]);
                // console.log(event.sent_at);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                if (Object.prototype.hasOwnProperty.call(azukiJson,
                    event.payload.collection.slug)) {
                    let temp:string = azukiJson[event.payload.collection.slug];
                    temp += JSON.stringify(map);
                    azukiJson[event.payload.collection.slug] = temp;
                } else {
                    azukiJson[event.payload.collection.slug] = JSON.stringify(map);
                }
            });
            await client.onItemCancelled(firstVal, (event) => {
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                if (Object.prototype.hasOwnProperty.call(azukiJson,
                    event.payload.collection.slug)) {
                    let temp:string = azukiJson[event.payload.collection.slug];
                    temp += JSON.stringify(map);
                    azukiJson[event.payload.collection.slug] = temp;
                } else {
                    azukiJson[event.payload.collection.slug] = JSON.stringify(map);
                }
            });
            client.onTraitOffer(firstVal, (event) => {
                // console.log("Event 4: " + event);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                if (Object.prototype.hasOwnProperty.call(azukiJson,
                    event.payload.collection.slug)) {
                    let temp:string = azukiJson[event.payload.collection.slug];
                    temp += JSON.stringify(map);
                    azukiJson[event.payload.collection.slug] = temp;
                } else {
                    azukiJson[event.payload.collection.slug] = JSON.stringify(map);
                }
            });
            client.onItemMetadataUpdated(firstVal, (event) => {
                // console.log("Event 4: " + event);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                if (Object.prototype.hasOwnProperty.call(azukiJson,
                    event.payload.collection.slug)) {
                    let temp:string = azukiJson[event.payload.collection.slug];
                    temp += JSON.stringify(map);
                    azukiJson[event.payload.collection.slug] = temp;
                } else {
                    azukiJson[event.payload.collection.slug] = JSON.stringify(map);
                }
            });
            client.onItemReceivedBid(firstVal, (event) => {
                // console.log("Event 4: " + event);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                if (Object.prototype.hasOwnProperty.call(azukiJson,
                    event.payload.collection.slug)) {
                    let temp:string = azukiJson[event.payload.collection.slug];
                    temp += JSON.stringify(map);
                    azukiJson[event.payload.collection.slug] = temp;
                } else {
                    azukiJson[event.payload.collection.slug] = JSON.stringify(map);
                }
            });
            client.onItemReceivedOffer(firstVal, (event) => {
                // console.log("Event 4: " + event);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                if (Object.prototype.hasOwnProperty.call(azukiJson,
                    event.payload.collection.slug)) {
                    let temp:string = azukiJson[event.payload.collection.slug];
                    temp += JSON.stringify(map);
                    azukiJson[event.payload.collection.slug] = temp;
                } else {
                    azukiJson[event.payload.collection.slug] = JSON.stringify(map);
                }
            });
            client.onItemTransferred(firstVal, (event) => {
                // console.log("Event 4: " + event);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                if (Object.prototype.hasOwnProperty.call(azukiJson,
                    event.payload.collection.slug)) {
                    let temp:string = azukiJson[event.payload.collection.slug];
                    temp += JSON.stringify(map);
                    azukiJson[event.payload.collection.slug] = temp;
                } else {
                    azukiJson[event.payload.collection.slug] = JSON.stringify(map);
                }
            });
            client.onCollectionOffer(firstVal, (event) => {
                // console.log("Event 4: " + event);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                if (Object.prototype.hasOwnProperty.call(azukiJson,
                    event.payload.collection.slug)) {
                    let temp:string = azukiJson[event.payload.collection.slug];
                    temp += JSON.stringify(map);
                    azukiJson[event.payload.collection.slug] = temp;
                } else {
                    azukiJson[event.payload.collection.slug] = JSON.stringify(map);
                }
            });
            await client.onItemSold(secondVal, (event) => {
                // console.log("Event 444: " + event);
                // console.log(event.payload);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                boredApeJson[boredApeCounter] = JSON.stringify(map);
                boredApeCounter++;
            });
            await client.onItemListed(secondVal, async (event) => {
                // console.log("Event 444: " + event);
                // console.log(event.payload);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                boredApeJson[boredApeCounter] = JSON.stringify(map);
                boredApeCounter++;
            });
            await client.onItemCancelled(secondVal, (event) => {
                // console.log("Event 4: " + event);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                boredApeJson[boredApeCounter] = JSON.stringify(map);
                boredApeCounter++;
            });
            client.onTraitOffer(secondVal, (event) => {
                // console.log("Event 444: " + event);
                // console.log(event.payload);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                boredApeJson[boredApeCounter] = JSON.stringify(map);
                boredApeCounter++;
            });
            client.onItemMetadataUpdated(secondVal, (event) => {
                // console.log("Event 444: " + event);
                // console.log(event.payload);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                boredApeJson[boredApeCounter] = JSON.stringify(map);
                boredApeCounter++;
            });
            client.onItemReceivedBid(secondVal, (event) => {
                // console.log("Event 4: " + event);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                boredApeJson[boredApeCounter] = JSON.stringify(map);
                boredApeCounter++;
            });
            client.onItemReceivedOffer(secondVal, (event) => {
                // console.log("Event 4: " + event);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                boredApeJson[boredApeCounter] = JSON.stringify(map);
                boredApeCounter++;
            });
            client.onItemTransferred(secondVal, (event) => {
                // console.log("Event 4: " + event);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                boredApeJson[boredApeCounter] = JSON.stringify(map);
                boredApeCounter++;
            });
            client.onCollectionOffer(secondVal, (event) => {
                // console.log("Event 4: " + event);
                let map = {};
                map[0] = event.event_type;
                map[1] = event.payload;
                map[2] = event.sent_at;
                boredApeJson[boredApeCounter] = JSON.stringify(map);
                boredApeCounter++;
            });
            await sleep(60000);
            // let finalString = JSON.stringify(azukiJson);
            let finalString2 = JSON.stringify(boredApeJson);
            client.disconnect();
            const bucket = admin.storage().bucket();
            let date = new Date();
            let dateString = date.getDate() + "-" + date.getMonth() + "-" + date.getFullYear();
            for (const key in azukiJson) {
                if (Object.prototype.hasOwnProperty.call(azukiJson, key)) {
                    const element = azukiJson[key];
                    let finalString = JSON.stringify(element);
                    let file1 = bucket.file("abrFolder/OpenSea/" + key + "/" + dateString +
                        "_"+date.getTime()+ ".json");
                    let pr1 = file1.save(finalString).then(() => console.log("Uploaded Successfully"));
                    promises.push(pr1);
                }
            }
            let file2 = bucket.file("abrFolder/OpenSea/" + secondVal + "/" + dateString +
                "_"+date.getTime() + ".json");
            let pr2 = file2.save(finalString2).then(() => console.log("Uploaded Successfully2"));
            promises.push(pr2);
            await Promise.all(promises);
            response.send("F: " + " " + finalString2+" "+secondVal);
            // return null;
        }
        catch (error) {
            console.log("Error: " + error);
            // return error;
            response.send("E: " + error);
        }
    });

export const task42 = functions
    .runWith({
        memory: "8GB", timeoutSeconds: 540,
    })
    .https.onRequest(async (request, response) => {
        try {
            let promises = [];
            let browser: Browser = await puppeteer.launch({
                // headless:false,
                args: [
                "--disable-web-security"
                ]
            });
            let map = new Map<string, number>();
            let cot = 0;
            let docIds = [];
            await admin
            .firestore()
            .collection("messari_chart_trigger")
            .get()
                .then((values) => {
                    values.docs.forEach(element => {
                        if (Object.prototype.hasOwnProperty.call(map, element.get("projectId"))) { 
                            docIds.push(element.id);
                        }
                        console.log("El: " + element.get("projectId"));
                        map[element.get("projectId")] = 0;
                        cot++;
                });
            });
            // let index = 0;
            // let slugLimit = index + 800;
            const page1 = await browser.newPage();
            let jsonObj1 = await page1.goto("https://firebasestorage.googleapis.com/v0/b/stock-up-crypto.appspot.com/o/only_slugs%2Fcrypto%2F1667589951.json?alt=media&token=84c9236d-53d0-414e-8b42-73ac28a31529", {
                "timeout": 60000,
            });
            let jsonVal1 = await jsonObj1.json();
            // let count = 0, ctt = 0;
            // let at = 0,ab=0;
            // console.log("Num: " + map.size);
            // let ba = {};
            for (const key in jsonVal1) {
                if (Object.prototype.hasOwnProperty.call(jsonVal1, key)) {
                    // const element = jsonVal1[key];
                    // if (!Object.prototype.hasOwnProperty.call(map, element["messari_id"])) { 
                    //     if (element["messari_id"] != "#N/A") {
                    //         let pr1 = admin.firestore().collection("messari_chart_trigger").doc()
                    //             .create({
                    //             dynamicId: 0,
                    //             projectId: element["messari_id"]
                    //         });
                    //         promises.push(pr1);
                    //         console.log("Slug: " + element["messari_id"]);
                    //         count++;
                    //     }
                    // } else {
                    //     console.log("Slug2: " + element["messari_id"]);
                    //     ctt++;
                    // }
                    // console.log("Token: " + element["tokenterminal_id"]);
                    // if (element["messari_id"] != "#N/A") {
                    //     if (!Object.prototype.hasOwnProperty.call(map, element["messari_id"])) { 
                    //         ab++;
                    //     } else {
                    //         at++;
                    //         console.log("Messari: " + element["messari_id"]);
                    //     }
                    //     ba[element["messari_id"]] = 0;
                    // } else {
                    //     ctt++;
                    // }
                    // console.log("Messari: " + element["messari_id"]);
                }
                // if (slugLimit == count) {
                //     break;
                // }
            }
            console.log("N: " + docIds.length);
            for (let index = 0; index < docIds.length; index++) {
                const element = docIds[index];
                let pr1 = admin.firestore().collection("messari_chart_trigger")
                    .doc(element).delete();
                promises.push(pr1);
            }

            // for (const key in jsonVal1) {
            //     if (Object.prototype.hasOwnProperty.call(jsonVal1.collection, key)) {
            //         const element = jsonVal1.collection[key];
            //         // console.log("Has: " + map.has(element["slug"]));
            //         if (!Object.prototype.hasOwnProperty.call(map, element["slug"])) {
            //             let pr1 = admin.firestore().collection("tokenterminal_trigger").doc()
            //                 .create({
            //                 dynamicId: 0,
            //                 projectId: element["slug"]
            //             });
            //             promises.push(pr1);
            //             console.log("Slug: " + element["slug"]);
            //             count++;
            //         } else {
            //             console.log("Slug2: " + element["slug"]);
            //             ctt++;
            //         }
            //     }
            //     if (slugLimit == count) {
            //         break;
            //     }
            // }
            await browser.close();
            // let naa = 0,maa = 0;
            // for (const key in ba) {
            //     if (Object.prototype.hasOwnProperty.call(ba, key)) {
            //         // const element = ba[key];
            //         naa++;
            //     }
            // }
            // for (const key in map) {
            //     if (Object.prototype.hasOwnProperty.call(map, key)) {
            //         // const element = ba[key];
            //         maa++;
            //     }
            // }
            // console.log("C " + ctt+' '+count+" "+ab+" "+at+" "+naa+" "+maa);
            let finalPromise = await Promise.all(promises);
            // response.send("Successfull: "+finalPromise.length+" "+count+" "+ctt+" "+cot);
            response.send("Successfull: "+finalPromise.length+" "+cot);
        }
        catch (error) {
            console.log("Error: " + error);
            response.send("Err: " + error);
        }
    });

export const task43 = functions
    .runWith({
        memory: "8GB", timeoutSeconds: 540,
    })
    .https.onRequest(async (request, response) => {
        try {
            let promises = [];
            let browser: Browser = await puppeteer.launch({
                // headless:false,
                args: [
                "--disable-web-security"
                ]
            });
            let map = new Map<string, number>();
            await admin
            .firestore()
            .collection("messari_chart_trigger")
            .get()
                .then((values) => {
                    values.docs.forEach(element => {
                        console.log("El: " + element.get("projectId"));
                    map[element.get("projectId")] = 0;
                });
            });
            let index = 0;
            let slugLimit = index + 800;
            const page1 = await browser.newPage();
            let jsonObj1 = await page1.goto("https://firebasestorage.googleapis.com/v0/b/stock-up-crypto.appspot.com/o/only_slugs%2Fnft%2F1666272656.json?alt=media&token=4d9a1109-9e1f-4eea-8b08-9ebda6d47f66", {
                "timeout": 30000,
            });
            let jsonVal1 = await jsonObj1.json();
            let count = 0, ctt = 0;
            // for (const key in map) {
            //     if (Object.prototype.hasOwnProperty.call(map, key)) {
            //         const element = map[key];
            //         console.log("Elmmm: " + element+" "+map.has(key)+" "+key);
            //     }
            // }
            for (const key in jsonVal1.collection) {
                if (Object.prototype.hasOwnProperty.call(jsonVal1.collection, key)) {
                    const element = jsonVal1.collection[key];
                    // console.log("Has: " + map.has(element["slug"]));
                    if (!Object.prototype.hasOwnProperty.call(map, element["slug"])) {
                        let pr1 = admin.firestore().collection("messari_chart_trigger").doc()
                            .create({
                            dynamicId: 0,
                            projectId: element["slug"]
                        });
                        promises.push(pr1);
                        console.log("Slug: " + element["slug"]);
                        count++;
                    } else {
                        console.log("Slug2: " + element["slug"]);
                        ctt++;
                    }
                }
                if (slugLimit == count) {
                    break;
                }
            }
            await browser.close();
            let finalPromise = await Promise.all(promises);
            response.send("Successfull: "+finalPromise.length+" "+count+" "+ctt);
        }
        catch (error) {
            console.log("Error: " + error);
            response.send("Err: " + error);
        }
    });

export const triggerChunk = functions
    .runWith({
        memory: "8GB", timeoutSeconds: 540,
        serviceAccount:"stock-up-crypto@appspot.gserviceaccount.com"
    })
    .firestore.document("trigger_chunk/{wildCard}").onWrite(async (change) => {
        try {
            let before = change.before.data();
            let after = change.after.data();
            if (after.trigger != before.trigger && after.name=="tokenTerminal") {
                // let promises = [];
                let docIds = [];
                let prev = after.prev;
                let currentCount:number = after.currentCount;
                let totalCount = after.totalCount;
                let lastDoc;
                if (prev) {
                    let docId = after.lastId;
                    lastDoc = await
                        admin.firestore().collection("tokenterminal_trigger").doc(docId);
                }
                if (!prev) {
                    await admin
                    .firestore()
                    .collection("tokenterminal_trigger")
                    .orderBy(admin.firestore.FieldPath.documentId())
                    .limit(40)
                    .get()
                        .then((values) => {
                            values.docs.forEach(element => {
                                docIds.push(element.id);
                            });
                    });
                } else {
                    await admin
                    .firestore()
                    .collection("tokenterminal_trigger")
                    .orderBy(admin.firestore.FieldPath.documentId())
                    .startAfter(lastDoc)
                    .limit(40)
                    .get()
                        .then((values) => {
                        values.docs.forEach(element => {
                            docIds.push(element.id);
                        });
                    });
                }
                // let index = 0;
                let count = 0;
                for (let index = 0; index < docIds.length; index++) {
                    const element = docIds[index];
                    await admin.firestore().collection("tokenterminal_trigger").doc(element)
                    .update({
                        dynamicId: admin.firestore.FieldValue.increment(1),
                    });
                    // promises.push(pr1);
                    // console.log("Slug: " + element);
                    sleep(1000);
                    count++;    
                }
                currentCount += count;
                if (currentCount == totalCount) {
                    await admin.firestore().collection("trigger_chunk").doc(change.after.id)
                    .update({
                        currentCount: 0,
                        prev: false,
                    });
                } else {
                    await admin.firestore().collection("trigger_chunk").doc(change.after.id)
                    .update({
                        prev: true,
                        // trigger: admin.firestore.FieldValue.increment(1),
                        currentCount: currentCount,  
                        lastId: docIds[docIds.length-1]
                    });   
                }
                // let finalPromise = await Promise.all(promises);
            }else if (after.trigger != before.trigger && after.name=="messari") {
                // let promises = [];
                let docIds = [];
                let prev = after.prev;
                let currentCount:number = after.currentCount;
                let totalCount = after.totalCount;
                let lastDoc;
                if (prev) {
                    let docId = after.lastId;
                    lastDoc = await
                        admin.firestore().collection("messari_chart_trigger").doc(docId);
                }
                if (!prev) {
                    await admin
                    .firestore()
                    .collection("messari_chart_trigger")
                    .orderBy(admin.firestore.FieldPath.documentId())
                    .limit(40)
                    .get()
                        .then((values) => {
                            values.docs.forEach(element => {
                                docIds.push(element.id);
                            });
                    });
                } else {
                    await admin
                    .firestore()
                    .collection("messari_chart_trigger")
                    .orderBy(admin.firestore.FieldPath.documentId())
                    .startAfter(lastDoc)
                    .limit(40)
                    .get()
                        .then((values) => {
                        values.docs.forEach(element => {
                            docIds.push(element.id);
                        });
                    });
                }
                // let index = 0;
                let count = 0;
                for (let index = 0; index < docIds.length; index++) {
                    const element = docIds[index];
                    await admin.firestore().collection("messari_chart_trigger").doc(element)
                    .update({
                        dynamicId: admin.firestore.FieldValue.increment(1),
                    });
                    // promises.push(pr1);
                    // console.log("Slug: " + element);
                    sleep(1000);
                    count++;    
                }
                currentCount += count;
                if (currentCount == totalCount) {
                    await admin.firestore().collection("trigger_chunk").doc(change.after.id)
                    .update({
                        currentCount: 0,
                        prev: false,
                    });
                } else {
                    await admin.firestore().collection("trigger_chunk").doc(change.after.id)
                    .update({
                        prev: true,
                        // trigger: admin.firestore.FieldValue.increment(1),
                        currentCount: currentCount,  
                        lastId: docIds[docIds.length-1]
                    });   
                }
                // let finalPromise = await Promise.all(promises);
            }
            return null;
        }
        catch (error) {
            console.log("TriggerChunk Err: " + error);
            return null;
        }
    });

export const scheduler2 = functions
    .runWith({
        memory: "128MB", timeoutSeconds: 120,
        serviceAccount: "stock-up-crypto@appspot.gserviceaccount.com"
    })
    .pubsub.schedule("0 0 */7 * *").onRun(async () => {
    try {
        let docIds = [],docIds2=[];
        await admin
            .firestore()
            .collection("trigger_chunk")
            .get()
            .then((values) => {
                values.forEach((element) => {
                    docIds.push(element.id);
                });
            });
        await admin
            .firestore()
            .collection("nonfungible_trigger")
            .get()
            .then((values) => {
                values.forEach((element) => {
                    docIds2.push(element.id);
                });
            });
            
        for (let index = 0; index < docIds.length; index++) {
            const element = docIds[index];
            await admin.firestore()
                .collection("trigger_chunk")
                .doc(element)
                .update({
                    trigger: admin.firestore.FieldValue.increment(1),
                });
            sleep(2000);
        }
        for (let index = 0; index < docIds2.length; index++) {
            const element = docIds2[index];
            admin.firestore()
                .collection("nonfungible_trigger")
                .doc(element)
                .update({
                    dynamicId: admin.firestore.FieldValue.increment(1),
                });
            sleep(2000);
        }
        return null;
    } catch (error) {
        console.log("Error: " + error);
        return error;
    }       
});

export const scheduler3 = functions
    .runWith({
        memory: "8GB", timeoutSeconds: 540,
        serviceAccount: "stock-up-crypto@appspot.gserviceaccount.com"
    })
    .pubsub.schedule("*/30 * * * *").onRun(async () => {
    try {
        // let promises = [];
        let docIds = [];
        let counts = [];
        // let index = 0;
        // let nftLimit = 50;
        // await admin.firestore().collection("indexCollection").doc("FONXIN5BR4lZvb24zPK9").get()
        // .then((value) => {
        //     index = value.get("index");
        //     assetsDone = value.get("assets");
        // });
        await admin
            .firestore()
            .collection("trigger_chunk")
            .get()
            .then((values) => {
                values.forEach((element) => {
                    docIds.push(element.id);
                    counts.push(element.get("currentCount"));
                });
            });
        for (let index = 0; index < docIds.length; index++) {
            const element = docIds[index];
            if (counts[index] > 0) {
                await admin.firestore()
                .collection("trigger_chunk")
                .doc(element)
                .update({
                    trigger: admin.firestore.FieldValue.increment(1),
                });
            }
            sleep(2000);
        }
        // let browser = await puppeteer.launch({
        //     // headless:false,
        //     args: ["--disable-web-security"],
        // });
        // const page1 = await browser.newPage();
        // let jsonObj1 = await page1.goto("https://firebasestorage.googleapis.com/v0/b/stock-up-crypto.appspot.com/o/only_slugs%2Fnft%2F1666272656.json?alt=media&token=4d9a1109-9e1f-4eea-8b08-9ebda6d47f66", {
        //     timeout: 30000,
        // });
        // let jsonVal1 = await jsonObj1.json();
        // let count = 0,createdNum=0;
        // for (const key in jsonVal1.collection) {
        //     if (count >= index) {
        //         if (Object.prototype.hasOwnProperty.call(jsonVal1.collection, key)) {
        //             const element = jsonVal1.collection[key];
        //             let pr1 = admin.firestore().collection("nftranks_trigger").doc().create({
        //                 slug: element.slug
        //             });
        //             let pr2 = admin.firestore().collection("nftChecklist").doc().create({
        //                 slug: element.slug
        //             });
        //             promises.push(pr1);
        //             promises.push(pr2);
        //             createdNum++;
        //         }
        //         if (createdNum == nftLimit) {
        //             break;
        //         }
        //     }
        //     count++;
        // }
        // await Promise.all(promises);
        // index += 50;
        // await admin.firestore().collection("indexCollection").doc("FONXIN5BR4lZvb24zPK9")
        // .update({
        //     index: index,
        // });
        return null;
    } catch (error) {
        console.log("Error: " + error);
        return error;
    }       
});

// export const task44 = functions
//     .runWith({
//         memory: "1GB",
//         timeoutSeconds: 540,
//     })
//     .https.onRequest(async (request, response) => {
//     try {
//         let promises = [];
//         let browser = await puppeteer.launch({
//             // headless:false,
//             args: ["--disable-web-security"],
//         });
//         const page1 = await browser.newPage();
//         let jsonObj1 = await page1.goto("https://firebasestorage.googleapis.com/v0/b/stock-up-crypto.appspot.com/o/only_slugs%2Fnft%2F1666272656.json?alt=media&token=4d9a1109-9e1f-4eea-8b08-9ebda6d47f66", {
//             timeout: 30000,
//         });
//         let jsonVal1 = await jsonObj1.json();
//         let count = 0,ctm=0;
//         for (const key in jsonVal1.collection) {
//             if (count > 200) {
//                 if (Object.prototype.hasOwnProperty.call(jsonVal1.collection, key)) {
//                     const element = jsonVal1.collection[key];
//                     let pr1 = admin.firestore().collection("nftranks_trigger").doc().create({
//                         slug: element.slug
//                     });
//                     promises.push(pr1);
//                     ctm++;
//                 }
//             }
//             count++;
//         }
//         await Promise.all(promises);
//         response.send("Successfull");
//     } catch (error) {
//         console.log("Error: " + error);
//         response.send("Err: " + error);
//     }
// });

// export const scheduler3 = functions.pubsub.schedule("0 0 0/3 1/1 * ? *").onRun(async () => {
//     try {
//         let docIds = [];
//         await admin
//             .firestore()
//             .collection("tokenterminal_trigger")
//             .get()
//             .then((values) => {
//                 values.forEach((element) => {
//                     docIds.push(element.id);
//                 });
//             });
//         for (let index = 0; index < docIds.length; index++) {
//             const element = docIds[index];
//             await admin.firestore()
//                 .collection("tokenterminal_trigger")
//                 .doc(element)
//                 .update({
//                     trigger: admin.firestore.FieldValue.increment(1),
//                 });
//             sleep(2000);
//         }
//         return null;
//     } catch (error) {
//         console.log("Error: " + error);
//         return error;
//     }       
// });
  
function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}