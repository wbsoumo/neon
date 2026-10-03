import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'main_navigation_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Input Method Tab: 'mobile' vs 'email'
  String _inputTab = 'mobile'; // Default to Mobile Number tab

  // Auth Method: 'password' vs 'pin'
  bool _isPasswordMode = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Selected Country Code (Default +41 Switzerland)
  String _selectedCountryCode = "+41";
  String _countrySearchQuery = "";

  final List<Map<String, String>> _countryCodes = [
    {'code': '+41', 'flag': '🇨🇭', 'name': 'Switzerland', 'currency': 'CHF'},
    {'code': '+91', 'flag': '🇮🇳', 'name': 'India', 'currency': 'INR'},
    {'code': '+971', 'flag': '🇦🇪', 'name': 'United Arab Emirates', 'currency': 'AED'},
    {'code': '+1', 'flag': '🇺🇸', 'name': 'United States', 'currency': 'USD'},
    {'code': '+44', 'flag': '🇬🇧', 'name': 'United Kingdom', 'currency': 'GBP'},
    {'code': '+65', 'flag': '🇸🇬', 'name': 'Singapore', 'currency': 'SGD'},
    {'code': '+49', 'flag': '🇩🇪', 'name': 'Germany', 'currency': 'EUR'},
    {'code': '+33', 'flag': '🇫🇷', 'name': 'France', 'currency': 'EUR'},
    {'code': '+1', 'flag': '🇨🇦', 'name': 'Canada', 'currency': 'CAD'},
    {'code': '+61', 'flag': '🇦🇺', 'name': 'Australia', 'currency': 'AUD'},
  ];

  // Controllers & Focus Nodes
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  final FocusNode _identityFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  String? _identityError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _identityFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    _identityFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    setState(() {
      _identityError = null;
      _passwordError = null;
    });

    if (_inputTab == 'mobile') {
      final phone = _phoneController.text.trim();
      if (phone.isEmpty) {
        setState(() => _identityError = "Please enter your mobile number");
        return false;
      }
      if (phone.length < 6 || !RegExp(r'^[0-9\s\-]+$').hasMatch(phone)) {
        setState(() => _identityError = "Enter a valid international mobile number");
        return false;
      }
    } else {
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        setState(() => _identityError = "Please enter your registered email");
        return false;
      }
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        setState(() => _identityError = "Enter a valid email address (name@example.com)");
        return false;
      }
    }

    if (_isPasswordMode) {
      if (_passwordController.text.isEmpty) {
        setState(() => _passwordError = "Please enter your password");
        return false;
      }
    } else {
      if (_pinController.text.length < 6) {
        setState(() => _passwordError = "Enter your 6-digit MPIN");
        return false;
      }
    }

    return true;
  }

  Future<void> _handleLogin() async {
    if (!_validateInputs()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    String identity = _inputTab == 'mobile'
        ? "$_selectedCountryCode${_phoneController.text.trim()}"
        : _emailController.text.trim();

    Map<String, dynamic> response;
    if (_isPasswordMode) {
      response = await ApiService.loginWithCredentials(identity, _passwordController.text);
    } else {
      response = await ApiService.loginWithPin(identity, _pinController.text);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

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
      _showSnackBar(response['message'] ?? "Invalid authentication credentials. Please try again.");
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          ],
        ),
        backgroundColor: const Color(0xFF991B1B), // Dark Red
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showCountryCodePicker() {
    _countrySearchQuery = "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredList = _countryCodes.where((item) {
              final q = _countrySearchQuery.toLowerCase();
              return item['name']!.toLowerCase().contains(q) || item['code']!.contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Select Country / Code",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkNavy),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (val) => setModalState(() => _countrySearchQuery = val),
                    decoration: InputDecoration(
                      hintText: "Search country or dialing code...",
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: AppTheme.bgLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filteredList.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                      itemBuilder: (context, index) {
                        final item = filteredList[index];
                        final isSelected = item['code'] == _selectedCountryCode;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          leading: Text(item['flag']!, style: const TextStyle(fontSize: 26)),
                          title: Text(item['name']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.darkNavy)),
                          trailing: Text(
                            item['code']!,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: isSelected ? AppTheme.neonPink : AppTheme.textMuted,
                            ),
                          ),
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
      },
    );
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: AppTheme.darkNavy),
            SizedBox(width: 10),
            Text("Reset Account Access", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        content: const Text(
          "For Swiss regulatory security, password & MPIN resets require identity verification. Please contact Neon Finance 24/7 Swiss Support or proceed with email verification.",
          style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.darkNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _showSnackBar("Password reset instructions sent to registered contact.");
            },
            child: const Text("Reset via Verification", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLegalDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.darkNavy)),
        content: SingleChildScrollView(
          child: Text(content, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5)),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.darkNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("I Understand", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeFlag = _countryCodes.firstWhere(
      (c) => c['code'] == _selectedCountryCode,
      orElse: () => _countryCodes.first,
    )['flag']!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // 1. Brand Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.darkNavy,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.darkNavy.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "neon",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Neon Finance",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.darkNavy,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "International Banking & Financial Services",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 2. Login Heading
              const Text(
                "Welcome back",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.darkNavy,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Sign in securely to your Neon Finance account.",
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMuted,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 24),

              // 3. Login Method Selector (Mobile Number vs Email)
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _inputTab = 'mobile';
                            _identityError = null;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _inputTab == 'mobile' ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: _inputTab == 'mobile'
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.phone_android_rounded,
                                size: 16,
                                color: _inputTab == 'mobile' ? AppTheme.darkNavy : AppTheme.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Mobile Number",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _inputTab == 'mobile' ? AppTheme.darkNavy : AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _inputTab = 'email';
                            _identityError = null;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _inputTab == 'email' ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: _inputTab == 'email'
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 16,
                                color: _inputTab == 'email' ? AppTheme.darkNavy : AppTheme.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Email Address",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _inputTab == 'email' ? AppTheme.darkNavy : AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4. Input Fields
              Text(
                _inputTab == 'mobile' ? "Mobile Number" : "Email Address",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkNavy),
              ),
              const SizedBox(height: 8),

              if (_inputTab == 'mobile') ...[
                // Country Code + Mobile Input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _identityError != null
                          ? Colors.red
                          : _identityFocus.hasFocus
                              ? AppTheme.darkNavy
                              : Colors.grey[300]!,
                      width: _identityFocus.hasFocus || _identityError != null ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Country Selector Pill
                      InkWell(
                        onTap: _showCountryCodePicker,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border(right: BorderSide(color: Colors.grey[200]!)),
                            color: AppTheme.bgLight,
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                          ),
                          child: Row(
                            children: [
                              Text(activeFlag, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 6),
                              Text(
                                _selectedCountryCode,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.darkNavy),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 18),
                            ],
                          ),
                        ),
                      ),
                      // Phone Number TextField
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          focusNode: _identityFocus,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: "Enter mobile number",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            isDense: true,
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.darkNavy),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Email TextField
                TextField(
                  controller: _emailController,
                  focusNode: _identityFocus,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "name@example.com",
                    prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppTheme.darkNavy, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _identityError != null ? Colors.red : Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _identityError != null ? Colors.red : AppTheme.darkNavy, width: 1.5),
                    ),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.darkNavy),
                ),
              ],

              if (_identityError != null) ...[
                const SizedBox(height: 6),
                Text(_identityError!, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
              ],

              const SizedBox(height: 18),

              // Auth Type Toggle: Password vs MPIN
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isPasswordMode ? "Password" : "6-Digit Security MPIN",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkNavy),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isPasswordMode = !_isPasswordMode;
                        _passwordError = null;
                      });
                    },
                    child: Text(
                      _isPasswordMode ? "Use MPIN instead" : "Use Password instead",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.neonPink),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_isPasswordMode) ...[
                TextField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: "Enter password",
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.darkNavy, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _passwordError != null ? Colors.red : Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _passwordError != null ? Colors.red : AppTheme.darkNavy, width: 1.5),
                    ),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.darkNavy),
                ),
              ] else ...[
                TextField(
                  controller: _pinController,
                  focusNode: _passwordFocus,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: "••••••",
                    prefixIcon: const Icon(Icons.shield_outlined, color: AppTheme.darkNavy, size: 20),
                    counterText: "",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _passwordError != null ? Colors.red : Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _passwordError != null ? Colors.red : AppTheme.darkNavy, width: 1.5),
                    ),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 6, color: AppTheme.darkNavy),
                ),
              ],

              if (_passwordError != null) ...[
                const SizedBox(height: 6),
                Text(_passwordError!, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
              ],

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showForgotPasswordDialog,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                  child: const Text(
                    "Forgot password?",
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 5. Primary CTA Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkNavy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_rounded, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "Sign In Securely",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // 6. Security Note Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: AppTheme.neonPink, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Secure Login & Encrypted Session",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Your connection is encrypted and account information is protected.",
                            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // 7. New Customer Register Link
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "New to Neon Finance?",
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: const Text(
                        "Create an account",
                        style: TextStyle(color: AppTheme.neonPink, fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 8. Support & Legal Links Footer
              Center(
                child: Column(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text("Support & Assistance", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                            content: const Text(
                              "If you are having trouble signing in, please email support@neon.ch or reach out to your Swiss relationship manager.",
                              style: TextStyle(fontSize: 13, height: 1.4),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.help_outline_rounded, size: 15, color: AppTheme.textMuted),
                      label: const Text(
                        "Need help signing in?",
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _showLegalDialog(
                            "Privacy Policy",
                            "Neon Finance respects client privacy under Swiss Federal Act on Data Protection (FADP) and international standards. All data transmissions are 256-bit encrypted.",
                          ),
                          child: const Text("Privacy Policy", style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text("•", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                        GestureDetector(
                          onTap: () => _showLegalDialog(
                            "Terms & Conditions",
                            "Use of Neon Finance international digital banking services is subject to client account agreements and Swiss financial terms.",
                          ),
                          child: const Text("Terms & Conditions", style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "© 2026 Neon Finance AG. All rights reserved.",
                      style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
