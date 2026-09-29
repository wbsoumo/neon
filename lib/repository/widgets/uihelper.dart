import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:blinkit_series/repository/widgets/skeleton_loader.dart';

class UiHelper {
  static Widget CustomImage({required String img, double? width, double? height, BoxFit fit = BoxFit.contain}) {
    String cleanUrl = img.trim();

    Widget buildFallback() {
      return Image.asset(
        'assets/images/no_product.png',
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (ctx, err, st) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0XFFF2F4F7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.image_not_supported_outlined, color: Color(0XFF0C831F), size: 24),
          ),
        ),
      );
    }

    if (cleanUrl.isEmpty) {
      return buildFallback();
    }

    // Fix: Handle relative server upload paths (with or without leading slash)
    if (cleanUrl.startsWith('uploads/') || cleanUrl.startsWith('/uploads/')) {
      final path = cleanUrl.startsWith('/') ? cleanUrl : '/$cleanUrl';
      cleanUrl = 'https://admin.sbmartquick.com$path';
    }

    // Handle Network Images (HTTP / HTTPS)
    if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
      if (cleanUrl.contains(' ')) {
        cleanUrl = Uri.encodeFull(cleanUrl);
      }
      return CachedNetworkImage(
        imageUrl: cleanUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => SkeletonLoader(
          width: width ?? double.infinity,
          height: height ?? double.infinity,
          borderRadius: 8,
        ),
        errorWidget: (context, url, error) => buildFallback(),
      );
    }

    // Fallback mapping for asset-only category references
    if (cleanUrl.contains('01_vegetables') || cleanUrl.contains('02_dairy') || cleanUrl.contains('03_snacks') || cleanUrl.contains('04_personal') || cleanUrl.contains('05_home') || cleanUrl.contains('06_atta') || cleanUrl.contains('07_oil') || cleanUrl.contains('08_instant') || cleanUrl.contains('09_beverages') || cleanUrl.contains('10_baby') || cleanUrl.contains('11_pet') || cleanUrl.contains('12_frozen') || cleanUrl.contains('13_bakery') || cleanUrl.contains('14_fresh') || cleanUrl.contains('15_kitchen') || cleanUrl.contains('16_organic')) {
      final String fileName = cleanUrl.replaceAll('https://sbmartquick.com/uploads/categories/', '').replaceAll('http://sbmartquick.com/uploads/categories/', '').replaceAll('https://taskbazi.site/uploads/categories/', '').replaceAll('http://taskbazi.site/uploads/categories/', '').replaceAll('/uploads/categories/', '').replaceAll('uploads/categories/', '').split('?').first.trim();
      final String cleanPath = fileName.startsWith('assets/images/') ? fileName : "assets/images/$fileName";
      return Image.asset(
        cleanPath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (ctx, err, st) => buildFallback(),
      );
    }

    String cleanPath = cleanUrl.startsWith('assets/images/') ? cleanUrl : "assets/images/$cleanUrl";

    return Image.asset(
      cleanPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => buildFallback(),
    );
  }

  static CustomText(
      {required String text,
      required Color color,
      required FontWeight fontweight,
      String? fontfamily,
      required double fontsize}) {
    return Text(
      text,
      style: TextStyle(
          fontSize: fontsize,
          fontFamily: fontfamily ?? "regular",
          fontWeight: fontweight,
          color: color),
    );
  }
  static CustomTextField({required TextEditingController controller}){
    return Container(
      height: 40,
      width: 360,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        border: Border.all(
          color: Color(0XFFC5C5C5)
        )
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: "Search 'ice-cream'",
          prefixIcon: const Icon(Icons.search, color: Color(0XFF9C9C9C)),
          suffixIcon: const Icon(Icons.mic, color: Color(0XFF9C9C9C)),
          border: InputBorder.none
        ),
      ),
    );
  }

  static CustomButton(VoidCallback callback){
    return Container(
      height: 18,
      width: 30,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Color(0XFF27AF34)
        ),
        borderRadius: BorderRadius.circular(4)
      ),
      child: Center(child: Text("Add",style: TextStyle(fontSize: 8,color: Color(0XFF27AF34)),),),
    );
  }
}
