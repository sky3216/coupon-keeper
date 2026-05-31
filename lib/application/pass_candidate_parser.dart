import '../domain/ocr_text.dart';
import '../domain/pass_candidate.dart';
import '../domain/pass_confidence.dart';
import '../domain/scan_item.dart';

class PassCandidateParser {
  const PassCandidateParser();

  PassCandidate? parse(ScanItem source, OcrTextResult result) {
    final lines = _meaningfulLines(result);
    if (lines.isEmpty) {
      return null;
    }

    final expiryCandidates = _expiryCandidates(lines);
    final valueCandidates = _valueCandidates(lines);
    final barcodeCandidates = _barcodeCandidates(lines);
    final descriptiveLines = lines
        .where((line) => !_isMachineReadable(line.text))
        .toList(growable: false);
    final title = descriptiveLines.isEmpty ? '' : descriptiveLines.first.text;
    final brand = _brand(descriptiveLines);

    return PassCandidate(
      source: source,
      ocrText: result.fullText,
      title: title,
      brand: brand?.text,
      estimatedValue: valueCandidates.isEmpty
          ? null
          : valueCandidates.first.value,
      valueCandidates: valueCandidates,
      expiryCandidates: expiryCandidates,
      confirmedExpiry: null,
      barcodeNumericCandidates: barcodeCandidates,
      confidence: PassConfidence(
        expiry: expiryCandidates.isEmpty
            ? 0
            : (expiryCandidates.first.confidence ?? 0),
        value: valueCandidates.isEmpty
            ? 0
            : (valueCandidates.first.confidence ?? 0),
        brand: brand?.confidence ?? 0,
        barcode: barcodeCandidates.isEmpty ? 0 : 0.7,
        overall: _averageConfidence(lines),
      ),
    );
  }
}

List<OcrTextLine> _meaningfulLines(OcrTextResult result) {
  final nestedLines = result.blocks.expand((block) => block.lines).toList();
  if (nestedLines.isNotEmpty) {
    return nestedLines.where((line) => line.text.trim().isNotEmpty).toList();
  }
  return result.fullText
      .split('\n')
      .map(
        (text) => OcrTextLine(
          text: text.trim(),
          bounds: const OcrBounds(left: 0, top: 0, width: 1, height: 0),
        ),
      )
      .where((line) => line.text.isNotEmpty)
      .toList();
}

List<ExpiryCandidate> _expiryCandidates(Iterable<OcrTextLine> lines) {
  final dates = <String, ExpiryCandidate>{};
  final numericPattern = RegExp(r'(\d{4})[./-](\d{1,2})[./-](\d{1,2})');
  final koreanPattern = RegExp(r'(\d{4})년\s*(\d{1,2})월\s*(\d{1,2})일');

  for (final line in lines) {
    for (final pattern in [numericPattern, koreanPattern]) {
      for (final match in pattern.allMatches(line.text)) {
        final date = _validDate(match.group(1), match.group(2), match.group(3));
        if (date != null) {
          dates.putIfAbsent(
            _dateKey(date),
            () => ExpiryCandidate(date: date, confidence: line.confidence),
          );
        }
      }
    }
  }
  return dates.values.toList(growable: false);
}

List<ValueCandidate> _valueCandidates(Iterable<OcrTextLine> lines) {
  final values = <int, ValueCandidate>{};
  final pattern = RegExp(r'(?:₩\s*)?(\d[\d,]*)\s*원');
  for (final line in lines) {
    for (final match in pattern.allMatches(line.text)) {
      final value = int.tryParse(match.group(1)!.replaceAll(',', ''));
      if (value != null) {
        values.putIfAbsent(
          value,
          () => ValueCandidate(value: value, confidence: line.confidence),
        );
      }
    }
  }
  return values.values.toList(growable: false);
}

List<String> _barcodeCandidates(Iterable<OcrTextLine> lines) {
  final values = <String>{};
  final pattern = RegExp(r'(?:\d[\s-]*){8,}');
  for (final line in lines) {
    for (final match in pattern.allMatches(line.text)) {
      final normalized = match.group(0)!.replaceAll(RegExp(r'\D'), '');
      if (normalized.length >= 8) {
        values.add(normalized);
      }
    }
  }
  return values.toList(growable: false);
}

OcrTextLine? _brand(List<OcrTextLine> lines) {
  for (final line in lines.skip(1)) {
    final match = RegExp(r'^(?:브랜드|상호)\s*[:：]\s*(.+)$').firstMatch(line.text);
    if (match != null) {
      return OcrTextLine(
        text: match.group(1)!.trim(),
        bounds: line.bounds,
        confidence: line.confidence,
      );
    }
  }
  return lines.length > 1 ? lines[1] : null;
}

bool _isMachineReadable(String value) {
  return RegExp(r'\d{4}[./-]\d{1,2}[./-]\d{1,2}').hasMatch(value) ||
      RegExp(r'\d{4}년\s*\d{1,2}월\s*\d{1,2}일').hasMatch(value) ||
      RegExp(r'(?:₩\s*)?\d[\d,]*\s*원').hasMatch(value) ||
      RegExp(r'(?:\d[\s-]*){8,}').hasMatch(value);
}

DateTime? _validDate(String? year, String? month, String? day) {
  final parsedYear = int.tryParse(year ?? '');
  final parsedMonth = int.tryParse(month ?? '');
  final parsedDay = int.tryParse(day ?? '');
  if (parsedYear == null || parsedMonth == null || parsedDay == null) {
    return null;
  }
  final date = DateTime(parsedYear, parsedMonth, parsedDay);
  if (date.year != parsedYear ||
      date.month != parsedMonth ||
      date.day != parsedDay) {
    return null;
  }
  return date;
}

String _dateKey(DateTime value) => '${value.year}-${value.month}-${value.day}';

double _averageConfidence(List<OcrTextLine> lines) {
  final known = lines
      .map((line) => line.confidence)
      .whereType<double>()
      .toList();
  if (known.isEmpty) {
    return 0;
  }
  return known.reduce((total, value) => total + value) / known.length;
}
