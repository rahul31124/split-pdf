import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/compress_pdf_provider.dart';

class CompressPdfScreen extends ConsumerWidget {
  const CompressPdfScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(compressPdfProvider);
    final notifier = ref.read(compressPdfProvider.notifier);

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
          "Compress PDF",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: state.isLoading
          ? _buildLoadingState()
          : (state.selectedFile == null
          ? _buildEmptyState(notifier)
          : _buildCompressionWorkspace(context, state, notifier)),
    );
  }

  Widget _buildEmptyState(CompressPdfNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.fileArchive, size: 64, color: Color(0xFFD32F2F)),
            ),
            const SizedBox(height: 24),
            Text(
              "Make PDFs Smaller",
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              "Compress your documents easily without losing crucial text quality. Perfect for email attachments.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => notifier.pickFile(),
              icon: const Icon(LucideIcons.uploadCloud, color: Colors.white),
              label: Text("Select PDF File", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE62222),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFFD32F2F)),
          const SizedBox(height: 24),
          Text(
            "Squeezing pixels...\nThis may take a moment.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.w500, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildCompressionWorkspace(BuildContext context, CompressPdfState state, CompressPdfNotifier notifier) {
    final double savingsMb = state.originalSizeMb - state.compressedSizeMb;
    final int savingsPercent = state.originalSizeMb > 0
        ? ((savingsMb / state.originalSizeMb) * 100).toInt()
        : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(LucideIcons.fileText, size: 28, color: Color(0xFFD32F2F)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.selectedFile!.path.split('/').last,
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Original Size: ${state.originalSizeMb.toStringAsFixed(2)} MB",
                                  style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          // Give user a way to change the file!
                          if (state.compressedFile == null)
                            IconButton(
                              icon: const Icon(LucideIcons.edit3, color: Colors.grey, size: 20),
                              onPressed: () => notifier.pickFile(),
                              tooltip: "Change File",
                            )
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    if (state.compressedFile != null) ...[
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
                            Text("Compression Successful!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green.shade800)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${state.compressedSizeMb.toStringAsFixed(2)} MB",
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 28, color: Colors.black87),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
                                  child: Text("-$savingsPercent%", style: GoogleFonts.poppins(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
                                )
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text("You saved ${savingsMb.toStringAsFixed(2)} MB", style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 14)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => Share.shareXFiles([XFile(state.compressedFile!.path)]),
                        icon: const Icon(LucideIcons.share2, color: Colors.white),
                        label: Text("Share Compressed PDF", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ] else ...[
                      Text("Compression Level", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      const SizedBox(height: 16),

                      _CompressionCard(
                        title: "Extreme Compression",
                        subtitle: "Smallest size, lowest quality text.",
                        isSelected: state.selectedLevel == CompressionLevel.low,
                        onTap: () => notifier.setCompressionLevel(CompressionLevel.low),
                      ),
                      const SizedBox(height: 12),
                      _CompressionCard(
                        title: "Balanced (Recommended)",
                        subtitle: "Good quality, medium file size.",
                        isSelected: state.selectedLevel == CompressionLevel.medium,
                        onTap: () => notifier.setCompressionLevel(CompressionLevel.medium),
                      ),
                      const SizedBox(height: 12),
                      _CompressionCard(
                        title: "High Quality",
                        subtitle: "Crispest images, largest file size.",
                        isSelected: state.selectedLevel == CompressionLevel.high,
                        onTap: () => notifier.setCompressionLevel(CompressionLevel.high),
                      ),

                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => notifier.compressPdf(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text("Compress Now", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],

                    const Spacer(),
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
class _CompressionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _CompressionCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF5F5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFD32F2F) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFFD32F2F).withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
              color: isSelected ? const Color(0xFFD32F2F) : Colors.grey.shade400,
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.black87 : Colors.black54,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}