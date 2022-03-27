import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:random_chat/signaling.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp();
  } else {
    // NOT running on the web!
    await Firebase.initializeApp();
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Signaling signaling = Signaling();
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  RTCSessionDescription? roomCreated;
  String? roomId;
  TextEditingController textEditingController =
      TextEditingController(text: 'test');
  late Stream documentStream;
  @override
  void initState() {
    _localRenderer.initialize();
    _remoteRenderer.initialize();

    FirebaseFirestore db = FirebaseFirestore.instance;
    Stream documentStream =
        FirebaseFirestore.instance.collection('rooms').doc('test').snapshots();

    signaling.onAddRemoteStream = ((stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    signaling.openUserMedia(_localRenderer, _remoteRenderer);

    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome to Flutter Explained - WebRTC"),
      ),
      body: Column(
        children: [
          roomCreated == null
              ? ElevatedButton(
                  onPressed: () async {
                    roomCreated = await signaling.createRoom(_remoteRenderer);
                    roomId = "test";
                    textEditingController.text = roomId!;
                    setState(() {
                      roomCreated != null;
                    });
                  },
                  child: Text("Create room"),
                )
              : Text("You created room"),
          SizedBox(
            width: 8,
          ),
          ElevatedButton(
            onPressed: () {
              // Add roomId
              signaling.joinRoom(
                textEditingController.text,
                _remoteRenderer,
              );
            },
            child: Text("Join room"),
          ),
          SizedBox(
            width: 8,
          ),
          ElevatedButton(
            onPressed: () {
              signaling.hangUp(_localRenderer);
            },
            child: Text("Hangup"),
          ),
          SizedBox(height: 8),

          // RTCVideoView(_localRenderer, mirror: true),
          // RTCVideoView(_remoteRenderer),
          Center(
              child: Stack(
                  alignment: AlignmentDirectional.topStart,
                  children: <Widget>[
                Container(
                  margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(color: Colors.black54),
                  child: RTCVideoView(_localRenderer, mirror: true),
                )
              ])),
          Text("The one you are talking to"),
          Center(
              child: Stack(
                  alignment: AlignmentDirectional.topStart,
                  children: <Widget>[
                Container(
                  margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(color: Colors.black54),
                  child: RTCVideoView(_remoteRenderer),
                )
              ]))
          // Padding(
          //   padding: const EdgeInsets.all(8.0),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       Text("Join the following Room: "),
          //       Flexible(
          //         child: TextFormField(
          //           controller: textEditingController,
          //         ),
          //       )
          //     ],
          //   ),
          // ),
          // SizedBox(height: 8)
        ],
      ),
    );
  }
}
