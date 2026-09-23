import 'package:flutter/material.dart';
import 'package:blinkit_series/repository/screens/category/category_products_screen.dart';
import 'package:blinkit_series/repository/screens/search/searchscreen.dart';
import 'package:blinkit_series/repository/services/api_service.dart';
import 'package:blinkit_series/repository/widgets/address_selection_bottom_sheet.dart';
import 'package:blinkit_series/repository/widgets/uihelper.dart';

class CategoryScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;

  const CategoryScreen({super.key, this.onProfileTap});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> _categoriesFromApi = [];
  List<Map<String, dynamic>> _allProducts = [];
  Map<String, dynamic>? _selectedStoreData;
  String _userAddress = "HOME - Sujal Dave, Ratanada, Jodhpur (Raj)";

  final List<Map<String, dynamic>> _fallbackCategories = [
    {"id": 1, "name": "Vegetables & Fruits", "image": "https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=500&q=80"},
    {"id": 2, "name": "Atta, Dal & Rice", "image": "https://images.unsplash.com/photo-1586201375761-83865001e31c?w=500&q=80"},
    {"id": 3, "name": "Oil, Ghee & Masala", "image": "https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=500&q=80"},
    {"id": 4, "name": "Dairy, Bread & Milk", "image": "https://images.unsplash.com/photo-1550583724-b2692b85b150?w=500&q=80"},
    {"id": 5, "name": "Biscuits & Bakery", "image": "https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=500&q=80"},
    {"id": 6, "name": "Lights, Diyas & Candles", "image": "https://images.unsplash.com/photo-1602874801007-bd458bb1b8b6?w=500&q=80"},
    {"id": 7, "name": "Electronics & Gadgets", "image": "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500&q=80"},
    {"id": 8, "name": "Beauty & Cosmetics", "image": "https://images.unsplash.com/photo-1586495777744-4413f21062fa?w=500&q=80"},
  ];

  @override
  void initState() {
    super.initState();
    _categoriesFromApi = _fallbackCategories;
    _loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final store = await ApiService.fetchSelectedStore();
    final cats = await ApiService.fetchCategories();
    final prods = await ApiService.fetchProducts();
    final savedAddr = await ApiService.getUserSelectedAddress();

    if (mounted) {
      setState(() {
        if (store != null) _selectedStoreData = store;
        if (cats.isNotEmpty) _categoriesFromApi = cats;
        _allProducts = prods;
        if (savedAddr != null && savedAddr.isNotEmpty) {
          _userAddress = savedAddr;
        }
      });
    }
  }

  void _openSearchScreen([String query = '']) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchScreen(
          allProducts: _allProducts,
          initialQuery: query,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Location & Search Header matching HomeScreen
            Container(
              color: const Color(0XFFF7CB45),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 16, left: 16, right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Delivery info, location & Profile icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedStoreData != null
                                      ? ((_selectedStoreData!['is_serviceable'] ?? true)
                                          ? "Delivery in ${_selectedStoreData!['delivery_time_mins'] ?? '15'} mins"
                                          : "🚫 Location Unserviceable")
                                      : "SB Mart in 16 minutes",
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _selectedStoreData != null
                                      ? ((_selectedStoreData!['is_serviceable'] ?? true)
                                          ? "${_selectedStoreData!['name'] ?? 'Dark Store'}"
                                          : "No Store Delivers Here")
                                      : "16 minutes",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () {
                                    AddressSelectionBottomSheet.show(
                                      context,
                                      onAddressSelected: (selectedAddress) {
                                        if (mounted) {
                                          setState(() {
                                            _userAddress = selectedAddress;
                                          });
                                        }
                                        _loadData();
                                      },
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _userAddress.isNotEmpty
                                              ? _userAddress
                                              : (_selectedStoreData != null
                                                  ? "${_selectedStoreData!['address'] ?? 'Store Location'}, ${_selectedStoreData!['city'] ?? ''}"
                                                  : "HOME - Sujal Dave, Ratanada, Jodhpur (Raj)"),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.arrow_drop_down, color: Colors.black, size: 20),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: widget.onProfileTap,
                            child: const CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.person,
                                color: Colors.black,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Search Bar Navigation Trigger
                      InkWell(
                        onTap: () => _openSearchScreen(),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 44,
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                            border: Border.all(
                              color: const Color(0XFFC5C5C5),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.search, color: Color(0XFF9C9C9C), size: 22),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Search 'ice-cream' or categories",
                                  style: TextStyle(
                                    color: Color(0XFF9C9C9C),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Icon(Icons.mic, color: Color(0XFF9C9C9C), size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(left: 20, top: 20, bottom: 12),
              child: Text(
                "All Categories",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),

            _categoriesFromApi.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text("No categories found in database"),
                    ),
                  )
                : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: _categoriesFromApi.length,
                        itemBuilder: (context, index) {
                          final item = _categoriesFromApi[index];
                          final String catName = (item["name"] ?? "").toString();
                          final String img = (item["image"] ?? "").toString();
                          final int? catId = item["id"] is int ? item["id"] : int.tryParse(item["id"]?.toString() ?? "");

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryProductsScreen(
                                    categoryName: catName,
                                    categoryImg: img,
                                    categoryId: catId,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Column(
                              children: [
                                Container(
                                  height: 70,
                                  width: 70,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: const Color(0XFFD9EBEB),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: UiHelper.CustomImage(img: img, fit: BoxFit.cover),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  catName,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
