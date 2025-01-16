import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ProductService {
  final String baseUrl;

  ProductService({required this.baseUrl});

  Future<List<dynamic>> fetchProducts({
    String? category,
    String? search,
    double? minPrice,
    double? maxPrice,
    String? user, // New user filter
  }) async {
    final queryParameters = {
      if (category != null) 'category': category,
      if (search != null) 'search': search,
      if (minPrice != null) 'minPrice': minPrice.toString(),
      if (maxPrice != null) 'maxPrice': maxPrice.toString(),
      if (user != null) 'user': user, // Add user filter
    };

    final uri = Uri.parse('$baseUrl/api/products')
        .replace(queryParameters: queryParameters);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch products');
    }
  }

  Future<List<dynamic>> fetchMyProducts(String? token) async {
    final uri = Uri.parse('$baseUrl/api/products/user-products');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch user products');
    }
  }

  /// Add sponsorship to a product
  /// Add sponsorship to a product
  Future<void> addSponsorship({
    required String productId,
    required double amountPaid,
    List<String>? targetLocations,
    required bool nationwide,
    required String token,
  }) async {
    final uri = Uri.parse('$baseUrl/api/products/add-sponsorship');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'productId': productId,
        'amountPaid': amountPaid,
        'targetLocations': targetLocations,
        'nationwide': nationwide,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add sponsorship: ${response.body}');
    }
  }

  Future<List<dynamic>> fetchCategories() async {
    final uri = Uri.parse('$baseUrl/api/categories');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch categories');
    }
  }

  Future<dynamic> addCategory(String name, String token) async {
    final uri = Uri.parse('$baseUrl/api/categories');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'name': name}),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body); // Return the created category
    } else {
      throw Exception('Failed to add category: ${response.body}');
    }
  }

  /// Get a specific product by ID
  Future<dynamic> fetchProductById(String productId) async {
    final uri = Uri.parse('$baseUrl/api/products/$productId');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch product');
    }
  }

  /// Create a new product
  Future<void> createProduct({
    required String name,
    required String description,
    required String category,
    double? price,
    bool occasion = false,
    required List<File> images,
    required String token,
  }) async {
    final uri = Uri.parse('$baseUrl/api/products');
    final request = http.MultipartRequest('POST', uri);

    // Add headers
    request.headers['Authorization'] = 'Bearer $token';

    // Add form fields
    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['category'] = category;
    if (price != null) request.fields['price'] = price.toString();
    request.fields['occasion'] = occasion.toString();

    // Add image files
    for (var image in images) {
      request.files
          .add(await http.MultipartFile.fromPath('images', image.path));
    }

    final response = await request.send();

    if (response.statusCode != 201) {
      final responseBody = await response.stream.bytesToString();
      throw Exception('Failed to create product: $responseBody');
    }
  }

  /// Update an existing product
  Future<void> updateProduct({
    required String productId,
    String? name,
    String? description,
    String? category,
    double? price,
    bool? occasion,
    List<File>? images,
    required String token,
  }) async {
    final uri = Uri.parse('$baseUrl/api/products/$productId');
    final request = http.MultipartRequest('PUT', uri);

    // Add headers
    request.headers['Authorization'] = 'Bearer $token';

    // Add form fields
    if (name != null) request.fields['name'] = name;
    if (description != null) request.fields['description'] = description;
    if (category != null) request.fields['category'] = category;
    if (price != null) request.fields['price'] = price.toString();
    if (occasion != null) request.fields['occasion'] = occasion.toString();

    // Add image files
    if (images != null) {
      for (var image in images) {
        request.files
            .add(await http.MultipartFile.fromPath('images', image.path));
      }
    }

    final response = await request.send();

    if (response.statusCode != 200) {
      final responseBody = await response.stream.bytesToString();
      throw Exception('Failed to update product: $responseBody');
    }
  }

  /// Delete a product
  Future<void> deleteProduct(String productId, String token) async {
    final uri = Uri.parse('$baseUrl/api/products/$productId');

    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete product');
    }
  }
}
