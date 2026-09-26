import 'package:flutter/material.dart';
import 'package:blinkit_series/repository/screens/bottomnav/bottomnavscreen.dart';
import 'package:blinkit_series/repository/screens/login/registerscreen.dart';
import 'package:blinkit_series/repository/services/api_service.dart';
import 'package:blinkit_series/repository/widgets/uihelper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  final List<String> _gridImages = const [
    "image 41.png",
    "image 42.png",
    "image 43.png",
    "image 44 (1).png",
    "image 35.png",
    "image 50.png",
    "image 52.png",
    "image 53.png",
  ];

  Future<void> _handleLogin() async {
    final phoneInput = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phoneInput.length != 10) {
      _showError("Please enter a valid 10-digit mobile number");
      return;
    }

    if (password.isEmpty) {
      _showError("Please enter your password");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String fullPhone = "+91$phoneInput";

    final response = await ApiService.loginUser(
      phone: fullPhone,
      password: password,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? "Welcome back!"),
            backgroundColor: const Color(0XFF0C831F),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavScreen()),
        );
      } else {
        _showError(response['message'] ?? "Invalid mobile number or password.");
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0XFFF9F9F9),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // 1. Top Decorative Product Grid Header
              SizedBox(
                height: 160,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: _gridImages.length,
                    itemBuilder: (context, index) {
                      return UiHelper.CustomImage(
                        img: _gridImages[index],
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                ),
              ),

              // 2. Brand Icon & App Title
              Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  "assets/images/sbmart.png",
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "SB Mart",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0XFF0C831F),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 2),

              const Text(
                "Superfast 10-Minute Grocery Delivery",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0XFF757575),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 16),

              // 3. Login Card Form
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Login to Your Account",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Mobile Number Input (+91 Prefix)
                      const Text(
                        "Mobile Number",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        decoration: InputDecoration(
                          counterText: "",
                          hintText: "Enter 10-digit number",
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.normal),
                          prefixIcon: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text("🇮🇳", style: TextStyle(fontSize: 18)),
                                SizedBox(width: 6),
                                Text(
                                  "+91",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text("|", style: TextStyle(color: Colors.grey, fontSize: 16)),
                              ],
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0XFFF9F9F9),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0XFF0C831F), width: 1.8),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Password Field
                      const Text(
                        "Password",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: "Enter your password",
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0XFF0C831F)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: const Color(0XFFF9F9F9),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0XFF0C831F), width: 1.8),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0XFF0C831F),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  "Login",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Don't have an account -> Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RegisterScreen()),
                              );
                            },
                            child: const Text(
                              "Register Now",
                              style: TextStyle(
                                color: Color(0XFF0C831F),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
