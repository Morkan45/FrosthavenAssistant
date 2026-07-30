import 'dart:math' show pi;

import 'package:flutter/material.dart';

import 'ui_tokens.dart';

// Shared UI constants for the Frosthaven Assistant app.

// Font sizes (static, unscaled — multiply by the scale factor where needed)
const double kFontSizeSmall = UiTypography.smallSize;
const double kFontSizeBody = UiTypography.bodySize;
const double kFontSizeTitle = UiTypography.titleSize;
const double kFontSizeButtonLabel = UiTypography.buttonLabelSize;
const double kFontSizeHeading = UiTypography.headingSize;
const double kFontSizeToast = UiTypography.toastSize;

/// Widget dimensions (multiply by the screen scale factor where used as kButtonSize * scale)
const double kButtonSize = UiTargetSize.compact;
const double kIconSize = 30;     // stat icons and list-tile leading images

/// Bar and toolbar height (multiply by userScalingBars where needed)
const double kBarHeight = 40.0;

/// Background image opacity for dark/light mode
const double kDarkModeOpacity = 0.4;
const double kLightModeOpacity = 0.7;

/// Standard text/icon shadow — offset and blur are equal; multiply by scale factor
const double kShadowOffset = 1.0;

/// Card box-shadow (multiply by scale where needed)
const double kCardShadowBlur = 4.0;
const double kCardShadowOffsetX = 2.0;
const double kCardShadowOffsetY = 4.0;

/// Card dimensions — base size for modifier/loot cards and ability cards
const double kModifierCardBaseWidth = 58.6666;
const double kAbilityCardWidth = 142.4;

/// Card border radii
const double kCardBorderRadius = UiRadii.card;
const double kGameCardBorderRadius = UiRadii.gameCard;

/// Monster card margin (multiply by scale)
const double kMonsterCardMargin = 1.6;

/// Card zoom dialog constants
const double kCardZoomDefaultScale = 6.0;
const double kCardZoomWidthFactor = 7.0;

/// Standard animation duration in milliseconds
const int kAnimationDurationMs = 300;

/// Menu layout
const double kMenuTopPadding = 20.0;     // top spacing inside modal menus
const double kMenuNarrowWidth = UiModal.narrowWidth;
const double kMenuMaxHeightRatio = 0.9;  // max height for scrollable menus

/// Button sizes and radii for action/condition buttons
const double kConditionButtonSize = 42.0;
const double kRoundButtonBorderRadius = 30.0;

/// Small item margin/spacing
const double kSmallMargin = 2.0;

/// Deck widget font size
const double kDeckFontSize = 12.0;

/// Height for save confirmation dialogs
const double kSaveModalHeight = 160.0;

/// Math helpers for card flip animations
const double kHalfPi = pi / 2;
const double kTwoPI = pi * 2;

/// Menu layout
const double kMenuCloseButtonSpacing = UiModal.closeButtonSpacing;
const double kCloseButtonWidth = UiTargetSize.closeButtonWidth;

/// Image cache heights
const int kMonsterImageCacheHeight = 75;   // cache height for monster list-tile images
const int kCharacterIconCacheHeight = 80;  // cache height for character class icon images

/// Screen breakpoints (shortest dimension compared against orientation-corrected value)
const double kPhoneScreenMaxDimension = UiBreakpoints.phoneMaxDimension;
const double kLargeTabletMinDimension =
    UiBreakpoints.largeTabletMinDimension;

/// Modal menu scale factors
const double kModalScaleTablet = 1.5;
const double kModalScaleLargeTablet = 2.0;

/// Modal background opacity
const double kModalBackgroundOpacity = 0.8;

/// Dialog inset padding
const double kDialogInsetPadding = 18;

// Static TextStyles (no scale factor — use as-is or pass to style: parameter)
const TextStyle kButtonLabelStyle = UiTypography.buttonLabel;
const TextStyle kTitleStyle = UiTypography.title;
const TextStyle kHeadingStyle = UiTypography.heading;
const TextStyle kBodyStyle = UiTypography.body;
const TextStyle kSubtitleStyle = UiTypography.small;
const TextStyle kBodyBlackStyle = UiTypography.bodyBlack;
