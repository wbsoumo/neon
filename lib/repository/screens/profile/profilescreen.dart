import 'package:flutter/material.dart';
import 'package:blinkit_series/repository/screens/profile/profile_detail_screen.dart';
import 'package:blinkit_series/repository/screens/profile/order_history_screen.dart';
import 'package:blinkit_series/repository/services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onBackTap;

  const ProfileScreen({super.key, this.onBackTap});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isDarkMode = false;

  void _navigateToDetail(BuildContext context, String title, Widget content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileDetailScreen(title: title, content: content),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0XFFF5F6F8),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 1. Warm Soft Gradient Header with Back Button & Profile Avatar
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0XFFFDF1C2), Color(0XFFF5F6F8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // Back arrow header row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                              onPressed: () {
                                widget.onBackTap?.call();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Profile Avatar Circle
                    const CircleAvatar(
                      radius: 46,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: Color(0XFF333333),
                        child: Icon(Icons.person, color: Colors.white, size: 48),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Title & Phone Number
                    const Text(
                      "Your account",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "8016222991",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0XFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // 2. Three Main Quick Action Cards (Your orders, Blinkit Money, Need help?)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTopQuickCard(
                      icon: Icons.shopping_basket_outlined,
                      label: "Your orders",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTopQuickCard(
                      icon: Icons.account_balance_wallet_outlined,
                      label: "Blinkit Money",
                      onTap: () => _navigateToDetail(context, "Blinkit Money", _buildBlinkitMoneyContent()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTopQuickCard(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: "Need help?",
                      onTap: () => _navigateToDetail(context, "Need help?", _buildNeedHelpContent()),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 3. Appearance Card (Theme Toggle)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.wb_sunny_outlined, size: 20, color: Colors.black87),
                        SizedBox(width: 10),
                        Text(
                          "Appearance",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isDarkMode = !_isDarkMode;
                        });
                      },
                      child: Row(
                        children: [
                          Text(
                            _isDarkMode ? "DARK" : "LIGHT",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0XFF5C6BC0),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0XFF5C6BC0)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 4. "Your information" Section Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                      child: Text(
                        "Your information",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    _buildOptionTile(
                      icon: Icons.menu_book_outlined,
                      title: "Address book",
                      onTap: () => _navigateToDetail(context, "Address book", _buildAddressBookContent()),
                    ),
                    const Divider(height: 1, indent: 48),
                    _buildOptionTile(
                      icon: Icons.soup_kitchen_outlined,
                      title: "Bookmarked recipes",
                      onTap: () => _navigateToDetail(context, "Bookmarked recipes", _buildBookmarkedRecipesContent()),
                    ),
                    const Divider(height: 1, indent: 48),
                    _buildOptionTile(
                      icon: Icons.favorite_border_rounded,
                      title: "Your wishlist",
                      onTap: () => _navigateToDetail(context, "Your wishlist", _buildWishlistContent()),
                    ),
                    const Divider(height: 1, indent: 48),
                    _buildOptionTile(
                      icon: Icons.receipt_long_outlined,
                      title: "GST details",
                      onTap: () => _navigateToDetail(context, "GST details", _buildGstContent()),
                    ),
                    const Divider(height: 1, indent: 48),
                    _buildOptionTile(
                      icon: Icons.card_giftcard_outlined,
                      title: "E-gift cards",
                      onTap: () => _navigateToDetail(context, "E-gift cards", _buildEGiftCardsContent()),
                    ),
                    const Divider(height: 1, indent: 48),
                    _buildOptionTile(
                      icon: Icons.description_outlined,
                      title: "Your prescriptions",
                      onTap: () => _navigateToDetail(context, "Your prescriptions", _buildPrescriptionsContent()),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 5. "Payment and coupons" Section Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                      child: Text(
                        "Payment and coupons",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    _buildOptionTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: "Blinkit Money",
                      onTap: () => _navigateToDetail(context, "Blinkit Money", _buildBlinkitMoneyContent()),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Top 3 Quick Cards Builder
  Widget _buildTopQuickCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: Colors.black87),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Row Option Tile Builder
  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: Colors.black87, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }

  // ------------ MOCK DETAIL CONTENTS FOR EACH RELEVANT OPTION ------------

  Widget _buildOrdersContent() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ApiService.getUserOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: Color(0XFF0C831F)),
            ),
          );
        }

        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text("No orders placed yet", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text("Your past and active orders will appear here.", style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          );
        }

        return Column(
          children: orders.map((ord) {
            final String status = ord['status']?.toString() ?? 'Pending';
            final String orderType = ord['order_type']?.toString() ?? 'delivery';
            final bool isPickup = orderType == 'pickup';
            final itemsList = ord['items'] as List? ?? [];
            final String itemsSummary = itemsList.map((e) => "${e['product_name']} x${e['quantity']}").join(", ");

            Color statusColor = const Color(0XFF0C831F); // Green default
            if (status == 'Pending') statusColor = Colors.orange;
            if (status == 'Out for Delivery' || status == 'Packing') statusColor = Colors.blue;
            if (status == 'Ready for Pickup') statusColor = Colors.purple;
            if (status == 'Cancelled') statusColor = Colors.red;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isPickup ? Icons.storefront : Icons.local_shipping,
                            size: 18,
                            color: isPickup ? Colors.purple : const Color(0XFF0C831F),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "#${ord['order_number']}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      Text(
                        "₹${ord['grand_total']}",
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0XFF0C831F)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Placed on: ${ord['created_at'] ?? 'Recently'}",
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  
                  if (ord['receiver_name'] != null && ord['receiver_name'].toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0XFFFFF8E1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Receiver: ${ord['receiver_name']} (${ord['receiver_phone']})",
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                  ],

                  if (isPickup) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0XFFF3E5F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Store Pickup: ${ord['pickup_date'] ?? ''} (${ord['pickup_time'] ?? ''})",
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple),
                      ),
                    ),
                  ],

                  const Divider(height: 16),
                  Text(
                    itemsSummary.isNotEmpty ? itemsSummary : "Order items details",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        status == 'Delivered' ? Icons.check_circle : Icons.timeline,
                        color: statusColor,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Status: $status",
                        style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildBlinkitMoneyContent() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0XFF0C831F), Color(0XFF085D15)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("Total Wallet Balance", style: TextStyle(color: Colors.white70, fontSize: 13)),
              SizedBox(height: 6),
              Text("₹0.00", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              SizedBox(height: 12),
              Text("Fast, 1-click checkout on all your orders", style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: const [
              Icon(Icons.add_circle_outline, color: Color(0XFF0C831F)),
              SizedBox(width: 12),
              Expanded(
                child: Text("Add Money to Wallet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNeedHelpContent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("Help & Support", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              Text("Got a question regarding your active order or refund?", style: TextStyle(fontSize: 13, color: Colors.black54)),
              SizedBox(height: 16),
              Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.chat_bubble_outline, color: Color(0XFF0C831F)),
                title: Text("Chat with Live Support"),
                trailing: Icon(Icons.chevron_right),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.phone_outlined, color: Color(0XFF0C831F)),
                title: Text("Request Callback"),
                trailing: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressBookContent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: const [
              Icon(Icons.home_outlined, color: Color(0XFF0C831F), size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Home - Primary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    SizedBox(height: 4),
                    Text("RATANR FLAT - 11E, Krishnanagar, India", style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
              Icon(Icons.more_vert, color: Colors.black38),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookmarkedRecipesContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: const [
            Icon(Icons.soup_kitchen_outlined, size: 60, color: Colors.black26),
            SizedBox(height: 12),
            Text("No Bookmarked Recipes Yet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            SizedBox(height: 6),
            Text("Save your favorite recipes while browsing items!", style: TextStyle(fontSize: 12, color: Colors.black45)),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: const [
            Icon(Icons.favorite_border_rounded, size: 60, color: Colors.black26),
            SizedBox(height: 12),
            Text("Your Wishlist is Empty", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            SizedBox(height: 6),
            Text("Explore products and tap the heart icon to save for later.", style: TextStyle(fontSize: 12, color: Colors.black45)),
          ],
        ),
      ),
    );
  }

  Widget _buildGstContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text("GST Identification Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          SizedBox(height: 8),
          Text("Add your company GSTIN to claim tax credit on business orders.", style: TextStyle(fontSize: 12, color: Colors.black54)),
          SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: "Enter 15-digit GSTIN",
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEGiftCardsContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: const [
          Icon(Icons.card_giftcard_outlined, size: 50, color: Color(0XFF0C831F)),
          SizedBox(height: 12),
          Text("Blinkit E-Gift Cards", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 6),
          Text("Gift instant groceries & electronics to your loved ones.", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildPrescriptionsContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: const [
          Icon(Icons.description_outlined, size: 50, color: Color(0XFF0C831F)),
          SizedBox(height: 12),
          Text("Saved Medical Prescriptions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 6),
          Text("Upload and view prescriptions for express medicine delivery.", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}
