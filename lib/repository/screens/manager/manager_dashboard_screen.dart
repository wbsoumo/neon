import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blinkit_series/domain/constants/api_constants.dart';
import 'package:blinkit_series/repository/screens/manager/manager_login_screen.dart';
import 'package:blinkit_series/repository/screens/manager/manager_order_detail_screen.dart';

class ManagerDashboardScreen extends StatefulWidget {
  final int storeId;
  final String storeName;
  final String managerName;

  const ManagerDashboardScreen({
    super.key,
    required this.storeId,
    required this.storeName,
    required this.managerName,
  });

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String _selectedFilter = 'All'; // All, Pending, Packing, Out for Delivery, Delivered

  Timer? _pollingTimer;
  Timer? _sirenTimer;
  int _lastKnownOrderCount = 0;
  bool _hasNewOrderAlert = false;
  Map<String, dynamic>? _newestOrderAlert;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    // Start real-time 5-second polling loop to check for incoming orders
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchOrders(isSilent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _sirenTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOrders({bool isSilent = false}) async {
    if (!isSilent) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final uri = Uri.parse(ApiConstants.managerOrders).replace(
        queryParameters: {
          'store_id': widget.storeId.toString(),
          if (_selectedFilter != 'All') 'status': _selectedFilter,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['orders'] != null) {
          final List<Map<String, dynamic>> fetched = List<Map<String, dynamic>>.from(data['orders']);

          // Check if new Pending orders arrived since last poll
          if (_lastKnownOrderCount > 0 && fetched.length > _lastKnownOrderCount) {
            final latest = fetched.first;
            if ((latest['status'] ?? '').toString().toLowerCase() == 'pending') {
              _triggerOrderSirenAlert(latest);
            }
          }

          if (mounted) {
            setState(() {
              _orders = fetched;
              _lastKnownOrderCount = fetched.length;
              _isLoading = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint("Manager polling error: $e");
    } finally {
      if (mounted && !isSilent) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Trigger continuous audio beep/siren & flashing alert banner
  void _triggerOrderSirenAlert(Map<String, dynamic> order) {
    if (_hasNewOrderAlert) return;

    setState(() {
      _hasNewOrderAlert = true;
      _newestOrderAlert = order;
    });

    // Audio Haptic & Siren Sound pulse loop
    _sirenTimer?.cancel();
    _sirenTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.vibrate();
    });
  }

  void _dismissSiren() {
    _sirenTimer?.cancel();
    setState(() {
      _hasNewOrderAlert = false;
      _newestOrderAlert = null;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_manager_logged_in');
    await prefs.remove('manager_store_id');
    await prefs.remove('manager_name');
    await prefs.remove('manager_phone');

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ManagerLoginScreen()),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0XFFF57F17);
      case 'packing':
        return Colors.blue.shade700;
      case 'out for delivery':
      case 'dispatched':
        return Colors.purple.shade700;
      case 'delivered':
        return const Color(0XFF0C831F);
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return Colors.black54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0XFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0XFF0A2C10),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storefront, color: Color(0XFF4FC23A), size: 20),
                const SizedBox(width: 6),
                Text(
                  widget.storeName,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              "Manager: ${widget.managerName} • Live Orders Portal",
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _fetchOrders(),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Logout Store Manager?"),
                  content: const Text("Are you sure you want to sign out from Store Manager portal?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _logout();
                      },
                      child: const Text("Logout", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Flashing Emergency Siren Alert Banner for New Incoming Orders
          if (_hasNewOrderAlert && _newestOrderAlert != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "🚨 NEW ORDER RECEIVED!",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                        Text(
                          "Order #${_newestOrderAlert!['order_number'] ?? _newestOrderAlert!['id']} • ₹${_newestOrderAlert!['grand_total']} (${_newestOrderAlert!['user_name'] ?? 'Customer'})",
                          style: const TextStyle(color: Colors.white90, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _dismissSiren();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ManagerOrderDetailScreen(
                            order: _newestOrderAlert!,
                            onStatusUpdated: () => _fetchOrders(),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red.shade700,
                    ),
                    child: const Text("View & Pack", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _dismissSiren,
                  ),
                ],
              ),
            ),

          // Status Category Filter Chips Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: ['All', 'Pending', 'Packing', 'Out for Delivery', 'Delivered'].map((filter) {
                  final bool isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      showCheckmark: false,
                      label: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0XFF0C831F),
                      backgroundColor: const Color(0XFFF0F1F5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                          _fetchOrders();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Orders List (Latest First)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0XFF0C831F)))
                : _orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              "No $_selectedFilter orders found for ${widget.storeName}",
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: const Color(0XFF0C831F),
                        onRefresh: () => _fetchOrders(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _orders.length,
                          itemBuilder: (context, index) {
                            final order = _orders[index];
                            final String status = order['status'] ?? 'Pending';
                            final List items = order['items'] is List ? (order['items'] as List) : [];
                            final String orderNum = order['order_number'] ?? "ORD-${order['id']}";
                            final String customerName = order['user_name'] ?? order['customer_name'] ?? "Customer";
                            final String customerPhone = order['user_phone'] ?? order['customer_phone'] ?? "";

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
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
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ManagerOrderDetailScreen(
                                        order: order,
                                        onStatusUpdated: () => _fetchOrders(),
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top Order Header & Status Pill
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "#$orderNum",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.black,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(status).withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: _getStatusColor(status), width: 1.2),
                                            ),
                                            child: Text(
                                              status.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: _getStatusColor(status),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 8),

                                      // Customer & Address Summary
                                      Row(
                                        children: [
                                          const Icon(Icons.person, size: 16, color: Colors.black54),
                                          const SizedBox(width: 6),
                                          Text(
                                            customerName,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                                          ),
                                          if (customerPhone.isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            Text("($customerPhone)", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                          ],
                                        ],
                                      ),

                                      const SizedBox(height: 4),

                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              order['delivery_address'] ?? 'Delivery Address',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const Divider(height: 16),

                                      // Total & Action Button
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "₹${(order['grand_total'] as num?)?.toStringAsFixed(0) ?? '0'}",
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0XFF0C831F),
                                                ),
                                              ),
                                              Text(
                                                "${items.length} ${items.length == 1 ? 'item' : 'items'} • ${order['payment_method'] ?? 'COD'}",
                                                style: const TextStyle(fontSize: 11, color: Colors.black45),
                                              ),
                                            ],
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => ManagerOrderDetailScreen(
                                                    order: order,
                                                    onStatusUpdated: () => _fetchOrders(),
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                                            label: const Text(
                                              "Order Details",
                                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0XFF0C831F),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              elevation: 0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
