import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../utils/constants.dart';
import '../../../widgets/compact_app_header.dart';

/// Read-only map showing the client's dropped pin for a booking's address —
/// opened from [BookingDetailScreen] via a map icon next to the address row.
/// Unlike [AddressPinMapView] (used for picking a pin), the marker here is
/// fixed/non-draggable and there is no confirm action; the provider can only
/// look, not edit.
class ClientLocationMapScreen extends StatelessWidget {
  final LatLng location;
  final String? addressLabel;

  const ClientLocationMapScreen({super.key, required this.location, this.addressLabel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CompactAppHeader(title: 'Client Location'),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: location, zoom: 16),
            markers: {Marker(markerId: const MarkerId('client'), position: location)},
            zoomControlsEnabled: false,
          ),
          if (addressLabel != null && addressLabel!.trim().isNotEmpty)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: kPrimaryColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          addressLabel!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF1A2233), height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
