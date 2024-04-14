import 'package:injecktor/injecktor.dart';
import 'package:test/test.dart';

class Dependency {
  final String name;
  final int age;

  Dependency(this.name, this.age);

  @override
  String toString() {
    return 'Dependency{name: $name, age: $age}';
  }
}

void main() {
  group('A group of tests', () {
    test('First Test', () {
      expect(
          () => print(
              InjectKtor.addSingleton<Dependency>(Dependency('idk', 100000))),
          prints('Dependency{name: idk, age: 100000}\n'));
    });
  });
}
