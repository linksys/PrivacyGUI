abstract class AppTreeNode<T> {
  final T data;
  AppTreeNode<T>? parent;
  final List<AppTreeNode<T>> children;
  double? width;
  double? height;
  String? tag;
  AppTreeNode({
    required this.data,
    this.parent,
    required this.children,
    this.width,
    this.height,
    this.tag,
  }) {
    for (var element in children) {
      element.parent = this;
    }
  }

  AppTreeNode<T> root() => parent == null ? this : parent!.root();
  AppTreeNode<T>? next() => parent == null
      ? null
      : isLast()
          ? null
          : parent?.children[index() + 1];
  bool isLast() => this == parent?.children.lastOrNull;
  bool isFirst() => this == parent?.children.firstOrNull;
  bool isRoot() => parent == null;
  bool isLeaf() => children.isEmpty;
  int index() => parent?.children.indexOf(this) ?? -1;
  int total() => 1 + (children.fold(0, (total, e) => total + e.total()));
  int level() =>
      isRoot() ? 0 : (parent?.level() != null ? (parent!.level() + 1) : 1);
  int maxLevel() => toFlatList()
      .reduce(
          (value, element) => value.level() > element.level() ? value : element)
      .level();
  int maxSibling() => toFlatList()
      .reduce((value, element) =>
          value.children.length > element.children.length ? value : element)
      .children
      .length;
  bool isAncesatorLast() => parent?.isLast() ?? false;
  List<bool> isAncestorLastArray() =>
      getChain().map((e) => e.isLast()).toList();
  List<AppTreeNode<T>> getChain() {
    List<AppTreeNode<T>> result = [];
    var ancesator = parent;
    while (ancesator != null) {
      result.add(ancesator);
      ancesator = ancesator.parent;
    }
    return result.reversed.toList();
  }

  List<AppTreeNode<T>> toFlatList() => [
        this,
        ...children.fold(
            <AppTreeNode<T>>[],
            (previousValue, element) =>
                [...previousValue, ...element.toFlatList()])
      ];
}
