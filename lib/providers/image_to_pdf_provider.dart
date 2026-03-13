import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ImageToPdfState {
  final bool isLoading;
  final List<XFile> selectedImages;
  final File? generatedPdf;

  ImageToPdfState({
    this.isLoading = false,
    this.selectedImages = const [],
    this.generatedPdf,
  });

  ImageToPdfState copyWith({
    bool? isLoading,
    List<XFile>? selectedImages,
    File? generatedPdf,
  }) {
    return ImageToPdfState(
      isLoading: isLoading ?? this.isLoading,
      selectedImages: selectedImages ?? this.selectedImages,
      generatedPdf: generatedPdf ?? this.generatedPdf,
    );
  }
}

class ImageToPdfNotifier extends Notifier<ImageToPdfState> {
  final ImagePicker _picker = ImagePicker();

  @override
  ImageToPdfState build() {
    return ImageToPdfState();
  }

  Future<void> pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
      );

      if (images.isNotEmpty) {
        state = state.copyWith(
          selectedImages: [...state.selectedImages, ...images],
          generatedPdf: null,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error picking images: $e");
      }
    }
  }

  void removeImage(int index) {
    final updatedList = List<XFile>.from(state.selectedImages);
    updatedList.removeAt(index);
    state = state.copyWith(selectedImages: updatedList, generatedPdf: null);
  }

  void clearAll() {
    state = ImageToPdfState();
  }

  Future<void> convertToPdf() async {
    if (state.selectedImages.isEmpty) return;

    state = state.copyWith(isLoading: true);

    try {
      final PdfDocument document = PdfDocument();
      document.pageSettings.size = PdfPageSize.a4;
      document.pageSettings.margins.all = 0;

      for (var img in state.selectedImages) {
        final List<int> imageBytes = await img.readAsBytes();
        final PdfBitmap pdfImage = PdfBitmap(imageBytes);
        final PdfPage page = document.pages.add();

        final Size pageSize = page.getClientSize();
        final double imageRatio = pdfImage.width / pdfImage.height;
        final double pageRatio = pageSize.width / pageSize.height;

        double drawWidth, drawHeight;
        if (imageRatio > pageRatio) {
          drawWidth = pageSize.width;
          drawHeight = pageSize.width / imageRatio;
        } else {
          drawHeight = pageSize.height;
          drawWidth = pageSize.height * imageRatio;
        }

        final double x = (pageSize.width - drawWidth) / 2;
        final double y = (pageSize.height - drawHeight) / 2;

        page.graphics.drawImage(pdfImage, Rect.fromLTWH(x, y, drawWidth, drawHeight));
      }

      final List<int> pdfBytes = await document.save();
      document.dispose();

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final pdfFile = File('${tempDir.path}/Scanned_Document_$timestamp.pdf');

      await pdfFile.writeAsBytes(pdfBytes);

      state = state.copyWith(
        isLoading: false,
        generatedPdf: pdfFile,
      );
    } catch (e) {
      if (kDebugMode) {
        print("Conversion failed: $e");
      }
      state = state.copyWith(isLoading: false);
    }
  }
}

final imageToPdfProvider = NotifierProvider<ImageToPdfNotifier, ImageToPdfState>(() {
  return ImageToPdfNotifier();
});