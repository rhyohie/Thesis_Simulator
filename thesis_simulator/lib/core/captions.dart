/// Plain-language text shown in the processing panel.
class Captions {
  static const String prepare =
      'The photo is turned into exactly the numbers the model was trained on: shrunk to '
      '60×60 (as in the baseline study), enlarged to 224×224, and every pixel value '
      'divided by 255 so it falls between 0 and 1. The enlargement adds no new detail.';

  static const String insideUnit =
      'Inside every convolution unit: convolution → batch normalization → ReLU. '
      'Batch normalization rescales the values to a steady range (at prediction time it '
      'uses averages saved during training). ReLU sets negative values to zero.';

  static const String insideUnitPlain =
      'Inside every convolution unit of this model: convolution → ReLU (there is no batch normalization). '
      'ReLU sets negative values to zero, so a detector that is never switched on shows as an inactive, '
      'all-zero map.';

  static const List<String> blocks = [
    'Block 1 · 2 convolutions. Small 3×3 detectors slide over the image and produce '
        'feature maps. Early layers typically respond to simple things like edges and '
        'colors. Pooling then halves the width and height.',
    'Block 2 · 2 convolutions. Detectors combine the simple patterns from block 1 '
        'into slightly larger ones. The maps get smaller while the number of maps grows.',
    'Block 3 · 2 convolutions. Layers here typically respond to textures and parts of '
        'shapes.',
    'Block 4 · 3 convolutions. Maps are now 14×14, so each pixel summarizes a large '
        'patch of the photo.',
    'Block 5 · 2 convolutions. The last maps are 7×7, one for each of 512 learned '
        'features. Each map says where in the image that feature appears.',
  ];

  static const String blocksNote =
      'Each small square is one feature map: the output of one learned detector. The 16 maps with the '
      'most visible pattern are drawn (the number under each map is its channel number). Colors go from '
      'dark blue (low) through green to yellow (high). Yellow only means "strong response here"; it does '
      'not mean a disease was found.';

  static const String scaleContrast =
      'Contrast each map: every map is stretched from its own lowest to its own highest value, so even a '
      'weak detector shows a pattern. A map that responds about equally over a large area (for example a '
      'plain pod surface) can look mostly yellow.';

  static const String scaleShared =
      'Same scale for all maps: one scale for the whole block, so strong maps look yellow and weak maps stay '
      'dark. A map labelled "inactive" outputs zero everywhere.';

  static const String average =
      'Global average pooling squeezes each 7×7 map into a single number: its average. '
      'The 512 maps become 512 numbers, each saying roughly how strongly one learned '
      'feature appears anywhere in the image. It has no weights of its own and it '
      'discards where the feature was.';

  static String classify(int total, String label) =>
      'Each class has its own weight for every one of the $total ${label}s (the numbers produced '
      'just before this step). A class score is the sum of weight × number over all $total, plus '
      'a bias. Softmax then turns the three scores into probabilities that add up to 1, and the '
      'largest wins.';

  static const String head =
      'This model has no global average pooling. The last 7×7×512 map is laid out as one long '
      'list of 25,088 numbers and passed through two dense layers of 4096 units each. The bars '
      'show each layer\'s activations (grouped, so many units share one bar). A unit that is '
      'inactive outputs exactly zero.';

  static const String evidence =
      'Because the model ends with average pooling followed by one dense layer, we can '
      'rebuild a map of where a class got its evidence: weight each of the 512 maps by '
      'that class\'s weights and add them up. The map is only 7×7, so it is coarse. It '
      'shows where the model found evidence, not proof that the model is right.';
}
