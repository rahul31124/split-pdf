import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../providers/merge_pdf_provider.dart';
import 'SuccessPreviewScreen.dart';

class MergePdfScreen extends ConsumerStatefulWidget {
  const MergePdfScreen({super.key});

  @override
  ConsumerState<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends ConsumerState<MergePdfScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final state = ref.read(mergePdfProvider);
      if (state.selectedFiles.isEmpty) {
        await ref.read(mergePdfProvider.notifier).pickFiles();

        if (ref.read(mergePdfProvider).selectedFiles.isEmpty && mounted) {
          Navigator.pop(context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mergePdfProvider);
    final notifier = ref.read(mergePdfProvider.notifier);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Merge PDFs",
          style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (state.selectedFiles.isNotEmpty && !state.isLoading)
            IconButton(
              icon: const Icon(LucideIcons.plusCircle, color: Color(0xFFD32F2F)),
              onPressed: () => notifier.pickFiles(),
              tooltip: "Add more files",
            ),
        ],
      ),
      body: _buildBody(context, ref, state, notifier, size),
      floatingActionButton: (state.selectedFiles.length >= 2 && !state.isLoading)
          ? FloatingActionButton.extended(
        onPressed: () async {
          final mergedPath = await notifier.mergePdfs();
          if (mergedPath != null && context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SuccessPreviewScreen(filePaths: [mergedPath]),
              ),
            );
          }
        },
        backgroundColor: const Color(0xFFD32F2F),
        icon: const Icon(LucideIcons.layers, color: Colors.white),
        label: Text(
          "Merge ${state.selectedFiles.length} Files",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, MergePdfState state, MergePdfNotifier notifier, Size size) {
    if (state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFFD32F2F)),
            SizedBox(height: size.height * 0.02),
            Text(
              "Stitching PDFs together...\nDo not close the app.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    if (state.selectedFiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(size.width * 0.05, size.height * 0.01, size.width * 0.05, size.height * 0.02),
          child: Text(
            "Long press and drag to reorder the files. The top file will be the first pages in the merged document.",
            style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: (size.width * 0.035).clamp(12.0, 14.0)),
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: EdgeInsets.fromLTRB(size.width * 0.05, 0, size.width * 0.05, size.height * 0.12),
            itemCount: state.selectedFiles.length,
            onReorder: (oldIndex, newIndex) => notifier.reorderFiles(oldIndex, newIndex),
            proxyDecorator: (child, index, animation) {
              return Material(
                elevation: 10,
                color: Colors.transparent,
                shadowColor: Colors.black.withOpacity(0.2),
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final file = state.selectedFiles[index];
              final fileName = file.path.split('/').last;

              return Container(
                key: ValueKey(file.path),
                margin: EdgeInsets.only(bottom: size.height * 0.015),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: size.height * 0.005),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFFFEBEE),
                    child: Text(
                      "${index + 1}",
                      style: GoogleFonts.poppins(color: const Color(0xFFD32F2F), fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    fileName,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: (size.width * 0.035).clamp(12.0, 15.0)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(LucideIcons.trash2, color: Colors.grey, size: (size.width * 0.05).clamp(18.0, 22.0)),
                        onPressed: () => notifier.removeFile(index),
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: Icon(LucideIcons.gripVertical, color: Colors.black54, size: (size.width * 0.06).clamp(20.0, 24.0)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}