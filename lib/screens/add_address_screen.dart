import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../models/client_address.dart';
import '../providers/auth_provider.dart';
import '../providers/city_provider.dart';
import '../providers/client_address_provider.dart';
import '../services/geocoding_api_service.dart';
import '../services/location_permission_service.dart';
import '../utils/api_error.dart';
import '../widgets/address_pin_map_view.dart';
import '../widgets/app_toast.dart';
import '../widgets/auth_card_scaffold.dart';
import '../widgets/inline_field_error.dart';
import '../widgets/themed_dropdown.dart';
import 'pin_location_fullscreen_screen.dart';

// Default map center when no existing pin and device location is
// unavailable/denied — Karachi, per the confirmed UX spec.
const LatLng _kDefaultMapCenter = LatLng(24.8607, 67.0011);

class AddAddressScreen extends StatefulWidget {
  static const routeName = '/add-address';
  final ClientAddress? existing;
  const AddAddressScreen({super.key, this.existing});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _fullAddressController;
  late final TextEditingController _areaController;
  String? _selectedCity;

  final _locationPermissionService = LocationPermissionService();
  final _geocodingApiService = GeocodingApiService();
  GoogleMapController? _mapController;

  LatLng? _pin;
  bool _resolvingPin = false;
  bool _myLocationEnabled = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.addressTitle ?? '');
    _fullAddressController = TextEditingController(text: existing?.fullAddress ?? '');
    _areaController = TextEditingController(text: existing?.area ?? '');
    _selectedCity = existing?.city;
    if (existing != null && existing.hasLocation && existing.latitude != null && existing.longitude != null) {
      _pin = LatLng(existing.latitude!, existing.longitude!);
    }
    context.read<CityProvider>().loadCities();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnDeviceLocationIfNoPin());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _fullAddressController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _centerOnDeviceLocationIfNoPin() async {
    final result = await _locationPermissionService.ensureLocationPermission();
    if (result != LocationPermissionResult.granted) return;
    if (mounted) setState(() => _myLocationEnabled = true);

    if (_pin != null) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (!mounted || _pin != null) return;
      final target = LatLng(position.latitude, position.longitude);
      _mapController?.animateCamera(CameraUpdate.newLatLng(target));
    } catch (_) {
      // Device location unavailable — keep the default city center.
    }
  }

  Future<void> _openFullscreenPicker() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => PinLocationFullscreenScreen(
          initialCenter: _pin ?? _kDefaultMapCenter,
          initialPin: _pin,
          myLocationEnabled: _myLocationEnabled,
        ),
      ),
    );
    if (result != null) {
      setState(() => _pin = result);
      _mapController?.animateCamera(CameraUpdate.newLatLng(result));
    }
  }

  Future<void> _savePin() async {
    if (_pin == null) return;
    setState(() => _resolvingPin = true);

    try {
      final result = await _geocodingApiService.reverseGeocode(latitude: _pin!.latitude, longitude: _pin!.longitude);
      if (!mounted) return;
      setState(() {
        _areaController.text = result.area.isNotEmpty ? result.area : _areaController.text;
        _fullAddressController.text = result.road.isNotEmpty ? result.road : _fullAddressController.text;
      });
      if (result.city.isNotEmpty) {
        final cities = context.read<CityProvider>().cities;
        final match = cities.firstWhere(
          (c) => c.toLowerCase() == result.city.toLowerCase(),
          orElse: () => '',
        );
        if (match.isNotEmpty) setState(() => _selectedCity = match);
      }
      if (!mounted) return;
      showAppToast(context, 'Pin saved — review the details below', type: AppToastType.success);
    } catch (e) {
      if (!mounted) return;
      showAppToast(context, friendlyErrorMessage(e), type: AppToastType.error);
    } finally {
      if (mounted) setState(() => _resolvingPin = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCity == null) {
      showAppToast(context, 'Please select a city', type: AppToastType.error);
      return;
    }

    final clientUid = context.read<AuthProvider>().clientUid;
    if (clientUid == null) return;

    final addressProvider = context.read<ClientAddressProvider>();
    final existing = widget.existing;

    final success = existing == null
        ? await addressProvider.addAddress(
            clientUid: clientUid,
            addressTitle: _titleController.text.trim(),
            fullAddress: _fullAddressController.text.trim(),
            area: _areaController.text.trim(),
            city: _selectedCity!,
            latitude: _pin?.latitude,
            longitude: _pin?.longitude,
          )
        : await addressProvider.updateAddress(
            addressUid: existing.uid,
            clientUid: clientUid,
            addressTitle: _titleController.text.trim(),
            fullAddress: _fullAddressController.text.trim(),
            area: _areaController.text.trim(),
            city: _selectedCity!,
            latitude: _pin?.latitude ?? existing.latitude,
            longitude: _pin?.longitude ?? existing.longitude,
          );

    if (!mounted) return;

    if (success) {
      showAppToast(context, _isEditing ? 'Address updated' : 'Address added', type: AppToastType.success);
      Navigator.of(context).pop();
    } else {
      final error = addressProvider.error ?? 'Failed to save address';
      showAppToast(context, error, type: AppToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.watch<ClientAddressProvider>().saving;

    return AuthCardScaffold(
      title: _isEditing ? 'Edit Address' : 'Add Address',
      subtitle: _isEditing ? 'Update your saved address details' : 'Save an address for faster bookings',
      avatarIcon: Icons.location_on_outlined,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            authFieldLabel('Pin your location'),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 320,
                child: Stack(
                  children: [
                    AddressPinMapView(
                      initialCenter: _kDefaultMapCenter,
                      pin: _pin,
                      myLocationEnabled: _myLocationEnabled,
                      onMapCreated: (controller) => _mapController = controller,
                      onPinChanged: (v) => setState(() => _pin = v),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        elevation: 2,
                        child: IconButton(
                          onPressed: _openFullscreenPicker,
                          icon: const Icon(Icons.fullscreen_rounded),
                          tooltip: 'Expand map',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _pin == null || _resolvingPin ? null : _savePin,
              icon: _resolvingPin
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.push_pin_outlined, size: 18),
              label: Text(_resolvingPin ? 'Resolving address...' : 'Save Pin'),
            ),
            if (_pin == null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Tap the map to drop a pin', style: TextStyle(color: Colors.grey[600], fontSize: 12.5)),
              ),
            const SizedBox(height: 20),
            authFieldLabel('Address Title'),
            TextFormField(
              controller: _titleController,
              decoration: authFieldDecoration(hint: 'e.g. Home, Office'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            authFieldLabel('Full Address'),
            TextFormField(
              controller: _fullAddressController,
              decoration: authFieldDecoration(hint: 'House no, street, landmark'),
              minLines: 2,
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            authFieldLabel('Area'),
            TextFormField(
              controller: _areaController,
              decoration: authFieldDecoration(hint: 'Enter area'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            authFieldLabel('City'),
            Consumer<CityProvider>(
              builder: (context, cityProvider, _) {
                if (cityProvider.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (cityProvider.error != null && cityProvider.cities.isEmpty) {
                  return InlineFieldError(message: cityProvider.error!, onRetry: cityProvider.loadCities);
                }
                return ThemedDropdownField<String>(
                  value: _selectedCity,
                  hint: 'Select your city',
                  items: cityProvider.cities.map((c) => ThemedDropdownItem(value: c, label: c)).toList(),
                  onChanged: (v) => setState(() => _selectedCity = v),
                );
              },
            ),
            const SizedBox(height: 28),
            AuthPrimaryButton(label: _isEditing ? 'Save Changes' : 'Save Address', isLoading: saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
