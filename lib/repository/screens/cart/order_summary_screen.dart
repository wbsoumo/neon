import 'package:flutter/material.dart';
import 'package:blinkit_series/domain/cart/cart_controller.dart';
import 'package:blinkit_series/repository/screens/cart/cartscreen.dart';

class OrderSummaryScreen extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderSummaryScreen({
    super.key,
    required this.orderData,
  });

  @override
  Widget build(BuildContext context) {
    final String orderNumber = orderData['order_number']?.toString() ?? 'ORD';
    final String status = orderData['status']?.toString() ?? 'Delivered';
    final String createdAt = orderData['created_at']?.toString() ?? 'Recently';
    final String address = orderData['delivery_address']?.toString() ?? 'Default Address';
    final String paymentMethod = orderData['payment_method']?.toString() ?? 'Cash on Delivery';
    final double grandTotal = double.tryParse(orderData['grand_total']?.toString() ?? '0') ?? 0.0;
    final double subtotal = double.tryParse(orderData['subtotal']?.toString() ?? '0') ?? grandTotal;
    final double deliveryFee = double.tryParse(orderData['delivery_fee']?.toString() ?? '0') ?? 0.0;
    final double handlingFee = double.tryParse(orderData['handling_fee']?.toString() ?? '2') ?? 2.0;

    final List itemsList = orderData['items'] as List? ?? [];
    final int itemTotalCount = itemsList.fold(0, (sum, it) => sum + (int.tryParse(it['quantity']?.toString() ?? '1') ?? 1));

    // Calculate MRP & Discount mock values if not explicitly provided
    final double calculatedMrp = itemsList.fold(0.0, (sum, it) {
      final double price = double.tryParse(it['price']?.toString() ?? '0') ?? 0.0;
      final double mrp = double.tryParse(it['mrp']?.toString() ?? '') ?? (price * 1.15);
      final int qty = int.tryParse(it['quantity']?.toString() ?? '1') ?? 1;
      return sum + (mrp * qty);
    });
    final double discount = (calculatedMrp - subtotal) > 0 ? (calculatedMrp - subtotal) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0XFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.black87),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Order removed from history view")),
              );
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Order Summary Header Block
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Order summary",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          status == 'Delivered'
                              ? "Arrived at ${createdAt.contains(',') ? createdAt.split(',').last.trim() : createdAt}"
                              : "Order Status: $status",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Downloading invoice for Order #$orderNumber...")),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                "Download Invoice",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0XFF0C831F),
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.download_outlined, size: 16, color: Color(0XFF0C831F)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 2. Items List Section
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$itemTotalCount ${itemTotalCount == 1 ? 'item' : 'items'} in this order",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (itemsList.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text("No items detail available", style: TextStyle(color: Colors.black54)),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: itemsList.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final item = itemsList[index];
                              final String name = item['product_name']?.toString() ?? item['name']?.toString() ?? 'Item';
                              final double price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
                              final int qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
                              final String unit = item['unit']?.toString() ?? '1 unit';
                              final String img = item['image']?.toString() ?? item['img']?.toString() ?? '';
                              final double mrp = double.tryParse(item['mrp']?.toString() ?? '') ?? (price * 1.15);

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Product Thumbnail Container
                                  Container(
                                    width: 60,
                                    height: 60,
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0XFFF8F9FA),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                                    ),
                                    child: img.startsWith('http')
                                        ? Image.network(img, fit: BoxFit.contain, errorBuilder: (c, o, s) => const Icon(Icons.shopping_bag_outlined, color: Colors.grey))
                                        : const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 28),
                                  ),
                                  const SizedBox(width: 14),

                                  // Product Name & Quantity
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "$unit x $qty",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  // Prices: Struck-through MRP and Final Price
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (mrp > price)
                                        Text(
                                          "₹${(mrp * qty).toStringAsFixed(0)}",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black38,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                      Text(
                                        "₹${(price * qty).toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 3. Rate Your Order Section Box
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0XFFFFF8E1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.star_rounded, color: Color(0XFFF57F17), size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "How were your ordered items?",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Thank you for rating your order! ⭐️⭐️⭐️⭐️⭐️")),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0XFF0C831F),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: const Text(
                              "Rate now",
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 4. Bill Details Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Bill details",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 14),

                          if (calculatedMrp > 0) ...[
                            _buildBillRow("MRP", "₹${calculatedMrp.toStringAsFixed(0)}"),
                            const SizedBox(height: 8),
                          ],
                          if (discount > 0) ...[
                            _buildBillRow("Product discount", "-₹${discount.toStringAsFixed(0)}", valueColor: const Color(0XFF0C831F)),
                            const SizedBox(height: 8),
                          ],
                          _buildBillRow("Item total", "₹${subtotal.toStringAsFixed(0)}"),
                          const SizedBox(height: 8),
                          _buildBillRow("Handling charge", "+₹${handlingFee.toStringAsFixed(0)}"),
                          const SizedBox(height: 8),
                          _buildBillRow(
                            "Delivery charges",
                            deliveryFee == 0 ? "FREE" : "₹${deliveryFee.toStringAsFixed(0)}",
                            valueColor: deliveryFee == 0 ? const Color(0XFF0C831F) : Colors.black,
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Bill total",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                "₹${grandTotal.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 5. Order Details Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Order details",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text("Order ID: #$orderNumber", style: const TextStyle(fontSize: 13, color: Colors.black87)),
                          const SizedBox(height: 4),
                          Text("Payment Method: $paymentMethod", style: const TextStyle(fontSize: 13, color: Colors.black87)),
                          const SizedBox(height: 4),
                          Text("Delivery Address: $address", style: const TextStyle(fontSize: 13, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Sticky Bottom Action Bar for "Repeat Order"
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // Re-add items to CartController
                    for (var item in itemsList) {
                      final String id = item['product_id']?.toString() ?? item['id']?.toString() ?? '1';
                      final String name = item['product_name']?.toString() ?? item['name']?.toString() ?? 'Item';
                      final double price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
                      final String img = item['image']?.toString() ?? item['img']?.toString() ?? '';
                      final String unit = item['unit']?.toString() ?? '1 unit';

                      CartController.instance.addItem(
                        id: id,
                        name: name,
                        img: img,
                        price: price,
                        unit: unit,
                      );
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Items added to cart!")),
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CartScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0XFF0C831F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "Repeat Order",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "VIEW CART ON NEXT STEP",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildBillRow(String label, String value, {Color valueColor = Colors.black}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    );
  }
}
