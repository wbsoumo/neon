import 'package:flutter/material.dart';
import 'package:blinkit_series/domain/cart/cart_controller.dart';
import 'package:blinkit_series/repository/widgets/animated_cart_button.dart';
import 'package:blinkit_series/repository/widgets/address_selection_bottom_sheet.dart';
import 'package:blinkit_series/repository/services/api_service.dart';

class CartScreen extends StatefulWidget {
  final VoidCallback? onBackTap;

  const CartScreen({super.key, this.onBackTap});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartController _cart = CartController.instance;

  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoadingRecs = false;

  static const double _freeDeliveryThreshold = 199.0;

  final List<Map<String, dynamic>> _defaultRecommendations = [
    {
      "id": "yml_1",
      "name": "Tejas Pure Ghee Diya",
      "unit": "30 pcs",
      "price": 86.0,
      "mrp": 95.0,
      "discount": "9% OFF",
      "img": "image 50.png",
    },
    {
      "id": "yml_2",
      "name": "Long Cotton Wicks",
      "unit": "100 pcs",
      "price": 22.0,
      "mrp": 40.0,
      "discount": "45% OFF",
      "img": "image 50.png",
    },
    {
      "id": "yml_3",
      "name": "Fresh Mix Marigold Flowers",
      "unit": "100 g",
      "price": 35.0,
      "mrp": 44.0,
      "discount": "20% OFF",
      "img": "image 41.png",
    },
    {
      "id": "yml_4",
      "name": "Amul Taaza T-Special Milk",
      "unit": "500 ml",
      "price": 27.0,
      "mrp": 28.0,
      "discount": "4% OFF",
      "img": "image 44 (1).png",
    },
  ];

  @override
  void initState() {
    super.initState();
    _cart.addListener(_update);
    _loadCategoryRecommendations();
  }

  @override
  void dispose() {
    _cart.removeListener(_update);
    super.dispose();
  }

  void _update() {
    if (mounted) {
      setState(() {});
      _loadCategoryRecommendations();
    }
  }

