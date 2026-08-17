import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index of the active bottom-navigation tab, shared so any screen can
/// jump to a tab (e.g. Home's "Added in Calendar" → Calendar tab).
final navigationIndexProvider = StateProvider<int>((ref) => 0);
