import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/app_toast.dart';
import '../widgets/auth_card_scaffold.dart';
import '../widgets/message_dialog.dart';

class CustomerEditProfileScreen extends StatefulWidget {
  static const routeName = '/edit-profile';
  const CustomerEditProfileScreen({super.key});

  @override
  State<CustomerEditProfileScreen> createState() => _CustomerEditProfileScreenState();
}

class _CustomerEditProfileScreenState extends State<CustomerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  // CNIC isn't shown on this form (nothing here needs it edited), but the
  // update endpoint's contract still requires a value in the request body -
  // keep whatever the client already has on file and resend it unchanged.
  String _cnic = '';
  String? _selectedGender;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.fetchClientDetail();
    if (!mounted) return;

    final detail = authProvider.clientDetail;
    if (success && detail != null) {
      _nameController.text = detail.fullName;
      _cnic = detail.cnic;
      _selectedGender = detail.gender.isNotEmpty ? detail.gender : null;
    } else {
      setState(() => _loading = false);
      await showMessageDialog(
        context,
        title: 'Could Not Load Profile',
        message: authProvider.error ?? 'Failed to load profile',
        type: MessageDialogType.error,
      );
      return;
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    setState(() => _saving = true);
    final success = await authProvider.updateClientDetail(
      fullName: _nameController.text.trim(),
      cnic: _cnic,
      gender: _selectedGender!,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (success) {
      showAppToast(context, 'Profile updated', type: AppToastType.success);
      Navigator.of(context).pop();
    } else {
      showAppToast(context, authProvider.error ?? 'Failed to update profile', type: AppToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthCardScaffold(
      title: 'Edit Profile',
      subtitle: 'Update your personal details',
      avatarIcon: Icons.person_outline,
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  authFieldLabel('Full Name'),
                  TextFormField(
                    controller: _nameController,
                    decoration: authFieldDecoration(hint: 'Enter your full name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  GenderSelector(
                    initialValue: _selectedGender,
                    onChanged: (value) => setState(() => _selectedGender = value),
                    validator: (v) => v == null ? 'Please select a gender' : null,
                  ),
                  const SizedBox(height: 28),
                  AuthPrimaryButton(label: 'Save Changes', isLoading: _saving, onPressed: _save),
                ],
              ),
            ),
    );
  }
}
