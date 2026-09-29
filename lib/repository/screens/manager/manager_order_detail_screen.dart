import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:blinkit_series/domain/constants/api_constants.dart';

class ManagerOrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback? onStatusUpdated;

  const ManagerOrderDetailScreen({
    super.key,
    required this.order,
    this.onStatusUpdated,
  });

  @override
  State<ManagerOrderDetailScreen> createState() => _ManagerOrderDetailScreenState();
}

class _ManagerOrderDetailScreenState extends State<ManagerOrderDetailScreen> {
  late String _currentStatus;
  List<Map<String, dynamic>> _riders = [];
  int? _selectedRiderId;
  bool _isUpdating = false;
  bool _isLoadingRiders = false;

  // Items packing checklist state
  final Map<int, bool> _packedItemsMap = {};

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order['status'] ?? 'Pending';
    final deliveryPartner = widget.order['delivery_partner'];
    if (deliveryPartner != null && deliveryPartner['id'] != null) {
      _selectedRiderId = int.tryParse(deliveryPartner['id'].toString());
    }
    _fetchRiders();
  }

  Future<void> _fetchRiders() async {
    setState(() {
      _isLoadingRiders = true;
    });

    try {
      final storeId = widget.order['store_id'] ?? 1;
      final uri = Uri.parse(ApiConstants.managerRiders).replace(queryParameters: {'store_id': storeId.toString()});
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          if (mounted) {
            setState(() {
              _riders = List<Map<String, dynamic>>.from(data['data']);
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching riders: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRiders = false;
        });
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.managerUpdateOrderStatus),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "order_id": widget.order['id'],
          "status": newStatus,
          if (_selectedRiderId != null) "delivery_partner_id": _selectedRiderId,
        }),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        if (mounted) {
          setState(() {
            _currentStatus = newStatus;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Order #${widget.order['id']} status updated to '$newStatus'!"),
              backgroundColor: const Color(0XFF0C831F),
            ),
          );
          widget.onStatusUpdated?.call();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? "Failed to update order status."),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  // Generate Google Maps URL & WhatsApp share message formatted for delivery riders
  Future<void> _shareToWhatsApp() async {
    final double lat = (widget.order['latitude'] as num?)?.toDouble() ?? 23.4013;
    final double lng = (widget.order['longitude'] as num?)?.toDouble() ?? 88.5010;
    final String mapsUrl = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";

    final String orderNum = widget.order['order_number'] ?? "ORD-${widget.order['id']}";
    final String customerName = widget.order['user_name'] ?? widget.order['customer_name'] ?? "Customer";
    final String customerPhone = widget.order['user_phone'] ?? widget.order['customer_phone'] ?? "";
    final String address = widget.order['delivery_address'] ?? "Delivery Location";
    final String paymentMethod = widget.order['payment_method'] ?? "Cash on Delivery";
    final double total = (widget.order['grand_total'] as num?)?.toDouble() ?? 0.0;

    final List items = widget.order['items'] is List ? widget.order['items'] : [];
    final String itemsSummary = items.map((it) {
      final name = it['name'] ?? 'Item';
      final qty = it['quantity'] ?? 1;
      return "• $name (x$qty)";
    }).join('\n');

    final String whatsappText = '''
📦 *SBMART DELIVERY ORDER ALERT*
----------------------------------
🆔 *Order Number:* #$orderNum
👤 *Customer:* $customerName
📞 *Phone:* $customerPhone
📍 *Address:* $address

🗺️ *Google Maps Location:*
$mapsUrl

🛍️ *Order Items:*
$itemsSummary

💵 *Total Amount:* ₹${total.toStringAsFixed(0)} ($paymentMethod)
----------------------------------
*Please dispatch & deliver promptly!* ⚡
'''.trim();

    final encodedText = Uri.encodeComponent(whatsappText);
    final Uri waUri = Uri.parse("https://api.whatsapp.com/send?text=$encodedText");

    try {
      if (await canLaunchUrl(waUri)) {
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
      } else {
        final Uri fallbackUri = Uri.parse("whatsapp://send?text=$encodedText");
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not open WhatsApp: $e")),
        );
      }
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
    final items = widget.order['items'] is List ? (widget.order['items'] as List) : [];
    final double lat = (widget.order['latitude'] as num?)?.toDouble() ?? 23.4013;
    final double lng = (widget.order['longitude'] as num?)?.toDouble() ?? 88.5010;

    return Scaffold(
      backgroundColor: const Color(0XFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Order #${widget.order['order_number'] ?? widget.order['id']}",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(_currentStatus).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getStatusColor(_currentStatus)),
            ),
            child: Text(
              _currentStatus.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(_currentStatus),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. WhatsApp Share to Rider Action Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0XFF25D366), Color(0XFF128C7E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0XFF25D366).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.chat_bubble_outline, color: Colors.white, size: 22),
                            SizedBox(width: 8),
                            Text(
                              "Share Order & Map to Rider",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Auto-generates Google Maps GPS link & order details for WhatsApp dispatch.",
                          style: TextStyle(fontSize: 12, color: Colors.white90),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _shareToWhatsApp,
                            icon: const Icon(Icons.share, color: Color(0XFF128C7E), size: 18),
                            label: const Text(
                              "1-Tap Share to WhatsApp",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0XFF128C7E)),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Customer & Delivery Address Card
                  Container(
                    width: double.infinity,
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
                        const Row(
                          children: [
                            Icon(Icons.person_pin_circle_outlined, color: Color(0XFF0C831F), size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Customer & Delivery Location",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 18, color: Colors.black54),
                            const SizedBox(width: 8),
                            Text(
                              (widget.order['user_name'] ?? widget.order['customer_name'] ?? "Customer").toString(),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 18, color: Colors.black54),
                            const SizedBox(width: 8),
                            SelectableText(
                              (widget.order['user_phone'] ?? widget.order['customer_phone'] ?? "No Phone").toString(),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0XFF0C831F)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, size: 18, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                (widget.order['delivery_address'] ?? "Address").toString(),
                                style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.map, size: 16, color: Colors.blue),
                            const SizedBox(width: 6),
                            Text(
                              "GPS: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}",
                              style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () async {
                                final uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
                                try {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                } catch (_) {}
                              },
                              icon: const Icon(Icons.open_in_new, size: 14, color: Color(0XFF0C831F)),
                              label: const Text("Open Map", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0XFF0C831F))),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Items Packing Checklist Card
                  Container(
                    width: double.infinity,
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
                            const Row(
                              children: [
                                Icon(Icons.checklist_rtl_rounded, color: Color(0XFF0C831F), size: 22),
                                SizedBox(width: 8),
                                Text(
                                  "Items Checklist (Packing)",
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                              ],
                            ),
                            Text(
                              "${items.length} ${items.length == 1 ? 'item' : 'items'}",
                              style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(height: 20),

                        if (items.isEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text("No item details specified for this order.", style: TextStyle(color: Colors.black54)),
                          ),
                        ] else ...[
                          Column(
                            children: List.generate(items.length, (idx) {
                              final item = items[idx];
                              final bool isPacked = _packedItemsMap[idx] ?? false;
                              final name = item['name'] ?? 'Product';
                              final qty = item['quantity'] ?? 1;
                              final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _packedItemsMap[idx] = !isPacked;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    border: idx == items.length - 1 ? null : Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                  ),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: isPacked,
                                        activeColor: const Color(0XFF0C831F),
                                        onChanged: (val) {
                                          setState(() {
                                            _packedItemsMap[idx] = val ?? false;
                                          });
                                        },
                                      ),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            decoration: isPacked ? TextDecoration.lineThrough : null,
                                            color: isPacked ? Colors.grey : Colors.black,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0XFFE8F5E9),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          "x$qty",
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0XFF0C831F)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "₹${(price * qty).toStringAsFixed(0)}",
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4. Assign Delivery Partner Card
                  Container(
                    width: double.infinity,
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
                        const Row(
                          children: [
                            Icon(Icons.delivery_dining, color: Color(0XFF0C831F), size: 22),
                            SizedBox(width: 8),
                            Text(
                              "Assign Delivery Partner (Rider)",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _isLoadingRiders
                            ? const LinearProgressIndicator(color: Color(0XFF0C831F))
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0XFFF8F9FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    isExpanded: true,
                                    hint: const Text("Select Delivery Rider..."),
                                    value: _selectedRiderId,
                                    items: _riders.map((r) {
                                      final rId = int.tryParse(r['id'].toString()) ?? 1;
                                      return DropdownMenuItem<int>(
                                        value: rId,
                                        child: Text(
                                          "${r['name']} (${r['phone'] ?? 'Active Rider'})",
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedRiderId = val;
                                      });
                                    },
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Sticky Bottom Action Bar to Update Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "UPDATE ORDER STATUS",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 0.8),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (_currentStatus != 'Packing')
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isUpdating ? null : () => _updateStatus('Packing'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text("Mark Packing", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    if (_currentStatus != 'Packing') const SizedBox(width: 8),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isUpdating ? null : () => _updateStatus('Out for Delivery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text("Dispatch", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isUpdating ? null : () => _updateStatus('Delivered'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0XFF0C831F),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text("Delivered", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
