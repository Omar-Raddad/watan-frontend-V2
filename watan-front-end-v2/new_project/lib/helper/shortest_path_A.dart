import 'package:new_project/helper/graph_helper.dart';
import 'package:new_project/helper/priority_queue.dart';

class AStar {
  final Graph graph;

  AStar(this.graph);

  List<String> findShortestPath(String startId, String goalId) {
    print("Finding shortest path from $startId to $goalId");
    final openSet = PriorityQueue<PathNode>((a, b) => a.f.compareTo(b.f));
    final Map<String, PathNode> allNodes = {};

    final startNode =
        PathNode(id: startId, g: 0, h: _heuristic(startId, goalId));
    openSet.add(startNode);
    allNodes[startId] = startNode;

    while (openSet.isNotEmpty) {
      final current = openSet.removeFirst();
      print("Visiting node: ${current.id}");

      if (current.id == goalId) {
        print("Goal reached!");
        return _reconstructPath(current);
      }

      final neighbors = graph.getNode(current.id)?.edges ?? {};
      for (final entry in neighbors.entries) {
        final neighborId = entry.key;
        final weight = entry.value;

        if (weight == double.infinity) continue; // Skip unreachable neighbors

        final g = current.g + weight;
        final neighborNode = allNodes.putIfAbsent(
          neighborId,
          () => PathNode(id: neighborId, h: _heuristic(neighborId, goalId)),
        );

        if (g < neighborNode.g) {
          neighborNode.g = g;
          neighborNode.parent = current;

          if (!openSet.contains(neighborNode)) {
            openSet.add(neighborNode);
          }
        }
      }
    }

    print("No path found.");
    return [];
  }

  double _heuristic(String nodeId, String goalId) {
    final node = graph.getNode(nodeId);
    final goal = graph.getNode(goalId);
    if (node == null || goal == null) return double.infinity;

    return GraphHelper.haversineDistance(
        node.latitude, node.longitude, goal.latitude, goal.longitude);
  }

  List<String> _reconstructPath(PathNode node) {
    final path = <String>[];
    PathNode? current = node; // Allow null handling
    while (current != null) {
      path.insert(0, current.id);
      current = current.parent;
    }
    return path;
  }
}

class PathNode {
  final String id;
  double g; // Cost from start to this node
  final double h; // Heuristic (estimated cost to goal)
  double get f => g + h; // Total cost
  PathNode? parent;

  // Added `g` as a named parameter with a default value of `double.infinity`
  PathNode({required this.id, this.g = double.infinity, required this.h});
}
