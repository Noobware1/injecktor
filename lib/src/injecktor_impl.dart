import 'package:injecktor/src/closeable.dart';
import 'package:injecktor/src/injecktor_interface.dart';

class InjectKtorImpl implements InjectKtorInterface {
  /// Holds references to every registered Instance when using
  static final Map<String, _InstanceBuilderFactory> _factories = {};

  @override
  void resetInstance() {
    _factories.clear();
  }

  @override
  S addSingleton<S>(S singleInstance, {bool? permanent, String? name}) {
    _insert<S>(
      isSingleton: true,
      name: name,
      permanent: permanent,
      builder: () => singleInstance,
    );
    return get<S>(name: name);
  }

  @override
  void addLazySingleton<S>(InstanceBuilderCallback<S> builder,
      {bool? permanent, String? name}) {
    _insert<S>(
      isSingleton: true,
      name: name,
      permanent: permanent,
      builder: builder,
    );
  }

  @override
  void addFactory<S>(InstanceBuilderCallback<S> builder,
      {bool? permanent, String? name}) {
    _insert<S>(
      isSingleton: false,
      name: name,
      permanent: permanent,
      builder: builder,
    );
  }

  /// Injects the Instance [S] builder into the `_factories` HashMap.
  void _insert<S>({
    required bool isSingleton,
    String? name,
    bool? permanent,
    required InstanceBuilderCallback<S> builder,
  }) {
    final key = _getKey(S, name);

    _InstanceBuilderFactory<S>? dep;
    if (_factories.containsKey(key)) {
      final newDep = _factories[key];
      if (newDep == null || !newDep.isDirty) {
        return;
      } else {
        dep = newDep as _InstanceBuilderFactory<S>;
      }
    }
    _factories[key] = _InstanceBuilderFactory<S>(
      isSingleton: isSingleton,
      builderFunc: builder,
      permanent: permanent ?? false,
      isInit: false,
      name: name,
      lateRemove: dep,
    );
  }

  @override
  S get<S>({String? name}) {
    final key = _getKey(S, name);
    if (isRegistered<S>(name: name)) {
      final dep = _factories[key];
      if (dep == null) {
        if (name == null) {
          throw 'Class "$S" is not registered';
        } else {
          throw 'Class "$S" with name "$name" is not registered';
        }
      }

      /// although dirty solution, the lifecycle starts inside
      /// `initDependencies`, so we have to return the instance from there
      /// to make it compatible with `Get.create()`.
      // final i = _initDependencies<S>(name: name);
      // return i ?? dep.getDependency() as S;
      return dep.getDependency() as S;
    } else {
      throw '"$S" not found. You need to call "Injectktor.addSington($S())" or "Injectktor.addLazySington(()=>$S())" or "Injectktor.addFactory(()=>$S())"';
    }
  }

  @override
  S getOrElse<S>(S Function() orElse, {String? name}) {
    if (isRegistered<S>(name: name)) {
      return get<S>(name: name);
    } else {
      return orElse();
    }
  }

  @override
  S? getOrNull<S>({String? name}) {
    if (isRegistered<S>(name: name)) {
      return get<S>(name: name);
    }
    return null;
  }

  _InstanceBuilderFactory? _getDependency<S>({String? name, String? key}) {
    final newKey = key ?? _getKey(S, name);

    if (!_factories.containsKey(newKey)) {
      // Get.log('Instance "$newKey" is not registered.', isError: true);
      return null;
    } else {
      return _factories[newKey];
    }
  }

  @override
  void replaceSingleton<P>(P child, {String? name}) {
    final info = getInstanceInfo<P>(name: name);
    final permanent = (info.isPermanent);
    remove<P>(name: name, force: permanent);
    addSingleton(child, name: name, permanent: permanent);
  }

  @override
  void lazyReplaceSingleton<P>(InstanceBuilderCallback<P> builder,
      {String? name, bool? permanent}) {
    final info = getInstanceInfo<P>(name: name);
    final permanent = (info.isPermanent);
    remove<P>(name: name, force: permanent);
    addLazySingleton(builder, name: name, permanent: permanent);
  }

  @override
  void markAsDirty<S>({String? name, String? key}) {
    final newKey = key ?? _getKey(S, name);
    if (_factories.containsKey(newKey)) {
      final dep = _factories[newKey];
      if (dep != null && !dep.permanent) {
        dep.isDirty = true;
      }
    }
  }

  @override
  InstanceInfo getInstanceInfo<S>({String? name}) {
    final build = _getDependency<S>(name: name);

    return InstanceInfo(
      isPermanent: build?.permanent ?? false,
      isSingleton: build?.isSingleton,
      isRegistered: isRegistered<S>(name: name),
      isPrepared: !(build?.isInit ?? true),
      isInit: build?.isInit,
    );
  }

