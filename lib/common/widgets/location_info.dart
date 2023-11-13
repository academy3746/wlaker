// ignore_for_file: avoid_print

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

class LocationInfo {
  Position? lastPosition;
  String? lastCountryCode;

  /// 위도 및 경도값 GET
  Future<Position> determinePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      print("위치정보 서비스가 비활성화 된 상태입니다.");
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        print("사용자에 의해 위치정보 접근 권한이 거부되었습니다!");
      }
    }

    return await Geolocator.getCurrentPosition(
      timeLimit: const Duration(seconds: 10),
      desiredAccuracy: LocationAccuracy.best,
    );
  }

  /// 위도 및 경도값을 주소 Format으로 타입 변경
  Future<String> getCurrentAddress(double latitude, double longitude) async {
    try {
      List<geocoding.Placemark> placeMarks =
          await geocoding.placemarkFromCoordinates(latitude, longitude);

      if (placeMarks.isNotEmpty) {
        geocoding.Placemark place = placeMarks.first;
        String result = "";

        if (place.locality != null && place.locality!.isNotEmpty) {
          result = place.locality!;
        } else if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty) {
          result = place.subAdministrativeArea!;
        } else if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          result = place.administrativeArea!;
        } else if (place.country != null && place.country!.isNotEmpty) {
          result = place.country!;
        }

        return result;
      }
      return "주소를 찾을 수 없는 위치입니다!";
    } catch (e) {
      print(e);
      return "주소 변환 중 오류가 발생하였습니다!";
    }
  }

  /// 해당 국가 ISO Code GET
  Future<String?> getCountryCode(Position position) async {
    try {
      List<geocoding.Placemark> placeMarks = await geocoding
          .placemarkFromCoordinates(position.latitude, position.longitude);

      var country = placeMarks.first.isoCountryCode;

      print("현재 위치 국가 ISO Code: $country");

      return country;
    } catch (e) {
      print("Fail to get National Code: $e");

      return null;
    }
  }

  /// 위치 변경 여부 Check
  bool hasLocationChanged(Position position) {
    if (lastPosition == null) {
      lastPosition = position;

      return false;
    }

    double distance = Geolocator.distanceBetween(
      lastPosition!.latitude,
      lastPosition!.longitude,
      position.latitude,
      position.longitude,
    );

    if (distance >= 500) {
      lastPosition = position;

      return true;
    }

    return false;
  }

  /// Location Changed (국가 단위)
  Future<void> getStreaming() async {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 500,
    );

    Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) async {
        if (hasLocationChanged(position)) {
          lastPosition = position;

          String? currentCountryCode = await getCountryCode(position);

          if (lastCountryCode != currentCountryCode) {
            print("국가 정보 업데이트: $currentCountryCode");
            lastCountryCode = currentCountryCode;

            String currentAddress =
                await getCurrentAddress(position.latitude, position.longitude);

            print("도시 정보 업데이트: $currentAddress");
          }

          print("위치 정보 업데이트: ${position.toString()}");
        }
      },
    );
  }

  /// Debug Location Changed
  Future<void> debugStreaming() async {
    const double debugLatitude = 37.3316756;
    const double debugLongitude = -122.030189;

    Future.delayed(
      const Duration(seconds: 5),
      () async {
        Position debugPosition = Position(
          latitude: debugLatitude,
          longitude: debugLongitude,
          timestamp: DateTime.now(),
          accuracy: 100.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 100.0,
          altitudeAccuracy: 100.0,
          headingAccuracy: 100.0,
        );

        if (hasLocationChanged(debugPosition)) {
          String? currentCountryCode = await getCountryCode(debugPosition);

          /// Send Push 로직 추후 구성
          if (lastCountryCode != currentCountryCode) {
            print("국가 정보 업데이트: $currentCountryCode");
            lastCountryCode = currentCountryCode;

            String currentAddress = await getCurrentAddress(
                debugPosition.latitude, debugPosition.longitude);
            print("도시 정보 업데이트: $currentAddress");
          }

          print("위치 정보 업데이트: ${debugPosition.toString()}");
          lastPosition = debugPosition;
        }
      },
    );
  }
}