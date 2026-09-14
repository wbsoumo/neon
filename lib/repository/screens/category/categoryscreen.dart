import 'package:flutter/material.dart';
import 'package:blinkit_series/repository/screens/category/category_products_screen.dart';
import 'package:blinkit_series/repository/services/api_service.dart';
import 'package:blinkit_series/repository/widgets/uihelper.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> _liveCategories = [];
  bool _isLoading = false;

  final List<Map<String, String>> grocerykitchen = [
    {"img": "image 41.png", "text": "Vegetables & \nFruits"},
    {"img": "image 42.png", "text": "Atta, Dal & \nRice"},
    {"img": "image 43.png", "text": "Oil, Ghee & \nMasala"},
    {"img": "image 44 (1).png", "text": "Dairy, Bread & \nMilk"},
    {"img": "image 45 (1).png", "text": "Biscuits & \nBakery"}
  ];

  final List<Map<String, String>> secondgrocery = [
    {"img": "image 21.png", "text": "Dry Fruits &\n Cereals"},
    {"img": "image 22.png", "text": "Kitchen &\n Appliances"},
    {"img": "image 23.png", "text": "Tea & \nCoffees"},
    {"img": "image 24.png", "text": "Ice Creams & \nmuch more"},
    {"img": "image 25.png", "text": "Noodles & \nPacket Food"}
  ];

  final List<Map<String, String>> snacksanddrinks = [
    {"img": "image 31.png", "text": "Chips &\n Namkeens"},
    {"img": "image 32.png", "text": "Sweets & \nChocalates"},
    {"img": "image 33.png", "text": "Drinks & \nJuices"},
    {"img": "image 34.png", "text": "Sauces &\n Spreads"},
    {"img": "image 35.png", "text": "Beauty &\n Cosmetics"}
  ];

  final List<Map<String, String>> hosuehold = [
    {"img": "image 36.png", "text": "Cleaners & \nDetergents"},
    {"img": "image 37.png", "text": "Dishwashers & \nSoaps"},
    {"img": "image 38.png", "text": "Tissues & \nDisposables"},
    {"img": "image 39.png", "text": "Air Fresheners"},
    {"img": "image 40.png", "text": "Repellents"}
  ];

  @override
  void initState() {
    super.initState();
    _loadLiveCategories();
  }

  Future<void> _loadLiveCategories() async {
    setState(() => _isLoading = true);
    final cats = await ApiService.fetchCategories();
    if (mounted) {
      setState(() {
        _liveCategories = cats;
        _isLoading = false;
      });
    }
  }

  Widget _buildCategorySection(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 16),
          child: UiHelper.CustomText(
            text: title,
            color: Colors.black,
            fontweight: FontWeight.bold,
            fontsize: 15,
            fontfamily: "bold",
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 125,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 20),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final String catName = (item["name"] ?? item["text"] ?? "").toString();
              final String img = (item["image"] ?? item["img"] ?? "image 41.png").toString();
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
                child: Container(
                  width: 82,
                  margin: const EdgeInsets.only(right: 14),
                  child: Column(
                    children: [
                      Container(
                        height: 75,
                        width: 75,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0XFFD9EBEB),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
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
                        catName.replaceAll('\n', ' '),
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
                ),
              );
            },
          ),
        ),
      ],
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
            // Top Location & Search Header
            Stack(
              children: [
                Container(
                  height: 190,
                  width: double.infinity,
                  color: const Color(0XFFF7CB45),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          const SizedBox(width: 20),
                          UiHelper.CustomText(
                              text: "Blinkit in",
                              color: const Color(0XFF000000),
                              fontweight: FontWeight.bold,
                              fontsize: 15,
                              fontfamily: "bold"),
                        ],
                      ),
                      Row(
                        children: [
                          const SizedBox(width: 20),
                          UiHelper.CustomText(
                              text: "16 minutes",
                              color: const Color(0XFF000000),
                              fontweight: FontWeight.bold,
                              fontsize: 20,
                              fontfamily: "bold")
                        ],
                      ),
                      Row(
                        children: [
                          const SizedBox(width: 20),
                          Expanded(
                            child: UiHelper.CustomText(
                                text: "HOME - Sujal Dave, Ratanada, Jodhpur (Raj)",
                                color: const Color(0XFF000000),
                                fontweight: FontWeight.bold,
                                fontsize: 14),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 20,
                  top: 40,
                  child: const CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: UiHelper.CustomTextField(controller: searchController),
                )
              ],
            ),

            if (_liveCategories.isNotEmpty)
              _buildCategorySection(context, "Featured Web Categories", _liveCategories),

            _buildCategorySection(context, "Grocery & Kitchen", grocerykitchen.map((e) => Map<String, dynamic>.from(e)).toList()),
            _buildCategorySection(context, "Pantry Staples", secondgrocery.map((e) => Map<String, dynamic>.from(e)).toList()),
            _buildCategorySection(context, "Snacks & Drinks", snacksanddrinks.map((e) => Map<String, dynamic>.from(e)).toList()),
            _buildCategorySection(context, "Household Essentials", hosuehold.map((e) => Map<String, dynamic>.from(e)).toList()),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

