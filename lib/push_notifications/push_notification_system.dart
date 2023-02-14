
import '../global/global.dart';
import '../models/user_ride_request_information.dart';
import '../push_notifications/notification_dialog_box.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PushNotificationSystem
{
  FirebaseMessaging messaging = FirebaseMessaging.instance;




  Future initializeCloudMessaging(BuildContext context) async
  {

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');

    //2. Foreground
    //When the app is open and it receives a push notification
    FirebaseMessaging.onMessage.listen((RemoteMessage? remoteMessage)
    {
      print('Got a message whilst in the foreground!');
      print('Message data: ${remoteMessage?.data}');
      if (remoteMessage?.notification != null) {
        print('Message also contained a notification: ${remoteMessage?.notification}');
      }
      //display ride request information - user information who request a ride
      readUserRideRequestInformation(remoteMessage!.data["rideRequestId"], context);
    });


    //1. Terminated
    //When the app is completely closed and opened directly from the push notification
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? remoteMessage)
    {
      if(remoteMessage != null)
      {
        //display ride request information - user information who request a ride
        readUserRideRequestInformation(remoteMessage.data["rideRequestId"], context);
      }
    });




    //3. Background
    //When the app is in the background and opened directly from the push notification.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? remoteMessage)
    {
      //display ride request information - user information who request a ride
      readUserRideRequestInformation(remoteMessage!.data["rideRequestId"], context);
    });
  }


  readUserRideRequestInformation(String userRideRequestId, BuildContext context)
  {
    FirebaseDatabase.instance.ref()
        .child("All Ride Requests")
        .child(userRideRequestId)
        .once()
        .then((snapData)
    {
      if(snapData.snapshot.value != null)
      {

        double originLat = double.parse((snapData.snapshot.value! as Map)["origin"]["latitude"]);
        double originLng = double.parse((snapData.snapshot.value! as Map)["origin"]["longitude"]);
        String originAddress = (snapData.snapshot.value! as Map)["originAddress"];

        double destinationLat = double.parse((snapData.snapshot.value! as Map)["destination"]["latitude"]);
        double destinationLng = double.parse((snapData.snapshot.value! as Map)["destination"]["longitude"]);
        String destinationAddress = (snapData.snapshot.value! as Map)["destinationAddress"];

        String userName = (snapData.snapshot.value! as Map)["userName"];
        String userPhone = (snapData.snapshot.value! as Map)["userPhone"];

        UserRideRequestInformation userRideRequestDetails = UserRideRequestInformation();

        userRideRequestDetails.originLatLng = LatLng(originLat, originLng);
        userRideRequestDetails.originAddress = originAddress;

        userRideRequestDetails.destinationLatLng = LatLng(destinationLat, destinationLng);
        userRideRequestDetails.destinationAddress = destinationAddress;

        userRideRequestDetails.userName = userName;
        userRideRequestDetails.userPhone = userPhone;

        showDialog(
            context: context,
            builder: (BuildContext context) => NotificationDialogBox(
                userRideRequestDetails: userRideRequestDetails,
            ),
        );
      }
      else
      {
        Fluttertoast.showToast(msg: "This Ride Request Id do not exists.");
      }
    });
  }

  Future generateAndGetToken() async
  {
    String? registrationToken = await messaging.getToken();
    print("FCM Registration Token: ");
    print(registrationToken);

    FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(currentFirebaseUser!.uid)
        .child("token")
        .set(registrationToken);

    messaging.subscribeToTopic("allDrivers");
    messaging.subscribeToTopic("allUsers");
  }
}