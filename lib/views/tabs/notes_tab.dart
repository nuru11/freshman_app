import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/controllers/subject/chapter_detail_controller.dart';
import 'package:vector_academy/models/models.dart';

class NotesTab extends StatelessWidget {
  const NotesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GetBuilder<ChapterDetailController>(
      builder: (controller) {
        if (controller.notes.isEmpty) {
          return _buildEmptyState(context);
        }

        return Container(
          color: theme.scaffoldBackgroundColor,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final note = controller.notes[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: _buildModernNoteCard(context, note, controller),
                    );
                  }, childCount: controller.notes.length),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Semantics(
        label: 'No notes available. Notes and materials for this chapter will appear here.',
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                    theme.colorScheme.secondary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.description_outlined,
                size: 60,
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No Notes Available',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Notes and materials for this chapter will appear here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernNoteCard(
    BuildContext context,
    Note note,
    ChapterDetailController controller,
  ) {
    final theme = Theme.of(context);
    final String type = note.content.toLowerCase() == 'pdf' ? 'PDF' : 'DOC';
    final bool isLocked = controller.isNoteLocked(note);
    final bool isDownloaded = note.isDownloaded;
    final bool isDownloading = note.isDownloading;
    final double downloadProgress = note.downloadProgress;
    final statusLabel = isLocked
        ? 'locked'
        : isDownloading
        ? 'downloading, ${(downloadProgress * 100).toInt()} percent'
        : isDownloaded
        ? 'downloaded'
        : 'not downloaded';
    final semanticAction = isDownloaded
        ? 'Double tap to open in the app.'
        : 'needs to be downloaded first. Use the download button.';
    final semanticLabel = 'PDF note, ${note.title}, $statusLabel. $semanticAction';

    return Semantics(
      button: !isLocked && !isDownloading,
      enabled: !isLocked && !isDownloading,
      label: semanticLabel,
      onTap: (isDownloading || isLocked)
          ? null
          : () => controller.openPDF(note.id),
      child: Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (isDownloading || isLocked)
              ? null
              : () => controller.openPDF(note.id),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // File Type Icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getFileTypeColor(type),
                            _getFileTypeColor(type).withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _getFileTypeColor(
                              type,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            _getFileTypeIcon(type),
                            color: Colors.white,
                            size: 26,
                          ),
                          if (isDownloading)
                            CircularProgressIndicator(
                              value: downloadProgress,
                              strokeWidth: 3,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.3,
                              ),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),

                    SizedBox(width: 16),
                    // Note Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 10),
                          // Use Wrap instead of Row to prevent overflow
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getFileTypeColor(
                                    type,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getFileTypeColor(
                                      type,
                                    ).withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  type.toUpperCase(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: _getFileTypeColor(type),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              // Container(
                              //   padding: EdgeInsets.symmetric(
                              //     horizontal: 8,
                              //     vertical: 4,
                              //   ),
                              //   decoration: BoxDecoration(
                              //     color: theme
                              //         .colorScheme
                              //         .surfaceContainerHighest
                              //         .withValues(alpha: 0.5),
                              //     borderRadius: BorderRadius.circular(12),
                              //   ),
                              //   child: Text(
                              //     note.size?.toString() ?? '0 MB',
                              //     style: theme.textTheme.labelSmall?.copyWith(
                              //       color: theme.colorScheme.onSurfaceVariant,
                              //       fontWeight: FontWeight.w500,
                              //     ),
                              //   ),
                              // ),
                              if (isDownloaded && !isDownloading)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.colorScheme.secondary
                                          .withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 14,
                                        color: theme.colorScheme.secondary,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Saved in app',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color:
                                                  theme.colorScheme.secondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (isLocked)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.orange.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'Locked',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              if (isDownloading)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          value: downloadProgress,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        '${(downloadProgress * 100).toInt()}%',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Action button
                    _buildDownloadButton(context, note, controller),
                  ],
                ),
                // Progress bar at the bottom when downloading
                if (isDownloading) ...[
                  SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    label:
                        'Downloading, ${(downloadProgress * 100).toInt()} percent',
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Downloading...',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${(downloadProgress * 100).toInt()}%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: downloadProgress,
                        backgroundColor: theme.colorScheme.primary.withValues(
                          alpha: 0.1,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                        minHeight: 3,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildDownloadButton(
    BuildContext context,
    Note note,
    ChapterDetailController controller,
  ) {
    final theme = Theme.of(context);
    final isLocked = controller.isNoteLocked(note);

    if (isLocked) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: ExcludeSemantics(
          child: IconButton(
            tooltip: 'Note locked',
            onPressed: null,
            icon: Icon(
              Icons.lock_rounded,
              color: theme.colorScheme.onSurfaceVariant,
              size: 22,
              semanticLabel: 'Locked',
            ),
            padding: EdgeInsets.all(12),
          ),
        ),
      );
    }

    if (note.isDownloaded) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.secondary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Icon(
            Icons.download_done,
            color: theme.colorScheme.secondary,
            size: 22,
          ),
        ),
      );
    }

    if (note.isDownloading) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: ExcludeSemantics(
          child: IconButton(
            tooltip: 'Downloading note',
            onPressed: null,
            icon: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: note.downloadProgress,
                color: theme.colorScheme.primary,
              ),
            ),
            padding: EdgeInsets.all(12),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ExcludeSemantics(
        child: IconButton(
          tooltip: 'Download note',
          onPressed: () => controller.downloadNote(note.id),
          icon: Icon(
            Icons.download_outlined,
            color: theme.colorScheme.primary,
            size: 22,
            semanticLabel: 'Download',
          ),
          padding: EdgeInsets.all(12),
        ),
      ),
    );
  }

  Color _getFileTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Color(0xFFE53E3E); // Red-500
      case 'doc':
      case 'docx':
        return Color(0xFF3182CE); // Blue-500
      case 'ppt':
      case 'pptx':
        return Color(0xFFDD6B20); // Orange-500
      case 'markdown':
      case 'md':
        return Color(0xFF805AD5); // Purple-500
      default:
        return Color(0xFF718096); // Gray-500
    }
  }

  IconData _getFileTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'markdown':
      case 'md':
        return Icons.code;
      default:
        return Icons.insert_drive_file;
    }
  }
}
