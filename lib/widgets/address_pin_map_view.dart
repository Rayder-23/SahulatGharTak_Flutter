import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Shared Google Map used for picking an address pin, both inline on
/// [AddAddressScreen] and full-screen via [PinLocationFullscreenScreen] —
/// keeps marker/tap/my-location behavior identical in both places.
class AddressPinMapView extends StatelessWidget {
  final LatLng initialCenter;
  final LatLng? pin;
  final bool myLocationEnabled;
  final ValueChanged<LatLng> onPinChanged;
  final ValueChanged<GoogleMapController>? onMapCreated;

  const AddressPinMapView({
    super.key,
    required this.initialCenter,
    required this.pin,
    required this.onPinChanged,
    this.myLocationEnabled = false,
    this.onMapCreated,
  });

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: pin ?? initialCenter, zoom: 15),
      onMapCreated: onMapCreated,
      onTap: onPinChanged,
      markers: pin == null
          ? const {}
          : {Marker(markerId: const MarkerId('pin'), position: pin!, draggable: true, onDragEnd: onPinChanged)},
      myLocationEnabled: myLocationEnabled,
      myLocationButtonEnabled: myLocationEnabled,
      zoomControlsEnabled: false,
    );
  }
}
