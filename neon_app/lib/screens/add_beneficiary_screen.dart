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
  String _beneficiaryType = "OTHER_BANK"; // OTHER_BANK or SELF_BANK

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _accNumController = TextEditingController();
  final TextEditingController _confirmAccNumController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();
  final TextEditingController _dailyLimitController = TextEditingController(text: "50000");
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

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
    _dailyLimitController.dispose();
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
    if (_accNumController.text.trim().isEmpty || _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required account details.")),
      );
      return;
    }

    if (_accNumController.text.trim() != _confirmAccNumController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account numbers do not match!")),
      );
      return;
    }

    final double dailyLimit = double.tryParse(_dailyLimitController.text.trim()) ?? 50000.0;
    if (_beneficiaryType == "OTHER_BANK" && dailyLimit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Daily limit must be greater than 0.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final res = await ApiService.addBeneficiary(
      appId: widget.user.appId,
      name: _nameController.text.trim(),
      accountNumber: _accNumController.text.trim(),
      ifsc: _ifscController.text.trim(),
      bankName: _bankNameController.text.trim(),
      accountType: "Savings Account",
      nickname: _nicknameController.text.trim().isNotEmpty 
          ? _nicknameController.text.trim() 
          : (_bankNameController.text.trim().isNotEmpty ? _bankNameController.text.trim() : "Beneficiary"),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      dailyLimit: dailyLimit,
      type: _beneficiaryType,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      final isSuccess = res['status'] == 'APPROVED' || res['status'] == 'PENDING' || res['success'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Beneficiary added successfully'),
          backgroundColor: isSuccess ? AppTheme.neonPink : AppTheme.dangerRed,
        ),
      );
      if (isSuccess) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text("Add Beneficiary", style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Step Progress Indicator Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  _buildStepChip(1, "Account Details"),
                  Expanded(child: Divider(color: Colors.grey[300], indent: 8, endIndent: 8)),
                  _buildStepChip(2, "Transfer Limits & Info"),
                ],
              ),
            ),
            
            // Main Form Content Scrollable Container
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _currentStep == 1 ? _buildStep1Form() : _buildStep2Form(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepChip(int step, String label) {
    final isActive = _currentStep >= step;
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isActive ? AppTheme.neonPink : Colors.grey[300],
          child: Text(
            "$step",
            style: TextStyle(
              color: isActive ? Colors.white : AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppTheme.textPrimary : AppTheme.textMuted,
            fontSize: 12,
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Select Account Type", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 10),
          
          // Beneficiary Type Switcher Tabs
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _beneficiaryType = "OTHER_BANK"),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _beneficiaryType == "OTHER_BANK" ? AppTheme.neonPink.withValues(alpha: 0.1) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _beneficiaryType == "OTHER_BANK" ? AppTheme.neonPink : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "Other Bank / IBAN",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _beneficiaryType == "OTHER_BANK" ? AppTheme.neonPink : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _beneficiaryType = "SELF_BANK"),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _beneficiaryType == "SELF_BANK" ? AppTheme.neonPink.withValues(alpha: 0.1) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _beneficiaryType == "SELF_BANK" ? AppTheme.neonPink : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "Neon Internal",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _beneficiaryType == "SELF_BANK" ? AppTheme.neonPink : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Input Boxes
          _buildInputBox(
            controller: _nameController,
            label: "Beneficiary Full Name *",
            icon: Icons.person_outline_rounded,
            hint: "e.g. Rahul Sharma",
          ),
          const SizedBox(height: 14),

          _buildInputBox(
            controller: _accNumController,
            label: "Account Number / IBAN *",
            icon: Icons.account_balance_wallet_outlined,
            keyboardType: TextInputType.text,
            hint: _beneficiaryType == "SELF_BANK" ? "11-Digit Neon Account Number" : "Enter Account Number or IBAN",
          ),
          const SizedBox(height: 14),

          _buildInputBox(
            controller: _confirmAccNumController,
            label: "Confirm Account Number *",
            icon: Icons.check_circle_outline_rounded,
            keyboardType: TextInputType.text,
            hint: "Re-enter Account Number",
          ),
          const SizedBox(height: 14),

          if (_beneficiaryType == "OTHER_BANK") ...[
            _buildInputBox(
              controller: _ifscController,
              label: "IFSC / SWIFT Code *",
              icon: Icons.business_rounded,
              hint: "e.g. SBIN0001234",
              suffixWidget: _isFetchingIfsc
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : null,
            ),
            const SizedBox(height: 14),

            _buildInputBox(
              controller: _bankNameController,
              label: "Bank Name *",
              icon: Icons.account_balance_rounded,
              hint: "e.g. State Bank of India",
            ),
            const SizedBox(height: 14),
          ],

          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                if (_nameController.text.trim().isEmpty || _accNumController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill all required account details")),
                  );
                  return;
                }
                setState(() => _currentStep = 2);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonPink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Next Step", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Transfer Limits & Additional Info", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),

          // Daily Transfer Limit Input Box (Mandatory for OTHER_BANK)
          _buildInputBox(
            controller: _dailyLimitController,
            label: "Daily Transfer Limit (₹ / CHF) *",
            icon: Icons.speed_rounded,
            keyboardType: TextInputType.number,
            hint: "e.g. 50000",
          ),
          const SizedBox(height: 14),

          _buildInputBox(
            controller: _nicknameController,
            label: "Beneficiary Nickname *",
            icon: Icons.label_outline_rounded,
            hint: "e.g. Main Salary Account",
          ),
          const SizedBox(height: 14),

          _buildInputBox(
            controller: _phoneController,
            label: "Phone Number (Optional)",
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            hint: "+91 98765 43210",
          ),
          const SizedBox(height: 14),

          _buildInputBox(
            controller: _emailController,
            label: "Email Address (Optional)",
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            hint: "beneficiary@email.com",
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _currentStep = 1),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text("Back", style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitBeneficiary,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonPink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text("Save Beneficiary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInputBox({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    Widget? suffixWidget,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!, width: 1.2),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: AppTheme.neonPink, size: 20),
          suffixIcon: suffixWidget != null ? Padding(padding: const EdgeInsets.all(12), child: suffixWidget) : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.neonPink, width: 1.5),
          ),
        ),
      ),
    );
  }
}
