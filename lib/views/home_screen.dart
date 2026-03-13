import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  Future<List<FileSystemEntity>> _getSavedFiles() async {
    final tempDir = await getTemporaryDirectory();
    final files = tempDir.listSync().where((file) {
      final path = file.path.toLowerCase();
      return path.endsWith('.pdf');
    }).toList();

    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return files;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      extendBody: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _selectedIndex == 0
                  ? _buildToolsGrid(context)
                  : _selectedIndex == 1
                  ? _buildFilesList(context)
                  : _buildSettingsList(context),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildFloatingNavBar(context),
    );
  }

  Widget _buildToolsGrid(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Padding(
      key: const ValueKey("tools_view"),
      padding: EdgeInsets.fromLTRB(
        size.width * 0.05,
        size.height * 0.01,
        size.width * 0.05,
        size.height * 0.12,
      ),
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 14),
            padding: EdgeInsets.fromLTRB(
              size.width * 0.04,
              24,
              size.width * 0.04,
              16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD32F2F), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD32F2F).withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: [
                _GridToolCard(title: "Split PDF", icon: LucideIcons.scissors, onTap: () => context.push('/split-pdf')),
                _GridToolCard(title: "Merge PDFs", icon: LucideIcons.layers, onTap: () => context.push('/merge-pdf')),
                _GridToolCard(title: "Compress", icon: LucideIcons.minimize, onTap: () => context.push('/compress-pdf')),
                _GridToolCard(title: "Delete Pages", icon: LucideIcons.trash2,  onTap: () => context.push('/delete-pdf')),
                _GridToolCard(title: "Image to PDF", icon: LucideIcons.image, onTap: () => context.push('/image-pdf')),
                _GridToolCard(title: "Lock PDF", icon: LucideIcons.fileLock, onTap: () => context.push('/lock-pdf')),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                color: const Color(0xFFFFFFFF),
                child: Text(
                  "PDF Tools",
                  style: GoogleFonts.poppins(
                    fontSize: (size.width * 0.05).clamp(18.0, 22.0),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFD32F2F),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesList(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return FutureBuilder<List<FileSystemEntity>>(
      key: const ValueKey("files_view"),
      future: _getSavedFiles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(size.height * 0.05),
                    child: Image.asset(
                      'assets/splash.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.02),
                Text(
                  "No files generated yet.",
                  style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: (size.width * 0.04).clamp(14.0, 16.0)),
                ),
                SizedBox(height: size.height * 0.1),
              ],
            ),
          );
        }

        final files = snapshot.data!;

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(size.width * 0.05, size.height * 0.02, size.width * 0.05, size.height * 0.12),
          physics: const BouncingScrollPhysics(),
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = File(files[index].path);
            final fileName = file.path.split('/').last;
            final fileSize = (file.lengthSync() / (1024 * 1024)).toStringAsFixed(2);
            final modDate = file.statSync().modified;
            final dateStr = "${modDate.day}/${modDate.month}/${modDate.year}";

            return Container(
              margin: EdgeInsets.only(bottom: size.height * 0.015),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: size.height * 0.01),
                leading: Container(
                  padding: EdgeInsets.all(size.width * 0.025),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(LucideIcons.fileText, color: const Color(0xFFD32F2F), size: size.width * 0.06),
                ),
                title: Text(
                  fileName,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: (size.width * 0.035).clamp(12.0, 15.0)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  "$dateStr • $fileSize MB",
                  style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: (size.width * 0.03).clamp(10.0, 13.0)),
                ),
                trailing: IconButton(
                  icon: Icon(LucideIcons.share2, color: Colors.black87, size: size.width * 0.06),
                  onPressed: () {
                    Share.shareXFiles([XFile(file.path)], text: 'Check out this PDF!');
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return ListView(
      key: const ValueKey("settings_view"),
      padding: EdgeInsets.fromLTRB(size.width * 0.05, size.height * 0.02, size.width * 0.05, size.height * 0.12),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSettingsTile(
          context: context,
          icon: LucideIcons.mail,
          title: "Contact Us",
          onTap: () => _showContactDialog(context),
        ),
        _buildSettingsTile(
          context: context,
          icon: LucideIcons.star,
          title: "Rate Us",
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Coming soon to the Play Store!", style: GoogleFonts.poppins()),
                backgroundColor: const Color(0xFFD32F2F),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        _buildSettingsTile(
          context: context,
          icon: LucideIcons.shieldCheck,
          title: "Privacy Policy",
          onTap: () => _showPrivacyPolicyDialog(context),
        ),
        _buildSettingsTile(
          context: context,
          icon: LucideIcons.heartHandshake,
          title: "Attributions",
          onTap: () => _showAttributionsDialog(context),
        ),
        _buildSettingsTile(
          context: context,
          icon: LucideIcons.info,
          title: "Version",
          subtitle: "1.0.0",
          onTap: () {},
        ),
      ],
    );
  }

  void _showContactDialog(BuildContext context) {
    final size = MediaQuery.of(context).size;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(size.width * 0.02),
              decoration: const BoxDecoration(color: Color(0xFFFFEBEE), shape: BoxShape.circle),
              child: Icon(LucideIcons.mail, color: const Color(0xFFD32F2F), size: (size.width * 0.06).clamp(20.0, 28.0)),
            ),
            SizedBox(width: size.width * 0.03),
            Text("Contact Us", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: (size.width * 0.045).clamp(16.0, 20.0))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Have a question or feedback? We'd love to hear from you. Send us an email at:",
              style: GoogleFonts.poppins(fontSize: (size.width * 0.035).clamp(12.0, 15.0), color: Colors.grey.shade700),
            ),
            SizedBox(height: size.height * 0.02),
            Container(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: size.height * 0.015),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "rdass87871@gmail.com",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: (size.width * 0.035).clamp(12.0, 14.0), color: const Color(0xFFD32F2F)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: "rdass87871@gmail.com"));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Email copied to clipboard!", style: GoogleFonts.poppins()),
                          backgroundColor: Colors.green.shade600,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Icon(LucideIcons.copy, color: Colors.grey.shade600, size: (size.width * 0.05).clamp(18.0, 22.0)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    final size = MediaQuery.of(context).size;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(size.width * 0.02),
              decoration: const BoxDecoration(color: Color(0xFFFFEBEE), shape: BoxShape.circle),
              child: Icon(LucideIcons.shieldCheck, color: const Color(0xFFD32F2F), size: (size.width * 0.06).clamp(20.0, 28.0)),
            ),
            SizedBox(width: size.width * 0.03),
            Text("Privacy Policy", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: (size.width * 0.045).clamp(16.0, 20.0))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "100% Offline & Secure",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: (size.width * 0.04).clamp(14.0, 16.0), color: Colors.black87),
            ),
            SizedBox(height: size.height * 0.01),
            Text(
              "We take your privacy seriously. This application operates entirely offline on your device.\n\nWe do not collect, store, or transmit any of your personal data, files, or PDF documents to any external servers. All file processing (merging, splitting, locking, etc.) is done locally using your phone's processor.\n\nYour documents belong to you, and they never leave your device.",
              style: GoogleFonts.poppins(fontSize: (size.width * 0.035).clamp(12.0, 15.0), color: Colors.grey.shade700, height: 1.5),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text("I Understand", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAttributionsDialog(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final List<String> dependencies = [
      'cupertino_icons', 'flutter_riverpod', 'riverpod_annotation', 'drift',
      'sqlite3_flutter_libs', 'path_provider', 'path', 'go_router',
      'google_fonts', 'fl_chart', 'lucide_icons', 'flutter_animate',
      'shared_preferences', 'animated_bottom_navigation_bar', 'intl',
      'flutter_floating_bottom_bar', 'google_generative_ai', 'flutter_markdown',
      'http', 'cached_network_image', 'syncfusion_flutter_pdf', 'file_picker',
      'share_plus', 'syncfusion_flutter_pdfviewer', 'pdfx', 'pdf_compressor',
      'image_picker', 'flutter_launcher_icons', 'flutter_lints'
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(size.width * 0.02),
              decoration: const BoxDecoration(color: Color(0xFFFFEBEE), shape: BoxShape.circle),
              child: Icon(LucideIcons.heartHandshake, color: const Color(0xFFD32F2F), size: (size.width * 0.06).clamp(20.0, 28.0)),
            ),
            SizedBox(width: size.width * 0.03),
            Text("Attributions", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: (size.width * 0.045).clamp(16.0, 20.0))),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Visual Assets",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: (size.width * 0.04).clamp(14.0, 16.0), color: Colors.black87),
                ),
                SizedBox(height: size.height * 0.01),
                Text(
                  "Illustrations and icons are designed by Freepik (www.freepik.com). We are deeply grateful for their open-source resources.",
                  style: GoogleFonts.poppins(fontSize: (size.width * 0.035).clamp(12.0, 14.0), color: Colors.grey.shade700, height: 1.5),
                ),
                SizedBox(height: size.height * 0.015),
                _buildCreditItem("• Hand drawn college entrance exam illustration", size),
                _buildCreditItem("• Hand drawn essay illustration", size),
                _buildCreditItem("• File transfer Generic black outline icon", size),

                SizedBox(height: size.height * 0.03),

                Text(
                  "Open Source Libraries",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: (size.width * 0.04).clamp(14.0, 16.0), color: Colors.black87),
                ),
                SizedBox(height: size.height * 0.01),
                Text(
                  "This app is built with Flutter and made possible by the following amazing open-source packages:",
                  style: GoogleFonts.poppins(fontSize: (size.width * 0.035).clamp(12.0, 14.0), color: Colors.grey.shade700, height: 1.5),
                ),
                SizedBox(height: size.height * 0.02),
                Wrap(
                  spacing: 6.0,
                  runSpacing: 6.0,
                  children: dependencies.map((dep) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      dep,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: (size.width * 0.028).clamp(10.0, 12.0),
                        color: const Color(0xFFD32F2F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditItem(String text, Size size) {
    return Padding(
      padding: EdgeInsets.only(bottom: size.height * 0.008),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: (size.width * 0.03).clamp(11.0, 13.0),
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final size = MediaQuery.of(context).size;

    return Container(
      margin: EdgeInsets.only(bottom: size.height * 0.015),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: size.height * 0.01),
        leading: Container(
          padding: EdgeInsets.all(size.width * 0.025),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFD32F2F), size: size.width * 0.06),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: (size.width * 0.035).clamp(12.0, 15.0)),
        ),
        subtitle: subtitle != null
            ? Text(
          subtitle,
          style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: (size.width * 0.03).clamp(10.0, 13.0)),
        )
            : null,
        trailing: Icon(LucideIcons.chevronRight, color: Colors.grey.shade400, size: size.width * 0.05),
      ),
    );
  }

  Widget _buildFloatingNavBar(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final navWidth = size.width > 500 ? 400.0 : size.width * 0.92;

    return Container(
      width: navWidth,
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.02, vertical: size.height * 0.015),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: _NavBarItem(
              title: "Home",
              icon: LucideIcons.home,
              isSelected: _selectedIndex == 0,
              onTap: () => setState(() => _selectedIndex = 0),
            ),
          ),
          Expanded(
            child: _NavBarItem(
              title: "Files",
              icon: LucideIcons.folder,
              isSelected: _selectedIndex == 1,
              onTap: () => setState(() => _selectedIndex = 1),
            ),
          ),
          Expanded(
            child: _NavBarItem(
              title: "Settings",
              icon: LucideIcons.settings,
              isSelected: _selectedIndex == 2,
              onTap: () => setState(() => _selectedIndex = 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double headerHeight = size.height * 0.32;

    return ClipPath(
      clipper: HeaderClipper(),
      child: Container(
        width: double.infinity,
        height: headerHeight,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: CurveBorderPainter())),
            Positioned(
              top: -size.height * 0.08,
              right: -size.width * 0.15,
              child: Container(
                width: size.width * 0.6,
                height: size.width * 0.6,
                decoration: BoxDecoration(color: const Color(0xFFD32F2F).withOpacity(0.04), shape: BoxShape.circle),
              ),
            ),
            Positioned(
              bottom: -size.height * 0.05,
              left: -size.width * 0.1,
              child: Container(
                width: size.width * 0.4,
                height: size.width * 0.4,
                decoration: BoxDecoration(color: const Color(0xFFD32F2F).withOpacity(0.04), shape: BoxShape.circle),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(size.width * 0.08, size.height * 0.02, size.width * 0.05, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: size.width * 0.03, vertical: size.height * 0.005),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD32F2F),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "WORKSPACE",
                              style: GoogleFonts.poppins(
                                fontSize: (size.width * 0.025).clamp(8.0, 11.0),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                          SizedBox(height: size.height * 0.02),
                          Text(
                            "Manage Your\nPDF Files",
                            style: GoogleFonts.poppins(
                              fontSize: (size.width * 0.07).clamp(24.0, 30.0),
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Image.asset(
                          'assets/quiz.png',
                          height: headerHeight * 0.45,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(LucideIcons.fileImage, size: size.width * 0.2, color: Colors.grey.withOpacity(0.2)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(vertical: size.height * 0.01),
        margin: EdgeInsets.symmetric(horizontal: size.width * 0.01),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD32F2F) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: (size.width * 0.045).clamp(16.0, 20.0),
              color: isSelected ? Colors.white : Colors.grey.shade500,
            ),
            if (isSelected) ...[
              SizedBox(width: size.width * 0.015),
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: (size.width * 0.03).clamp(10.0, 13.0),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _GridToolCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _GridToolCard({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final cardHeight = constraints.maxHeight;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD32F2F), width: 1.5),
              boxShadow: [
                BoxShadow(color: const Color(0xFFD32F2F).withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(cardWidth * 0.15),
                  decoration: const BoxDecoration(color: Color(0xFFFFEBEE), shape: BoxShape.circle),
                  child: Icon(
                    icon,
                    color: const Color(0xFFD32F2F),
                    size: cardWidth * 0.28,
                  ),
                ),
                SizedBox(height: cardHeight * 0.08),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: (cardWidth * 0.12).clamp(10.0, 14.0),
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    var controlPoint = Offset(size.width / 2, size.height + 20);
    var endPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class CurveBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var path = Path();
    path.moveTo(0, size.height - 40);
    var controlPoint = Offset(size.width / 2, size.height + 20);
    var endPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);

    var paint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}