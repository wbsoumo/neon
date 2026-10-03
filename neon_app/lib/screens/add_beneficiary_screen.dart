import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class CountryConfig {
  final String code;
  final String name;
  final String flag;
  final String defaultCurrency;
  final bool isIndia;
  final bool requiresIBAN;
  final String? routingLabel;
  final String? routingHint;

  const CountryConfig({
    required this.code,
    required this.name,
    required this.flag,
    required this.defaultCurrency,
    this.isIndia = false,
    this.requiresIBAN = true,
    this.routingLabel,
    this.routingHint,
  });
}

class AddBeneficiaryScreen extends StatefulWidget {
  final UserModel user;
  const AddBeneficiaryScreen({super.key, required this.user});

  @override
  State<AddBeneficiaryScreen> createState() => _AddBeneficiaryScreenState();
}

class _AddBeneficiaryScreenState extends State<AddBeneficiaryScreen> {
  int _currentStep = 1; // Step 1: Select Country, Step 2: Banking Details, Step 3: Limits & Currency
  bool _isLoading = false;
  bool _isFetchingIfsc = false;
  String _beneficiaryType = "OTHER_BANK"; // OTHER_BANK or SELF_BANK

  // Country Configuration Architecture
  final List<CountryConfig> _supportedCountries = const [
    CountryConfig(code: 'IN', name: 'India', flag: '🇮🇳', defaultCurrency: 'INR', isIndia: true, requiresIBAN: false, routingLabel: 'IFSC Code', routingHint: 'e.g. SBIN0001234'),
    CountryConfig(code: 'CH', name: 'Switzerland', flag: '🇨🇭', defaultCurrency: 'CHF', requiresIBAN: true, routingLabel: 'Clearing / BC Code (Optional)', routingHint: 'e.g. 09000'),
    CountryConfig(code: 'SG', name: 'Singapore', flag: '🇸🇬', defaultCurrency: 'SGD', requiresIBAN: false, routingLabel: 'Bank & Branch Code', routingHint: 'e.g. 7171-001'),
    CountryConfig(code: 'AE', name: 'UAE', flag: '🇦🇪', defaultCurrency: 'AED', requiresIBAN: true),
    CountryConfig(code: 'US', name: 'USA', flag: '🇺🇸', defaultCurrency: 'USD', requiresIBAN: false, routingLabel: 'ABA Routing Number (9-digits)', routingHint: 'e.g. 021000021'),
    CountryConfig(code: 'CA', name: 'Canada', flag: '🇨🇦', defaultCurrency: 'CAD', requiresIBAN: false, routingLabel: 'Transit & Institution No.', routingHint: 'e.g. 00010-004'),
    CountryConfig(code: 'AU', name: 'Australia', flag: '🇦🇺', defaultCurrency: 'AUD', requiresIBAN: false, routingLabel: 'BSB Code (6-digits)', routingHint: 'e.g. 062-000'),
    CountryConfig(code: 'GB', name: 'United Kingdom', flag: '🇬🇧', defaultCurrency: 'GBP', requiresIBAN: true, routingLabel: 'Sort Code (6-digits)', routingHint: 'e.g. 20-00-00'),
    CountryConfig(code: 'DE', name: 'Germany', flag: '🇩🇪', defaultCurrency: 'EUR', requiresIBAN: true),
    CountryConfig(code: 'FR', name: 'France', flag: '🇫🇷', defaultCurrency: 'EUR', requiresIBAN: true),
  ];

