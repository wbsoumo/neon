import 'dart:async';
import 'package:flutter/material.dart';
import 'package:blinkit_series/repository/widgets/animated_cart_button.dart';
import 'package:blinkit_series/repository/widgets/uihelper.dart';
import 'package:blinkit_series/repository/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController searchController = TextEditingController();
  int _selectedCategoryIndex = 0;

  Timer? _searchHintTimer;
  int _searchHintIndex = 0;
  final List<String> _searchHints = [
    "milk",
    "atta, dal",
    "chips",
    "diwali lights",
    "chocolates",
    "headphones",
    "face wash",
    "gifts"
  ];

  Map<String, dynamic>? _selectedStoreData;
  List<Map<String, dynamic>> _liveProducts = [];
  bool _isLoadingLiveProducts = false;

  @override
  void initState() {
    super.initState();
    _fetchLiveBackendData();
    _searchHintTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _searchHintIndex = (_searchHintIndex + 1) % _searchHints.length;
        });
      }
    });
  }

  Future<void> _fetchLiveBackendData() async {
    setState(() => _isLoadingLiveProducts = true);
    final store = await ApiService.fetchSelectedStore();
    final prods = await ApiService.fetchProducts(storeId: store?['id'] ?? 1);
    if (mounted) {
      setState(() {
        _selectedStoreData = store;
        if (prods.isNotEmpty) {
          _liveProducts = prods;
          // Dynamically map API products with database images into featured and grocery sections
          featuredItems.clear();
          groceryKitchenItems.clear();
          for (var p in prods) {
            final double price = double.tryParse(p['effective_price']?.toString() ?? p['price']?.toString() ?? '0') ?? 0.0;
            final String img = p['image'] ?? 'http://images.unsplash.com/photo-1542838132-92c53300491e?w=500&q=80';
            final mapItem = {
              "id": p['id'].toString(),
              "img": img,
              "text": p['name'].toString(),
              "price": price,
            };
            if (p['is_featured'] == 1 || p['is_featured'] == true) {
              featuredItems.add(mapItem);
            }
            groceryKitchenItems.add(mapItem);
          }
          if (featuredItems.isEmpty && groceryKitchenItems.isNotEmpty) {
            featuredItems.addAll(groceryKitchenItems.take(3));
          }
        }
        _isLoadingLiveProducts = false;
      });
    }
  }

  final List<Map<String, dynamic>> _headerCategories = [
    {"name": "All", "icon": Icons.shopping_bag_outlined},
    {"name": "Ganeshotsav", "icon": Icons.festival_outlined},
    {"name": "Electronics", "icon": Icons.headphones_outlined},
    {"name": "Beauty", "icon": Icons.brush_outlined},
    {"name": "Gifting", "icon": Icons.card_giftcard_outlined},
    {"name": "Pharmacy", "icon": Icons.local_hospital_outlined},
    {"name": "Pet Care", "icon": Icons.pets_outlined},
    {"name": "Toys", "icon": Icons.toys_outlined},
  ];

  final List<Map<String, String>> megaSaleData = [
    {"img": "image 50.png", "text": "Lights, Diyas \n & Candles"},
    {"img": "image 51.png", "text": "Diwali \n Gifts"},
    {"img": "image 52.png", "text": "Appliances  \n & Gadgets"},
    {"img": "image 53.png", "text": "Home \n & Living"}
  ];

  final List<Map<String, dynamic>> featuredItems = [
    {"id": "feat_1", "img": "image 54.png", "text": "Golden Glass\n Wooden Lid Candle (Oudh)", "price": 79.0},
    {"id": "feat_2", "img": "image 57.png", "text": "Royal Gulab Jamun\n By Bikano", "price": 149.0},
    {"id": "feat_3", "img": "image 63.png", "text": "Golden Glass\n Wooden Lid Candle (Oudh)", "price": 79.0},
  ];

  final List<Map<String, dynamic>> groceryKitchenItems = [
    {"id": "groc_1", "img": "image 41.png", "text": "Vegetables & \nFruits", "price": 49.0},
    {"id": "groc_2", "img": "image 42.png", "text": "Atta, Dal & \nRice", "price": 199.0},
    {"id": "groc_3", "img": "image 43.png", "text": "Oil, Ghee & \nMasala", "price": 165.0},
    {"id": "groc_4", "img": "image 44 (1).png", "text": "Dairy, Bread & \nMilk", "price": 33.0},
    {"id": "groc_5", "img": "image 45 (1).png", "text": "Biscuits & \nBakery", "price": 40.0}
  ];

  // Specific Category Products Database
  final Map<String, List<Map<String, dynamic>>> _categoryProducts = {
    "Ganeshotsav": [
      {"id": "gan_1", "name": "Assorted Panch Phal for Pooja", "unit": "1 pack", "price": 89.0, "mrp": 110.0, "img": "image 41.png"},
      {"id": "gan_2", "name": "Fresh Hibiscus Flowers (Gudhal)", "unit": "5 pcs", "price": 9.0, "mrp": 10.0, "img": "image 41.png"},
      {"id": "gan_3", "name": "Mix Marigold Garland 3.5ft", "unit": "1 pc", "price": 62.0, "mrp": 73.0, "img": "image 41.png"},
      {"id": "gan_4", "name": "Durva Grass / Doob Grass", "unit": "1 pack", "price": 15.0, "mrp": 18.0, "img": "image 41.png"},
    ],
    "Electronics": [
      {"id": "elec_1", "name": "Wireless Stereo Headphones", "unit": "1 unit", "price": 899.0, "mrp": 1499.0, "img": "image 52.png"},
      {"id": "elec_2", "name": "Fast Charging Powerbank 10000mAh", "unit": "1 unit", "price": 699.0, "mrp": 1199.0, "img": "image 52.png"},
      {"id": "elec_3", "name": "Type-C Braided Cable 1.5m", "unit": "1 pc", "price": 199.0, "mrp": 399.0, "img": "image 52.png"},
    ],
    "Beauty": [
      {"id": "bt_1", "name": "Matte Lipstick Velvet Red", "unit": "1 pc", "price": 249.0, "mrp": 350.0, "img": "image 35.png"},
      {"id": "bt_2", "name": "Nourishing Herbal Hair Oil", "unit": "200 ml", "price": 135.0, "mrp": 175.0, "img": "image 35.png"},
      {"id": "bt_3", "name": "Hydrating Face Moisturizer", "unit": "100 g", "price": 180.0, "mrp": 250.0, "img": "image 35.png"},
    ],
    "Gifting": [
      {"id": "gift_1", "name": "Diwali Royal Gift Hamper", "unit": "1 box", "price": 499.0, "mrp": 699.0, "img": "image 51.png"},
      {"id": "gift_2", "name": "Premium Assorted Chocolates", "unit": "300 g", "price": 299.0, "mrp": 399.0, "img": "image 51.png"},
      {"id": "gift_3", "name": "Decorative Brass Diya Set", "unit": "2 pcs", "price": 199.0, "mrp": 299.0, "img": "image 50.png"},
    ],
    "Pharmacy": [
      {"id": "pharm_1", "name": "First Aid Medical Kit", "unit": "1 kit", "price": 199.0, "mrp": 250.0, "img": "image 41.png"},
      {"id": "pharm_2", "name": "Vitamin C Immunity Tablets", "unit": "60 tabs", "price": 149.0, "mrp": 200.0, "img": "image 41.png"},
    ],
    "Pet Care": [
      {"id": "pet_1", "name": "Adult Dog Food Chicken & Rice", "unit": "1.2 kg", "price": 320.0, "mrp": 400.0, "img": "image 41.png"},
      {"id": "pet_2", "name": "Interactive Rubber Pet Toy", "unit": "1 pc", "price": 99.0, "mrp": 150.0, "img": "image 41.png"},
    ],
    "Toys": [
      {"id": "toy_1", "name": "Diecast Metal Toy Car", "unit": "1 pc", "price": 149.0, "mrp": 220.0, "img": "image 52.png"},
      {"id": "toy_2", "name": "3x3 Speed Puzzle Cube", "unit": "1 pc", "price": 89.0, "mrp": 149.0, "img": "image 52.png"},
    ],
  };

  @override
  void dispose() {
    _searchHintTimer?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCatName = _headerCategories[_selectedCategoryIndex]["name"] as String;
    final bool isAllSelected = _selectedCategoryIndex == 0;

    return Scaffold(
      backgroundColor: const Color(0XFFF5F6F8),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Fresh Green Header (Matching App Theme)
            Container(
              decoration: const BoxDecoration(
                color: Color(0XFF0C831F),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // Top Row: Delivery Time, Location & Wallet/Profile Icons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedStoreData != null
                                      ? "Delivery in ${_selectedStoreData!['delivery_time_mins'] ?? '10-15'} mins"
                                      : "Blinkit in 18 minutes",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _selectedStoreData != null
                                      ? "${_selectedStoreData!['name'] ?? 'Dark Store'}"
                                      : "18 minutes",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _selectedStoreData != null
                                            ? "${_selectedStoreData!['address'] ?? 'Store Location'}, ${_selectedStoreData!['city'] ?? ''}"
                                            : "Krishnanagar, Hub 1...",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Wallet Pill & Profile Avatar
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.all(2),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: const Color(0XFFF7CB45),
                                      child: const Icon(Icons.account_balance_wallet, color: Color(0XFF0C831F), size: 16),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0XFF212121),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        "₹0",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 10),

                              const CircleAvatar(
                                radius: 18,
                                backgroundColor: Color(0XFF421503),
                                child: Icon(Icons.person, color: Colors.white, size: 20),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Search Bar with right vertical divider & mic icon & animated sliding hint text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            const Icon(Icons.search, color: Colors.black87, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  if (searchController.text.isEmpty)
                                    IgnorePointer(
                                      child: Row(
                                        children: [
                                          const Text(
                                            'Search ',
                                            style: TextStyle(
                                              color: Color(0XFF5C6BC0),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          ClipRect(
                                            child: AnimatedSwitcher(
                                              duration: const Duration(milliseconds: 400),
                                              transitionBuilder: (Widget child, Animation<double> animation) {
                                                final inAnimation = Tween<Offset>(
                                                  begin: const Offset(0, 1.0),
                                                  end: Offset.zero,
                                                ).animate(animation);
                                                final outAnimation = Tween<Offset>(
                                                  begin: const Offset(0, -1.0),
                                                  end: Offset.zero,
                                                ).animate(animation);

                                                if (child.key == ValueKey<int>(_searchHintIndex)) {
                                                  return SlideTransition(
                                                    position: inAnimation,
                                                    child: FadeTransition(opacity: animation, child: child),
                                                  );
                                                } else {
                                                  return SlideTransition(
                                                    position: outAnimation,
                                                    child: FadeTransition(opacity: animation, child: child),
                                                  );
                                                }
                                              },
                                              child: Text(
                                                '"${_searchHints[_searchHintIndex]}"',
                                                key: ValueKey<int>(_searchHintIndex),
                                                style: const TextStyle(
                                                  color: Color(0XFF5C6BC0),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  TextField(
                                    controller: searchController,
                                    onChanged: (val) {
                                      setState(() {});
                                    },
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IntrinsicHeight(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  VerticalDivider(
                                    width: 1,
                                    thickness: 1,
                                    indent: 10,
                                    endIndent: 10,
                                    color: Color(0XFFE0E0E0),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.mic, color: Colors.black87, size: 22),
                                  SizedBox(width: 12),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Scrollable Header Categories Row
                    SizedBox(
                      height: 62,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _headerCategories.length,
                        itemBuilder: (context, index) {
                          final cat = _headerCategories[index];
                          final bool isSelected = _selectedCategoryIndex == index;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedCategoryIndex = index;
                              });
                            },
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(
                                    cat["icon"] as IconData,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  Text(
                                    cat["name"] as String,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                  Container(
                                    height: 3,
                                    width: 28,
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),

            if (isAllSelected) ...[
              // ---------------- MAIN HOME VIEW WHEN "ALL" IS SELECTED ----------------

              // Mega Diwali Sale Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: const Color(0XFF0C831F),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.stars, color: Color(0XFFF7CB45), size: 20),
                        const SizedBox(width: 8),
                        UiHelper.CustomText(
                            text: "Mega Diwali Sale",
                            color: Colors.white,
                            fontweight: FontWeight.bold,
                            fontsize: 20,
                            fontfamily: "bold"),
                        const SizedBox(width: 8),
                        const Icon(Icons.stars, color: Color(0XFFF7CB45), size: 20),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 140,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: ListView.builder(
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              child: Container(
                                width: 100,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                    color: const Color(0XFFEAD3D3),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: UiHelper.CustomImage(
                                            img: megaSaleData[index]["img"].toString(),
                                            width: 88,
                                            height: 70,
                                            fit: BoxFit.cover),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      megaSaleData[index]["text"].toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          itemCount: megaSaleData.length,
                          scrollDirection: Axis.horizontal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Featured Candles & Diwali Gifts Section with Animated Cart Buttons
              SizedBox(
                height: 255,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ListView.builder(
                    itemBuilder: (context, index) {
                      final item = featuredItems[index];
                      final String title = item["text"].toString();
                      final double price = (item["price"] as num).toDouble();
                      final String img = item["img"].toString();

                      return Container(
                        width: 125,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              clipBehavior: Clip.antiAlias,
                              height: 100,
                              width: 125,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: UiHelper.CustomImage(img: img, fit: BoxFit.cover),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 12, color: Color(0XFF9C9C9C)),
                                const SizedBox(width: 2),
                                UiHelper.CustomText(
                                    text: "16 MINS",
                                    color: const Color(0XFF9C9C9C),
                                    fontweight: FontWeight.normal,
                                    fontsize: 10)
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                UiHelper.CustomText(
                                    text: "₹${price.toStringAsFixed(0)}",
                                    color: Colors.black,
                                    fontweight: FontWeight.bold,
                                    fontsize: 13),
                                AnimatedCartButton(
                                  id: "feat_$index",
                                  name: title.replaceAll('\n', ' '),
                                  img: img,
                                  price: price,
                                  width: 64,
                                  height: 28,
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                    itemCount: featuredItems.length,
                    scrollDirection: Axis.horizontal,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Grocery & Kitchen Header
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: UiHelper.CustomText(
                    text: "Grocery & Kitchen",
                    color: Colors.black,
                    fontweight: FontWeight.bold,
                    fontsize: 15,
                    fontfamily: "bold"),
              ),
              const SizedBox(height: 10),

              // Grocery & Kitchen Horizontal List
              SizedBox(
                height: 175,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: ListView.builder(
                    itemBuilder: (context, index) {
                      final item = groceryKitchenItems[index];
                      final String title = item["text"].toString();
                      final double price = (item["price"] as num).toDouble();
                      final String img = item["img"].toString();

                      return Container(
                        width: 85,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            Container(
                              height: 75,
                              width: 75,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: const Color(0XFFD9EBEB)),
                              child: UiHelper.CustomImage(img: img, fit: BoxFit.cover),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              title,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.normal,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 6),
                            AnimatedCartButton(
                              id: "groc_$index",
                              name: title.replaceAll('\n', ' '),
                              img: img,
                              price: price,
                              width: 70,
                              height: 26,
                            ),
                          ],
                        ),
                      );
                    },
                    itemCount: groceryKitchenItems.length,
                    scrollDirection: Axis.horizontal,
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ] else ...[
              // ---------------- SPECIFIC CATEGORY VIEW WHEN SPECIFIC CATEGORY IS SELECTED ----------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedCatName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      "${(_categoryProducts[selectedCatName] ?? []).length} items",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0XFF757575),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.76,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: (_categoryProducts[selectedCatName] ?? []).length,
                itemBuilder: (context, index) {
                  final item = _categoryProducts[selectedCatName]![index];
                  final String id = item["id"];
                  final String name = item["name"];
                  final String unit = item["unit"];
                  final double price = (item["price"] as num).toDouble();
                  final double mrp = (item["mrp"] as num).toDouble();
                  final String img = item["img"];

                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
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
                        Expanded(
                          child: Center(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0XFFF9F9F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: UiHelper.CustomImage(img: img),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          unit,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0XFF757575),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "₹${price.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "₹${mrp.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0XFF9E9E9E),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ),
                            AnimatedCartButton(
                              id: id,
                              name: name,
                              img: img,
                              price: price,
                              unit: unit,
                              width: 62,
                              height: 28,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
    );
  }
}
