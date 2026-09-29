import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blinkit_series/domain/constants/api_constants.dart';
import 'package:blinkit_series/repository/screens/manager/manager_dashboard_screen.dart';

class ManagerLoginScreen extends StatefulWidget {
  const ManagerLoginScreen({super.key});

  @override
  State<ManagerLoginScreen> createState() => _ManagerLoginScreenState();
}

class _ManagerLoginScreenState extends State<ManagerLoginScreen> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _processLogin() async {
    final login = _loginController.text.trim();
    final password = _passwordController.text.trim();

    if (login.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter Manager Phone/Email and Password."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.managerLogin),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "login": login,
          "password": password,
        }),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        final manager = data['manager'] ?? {};
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_manager_logged_in', true);
        await prefs.setInt('manager_store_id', manager['store_id'] ?? 1);
        await prefs.setString('manager_name', manager['name'] ?? 'Store Manager');
        await prefs.setString('manager_phone', manager['phone'] ?? login);
        await prefs.setString('manager_store_name', manager['store_name'] ?? 'Main Store');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Welcome back, ${manager['name']}! Connected to ${manager['store_name']}"),
              backgroundColor: const Color(0XFF0C831F),
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ManagerDashboardScreen(
                storeId: manager['store_id'] ?? 1,
                storeName: manager['store_name'] ?? 'Main Store',
                managerName: manager['name'] ?? 'Store Manager',
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? "Login failed. Check your store manager credentials."),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Connection error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0XFF0A2C10),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Store Manager Icon Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0XFF0C831F).withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0XFF0C831F), width: 2),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    size: 64,
                    color: Color(0XFF4FC23A),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "SBMart Partner",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const Text(
                  "Dark Store Manager & Order Operations Portal",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 36),

                // Card Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Manager Sign In",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Only authorized store managers can access this area.",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),

                      // Phone / Email field
                      const Text(
                        "Phone Number or Email",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black70),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _loginController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: "Enter manager phone/email",
                          prefixIcon: const Icon(Icons.person_outline, color: Color(0XFF0C831F)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0XFF0C831F), width: 1.8),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Password field
                      const Text(
                        "Password",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black70),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: "Enter password",
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0XFF0C831F)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0XFF0C831F), width: 1.8),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _processLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0XFF0C831F),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  "Login to Store Portal",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 18),
                  label: const Text(
                    "Back to Customer App",
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
