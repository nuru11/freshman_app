import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/services/api/optimal_computer_products.dart';
import 'package:vector_academy/views/home/optimal_computer_products_page.dart';

class OptimalComputerProductsController extends GetxController {
  final OptimalComputerProductsApi _api = OptimalComputerProductsApi();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<OptimalComputerProduct> _slides = [];
  List<OptimalComputerProduct> get slides => _slides;

  @override
  void onInit() {
    super.onInit();
    loadSlides();
  }

  Future<void> loadSlides() async {
    if (_slides.isEmpty) {
      _isLoading = true;
      update();
    }
    try {
      _slides = await _api.fetchSlides();
    } catch (_) {
      if (_slides.isEmpty) {
        _slides = [];
      }
    } finally {
      _isLoading = false;
      update();
    }
  }
}

class OptimalComputerProductsBar extends StatelessWidget {
  const OptimalComputerProductsBar({super.key});

  void _openList() {
    Get.to(() => const OptimalComputerProductsPage());
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OptimalComputerProductsController>(
      builder: (controller) {
        final slides = controller.slides;
        if (controller.isLoading && slides.isEmpty) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: SizedBox(
              height: 72,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }
        if (slides.isEmpty) {
          return const SizedBox.shrink();
        }

        final cardSize = _cardSize(context);
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFCBD5E1).withValues(alpha: 0.9),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.storefront_outlined,
                    size: 18,
                    color: Color(0xFF334155),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Optimal Computer',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: cardSize.height,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: slides.length,
                  separatorBuilder: (_, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: cardSize.width,
                      height: cardSize.height,
                      child: _ProductSlideCard(
                        product: slides[index],
                        onTap: _openList,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  ({double width, double height}) _cardSize(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;
    final isTablet = screenWidth >= 768;
    final width = (screenWidth * (isCompact ? 0.34 : 0.30))
        .clamp(128.0, isTablet ? 168.0 : 152.0)
        .toDouble();
    return (width: width, height: width / 0.86);
  }
}

class _ProductSlideCard extends StatelessWidget {
  const _ProductSlideCard({required this.product, required this.onTap});

  final OptimalComputerProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl;
    final price = formatOptimalComputerPrice(product.price);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl == null
                        ? const ColoredBox(
                            color: Color(0xFFF1F5F9),
                            child: Center(
                              child: Icon(
                                Icons.devices_outlined,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorWidget: (context, url, error) => const ColoredBox(
                              color: Color(0xFFF1F5F9),
                              child: Center(
                                child: Icon(
                                  Icons.devices_outlined,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                if (price.isNotEmpty)
                  Text(
                    price,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