  Future<void> _loadCategoryRecommendations() async {
    if (_isLoadingRecs) return;
    
    // Find unique category IDs in cart
    final cartCategoryIds = _cart.items.values
        .map((e) => e.categoryId)
        .where((id) => id != null)
        .cast<int>()
        .toSet();

    List<Map<String, dynamic>> fetched = [];
    if (cartCategoryIds.isNotEmpty) {
      for (final catId in cartCategoryIds) {
        final prods = await ApiService.fetchProducts(categoryId: catId);
        fetched.addAll(prods);
      }
    } else {
      // Fetch general top products
      fetched = await ApiService.fetchProducts();
    }

    if (mounted) {
      setState(() {
        _recommendations = fetched;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = _cart.items.values.toList();
    final int totalItemCount = _cart.totalItemCount;
    final double subtotal = _cart.totalAmount;
    final double amountNeededForFreeDelivery = (_freeDeliveryThreshold - subtotal).clamp(0.0, _freeDeliveryThreshold);
    final double progressRatio = (subtotal / _freeDeliveryThreshold).clamp(0.0, 1.0);

    // Filter recommendations: show products in categories in cart, EXCLUDE products already in cart
    final cartItemIds = _cart.items.keys.toSet();
    final List<Map<String, dynamic>> filteredRecs = _recommendations.where((item) {
      final String idStr = item['id'].toString();
      return !cartItemIds.contains(idStr);
    }).toList();

    final displayRecs = filteredRecs.isNotEmpty ? filteredRecs : _defaultRecommendations.where((item) => !cartItemIds.contains(item['id'].toString())).toList();

    return Scaffold(
      backgroundColor: const Color(0XFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            widget.onBackTap?.call();
          },
        ),
        title: const Text(
          "Checkout",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {},
          ),
          Container(
            margin: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0XFFE0E0E0)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.share_outlined, size: 16, color: Colors.black87),
                SizedBox(width: 4),
                Text(
                  "Share",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. FREE DELIVERY PROGRESS BAR BANNER
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: subtotal >= _freeDeliveryThreshold
                                    ? const Color(0XFFE8F5E9)
                                    : const Color(0XFFFFF8E1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                subtotal >= _freeDeliveryThreshold
                                    ? Icons.celebration
                                    : Icons.delivery_dining,
                                color: subtotal >= _freeDeliveryThreshold
                                    ? const Color(0XFF0C831F)
                                    : const Color(0XFFF57F17),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          subtotal >= _freeDeliveryThreshold
                                              ? "Yay! You unlocked FREE Delivery 🥳 🎉"
                                              : "Add ₹${amountNeededForFreeDelivery.toStringAsFixed(0)} more for FREE Delivery",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: subtotal >= _freeDeliveryThreshold
                                                ? const Color(0XFF0C831F)
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (subtotal >= _freeDeliveryThreshold)
                                        const Text(
                                          "🎉 🎊",
                                          style: TextStyle(fontSize: 18),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    subtotal >= _freeDeliveryThreshold
                                        ? "No extra delivery charge will be added to this order"
                                        : "Shop for ₹${_freeDeliveryThreshold.toStringAsFixed(0)} or more to save delivery fees",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Animated Linear Progress Indicator
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progressRatio,
                            minHeight: 8,
                            backgroundColor: const Color(0XFFEEEEEE),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              subtotal >= _freeDeliveryThreshold
                                  ? const Color(0XFF0C831F)
                                  : const Color(0XFFF7CB45),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 2. SPECIAL DEAL FOR YOU SECTION
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.local_offer, color: Color(0XFF673AB7), size: 18),
                            SizedBox(width: 6),
                            Text(
                              "Special deal for you!",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0XFFF8F5FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0XFFE8E0FF)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.sanitizer_outlined, color: Color(0XFF5C6BC0), size: 36),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Head & Shoulders Anti Hairfall Offer",
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                            height: 1.2,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              "₹45 ",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            Text(
                                              "₹79",
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.black38,
                                                decoration: TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  AnimatedCartButton(
                                    id: "deal_1",
                                    name: "Head & Shoulders Special Offer",
                                    img: "image 35.png",
                                    price: 45.0,
                                    width: 64,
                                    height: 32,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0XFFF0EBFF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.lock_open, size: 16, color: Color(0XFF673AB7)),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Yay! Special deal unlocked. Add this item to your cart",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0XFF673AB7),
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

                  const SizedBox(height: 14),

                  // 3. CART ITEMS LIST (DELIVERY IN 11 MINS)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 14,
                              backgroundColor: Color(0XFFE8F5E9),
                              child: Icon(Icons.timer_outlined, color: Color(0XFF0C831F), size: 18),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Delivery in 11 minutes",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  "Shipment of ${totalItemCount == 0 ? 0 : totalItemCount} ${totalItemCount == 1 ? 'item' : 'items'}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        if (cartItems.isEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.shopping_basket_outlined, size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Your cart is currently empty",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          Column(
                            children: cartItems.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: const Color(0XFFF9F9F9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: item.img.startsWith('http')
                                          ? Image.network(
                                              item.img,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag, color: Color(0XFF0C831F), size: 28),
                                            )
                                          : Image.asset(
                                              "assets/images/${item.img}",
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag, color: Color(0XFF0C831F), size: 28),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item.unit,
                                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        AnimatedCartButton(
                                          id: item.id,
                                          name: item.name,
                                          img: item.img,
                                          price: item.price,
                                          unit: item.unit,
                                          categoryId: item.categoryId,
                                          width: 72,
                                          height: 32,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "₹${(item.price * item.quantity).toStringAsFixed(0)}",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4. "YOU MIGHT ALSO LIKE" SECTION (ON CART CATEGORIES, FILTER OUT CART ITEMS)
                  if (displayRecs.isNotEmpty) ...[
                    const Text(
                      "You might also like",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: displayRecs.length,
                        itemBuilder: (context, index) {
                          final item = displayRecs[index];
                          final String idStr = item['id'].toString();
                          final String name = (item['name'] ?? item['title'] ?? 'Product').toString();
                          final String unit = (item['unit'] ?? '1 unit').toString();
                          final double price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
                          final double mrp = double.tryParse(item['mrp']?.toString() ?? (price * 1.2).toString()) ?? price;
                          final String img = (item['img'] ?? item['image'] ?? '').toString();
                          final int? catId = item['category_id'] is int ? item['category_id'] : int.tryParse(item['category_id']?.toString() ?? '');

                          return Container(
                            width: 130,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: const Color(0XFFF9F9F9),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: img.startsWith('http')
                                        ? Image.network(
                                            img,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 36),
                                          )
                                        : Image.asset(
                                            "assets/images/$img",
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 36),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  unit,
                                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "₹${price.toStringAsFixed(0)}",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black,
                                          ),
                                        ),
                                        if (mrp > price)
                                          Text(
                                            "₹${mrp.toStringAsFixed(0)}",
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.black38,
                                              decoration: TextDecoration.lineThrough,
                                            ),
                                          ),
                                      ],
                                    ),
                                    AnimatedCartButton(
                                      id: idStr,
                                      name: name,
                                      img: img,
                                      price: price,
                                      unit: unit,
                                      categoryId: catId,
                                      width: 56,
                                      height: 28,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 5. TOTAL BILLING BREAKDOWN CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
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
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 16, color: Colors.black54),
                                SizedBox(width: 6),
                                Text("Items total", style: TextStyle(fontSize: 13, color: Colors.black87)),
                              ],
                            ),
                            Text(
                              "₹${subtotal.toStringAsFixed(0)}",
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.delivery_dining_outlined, size: 16, color: Colors.black54),
                                SizedBox(width: 6),
                                Text("Delivery charge", style: TextStyle(fontSize: 13, color: Colors.black87)),
                              ],
                            ),
                            _cart.deliveryFee == 0
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0XFFE8F5E9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      "FREE",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0XFF0C831F),
                                      ),
                                    ),
                                  )
                                : Text(
                                    "₹${_cart.deliveryFee.toStringAsFixed(0)}",
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.cleaning_services_outlined, size: 16, color: Colors.black54),
                                SizedBox(width: 6),
                                Text("Handling fee", style: TextStyle(fontSize: 13, color: Colors.black87)),
                              ],
                            ),
                            Text(
                              "₹${_cart.handlingFee.toStringAsFixed(0)}",
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1, color: Color(0XFFE0E0E0)),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Grand Total",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              "₹${_cart.grandTotal.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0XFF0C831F),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // 6. STICKY BOTTOM ADDRESS BANNER & CASH ON DELIVERY PAYMENT BAR
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Delivery Address Pill
                InkWell(
                  onTap: () {
                    AddressSelectionBottomSheet.show(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: const Color(0XFFFDFDFD),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 12,
                              backgroundColor: Color(0XFFF7CB45),
                              child: Icon(Icons.location_on, color: Colors.black87, size: 14),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Delivering to Ratanr Flat 11E",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 1),
                                  Text(
                                    "11E Krishnanagar, India",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Text(
                              "Change",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0XFF0C831F),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1),

                // Sticky Payment Bar - CASH ON DELIVERY ONLY FOR NOW
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0XFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.payments_outlined, color: Color(0XFF0C831F), size: 18),
                          ),
                          const SizedBox(width: 8),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "PAY USING",
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black45,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                "Cash on Delivery",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Green Place Order Button with Backend Sync
                      GestureDetector(
                        onTap: () async {
                          if (_cart.items.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Your cart is empty! Add items first.")),
                            );
                            return;
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Placing Cash on Delivery order...")),
                          );

                          final itemsList = _cart.items.values.map((it) {
                            return {
                              "product_id": int.tryParse(it.id) ?? 1,
                              "name": it.name,
                              "price": it.price,
                              "quantity": it.quantity,
                              "total": it.price * it.quantity,
                            };
                          }).toList();

                          final response = await ApiService.createOrder(
                            userName: "Demo Customer",
                            userPhone: "9876543210",
                            deliveryAddress: "11E Krishnanagar Main Road, Krishnanagar",
                            items: itemsList,
                            storeId: 1,
                            paymentMethod: "Cash on Delivery",
                          );

                          if (mounted) {
                            if (response['status'] == 'success') {
                              _cart.clearCart();
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: const Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Color(0XFF0C831F), size: 28),
                                      SizedBox(width: 8),
                                      Text("Order Placed!"),
                                    ],
                                  ),
                                  content: Text(
                                    "Order #${response['order_number'] ?? 'SUCCESS'} (Cash on Delivery) has been placed successfully!\n\nPay cash when your delivery partner arrives.",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(ctx).pop();
                                        widget.onBackTap?.call();
                                      },
                                      child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Order Failed: ${response['message'] ?? 'Error'}")),
                              );
                            }
                          }
                        },
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0XFF0C831F),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "₹${_cart.grandTotal.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    "TOTAL",
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              const Row(
                                children: [
                                  Text(
                                    "Place Order",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_right_sharp, color: Colors.white, size: 20),
                                ],
                              ),
                            ],
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
    );
  }
}
