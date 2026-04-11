import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/match_model.dart';

final activeMatchProvider = StateProvider<MatchModel?>((ref) => null);
