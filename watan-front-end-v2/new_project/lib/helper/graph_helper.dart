import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Graph {
  final Map<String, Node> nodes = {};

  void addNode(String id, double latitude, double longitude) {
    nodes[id] = Node(id, latitude, longitude);
  }

  void addEdge(String fromId, String toId, double weight) {
    nodes[fromId]?.edges[toId] = weight;
  }

  Node? getNode(String id) => nodes[id];
  List<String> get allNodeIds => nodes.keys.toList();
}

class Node {
  final String id;
  final double latitude;
  final double longitude;
  final Map<String, double> edges = {};

  Node(this.id, this.latitude, this.longitude);
}

class GraphHelper {
  static double haversineDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371; // Earth's radius in kilometers
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a = pow(sin(dLat / 2), 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            pow(sin(dLon / 2), 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) => degrees * pi / 180;

  static double getEdgeWeight(double distance, String status) {
    switch (status) {
      case 'Smooth':
        return distance;
      case 'Moderate':
        return distance * 2;
      case 'Congested':
        return distance * 3;
      default:
        return double.infinity; // Closed or unknown
    }
  }
}

Future<Graph> constructGraph({
  required LatLng userLocation,
  required LatLng destination,
  required List<Map<String, dynamic>> checkpoints,
  required String apiKey,
}) async {
  final graph = Graph();

  // Add the user location and destination as nodes
  graph.addNode('user', userLocation.latitude, userLocation.longitude);
  graph.addNode('destination', destination.latitude, destination.longitude);

  // Add checkpoints as nodes (skip closed checkpoints)
  for (final checkpoint in checkpoints) {
    if (checkpoint['mainStatus'] == 'Closed') {
      print("Skipping closed checkpoint: ${checkpoint['_id']}");
      continue;
    }
    final id = checkpoint['_id'];
    final lat = checkpoint['coordinates']['coordinates'][1];
    final lon = checkpoint['coordinates']['coordinates'][0];
    graph.addNode(id, lat, lon);
  }

  final allNodes = graph.allNodeIds;

  // Add edges using road distances between nodes
  for (int i = 0; i < allNodes.length; i++) {
    for (int j = i + 1; j < allNodes.length; j++) {
      final node1 = graph.getNode(allNodes[i]);
      final node2 = graph.getNode(allNodes[j]);

      if (node1 != null && node2 != null) {
        try {
          final distance = await _fetchDistanceFromDirectionsAPI(
            node1.latitude,
            node1.longitude,
            node2.latitude,
            node2.longitude,
            apiKey,
          );

          // Determine edge weight based on status
          final status = checkpoints.firstWhere(
            (c) => c['_id'] == node1.id,
            orElse: () => {'secondaryStatus': 'Smooth'},
          )['secondaryStatus'];

          final weight = GraphHelper.getEdgeWeight(distance, status);
          graph.addEdge(node1.id, node2.id, weight);
          graph.addEdge(node2.id, node1.id, weight);
        } catch (e) {
          print(
              "Error fetching distance between ${node1.id} and ${node2.id}: $e");
        }
      }
    }
  }

  return graph;
}

Future<double> _fetchDistanceFromDirectionsAPI(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
  String apiKey,
) async {
  final url =
      'https://maps.googleapis.com/maps/api/directions/json?origin=$lat1,$lon1&destination=$lat2,$lon2&key=$apiKey&mode=driving';
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['routes'].isNotEmpty) {
      final distance = data['routes'][0]['legs'][0]['distance']['value'];
      return distance / 1000; // Convert meters to kilometers
    }
  }
  throw Exception('Failed to fetch directions');
}
