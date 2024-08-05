

class User {
  final String name;
  final int index;

  User({required this.name, required this.index});

  User copyWith({
    String? name,
    int? index,
  }) {
    return User(
      name: name ?? this.name,
      index: index ?? this.index,
    );
  }
}