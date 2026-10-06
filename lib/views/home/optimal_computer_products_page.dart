import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vector_academy/services/api/optimal_computer_products.dart';
import 'package:vector_academy/utils/navigation_utils.dart';

class OptimalComputerProductsPage extends StatefulWidget {
  const OptimalComputerProductsPage({super.key});

  @override
  State<OptimalComputerProductsPage> createState() =>
      _OptimalComputerProductsPageState();
}

class _OptimalComputerProductsPageState
    extends State<OptimalComputerProductsPage> {
  final OptimalComputerProductsApi _api = OptimalComputerProductsApi();
  bool _loading = true;
  List<OptimalComputerProduct> _products = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final products = await _api.fetchList();
      if (!mounted) return;
      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _products = [];
        _loading = false;
      });
    }
  }

  Future<void> _downloadApp() async {
    final uri = Uri.parse(optimalComputerStoreUrl());
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openTelegram() async {
    final uri = Uri.parse('https://t.me/Optimal_computer');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Optimal Computer',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => safePop(context: context),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'እንደዚህ አይነት መሠል ላፕቶፓችን እና ታብሌቶችን በቅናሽ እና በተመጣጣኝ ዋጋ ፤ ሂሳብ ቀድመው ሳይከፍሉ ካሉበት እናደርሳለን ። አይተው ካልወደዱት ይመልሱታል ። አሁኑኑ ተቀላቀሉ !!!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _downloadApp,
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Download app'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openTelegram,
                      icon: const Icon(Icons.telegram),
                      label: const Text('Telegram'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No products to show yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemCount: _products.length,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _ProductListTile(product: _products[index]);
              },
            ),
    );
  }
}

class _ProductListTile extends StatelessWidget {
  const _ProductListTile({required this.product});

  final OptimalComputerProduct product;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl;
    final price = formatOptimalComputerPrice(product.price);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 72,
                height: 72,
                child: imageUrl == null
                    ? const ColoredBox(
                        color: Color(0xFFF1F5F9),
                        child: Icon(
                          Icons.devices_outlined,
                          color: Color(0xFF64748B),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => const ColoredBox(
                          color: Color(0xFFF1F5F9),
                          child: Icon(
                            Icons.devices_outlined,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  if (price.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
