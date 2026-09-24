import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/client_address.dart';
import '../models/service_title.dart';
import '../providers/auth_provider.dart';
import '../providers/client_address_provider.dart';
import '../providers/customer_service_request_provider.dart';
import '../providers/service_title_provider.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/input_formatters.dart';
import '../utils/platform_date_picker.dart';
import '../widgets/app_toast.dart';
import '../widgets/auth_card_scaffold.dart';
import '../widgets/inline_field_error.dart';
import '../widgets/message_dialog.dart';
import '../widgets/themed_dropdown.dart';
import 'add_address_screen.dart';
import 'service_requests_screen.dart';

/// Route arguments for [ServiceRequestFormScreen]: the selected backend
/// [Category] plus the parent service's accent color, so the form's accent
/// matches where the user came from.
class ServiceRequestFormArgs {
  final Category category;
  final Color color;
  const ServiceRequestFormArgs({required this.category, required this.color});
}

class ServiceRequestFormScreen extends StatefulWidget {
  static const routeName = '/service-request/new';
  const ServiceRequestFormScreen({super.key});

  @override
  State<ServiceRequestFormScreen> createState() => _ServiceRequestFormScreenState();
}

/// Sentinel dropdown value for "my job isn't listed" — when selected, the
/// user types their own service title and the description becomes required
/// so staff have enough detail to assign a provider manually.
const String _otherServiceTitleValue = '__other__';

