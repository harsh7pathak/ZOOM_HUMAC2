// @dart=2.9

import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zoom_plugin/zoom_options.dart';
import 'package:flutter_zoom_plugin/zoom_view.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome to Flutter',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Welcome to Flutter'),
        ),
        body:  Center(
          child: InkWell(
            onTap: ()
            {
              Navigator.push(context, MaterialPageRoute(builder: (context) => MeetingWidget()));
            },
          ),
        ),
      ),
    );
  }
}

class MeetingWidget extends StatelessWidget {

  ZoomOptions zoomOptions;
  ZoomMeetingOptions meetingOptions;

  Timer timer;

  MeetingWidget({Key key, meetingId, meetingPassword}) : super(key: key) {
    // Setting up the Zoom credentials
    this.zoomOptions = new ZoomOptions(
      domain: "zoom.us",
      appKey: "appKey", // Replace with with key got from the Zoom Marketplace
      appSecret: "appSecret", // Replace with with secret got from the Zoom Marketplace
    );

    // Setting Zoom meeting options (default to false if not set)
    this.meetingOptions = new ZoomMeetingOptions(
        userId: 'example',
        meetingId: meetingId,
        meetingPassword: meetingPassword,
        disableDialIn: "true",
        disableDrive: "true",
        disableInvite: "true",
        disableShare: "true",
        noAudio: "false",
        noDisconnectAudio: "false"
    );
  }

  bool _isMeetingEnded(String status) {
    var result = false;

    if (Platform.isAndroid)
      result = status == "MEETING_STATUS_DISCONNECTING" || status == "MEETING_STATUS_FAILED";
    else
      result = status == "MEETING_STATUS_IDLE";

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Loading meeting '),
      ),
      body: Padding(
          padding: EdgeInsets.all(16.0),
          child: ZoomView(onViewCreated: (controller) {

            print("Created the view");

            controller.initZoom(this.zoomOptions)
                .then((results) {

              print("initialised");
              print(results);

              if(results[0] == 0) {

                // Listening on the Zoom status stream (1)
                controller.zoomStatusEvents.listen((status) {

                  print("Meeting Status Stream: " + status[0] + " - " + status[1]);

                  if (_isMeetingEnded(status[0])) {
                    Navigator.pop(context);
                    timer?.cancel();
                  }
                });

                print("listen on event channel");

                controller.joinMeeting(this.meetingOptions)
                    .then((joinMeetingResult) {

                  // Polling the Zoom status (2)
                  timer = Timer.periodic(new Duration(seconds: 2), (timer) {
                    controller.meetingStatus(this.meetingOptions.meetingId)
                        .then((status) {
                      print("Meeting Status Polling: " + status[0] + " - " + status[1]);
                    });
                  });
                });
              }

            }).catchError((error) {
              print(error);
            });
          })
      ),
    );
  }
}