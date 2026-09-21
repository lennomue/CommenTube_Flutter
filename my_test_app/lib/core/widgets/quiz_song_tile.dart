import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/favorite.dart';
import '../models/playlist.dart';
import '../models/quiz.dart';
import '../repositories/favorite_providers.dart';
import '../repositories/playlist_providers.dart';
import '../utils/display_formatters.dart';

class QuizSongTile extends ConsumerWidget {
  const QuizSongTile({
    super.key,
    required this.quiz,
    required this.onOpen,
    this.showDragHandle = false,
    this.showActions = true,
    this.enabled = true,
  });

  final QuizWithLiveStats quiz;
  final VoidCallback onOpen;
  final bool showDragHandle;
  final bool showActions;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorite = SavedFavorite.song(
      videoId: quiz.quiz.videoId,
      title: quiz.quiz.title,
    );
    final isFavorite =
        ref
            .watch(favoritesProvider)
            .value
            ?.any((item) => item.id == favorite.id) ??
        false;
    final isInPlaylist =
        ref
            .watch(playlistsProvider)
            .value
            ?.any((playlist) => playlist.containsVideo(quiz.quiz.videoId)) ??
        false;
    return Material(
      color: const Color(0xFF1C1C1C),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onOpen : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 5, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.quiz.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${formatCompactCount(quiz.videoStats.viewCount)}回視聴 ・ '
                      '${formatRelativeDate(quiz.quiz.postedAt)}',
                      style: const TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (showActions)
                IconButton(
                  key: ValueKey('song-favorite-${quiz.quiz.videoId}'),
                  tooltip: 'お気に入り',
                  onPressed: () => ref
                      .read(favoriteRepositoryProvider)
                      .toggleFavorite(favorite),
                  icon: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                  ),
                ),
              if (showActions)
                IconButton(
                  key: ValueKey('song-playlist-${quiz.quiz.videoId}'),
                  tooltip: '再生リスト',
                  onPressed: () => showAddToPlaylistSheet(
                    context,
                    ref,
                    videoId: quiz.quiz.videoId,
                  ),
                  icon: Icon(
                    isInPlaylist
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                  ),
                ),
              if (showDragHandle)
                const Padding(
                  padding: EdgeInsets.only(right: 7),
                  child: Icon(Icons.drag_handle_rounded, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showAddToPlaylistSheet(
  BuildContext context,
  WidgetRef ref, {
  required String videoId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: const Color(0xFF171717),
    builder: (sheetContext) => _PlaylistPicker(videoId: videoId),
  );
}

Future<bool> showBatchPlaylistSheet(
  BuildContext context,
  WidgetRef ref, {
  required List<String> videoIds,
  String? sourcePlaylistId,
}) async {
  if (videoIds.isEmpty) {
    return false;
  }
  return await showModalBottomSheet<bool>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF171717),
        builder: (sheetContext) => _BatchPlaylistPicker(
          videoIds: videoIds,
          sourcePlaylistId: sourcePlaylistId,
        ),
      ) ??
      false;
}

class _BatchPlaylistPicker extends ConsumerWidget {
  const _BatchPlaylistPicker({
    required this.videoIds,
    required this.sourcePlaylistId,
  });

