import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class CreateMpinScreen extends StatefulWidget {
  final UserModel user;
  final bool isModalReminder;

  const CreateMpinScreen({
    super.key,
    required this.user,
    this.isModalReminder = false,
  });

  @override
  State<CreateMpinScreen> createState() => _CreateMpinScreenState();
}

class _CreateMpinScreenState extends State<CreateMpinScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;
  int _currentStep = 1; // 1: Enter PIN, 2: Confirm PIN

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _onKeyPress(String val) {
    setState(() => _errorMessage = null);
    final controller = _currentStep == 1 ? _pinController : _confirmPinController;

    if (val == 'backspace') {
      if (controller.text.isNotEmpty) {
        setState(() {
          controller.text = controller.text.substring(0, controller.text.length - 1);
        });
      }
    } else if (controller.text.length < 6) {
      setState(() {
        controller.text += val;
      });

      if (_currentStep == 1 && controller.text.length == 6) {
        // Automatically proceed to confirm step
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) {
            setState(() => _currentStep = 2);
          }
        });
      } else if (_currentStep == 2 && controller.text.length == 6) {
        // Automatically trigger save when confirmation complete
        _handleSaveMpin();
      }
    }
  }

  Future<void> _handleSaveMpin() async {
    final p1 = _pinController.text.trim();
    final p2 = _confirmPinController.text.trim();

    if (p1.length != 6 || !RegExp(r'^\d{6}$').hasMatch(p1)) {
      setState(() {
        _errorMessage = "MPIN must be exactly 6 numeric digits.";
        _currentStep = 1;
        _pinController.clear();
        _confirmPinController.clear();
      });
      return;
    }

    if (p1 != p2) {
      setState(() {
        _errorMessage = "MPINs do not match. Please try setting it again.";
        _currentStep = 1;
        _pinController.clear();
        _confirmPinController.clear();
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final res = await ApiService.createMpin(
      mpin: p1,
      sessionId: widget.user.sessionId,
      appId: widget.user.appId,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text("Transaction MPIN set successfully!", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else {
      setState(() {
        _errorMessage = res['message'] ?? "Failed to set MPIN. Please try again.";
        _currentStep = 1;
        _pinController.clear();
        _confirmPinController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isChanging = widget.user.hasMpin;
    final activeText = _currentStep == 1 ? _pinController.text : _confirmPinController.text;

    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          isChanging ? "Change Security MPIN" : "Set Security MPIN",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.neonPink.withValues(alpha: 0.3), width: 2),
                      ),
                      child: const Icon(Icons.shield_outlined, color: AppTheme.neonPink, size: 44),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _currentStep == 1
                          ? (isChanging ? "Enter New 6-Digit MPIN" : "Create 6-Digit MPIN")
                          : "Confirm 6-Digit MPIN",
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _currentStep == 1
                          ? "This MPIN will protect all your transfers, payouts, and Swiss banking operations."
                          : "Re-enter the 6-digit code to confirm and save your MPIN.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 32),

                    // 6-Digit PIN Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        final isFilled = index < activeText.length;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFilled ? AppTheme.neonPink : Colors.white.withValues(alpha: 0.2),
                            border: Border.all(
                              color: isFilled ? AppTheme.neonPink : Colors.white.withValues(alpha: 0.4),
                              width: 2,
                            ),
                            boxShadow: isFilled
                                ? [
                                    BoxShadow(
                                      color: AppTheme.neonPink.withValues(alpha: 0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : [],
                          ),
                        );
                      }),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                    if (_isSubmitting) ...[
                      const SizedBox(height: 24),
                      const CircularProgressIndicator(color: AppTheme.neonPink),
                    ],
                  ],
                ),
              ),
            ),

            // On-Screen Keypad
            Container(
              padding: const EdgeInsets.only(bottom: 24, top: 12, left: 32, right: 32),
              child: Column(
                children: [
                  for (var row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                    ['', '0', 'backspace']
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: row.map((key) {
                          if (key.isEmpty) {
                            return const SizedBox(width: 70, height: 60);
                          }

                          return InkWell(
                            onTap: _isSubmitting ? null : () => _onKeyPress(key),
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              width: 70,
                              height: 60,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              child: key == 'backspace'
                                  ? const Icon(Icons.backspace_outlined, color: Colors.white, size: 24)
                                  : Text(
                                      key,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
