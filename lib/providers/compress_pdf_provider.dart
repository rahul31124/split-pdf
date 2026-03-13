import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_compressor/pdf_compressor.dart';
enum CompressionLevel { low, medium, high }

class CompressPdfState {
  final File? selectedFile;
  final File? compressedFile;
  final double originalSizeMb;
  final double compressedSizeMb;
  final CompressionLevel selectedLevel;
  final bool isLoading;

  CompressPdfState({
    this.selectedFile,
    this.compressedFile,
    this.originalSizeMb = 0.0,
    this.compressedSizeMb = 0.0,
    this.selectedLevel = CompressionLevel.medium,
    this.isLoading = false,
  });

  CompressPdfState copyWith({
    File? selectedFile,
    File? compressedFile,
    double? originalSizeMb,
    double? compressedSizeMb,
    CompressionLevel? selectedLevel,
    bool? isLoading,
  }) {
    return CompressPdfState(
      selectedFile: selectedFile ?? this.selectedFile,
      compressedFile: compressedFile ?? this.compressedFile,
      originalSizeMb: originalSizeMb ?? this.originalSizeMb,
      compressedSizeMb: compressedSizeMb ?? this.compressedSizeMb,
      selectedLevel: selectedLevel ?? this.selectedLevel,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CompressPdfNotifier extends Notifier<CompressPdfState> {
  @override
  CompressPdfState build() => CompressPdfState();
  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final bytes = await file.length();
      final sizeMb = bytes / (1024 * 1024);

      state = state.copyWith(
        selectedFile: file,
        originalSizeMb: sizeMb,
        compressedFile: null,
        compressedSizeMb: 0.0,
      );
    }
  }

  void setCompressionLevel(CompressionLevel level) {
    state = state.copyWith(selectedLevel: level);
  }
  Future<void> compressPdf() async {
    if (state.selectedFile == null) return;

    try {
      state = state.copyWith(isLoading: true);


      final directory = await getApplicationDocumentsDirectory();
      final outputPath = '${directory.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.pdf';

      CompressQuality quality;
      switch (state.selectedLevel) {
        case CompressionLevel.low:
          quality = CompressQuality.LOW;
          break;
        case CompressionLevel.medium:
          quality = CompressQuality.MEDIUM;
          break;
        case CompressionLevel.high:
          quality = CompressQuality.HIGH;
          break;
      }

      await PdfCompressor.compressPdfFile(
        state.selectedFile!.path,
        outputPath,
        quality,
      );

      final compressedFile = File(outputPath);
      final bytes = await compressedFile.length();
      final compressedSizeMb = bytes / (1024 * 1024);

      state = state.copyWith(
        compressedFile: compressedFile,
        compressedSizeMb: compressedSizeMb,
        isLoading: false,
      );
    } catch (e) {
      if (kDebugMode) {
        print(" COMPRESSION ERROR: $e");
      }
      state = state.copyWith(isLoading: false);
    }
  }
}

final compressPdfProvider = NotifierProvider<CompressPdfNotifier, CompressPdfState>(() {
  return CompressPdfNotifier();
});