import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;
import 'package:pdfx/pdfx.dart' as pdfx;

class DeletePagesState {
  final bool isLoading;
  final File? selectedFile;
  final int totalPages;
  final Set<int> selectedPagesToDelete;
  final File? generatedPdf;
  final List<Uint8List> pageThumbnails;

  DeletePagesState({
    this.isLoading = false,
    this.selectedFile,
    this.totalPages = 0,
    this.selectedPagesToDelete = const {},
    this.generatedPdf,
    this.pageThumbnails = const [],
  });

  DeletePagesState copyWith({
    bool? isLoading,
    File? selectedFile,
    int? totalPages,
    Set<int>? selectedPagesToDelete,
    File? generatedPdf,
    List<Uint8List>? pageThumbnails,
  }) {
    return DeletePagesState(
      isLoading: isLoading ?? this.isLoading,
      selectedFile: selectedFile ?? this.selectedFile,
      totalPages: totalPages ?? this.totalPages,
      selectedPagesToDelete: selectedPagesToDelete ?? this.selectedPagesToDelete,
      generatedPdf: generatedPdf ?? this.generatedPdf,
      pageThumbnails: pageThumbnails ?? this.pageThumbnails,
    );
  }
}

class DeletePagesNotifier extends Notifier<DeletePagesState> {
  @override
  DeletePagesState build() {
    return DeletePagesState();
  }

  Future<void> pickPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        state = state.copyWith(isLoading: true);

        final file = File(result.files.single.path!);

        final pdfxDoc = await pdfx.PdfDocument.openFile(file.path);
        final pageCount = pdfxDoc.pagesCount;

        List<Uint8List> thumbnails = [];

        for (int i = 1; i <= pageCount; i++) {
          final page = await pdfxDoc.getPage(i);
          final render = await page.render(
            width: 300,
            height: 300 / (page.width / page.height),
            format: pdfx.PdfPageImageFormat.jpeg,
          );
          if (render != null) {
            thumbnails.add(render.bytes);
          }
          await page.close();
        }
        await pdfxDoc.close();

        state = state.copyWith(
          isLoading: false,
          selectedFile: file,
          totalPages: pageCount,
          selectedPagesToDelete: {},
          generatedPdf: null,
          pageThumbnails: thumbnails,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error picking/rendering PDF: $e");
      }
      state = state.copyWith(isLoading: false);
    }
  }

  void togglePageSelection(int pageIndex) {
    final updatedSelection = Set<int>.from(state.selectedPagesToDelete);
    if (updatedSelection.contains(pageIndex)) {
      updatedSelection.remove(pageIndex);
    } else {
      updatedSelection.add(pageIndex);
    }
    state = state.copyWith(selectedPagesToDelete: updatedSelection);
  }

  void resetAll() {
    state = DeletePagesState();
  }

  Future<void> processPdf() async {
    if (state.selectedFile == null || state.selectedPagesToDelete.isEmpty) return;

    state = state.copyWith(isLoading: true);

    try {
      final bytes = await state.selectedFile!.readAsBytes();
      // --- MODIFY PDF USING SYNCFUSION ---
      final document = syncfusion.PdfDocument(inputBytes: bytes);

      // We MUST sort in reverse order, otherwise deleting page 1 shifts page 2 down to index 1, breaking everything
      final List<int> pagesToRemove = state.selectedPagesToDelete.toList()
        ..sort((a, b) => b.compareTo(a));

      for (int index in pagesToRemove) {
        document.pages.removeAt(index);
      }

      final List<int> modifiedBytes = await document.save();
      document.dispose();

      final tempDir = await getTemporaryDirectory();
      final originalName = state.selectedFile!.path.split('/').last.replaceAll('.pdf', '');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newFile = File('${tempDir.path}/${originalName}_Edited_$timestamp.pdf');

      await newFile.writeAsBytes(modifiedBytes);

      state = state.copyWith(
        isLoading: false,
        generatedPdf: newFile,
      );
    } catch (e) {
      if (kDebugMode) {
        print("Error deleting pages: $e");
      }
      state = state.copyWith(isLoading: false);
    }
  }
}

final deletePagesProvider = NotifierProvider<DeletePagesNotifier, DeletePagesState>(() {
  return DeletePagesNotifier();
});