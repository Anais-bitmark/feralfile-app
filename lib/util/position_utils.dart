import 'package:geocoding/geocoding.dart';

String getLocationName(Placemark placeMark) {
  List<String> locationLevel = [];
  if (placeMark.subLocality != null && placeMark.subLocality!.isNotEmpty) {
    locationLevel.add(placeMark.subLocality!);
  }
  if (placeMark.subAdministrativeArea != null &&
      placeMark.subAdministrativeArea!.isNotEmpty) {
    locationLevel.add(placeMark.subAdministrativeArea!);
  }
  if (placeMark.locality != null && placeMark.locality!.isNotEmpty) {
    locationLevel.add(placeMark.locality!);
  }
  if (placeMark.administrativeArea != null &&
      placeMark.administrativeArea!.isNotEmpty) {
    locationLevel.add(placeMark.administrativeArea!);
  }
  if (placeMark.isoCountryCode != null &&
      placeMark.isoCountryCode!.isNotEmpty) {
    locationLevel.add(placeMark.isoCountryCode!);
  }
  while (locationLevel.length > 3) {
    locationLevel.removeAt(0);
  }
  return locationLevel.join(", ");
}

// get placeMark from longitude and latitude
Future<Placemark?> getPlaceMarkFromCoordinates(
    double latitude, double longitude) async {
  List<Placemark> placeMarks = await placemarkFromCoordinates(
      latitude, longitude,
      localeIdentifier: "en_US");
  if (placeMarks.isEmpty) {
    return null;
  }
  return placeMarks.first;
}

// get location name from longitude and latitude
Future<String> getLocationNameFromCoordinates(
    double latitude, double longitude) async {
  final placeMark = await getPlaceMarkFromCoordinates(latitude, longitude);
  if (placeMark == null) {
    return "";
  }
  return getLocationName(placeMark);
}