  late CountryConfig _selectedCountry;
  String _selectedCurrency = 'CHF';

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _accNumController = TextEditingController();
  final TextEditingController _confirmAccNumController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _swiftController = TextEditingController(text: "UBSWCHZH80A");
  final TextEditingController _routingController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _bankAddressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _dailyLimitController = TextEditingController(text: "50000");
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCountry = _supportedCountries.firstWhere((c) => c.code == 'IN');
    _selectedCurrency = _selectedCountry.defaultCurrency;
    _ifscController.addListener(_onIfscChanged);
  }

  @override
  void dispose() {
    _ifscController.removeListener(_onIfscChanged);
    _nameController.dispose();
    _accNumController.dispose();
    _confirmAccNumController.dispose();
    _ifscController.dispose();
    _swiftController.dispose();
    _routingController.dispose();
    _bankNameController.dispose();
    _bankAddressController.dispose();
    _cityController.dispose();
    _dailyLimitController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onIfscChanged() async {
    if (!_selectedCountry.isIndia) return;
    final cleanIfsc = _ifscController.text.trim().toUpperCase();
    if (cleanIfsc.length == 11) {
      setState(() => _isFetchingIfsc = true);
      try {
        final res = await http.get(Uri.parse("https://ifsc.razorpay.com/$cleanIfsc"));
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          setState(() {
            _bankNameController.text = data['BANK'] ?? '';
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

    final codeUsed = _selectedCountry.isIndia 
        ? _ifscController.text.trim().toUpperCase() 
        : _swiftController.text.trim().toUpperCase();

    final res = await ApiService.addBeneficiary(
      appId: widget.user.appId,
      name: _nameController.text.trim(),
      accountNumber: _accNumController.text.trim(),
      ifsc: codeUsed,
      bankName: _bankNameController.text.trim().isNotEmpty 
          ? _bankNameController.text.trim() 
          : "${_selectedCountry.name} International Bank",
      accountType: "Savings Account (${_selectedCountry.code} - $_selectedCurrency)",
      nickname: _nicknameController.text.trim().isNotEmpty 
          ? _nicknameController.text.trim() 
          : "${_selectedCountry.flag} ${_nameController.text.trim()}",
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
        title: const Text("Add P2B Beneficiary", style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Progress Indicator
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  _buildStepChip(1, "Country"),
                  Expanded(child: Divider(color: Colors.grey[300], indent: 4, endIndent: 4)),
                  _buildStepChip(2, "Banking Info"),
                  Expanded(child: Divider(color: Colors.grey[300], indent: 4, endIndent: 4)),
                  _buildStepChip(3, "Currency & Limit"),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _buildCurrentStepContent(),
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
          radius: 11,
          backgroundColor: isActive ? AppTheme.neonPink : Colors.grey[300],
          child: Text(
            "$step",
            style: TextStyle(
              color: isActive ? Colors.white : AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppTheme.textPrimary : AppTheme.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1CountrySelection();
      case 2:
        return _buildStep2BankingForm();
      case 3:
        return _buildStep3CurrencyAndLimits();
      default:
        return _buildStep1CountrySelection();
    }
  }

  // STEP 1: Country Selection Screen
  Widget _buildStep1CountrySelection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Beneficiary Country",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkNavy),
          ),
          const SizedBox(height: 4),
          const Text(
            "Choose the destination country for this bank beneficiary",
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _supportedCountries.length,
            itemBuilder: (context, index) {
              final country = _supportedCountries[index];
              final isSelected = _selectedCountry.code == country.code;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedCountry = country;
                    _selectedCurrency = country.defaultCurrency;
                  });
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.neonPink.withOpacity(0.06) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppTheme.neonPink : Colors.grey[200]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(country.flag, style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              country.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? AppTheme.neonPink : AppTheme.darkNavy,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                country.defaultCurrency,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => setState(() => _currentStep = 2),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonPink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Continue with ${_selectedCountry.name}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 2: Country-Specific Banking Form
  Widget _buildStep2BankingForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_selectedCountry.flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                "${_selectedCountry.name} Banking Details",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildInputBox(
            controller: _nameController,
            label: "Beneficiary Full Name *",
            icon: Icons.person_outline_rounded,
            hint: "e.g. John Doe / Swiss Trading AG",
          ),
          const SizedBox(height: 14),

          _buildInputBox(
            controller: _accNumController,
            label: _selectedCountry.requiresIBAN ? "IBAN / Account Number *" : "Account Number *",
            icon: Icons.account_balance_wallet_outlined,
            keyboardType: TextInputType.text,
            hint: _selectedCountry.isIndia 
                ? "Enter 11-16 digit Account Number" 
                : (_selectedCountry.requiresIBAN ? "e.g. CH93 0076 2011 6238 5295 7" : "Enter Account Number"),
          ),
          const SizedBox(height: 14),

          _buildInputBox(
            controller: _confirmAccNumController,
            label: "Confirm Account Number / IBAN *",
            icon: Icons.check_circle_outline_rounded,
            keyboardType: TextInputType.text,
            hint: "Re-enter Account Number / IBAN",
          ),
          const SizedBox(height: 14),

          if (_selectedCountry.isIndia) ...[
            _buildInputBox(
              controller: _ifscController,
              label: "IFSC Code *",
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
          ] else ...[
            _buildInputBox(
              controller: _swiftController,
              label: "SWIFT / BIC Code *",
              icon: Icons.language_rounded,
              hint: "e.g. UBSWCHZH80A / CITIUS33",
            ),
            const SizedBox(height: 14),

            if (_selectedCountry.routingLabel != null) ...[
              _buildInputBox(
                controller: _routingController,
                label: "${_selectedCountry.routingLabel!} *",
                icon: Icons.alt_route_rounded,
                hint: _selectedCountry.routingHint ?? "Enter Bank Code",
              ),
              const SizedBox(height: 14),
            ],

            _buildInputBox(
              controller: _bankNameController,
              label: "Bank Name *",
              icon: Icons.account_balance_rounded,
              hint: "e.g. UBS Switzerland AG / DBS Bank",
            ),
            const SizedBox(height: 14),

            _buildInputBox(
              controller: _bankAddressController,
              label: "Bank Address / City",
              icon: Icons.location_on_outlined,
              hint: "e.g. Bahnhofstrasse 45, Zürich",
            ),
          ],

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
                    onPressed: () {
                      if (_nameController.text.trim().isEmpty || _accNumController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please fill all required account details")),
                        );
                        return;
                      }
                      setState(() => _currentStep = 3);
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
                        Text("Next Step", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // STEP 3: Currency & Limits
  Widget _buildStep3CurrencyAndLimits() {
    final availableCurrencies = ['CHF', 'USD', 'EUR', 'INR', 'AED', 'SGD', 'GBP', 'AUD', 'CAD'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Currency & Transfer Limits", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),

          // Currency Dropdown
          const Text("Beneficiary Payout Currency *", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: availableCurrencies.contains(_selectedCurrency) ? _selectedCurrency : 'CHF',
                isExpanded: true,
                items: availableCurrencies.map((c) {
                  return DropdownMenuItem<String>(
                    value: c,
                    child: Row(
                      children: [
                        Icon(Icons.currency_exchange_rounded, color: AppTheme.neonPink, size: 18),
                        const SizedBox(width: 10),
                        Text("$c - Payout Currency", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCurrency = val);
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          _buildInputBox(
            controller: _dailyLimitController,
            label: "Daily Transfer Limit ($_selectedCurrency) *",
            icon: Icons.speed_rounded,
            keyboardType: TextInputType.number,
            hint: "e.g. 50000",
          ),
          const SizedBox(height: 14),

          _buildInputBox(
            controller: _nicknameController,
            label: "Beneficiary Nickname *",
            icon: Icons.label_outline_rounded,
            hint: "e.g. ${_selectedCountry.flag} ${_selectedCountry.name} Account",
          ),
          const SizedBox(height: 14),

          _buildInputBox(
            controller: _phoneController,
            label: "Contact Phone (Optional)",
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            hint: "+41 79 123 45 67",
          ),
          const SizedBox(height: 14),

          _buildInputBox(
            controller: _emailController,
            label: "Contact Email (Optional)",
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            hint: "beneficiary@domain.com",
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _currentStep = 2),
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
          ),
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
