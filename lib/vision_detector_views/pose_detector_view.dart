//import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:dino_run/main.dart';

import 'camera_view.dart';
import 'painters/pose_painter.dart';

class PoseDetectorView extends StatefulWidget {
  const PoseDetectorView({super.key});

  @override
  State<StatefulWidget> createState() => _PoseDetectorViewState();
}

class _PoseDetectorViewState extends State<PoseDetectorView> {
  int i = 1;
  double standing_wrist = 0;
  double standing_mid = 0;
  /*double rwrist = 0;
  double lwrist = 0;*/
  int squatno = 0;
  int frame = 0;
  bool fixedAngle = false;
  bool squat = false;

  final PoseDetector _poseDetector =
      PoseDetector(options: PoseDetectorOptions());
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;

  @override
  void dispose() async {
    _canProcess = false;
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CameraView(
      title: 'Pose Detector',
      customPaint: _customPaint,
      text: _text,
      onImage: (inputImage) {
        processImage(inputImage);
      },
    );
  }

  Future<void> processImage(InputImage inputImage) async {
    i++;
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });

    final poses = await _poseDetector.processImage(inputImage);

    for (Pose pose in poses) {
      // to access specific landmarks  [ we need wrist,pinky,index]
      final rightwrist = pose.landmarks[PoseLandmarkType.rightWrist];
      final leftwrist = pose.landmarks[PoseLandmarkType.leftWrist];

      final rightpinky = pose.landmarks[PoseLandmarkType.rightPinky];
      final leftpinky = pose.landmarks[PoseLandmarkType.leftPinky];

      final rightindex = pose.landmarks[PoseLandmarkType.rightIndex];
      final leftindex = pose.landmarks[PoseLandmarkType.leftIndex];

      //print(rightwrist.x);
      //print(leftwrist.x);

      if (rightwrist != null &&
          rightpinky != null &&
          rightindex != null &&
          leftwrist != null &&
          leftpinky != null &&
          leftindex != null) {
        //midpoint of pinky and index
        double rmidx = (rightpinky.x + rightindex.x) / 2;
        //double rmidy = (rightpinky.y + rightindex.y)/2;

        double lmidx = (leftpinky.x + leftindex.x) / 2;
        //double lmidy = (leftpinky.y + leftindex.y)/2;

        print(rmidx);
        print(lmidx);

        //finding vertical and horizontal distancebetween the right and left
        double dx_wrist = rightwrist.x - leftwrist.x;
        //double dy_wrist = rightwrist.y - leftwrist.y;

        double dx_mid = rmidx - lmidx;
        //double dy_mid = rmidy - lmidy;

        print(dx_wrist);
        print(dx_mid);

        changer.selectedOpt = 0;
        changer.notify();

        // Store average value of standing of between 50 and 100 frames
        if (!changer.positionCapture) {
          frame++;
          print("frame no :$frame");
        }

        /*if (frame <= 25) {
          rwrist += rightwrist.x;
          lwrist += leftwrist.x;
          changer.poseStanding = (rwrist - lwrist) / 25;
          changer.notify();
        }*/

        if (frame >= 50 && frame <= 150) {
          standing_wrist += dx_wrist;
          standing_mid += dx_mid;
        }

        if (frame > 150 && !changer.positionCapture) {
          changer.positionCapture = true;
          standing_mid = standing_mid / 100;
          standing_wrist = standing_wrist / 100;
          print(
              "The average horizontal distance of wrist is ${standing_wrist.abs()}");
          print(
              "The average horizontal distance of mid is ${standing_mid.abs()}");
          const snackBar = SnackBar(
            content: Text('you are ready to start'),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }

        // check hand movement

        if (changer.positionCapture && !squat) {
          print("CURRENT  WRIST: ${dx_wrist.abs()}");
          print("CURRENT  MID: ${dx_mid.abs()}");

          if ((dx_wrist.abs() - standing_wrist.abs() > 10 &&
              dx_mid.abs() - standing_mid.abs() > 10)) {
            squat = true;
            squatno++;
            changer.selectedOpt = 1;
            changer.notify();

            print("SQUAT");
          } else {
            changer.selectedOpt = 0;
            changer.notify();
          }
        }

        // check for standing

        if (changer.positionCapture && squat) {
          print("CURRENT ANGLE: ${dx_wrist.abs()}");
          print("CURRENT  MID: ${dx_mid.abs()}");

          if ((dx_wrist.abs() - changer.poseStanding.abs() < 10)) {
            squat = false;
            // print("STAND");
          }
        }

        print("No of squats : $squatno");
      }
    }
    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      final painter = PosePainter(poses, inputImage.inputImageData!.size,
          inputImage.inputImageData!.imageRotation);
      _customPaint = CustomPaint(painter: painter);
    } else {
      _text = 'Poses found: ${poses.length}\n\n';

      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}
