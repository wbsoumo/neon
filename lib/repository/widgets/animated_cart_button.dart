import 'package:flutter/material.dart';
import 'package:blinkit_series/domain/cart/cart_controller.dart';

class AnimatedCartButton extends StatefulWidget {
  final String id;
  final String name;
  final String img;
  final double price;
  final String unit;
  final int? categoryId;
  final double width;
  final double height;

  const AnimatedCartButton({
    super.key,
    required this.id,
    required this.name,
    required this.img,
    required this.price,
    this.unit = "1 unit",
    this.categoryId,
    this.width = 72,
    this.height = 32,
  });

  @override
  State<AnimatedCartButton> createState() => _AnimatedCartButtonState();
}

class _AnimatedCartButtonState extends State<AnimatedCartButton> {
  final CartController _cart = CartController.instance;

  @override
  void initState() {
    super.initState();
    _cart.addListener(_update);
  }

  @override
  void dispose() {
    _cart.removeListener(_update);
    super.dispose();
  }

  void _update() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final int qty = _cart.getItemQuantity(widget.id);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: widget.height,
      width: qty > 0 ? (widget.width < 80 ? 82 : widget.width) : widget.width,
      decoration: BoxDecoration(
        color: qty > 0 ? const Color(0XFF0C831F) : const Color(0XFFF7FFF9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0XFF0C831F),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0XFF0C831F).withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: qty == 0
            ? TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 180),
                tween: Tween(begin: 1.0, end: 1.0),
                key: ValueKey("add_btn_$qty"),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: InkWell(
                  key: const ValueKey("add_btn"),
                  onTap: () {
                    _cart.addItem(
                      id: widget.id,
                      name: widget.name,
                      img: widget.img,
                      price: widget.price,
                      unit: widget.unit,
                      categoryId: widget.categoryId,
                    );
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "${widget.name} added to cart",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0XFF0C831F),
                        duration: const Duration(milliseconds: 1400),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.all(12),
                      ),
                    );
                  },
                borderRadius: BorderRadius.circular(8),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            "ADD",
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0XFF0C831F),
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.add,
                            size: 14,
                            color: Color(0XFF0C831F),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ),
                ),
              )
            : Row(
                key: const ValueKey("counter_btn"),
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      _cart.removeSingleQuantity(widget.id);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                      child: Icon(
                        Icons.remove,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    "$qty",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _cart.addItem(
                        id: widget.id,
                        name: widget.name,
                        img: widget.img,
                        price: widget.price,
                        unit: widget.unit,
                        categoryId: widget.categoryId,
                      );
                    },
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                      child: Icon(
                        Icons.add,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
