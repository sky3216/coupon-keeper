enum ScanSourceType { photos, downloads }

extension ScanSourceTypeCopy on ScanSourceType {
  String get label {
    switch (this) {
      case ScanSourceType.photos:
        return '사진';
      case ScanSourceType.downloads:
        return '다운로드/파일';
    }
  }

  String get actionLabel {
    switch (this) {
      case ScanSourceType.photos:
        return '사진에서 찾기';
      case ScanSourceType.downloads:
        return '다운로드/파일에서 찾기';
    }
  }

  String get supportingCopy {
    switch (this) {
      case ScanSourceType.photos:
        return '사진 앱에서 직접 고른 항목만 확인해요.';
      case ScanSourceType.downloads:
        return '다운로드한 이미지나 폴더를 직접 고릅니다.';
    }
  }
}
