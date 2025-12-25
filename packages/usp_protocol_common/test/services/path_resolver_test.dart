import 'package:test/test.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

// Mock implementation of ITraversableNode for testing
class TestNode implements ITraversableNode<TestNode> {
  @override
  final String name;
  final Map<String, TestNode> _children = {};

  TestNode(this.name);

  void addChild(TestNode child) {
    _children[child.name] = child;
  }

  @override
  TestNode? getChild(String name) => _children[name];

  @override
  Iterable<TestNode> getAllChildren() => _children.values;

  @override
  String toString() => 'TestNode($name)';
}

void main() {
  group('PathResolver', () {
    late TestNode root;
    late PathResolver resolver;

    setUp(() {
      // Build a simple tree: Device.A.B and Device.A.C
      root = TestNode('Device');
      final nodeA = TestNode('A');
      final nodeB = TestNode('B');
      final nodeC = TestNode('C');

      nodeA.addChild(nodeB);
      nodeA.addChild(nodeC);
      root.addChild(nodeA);

      resolver = PathResolver();
    });

    test('should resolve a direct path', () {
      final path = UspPath.parse('Device.A.B');
      final results = resolver.resolve(root, path);

      expect(results.length, 1);
      expect(results.first.name, 'B');
    });

    test('should resolve a wildcard path', () {
      final path = UspPath.parse('Device.A.*');
      final results = resolver.resolve(root, path);

      expect(results.length, 2);
      expect(results.map((n) => n.name).toList(), containsAll(['B', 'C']));
    });

    test('should return an empty list for a non-existent path', () {
      final path = UspPath.parse('Device.A.D');
      final results = resolver.resolve(root, path);

      expect(results, isEmpty);
    });

    test('should handle paths that do not start with the root name', () {
      final path = UspPath.parse('A.C');
      final results = resolver.resolve(root, path);

      expect(results.length, 1);
      expect(results.first.name, 'C');
    });

    test('should return root for path matching root name', () {
      final path = UspPath.parse('Device');
      final results = resolver.resolve(root, path);

      expect(results.length, 1);
      expect(results.first.name, 'Device');
    });
  });
}
