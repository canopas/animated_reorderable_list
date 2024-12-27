class User {
  final String name;
  final int id;

  User({required this.name, required this.id});

  User copyWith({
    String? name,
    int? id,
  }) {
    return User(
      name: name ?? this.name,
      id: id ?? this.id,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is User && other.name == name && other.id == id;
  }

  @override
  int get hashCode => Object.hash(name, id);
}