  final List<String> videoIds;
  final String? sourcePlaylistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF666666),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            sourcePlaylistId == null ? '作品をまとめて追加' : '別の再生リストへ移動',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            '${videoIds.length}作品を、表示されている順番で移動します',
            style: const TextStyle(color: Color(0xFFAAAAAA)),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: playlists.when(
              data: (items) {
                final targets = items
                    .where((item) => item.id != sourcePlaylistId)
                    .toList(growable: false);
                if (targets.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      '移動先の再生リストはまだありません',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: targets.length,
                  itemBuilder: (context, index) {
                    final playlist = targets[index];
                    return ListTile(
                      key: ValueKey('batch-playlist-target-${playlist.id}'),
                      title: Text(playlist.name),
                      subtitle: Text('${playlist.videoIds.length}作品'),
                      trailing: FilledButton(
                        key: ValueKey('batch-playlist-move-${playlist.id}'),
                        onPressed: () => _move(context, ref, playlist.id),
                        child: const Text('まとめて移動'),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  const Center(child: Text('再生リストを読み込めませんでした')),
            ),
          ),
          const Divider(),
          ListTile(
            key: const ValueKey('create-batch-playlist-button'),
            leading: const Icon(Icons.add_rounded),
            title: const Text('新しい再生リスト'),
            onTap: () async {
              final draft = await showPlaylistEditor(context);
              if (draft == null) {
                return;
              }
              final repository = ref.read(playlistRepositoryProvider);
              final playlistId = await repository.createPlaylist(draft);
              if (sourcePlaylistId == null) {
                await repository.addVideos(playlistId, videoIds);
              } else {
                await repository.moveVideos(
                  sourcePlaylistId: sourcePlaylistId!,
                  targetPlaylistId: playlistId,
                  videoIds: videoIds,
                );
              }
              if (context.mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _move(
    BuildContext context,
    WidgetRef ref,
    String targetPlaylistId,
  ) async {
    final repository = ref.read(playlistRepositoryProvider);
    if (sourcePlaylistId == null) {
      await repository.addVideos(targetPlaylistId, videoIds);
    } else {
      await repository.moveVideos(
        sourcePlaylistId: sourcePlaylistId!,
        targetPlaylistId: targetPlaylistId,
        videoIds: videoIds,
      );
    }
    if (context.mounted) {
      Navigator.pop(context, true);
    }
  }
}

class _PlaylistPicker extends ConsumerWidget {
  const _PlaylistPicker({required this.videoId});

  final String videoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF666666),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '再生リストに追加',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: playlists.when(
              data: (items) => _playlistChoices(context, ref, items),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  const Center(child: Text('再生リストを読み込めませんでした')),
            ),
          ),
          const Divider(),
          ListTile(
            key: const ValueKey('create-playlist-button'),
            leading: const Icon(Icons.add_rounded),
            title: const Text('新しい再生リスト'),
            onTap: () async {
              final draft = await showPlaylistEditor(context);
              if (draft == null) {
                return;
              }
              await ref
                  .read(playlistRepositoryProvider)
                  .createPlaylist(draft, firstVideoId: videoId);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _playlistChoices(
    BuildContext context,
    WidgetRef ref,
    List<UserPlaylist> items,
  ) {
    final editableItems = items;
    if (editableItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Text(
          '再生リストはまだありません',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFAAAAAA)),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: editableItems.length,
      itemBuilder: (context, index) {
        final playlist = editableItems[index];
        final selected = playlist.containsVideo(videoId);
        return ListTile(
          key: ValueKey('playlist-picker-${playlist.id}'),
          title: Text(playlist.name),
          subtitle: Text('${playlist.videoIds.length}作品'),
          trailing: Icon(
            selected ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          ),
          onTap: () async {
            await ref
                .read(playlistRepositoryProvider)
                .toggleVideo(playlist.id, videoId);
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
        );
      },
    );
  }
}

Future<PlaylistDraft?> showPlaylistEditor(
  BuildContext context, {
  UserPlaylist? playlist,
}) {
  return showDialog<PlaylistDraft>(
    context: context,
    builder: (context) => _PlaylistEditorDialog(playlist: playlist),
  );
}

class _PlaylistEditorDialog extends StatefulWidget {
  const _PlaylistEditorDialog({this.playlist});

  final UserPlaylist? playlist;

  @override
  State<_PlaylistEditorDialog> createState() => _PlaylistEditorDialogState();
}

class _PlaylistEditorDialogState extends State<_PlaylistEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late bool _isPublic;
  late bool _allowsCollaboration;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.playlist?.name);
    _descriptionController = TextEditingController(
      text: widget.playlist?.description,
    );
    _isPublic = widget.playlist?.isPublic ?? false;
    _allowsCollaboration = widget.playlist?.allowsCollaboration ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.playlist == null ? '再生リストを作成' : '再生リストを編集'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey('playlist-name-field'),
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: '名前'),
            ),
            TextField(
              key: const ValueKey('playlist-description-field'),
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '説明'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('公開する'),
              value: _isPublic,
              onChanged: (value) => setState(() => _isPublic = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('共同編集を許可'),
              value: _allowsCollaboration,
              onChanged: (value) =>
                  setState(() => _allowsCollaboration = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('キャンセル'),
        ),
        FilledButton(
          key: const ValueKey('save-playlist-button'),
          onPressed: () {
            if (_nameController.text.trim().isEmpty) {
              return;
            }
            Navigator.pop(
              context,
              PlaylistDraft(
                name: _nameController.text,
                isPublic: _isPublic,
                description: _descriptionController.text,
                allowsCollaboration: _allowsCollaboration,
              ),
            );
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
