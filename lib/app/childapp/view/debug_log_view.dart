import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:child_track/core/services/debug_log_service.dart';

/// Full-screen debug log viewer for tracking diagnostics.
///
/// Shows real-time logs with color-coded severity, auto-scroll,
/// and copy-to-clipboard. Access from the child app for development testing.
class DebugLogView extends StatefulWidget {
  const DebugLogView({super.key});

  @override
  State<DebugLogView> createState() => _DebugLogViewState();
}

class _DebugLogViewState extends State<DebugLogView> {
  final _debugLog = DebugLogService();
  final _scrollController = ScrollController();
  late StreamSubscription<List<DebugLogEntry>> _subscription;
  List<DebugLogEntry> _entries = [];
  bool _autoScroll = true;
  String? _filterTag; // null = show all

  static const _tagColors = <String, Color>{
    'QUEUE': Color(0xFF42A5F5),
    'UPLOAD': Color(0xFF66BB6A),
    'TRIP': Color(0xFFFF7043),
    'SERVICE': Color(0xFFAB47BC),
    'API': Color(0xFF26C6DA),
    'RETRY': Color(0xFFFFA726),
  };

  @override
  void initState() {
    super.initState();
    _entries = _debugLog.entries;
    _subscription = _debugLog.stream.listen((entries) {
      if (mounted) {
        setState(() => _entries = entries);
        if (_autoScroll) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToBottom(),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  List<DebugLogEntry> get _filteredEntries {
    if (_filterTag == null) return _entries;
    return _entries.where((e) => e.tag == _filterTag).toList();
  }

  void _copyAllLogs() {
    final text = _filteredEntries
        .map((e) => '${e.timeFormatted} [${e.tag}] ${e.message}')
        .join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_filteredEntries.length} logs copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEntries;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Debug Logs',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Auto-scroll toggle
          IconButton(
            icon: Icon(
              _autoScroll ? Icons.vertical_align_bottom : Icons.unfold_more,
              color: _autoScroll ? Colors.greenAccent : Colors.white54,
            ),
            tooltip: _autoScroll ? 'Auto-scroll ON' : 'Auto-scroll OFF',
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
          ),
          // Copy all
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white54),
            tooltip: 'Copy all logs',
            onPressed: _copyAllLogs,
          ),
          // Clear
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white54),
            tooltip: 'Clear logs',
            onPressed: () {
              _debugLog.clear();
              setState(() => _entries = []);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter chips ──
          Container(
            height: 48,
            color: const Color(0xFF16213E),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip(null, 'ALL', Colors.white),
                ..._tagColors.entries.map(
                  (e) => _filterChip(e.key, e.key, e.value),
                ),
              ],
            ),
          ),

          // ── Status bar ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0xFF0F3460),
            child: Text(
              '${filtered.length} entries'
              '${_filterTag != null ? " (filtered: $_filterTag)" : ""}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.white54,
              ),
            ),
          ),

          // ── Log list ──
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No logs yet.\n\nLogs will appear here when\nthe tracking service runs.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: Colors.white38,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final entry = filtered[index];
                      return _LogEntryTile(
                        entry: entry,
                        tagColor: _tagColors[entry.tag] ?? Colors.grey,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String? tag, String label, Color color) {
    final isSelected = _filterTag == tag;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filterTag = tag),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? color.withAlpha(60) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.white24,
              width: isSelected ? 1.5 : 0.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : Colors.white54,
            ),
          ),
        ),
      ),
    );
  }
}

class _LogEntryTile extends StatelessWidget {
  final DebugLogEntry entry;
  final Color tagColor;

  const _LogEntryTile({required this.entry, required this.tagColor});

  Color get _bgColor {
    switch (entry.level) {
      case LogLevel.error:
        return const Color(0x20FF5252);
      case LogLevel.warning:
        return const Color(0x15FFA726);
      case LogLevel.success:
        return const Color(0x1066BB6A);
      case LogLevel.info:
        return Colors.transparent;
    }
  }

  Color get _textColor {
    switch (entry.level) {
      case LogLevel.error:
        return const Color(0xFFFF5252);
      case LogLevel.warning:
        return const Color(0xFFFFA726);
      case LogLevel.success:
        return const Color(0xFF66BB6A);
      case LogLevel.info:
        return const Color(0xFFB0BEC5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          Text(
            entry.timeFormatted,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Colors.white30,
            ),
          ),
          const SizedBox(width: 6),
          // Tag badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: tagColor.withAlpha(40),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              entry.tag,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: tagColor,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Message
          Expanded(
            child: Text(
              entry.message,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: _textColor,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
