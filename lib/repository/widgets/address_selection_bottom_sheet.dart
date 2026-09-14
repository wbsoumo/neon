import 'package:flutter/material.dart';
import 'package:blinkit_series/repository/screens/bottomnav/bottomnavscreen.dart';

class AddressSelectionBottomSheet extends StatefulWidget {
  final String currentAddress;
  final Function(String selectedAddress)? onAddressSelected;

  const AddressSelectionBottomSheet({
    super.key,
    this.currentAddress = "RATANR FLAT, 11E Krishnanagar Main Hub, Krishnanagar",
    this.onAddressSelected,
  });

  static void show(BuildContext context, {String? currentAddress, Function(String)? onAddressSelected}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddressSelectionBottomSheet(
        currentAddress: currentAddress ?? "RATANR FLAT, 11E Krishnanagar Main Hub, Krishnanagar",
        onAddressSelected: onAddressSelected,
      ),
    );
  }

  @override
  State<AddressSelectionBottomSheet> createState() => _AddressSelectionBottomSheetState();
}

class _AddressSelectionBottomSheetState extends State<AddressSelectionBottomSheet> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _savedAddresses = [
    {
      "type": "Home",
      "distance": "37 km",
      "address": "11E, Krishnanagar",
      "phone": "+91-8016222991",
    },
    {
      "type": "Home",
      "distance": "79 km",
      "address": "Netaji Hall, Kalyani Government Engineering College, Block C, Kalyani, West Bengal",
      "phone": "+91-8016222991",
    },
    {
      "type": "Work / Campus",
      "distance": "79 km",
      "address": "KGEC Main Building, Block C, Kalyani, West Bengal",
      "phone": "+91-8016222991",
    },
  ];

  void _openAddAddressModal(BuildContext context) {
    Navigator.pop(context); // Close current sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddAddressBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0XFFF8F9FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle & Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "Select a location",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Search field
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0XFFF0F1F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      icon: Icon(Icons.search, color: Colors.black54, size: 20),
                      hintText: "Search for area, street name...",
                      hintStyle: TextStyle(fontSize: 13, color: Colors.black45),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action buttons card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Use current location
                        InkWell(
                          onTap: () {
                            widget.onAddressSelected?.call("Debagram, Nadia, West Bengal");
                            Navigator.pop(context);
                          },
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                const Icon(Icons.my_location, color: Color(0XFFD32F2F), size: 22),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Use current location",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0XFFD32F2F),
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        "Debagram",
                                        style: TextStyle(fontSize: 12, color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.black38),
                              ],
                            ),
                          ),
                        ),

                        const Divider(height: 1, indent: 50),

                        // Add Address
                        InkWell(
                          onTap: () => _openAddAddressModal(context),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                const Icon(Icons.add, color: Color(0XFFD32F2F), size: 22),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Text(
                                    "Add Address",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0XFFD32F2F),
                                    ),
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.black38),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Saved Addresses Header
                  const Text(
                    "SAVED ADDRESSES",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.black45,
                      letterSpacing: 0.8,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // List of saved addresses
                  Column(
                    children: _savedAddresses.map((addr) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0XFFEBEBEB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.home_outlined, color: Colors.black87, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  addr['type'] ?? 'Home',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0XFFF0F1F5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    addr['distance'] ?? '',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              addr['address'] ?? '',
                              style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Phone number: ${addr['phone']}",
                              style: const TextStyle(fontSize: 11, color: Colors.black54),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0XFFF5F6F8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.more_horiz, size: 16, color: Colors.black54),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0XFFF5F6F8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.share_outlined, size: 16, color: Colors.black54),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddAddressBottomSheet extends StatefulWidget {
  const AddAddressBottomSheet({super.key});

  @override
  State<AddAddressBottomSheet> createState() => _AddAddressBottomSheetState();
}

class _AddAddressBottomSheetState extends State<AddAddressBottomSheet> {
  final TextEditingController _addressDetailsController = TextEditingController();

  double _lat = 23.412600;
  double _lng = 88.429200;
  Offset _pinOffset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header with Back button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  "Select delivery location",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Interactive Map view with movable pointer
          Expanded(
            flex: 4,
            child: ClipRRect(
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _pinOffset += details.delta;
                    _lat -= details.delta.dy * 0.00015;
                    _lng += details.delta.dx * 0.00015;
                  });
                },
                child: Stack(
                  children: [
                    // Interactive Map Tile Grid
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0XFFDFE6EB),
                          image: DecorationImage(
                            image: NetworkImage("https://maps.googleapis.com/maps/api/staticmap?center=23.4126,88.4292&zoom=15&size=600x400&sensor=false&key=AIzaSyA"),
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                        ),
                        child: Container(
                          color: const Color(0XFF2C3E50).withOpacity(0.10),
                        ),
                      ),
                    ),

                    // Movable Pointer & Badge
                    Center(
                      child: Transform.translate(
                        offset: _pinOffset,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.90),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.touch_app, color: Color(0XFF29B6F6), size: 14),
                                      SizedBox(width: 6),
                                      Text(
                                        "Move pin to exact location",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Lat: ${_lat.toStringAsFixed(6)}, Lng: ${_lng.toStringAsFixed(6)}",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0XFFF7CB45),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0XFFE53935).withOpacity(0.2),
                                    border: Border.all(color: const Color(0XFFE53935).withOpacity(0.5), width: 1.5),
                                  ),
                                ),
                                const Icon(
                                  Icons.location_on,
                                  size: 46,
                                  color: Color(0XFFE53935),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                    // Reset button
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _pinOffset = Offset.zero;
                            _lat = 23.412600;
                            _lng = 88.429200;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Reset pin to exact current GPS position"),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.my_location, color: Color(0XFFE53935), size: 18),
                              SizedBox(width: 8),
                              Text(
                                "Recenter pin",
                                style: TextStyle(
                                  color: Color(0XFFE53935),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
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
            ),
          ),

          // Bottom form inputs
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Delivery details",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0XFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0XFFEBEBEB)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0XFFD32F2F), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Debagram (GPS: ${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)})",
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.black45),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _addressDetailsController,
                    decoration: InputDecoration(
                      labelText: "Address details*",
                      hintText: "E.g. Floor, House no.",
                      labelStyle: const TextStyle(color: Colors.black54, fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0XFF0C831F), width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    "Receiver details for this address",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0XFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0XFFEBEBEB)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.phone_outlined, color: Colors.black87, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Soumo Jit Saha, 8016222991",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.black45),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Saved Address with exact GPS coordinates: Lat ${_lat.toStringAsFixed(6)}, Lng ${_lng.toStringAsFixed(6)}",
                            ),
                            backgroundColor: const Color(0XFF0C831F),
                          ),
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0XFFE53935),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Save address",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
