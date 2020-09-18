import 'dart:async';
import 'dart:convert';
import 'dart:io'; //file read and write
import 'package:path_provider/path_provider.dart'; //file directory access
import 'dart:core';
import 'home.dart';

ChartLog chartLog = ChartLog();

//define the file name
String fileName = "homeicu_ecg.log";

// store files class
class ChartLog {
  Directory dir;

  ChartLog();

  init() async {
    if (file == null) {
      // get file access location
      Directory dir = await getApplicationDocumentsDirectory();
      //note: temporary file uses getTemporaryDirectory()
      file = File(dir.path + "/" + fileName);

      if (await file.exists() == false) {
        await file.create();
        print("new file created!");
      }
    }
  }

  IOSink sink;
  File file;

  addToFile(List<int> content) async {
    // create the file stream, if it has not been opened.
    if (sink == null) {
      sink = file.openWrite(mode: FileMode.writeOnlyAppend, encoding: utf8);
    }

    // write content to the file stream
    if (sink != null) {
      //print("history: +${content.length} = ${await file.length()}");
      sink.write(content);
    }
  }

  delete() async {
    await file.delete();
    print("file deleted.");

    await file.create();
    sink = file.openWrite(mode: FileMode.writeOnlyAppend, encoding: utf8);
    print("file re-recreated.");
  }

  Stream<List<int>> readStream;

  readFile(int length, int offsetFromEOF) async {
    // wait the last chart finish
    if (ecgStreamController != null) await ecgStreamController.close();

    //close write stream
    if (sink != null) {
      await sink.close();
      sink = null;
    }

    int fileSize = await file.length();
    print('history file size = $fileSize, read len:$length, offset:$offsetFromEOF');

    /* 
      File: 
      |    <  fileSize     >       |
    start         end             EOF
      |   <length> |<offsetFromEOF>|
    */

    if (offsetFromEOF + length > fileSize)
      readStream = file.openRead(0, offsetFromEOF);
    else
      readStream = file.openRead(
          (fileSize - 1) - offsetFromEOF - length + 1, //start
          (fileSize - 1) - offsetFromEOF); //end
  }
}
