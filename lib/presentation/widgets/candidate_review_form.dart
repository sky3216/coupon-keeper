import 'package:flutter/material.dart';

import '../../domain/pass_candidate.dart';
import '../theme/app_theme.dart';
import 'source_image_preview.dart';

class CandidateReviewForm extends StatefulWidget {
  const CandidateReviewForm({
    required this.candidate,
    required this.currentIndex,
    required this.totalCount,
    required this.onChanged,
    required this.onSave,
    required this.onReject,
    required this.onManualRegistration,
    super.key,
  });

  final PassCandidate candidate;
  final int currentIndex;
  final int totalCount;
  final void Function({
    required String title,
    required String? brand,
    required int? estimatedValue,
    required DateTime? confirmedExpiry,
  })
  onChanged;
  final Future<void> Function() onSave;
  final VoidCallback onReject;
  final VoidCallback onManualRegistration;

  @override
  State<CandidateReviewForm> createState() => _CandidateReviewFormState();
}

class _CandidateReviewFormState extends State<CandidateReviewForm> {
  late final TextEditingController _title;
  late final TextEditingController _brand;
  late final TextEditingController _value;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.candidate.title);
    _brand = TextEditingController(text: widget.candidate.brand);
    _value = TextEditingController(
      text: widget.candidate.estimatedValue?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _brand.dispose();
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final candidate = widget.candidate;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label:
                '전체 후보 ${widget.totalCount}개 중 ${widget.currentIndex}번째 후보 검토 중',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '후보 ${widget.currentIndex}/${widget.totalCount}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: widget.currentIndex / widget.totalCount,
                  minHeight: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SourceImagePreview(source: candidate.source),
          const SizedBox(height: 24),
          _Field(
            controller: _title,
            label: '제목',
            needsReview: candidate.title.trim().isEmpty,
            onChanged: (value) => widget.onChanged(
              title: value,
              brand: candidate.brand,
              estimatedValue: candidate.estimatedValue,
              confirmedExpiry: candidate.confirmedExpiry,
            ),
          ),
          _Field(
            controller: _brand,
            label: '브랜드',
            needsReview: candidate.confidence.brand < 0.8,
            onChanged: (value) => widget.onChanged(
              title: candidate.title,
              brand: value,
              estimatedValue: candidate.estimatedValue,
              confirmedExpiry: candidate.confirmedExpiry,
            ),
          ),
          Text('만료일', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          if (candidate.expiryCandidates.length != 1 ||
              candidate.confirmedExpiry == null)
            const Text('인식된 날짜 중 하나를 선택해 주세요'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: candidate.expiryCandidates.map((expiry) {
              return ChoiceChip(
                label: Text(_date(expiry.date)),
                selected: candidate.confirmedExpiry == expiry.date,
                onSelected: (_) => widget.onChanged(
                  title: candidate.title,
                  brand: candidate.brand,
                  estimatedValue: candidate.estimatedValue,
                  confirmedExpiry: expiry.date,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _Field(
            controller: _value,
            label: '금액',
            needsReview: candidate.confidence.value < 0.8,
            keyboardType: TextInputType.number,
            onChanged: (value) => widget.onChanged(
              title: candidate.title,
              brand: candidate.brand,
              estimatedValue: int.tryParse(value),
              confirmedExpiry: candidate.confirmedExpiry,
            ),
          ),
          if (candidate.barcodeNumericCandidates.isNotEmpty) ...[
            Text('바코드 후보', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(candidate.barcodeNumericCandidates.join(', ')),
            const SizedBox(height: 16),
          ],
          Semantics(
            label: candidate.isSaveReady
                ? '이 쿠폰 저장'
                : '제목 또는 브랜드와 만료일을 확인하면 저장할 수 있습니다',
            button: true,
            enabled: candidate.isSaveReady,
            child: FilledButton(
              onPressed: candidate.isSaveReady
                  ? () async {
                      await widget.onSave();
                    }
                  : null,
              child: const Text('이 쿠폰 저장'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: widget.onReject, child: const Text('쿠폰 아님')),
          TextButton(
            onPressed: widget.onManualRegistration,
            child: const Text('직접 등록'),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.needsReview,
    required this.onChanged,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final bool needsReview;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: label,
          suffix: needsReview
              ? const Text(
                  '확인 필요',
                  style: TextStyle(color: AppTheme.warning, fontSize: 13),
                )
              : null,
        ),
      ),
    );
  }
}

String _date(DateTime value) {
  return '${value.year}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';
}
