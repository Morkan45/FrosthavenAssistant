import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Resource/app_constants.dart';
import 'package:frosthaven_assistant/Resource/ui_tokens.dart';

void main() {
  test('spacing scale remains ordered', () {
    expect([
      UiSpacing.xxs,
      UiSpacing.xs,
      UiSpacing.sm,
      UiSpacing.md,
      UiSpacing.section,
      UiSpacing.menuTop,
      UiSpacing.lg,
      UiSpacing.xl,
    ], orderedEquals([2, 4, 8, 16, 18, 20, 24, 48]));
  });

  test('legacy constants preserve token values', () {
    expect(kButtonSize, UiTargetSize.compact);
    expect(kMenuNarrowWidth, UiModal.narrowWidth);
    expect(kCardBorderRadius, UiRadii.card);
    expect(kGameCardBorderRadius, UiRadii.gameCard);
    expect(kTitleStyle, UiTypography.title);
    expect(kButtonLabelStyle, UiTypography.buttonLabel);
    expect(kPhoneScreenMaxDimension, UiBreakpoints.phoneMaxDimension);
    expect(kLargeTabletMinDimension, UiBreakpoints.largeTabletMinDimension);
  });

  test('operational card radii stay within eight pixels', () {
    expect(UiRadii.card, lessThanOrEqualTo(8));
    expect(UiRadii.deckStack, lessThanOrEqualTo(8));
    expect(UiRadii.gameCard, lessThanOrEqualTo(8));
  });
}
