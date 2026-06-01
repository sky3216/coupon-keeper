class OcrBounds {
  const OcrBounds({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  factory OcrBounds.fromMap(Map<Object?, Object?> map) {
    return OcrBounds(
      left: _number(map['left']),
      top: _number(map['top']),
      width: _number(map['width']),
      height: _number(map['height']),
    );
  }
}

class OcrTextLine {
  const OcrTextLine({
    required this.text,
    required this.bounds,
    this.confidence,
  });

  final String text;
  final OcrBounds bounds;
  final double? confidence;

  factory OcrTextLine.fromMap(Map<Object?, Object?> map) {
    return OcrTextLine(
      text: map['text'] as String,
      bounds: OcrBounds.fromMap(map['bounds'] as Map<Object?, Object?>),
      confidence: _nullableNumber(map['confidence']),
    );
  }
}

class OcrTextBlock {
  const OcrTextBlock({
    required this.text,
    required this.bounds,
    required this.lines,
    this.confidence,
  });

  final String text;
  final OcrBounds bounds;
  final List<OcrTextLine> lines;
  final double? confidence;

  factory OcrTextBlock.fromMap(Map<Object?, Object?> map) {
    return OcrTextBlock(
      text: map['text'] as String,
      bounds: OcrBounds.fromMap(map['bounds'] as Map<Object?, Object?>),
      lines: (map['lines'] as List<Object?>)
          .map((line) => OcrTextLine.fromMap(line as Map<Object?, Object?>))
          .toList(growable: false),
      confidence: _nullableNumber(map['confidence']),
    );
  }
}

class OcrTextResult {
  const OcrTextResult({required this.fullText, required this.blocks});

  const OcrTextResult.empty() : this(fullText: '', blocks: const []);

  final String fullText;
  final List<OcrTextBlock> blocks;

  bool get isEmpty => fullText.trim().isEmpty && blocks.isEmpty;

  factory OcrTextResult.fromMap(Map<Object?, Object?> map) {
    return OcrTextResult(
      fullText: map['fullText'] as String,
      blocks: (map['blocks'] as List<Object?>)
          .map((block) => OcrTextBlock.fromMap(block as Map<Object?, Object?>))
          .toList(growable: false),
    );
  }
}

double _number(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  throw const FormatException('Expected a numeric OCR value.');
}

double? _nullableNumber(Object? value) {
  return value == null ? null : _number(value);
}
