import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

import '../providers/split_pdf_provider.dart';
import 'SuccessPreviewScreen.dart';

class SplitPdfScreen extends ConsumerStatefulWidget {
  const SplitPdfScreen({super.key});

  @override
  ConsumerState<SplitPdfScreen> createState() => _SplitPdfScreenState();
}

class _SplitPdfScreenState extends ConsumerState<SplitPdfScreen> {
  Future<pdfx.PdfDocument>? _pdfDocFuture;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final state = ref.read(splitPdfProvider);
      final notifier = ref.read(splitPdfProvider.notifier);

      if (state.selectedFile == null) {
        await notifier.pickPdf();

        if (ref.read(splitPdfProvider).selectedFile == null && mounted) {
          Navigator.pop(context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(splitPdfProvider);


    if (state.selectedFile != null && _pdfDocFuture == null) {
      _pdfDocFuture = pdfx.PdfDocument.openFile(state.selectedFile!.path);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Extract Pages (Split)",
          style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: _buildBody(state),

      bottomNavigationBar: state.selectedPages.isEmpty
          ? const SizedBox.shrink()
          : _buildBottomActionBar(state),
    );
  }

  Widget _buildBody(SplitPdfState state) {
    if (state.isLoading) {
      return _buildLoadingState("Processing PDF...");
    }

    if (state.selectedFile == null || _pdfDocFuture == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(10)),
                child: const Icon(LucideIcons.layers, color: Color(0xFFD32F2F), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Select Pages", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                    Text("Tap the pages you want to extract.", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: FutureBuilder<pdfx.PdfDocument>(
            future: _pdfDocFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState("Rendering pages...");
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}", style: GoogleFonts.poppins(color: Colors.red)));
              }
              if (!snapshot.hasData) {
                return const Center(child: Text("No data found in PDF"));
              }

              final pdfDoc = snapshot.data!;

              return GridView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.7,
                ),
                itemCount: state.totalPages,
                itemBuilder: (context, index) {
                  final isSelected = state.selectedPages.contains(index);

                  return GestureDetector(
                    onTap: () => ref.read(splitPdfProvider.notifier).togglePageSelection(index),
                    child: _PdfThumbnailCell(
                      document: pdfDoc,
                      pageIndex: index,
                      isSelected: isSelected,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(SplitPdfState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Selected", style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
                Text("${state.selectedPages.length} Pages", style: GoogleFonts.poppins(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final savedPaths = await ref.read(splitPdfProvider.notifier).splitSelectedPagesIntoSingleFiles();
                if (savedPaths.isNotEmpty && mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => SuccessPreviewScreen(filePaths: savedPaths)),
                  );
                }
              },
              icon: const Icon(LucideIcons.scissors, color: Colors.white, size: 20),
              label: Text("Extract", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFFD32F2F)),
          const SizedBox(height: 20),
          Text(message, style: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}


class _PdfThumbnailCell extends StatefulWidget {
  final pdfx.PdfDocument document;
  final int pageIndex;
  final bool isSelected;

  const _PdfThumbnailCell({
    required this.document,
    required this.pageIndex,
    required this.isSelected,
  });

  @override
  State<_PdfThumbnailCell> createState() => _PdfThumbnailCellState();
}

class _PdfThumbnailCellState extends State<_PdfThumbnailCell> {
  Uint8List? _imageBytes;
  bool _hasError = false;
  static bool _isRendering = false;

  @override
  void initState() {
    super.initState();
    _renderThumbnail();
  }

  Future<void> _renderThumbnail() async {
    while (_isRendering) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    try {
      _isRendering = true;
      await Future.delayed(const Duration(milliseconds: 10));

      final page = await widget.document.getPage(widget.pageIndex + 1);
      final pageImage = await page.render(
        width: page.width / 2,
        height: page.height / 2,
        format: pdfx.PdfPageImageFormat.jpeg,
        quality: 40,
      );

      if (mounted && pageImage != null) {
        setState(() {
          _imageBytes = pageImage.bytes;
          _hasError = false;
        });
      }
      await page.close();
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      _isRendering = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: widget.isSelected
            ? [BoxShadow(color: const Color(0xFFD32F2F).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))]
            : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(
          color: widget.isSelected ? const Color(0xFFD32F2F) : Colors.transparent,
          width: 3,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.white),
            if (_imageBytes != null)
              Image.memory(_imageBytes!, fit: BoxFit.cover)
            else if (_hasError)
              const Center(child: Icon(LucideIcons.alertCircle, color: Colors.red))
            else
              const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD32F2F))),

            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
                child: Text(
                  "PAGE ${widget.pageIndex + 1}",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                ),
              ),
            ),

            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: widget.isSelected ? 1.0 : 0.0,
              child: Container(
                color: const Color(0xFFD32F2F).withOpacity(0.2),
                child: const Center(
                  child: Icon(LucideIcons.checkCircle2, color: Color(0xFFD32F2F), size: 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}