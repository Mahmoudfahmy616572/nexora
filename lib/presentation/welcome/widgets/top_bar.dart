import 'package:flutter/material.dart';

import '../../../core/utils/breakpoints.dart';
import '../../../core/widgets/brand_lockup.dart';
import '../../../core/widgets/language_selector.dart';

/// Welcome top bar: the language switch sits at the start (left in English,
/// mirrored to the right in Arabic) with the brand lockup at the end.
class WelcomeTopBar extends StatelessWidget {
  const WelcomeTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final mobile = Breakpoints.isMobile(context);
    final narrow = MediaQuery.sizeOf(context).width < 380;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        LanguageSelector(compact: mobile),
        Expanded(child: BrandLockup(compact: mobile, narrow: narrow)),
      ],
    );
  }
}
