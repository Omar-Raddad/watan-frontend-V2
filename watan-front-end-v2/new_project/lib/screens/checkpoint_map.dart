import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:new_project/helper/shortest_path_A.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../services/checkpoint_service.dart';
import '../helper/graph_helper.dart'; // Haversine distance
import 'package:http/http.dart' as http;

class CheckpointMap extends StatefulWidget {
  const CheckpointMap({Key? key}) : super(key: key);

  @override
  _CheckpointMapState createState() => _CheckpointMapState();
}

class _CheckpointMapState extends State<CheckpointMap> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  LatLng? _selectedSource;
  LatLng? _selectedDestination;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  final CheckpointService checkpointService =
      CheckpointService(baseUrl: 'http://172.16.0.68:5000');

  final AStar aStar = AStar(Graph()); // Graph for A* algorithm
  StreamSubscription<Position>? _positionStream;
  bool _userMovedCamera = false;
  bool _initialCameraSet =
      false; // To track if the initial camera position is set
  @override
  void initState() {
    super.initState();
    _checkAndRequestLocationPermission();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("Location services are disabled.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print("Location permission denied.");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      // Set initial camera position only once
      if (!_initialCameraSet && _mapController != null) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition!, 14),
        );
        _initialCameraSet = true;
      }

      _positionStream = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen((Position pos) {
        setState(() {
          _currentPosition = LatLng(pos.latitude, pos.longitude);
        });

        // Do not re-center the camera automatically when the user moves it
        if (!_userMovedCamera && _mapController != null) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(_currentPosition!),
          );
        }
      });

      await _fetchCheckpoints();
    } catch (e) {
      print('Error getting user location: $e');
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _checkAndRequestLocationPermission() async {
    var status = await Permission.location.request();

    if (status.isGranted) {
      await _getUserLocation();
    } else {
      _showPermissionDialog();
    }
  }

  Future<void> _fetchCheckpoints() async {
    try {
      final checkpoints = await checkpointService.getCheckpoints();
      setState(() {
        _markers = checkpoints.map<Marker>((checkpoint) {
          final double latitude = checkpoint['coordinates']['coordinates'][1];
          final double longitude = checkpoint['coordinates']['coordinates'][0];
          final String id = checkpoint['_id'];

          // Add node to graph
          aStar.graph.addNode(id, latitude, longitude);

          return Marker(
            markerId: MarkerId(id),
            position: LatLng(latitude, longitude),
            infoWindow: InfoWindow(
              title: checkpoint['name'],
              snippet:
                  'Status: ${checkpoint['mainStatus']} (${checkpoint['secondaryStatus']})',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              checkpoint['mainStatus'] == 'Open'
                  ? (checkpoint['secondaryStatus'] == 'Smooth'
                      ? BitmapDescriptor.hueGreen
                      : checkpoint['secondaryStatus'] == 'Moderate'
                          ? BitmapDescriptor.hueOrange
                          : BitmapDescriptor.hueRed)
                  : BitmapDescriptor.hueBlue,
            ),
          );
        }).toSet();

        for (int i = 0; i < checkpoints.length; i++) {
          for (int j = i + 1; j < checkpoints.length; j++) {
            final checkpointA = checkpoints[i];
            final checkpointB = checkpoints[j];

            _addEdgeUsingRoadDistance(checkpointA, checkpointB);
          }
        }
      });
    } catch (e) {
      print('Error fetching checkpoints: $e');
    }
  }

  Future<void> _addEdgeUsingRoadDistance(Map<String, dynamic> checkpointA,
      Map<String, dynamic> checkpointB) async {
    final double fromLat = checkpointA['coordinates']['coordinates'][1];
    final double fromLng = checkpointA['coordinates']['coordinates'][0];
    final double toLat = checkpointB['coordinates']['coordinates'][1];
    final double toLng = checkpointB['coordinates']['coordinates'][0];

    final String apiKey = 'AIzaSyBLV1pHigFWtxnbxL8tdLh93QvOkRGgzXc';
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$fromLat,$fromLng&destination=$toLat,$toLng&key=$apiKey&mode=driving';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = data['routes'];
        if (routes.isNotEmpty) {
          final legs = routes[0]['legs'];
          if (legs.isNotEmpty) {
            final distance =
                legs[0]['distance']['value'] / 1000.0; // Meters to kilometers

            aStar.graph
                .addEdge(checkpointA['_id'], checkpointB['_id'], distance);
            aStar.graph
                .addEdge(checkpointB['_id'], checkpointA['_id'], distance);
          }
        }
      } else {
        print('Error fetching directions: ${response.body}');
      }
    } catch (e) {
      print('Error fetching directions: $e');
    }
  }

  Future<void> _fetchAndDrawRoute() async {
    if (_selectedSource == null || _selectedDestination == null) {
      print("Source or destination not set.");
      return;
    }

    try {
      // Fetch route points using Google Maps Directions API
      final routePoints = await _fetchRoutePolyline(
        _selectedSource!.latitude,
        _selectedSource!.longitude,
        _selectedDestination!.latitude,
        _selectedDestination!.longitude,
      );

      // Optionally evaluate checkpoints along the route
      final adjustedRoute = await _adjustRouteForCheckpoints(routePoints);

      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            color: Colors.blue,
            width: 5,
            points: adjustedRoute,
          ),
        };
      });
    } catch (e) {
      print("Error fetching or drawing route: $e");
    }
  }

  Future<List<LatLng>> _fetchRoutePolyline(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    const apiKey =
        'AIzaSyBLV1pHigFWtxnbxL8tdLh93QvOkRGgzXc'; // Replace with your key
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$startLat,$startLng&destination=$endLat,$endLng&key=$apiKey&mode=driving';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['routes'].isNotEmpty) {
        final polyline = data['routes'][0]['overview_polyline']['points'];
        return _decodePolyline(polyline);
      }
    }
    throw Exception('Failed to fetch directions');
  }

  Future<List<LatLng>> _adjustRouteForCheckpoints(List<LatLng> route) async {
    final checkpoints = await checkpointService.getCheckpoints();

    // Filter checkpoints relevant to the route
    final relevantCheckpoints = checkpoints.where((checkpoint) {
      final LatLng position = LatLng(
        checkpoint['coordinates']['coordinates'][1],
        checkpoint['coordinates']['coordinates'][0],
      );
      return _isCheckpointAlongRoute(route, position);
    }).toList();

    // Optionally adjust the route based on checkpoint statuses
    // For now, return the original route without adjustments
    return route;
  }

  bool _isCheckpointAlongRoute(List<LatLng> route, LatLng checkpoint) {
    const double proximityThreshold = 0.5; // kilometers
    for (final point in route) {
      final distance = GraphHelper.haversineDistance(
        point.latitude,
        point.longitude,
        checkpoint.latitude,
        checkpoint.longitude,
      );
      if (distance <= proximityThreshold) {
        return true;
      }
    }
    return false;
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dLat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dLng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Location access permission is required to use the map. '
          'Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Set the initial camera position only once after the map is created
    if (_currentPosition != null && !_initialCameraSet) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 14),
      );
      _initialCameraSet = true;
    }
  }

  void _onCameraMoveStarted() {
    _userMovedCamera = true;
  }

  void _onCameraIdle() {
    if (!_userMovedCamera && _currentPosition != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
    }
  }

  Future<void> _selectSourceDestination(String type, LatLng location) async {
    setState(() {
      if (type == 'source') {
        _selectedSource = location;
      } else {
        _selectedDestination = location;
      }
    });

    if (_selectedSource != null && _selectedDestination != null) {
      final startId = _findClosestCheckpoint(_selectedSource!);
      final goalId = _findClosestCheckpoint(_selectedDestination!);

      if (startId != null && goalId != null) {
        final path = aStar.findShortestPath(startId, goalId);
        _drawPath(path);
      } else {
        _drawStraightLine(_selectedSource!, _selectedDestination!);
      }
    }
  }

  String? _findClosestCheckpoint(LatLng position) {
    String? closestId;
    double closestDistance = double.infinity;

    for (final node in aStar.graph.nodes.values) {
      final distance = GraphHelper.haversineDistance(
        position.latitude,
        position.longitude,
        node.latitude,
        node.longitude,
      );

      if (distance < closestDistance) {
        closestDistance = distance;
        closestId = node.id;
      }
    }

    return closestId;
  }

  void _drawPath(List<String> path) {
    print("Using Google Maps Directions API for the route.");
    _fetchAndDrawRoute();
  }

  void _drawStraightLine(LatLng start, LatLng end) {
    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('straight_line'),
          color: Colors.red,
          width: 5,
          points: [start, end],
        ),
      };
    });
  }

  Widget _buildLegend() {
    return Positioned(
      bottom: 20,
      left: 10,
      child: Card(
        color: Colors.white.withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem(Colors.green, 'Smooth Movement'),
              _buildLegendItem(Colors.orange, 'Moderate Movement'),
              _buildLegendItem(Colors.red, 'Congested Movement'),
              _buildLegendItem(Colors.blue, 'Closed Checkpoint'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildHeaderBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final source = await _pickLocation('Source');
                    if (source != null) {
                      _selectSourceDestination('source', source);
                    }
                  },
                  child: const Text('Select Source'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final destination = await _pickLocation('Destination');
                    if (destination != null) {
                      _selectSourceDestination('destination', destination);
                      await _fetchAndDrawRoute(); // Automatically fetch and draw route
                    }
                  },
                  child: const Text('Select Destination'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<LatLng?> _pickLocation(String type) async {
    Completer<LatLng?> completer = Completer();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Pick $type Location'),
          content: SizedBox(
            height: 400,
            child: GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: _currentPosition ?? LatLng(32.22503, 35.26097),
                zoom: 10,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onTap: (LatLng location) {
                Navigator.of(context).pop();
                completer.complete(location);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkpoints Map'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;

              if (_currentPosition != null && !_initialCameraSet) {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(_currentPosition!, 14),
                );
                _initialCameraSet = true;
              }
            },
            initialCameraPosition: CameraPosition(
              target: _currentPosition ?? LatLng(32.22503, 35.26097),
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          _buildLegend(),
          _buildHeaderBar(),
        ],
      ),
    );
  }
}
