import 'package:flutter/material.dart';
import '../services/inventory_service.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final InventoryService _inventoryService = InventoryService();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final productsData = await _inventoryService.getProducts();
      setState(() {
        _products = productsData.map((json) => Product.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Product> get _filteredProducts {
    if (_selectedCategory == 'all') return _products;
    return _products.where((p) => p.category == _selectedCategory).toList();
  }

  Set<String> get _categories {
    final cats = _products.map((p) => p.category).toSet();
    return {'all', ...cats};
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [AppTheme.charcoal, AppTheme.charcoalDeep]
                    : [AppTheme.pearlBg, AppTheme.roseGoldLight],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, isDark),
                if (!_isLoading && _error == null) _buildCategoryFilter(isDark),
                Expanded(
                  child: _buildBody(isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : AppTheme.charcoal),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Text(
            'Beauty Products',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.charcoal,
            ),
          ),
          const Spacer(),
          Icon(Icons.shopping_bag, color: AppTheme.gold, size: 28),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(bool isDark) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories.elementAt(index);
          final isSelected = category == _selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedCategory = category),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.gold
                      : (isDark ? AppTheme.charcoalMuted.withOpacity(0.5) : Colors.white.withOpacity(0.7)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.gold : AppTheme.gold.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  category == 'all' ? 'All' : category.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white : AppTheme.charcoal),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.gold),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Failed to load products',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: AppTheme.gold.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No products available',
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: AppTheme.gold,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          return _buildProductCard(_filteredProducts[index], isDark);
        },
      ),
    );
  }

  Widget _buildProductCard(Product product, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.charcoalMuted.withOpacity(0.5)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.gold.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showProductDetails(product),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product icon/image placeholder
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.shopping_bag,
                      size: 40,
                      color: AppTheme.gold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Product name
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.charcoal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // SKU
                Text(
                  'SKU: ${product.sku}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.black45,
                  ),
                ),
                const Spacer(),

                // Stock status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStockColor(product).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    product.stockStatus,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStockColor(product),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.formattedPrice,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.gold,
                      ),
                    ),
                    Icon(Icons.arrow_forward, size: 16, color: AppTheme.gold),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStockColor(Product product) {
    if (product.quantity == 0) return Colors.red;
    if (product.isLowStock) return Colors.orange;
    return Colors.green;
  }

  void _showProductDetails(Product product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.charcoalMuted : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'SKU: ${product.sku}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              if (product.description != null) ...[
                const SizedBox(height: 16),
                Text(
                  product.description!,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _buildDetailRow('Category', product.category.replaceAll('_', ' ').toUpperCase(), isDark),
              _buildDetailRow('Price', product.formattedPrice, isDark),
              _buildDetailRow('Stock', '${product.quantity} units', isDark),
              _buildDetailRow('Status', product.stockStatus, isDark),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: product.quantity > 0 ? () => _addToCart(product) : null,
                  icon: const Icon(Icons.shopping_cart),
                  label: Text(product.quantity > 0 ? 'Add to Cart' : 'Out of Stock'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.charcoal,
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(Product product) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart!'),
        backgroundColor: AppTheme.gold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
