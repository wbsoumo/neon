import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blinkit_series/repository/screens/bottomnav/bottomnavscreen.dart';
import 'package:blinkit_series/repository/services/api_service.dart';

class AddAddressScreen extends StatefulWidget {
  final bool isFirstTime;

  const AddAddressScreen({
    super.key,
    this.isFirstTime = true,
  });

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final TextEditingController _houseNoController = TextEditingController();
  final TextEditingController _areaController = TextEditingController(text: "Krishnanagar, Nadia, West Bengal - 741101");
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _receiverNameController = TextEditingController();
  final TextEditingController _receiverPhoneController = TextEditingController();

  String _selectedTag = "Home";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _receiverNameController.text = prefs.getString('user_name') ?? '';
      String phone = prefs.getString('user_phone') ?? '';
      if (phone.startsWith('+91')) {
        phone = phone.replaceFirst('+91', '').trim();
      }
      _receiverPhoneController.text = phone;
    });
  }

  Future<void> _saveAddress() async {
    if (_houseNoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter House / Flat / Building No."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String fullAddress = "${_houseNoController.text.trim()}, ${_areaController.text.trim()}${_landmarkController.text.trim().isNotEmpty ? ' (Near ${_landmarkController.text.trim()})' : ''}";
    final String receiverPhone = _receiverPhoneController.text.trim().isNotEmpty
        ? "+91${_receiverPhoneController.text.trim()}"
        : "";

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_selected_address', fullAddress);

      // Call API to save address
      await ApiService.storeAddress(
        userPhone: prefs.getString('user_phone') ?? receiverPhone,
        addressType: _selectedTag,
        addressDetails: fullAddress,
        receiverName: _receiverNameController.text.trim().isNotEmpty
            ? _receiverNameController.text.trim()
            : (prefs.getString('user_name') ?? 'Customer'),
        receiverPhone: receiverPhone,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Address saved successfully!"),
            backgroundColor: Color(0XFF0C831F),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        // Even on network timeout, save locally and proceed
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_selected_address', fullAddress);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavScreen()),
          (route) => false,
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
      backgroundColor: const Color(0XFFF5F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: widget.isFirstTime
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Enter Complete Address",
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Step 2 of 2: Save delivery location",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map Mock Card with Location Pin
            Container(
              height: 180,
              width: double.infinity,
              color: Colors.blueGrey.shade100,
              child: Stack(
                children: [
                  // Map Background Image / Graphic
                  Image.network(
                    "https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?w=800&q=80",
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    color: Colors.black.withOpacity(0.15),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0XFF0C831F),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 6),
                            ],
                          ),
                          child: const Text(
                            "Order will be delivered here",
                            style: TextStyle(
                              fontSize: 11,
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

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.my_location, color: Color(0XFF0C831F), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Krishnanagar Main Hub",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                "Standard 10-15 Min Superfast Delivery Available",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tag Selector (Home, Work, Other)
                  const Text(
                    "SAVE ADDRESS AS",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildTagChip("Home", Icons.home_rounded),
                      const SizedBox(width: 10),
                      _buildTagChip("Work", Icons.work_rounded),
                      const SizedBox(width: 10),
                      _buildTagChip("Other", Icons.location_on_rounded),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Form Input Fields
                  _buildInputField(
                    controller: _houseNoController,
                    label: "House / Flat / Block No. *",
                    hint: "e.g. Flat 4B, Sunflower Apartments",
                    icon: Icons.business,
                  ),
                  const SizedBox(height: 14),

                  _buildInputField(
                    controller: _areaController,
                    label: "Apartment / Road / Area *",
                    hint: "e.g. Court Road, Krishnanagar",
                    icon: Icons.map,
                  ),
                  const SizedBox(height: 14),

                  _buildInputField(
                    controller: _landmarkController,
                    label: "Nearby Landmark (Optional)",
                    hint: "e.g. Near Collectorate Office",
                    icon: Icons.storefront,
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "RECEIVER DETAILS",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildInputField(
                    controller: _receiverNameController,
                    label: "Receiver Name",
                    hint: "Enter receiver's name",
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 14),

                  _buildInputField(
                    controller: _receiverPhoneController,
                    label: "Receiver Phone Number",
                    hint: "10-digit mobile number",
                    icon: Icons.phone_android,
                    keyboardType: TextInputType.phone,
                    prefixText: "+91 ",
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0XFF0C831F),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              "Save Address & Proceed to Shop",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(String tag, IconData icon) {
    final bool isSelected = _selectedTag == tag;
    return ChoiceChip(
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? Colors.white : const Color(0XFF0C831F),
      ),
      label: Text(
        tag,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0XFF0C831F),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? const Color(0XFF0C831F) : Colors.grey.shade300,
        ),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedTag = tag;
          });
        }
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(icon, color: const Color(0XFF0C831F), size: 20),
            prefixText: prefixText,
            prefixStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
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
      ],
    );
  }
}
