import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';

class SplitPdfState {
  final File? selectedFile;
  final int totalPages;
  final Set<int> selectedPages;
  final bool isLoading;

  SplitPdfState({
    this.selectedFile,
    this.totalPages = 0,
    this.selectedPages = const {},
    this.isLoading = false,
  });

  SplitPdfState copyWith({
    File? selectedFile,
    int? totalPages,
    Set<int>? selectedPages,
    bool? isLoading,
  }) {
    return SplitPdfState(
      selectedFile: selectedFile ?? this.selectedFile,
      totalPages: totalPages ?? this.totalPages,
      selectedPages: selectedPages ?? this.selectedPages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SplitPdfNotifier extends Notifier<SplitPdfState> {
  @override
  SplitPdfState build() {
    return SplitPdfState();
  }

  Future<void> pickPdf() async {
    try {
      if (kDebugMode) {
        print(" [PICKER] STEP 1: Opening storage...");
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.single.path == null) {
        if (kDebugMode) {
          print("[PICKER] Canceled.");
        }
        return;
      }

      if (!result.files.single.name.toLowerCase().endsWith('.pdf')) {
        if (kDebugMode) {
          print(" [PICKER] ERROR: Not a PDF.");
        }
        return;
      }

      state = state.copyWith(isLoading: true);

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final pagesCount = document.pages.count;
      document.dispose();

      if (kDebugMode) {
        print(" [PICKER] Success! PDF loaded. Total pages: $pagesCount");
      }

      state = state.copyWith(
        selectedFile: file,
        totalPages: pagesCount,
        selectedPages: {},
        isLoading: false,
      );
    } catch (e) {
      if (kDebugMode) {
        print(" [PICKER] ERROR: $e");
      }
      state = state.copyWith(isLoading: false);
    }
  }


  void togglePageSelection(int pageIndex) {
    final currentSelection = Set<int>.from(state.selectedPages);

    if (currentSelection.contains(pageIndex)) {
      currentSelection.remove(pageIndex);
    } else {
      currentSelection.add(pageIndex);
    }

    state = state.copyWith(selectedPages: currentSelection);
  }

  Future<List<String>> splitSelectedPagesIntoSingleFiles() async {
    if (state.selectedFile == null || state.selectedPages.isEmpty) return [];

    try {
      state = state.copyWith(isLoading: true);

      final bytes = await state.selectedFile!.readAsBytes();
      final originalDoc = PdfDocument(inputBytes: bytes);
      final directory = await getApplicationDocumentsDirectory();

      List<String> savedFilePaths = [];

      for (int pageIndex in state.selectedPages) {
        final newDoc = PdfDocument();
        newDoc.pages.add().graphics.drawPdfTemplate(
          originalDoc.pages[pageIndex].createTemplate(),
          const Offset(0, 0),
        );

        final List<int> newBytes = await newDoc.save();
        final File newFile = File('${directory.path}/split_page_${pageIndex + 1}.pdf');
        await newFile.writeAsBytes(newBytes);
        newDoc.dispose();

        savedFilePaths.add(newFile.path);
      }

      originalDoc.dispose();
      state = state.copyWith(isLoading: false);

      return savedFilePaths;

    } catch (e) {
      if (kDebugMode) {
        print(" [SPLIT] ERROR: $e");
      }
      state = state.copyWith(isLoading: false);
      return [];
    }
  }
}

final splitPdfProvider = NotifierProvider<SplitPdfNotifier, SplitPdfState>(() {
  return SplitPdfNotifier();
});