import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/productService.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final ProductService _productService =
      ProductService(baseUrl: 'http://172.16.0.68:5000');

  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  bool _isOccasion = false;
  bool _isLoading = false;

  // Selected images
  final List<File> _selectedImages = [];

  // Categories
  List<dynamic> _categories = [];
  String? _selectedCategory;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final data = await _productService.fetchCategories();
      setState(() {
        _categories = data;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Product'),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.6)),

          // Main form
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Title
                Text(
                  'Create a Product',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        label: 'Product Name',
                        validatorMsg: 'Please enter a product name.',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _descController,
                        label: 'Description',
                        validatorMsg: 'Please enter a description.',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Category Dropdown or Add New
                      _buildCategoryDropdown(),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _priceController,
                        label: 'Price',
                        validatorMsg: 'Please enter a price (or 0).',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Checkbox(
                            value: _isOccasion,
                            onChanged: (val) {
                              setState(() => _isOccasion = val ?? false);
                            },
                            activeColor: Colors.white,
                            checkColor: Colors.black,
                          ),
                          const Text(
                            'Is this an occasion product?',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Image picker
                      ElevatedButton.icon(
                        icon: const Icon(Icons.image),
                        label: const Text('Select Images'),
                        onPressed: _pickImages,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Show image previews
                      if (_selectedImages.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedImages.map((file) {
                            return Stack(
                              children: [
                                Image.file(
                                  file,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(file),
                                    child: Container(
                                      color: Colors.red,
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 24),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createProduct,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.black,
                                )
                              : const Text('Create Product'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          onChanged: (val) => setState(() => _selectedCategory = val),
          decoration: InputDecoration(
            labelText: 'Select Category',
            labelStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withOpacity(0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          items: _isLoadingCategories
              ? [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Loading...'),
                  ),
                ]
              : _categories
                  .map((category) => DropdownMenuItem<String>(
                        value: category['name'],
                        child: Text(category['name']),
                      ))
                  .toList(),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () async {
            final newCategory = await _addCategoryDialog();
            if (newCategory != null) {
              setState(() {
                _categories.add(newCategory);
                _selectedCategory = newCategory['name'];
              });
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Add New Category'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>?> _addCategoryDialog() async {
    final TextEditingController categoryController = TextEditingController();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Category'),
          content: TextField(
            controller: categoryController,
            style: const TextStyle(
                color: Colors.black), // Ensure input text is black
            decoration: const InputDecoration(
              hintText: 'Category Name',
              hintStyle:
                  TextStyle(color: Colors.grey), // Optional hint text style
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = categoryController.text.trim();
                if (name.isEmpty) return;

                try {
                  final newCategory =
                      await _productService.addCategory(name, token);
                  Navigator.pop(context, newCategory);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add category: $e')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        for (final file in pickedFiles) {
          _selectedImages.add(File(file.path));
        }
      });
    }
  }

  void _removeImage(File file) {
    setState(() => _selectedImages.remove(file));
  }

  Future<void> _createProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';

      if (token.isEmpty) {
        throw Exception('No auth token found. Please log in again.');
      }

      final double? price = double.tryParse(_priceController.text.trim());

      await _productService.createProduct(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        category: _selectedCategory ?? '',
        price: price,
        occasion: _isOccasion,
        images: _selectedImages,
        token: token,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String validatorMsg,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return validatorMsg;
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    );
  }
}
