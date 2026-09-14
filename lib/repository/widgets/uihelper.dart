import 'package:flutter/material.dart';

class UiHelper {
  static Widget CustomImage({required String img, double? width, double? height, BoxFit fit = BoxFit.contain}) {
    String cleanUrl = img.trim();

    // Map common asset names from database to high-quality reliable CDN URLs for mobile devices
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      final String baseName = cleanUrl.replaceAll('assets/images/', '').split('?').first.trim();
      switch (baseName) {
        case 'image 54.png':
        case 'image 63.png':
        case 'image 50.png':
          cleanUrl = 'https://images.unsplash.com/photo-1602874801007-bd458bb1b8b6?w=500&q=80';
          break;
        case 'image 57.png':
          cleanUrl = 'https://images.unsplash.com/photo-1599785209707-a456fc1337cc?w=500&q=80';
          break;
        case 'image 41.png':
          cleanUrl = 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=500&q=80';
          break;
        case 'image 42.png':
          cleanUrl = 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=500&q=80';
          break;
        case 'image 43.png':
          cleanUrl = 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=500&q=80';
          break;
        case 'image 44 (1).png':
        case 'image 44.png':
          cleanUrl = 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=500&q=80';
          break;
        case 'image 45 (1).png':
        case 'image 45.png':
          cleanUrl = 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=500&q=80';
          break;
        case 'image 51.png':
          cleanUrl = 'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=500&q=80';
          break;
        case 'image 52.png':
          cleanUrl = 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500&q=80';
          break;
        case 'image 53.png':
          cleanUrl = 'https://images.unsplash.com/photo-1583847268964-b28dc8f51f92?w=500&q=80';
          break;
        case 'image 35.png':
          cleanUrl = 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?w=500&q=80';
          break;
      }
    }

    if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
      return Image.network(
        cleanUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to local asset if network fails on mobile device
          String fallbackAsset = "assets/images/image 41.png";
          return Image.asset(
            fallbackAsset,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (ctx, err, st) => Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.shopping_bag_outlined, color: Color(0XFF0C831F), size: 24),
              ),
            ),
          );
        },
      );
    }

    String cleanPath = cleanUrl.startsWith('assets/images/') ? cleanUrl : "assets/images/$cleanUrl";

    return Image.asset(
      cleanPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.fastfood, color: Color(0XFF0C831F), size: 24),
          ),
        );
      },
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
