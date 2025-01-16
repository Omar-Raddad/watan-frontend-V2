import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // Add this package to your pubspec.yaml
import '../services/checkpoint_service.dart';

class CheckpointDetailsPage extends StatefulWidget {
  final String checkpointId;

  const CheckpointDetailsPage({Key? key, required this.checkpointId})
      : super(key: key);

  @override
  _CheckpointDetailsPageState createState() => _CheckpointDetailsPageState();
}

class _CheckpointDetailsPageState extends State<CheckpointDetailsPage> {
  final CheckpointService checkpointService =
      CheckpointService(baseUrl: 'http://172.16.0.68:5000');
  Map<String, dynamic>? _checkpointDetails;
  bool _isLoading = true;
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 5; // Default rating value

  Future<void> _fetchCheckpointDetails() async {
    try {
      final details =
          await checkpointService.getCheckpointDetails(widget.checkpointId);
      setState(() {
        _checkpointDetails = details;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching checkpoint details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addReview() async {
    if (_reviewController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review text cannot be empty')),
      );
      return;
    }

    try {
      await checkpointService.addReview(
        widget.checkpointId,
        {"text": _reviewController.text, "rating": _rating},
      );
      _reviewController.clear();
      _fetchCheckpointDetails(); // Refresh details
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add review')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCheckpointDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkpoint Details'),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.green],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : _checkpointDetails == null
                  ? const Center(
                      child: Text(
                        'Failed to load details.',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _checkpointDetails!['name'],
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Status: ${_checkpointDetails!['mainStatus']} (${_checkpointDetails!['secondaryStatus']})',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Reviews:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._checkpointDetails!['reviews']
                                .map<Widget>((review) => Card(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      color: Colors.white.withOpacity(0.9),
                                      child: ListTile(
                                        title: Text(
                                          review['text'] ?? 'No text',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                            'Rating: ${review['rating']} stars'),
                                      ),
                                    ))
                                .toList(),
                            const SizedBox(height: 16),
                            const Text(
                              'Rate this checkpoint:',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            RatingBar.builder(
                              initialRating: _rating,
                              minRating: 1,
                              direction: Axis.horizontal,
                              allowHalfRating: false,
                              itemCount: 5,
                              itemPadding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              itemBuilder: (context, _) => const Icon(
                                Icons.star,
                                color: Colors.red, // Red stars
                              ),
                              onRatingUpdate: (rating) {
                                setState(() {
                                  _rating = rating;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _reviewController,
                              decoration: InputDecoration(
                                labelText: 'Add a Review',
                                labelStyle:
                                    const TextStyle(color: Colors.white70),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _addReview,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Submit Review'),
                            ),
                          ],
                        ),
                      ),
                    ),
        ],
      ),
    );
  }
}
