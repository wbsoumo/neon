import 'package:flutter/material.dart';
import 'package:blinkit_series/repository/screens/cart/cartscreen.dart';
import 'package:blinkit_series/repository/screens/search/searchscreen.dart';
import 'package:blinkit_series/repository/widgets/animated_cart_button.dart';
import 'package:blinkit_series/repository/widgets/floating_cart_pill.dart';
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

  // Active Filter / Sort state
  String _selectedSort = "Relevance";
  String _selectedType = "All";
  String _selectedOrigin = "All";

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

  List<Map<String, dynamic>> _sideCategories = [];
  List<Map<String, dynamic>> _categoryProducts = [];
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndProducts();
  }

  Future<void> _loadCategoriesAndProducts() async {
    final allCats = await ApiService.fetchCategories();
    if (mounted && allCats.isNotEmpty) {
      int initialIdx = 0;
      if (widget.categoryId != null) {
        final matchIdx = allCats.indexWhere((c) => c['id'] == widget.categoryId);
        if (matchIdx != -1) initialIdx = matchIdx;
      }
      setState(() {
        _sideCategories = allCats;
        _selectedCategoryIndex = initialIdx;
      });
      _fetchProductsForCategory(allCats[initialIdx]['id']);
    } else {
      _fetchProductsForCategory(widget.categoryId);
    }
  }

  Future<void> _fetchProductsForCategory(int? catId) async {
    final prods = await ApiService.fetchProducts(categoryId: catId);
    if (mounted) {
      setState(() {
        if (prods.isNotEmpty) {
          _categoryProducts = prods.map((p) {
            final double price = double.tryParse(p['effective_price']?.toString() ?? p['price']?.toString() ?? '0') ?? 0.0;
            final double mrp = double.tryParse(p['effective_mrp']?.toString() ?? p['mrp']?.toString() ?? '0') ?? (price * 1.25);
            final String img = p['image']?.toString() ?? widget.categoryImg;
            final String origin = p['origin'] ?? (p['id'].hashCode % 2 == 0 ? "India" : "Imported");
            final String type = p['type'] ?? (price > 50 ? "Organic" : "Standard");
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
              "type": type,
              "origin": origin,
            };
          }).toList();
        } else {
          _categoryProducts = [];
        }
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
      "type": "Organic",
      "origin": "India",
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
      "type": "Standard",
      "origin": "India",
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
      "type": "Standard",
      "origin": "India",
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
      "type": "Standard",
      "origin": "India",
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
      "type": "Hydroponic",
      "origin": "India",
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
      "type": "Organic",
      "origin": "India",
      "img": "potato.png",
    },
    {
      "id": "exotic_1",
      "name": "Exotic Imported Avocado",
      "unit": "2 pcs",
      "price": 189.0,
      "mrp": 250.0,
      "mins": "15 mins",
      "stock": "3 left",
      "subCat": "Exotics",
      "type": "Organic",
      "origin": "Imported",
      "img": "image 41.png",
    },
  ];

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final options = [
          "Relevance",
          "Price: Low to High",
          "Price: High to Low",
          "Discount: High to Low",
        ];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Sort Products By",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...options.map((opt) {
                final bool isSel = _selectedSort == opt;
                return ListTile(
                  title: Text(opt, style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                  trailing: isSel ? const Icon(Icons.check_circle, color: Color(0XFF0C831F)) : null,
                  onTap: () {
                    setState(() => _selectedSort = opt);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showTypeBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final options = ["All", "Organic", "Hydroponic", "Standard"];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Filter by Product Type",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...options.map((opt) {
                final bool isSel = _selectedType == opt;
                return ListTile(
                  title: Text(opt, style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                  trailing: isSel ? const Icon(Icons.check_circle, color: Color(0XFF0C831F)) : null,
                  onTap: () {
                    setState(() => _selectedType = opt);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showOriginBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final options = ["All", "India", "Imported"];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Filter by Country of Origin",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...options.map((opt) {
                final bool isSel = _selectedOrigin == opt;
                return ListTile(
                  title: Text(opt, style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                  trailing: isSel ? const Icon(Icons.check_circle, color: Color(0XFF0C831F)) : null,
                  onTap: () {
                    setState(() => _selectedOrigin = opt);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showAllFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.55,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("All Filters & Sort", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedSort = "Relevance";
                            _selectedType = "All";
                            _selectedOrigin = "All";
                          });
                          setModalState(() {});
                        },
                        child: const Text("Reset All", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      children: [
                        const Text("Sort By", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Wrap(
                          spacing: 8,
                          children: ["Relevance", "Price: Low to High", "Price: High to Low"].map((s) {
                            final sel = _selectedSort == s;
                            return ChoiceChip(
                              label: Text(s),
                              selected: sel,
                              selectedColor: const Color(0XFFE8F5E9),
                              onSelected: (_) {
                                setState(() => _selectedSort = s);
                                setModalState(() {});
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        const Text("Product Type", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Wrap(
                          spacing: 8,
                          children: ["All", "Organic", "Hydroponic", "Standard"].map((t) {
                            final sel = _selectedType == t;
                            return ChoiceChip(
                              label: Text(t),
                              selected: sel,
                              selectedColor: const Color(0XFFE8F5E9),
                              onSelected: (_) {
                                setState(() => _selectedType = t);
                                setModalState(() {});
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        const Text("Country of Origin", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Wrap(
                          spacing: 8,
                          children: ["All", "India", "Imported"].map((o) {
                            final sel = _selectedOrigin == o;
                            return ChoiceChip(
                              label: Text(o),
                              selected: sel,
                              selectedColor: const Color(0XFFE8F5E9),
                              onSelected: (_) {
                                setState(() => _selectedOrigin = o);
                                setModalState(() {});
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0XFF0C831F),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Apply Filters", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.categoryName.replaceAll('\n', ' ');

    final List<Map<String, dynamic>> displayList = _categoryProducts.isNotEmpty ? _categoryProducts : _mockProducts;

    // 1. Filter products based on active category/sub-category
    var filteredProducts = List<Map<String, dynamic>>.from(displayList);

    // 2. Apply Type Filter
    if (_selectedType != "All") {
      filteredProducts = filteredProducts.where((p) => (p["type"] ?? "Standard") == _selectedType).toList();
    }

    // 3. Apply Origin Filter
    if (_selectedOrigin != "All") {
      filteredProducts = filteredProducts.where((p) => (p["origin"] ?? "India") == _selectedOrigin).toList();
    }

    // 4. Apply Sorting
    if (_selectedSort == "Price: Low to High") {
      filteredProducts.sort((a, b) => (a["price"] as num).compareTo(b["price"] as num));
    } else if (_selectedSort == "Price: High to Low") {
      filteredProducts.sort((a, b) => (b["price"] as num).compareTo(a["price"] as num));
    } else if (_selectedSort == "Discount: High to Low") {
      filteredProducts.sort((a, b) {
        final double discA = ((a["mrp"] as num) - (a["price"] as num)).toDouble();
        final double discB = ((b["mrp"] as num) - (b["price"] as num)).toDouble();
        return discB.compareTo(discA);
      });
    }

    // Sidebar items from backend API categories or static fallback
    final sidebarItems = _sideCategories.isNotEmpty
        ? _sideCategories
        : _subCategories.map((s) => {"name": s["name"] ?? s["text"], "image": s["img"]}).toList();

    final activeCategoryName = _sideCategories.isNotEmpty
        ? (_sideCategories[_selectedCategoryIndex]["name"] ?? title)
        : title;

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
              activeCategoryName.replaceAll('\n', ' '),
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(
                    allProducts: displayList,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.ios_share, color: Colors.black, size: 20),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          Row(
            children: [
              // 1. Left Vertical Category Navigation Sidebar
              Container(
                width: 84,
                color: Colors.white,
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: sidebarItems.length,
                  itemBuilder: (context, index) {
                    final catItem = sidebarItems[index];
                    final bool isSelected = _selectedCategoryIndex == index;
                    final String label = (catItem["name"] ?? "").toString();
                    final String img = (catItem["image"] ?? catItem["img"] ?? "image 41.png").toString();
                    final int? cId = catItem["id"] is int ? catItem["id"] : int.tryParse(catItem["id"]?.toString() ?? "");

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategoryIndex = index;
                        });
                        _fetchProductsForCategory(cId);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
                                  child: UiHelper.CustomImage(img: img),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              label.replaceAll('\n', ' '),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
                      // Top Interactive Filter Chips Bar
                      Container(
                        height: 46,
                        color: Colors.white,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildFilterChip(
                              "Filters",
                              icon: Icons.tune,
                              isActive: _selectedSort != "Relevance" || _selectedType != "All" || _selectedOrigin != "All",
                              onTap: _showAllFiltersBottomSheet,
                            ),
                            _buildFilterChip(
                              "Sort: $_selectedSort",
                              icon: Icons.swap_vert,
                              isActive: _selectedSort != "Relevance",
                              onTap: _showSortBottomSheet,
                            ),
                            _buildFilterChip(
                              "Type: $_selectedType",
                              isActive: _selectedType != "All",
                              onTap: _showTypeBottomSheet,
                            ),
                            _buildFilterChip(
                              "Origin: $_selectedOrigin",
                              isActive: _selectedOrigin != "All",
                              onTap: _showOriginBottomSheet,
                            ),
                          ],
                        ),
                      ),

                      // Products Body
                      Expanded(
                        child: filteredProducts.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.search_off, size: 48, color: Colors.grey),
                                    const SizedBox(height: 8),
                                    const Text("No products match active filters", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 6),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _selectedSort = "Relevance";
                                          _selectedType = "All";
                                          _selectedOrigin = "All";
                                        });
                                      },
                                      child: const Text("Reset Filters", style: TextStyle(color: Color(0XFF0C831F), fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              )
                            : SingleChildScrollView(
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
                                        childAspectRatio: 0.64,
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
                                                color: Colors.black.withValues(alpha: 0.04),
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
                                                      height: 110,
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
                                                        backgroundColor: Colors.white.withValues(alpha: 0.85),
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
                                                            color: Colors.white.withValues(alpha: 0.9),
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
                                    const SizedBox(height: 80),
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
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: FloatingCartPill(
              onViewCartTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CartScreen(
                      onBackTap: () => Navigator.pop(context),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label, {
    IconData? icon,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0XFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? const Color(0XFF0C831F) : const Color(0XFFE0E0E0),
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isActive ? const Color(0XFF0C831F) : Colors.black87),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: isActive ? const Color(0XFF0C831F) : Colors.black87,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 14,
              color: isActive ? const Color(0XFF0C831F) : Colors.black87,
            ),
          ],
        ),
      ),
    );
  }
}
