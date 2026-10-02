import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AddBeneficiaryScreen extends StatefulWidget {
  final UserModel user;
  const AddBeneficiaryScreen({super.key, required this.user});

  @override
  State<AddBeneficiaryScreen> createState() => _AddBeneficiaryScreenState();
}

class _AddBeneficiaryScreenState extends State<AddBeneficiaryScreen> {
  int _currentStep = 1;
  bool _isLoading = false;
  bool _isFetchingIfsc = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _accNumController = TextEditingController();
  final TextEditingController _confirmAccNumController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String _accountType = "Savings Account";

  @override
  void initState() {
    super.initState();
    _ifscController.addListener(_onIfscChanged);
  }

  @override
  void dispose() {
    _ifscController.removeListener(_onIfscChanged);
    _nameController.dispose();
    _accNumController.dispose();
    _confirmAccNumController.dispose();
    _ifscController.dispose();
    _bankNameController.dispose();
    _branchController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onIfscChanged() async {
    final cleanIfsc = _ifscController.text.trim().toUpperCase();
    if (cleanIfsc.length == 11) {
      setState(() => _isFetchingIfsc = true);
      try {
        final res = await http.get(Uri.parse("https://ifsc.razorpay.com/$cleanIfsc"));
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          setState(() {
            _bankNameController.text = data['BANK'] ?? '';
            _branchController.text = data['BRANCH'] ?? '';
            if (_nicknameController.text.isEmpty) {
              _nicknameController.text = data['BANK'] ?? '';
            }
          });
        }
      } catch (e) {
        // Fallback silently if offline
      } finally {
        if (mounted) setState(() => _isFetchingIfsc = false);
      }
    }
  }

  Future<void> _submitBeneficiary() async {
    if (_accNumController.text != _confirmAccNumController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account numbers do not match!")),
      );
      return;
    }
    setState(() => _isLoading = true);

    final res = await ApiService.addBeneficiary(
      appId: widget.user.appId,
      name: _nameController.text,
      accountNumber: _accNumController.text,
      ifsc: _ifscController.text,
      bankName: _bankNameController.text,
      accountType: _accountType,
      nickname: _nicknameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Beneficiary Added Successfully')),
      );
      if (res['status'] == 'success' || res['success'] == true) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text("Add Beneficiary", style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Step Indicators
            Row(
              children: [
                _buildStepIndicator(1, "Account Details"),
                Expanded(child: Divider(color: Colors.grey[300])),
                _buildStepIndicator(2, "Additional Info"),
              ],
            ),
            const SizedBox(height: 24),

            if (_currentStep == 1) _buildStep1Form() else _buildStep2Form(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isDone = _currentStep >= step;
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isDone ? AppTheme.neonPink : Colors.grey[300],
          child: Text("$step", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
            color: isDone ? AppTheme.textPrimary : AppTheme.textMuted,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildStep1Form() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Account Details", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: "Beneficiary Full Name",
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _accNumController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Account Number / IBAN",
              prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _confirmAccNumController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Confirm Account Number",
              prefixIcon: const Icon(Icons.check_circle_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _ifscController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: "IFSC Code / Swift Code",
              prefixIcon: const Icon(Icons.business_outlined),
              suffixIcon: _isFetchingIfsc ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2)) : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _bankNameController,
            decoration: InputDecoration(
              labelText: "Bank Name",
              prefixIcon: const Icon(Icons.account_balance_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                if (_nameController.text.isEmpty || _accNumController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all required fields")));
                  return;
                }
                setState(() => _currentStep = 2);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonPink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text("Next Step", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Form() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Additional Information", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(
            controller: _nicknameController,
            decoration: InputDecoration(
              labelText: "Nickname (Optional)",
              prefixIcon: const Icon(Icons.label_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: "Phone Number",
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: "Email Address",
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _currentStep = 1),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text("Back"),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitBeneficiary,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonPink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Add Beneficiary", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
