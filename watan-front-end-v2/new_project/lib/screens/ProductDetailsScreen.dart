import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../services/message_service.dart';
import '../services/notification_service.dart';
import './conversation_screen.dart'; // Replace with your actual conversation screen import

class ProductDetailsScreen extends StatelessWidget {
  final Product product;

  const ProductDetailsScreen({Key? key, required this.product})
      : super(key: key);

  String _getImageUrl(String imagePath) {
    const String baseUrl = "http://172.16.0.68:5000";
    return "$baseUrl$imagePath";
  }

  Future<void> _handleBuyNow(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username =
          prefs.getString('username'); // Get the logged-in username
      final messageService = MessageService(baseUrl: 'http://172.16.0.68:5000');
      final notificationService = NotificationService();

      if (username == null) {
        throw Exception("User is not logged in.");
      }

      // Send a message to the product owner
      final content =
          "$username is interested in purchasing '${product.name}' for \$${product.price?.toStringAsFixed(2) ?? 'N/A'}.";
      await messageService.startConversation(product.ownerId, content);

      // Send a purchase notification to the product owner
      await notificationService.sendPurchaseNotification(
        product.ownerId,
        username,
        product.name,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase notification and message sent to the owner!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to the conversation screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ConversationsScreen(), // Replace with your actual parameters for the conversation screen
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to process Buy Now: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          // Background with Gradient Overlay
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Images
                if (product.images.isNotEmpty)
                  SizedBox(
                    height: 300,
                    child: PageView.builder(
                      itemCount: product.images.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: Image.network(
                              _getImageUrl(product.images[index]),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: Colors.grey.shade300,
                                child: const Center(
                                    child: Icon(Icons.broken_image,
                                        color: Colors.grey, size: 50)),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                // Product Name
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                // Product Price
                Text(
                  product.price != null
                      ? '\$${product.price!.toStringAsFixed(2)}'
                      : 'Price: Not Available',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                // Product Category
                Text(
                  'Category: ${product.categoryName}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                // Product Description
                const Text(
                  'Description',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                // Call-to-Action Button
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      _handleBuyNow(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      'Buy Now',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
