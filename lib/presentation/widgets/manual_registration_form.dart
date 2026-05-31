import 'package:flutter/material.dart';

import '../../domain/scan_item.dart';
import 'source_image_preview.dart';

class ManualRegistrationForm extends StatefulWidget {
  const ManualRegistrationForm({
    required this.source,
    required this.onSave,
    required this.onCancel,
    super.key,
  });

  final ScanItem source;
  final Future<void> Function({
    required String title,
    required String? brand,
    required DateTime? expiry,
    int? estimatedValue,
  })
  onSave;
  final VoidCallback onCancel;

  @override
  State<ManualRegistrationForm> createState() => _ManualRegistrationFormState();
}

class _ManualRegistrationFormState extends State<ManualRegistrationForm> {
  final _title = TextEditingController();
  final _brand = TextEditingController();
  final _expiry = TextEditingController();
  final _value = TextEditingController();

  DateTime? get parsedExpiry {
    final match = RegExp(
      r'^(\d{4})[./-](\d{1,2})[./-](\d{1,2})$',
    ).firstMatch(_expiry.text);
    if (match == null) {
      return null;
    }
    final date = DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
    return date;
  }

  bool get isReady =>
      (_title.text.trim().isNotEmpty || _brand.text.trim().isNotEmpty) &&
      parsedExpiry != null;

  @override
  void dispose() {
    _title.dispose();
    _brand.dispose();
    _expiry.dispose();
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '쿠폰 정보를 직접 입력해 주세요',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          SourceImagePreview(source: widget.source),
          const SizedBox(height: 24),
          _input(_title, '제목'),
          _input(_brand, '브랜드'),
          _input(_expiry, '만료일', hint: '2026.06.30'),
          _input(_value, '금액', keyboardType: TextInputType.number),
          FilledButton(
            onPressed: isReady
                ? () async {
                    await widget.onSave(
                      title: _title.text,
                      brand: _brand.text.isEmpty ? null : _brand.text,
                      expiry: parsedExpiry,
                      estimatedValue: int.tryParse(_value.text),
                    );
                  }
                : null,
            child: const Text('쿠폰 저장'),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: widget.onCancel, child: const Text('취소')),
        ],
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String label, {
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: label,
          hintText: hint,
        ),
      ),
    );
  }
}
