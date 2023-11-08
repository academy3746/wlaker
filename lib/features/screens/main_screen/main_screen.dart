// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:walker/constants/sizes.dart';
import 'package:walker/features/widgets/health_info.dart';
import 'package:walker/features/widgets/health_permission_handler.dart';
import 'package:walker/features/widgets/location_info.dart';
import 'package:walker/features/widgets/location_permission_handler.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static String routeName = "/main";

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  /// Import Location Info
  LocationInfo locationInfo = LocationInfo();

  /// GPS Initialize
  Position? currentPosition;

  /// Initialize Address
  String? currentAddress;

  final StreamController<int> _stepsStreamController = StreamController<int>();

  final HealthDataFetcher _healthDataFetcher = HealthDataFetcher();

  /// Get Current Location Values
  Future<void> _determinePosition() async {
    try {
      Position position = await locationInfo.determinePermission();
      String address = await locationInfo.getCurrentAddress(
        position.latitude,
        position.longitude,
      );
      setState(() {
        currentPosition = position;
        currentAddress = address;

        print("현재 위치 값: $currentPosition");
        print("현재 주소: $currentAddress");
      });
    } catch (e) {
      print(e);
    }
  }

  /// Request Location Access Permission & Get Current Place
  Future<void> _requestAndDetermineLocation() async {
    AccessLocationPermissionHandler permissionHandler =
        AccessLocationPermissionHandler(context);
    bool hasLocPermission = await permissionHandler.requestLocationPermission();

    if (hasLocPermission) {
      await _determinePosition();

      locationInfo.getStreaming();
    } else {
      print("위치정보 서비스 권한이 거부되었습니다.");
    }
  }

  Future<void> _fetchStepsPeriodically() async {
    Timer.periodic(
      const Duration(seconds: 15),
          (timer) async {
        print('타이머 작동');
        try {
          int steps = await _healthDataFetcher.fetchSteps();
          print("가져온 걸음 수: $steps");

          if (!_stepsStreamController.isClosed) {
            _stepsStreamController.add(steps);
          }
        } catch (error, stackTrace) {
          print("걸음 수 가져오기 에러: $error");

          if (!_stepsStreamController.isClosed) {
            _stepsStreamController.addError(error, stackTrace);
          }
        }
      },
    );
  }

  Future<void> _requestAndDetermineHealth() async {
    AccessHealthPermissionHandler permissionHandler =
        AccessHealthPermissionHandler(context);

    bool hasHealthPermission =
        await permissionHandler.requestHealthPermission();

    if (hasHealthPermission) {
      print("Access to health data has submitted by user.");
      await _requestAndDetermineLocation();
      await _fetchStepsPeriodically();
    } else {
      print("Access to health data has denied by user.");
    }
  }

  @override
  void initState() {
    super.initState();

    _requestAndDetermineHealth();
  }

  @override
  void dispose() {
    _stepsStreamController.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Demo Application",
          style: TextStyle(
            color: Colors.black,
            fontSize: Sizes.size24,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(
            Sizes.size24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              /// 위도 값
              const Text(
                "위도",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: Sizes.size20,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(
                  top: Sizes.size10,
                  bottom: Sizes.size24,
                ),
                child: Text(
                  currentPosition?.latitude.toString() ?? "위도 값 갱신중",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: Sizes.size16,
                  ),
                ),
              ),

              /// 경도 값
              const Text(
                "경도",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: Sizes.size20,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(
                  top: Sizes.size10,
                  bottom: Sizes.size24,
                ),
                child: Text(
                  currentPosition?.longitude.toString() ?? "경도 값 갱신중",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: Sizes.size16,
                  ),
                ),
              ),

              /// 주소 값
              const Text(
                "현재 위치",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: Sizes.size20,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(
                  top: Sizes.size10,
                  bottom: Sizes.size24,
                ),
                child: Text(
                  "현재 위치는 $currentAddress 입니다.",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: Sizes.size16,
                  ),
                ),
              ),

              /// 현재 걸음 수
              const Text(
                "현재 걸음 수",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: Sizes.size20,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(
                  top: Sizes.size10,
                  bottom: Sizes.size24,
                ),
                child: StreamBuilder<int>(
                  stream: _stepsStreamController.stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        "현재까지 ${snapshot.data}걸음 걸으셨네요!",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: Sizes.size16,
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Text(
                        "걸음 수를 가져오는데 문제가 발생했습니다: ${snapshot.error}",
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: Sizes.size16,
                        ),
                      );
                    } else {
                      return const CircularProgressIndicator.adaptive();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
