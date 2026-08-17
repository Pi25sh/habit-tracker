import 'package:flutter/material.dart';

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: const Text('Export Data', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.cloud_download_outlined, size: 64, color: Colors.blue),
          const SizedBox(height: 24),
          const Text(
            'Your data belongs to you.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 8),
          const Text(
            'Export your journal entries, habits, and mood history in any format you prefer.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 48),
          
          _buildExportOption('PDF Document', 'Beautifully formatted journals', Icons.picture_as_pdf, Colors.redAccent),
          _buildExportOption('Markdown (.md)', 'For Obsidian & Notion', Icons.text_snippet, Colors.purple),
          _buildExportOption('JSON Data', 'Complete structured database', Icons.data_object, Colors.green),
          _buildExportOption('CSV Spreadsheet', 'For Excel & Analytics', Icons.table_chart, Colors.orange),
          _buildExportOption('ZIP Archive', 'Includes images & voice notes', Icons.folder_zip, Colors.blueGrey),
        ],
      ),
    );
  }

  Widget _buildExportOption(String title, String subtitle, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.download, color: Colors.black26),
        ],
      ),
    );
  }
}
