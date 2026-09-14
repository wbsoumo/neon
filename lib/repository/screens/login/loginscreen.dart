import 'package:flutter/material.dart';
import 'package:blinkit_series/repository/screens/bottomnav/bottomnavscreen.dart';
import 'package:blinkit_series/repository/widgets/uihelper.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0XFFF9F9F9),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // 1. Soft Pastel Circles (Bubbles positioned in background)
                Positioned(
                  left: -80,
                  top: -20,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0XFFEBF7EE).withOpacity(0.85),
                    ),
                  ),
                ),
                Positioned(
                  right: -90,
                  top: 120,
                  child: Container(
                    width: 340,
                    height: 340,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0XFFFDF5D6).withOpacity(0.85),
                    ),
                  ),
                ),

                // 2. Main Page Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      // Product Grid Header
                      Expanded(
                        flex: 6,
                        child: GridView.builder(
                          padding: const EdgeInsets.only(top: 10),
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.85,
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

                      const SizedBox(height: 10),

                      // Yellow Blinkit Logo Card
                      Container(
                        height: 64,
                        width: 64,
                        decoration: BoxDecoration(
                          color: const Color(0XFFF7CB45),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: UiHelper.CustomImage(
                            img: "http://images.unsplash.com/photo-1542838132-92c53300491e?w=500&q=80",
                            height: 34,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Headlines
                      const Text(
                        "India’s last minute app",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        "Groceries, essentials and more\ndelivered in minutes.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0XFF757575),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Bottom Login Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Color(0XFFE0F2F1),
                                  child: Icon(Icons.person, color: Color(0XFF00897B), size: 26),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        "Soumojit Saha",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        "8016222991",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0XFF757575),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(40, 30),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    "Edit",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0XFF0C831F),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => const BottomNavScreen()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0XFF0C831F),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.near_me,
                                        color: Color(0XFF0C831F),
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      "Login with ",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      "zomato",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0XFFE8F5E9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.check_circle, color: Color(0XFF0C831F), size: 16),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "Access your saved addresses from Zomato automatically!",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0XFF0C831F),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