  @override
  void reload<S>({String? name, String? key, bool force = false}) {
    final newKey = key ?? _getKey(S, name);

    final builder = _getDependency<S>(name: name, key: newKey);
    if (builder == null) return;

    if (builder.permanent && !force) {
      // Get.log(
      //   '''Instance "$newKey" is permanent. Use [force = true] to force the restart.''',
      //   isError: true,
      // );
      return;
    }

    final i = builder.dependency;

    if (i is CloseableMixin) {
      i.close();
      // Get.log('"$newKey" onDelete() called');
    }

    builder.dependency = null;
    builder.isInit = false;

    // Get.log('Instance "$newKey" was restarted.');
  }

  @override
  void reloadAll({bool force = false}) {
    _factories.forEach((key, value) {
      if (value.permanent && !force) {
        // Get.log('Instance "$key" is permanent. Skipping reload');
      } else {
        value.dependency = null;
        value.isInit = false;
        // Get.log('Instance "$key" was reloaded.');
      }
    });
  }

  @override
  bool remove<S>({String? name, String? key, bool force = false}) {
    final newKey = key ?? _getKey(S, name);

    if (!_factories.containsKey(newKey)) {
      // Get.log('Instance "$newKey" already removed.', isError: true);
      return false;
    }

    final dep = _factories[newKey];

    if (dep == null) return false;

    final _InstanceBuilderFactory builder;
    if (dep.isDirty) {
      builder = dep.lateRemove ?? dep;
    } else {
      builder = dep;
    }

    if (builder.permanent && !force) {
      // Get.log(
      //   // ignore: lines_longer_than_80_chars
      //   '"$newKey" has been marked as permanent, SmartManagement is not authorized to remove it.',
      //   isError: true,
      // );
      return false;
    }
    final i = builder.dependency;

    if (i is CloseableMixin) {
      i.close();
      // Get.log('"$newKey" onDelete() called');
    }

    if (builder.permanent) {
      builder.dependency = null;
      builder.isInit = false;
      return true;
    } else {
      if (dep.lateRemove != null) {
        dep.lateRemove = null;
        // Get.log('"$newKey" deleted from memory');
        return false;
      } else {
        _factories.remove(newKey);
        if (_factories.containsKey(newKey)) {
          // Get.log('Error removing object "$newKey"', isError: true);
        } else {
          // Get.log('"$newKey" deleted from memory');
        }
        return true;
      }
    }
  }

  @override
  void removeAll({bool force = false}) {
    final keys = _factories.keys.toList();
    for (final key in keys) {
      remove(key: key, force: force);
    }
  }

  @override
  bool isPrepared<S>({String? name}) =>
      _factories.containsKey(_getKey(S, name));

  @override
  bool isRegistered<S>({String? name}) {
    final newKey = _getKey(S, name);

    final builder = _getDependency<S>(name: name, key: newKey);
    if (builder == null) {
      return false;
    }

    if (!builder.isInit) {
      return true;
    }
    return false;
  }

  /// Generates the key based on [type] (and optionally a [name])
  /// to register an Instance Builder in the hashmap.
  String _getKey(Type type, String? name) {
    return name == null ? type.toString() : type.toString() + name;
  }
}

/// Internal class to register instances with `Injecktor.find<S>()`.
class _InstanceBuilderFactory<S> {
  /// Marks the Builder as a single instance.
  /// For reusing [dependency] instead of [builderFunc]
  bool isSingleton;

  /// Stores the actual object instance when [isSingleton]=true.
  S? dependency;

  /// Generates (and regenerates) the instance when [isSingleton]=false.
  /// Usually used by factory methods
  InstanceBuilderCallback<S> builderFunc;

  /// Flag to persist the instance in memory,
  /// without considering `Get.smartManagement`
  bool permanent = false;

  bool isInit = false;

  _InstanceBuilderFactory<S>? lateRemove;

  bool isDirty = false;

  String? name;

  _InstanceBuilderFactory({
    required this.isSingleton,
    required this.builderFunc,
    required this.permanent,
    required this.isInit,
    required this.name,
    required this.lateRemove,
  });

  // void _showInitLog() {
  //   if (name == null) {
  //     Get.log('Instance "$S" has been created');
  //   } else {
  //     Get.log('Instance "$S" has been created with name "$name"');
  //   }
  // }

  /// Gets the actual instance by it's [builderFunc] or the persisted instance.
  S getDependency() {
    if (isSingleton) {
      dependency ??= builderFunc();
      return dependency!;
    } else {
      return builderFunc();
    }
  }
}
