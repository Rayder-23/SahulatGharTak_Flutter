import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/reverse_geocode_result.dart';
import '../services/geocoding_api_service.dart';
import '../utils/constants.dart';
import '../widgets/address_pin_map_view.dart';
import '../widgets/compact_app_header.dart';

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
  final _geocodingApiService = GeocodingApiService();
  final _searchController = TextEditingController();
  GoogleMapController? _mapController;
  Timer? _debounce;
  LatLng? _pin;
  List<ReverseGeocodeResult> _searchResults = [];
  bool _searching = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _pin = widget.initialPin;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searchError = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _runSearch(query.trim()));
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final results = await _geocodingApiService.search(query: query);
      if (!mounted) return;
      setState(() => _searchResults = results);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _searchError = 'Search failed — try again';
      });
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _selectResult(ReverseGeocodeResult result) {
    final target = LatLng(result.latitude, result.longitude);
    setState(() {
      _pin = target;
      _searchResults = [];
      _searchController.text = result.displayName;
    });
    FocusScope.of(context).unfocus();
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 15));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CompactAppHeader(title: 'Pin your location'),
      body: Stack(
        children: [
          AddressPinMapView(
            initialCenter: widget.initialCenter,
            pin: _pin,
            myLocationEnabled: widget.myLocationEnabled,
            onMapCreated: (controller) => _mapController = controller,
            onPinChanged: (v) => setState(() => _pin = v),
          ),
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search a city or area',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : (_searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchResults = [];
                                      _searchError = null;
                                    });
                                  },
                                )
                              : null),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.place_outlined, size: 20),
                          title: Text(result.displayName, maxLines: 2, overflow: TextOverflow.ellipsis),
                          onTap: () => _selectResult(result),
                        );
                      },
                    ),
                  ),
                if (_searchError != null)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: Text(_searchError!, style: const TextStyle(color: Colors.red, fontSize: 12.5)),
                  ),
              ],
            ),
          ),
          if (_pin == null && _searchResults.isEmpty)
            const Positioned(
              top: 70,
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
