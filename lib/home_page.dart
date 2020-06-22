import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Position _currentPosition;
  String currentPath;
  int timer = 5; // T can be changed
  int counter = 0;
  final databaseReference = Firestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User Location Tracker"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_currentPosition != null)
              Text(
                  "Current Location:\nLAT: ${_currentPosition.latitude} LNG: ${_currentPosition.longitude} \n\nTimestamp: ${new DateTime.now()}\n\n", style: TextStyle(fontSize: 16),),
            FlatButton(
              color: Colors.blue[100],
              child: Text("Start Journey"),
              onPressed: () {
                getPos();
                var fiveSeconds = Duration(seconds: timer);
                Timer.periodic(fiveSeconds, (Timer t) => {readFile()});

                var longSeconds = Duration(seconds: 5, milliseconds: 100);
                Timer.periodic(longSeconds, (Timer t) => {clearFile()});
              },
            ),

            /* FlatButton(
              child: Text("Test Read and Clean function"),
              onPressed: () {
                //readFile();
                clearFile();
              },
            ), */
          ],
        ),
      ),
    );
  }

  _getCurrentLocation() {
    final Geolocator geolocator = Geolocator();

    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
      });
    }).catchError((e) {
      print(e);
    });
  }

  getPos() {
    var geolocator = Geolocator();
    var locationOptions =
        LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 50);
    StreamSubscription<Position> positionStream = geolocator
        .getPositionStream(locationOptions)
        .listen((Position position) {
      setState(() {
        _currentPosition = position;
      });
      writePos(position);
    });
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    File file = File('$path/location.txt');
    currentPath = file.path;
    //print(currentPath);
    return file;
  }

  Future<File> writePos(Position position) async {
    final file = await _localFile;

    return file.writeAsString('$position, ${DateTime.now()}\n',
        mode: FileMode.append);
  }

  Future<void> _uploadFile() async { 
    // this function is not used anywhere at the moment, but you can upload the txt file to 
    // fire storage just in case as a backup storage container. 
    StorageReference storageReference;

    storageReference = FirebaseStorage.instance.ref().child("location.txt");

    File file = new File(currentPath);

    final StorageUploadTask uploadTask = storageReference.putFile(file);
    final StorageTaskSnapshot downloadUrl = (await uploadTask.onComplete);

    final String url = (await downloadUrl.ref.getDownloadURL());
    print("File uploaded after $timer seconds. The URL is $url");
  }

  void _createRecord(List mylist) async {
    DocumentReference ref = await databaseReference.collection("visits").add({
      'userID': counter++,
      'Latitude': mylist[0],
      'Longitude': mylist[1],
      'Timestamp': mylist[2]
    });
    print(ref.documentID);
    //counter++;
  }

  readFile() {
    File data = new File(currentPath);
    data.readAsLines().then(processLines).catchError((e) => handleError(e));
  }

  processLines(List<String> lines) {
    // process lines:
    for (var line in lines) {
      List mylist = line.split(',');
      _createRecord(mylist);
      print('created records');
    }
  }

  handleError(e) {
    print("An error...");
  }

  Future<File> clearFile() async {
    final file = await _localFile;
    return file.writeAsString('');
  }
}
