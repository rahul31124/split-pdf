import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class LockPdfState {
  final bool isLoading;
  final File? selectedFile;
  final File? lockedFile;

  LockPdfState({
    this.isLoading = false,
    this.selectedFile,
    this.lockedFile,
  });

  LockPdfState copyWith({
    bool? isLoading,
    File? selectedFile,
    File? lockedFile,
  }) {
    return LockPdfState(
      isLoading: isLoading ?? this.isLoading,
      selectedFile: selectedFile ?? this.selectedFile,
      lockedFile: lockedFile ?? this.lockedFile,
    );
  }
}

class LockPdfNotifier extends Notifier<LockPdfState> {

  @override
  LockPdfState build() {
    return LockPdfState();
  }

  Future<void> pickPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        state = state.copyWith(
          selectedFile: File(result.files.single.path!),
          lockedFile: null,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error picking file: $e");
      }
    }
  }

  Future<void> lockPdfWithPassword(String password) async {
    if (state.selectedFile == null || password.isEmpty) return;

    state = state.copyWith(isLoading: true);

    try {
      final List<int> bytes = await state.selectedFile!.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      final PdfSecurity security = document.security;
      security.userPassword = password;
      security.ownerPassword = password;
      security.algorithm = PdfEncryptionAlgorithm.aesx256Bit;

      final List<int> lockedBytes = await document.save();
      document.dispose();

      final tempDir = await getTemporaryDirectory();
      final originalName = state.selectedFile!.path.split('/').last.replaceAll('.pdf', '');
      final lockedFile = File('${tempDir.path}/${originalName}_locked.pdf');

      await lockedFile.writeAsBytes(lockedBytes);

      state = state.copyWith(
        isLoading: false,
        lockedFile: lockedFile,
      );
    } catch (e) {
      if (kDebugMode) {
        print("Encryption failed: $e");
      }
      state = state.copyWith(isLoading: false);
    }
  }
}

final lockPdfProvider = NotifierProvider<LockPdfNotifier, LockPdfState>(() {
  return LockPdfNotifier();
});