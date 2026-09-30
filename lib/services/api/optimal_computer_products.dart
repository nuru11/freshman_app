import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class OptimalComputerProduct {
  const OptimalComputerProduct({
    required this.id,
    required this.name,
    this.imageUrl,
    this.price,
  });

  final String id;
  final String name;
  final String? imageUrl;
  final double? price;

  factory OptimalComputerProduct.fromJson(Map<String, dynamic> json) {
    final priceValue = json['displayPrice'];
    double? price;
    if (priceValue is num) {
      price = priceValue.toDouble();
    } else if (priceValue is String) {
      price = double.tryParse(priceValue);
    }

    final image = json['displayImage'];
    return OptimalComputerProduct(
      id: json['id']?.toString() ?? '',
      name: json['productName']?.toString() ?? 'Product',
      imageUrl: image is String && image.trim().isNotEmpty
          ? resolveOptimalComputerImageUrl(image)
          : null,
      price: price,
    );
  }
}

const optimalComputerApiBase = 'https://optimalcomputerapi.entrancetricks.com/api';
const optimalComputerOrigin = 'https://optimalcomputerapi.entrancetricks.com';
const optimalComputerPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.optimalcomputer.app';
const optimalComputerAppStoreUrl =
    'https://apps.apple.com/us/app/optimal-computer/id6808658675';

String optimalComputerStoreUrl() {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return optimalComputerAppStoreUrl;
  }
  return optimalComputerPlayStoreUrl;
}

String resolveOptimalComputerImageUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  if (trimmed.startsWith('/')) {
    return '$optimalComputerOrigin$trimmed';
  }
  return '$optimalComputerOrigin/$trimmed';
}

String formatOptimalComputerPrice(double? price) {
  if (price == null) return '';
  if (price == price.roundToDouble()) {
    return 'ETB ${price.toStringAsFixed(0)}';
  }
  return 'ETB ${price.toStringAsFixed(2)}';
}

class OptimalComputerProductsApi {
  OptimalComputerProductsApi({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: optimalComputerApiBase,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
            ),
          );

  final Dio _dio;

  Future<List<OptimalComputerProduct>> fetchSlides() {
    return _fetch(showOnAppSlide: true);
  }

  Future<List<OptimalComputerProduct>> fetchList() {
    return _fetch(showOnAppList: true);
  }

  Future<List<OptimalComputerProduct>> _fetch({
    bool showOnAppSlide = false,
    bool showOnAppList = false,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/products',
      queryParameters: {
        'activeOnly': 'true',
        if (showOnAppSlide) 'showOnAppSlide': 'true',
        if (showOnAppList) 'showOnAppList': 'true',
      },
    );
    final data = response.data;
    final raw = data?['products'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (item) => OptimalComputerProduct.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((product) => product.id.isNotEmpty)
        .toList();
  }
}
