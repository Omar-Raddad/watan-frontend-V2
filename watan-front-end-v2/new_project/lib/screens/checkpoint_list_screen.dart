import 'package:flutter/material.dart';
import 'package:new_project/screens/checkpoint_details_screen.dart';
import '../services/checkpoint_service.dart';

class CheckpointsListPage extends StatefulWidget {
  const CheckpointsListPage({Key? key}) : super(key: key);

  @override
  _CheckpointsListPageState createState() => _CheckpointsListPageState();
}

class _CheckpointsListPageState extends State<CheckpointsListPage> {
  final CheckpointService checkpointService =
      CheckpointService(baseUrl: 'http://172.16.0.68:5000');
  List<dynamic> _checkpoints = [];
  bool _isLoading = true;

  Future<void> _fetchCheckpoints() async {
    try {
      final checkpoints = await checkpointService.getCheckpoints();
      setState(() {
        _checkpoints = checkpoints;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching checkpoints: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCheckpoints();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkpoints List'),
      ),
      body: Stack(
        children: [
          // Background
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
                  child: CircularProgressIndicator(color: Colors.white))
              : _checkpoints.isEmpty
                  ? const Center(
                      child: Text(
                        'No checkpoints available.',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _checkpoints.length,
                      itemBuilder: (context, index) {
                        final checkpoint = _checkpoints[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          color: Colors.white.withOpacity(0.9),
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Icon(
                              checkpoint['mainStatus'] == 'Open'
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: checkpoint['mainStatus'] == 'Open'
                                  ? Colors.green
                                  : Colors.red,
                              size: 32,
                            ),
                            title: Text(
                              checkpoint['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Status: ${checkpoint['mainStatus']} (${checkpoint['secondaryStatus']})',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CheckpointDetailsPage(
                                    checkpointId: checkpoint['_id'],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}
