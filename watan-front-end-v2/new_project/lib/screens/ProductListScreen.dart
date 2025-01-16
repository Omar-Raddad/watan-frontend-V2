import 'package:flutter/material.dart';
import 'package:new_project/models/sponserShip_model.dart';
import 'package:new_project/screens/AddProductScreen.dart';
import 'package:new_project/screens/ProductDetailsScreen.dart';
import 'package:new_project/screens/myProduct_screen.dart';
import '../services/productService.dart';
import '../models/product_model.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

// Simple class to store filter options
class _FilterOptions {
  String? category; // Category ID or name
  String? search; // Search text
  double? minPrice; // Minimum price
  double? maxPrice; // Maximum price
  bool? occasion; // True/False
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService productService =
      ProductService(baseUrl: 'http://172.16.0.68:5000');

  List<Product> products = [];
  bool isLoading = true;

  // Current filters
  _FilterOptions filters = _FilterOptions();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts({
    _FilterOptions? filterOpts,
    String? userId,
  }) async {
    setState(() => isLoading = true);

    try {
      final data = await productService.fetchProducts(
        category: filterOpts?.category,
        search: filterOpts?.search,
        minPrice: filterOpts?.minPrice,
        maxPrice: filterOpts?.maxPrice,
        user: userId,
      );

      // Sort sponsored products first
      List<Product> sortedProducts =
          data.map((item) => Product.fromJson(item)).toList()
            ..sort((a, b) {
              if (a.isSponsored && !b.isSponsored) {
                return -1; // Sponsored products come first
              } else if (!a.isSponsored && b.isSponsored) {
                return 1; // Non-sponsored products come later
              }
              return 0;
            });

      // Limit to max 10 products
      setState(() {
        products = sortedProducts.take(50).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load products: $e')),
      );
    }
  }

  void _showFilterSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterBottomSheet(
        initialFilters: filters,
        onApply: (newFilters) {
          setState(() => filters = newFilters);
          Navigator.pop(context); // Close the bottom sheet
          _fetchProducts(filterOpts: newFilters);
        },
      ),
    );
  }

  String _getImageUrl(String imagePath) {
    const String baseUrl = "http://172.16.0.68:5000";
    return "$baseUrl$imagePath";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// Instead of using `actions: []`, we place everything inside the title
      /// so we have full control over layout.
      appBar: AppBar(
        backgroundColor: Colors.green.shade600,
        elevation: 2,
        title: Row(
          children: [
            const Text(
              'Discover Products',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            // My Products icon
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.person, color: Colors.white),
                tooltip: 'My Products',
                splashRadius: 24,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MyProductsScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            // Filter icon
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.white),
                tooltip: 'Filter',
                splashRadius: 24,
                onPressed: _showFilterSheet,
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green.shade600,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final productAdded = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddProductScreen(),
            ),
          );
          if (productAdded == true) {
            _fetchProducts(); // Reload after adding a product
          }
        },
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.shade100,
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(12.0),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _buildProductCard(product);
                },
              ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(product: product),
            ),
          );
        },
        child: Stack(
          children: [
            Row(
              children: [
                if (product.images.isNotEmpty)
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Image.network(
                      _getImageUrl(product.images.first),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: Icon(Icons.broken_image,
                              color: Colors.grey, size: 50),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _buildProductDetails(product),
                  ),
                ),
              ],
            ),
            // Badge for sponsored products
            if (product.isSponsored)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Sponsored',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetails(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          product.price != null
              ? '\$${product.price!.toStringAsFixed(2)}'
              : 'Price: Not Available',
          style: TextStyle(
            color: Colors.green.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          product.categoryName,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final _FilterOptions initialFilters;
  final ValueChanged<_FilterOptions> onApply;

  const _FilterBottomSheet({
    Key? key,
    required this.initialFilters,
    required this.onApply,
  }) : super(key: key);

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late TextEditingController _searchController;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  String? _category;
  bool? _occasion;

  List<dynamic> categories = [];
  bool isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: widget.initialFilters.search);
    _minPriceController = TextEditingController(
        text: widget.initialFilters.minPrice?.toString() ?? '');
    _maxPriceController = TextEditingController(
        text: widget.initialFilters.maxPrice?.toString() ?? '');
    _occasion = widget.initialFilters.occasion;
    _category = widget.initialFilters.category;

    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final productService = ProductService(baseUrl: 'http://172.16.0.68:5000');
      final data = await productService.fetchCategories();
      if (mounted) {
        setState(() {
          categories = data;
          isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingCategories = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: $e')),
        );
      }
    }
  }

  Widget _buildCategoryDropdown() {
    if (isLoadingCategories) {
      return DropdownButtonFormField<String>(
        value: null,
        onChanged: null,
        decoration: InputDecoration(
          labelText: 'Category',
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.category, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        items: const [
          DropdownMenuItem<String>(
            value: null,
            child: Text('Loading...'),
          ),
        ],
      );
    }

    return DropdownButtonFormField<String>(
      value: _category,
      onChanged: (val) => setState(() => _category = val),
      decoration: InputDecoration(
        labelText: 'Category',
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.category, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      items: categories.map((category) {
        return DropdownMenuItem<String>(
          value: category['_id'],
          child: Text(category['name']),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const Text(
                'Filter Products',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _searchController,
                labelText: 'Search',
                icon: Icons.search,
              ),
              const SizedBox(height: 12),
              _buildCategoryDropdown(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _minPriceController,
                      labelText: 'Min Price',
                      icon: Icons.attach_money,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _maxPriceController,
                      labelText: 'Max Price',
                      icon: Icons.money_off,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _occasion ?? false,
                    onChanged: (val) => setState(() => _occasion = val),
                  ),
                  const Text(
                    'Occasion Only',
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _applyFilters,
                icon: const Icon(Icons.filter_list),
                label: const Text('Apply Filters'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    String? labelText,
    IconData? icon,
    Function(String)? onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  void _applyFilters() {
    final newFilters = _FilterOptions()
      ..search = _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim()
      ..category =
          (_category?.trim().isNotEmpty ?? false) ? _category!.trim() : null
      ..minPrice = _minPriceController.text.isNotEmpty
          ? double.tryParse(_minPriceController.text)
          : null
      ..maxPrice = _maxPriceController.text.isNotEmpty
          ? double.tryParse(_maxPriceController.text)
          : null
      ..occasion = (_occasion == true) ? true : null;

    widget.onApply(newFilters);
  }
}
