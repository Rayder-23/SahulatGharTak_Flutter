import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../providers/auth_provider.dart';
import '../providers/city_provider.dart';
import '../utils/constants.dart';
import '../utils/input_formatters.dart';
import '../utils/provider_terms_and_conditions.dart';
import '../widgets/app_toast.dart';
import '../widgets/auth_card_scaffold.dart';
import '../widgets/inline_field_error.dart';
import '../widgets/message_dialog.dart';
import '../widgets/primary_category_dialog.dart';
import '../widgets/terms_and_conditions_section.dart';
import '../widgets/themed_dropdown.dart';
import 'category_picker_screen.dart';
import 'login_screen.dart';
import 'provider_dashboard_screen.dart';
import 'provider_document_upload_screen.dart';

class ProviderRegistrationScreen extends StatefulWidget {
  static const routeName = '/register-provider';
  const ProviderRegistrationScreen({super.key});

  @override
  State<ProviderRegistrationScreen> createState() =>
      _ProviderRegistrationScreenState();
}

class _ProviderRegistrationScreenState
    extends State<ProviderRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cnicController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedGender;
  Set<Category> _selectedCategories = {};
  int? _primaryCategoryId;
  String? _selectedCity;
  bool _obscurePassword = true;
  bool _agreedToTerms = false;
  int _experienceYears = 0;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    _fullNameController.text = currentUser?.username ?? '';
    _phoneController.text = currentUser?.mobileNo ?? '';
    // Gender was already required when this account first registered as a
    // customer - fetch it instead of asking again, seeding from any
    // already-cached client detail (e.g. the user just visited Edit
    // Profile) so there's no flash of an empty value while this resolves.
    final cachedGender = authProvider.clientDetail?.gender;
    if (cachedGender != null && cachedGender.isNotEmpty) _selectedGender = cachedGender;
    _loadGender();
    context.read<CityProvider>().loadCities();
  }

  Future<void> _loadGender() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.fetchClientDetail();
    if (!mounted) return;
    final gender = authProvider.clientDetail?.gender;
    if (gender != null && gender.isNotEmpty) setState(() => _selectedGender = gender);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _cnicController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickCategories() async {
    final result = await Navigator.of(context).push<List<Category>>(
      MaterialPageRoute(
          builder: (_) => CategoryPickerScreen(
              selectedCategoryIds: _selectedCategories.map((c) => c.id).toSet())),
    );
    if (result == null || result.isEmpty || !mounted) return;

    if (result.length == 1) {
      setState(() {
        _selectedCategories = result.toSet();
        _primaryCategoryId = result.first.id;
      });
      return;
    }

    final currentPrimary = _primaryCategoryId;
    final chosen = await showPrimaryCategoryDialog(context, categories: result, initialPrimaryId: currentPrimary);
    if (!mounted) return;
    setState(() {
      _selectedCategories = result.toSet();
      _primaryCategoryId = chosen ?? result.first.id;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategories.isEmpty || _primaryCategoryId == null) {
      showAppToast(context, 'Please select at least one category', type: AppToastType.error);
      return;
    }
    if (_selectedGender == null) {
      showAppToast(context, 'Please select a gender', type: AppToastType.error);
      return;
    }
    if (!_agreedToTerms) {
      showAppToast(context, 'Please agree to the Terms and Conditions', type: AppToastType.error);
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.registerProvider(
      fullName: _fullNameController.text.trim(),
      mobileNo: _phoneController.text.trim(),
      password: _passwordController.text,
      cnic: _cnicController.text.trim(),
      gender: _selectedGender!,
      experienceYears: _experienceYears,
      description: _descriptionController.text.trim(),
      categoryIds: _selectedCategories.map((c) => c.id).toList(),
      primaryCategoryId: _primaryCategoryId!,
      city: _selectedCity,
    );

    if (!mounted) return;

    if (success) {
      await showMessageDialog(
        context,
        title: 'Registration Successful',
        message: 'Registration successful.',
        type: MessageDialogType.success,
      );
      if (!mounted) return;
      final providerUid = authProvider.currentUser?.providerUid;
      if (providerUid != null) {
        Navigator.of(context).pushReplacementNamed(
          ProviderDocumentUploadScreen.routeName,
          arguments: ProviderDocumentUploadArgs(providerUid: providerUid),
        );
      } else {
        // Fallback: providerUid should always be present after a successful registration,
        // but don't strand the user on this screen if it's ever missing.
        Navigator.of(context)
            .pushReplacementNamed(ProviderDashboardScreen.routeName);
      }
    } else {
      await showMessageDialog(
        context,
        title: 'Registration Failed',
        message: authProvider.error ?? 'Registration failed',
        type: MessageDialogType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return AuthCardScaffold(
      title: 'Register as a Service Provider',
      avatarIcon: Icons.engineering,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            authFieldLabel('Full Name'),
            TextFormField(
              controller: _fullNameController,
              decoration: authFieldDecoration(hint: 'Enter your full name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            // Mobile number and gender were already provided when this
            // account first registered as a customer, so they're shown as
            // compact, locked read-only chips side by side instead of two
            // full-height fields repeating information already on file.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _LockedInfoChip(
                    icon: Icons.phone_rounded,
                    label: 'MOBILE NUMBER',
                    value: _phoneController.text.isEmpty ? '-' : _phoneController.text,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LockedInfoChip(
                    icon: Icons.wc_rounded,
                    label: 'GENDER',
                    value: _selectedGender ?? '-',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            authFieldLabel('CNIC'),
            TextFormField(
              controller: _cnicController,
              keyboardType: TextInputType.number,
              inputFormatters: [CnicInputFormatter()],
              decoration: authFieldDecoration(hint: 'XXXXX-XXXXXXX-X').copyWith(
                hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
              ),
              validator: cnicValidator,
            ),
            const SizedBox(height: 20),
            authFieldLabel('Confirm Your Account Password'),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: authFieldDecoration(
                hint: 'Enter your existing account password',
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.black45),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
            ),
            const SizedBox(height: 20),
            authFieldLabel('Categories'),
            FormField<Set<Category>>(
              initialValue: _selectedCategories,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              builder: (state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: () async {
                        await _pickCategories();
                        state.didChange(_selectedCategories);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: InputDecorator(
                        decoration:
                            authFieldDecoration(hint: 'Select your categories')
                                .copyWith(
                          errorText: state.errorText,
                          suffixIcon: const Icon(Icons.chevron_right_rounded,
                              color: Colors.black38),
                        ),
                        child: Text(
                          _selectedCategories.isEmpty
                              ? 'Select your categories'
                              : _selectedCategories.map((c) => c.name).join(', '),
                          style: TextStyle(
                            fontSize: 15,
                            color: _selectedCategories.isEmpty
                                ? Colors.grey.shade600
                                : Colors.black87,
                            fontWeight: _selectedCategories.isEmpty
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (_selectedCategories.length > 1) ...[
                      const SizedBox(height: 10),
                      Text('Set primary category', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedCategories.map((category) {
                          final isPrimary = category.id == _primaryCategoryId;
                          return ChoiceChip(
                            label: Text(category.name),
                            selected: isPrimary,
                            onSelected: (_) => setState(() => _primaryCategoryId = category.id),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                );
              },
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
                  items: cityProvider.cities
                      .map((c) => ThemedDropdownItem(value: c, label: c))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCity = v),
                );
              },
            ),
            const SizedBox(height: 20),
            authFieldLabel('Experience (years)'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE0E0E5)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: kPrimaryColor,
                    onPressed: _experienceYears > 0
                        ? () => setState(() => _experienceYears--)
                        : null,
                  ),
                  Expanded(
                    child: Text(
                      '$_experienceYears ${_experienceYears == 1 ? 'year' : 'years'}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: kPrimaryColor,
                    onPressed: _experienceYears < 50
                        ? () => setState(() => _experienceYears++)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            authFieldLabel('Description'),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration:
                  authFieldDecoration(hint: 'Briefly describe your services'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            TermsAndConditionsSection(
              value: _agreedToTerms,
              onChanged: (v) => setState(() => _agreedToTerms = v),
              termsTitle: providerTermsAndConditionsTitle,
              termsBody: providerTermsAndConditionsBody,
              termsClosing: providerTermsAndConditionsClosing,
            ),
            const SizedBox(height: 28),
            AuthPrimaryButton(
                label: 'Register',
                isLoading: isLoading,
                onPressed: _agreedToTerms ? _submit : null),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account? ',
                    style: TextStyle(color: Colors.black54)),
                InkWell(
                  onTap: () => Navigator.of(context).pushReplacementNamed(
                      LoginScreen.routeName,
                      arguments: 'Provider'),
                  child: const Text('Login',
                      style: TextStyle(
                          color: kPrimaryColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact, locked (non-editable) display of a value already on file for
/// this account - used for Mobile Number/Gender so re-confirming information
/// already provided during customer registration doesn't need a full-height
/// field of its own.
class _LockedInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _LockedInfoChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDEF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black38),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.w600, letterSpacing: 0.3),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF1A2233)),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock_outline, size: 14, color: Colors.black38),
        ],
      ),
    );
  }
}
