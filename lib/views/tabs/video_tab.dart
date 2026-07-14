import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vector_academy/controllers/subject/chapter_detail_controller.dart';
import 'package:vector_academy/models/models.dart';

class VideoTab extends StatelessWidget {
  const VideoTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GetBuilder<ChapterDetailController>(
      builder: (controller) {
        // Show loading indicator when videos are loading
        if (controller.isVideosLoading) {
          return _buildLoadingState(context);
        }

        if (controller.videos.isEmpty) {
          return _buildEmptyState(context);
        }

        return Container(
          color: theme.colorScheme.surface,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final video = controller.videos[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: _buildModernVideoCard(context, video, controller),
                    );
                  }, childCount: controller.videos.length),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.1),
                  theme.colorScheme.secondary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Loading Videos...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please wait while we fetch the videos',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
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
              Icons.video_library_outlined,
              size: 60,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No Videos Available',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Videos for this chapter will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernVideoCard(
    BuildContext context,
    Video video,
    ChapterDetailController controller,
  ) {
    final theme = Theme.of(context);
    final bool isLocked = controller.isVideoLocked(video);
    final bool isWatched = video.isWatched;

    return Container(
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
          onTap: isLocked ? null : () => controller.playVideo(video.id),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                // Video Thumbnail
                Container(
                  width: 100,
                  height: 75,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isLocked
                                    ? Colors.grey[400]!
                                    : theme.colorScheme.primary)
                                .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Thumbnail Image
                        if (video.thumbnail != null &&
                            video.thumbnail!.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: video.thumbnail!,
                            width: 100,
                            height: 75,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isLocked
                                      ? [Colors.grey[300]!, Colors.grey[400]!]
                                      : [
                                          theme.colorScheme.primary.withValues(
                                            alpha: 0.8,
                                          ),
                                          theme.colorScheme.secondary
                                              .withValues(alpha: 0.6),
                                        ],
                                ),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isLocked ? Colors.grey[600]! : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isLocked
                                      ? [Colors.grey[300]!, Colors.grey[400]!]
                                      : [
                                          theme.colorScheme.primary.withValues(
                                            alpha: 0.8,
                                          ),
                                          theme.colorScheme.secondary
                                              .withValues(alpha: 0.6),
                                        ],
                                ),
                              ),
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: isLocked
                                    ? Colors.grey[600]
                                    : Colors.white,
                                size: 24,
                              ),
                            ),
                          )
                        else
                          // Fallback gradient when no thumbnail
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isLocked
                                    ? [Colors.grey[300]!, Colors.grey[400]!]
                                    : [
                                        theme.colorScheme.primary.withValues(
                                          alpha: 0.8,
                                        ),
                                        theme.colorScheme.secondary.withValues(
                                          alpha: 0.6,
                                        ),
                                      ],
                              ),
                            ),
                          ),

                        // Play icon overlay
                        Center(
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isLocked ? Icons.lock : Icons.play_arrow,
                              color: isLocked
                                  ? Colors.grey[600]
                                  : theme.colorScheme.primary,
                              size: 24,
                            ),
                          ),
                        ),

                        // Duration badge
                        if (video.duration != 0)
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                video.duration.toString(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                        // Watched indicator
                        if (isWatched && !isLocked)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.secondary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 20),

                // Video Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isLocked
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onSurface,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 12),

                      // Download progress bar (shown when downloading)
                      if (video.isDownloading) ...[
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: video.downloadProgress,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.download,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Downloading ${(video.downloadProgress * 100).round()}%',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                      ],

                      Row(
                        children: [
                          if (isWatched && !isLocked) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.colorScheme.secondary.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: theme.colorScheme.secondary,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Watched',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: theme.colorScheme.secondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12),
                          ],
                          if (isLocked) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.colorScheme.error.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock,
                                    size: 16,
                                    color: theme.colorScheme.error,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Locked',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: theme.colorScheme.error,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Action button
                if (!isLocked) _buildDownloadButton(context, video, controller),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadButton(
    BuildContext context,
    Video video,
    ChapterDetailController controller,
  ) {
    final theme = Theme.of(context);

    if (video.isDownloaded) {
      // Show downloaded indicator
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
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
            size: 20,
          ),
        ),
      );
    }

    if (video.isDownloading) {
      // Show progress indicator
      return Container(
        width: 60,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Circular progress indicator
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                value: video.downloadProgress,
                strokeWidth: 2.5,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.2,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
            // Progress percentage text
            Text(
              '${(video.downloadProgress * 100).round()}%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 8,
              ),
            ),
          ],
        ),
      );
    }

    // Show download button
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: () => controller.downloadVideo(video.id),
        icon: Icon(
          Icons.download_outlined,
          color: theme.colorScheme.primary,
          size: 20,
        ),
      ),
    );
  }
}
