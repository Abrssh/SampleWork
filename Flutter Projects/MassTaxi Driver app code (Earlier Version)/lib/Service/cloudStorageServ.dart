import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:downloads_path_provider_28/downloads_path_provider_28.dart'
    as downPath;
// import 'package:path_provider/path_provider.dart' as pathProv;
import 'package:permission_handler/permission_handler.dart';

class CloudStorageService {
  Future<String> uploadImage(File imageToUpload, String folderName) async {
    try {
      String imageFileName = folderName +
          "/" +
          DateTime.now().millisecondsSinceEpoch.toString() +
          ".jpg";
      final firebase_storage.Reference firebaseStorageRef =
          firebase_storage.FirebaseStorage.instance.ref().child(imageFileName);
      firebase_storage.UploadTask uploadTask =
          firebaseStorageRef.putFile(imageToUpload);

      return uploadTask.then((value) async {
        if (value.state == firebase_storage.TaskState.success) {
          String downloadUrl = await value.ref.getDownloadURL();
          return downloadUrl;
        } else {
          return "f";
        }
      });
    } catch (e) {
      return "f";
    }
  }

  Future<bool> downloadAudio(String firebaseUrl, String uniqueName) async {
    try {
      firebase_storage.Reference audioReference =
          firebase_storage.FirebaseStorage.instance.refFromURL(firebaseUrl);
      // Directory pathDir = await pathProv.getExternalStorageDirectory();
      Directory downDir =
          await downPath.DownloadsPathProvider.downloadsDirectory;
      List<String> urlSplit = firebaseUrl.split(".");
      String split2 = urlSplit[urlSplit.length - 1];
      List<String> fileFormat = split2.split("?");
      // print("down path : " + downDir.path);
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        // print("request");
        await Permission.storage.request();
      }

      File localFile =
          File(downDir.path + "/" + uniqueName + "." + fileFormat[0]);

      // File a = await File(downDir.path + "/aaa.txt").create();
      // await a.writeAsString("contents");
      // print("Ada: " + a.path);
      bool result = false;
      await audioReference
          .writeToFile(localFile)
          .then((firebase_storage.TaskSnapshot taskSnapshot) {
        if (taskSnapshot.state == firebase_storage.TaskState.success) {
          result = true;
          print("result success" + localFile.path);
        } else {
          result = false;
        }
      });
      return result;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteFile(String firebaseUrl) async {
    try {
      firebase_storage.Reference imageRef =
          firebase_storage.FirebaseStorage.instance.refFromURL(firebaseUrl);
      bool result = await imageRef
          .delete()
          .then((value) => true)
          .catchError((error) => false);
      return result;
    } catch (e) {
      return false;
    }
  }
}
