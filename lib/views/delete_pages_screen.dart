import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/delete_pages_provider.dart';

class DeletePagesScreen extends ConsumerStatefulWidget {
  const DeletePagesScreen({super.key});

  @override
  ConsumerState<DeletePagesScreen> createState() => _DeletePagesScreenState();
}

class _DeletePagesScreenState extends ConsumerState<DeletePagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final state = ref.read(deletePagesProvider);
      if (state.selectedFile == null) {
        await ref.read(deletePagesProvider.notifier).pickPdf();
        if (ref.read(deletePagesProvider).selectedFile == null && mounted) {
          Navigator.pop(context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deletePagesProvider);
    final notifier = ref.read(deletePagesProvider.notifier);
    const Color primaryColor = Color(0xFFD32F2F);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black87),
          onPressed: () {
            notifier.resetAll();
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Delete Pages",
          style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        actions: [
          if (state.selectedFile != null && state.generatedPdf == null)
            IconButton(
              icon: const Icon(LucideIcons.filePlus, color: primaryColor),
              onPressed: () => notifier.pickPdf(),
            )
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: state.isLoading
            ? _buildLoadingState(primaryColor)
            : (state.selectedFile == null
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
            "Analyzing & Rendering Pages...\nThis takes a few seconds.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.w500, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspace(BuildContext context, DeletePagesState state, DeletePagesNotifier notifier, Color primaryColor) {
    final size = MediaQuery.of(context).size;

    return SingleChildScrollView(
      key: const ValueKey("workspace_state"),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.05, vertical: size.height * 0.02),
      child: AnimatedSwitcher(
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
            ? _buildSuccessView(state, primaryColor, notifier, size)
            : _buildPageSelectionGrid(state, notifier, primaryColor, size),
      ),
    );
  }

  Widget _buildPageSelectionGrid(DeletePagesState state, DeletePagesNotifier notifier, Color primaryColor, Size size) {
    final int crossAxisCount = size.width > 600 ? 5 : 3;

    return Column(
      key: const ValueKey("selection_grid"),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Select pages to remove",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: (size.width * 0.04).clamp(14.0, 18.0), color: Colors.black87),
            ),
            if (state.selectedPagesToDelete.isNotEmpty)
              Text(
                "${state.selectedPagesToDelete.length} Selected",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: (size.width * 0.035).clamp(12.0, 14.0), color: primaryColor),
              ),
          ],
        ),
        SizedBox(height: size.height * 0.02),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: state.pageThumbnails.length,
          itemBuilder: (context, index) {
            final isSelected = state.selectedPagesToDelete.contains(index);

            return GestureDetector(
              onTap: () {
                if (state.totalPages - state.selectedPagesToDelete.length == 1 && !isSelected) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("You cannot delete all pages.", style: GoogleFonts.poppins()),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                notifier.togglePageSelection(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.grey.shade300,
                    width: isSelected ? 3.0 : 1.0,
                  ),
                  boxShadow: [
                    if (!isSelected)
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.memory(
                        state.pageThumbnails[index],
                        fit: BoxFit.cover,
                      ),
                    ),

                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(9)),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${index + 1}",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),

                    if (isSelected) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                          child: const Icon(LucideIcons.trash2, size: 14, color: Colors.white),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            );
          },
        ),
        SizedBox(height: size.height * 0.04),
        ElevatedButton.icon(
          onPressed: state.selectedPagesToDelete.isEmpty ? null : () => notifier.processPdf(),
          icon: const Icon(LucideIcons.trash2, color: Colors.white, size: 20),
          label: Text("Delete Selected Pages", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            disabledBackgroundColor: Colors.grey.shade300,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        SizedBox(height: size.height * 0.05),
      ],
    );
  }

  Widget _buildSuccessView(DeletePagesState state, Color primaryColor, DeletePagesNotifier notifier, Size size) {
    return Column(
      key: const ValueKey("success_view"),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(size.width * 0.06),
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
                padding: EdgeInsets.all(size.width * 0.04),
                decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                child: Icon(LucideIcons.checkCircle2, color: Colors.green.shade600, size: size.width * 0.1),
              ),
              SizedBox(height: size.height * 0.02),
              Text("Pages Deleted!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: (size.width * 0.045).clamp(16.0, 20.0), color: Colors.green.shade800)),
              SizedBox(height: size.height * 0.01),
              Text(
                "Removed ${state.selectedPagesToDelete.length} pages successfully.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: (size.width * 0.035).clamp(12.0, 14.0), color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        SizedBox(height: size.height * 0.03),
        ElevatedButton.icon(
          onPressed: () => Share.shareXFiles([XFile(state.generatedPdf!.path)]),
          icon: const Icon(LucideIcons.share2, color: Colors.white),
          label: Text("Share Document", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        SizedBox(height: size.height * 0.02),
        TextButton(
          onPressed: () {
            notifier.resetAll();
            notifier.pickPdf();
          },
          child: Text("Edit another PDF", style: GoogleFonts.poppins(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
        )
      ],
    );
  }
}