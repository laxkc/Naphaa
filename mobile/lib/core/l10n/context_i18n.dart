import 'package:flutter/widgets.dart';

extension ContextI18nX on BuildContext {
  bool get isNepali => Localizations.localeOf(this).languageCode == 'ne';

  String tr(String en, String ne) => isNepali ? ne : en;
}