class _ServiceRequestFormScreenState extends State<ServiceRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otherTitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactNoController = TextEditingController();
  final _remarksController = TextEditingController();

  Category? _category;
  Color _accentColor = kPrimaryColor;
  String? _selectedServiceTitle;
  int? _selectedServiceTitleUid;
  double? _selectedBasePrice;
  ClientAddress? _selectedAddress;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isUrgent = false;
  bool _initialized = false;

  String _ownContactPerson = '';
  String _ownContactNo = '';
  bool _useOwnContact = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)!.settings.arguments as ServiceRequestFormArgs;
    _category = args.category;
    _accentColor = args.color;

    final user = context.read<AuthProvider>().currentUser;
    _ownContactPerson = user?.username ?? '';
    _ownContactNo = user?.mobileNo ?? '';
    _contactPersonController.text = _ownContactPerson;
    _contactNoController.text = formatMobileForDisplay(_ownContactNo);

    // didChangeDependencies() runs during the build phase, so calling these
    // synchronously here would notify listeners (via each provider's
    // synchronous pre-await notifyListeners()) while the tree is still
    // building. Defer to after the current frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ServiceTitleProvider>().loadServiceTitles(_category!.id);

      final clientUid = context.read<AuthProvider>().clientUid;
      if (clientUid != null) {
        context.read<ClientAddressProvider>().loadAddresses(clientUid).then((_) {
          if (!mounted) return;
          final addresses = context.read<ClientAddressProvider>().addresses;
          if (addresses.isNotEmpty) {
            setState(() => _selectedAddress = addresses.first);
          }
        });
      }
    });
  }

  bool get _isOtherServiceTitle => _selectedServiceTitle == _otherServiceTitleValue;

  void _selectServiceTitle(String? value, List<ServiceTitle> titles) {
    ServiceTitle? match;
    for (final t in titles) {
      if (t.title == value) {
        match = t;
        break;
      }
    }
    setState(() {
      _selectedServiceTitle = value;
      _selectedServiceTitleUid = match?.id;
      _selectedBasePrice = match?.basePrice;
    });
  }

  @override
  void dispose() {
    _otherTitleController.dispose();
    _descriptionController.dispose();
    _contactPersonController.dispose();
    _contactNoController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showPlatformDatePicker(context, initialDate: now, firstDate: now, lastDate: now.add(const Duration(days: 365)));
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final t = await showPlatformTimePicker(context, initialTime: TimeOfDay.now());
    if (t != null) setState(() => _selectedTime = t);
  }

  String _formatTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _toggleUseOwnContact(bool value) {
    setState(() {
      _useOwnContact = value;
      if (value) {
        _contactPersonController.text = _ownContactPerson;
        _contactNoController.text = formatMobileForDisplay(_ownContactNo);
      } else {
        _contactPersonController.clear();
        _contactNoController.clear();
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAddress == null) {
      showAppToast(context, 'Please select an address', type: AppToastType.error);
      return;
    }
    final clientUid = context.read<AuthProvider>().clientUid;
    if (clientUid == null) return;

    final requestProvider = context.read<CustomerServiceRequestProvider>();
    final success = await requestProvider.createRequest(
      clientUid: clientUid,
      categoryUid: _category!.id,
      clientAddressUid: _selectedAddress!.uid,
      serviceTitle: _isOtherServiceTitle ? _otherTitleController.text.trim() : _selectedServiceTitle!,
      serviceDescription: _descriptionController.text.trim(),
      preferredServiceDate: _selectedDate == null ? '' : DateFormat('yyyy-MM-dd').format(_selectedDate!),
      preferredServiceTime: _selectedTime == null ? '' : _formatTime(_selectedTime!),
      isUrgent: _isUrgent,
      contactPerson: _contactPersonController.text.trim(),
      contactNo: digitsOnlyMobile(_contactNoController.text),
      serviceTitleUid: _selectedServiceTitleUid,
      remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacementNamed(ServiceRequestsScreen.routeName);
    } else {
      await showMessageDialog(
        context,
        title: 'Submission Failed',
        message: requestProvider.error ?? 'Failed to submit request',
        type: MessageDialogType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressState = context.watch<ClientAddressProvider>();
    final saving = context.watch<CustomerServiceRequestProvider>().saving;
    final titleState = context.watch<ServiceTitleProvider>();

    return AuthCardScaffold(
      title: _category?.name ?? 'Service Request',
      subtitle: 'Fill in the details to request this service',
      avatarIcon: Icons.assignment_outlined,
      accentColor: _accentColor,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            authFieldLabel('Estimated Budget'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _accentColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.payments_outlined, size: 18, color: _accentColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedBasePrice != null
                          ? formatCurrency(_selectedBasePrice!)
                          : _selectedServiceTitle == null
                              ? 'Select a service title below to see the estimate'
                              : 'No estimate set for this service yet',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _selectedBasePrice != null ? Colors.black87 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (addressState.loading)
              const Center(child: CircularProgressIndicator())
            else if (addressState.addresses.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    const Icon(Icons.location_off, color: Colors.orange),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('No saved addresses', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('Add an address to continue', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushNamed(AddAddressScreen.routeName),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              )
            else ...[
              authFieldLabel('Service Address'),
              ThemedDropdownField<ClientAddress>(
                value: _selectedAddress,
                hint: 'Select an address',
                items: addressState.addresses
                    .map((a) => ThemedDropdownItem(
                        value: a, label: '${a.addressTitle} — ${a.fullAddress}, ${a.area}, ${a.city}'))
                    .toList(),
                onChanged: (v) => setState(() => _selectedAddress = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
            ],
            const SizedBox(height: 20),
            authFieldLabel('Service Title'),
            if (titleState.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (titleState.error != null && titleState.serviceTitles.isEmpty)
              InlineFieldError(
                message: titleState.error!,
                onRetry: () => context.read<ServiceTitleProvider>().loadServiceTitles(_category!.id),
              )
            else
              ThemedDropdownField<String>(
                value: _selectedServiceTitle,
                hint: 'Select a service title',
                items: [
                  ...titleState.serviceTitles.map((t) => ThemedDropdownItem(value: t.title, label: t.title)),
                  const ThemedDropdownItem(value: _otherServiceTitleValue, label: 'Other (not listed)'),
                ],
                onChanged: (v) => _selectServiceTitle(v, titleState.serviceTitles),
                validator: (v) => v == null ? 'Required' : null,
              ),
            if (_isOtherServiceTitle) ...[
              const SizedBox(height: 20),
              authFieldLabel('Specify Service'),
              TextFormField(
                controller: _otherTitleController,
                decoration: authFieldDecoration(hint: 'What job do you need done?'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ],
            const SizedBox(height: 20),
            authFieldLabel(_isOtherServiceTitle ? 'Service Description' : 'Service Description (optional)'),
            TextFormField(
              controller: _descriptionController,
              decoration: authFieldDecoration(hint: 'Describe what you need'),
              minLines: 2,
              maxLines: 4,
              validator: _isOtherServiceTitle
                  ? (v) => (v == null || v.trim().isEmpty) ? 'Please describe the job so staff can assign a provider' : null
                  : null,
            ),
            const SizedBox(height: 20),
            Material(
              type: MaterialType.card,
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text('Mark as Urgent', style: TextStyle(fontWeight: FontWeight.w600)),
                value: _isUrgent,
                activeThumbColor: _accentColor,
                onChanged: (v) => setState(() => _isUrgent = v),
              ),
            ),
            const SizedBox(height: 20),
            authFieldLabel('On-site Contact'),
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Who should the provider reach out to for this job?',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
            Material(
              type: MaterialType.card,
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text('Same as my account', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  _useOwnContact ? 'Provider will contact you: $_ownContactPerson, $_ownContactNo' : 'Enter a different contact below',
                  style: const TextStyle(fontSize: 12),
                ),
                value: _useOwnContact,
                activeThumbColor: _accentColor,
                onChanged: _toggleUseOwnContact,
              ),
            ),
            const SizedBox(height: 14),
            authFieldLabel('On-site Contact Person'),
            TextFormField(
              controller: _contactPersonController,
              enabled: !_useOwnContact,
              decoration: authFieldDecoration(hint: 'Enter contact person name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            authFieldLabel('On-site Contact Number'),
            TextFormField(
              controller: _contactNoController,
              enabled: !_useOwnContact,
              keyboardType: TextInputType.phone,
              inputFormatters: [MobileNumberInputFormatter()],
              decoration: authFieldDecoration(hint: '03XX-XXXXXXX'),
              validator: !_useOwnContact ? mobileNumberValidator : null,
            ),
            const SizedBox(height: 20),
            authFieldLabel('Remarks (optional)'),
            TextFormField(
              controller: _remarksController,
              decoration: authFieldDecoration(hint: 'Any additional remarks'),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            authFieldLabel('Preferred Date & Time (optional)'),
            Row(
              children: [
                Expanded(
                  child: _PickerField(
                    icon: Icons.calendar_today,
                    label: _selectedDate == null ? 'Preferred Date' : DateFormat.yMMMd().format(_selectedDate!),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerField(
                    icon: Icons.access_time,
                    label: _selectedTime == null ? 'Preferred Time' : _selectedTime!.format(context),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            AuthPrimaryButton(label: 'Submit Request', isLoading: saving, onPressed: _submit, color: _accentColor),
          ],
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerField({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: const Color(0xFFF5F5F7), borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(color: Colors.black87), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
