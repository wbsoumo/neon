import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordMode = true; // Toggle between Password & MPIN login
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Dynamic Input Mode: 'phone' vs 'email'
  bool _isPhoneInput = false;
  String _selectedCountryCode = "+91";

  final List<Map<String, String>> _countryCodes = [
    {'code': '+91', 'flag': '🇮🇳', 'name': 'India'},
    {'code': '+41', 'flag': '🇨🇭', 'name': 'Switzerland'},
    {'code': '+971', 'flag': '🇦🇪', 'name': 'UAE'},
    {'code': '+65', 'flag': '🇸🇬', 'name': 'Singapore'},
    {'code': '+1', 'flag': '🇺🇸', 'name': 'USA'},
    {'code': '+1', 'flag': '🇨🇦', 'name': 'Canada'},
    {'code': '+61', 'flag': '🇦🇺', 'name': 'Australia'},
    {'code': '+44', 'flag': '🇬🇧', 'name': 'UK'},
    {'code': '+49', 'flag': '🇩🇪', 'name': 'Germany'},
    {'code': '+33', 'flag': '🇫🇷', 'name': 'France'},
  ];

  // Controllers
  final TextEditingController _identityController = TextEditingController(); // Email or Mobile
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _identityController.addListener(_detectInputType);
  }

  void _detectInputType() {
    final text = _identityController.text.trim();
    if (text.isEmpty) {
      if (_isPhoneInput) {
        setState(() => _isPhoneInput = false);
      }
      return;
    }

    // If text contains '@' or letters -> Email Mode
    // If text starts with digits or '+' -> Phone Mode
    final hasLetterOrAt = RegExp(r'[a-zA-Z@]').hasMatch(text);
    final isNumeric = RegExp(r'^[0-9+\s\-]+$').hasMatch(text);

    if (isNumeric && !_isPhoneInput) {
      setState(() => _isPhoneInput = true);
    } else if (hasLetterOrAt && _isPhoneInput) {
      setState(() => _isPhoneInput = false);
    }
  }

  @override
  void dispose() {
    _identityController.removeListener(_detectInputType);
    _identityController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final rawIdentity = _identityController.text.trim();
    if (rawIdentity.isEmpty) {
      _showSnackBar("Please enter your registered Mobile Number or Email Address");
      return;
    }

    String fullIdentity = rawIdentity;
    if (_isPhoneInput) {
      if (rawIdentity.length < 6) {
        _showSnackBar("Please enter a valid mobile number");
        return;
      }
      if (!rawIdentity.startsWith('+')) {
        fullIdentity = "$_selectedCountryCode$rawIdentity";
      }
    } else {
      if (!rawIdentity.contains('@') || !rawIdentity.contains('.')) {
        _showSnackBar("Please enter a valid email address (e.g. user@domain.com)");
        return;
      }
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> response;
    if (_isPasswordMode) {
      if (_passwordController.text.isEmpty) {
        _showSnackBar("Please enter your account password");
        setState(() => _isLoading = false);
        return;
      }
      response = await ApiService.loginWithCredentials(fullIdentity, _passwordController.text);
    } else {
      if (_pinController.text.length < 4) {
        _showSnackBar("Please enter your 6-digit Security MPIN");
        setState(() => _isLoading = false);
        return;
      }
      response = await ApiService.loginWithPin(fullIdentity, _pinController.text);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (response['success'] == true && response['user'] != null) {
        final sessionId = response['session_id'] ?? '';
        final user = UserModel.fromJson(response['user'], sessionId: sessionId);
        await ApiService.saveUserSession(user, sessionId);
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => MainNavigationScreen(user: user)),
            (route) => false,
          );
        }
      } else {
        _showSnackBar(response['message'] ?? "Login failed. Please check your credentials.");
      }
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCountryCodePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Select Country Code",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkNavy,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: _countryCodes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _countryCodes[index];
                    return ListTile(
                      leading: Text(item['flag']!, style: const TextStyle(fontSize: 24)),
                      title: Text("${item['name']} (${item['code']})", style: const TextStyle(fontWeight: FontWeight.w700)),
                      onTap: () {
                        setState(() => _selectedCountryCode = item['code']!);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Brand Logo Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.neonPink, AppTheme.neonCyan],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Center(
                        child: Text(
                          "neon",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Neon Finance",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "International Digital Banking Portal",
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Login Type Switcher Pills
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isPasswordMode = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isPasswordMode ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _isPasswordMode
                                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)]
                                : [],
                          ),
                          child: Text(
                            "Password Login",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: _isPasswordMode ? AppTheme.neonPink : AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isPasswordMode = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isPasswordMode ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: !_isPasswordMode
                                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)]
                                : [],
                          ),
                          child: Text(
                            "Fast MPIN Login",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: !_isPasswordMode ? AppTheme.neonPink : AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Form Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isPhoneInput ? "Mobile Number" : "Email or Mobile Number",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                  if (_isPhoneInput)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.neonCyan.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "PHONE MODE",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkNavy,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _identityController,
                keyboardType: _isPhoneInput ? TextInputType.phone : TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: _isPhoneInput ? "Enter 10-digit phone number" : "Enter Email or Mobile number",
                  prefixIcon: _isPhoneInput
                      ? InkWell(
                          onTap: _showCountryCodePicker,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _countryCodes.firstWhere((c) => c['code'] == _selectedCountryCode)['flag']!,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _selectedCountryCode,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppTheme.darkNavy,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 20),
                              ],
                            ),
                          ),
                        )
                      : const Icon(Icons.mark_email_read_outlined, color: AppTheme.neonPink),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.neonPink, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (_isPasswordMode) ...[
                Text(
                  "Account Password",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: "Enter account password",
                    prefixIcon: const Icon(Icons.lock_person_outlined, color: AppTheme.neonPink),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.neonPink, width: 2),
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  "6-Digit Security MPIN",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: "Enter 6-digit MPIN",
                    prefixIcon: const Icon(Icons.shield_outlined, color: AppTheme.neonPink),
                    counterText: "",
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.neonPink, width: 2),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Submit Login Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonPink,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.verified_user_outlined, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Secure Sign In",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Forgot Password or MPIN?",
                    style: TextStyle(
                      color: AppTheme.neonPink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
