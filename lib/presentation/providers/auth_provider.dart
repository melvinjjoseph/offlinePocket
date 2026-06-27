import 'package:flutter_riverpod/flutter_riverpod.dart';

// false = locked, true = authenticated
final authStateProvider = StateProvider<bool>((ref) => false);
