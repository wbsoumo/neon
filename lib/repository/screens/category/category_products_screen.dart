import 'package:flutter/material.dart';
import 'package:blinkit_series/repository/widgets/animated_cart_button.dart';
import 'package:blinkit_series/repository/widgets/uihelper.dart';
import 'package:blinkit_series/repository/services/api_service.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String categoryName;
  final String categoryImg;
  final int? categoryId;

  const CategoryProductsScreen({
    super.key,
    required this.categoryName,
    required this.categoryImg,
    this.categoryId,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  int _selectedSubCatIndex = 0;
  final Set<String> _favoriteIds = {};

  final List<Map<String, String>> _subCategories = [
    {"name": "All", "img": "image 41.png"},
    {"name": "Fresh Vegetables", "text": "Fresh\nVegetables", "img": "image 41.png"},
    {"name": "Fresh Fruits", "text": "Fresh\nFruits", "img": "image 41.png"},
    {"name": "Exotics", "text": "Exotics", "img": "image 41.png"},
    {"name": "Coriander & Others", "text": "Coriander &\nOthers", "img": "image 41.png"},
    {"name": "Freshly Cut & Sprouts", "text": "Freshly Cut &\nSprouts", "img": "image 41.png"},
    {"name": "Trusted Organics", "text": "Trusted\nOrganics", "img": "image 41.png"},
    {"name": "Flowers & Leaves", "text": "Flowers &\nLeaves", "img": "image 41.png"},
  ];

  List<Map<String, dynamic>> _liveProducts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCategoryProducts();
  }

  Future<void> _fetchCategoryProducts() async {
    setState(() => _isLoading = true);
    final prods = await ApiService.fetchProducts(categoryId: widget.categoryId);
    if (mounted) {
      setState(() {
        if (prods.isNotEmpty) {
          _liveProducts = prods.map((p) {
            final double price = double.tryParse(p['effective_price']?.toString() ?? p['price']?.toString() ?? '0') ?? 0.0;
            final double mrp = double.tryParse(p['effective_mrp']?.toString() ?? p['mrp']?.toString() ?? '0') ?? (price * 1.25);
            final String img = p['image'] ?? widget.categoryImg;
            return {
              "id": p['id'].toString(),
              "name": p['name'].toString(),
              "unit": p['unit']?.toString() ?? "1 unit",
              "price": price,
              "mrp": mrp,
              "mins": "12 mins",
              "stock": p['available_stock'] != null ? "${p['available_stock']} left" : null,
              "subCat": "All",
              "img": img,
            };
          }).toList();
        }
        _isLoading = false;
      });
    }
  }

  final List<Map<String, dynamic>> _mockProducts = [
    {
      "id": "pooja_1",
      "name": "Assorted Fruits for Pooja (Panch Phal)",
      "unit": "1 pack",
      "price": 89.0,
      "mrp": 110.0,
      "mins": "11 mins",
      "stock": null,
      "subCat": "Fresh Fruits",
      "img": "image 41.png",
    },
    {
      "id": "pooja_2",
      "name": "Hibiscus Flowers (Gudhal)",
      "unit": "5 pcs",
      "price": 9.0,
      "mrp": 10.0,
      "mins": "11 mins",
      "stock": "2 left",
      "subCat": "Flowers & Leaves",
      "img": "image 41.png",
    },
    {
      "id": "pooja_3",
      "name": "Mix Marigold Garland",
      "unit": "1 pc",
      "price": 62.0,
      "mrp": 73.0,
      "tag": "3.5 ft",
      "mins": "11 mins",
      "stock": "2 left",
      "subCat": "Flowers & Leaves",
      "img": "image 41.png",
    },
    {
      "id": "pooja_4",
      "name": "Doob Grass / Durva Grass (Garike)",
      "unit": "1 pack",
      "price": 15.0,
      "mrp": 18.0,
      "mins": "11 mins",
      "stock": null,
      "subCat": "Flowers & Leaves",
      "img": "image 41.png",
    },
    {
      "id": "veg_1",
      "name": "Hybrid Fresh Tomato",
      "unit": "500 g",
      "price": 24.0,
      "mrp": 35.0,
      "mins": "11 mins",
      "stock": null,
      "subCat": "Fresh Vegetables",
      "img": "tomato.png",
    },
    {
      "id": "veg_2",
      "name": "Organic Farm Potato",
      "unit": "1 kg",
      "price": 32.0,
      "mrp": 40.0,
      "mins": "11 mins",
      "stock": "5 left",
      "subCat": "Fresh Vegetables",
      "img": "potato.png",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final String title = widget.categoryName.replaceAll('\n', ' ');

    final List<Map<String, dynamic>> displayList = _liveProducts.isNotEmpty ? _liveProducts : _mockProducts;

    // Filter products based on selected sub-category
    final selectedSubCatName = _subCategories[_selectedSubCatIndex]["name"]!;
    final filteredProducts = selectedSubCatName == "All"
        ? displayList
        : displayList.where((p) => p["subCat"] == selectedSubCatName || p["subCat"] == "All").toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: const Color(0XFFF2F3F5),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: const [
                Text(
                  "Delivering to Ratanr Flat 11E: 11E, Kris...",
                  style: TextStyle(
                    color: Color(0XFF0C831F),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Color(0XFF0C831F), size: 16),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.ios_share, color: Colors.black, size: 20),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Row(
        children: [
          // 1. Left Vertical Sub-Category Navigation Sidebar
          Container(
            width: 82,
            color: Colors.white,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: _subCategories.length,
              itemBuilder: (context, index) {
                final subCat = _subCategories[index];
                final bool isSelected = _selectedSubCatIndex == index;
                final String label = subCat["text"] ?? subCat["name"]!;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedSubCatIndex = index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0XFFFDF8E7) : Colors.white,
                      border: Border(
                        left: BorderSide(
                          color: isSelected ? const Color(0XFF0C831F) : Colors.transparent,
                          width: 3.5,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0XFFF4F6F8),
                            border: isSelected
                                ? Border.all(color: const Color(0XFF0C831F), width: 1.5)
                                : null,
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: UiHelper.CustomImage(img: subCat['img'] ?? "image 41.png"),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.black : const Color(0XFF757575),
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const VerticalDivider(width: 1, thickness: 1, color: Color(0XFFE0E0E0)),

          // 2. Right Main Products Section
          Expanded(
            child: Container(
              color: const Color(0XFFFDF6E3), // Warm festive yellow background matching screenshot
              child: Column(
                children: [
                  // Top Filter Chips Bar
                  Container(
                    height: 46,
                    color: Colors.white,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildFilterChip("Filters", icon: Icons.tune),
                        _buildFilterChip("Sort", icon: Icons.swap_vert),
                        _buildFilterChip("Type"),
                        _buildFilterChip("Country Of Origin"),
                      ],
                    ),
                  ),

                  // Products Body
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Festive Banner Header
                          const Text(
                            "Celebrate Ganesh Chaturthi",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              fontFamily: "bold",
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "Bring home nature's charm",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0XFF616161),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 2-Column Product Grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.76,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final item = filteredProducts[index];
                              final String id = item["id"];
                              final String name = item["name"];
                              final String unit = item["unit"];
                              final double price = (item["price"] as num).toDouble();
                              final double mrp = (item["mrp"] as num).toDouble();
                              final String mins = item["mins"];
                              final String? stock = item["stock"];
                              final String? tag = item["tag"];
                              final String img = item["img"];
                              final bool isFav = _favoriteIds.contains(id);

                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Top Image with Heart & ADD button overlay
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                          child: Container(
                                            height: 125,
                                            width: double.infinity,
                                            color: const Color(0XFFF9F9F9),
                                            child: UiHelper.CustomImage(
                                              img: img,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),

                                        // Heart Favorite Icon
                                        Positioned(
                                          top: 6,
                                          right: 6,
                                          child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                if (isFav) {
                                                  _favoriteIds.remove(id);
                                                } else {
                                                  _favoriteIds.add(id);
                                                }
                                              });
                                            },
                                            child: CircleAvatar(
                                              radius: 12,
                                              backgroundColor: Colors.white.withOpacity(0.85),
                                              child: Icon(
                                                isFav ? Icons.favorite : Icons.favorite_border,
                                                size: 14,
                                                color: isFav ? Colors.red : Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Bottom Bar over Image: Unit tag on left, ADD button on right
                                        Positioned(
                                          bottom: 6,
                                          left: 6,
                                          right: 6,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.9),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  unit,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              AnimatedCartButton(
                                                id: id,
                                                name: name,
                                                img: img,
                                                price: price,
                                                unit: unit,
                                                width: 54,
                                                height: 28,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Content Section Below Image
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Price & Discount Strikethrough
                                          Row(
                                            children: [
                                              Text(
                                                "₹${price.toStringAsFixed(0)}",
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                "₹${mrp.toStringAsFixed(0)}",
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0XFF9E9E9E),
                                                  decoration: TextDecoration.lineThrough,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),

                                          // Product Name
                                          Text(
                                            name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                              height: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 4),

                                          if (tag != null)
                                            Container(
                                              margin: const EdgeInsets.only(bottom: 4),
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: const Color(0XFFFFECB3),
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                              child: Text(
                                                tag,
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0XFF8D6E63),
                                                ),
                                              ),
                                            ),

                                          // Delivery Estimate & Low Stock Indicator
                                          Row(
                                            children: [
                                              const Icon(Icons.timer_outlined, size: 11, color: Color(0XFF757575)),
                                              const SizedBox(width: 2),
                                              Text(
                                                mins,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Color(0XFF757575),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              if (stock != null) ...[
                                                const SizedBox(width: 6),
                                                const Icon(Icons.battery_2_bar, size: 11, color: Color(0XFF757575)),
                                                const SizedBox(width: 2),
                                                Text(
                                                  stock,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Color(0XFF757575),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          // Bottom "See all products ❯" button
                          Center(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0XFFE0E0E0)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    "See all products",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0XFF1E3A8A),
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_right, color: Color(0XFF1E3A8A), size: 18),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
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

  Widget _buildFilterChip(String label, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0XFFE0E0E0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.black87),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.arrow_drop_down, size: 14, color: Colors.black87),
        ],
      ),
    );
  }
}
