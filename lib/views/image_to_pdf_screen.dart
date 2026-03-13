import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/image_to_pdf_provider.dart';

class ImageToPdfScreen extends ConsumerStatefulWidget {
  const ImageToPdfScreen({super.key});

  @override
  ConsumerState<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends ConsumerState<ImageToPdfScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final state = ref.read(imageToPdfProvider);
      if (state.selectedImages.isEmpty) {
        await ref.read(imageToPdfProvider.notifier).pickImages();
        if (ref.read(imageToPdfProvider).selectedImages.isEmpty && mounted) {
          Navigator.pop(context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(imageToPdfProvider);
    final notifier = ref.read(imageToPdfProvider.notifier);

    const Color primaryColor = Color(0xFFD32F2F);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black87),
          onPressed: () {
            notifier.clearAll();
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Image to PDF",
          style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        actions: [
          if (state.selectedImages.isNotEmpty && state.generatedPdf == null)
            TextButton.icon(
              onPressed: () => notifier.pickImages(),
              icon: const Icon(LucideIcons.plus, color: primaryColor, size: 18),
              label: Text("Add", style: GoogleFonts.poppins(color: primaryColor, fontWeight: FontWeight.bold)),
            )
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: state.isLoading
            ? _buildLoadingState(primaryColor)
            : (state.selectedImages.isEmpty
            ? const SizedBox.shrink()
            : _buildWorkspace(context, state, notifier, primaryColor)),
      ),
    );
  }

  Widget _buildLoadingState(Color primaryColor) {
    return Center(
      key: const ValueKey("loading_state"),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: primaryColor.withOpacity(0.08), shape: BoxShape.circle),
            child: const CircularProgressIndicator(color: Color(0xFFD32F2F)),
          ),
          const SizedBox(height: 24),
          Text(
            "Stitching Pages Together...\nCreating your document.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.w500, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspace(BuildContext context, ImageToPdfState state, ImageToPdfNotifier notifier, Color primaryColor) {
    return SingleChildScrollView(
      key: const ValueKey("workspace_state"),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
              return Stack(
                alignment: Alignment.topCenter,
                children: <Widget>[
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            child: state.generatedPdf != null
                ? _buildSuccessView(state, primaryColor, notifier)
                : _buildImageGridBuilder(state, notifier, primaryColor),
          ),

          const SizedBox(height: 60),
          Center(
            child: Opacity(
              opacity: 0.85,
              child: Image.asset(
                'assets/splash.png',
                height: 180,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildImageGridBuilder(ImageToPdfState state, ImageToPdfNotifier notifier, Color primaryColor) {
    return Column(
      key: const ValueKey("image_grid"),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${state.selectedImages.length} Images Selected",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
            ),
            Text(
              "Each image is 1 page",
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // The Image Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1, // Square thumbnails
          ),
          itemCount: state.selectedImages.length,
          itemBuilder: (context, index) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(state.selectedImages[index].path),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Delete Button on each thumbnail
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => notifier.removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(LucideIcons.x, color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () => notifier.convertToPdf(),
          icon: const Icon(LucideIcons.fileOutput, color: Colors.white, size: 20),
          label: Text("Convert to PDF", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView(ImageToPdfState state, Color primaryColor, ImageToPdfNotifier notifier) {
    return Column(
      key: const ValueKey("success_view"),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.shade200, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.green.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                child: Icon(LucideIcons.checkCircle2, color: Colors.green.shade600, size: 40),
              ),
              const SizedBox(height: 16),
              Text("PDF Generated!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green.shade800)),
              const SizedBox(height: 8),
              Text(
                "Combined ${state.selectedImages.length} images into one file.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => Share.shareXFiles([XFile(state.generatedPdf!.path)]),
          icon: const Icon(LucideIcons.share2, color: Colors.white),
          label: Text("Share PDF Document", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            notifier.clearAll();
            notifier.pickImages();
          },
          child: Text("Create another PDF", style: GoogleFonts.poppins(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
        )
      ],
    );
  }
}