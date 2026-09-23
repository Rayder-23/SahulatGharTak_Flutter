import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../utils/constants.dart';
import '../widgets/address_pin_map_view.dart';

/// Full-screen version of the address pin picker, pushed from
/// [AddAddressScreen] when the inline map feels too small to place an
/// accurate pin. Returns the confirmed [LatLng] via `Navigator.pop`, or
/// `null` if dismissed without confirming.
class PinLocationFullscreenScreen extends StatefulWidget {
  final LatLng initialCenter;
  final LatLng? initialPin;
  final bool myLocationEnabled;

  const PinLocationFullscreenScreen({
    super.key,
    required this.initialCenter,
    this.initialPin,
    this.myLocationEnabled = false,
  });

  @override
  State<PinLocationFullscreenScreen> createState() => _PinLocationFullscreenScreenState();
}

class _PinLocationFullscreenScreenState extends State<PinLocationFullscreenScreen> {
  LatLng? _pin;

  @override
  void initState() {
    super.initState();
    _pin = widget.initialPin;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pin your location'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          AddressPinMapView(
            initialCenter: widget.initialCenter,
            pin: _pin,
            myLocationEnabled: widget.myLocationEnabled,
            onPinChanged: (v) => setState(() => _pin = v),
          ),
          if (_pin == null)
            const Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  child: Text('Tap the map to drop a pin', textAlign: TextAlign.center),
                ),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _pin == null ? null : () => Navigator.of(context).pop(_pin),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Confirm Location'),
            ),
          ),
        ],
      ),
    );
  }
}
