import 'package:flutter_bloc/flutter_bloc.dart';

import 'welcome_state.dart';

/// Cubit for the welcome / landing screen.
///
/// The screen itself is static for now; navigation and language switching are
/// handled by the router and the app-wide [LocaleCubit]. This cubit is the
/// home for any welcome-specific logic added later (e.g. campaign content).
class WelcomeCubit extends Cubit<WelcomeState> {
  WelcomeCubit() : super(const WelcomeState());
}
