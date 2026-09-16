import 'dart:async';
import 'package:flutter/material.dart';
import 'package:blinkit_series/repository/widgets/animated_cart_button.dart';
import 'package:blinkit_series/repository/widgets/product_detail_dialog.dart';
import 'package:blinkit_series/repository/widgets/uihelper.dart';
import 'package:blinkit_series/repository/widgets/skeleton_loader.dart';
import 'package:blinkit_series/repository/widgets/address_selection_bottom_sheet.dart';
import 'package:blinkit_series/repository/screens/search/searchscreen.dart';
import 'package:blinkit_series/repository/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;

  const HomeScreen({super.key, this.onProfileTap});

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

  Map<String, dynamic>? _selectedStoreData = ApiService.memoryCachedStore;
  String? _userSelectedAddress;
  List<Map<String, dynamic>> _liveProducts = [];
  bool _isLoadingLiveProducts = true;
  double _userWalletBalance = 0.0;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestLocationPermission();
    });
  }

  void _checkAndRequestLocationPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final bool? isGranted = prefs.getBool('location_permission_granted');
    
    // If permission has already been explicitly handled (granted or denied/saved), do not show dialog again
    if (isGranted != null) {
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.location_on, color: Color(0XFFE53935), size: 26),
              SizedBox(width: 10),
              Text(
                "Device Location",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            "SonarbanglaMart needs location access to check service availability and auto-select your nearest dark store for 15-min delivery.",
            style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
          ),
          actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          actions: [
            OutlinedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('location_permission_granted', false);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  AddressSelectionBottomSheet.show(
                    context,
                    onAddressSelected: (selectedAddress) {
                      _fetchLiveBackendData(forceRefresh: true);
                    },
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Deny / Choose", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('location_permission_granted', true);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  final storeData = await ApiService.fetchSelectedStore(lat: 23.4013, lng: 88.5010, forceRefresh: true);
                  if (mounted) {
                    setState(() {
                      _selectedStoreData = storeData;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Location access granted! Connected to ${storeData?['name'] ?? 'Nearest Dark Store'}"),
                        backgroundColor: const Color(0XFF0C831F),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0XFF0C831F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Allow Location", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchLiveBackendData({bool forceRefresh = false}) async {
    // 1. Immediately fetch user wallet balance so top pill updates instantly
    ApiService.fetchUserWallet().then((wallet) {
      if (mounted) {
        setState(() {
          _userWalletBalance = wallet;
        });
      }
    });

    // 2. Read cached store, user address, categories, and products from local storage
    final cachedStore = await ApiService.fetchSelectedStore(forceRefresh: forceRefresh);
    final savedAddress = await ApiService.getUserSelectedAddress();
    final cachedCats = await ApiService.fetchCategories();
    final cachedProds = await ApiService.fetchProducts(storeId: cachedStore?['id'] ?? 1, forceRefresh: false);

    bool hasAnyData = false;
    if (savedAddress != null && mounted) {
      _userSelectedAddress = savedAddress;
    }
    if (cachedStore != null && mounted) {
      _selectedStoreData = cachedStore;
      hasAnyData = true;
      if (cachedStore['search_hint'] != null && cachedStore['search_hint'].toString().isNotEmpty) {
        final List<String> customHints = cachedStore['search_hint'].toString().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        if (customHints.isNotEmpty) {
          _searchHints.clear();
          _searchHints.addAll(customHints);
        }
      }
    }

    if (cachedCats.isNotEmpty && mounted) {
      _populateCategoriesData(cachedCats);
      hasAnyData = true;
    }

    if (cachedProds.isNotEmpty && mounted) {
      _populateProductsData(cachedProds);
      hasAnyData = true;
    }

    // If local cached data exists, dismiss skeleton loader instantly (0s wait!)
    if (mounted) {
      setState(() {
        _isLoadingLiveProducts = !hasAnyData;
      });
    }

    // Precache all product network images in background so subsequent renders are instant
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheImages();
    });

    // 3. Perform silent background version check via /api/v1/sync-check
    _performSmartVersionSync(cachedStore?['id'] ?? 1, forceRefresh);
  }

  Future<void> _performSmartVersionSync(int storeId, bool forceRefresh) async {
    final syncData = await ApiService.checkSyncStatus(storeId: storeId);
    if (syncData != null && syncData['versions'] != null) {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedProdVer = prefs.getString('cache_products_version_v1');
      final String serverProdVer = syncData['versions']['products']?.toString() ?? '';

      // Only perform background fetch if version changed or force refresh is true
      if (forceRefresh || cachedProdVer == null || cachedProdVer != serverProdVer) {
        final freshStore = await ApiService.fetchSelectedStore(forceRefresh: true);
        final freshProds = await ApiService.fetchProducts(storeId: storeId, forceRefresh: true);
        if (mounted) {
          setState(() {
            if (freshStore != null) _selectedStoreData = freshStore;
            if (freshProds.isNotEmpty) _populateProductsData(freshProds);
            _isLoadingLiveProducts = false;
          });
          prefs.setString('cache_products_version_v1', serverProdVer);
        }
      }
    }
  }

  void _precacheImages() {
    if (!mounted) return;
    for (var p in _liveProducts) {
      final img = p['image']?.toString();
      if (img != null && (img.startsWith('http://') || img.startsWith('https://'))) {
        precacheImage(NetworkImage(img), context).catchError((_) {});
      }
    }
  }

  void _populateCategoriesData(List<Map<String, dynamic>> categories) {
    setState(() {
      final List<Map<String, dynamic>> updatedHeaderCats = [
        {"name": "All", "icon": Icons.shopping_bag_outlined}
      ];
      for (var c in categories) {
        final bool showHp = c['show_on_homepage'] == true || c['show_on_homepage'] == 1 || c['show_on_homepage'] == '1';
        if (showHp) {
          updatedHeaderCats.add({
            "name": c['name'].toString(),
            "icon": _getCategoryIconData(c['icon']?.toString()),
          });
        }
      }
      if (updatedHeaderCats.length > 1) {
        _headerCategories.clear();
        _headerCategories.addAll(updatedHeaderCats);
      }
    });
  }

  void _populateProductsData(List<Map<String, dynamic>> prods) {
    setState(() {
      _liveProducts = prods;
      featuredItems.clear();
      groceryKitchenItems.clear();
      for (var p in prods) {
        final double price = double.tryParse(p['effective_price']?.toString() ?? p['price']?.toString() ?? '0') ?? 0.0;
        final double mrp = double.tryParse(p['effective_mrp']?.toString() ?? p['mrp']?.toString() ?? '0') ?? price;
        final String img = p['image'] ?? 'http://images.unsplash.com/photo-1542838132-92c53300491e?w=500&q=80';
        final mapItem = {
          "id": p['id'].toString(),
          "img": img,
          "text": p['name'].toString(),
          "name": p['name'].toString(),
          "unit": p['unit'] ?? '1 pc',
          "price": price,
          "mrp": mrp,
        };
        final isFeatured = p['is_featured'] == 1 || p['is_featured'] == '1' || p['is_featured'] == true || p['is_featured'] == 'true';
        if (isFeatured) {
          featuredItems.add(mapItem);
        }
        groceryKitchenItems.add(mapItem);

        final catName = p['category']?['name']?.toString() ?? p['category_name']?.toString();
        if (catName != null && catName.isNotEmpty) {
          _categoryProducts.putIfAbsent(catName, () => []);
          if (!_categoryProducts[catName]!.any((item) => item['id'] == mapItem['id'])) {
            _categoryProducts[catName]!.add(mapItem);
          }
          for (var key in _categoryProducts.keys) {
            if (catName.toLowerCase().contains(key.toLowerCase()) || key.toLowerCase().contains(catName.toLowerCase())) {
              if (!_categoryProducts[key]!.any((item) => item['id'] == mapItem['id'])) {
                _categoryProducts[key]!.add(mapItem);
              }
            }
          }
        }
      }
      if (featuredItems.isEmpty && groceryKitchenItems.isNotEmpty) {
        featuredItems.addAll(groceryKitchenItems.take(5));
      }
    });
  }

  IconData _getCategoryIconData(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'festival_outlined':
        return Icons.festival_outlined;
      case 'headphones_outlined':
        return Icons.headphones_outlined;
      case 'brush_outlined':
        return Icons.brush_outlined;
      case 'card_giftcard_outlined':
        return Icons.card_giftcard_outlined;
      case 'local_hospital_outlined':
        return Icons.local_hospital_outlined;
      case 'pets_outlined':
        return Icons.pets_outlined;
      case 'toys_outlined':
        return Icons.toys_outlined;
      case 'fastfood_outlined':
        return Icons.fastfood_outlined;
      case 'local_drink_outlined':
        return Icons.local_drink_outlined;
      case 'local_grocery_store_outlined':
        return Icons.local_grocery_store_outlined;
      case 'shopping_bag_outlined':
      default:
        return Icons.shopping_bag_outlined;
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
      body: _isLoadingLiveProducts
          ? SkeletonLoader.homePageFullSkeleton()
          : RefreshIndicator(
              onRefresh: () => _fetchLiveBackendData(forceRefresh: true),
              color: const Color(0XFF0C831F),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            // 1. Fresh Customizable Header Banner
            Container(
              decoration: BoxDecoration(
                color: () {
                  final hexStr = _selectedStoreData?['banner_color']?.toString().replaceAll('#', '');
                  if (hexStr != null && hexStr.length == 6) {
                    return Color(int.parse("0xFF$hexStr"));
                  }
                  return const Color(0XFF0C831F);
                }(),
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
                                      ? ((_selectedStoreData!['is_serviceable'] ?? true)
                                          ? "Delivery in ${_selectedStoreData!['delivery_time_mins'] ?? '15'} mins"
                                          : "🚫 Location Unserviceable")
                                      : "Blinkit in 18 minutes",
                                  style: TextStyle(
                                    color: (_selectedStoreData?['is_serviceable'] ?? true) ? Colors.white70 : const Color(0XFFFFEB3B),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _selectedStoreData != null
                                      ? ((_selectedStoreData!['is_serviceable'] ?? true)
                                          ? "${_selectedStoreData!['name'] ?? 'Dark Store'}"
                                          : "No Store Delivers Here")
                                      : "18 minutes",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
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
                                            _userSelectedAddress = selectedAddress;
                                          });
                                        }
                                        _fetchLiveBackendData(forceRefresh: true);
                                      },
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _userSelectedAddress != null && _userSelectedAddress!.isNotEmpty
                                              ? _userSelectedAddress!
                                              : (_selectedStoreData != null
                                                  ? "${_selectedStoreData!['address'] ?? 'Store Location'}, ${_selectedStoreData!['city'] ?? ''}"
                                                  : "RATANR FLAT, 11E Krishnanagar Main Hub..."),
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
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Wallet Pill & Profile Avatar
                          Row(
                            children: [
                              // Interactive Clickable Wallet Pill with Ripple Effect
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.account_balance_wallet, color: Color(0XFFF7CB45)),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                "Wallet Balance: ₹${_userWalletBalance % 1 == 0 ? _userWalletBalance.toInt() : _userWalletBalance.toStringAsFixed(1)} (Cashback Ready)",
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: const Color(0XFF212121),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(22),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.12),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: const BoxDecoration(
                                            color: Color(0XFFF7CB45),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.account_balance_wallet, color: Color(0XFF0C831F), size: 16),
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0XFF212121),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Text(
                                            "₹${_userWalletBalance % 1 == 0 ? _userWalletBalance.toInt() : _userWalletBalance.toStringAsFixed(1)}",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10),

                              // Interactive Clickable Profile Avatar Button
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    if (widget.onProfileTap != null) {
                                      widget.onProfileTap!();
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Opening Profile & Account Details..."),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0XFF3E1B00),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.person, color: Colors.white, size: 20),
                                  ),
                                ),
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
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => SearchScreen(
                                allProducts: _liveProducts.isNotEmpty ? _liveProducts : groceryKitchenItems,
                                initialQuery: searchController.text,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
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
                                      readOnly: false,
                                      onChanged: (value) {
                                        if (value.isNotEmpty) {
                                          final typedValue = value;
                                          searchController.clear();
                                          final hexStr = _selectedStoreData?['banner_color']?.toString().replaceAll('#', '');
                                          final Color activeTheme = (hexStr != null && hexStr.length == 6)
                                              ? Color(int.parse("0xFF$hexStr"))
                                              : const Color(0XFF0C831F);
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => SearchScreen(
                                                allProducts: _liveProducts.isNotEmpty ? _liveProducts : groceryKitchenItems,
                                                initialQuery: typedValue,
                                                themeColor: activeTheme,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      onTap: () {
                                        final hexStr = _selectedStoreData?['banner_color']?.toString().replaceAll('#', '');
                                        final Color activeTheme = (hexStr != null && hexStr.length == 6)
                                            ? Color(int.parse("0xFF$hexStr"))
                                            : const Color(0XFF0C831F);
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => SearchScreen(
                                              allProducts: _liveProducts.isNotEmpty ? _liveProducts : groceryKitchenItems,
                                              initialQuery: searchController.text,
                                              themeColor: activeTheme,
                                            ),
                                          ),
                                        );
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
                              const IntrinsicHeight(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
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
                    ),

                    if (_selectedStoreData != null && _selectedStoreData!['is_serviceable'] == false) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0XFFE53935), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_off, color: Color(0XFFE53935), size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _selectedStoreData!['closure_reason'] ?? "We currently do not deliver to this location.",
                                  style: const TextStyle(
                                    color: Color(0XFFD32F2F),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

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

              // Mega Sale Custom Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: () {
                  final hexStr = _selectedStoreData?['banner_color']?.toString().replaceAll('#', '');
                  if (hexStr != null && hexStr.length == 6) {
                    return Color(int.parse("0xFF$hexStr"));
                  }
                  return const Color(0XFF0C831F);
                }(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.stars, color: Color(0XFFF7CB45), size: 20),
                        const SizedBox(width: 8),
                        UiHelper.CustomText(
                            text: _selectedStoreData?['banner_title']?.toString().isNotEmpty == true
                                ? _selectedStoreData!['banner_title'].toString()
                                : "Mega Diwali Sale",
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
                            final card = _selectedStoreData?['promo_cards'] != null && (_selectedStoreData!['promo_cards'] as List).length > index
                                ? (_selectedStoreData!['promo_cards'] as List)[index]
                                : megaSaleData[index];

                            final String title = card["text"] ?? card["title"] ?? "";
                            final String img = card["img"] ?? "image 50.png";
                            final String targetType = card["target_type"] ?? "category";
                            final String targetId = card["target_id"]?.toString() ?? "";

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              child: InkWell(
                                onTap: () {
                                  if (targetType == "product") {
                                    final cleanId = targetId.replaceAll('prod_', '');
                                    final matchProd = _liveProducts.firstWhere(
                                      (p) => p['id'] == cleanId,
                                      orElse: () => {
                                        "id": cleanId,
                                        "name": title,
                                        "unit": "1 pc",
                                        "price": 149.0,
                                        "mrp": 199.0,
                                        "img": img,
                                      },
                                    );
                                    ProductDetailDialog.show(context, matchProd);
                                  } else {
                                    final cleanId = targetId.replaceAll('cat_', '');
                                    setState(() {
                                      final foundIndex = _headerCategories.indexWhere((c) => c['name'].toString().toLowerCase().contains(title.toLowerCase()));
                                      if (foundIndex != -1) {
                                        _selectedCategoryIndex = foundIndex;
                                      } else {
                                        _selectedCategoryIndex = (index + 1) % _headerCategories.length;
                                      }
                                    });
                                  }
                                },
                                borderRadius: BorderRadius.circular(10),
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
                                              img: img,
                                              width: 88,
                                              height: 70,
                                              fit: BoxFit.cover),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        title,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          itemCount: (_selectedStoreData?['promo_cards'] as List?)?.length ?? megaSaleData.length,
                          scrollDirection: Axis.horizontal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Featured Products Section
              if (_isLoadingLiveProducts) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
                  child: UiHelper.CustomText(
                      text: "Featured Products",
                      color: Colors.black,
                      fontweight: FontWeight.bold,
                      fontsize: 16,
                      fontfamily: "bold"),
                ),
                SizedBox(
                  height: 195,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    itemBuilder: (context, index) => SkeletonLoader.productCardSkeleton(),
                  ),
                ),
              ] else if (featuredItems.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
                  child: UiHelper.CustomText(
                      text: "Featured Products",
                      color: Colors.black,
                      fontweight: FontWeight.bold,
                      fontsize: 16,
                      fontfamily: "bold"),
                ),
                SizedBox(
                  height: 195,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    itemCount: featuredItems.length,
                    itemBuilder: (context, index) {
                      final item = featuredItems[index];
                      final String title = item["text"].toString();
                      final double price = (item["price"] as num).toDouble();
                      final String img = item["img"].toString();

                      return InkWell(
                        onTap: () => ProductDetailDialog.show(context, item),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 125,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.all(6),
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
                              Container(
                                clipBehavior: Clip.antiAlias,
                                height: 85,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                color: const Color(0XFFF9F9F9),
                              ),
                              child: UiHelper.CustomImage(img: img, fit: BoxFit.cover),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                height: 1.1,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 11, color: Color(0XFF9C9C9C)),
                                const SizedBox(width: 2),
                                UiHelper.CustomText(
                                    text: "16 MINS",
                                    color: const Color(0XFF9C9C9C),
                                    fontweight: FontWeight.normal,
                                    fontsize: 9)
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                UiHelper.CustomText(
                                    text: "₹${price.toStringAsFixed(0)}",
                                    color: Colors.black,
                                    fontweight: FontWeight.bold,
                                    fontsize: 12),
                                AnimatedCartButton(
                                  id: "feat_$index",
                                  name: title.replaceAll('\n', ' '),
                                  img: img,
                                  price: price,
                                  width: 60,
                                  height: 26,
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 15),

              // Dynamic Category Sections (Grocery & Kitchen, Beauty, Electronics, etc.)
              for (var entry in _categoryProducts.entries)
                if (entry.value.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 8),
                    child: UiHelper.CustomText(
                        text: entry.key,
                        color: Colors.black,
                        fontweight: FontWeight.bold,
                        fontsize: 16,
                        fontfamily: "bold"),
                  ),
                  SizedBox(
                    height: 195,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      itemCount: entry.value.length,
                      itemBuilder: (context, index) {
                        final item = entry.value[index];
                        final String title = (item["name"] ?? item["text"]).toString();
                        final double price = (item["price"] as num).toDouble();
                        final String img = item["img"].toString();
                        final String id = item["id"].toString();

                        return InkWell(
                          onTap: () => ProductDetailDialog.show(context, item),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 125,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            padding: const EdgeInsets.all(6),
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
                                Container(
                                  clipBehavior: Clip.antiAlias,
                                  height: 85,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: const Color(0XFFF9F9F9),
                                  ),
                                  child: UiHelper.CustomImage(img: img, fit: BoxFit.cover),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    height: 1.1,
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    const Icon(Icons.timer_outlined, size: 11, color: Color(0XFF9C9C9C)),
                                    const SizedBox(width: 2),
                                    UiHelper.CustomText(
                                        text: "16 MINS",
                                        color: const Color(0XFF9C9C9C),
                                        fontweight: FontWeight.normal,
                                        fontsize: 9)
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    UiHelper.CustomText(
                                        text: "₹${price.toStringAsFixed(0)}",
                                        color: Colors.black,
                                        fontweight: FontWeight.bold,
                                        fontsize: 12),
                                    AnimatedCartButton(
                                      id: "${entry.key}_$id",
                                      name: title.replaceAll('\n', ' '),
                                      img: img,
                                      price: price,
                                      width: 60,
                                      height: 26,
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

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

            // 5. Unserviceable location bottom red warning banner (matching exact user screenshot)
            if (_selectedStoreData != null && (_selectedStoreData!['is_serviceable'] == false || _selectedStoreData!['is_operational'] == false)) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                color: const Color(0XFFE53935),
                child: Text(
                  _selectedStoreData!['closure_reason']?.toString() ??
                      "We are currently not available at your location. Distance to nearest store is 44.7 km (Coverage limit: 5.00 km).",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }
}
