import 'package:flutter/material.dart';
import 'package:new_project/models/sponserShip_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../services/productService.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({Key? key}) : super(key: key);

  @override
  _MyProductsScreenState createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  final ProductService productService =
      ProductService(baseUrl: 'http://172.16.0.68:5000');

  List<Product> myProducts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyProducts();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null) {
      throw Exception('Authentication token not found');
    }
    return token;
  }

  Future<void> _fetchMyProducts() async {
    setState(() => isLoading = true);

    try {
      final token = await _getToken();
      // Replace with actual token retrieval
      final data = await productService.fetchMyProducts(token);
      setState(() {
        myProducts = data.map((item) => Product.fromJson(item)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load your products: $e')),
      );
    }
  }

  String _getImageUrl(String imagePath) {
    const String baseUrl = "http://172.16.0.68:5000"; // Your backend URL
    return "$baseUrl$imagePath";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products'),
        backgroundColor: Colors.green.shade600,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: myProducts.length,
              itemBuilder: (context, index) {
                final product = myProducts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: product.images.isNotEmpty
                        ? Image.network(
                            _getImageUrl(product.images.first),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.image_not_supported),
                    title: Text(product.name),
                    subtitle: Text(product.categoryName),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Add Sponsorship',
                      onPressed: () async {
                        final token =
                            await _getToken(); // Ensure token is fetched
                        final result = await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (_) => SponsorshipModal(
                            productId: product.id,
                            token: token!,
                          ),
                        );

                        if (result == true) {
                          _fetchMyProducts(); // Refresh products after sponsorship
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
