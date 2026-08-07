//for use with ColorFiltered widget

import 'package:flutter/widgets.dart';

/// Wraps [child] in a grayscale [ColorFiltered] only when [grayedOut] is true.
///
/// Do not substitute an identity matrix for the "normal" case: ColorFiltered
/// allocates an offscreen save layer regardless of the matrix, so an identity
/// filter costs a full extra render pass per widget for no visual difference.
Widget grayScaleIf({required bool grayedOut, required Widget child}) {
  if (!grayedOut) {
    return child;
  }
  return ColorFiltered(
      colorFilter: const ColorFilter.matrix(grayScale), child: child);
}

const List<double> grayScale = [
//R  G   B    A  Const
  0.2126, 0.59, 0.11, 0, 0, //
  0.2126, 0.59, 0.11, 0, 0, //
  0.2126, 0.59, 0.11, 0, 0, //
  0, 0, 0, 1, 0, //
];

const List<double> grayScale2 = [
//R  G   B    A  Const
  0.33, 0.7152, 0.0722, 0, 0, //
  0.33, 0.7152, 0.0722, 0, 0, //
  0.33, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
];

const List<double> identity = [
//R  G   B    A  Const
  1, 0, 0, 0, 0, //
  0, 1, 0, 0, 0, //
  0, 0, 1, 0, 0, //
  0, 0, 0, 1, 0, //
];

const List<double> inverse = [
//R  G   B    A  Const
  -1, 0, 0, 0, 255, //
  0, -1, 0, 0, 255, //
  0, 0, -1, 0, 255, //
  0, 0, 0, 1, 0, //
];

const List<double> sepia = [
//R  G   B    A  Const
  0.393, 0.769, 0.189, 0, 0, //
  0.349, 0.686, 0.168, 0, 0, //
  0.272, 0.534, 0.131, 0, 0, //
  0, 0, 0, 1, 0, //
];

const Map<String, List<double>> colorFilters = {
  'Identity': [
    //R  G   B    A  Const
    1, 0, 0, 0, 0, //
    0, 1, 0, 0, 0, //
    0, 0, 1, 0, 0, //
    0, 0, 0, 1, 0, //
  ],
  'Grey Scale': [
    //R  G   B    A  Const
    0.33, 0.59, 0.11, 0, 0, //
    0.33, 0.59, 0.11, 0, 0, //
    0.33, 0.59, 0.11, 0, 0, //
    0, 0, 0, 1, 0, //
  ],
  'Inverse': [
    //R  G   B    A  Const
    -1, 0, 0, 0, 255, //
    0, -1, 0, 0, 255, //
    0, 0, -1, 0, 255, //
    0, 0, 0, 1, 0, //
  ],
  'Sepia': [
    //R  G   B    A  Const
    0.393, 0.769, 0.189, 0, 0, //
    0.349, 0.686, 0.168, 0, 0, //
    0.272, 0.534, 0.131, 0, 0, //
    0, 0, 0, 1, 0, //
  ],
};
