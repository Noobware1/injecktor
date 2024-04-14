import 'package:injecktor/injecktor.dart';

void main() {
  print(InjectKtor.addSingleton<Dependency>(Dependency('idk', 100000)));
}

class Dependency {
  final String name;
  final int age;

  Dependency(this.name, this.age);

  @override
  String toString() {
    return 'Dependency{name: $name, age: $age}';
  }
}
