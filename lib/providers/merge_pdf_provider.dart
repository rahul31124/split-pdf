import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';

class MergePdfState {
  final List<File> selectedFiles;
  final bool isLoading;

  MergePdfState({this.selectedFiles = const [], this.isLoading = false});

  MergePdfState copyWith({List<File>? selectedFiles, bool? isLoading}) {
    return MergePdfState(
      selectedFiles: selectedFiles ?? this.selectedFiles,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MergePdfNotifier extends Notifier<MergePdfState> {
  @override
  MergePdfState build() => MergePdfState();

  Future<void> pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      final newFiles = result.paths.map((path) => File(path!)).toList();
      state = state.copyWith(
        selectedFiles: [...state.selectedFiles, ...newFiles],
      );
    }
  }

  void reorderFiles(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final files = List<File>.from(state.selectedFiles);
    final file = files.removeAt(oldIndex);
    files.insert(newIndex, file);

    state = state.copyWith(selectedFiles: files);
  }
  void removeFile(int index) {
    final files = List<File>.from(state.selectedFiles);
    files.removeAt(index);
    state = state.copyWith(selectedFiles: files);
  }

  Future<String?> mergePdfs() async {
    if (state.selectedFiles.length < 2) return null;

    state = state.copyWith(isLoading: true);
    final PdfDocument finalDoc = PdfDocument();

    try {
      for (File file in state.selectedFiles) {
        final List<int> bytes = await file.readAsBytes();
        final PdfDocument importedDoc = PdfDocument(inputBytes: bytes);

        for (int i = 0; i < importedDoc.pages.count; i++) {
          finalDoc.pages.add().graphics.drawPdfTemplate(
            importedDoc.pages[i].createTemplate(),
            const Offset(0, 0),
          );
        }
        importedDoc.dispose();
      }

      final List<int> outputBytes = await finalDoc.save();
      final directory = await getApplicationDocumentsDirectory();
      final String path = '${directory.path}/merged_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final File outputFile = File(path);
      await outputFile.writeAsBytes(outputBytes);

      finalDoc.dispose();
      state = state.copyWith(isLoading: false);

      return path;
    } catch (e) {
      if (kDebugMode) {
        print("MERGE ERROR: $e");
      }
      state = state.copyWith(isLoading: false);
      return null;
    }
  }
}

final mergePdfProvider = NotifierProvider<MergePdfNotifier, MergePdfState>(() => MergePdfNotifier());