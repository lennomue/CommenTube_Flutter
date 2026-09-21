import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/playlist.dart';
import '../../../core/models/quiz.dart';
import '../../../core/repositories/playlist_providers.dart';
import '../../../core/repositories/quiz_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/state/fullscreen_edit_controller.dart';
import '../../../core/state/quiz_experience_controller.dart';
import '../../../core/widgets/quiz_song_tile.dart';

class PlaylistScreen extends ConsumerStatefulWidget {
  const PlaylistScreen({
    super.key,
    required this.playlistId,
    this.previewPlaylist,
  });

  final String playlistId;
  final UserPlaylist? previewPlaylist;

  @override
  ConsumerState<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends ConsumerState<PlaylistScreen> {
  late final FullscreenEditController _fullscreenEditController;
  bool _isEditing = false;
  List<String>? _draftOrder;
  final List<String> _selectedVideoIds = [];
  bool _isReordering = false;
  bool _returnsToWorksTab = false;
  _PlaylistSelectionAction _selectionAction =
      _PlaylistSelectionAction.moveTogether;

  @override
  void initState() {
    super.initState();
    _fullscreenEditController = ref.read(fullscreenEditProvider.notifier);
  }

  @override
  void dispose() {
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fullscreenEditController.hide();
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playlistValue = widget.previewPlaylist == null
        ? ref.watch(playlistProvider(widget.playlistId))
        : AsyncData<UserPlaylist?>(widget.previewPlaylist);
    final quizzesValue = ref.watch(quizzesProvider);
    return Scaffold(
      body: SafeArea(
        child: playlistValue.when(
          data: (playlist) => playlist == null
              ? const Center(child: Text('再生リストが見つかりません'))
              : quizzesValue.when(
                  data: (quizzes) => _buildContent(playlist, quizzes),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) =>
                      const Center(child: Text('作品を読み込めませんでした')),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              const Center(child: Text('再生リストを読み込めませんでした')),
        ),
      ),
    );
  }

  Widget _buildContent(
    UserPlaylist playlist,
    List<QuizWithLiveStats> allQuizzes,
  ) {
    final quizzesById = {
      for (final quiz in allQuizzes) quiz.quiz.videoId: quiz,
    };
    final order = _isEditing
        ? (_draftOrder ??= List.of(playlist.videoIds))
        : playlist.videoIds;
    final quizzes = order
        .map((id) => quizzesById[id])
        .whereType<QuizWithLiveStats>()
        .toList(growable: false);
    if (_isEditing) {
      return _PlaylistSongList(
        quizzes: quizzes,
        isEditing: true,
        isReordering: _isReordering,
        selectedVideoIds: _selectedVideoIds,
        selectionAction: _selectionAction,
        onToggleEdit: () => _toggleEditing(playlist),
        onCancelEdit: _cancelEditing,
        onRemove: _removeDraftItem,
        onToggleSelected: _toggleSelected,
        onClearSelection: () => setState(_selectedVideoIds.clear),
        onSelectAll: _selectAll,
        onSelectionActionChanged: (value) =>
            setState(() => _selectionAction = value),
        onExecuteSelection: () => _executeSelection(playlist),
        onReorder: _reorder,
        onReorderStart: () => setState(() => _isReordering = true),
        onReorderEnd: () => setState(() => _isReordering = false),
        onQuizSelected: (_) {},
      );
    }
    return DefaultTabController(
      length: 2,
      initialIndex: _returnsToWorksTab ? 1 : 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 8, 4),
            child: Row(
              children: [
                IconButton(
                  key: const ValueKey('playlist-back-button'),
                  tooltip: 'ライブラリに戻る',
                  onPressed: Navigator.of(context).pop,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
                Expanded(
                  child: Text(
                    playlist.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                PopupMenuButton<_PlaylistAction>(
                  key: const ValueKey('playlist-menu-button'),
                  icon: const Icon(Icons.more_horiz_rounded),
                  onSelected: (action) =>
                      _handleAction(action, playlist, quizzes),
                  itemBuilder: (context) => playlist.isOwned
                      ? const [
                          PopupMenuItem(
                            value: _PlaylistAction.edit,
                            child: Text('編集'),
                          ),
                          PopupMenuItem(
                            value: _PlaylistAction.share,
                            child: Text('共有'),
                          ),
                          PopupMenuItem(
                            value: _PlaylistAction.delete,
                            child: Text('削除'),
                          ),
                        ]
                      : const [
                          PopupMenuItem(
                            value: _PlaylistAction.copy,
                            child: Text('プレイリストを保存'),
                          ),
                        ],
                ),
              ],
            ),
          ),
          if (playlist.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 8),
              child: Text(
                playlist.description,
                style: const TextStyle(color: Color(0xFFBBBBBB)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('start-playlist-quiz'),
                    onPressed: quizzes.isEmpty
                        ? null
                        : () => _startPlaylistQuiz(playlist, quizzes),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('この再生リストでクイズ'),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  key: const ValueKey('shuffle-playlist-quiz'),
                  tooltip: 'シャッフル再生',
                  onPressed: quizzes.length < 2
                      ? null
                      : () => _startPlaylistQuiz(
                          playlist,
                          List.of(quizzes)..shuffle(),
                        ),
                  icon: const Icon(Icons.shuffle_rounded),
                ),
              ],
            ),
          ),
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.grid_view_rounded), text: 'クイズ'),
              Tab(icon: Icon(Icons.queue_music_rounded), text: '作品'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _PlaylistQuizGrid(
                  quizzes: quizzes,
                  onQuizSelected: _openSingleQuiz,
                ),
                _PlaylistSongList(
                  quizzes: quizzes,
                  isEditing: _isEditing,
                  isReordering: _isReordering,
                  selectedVideoIds: _selectedVideoIds,
                  selectionAction: _selectionAction,
                  onToggleEdit: playlist.isOwned
                      ? () => _toggleEditing(playlist)
                      : null,
                  onCancelEdit: _cancelEditing,
                  onRemove: _removeDraftItem,
                  onToggleSelected: _toggleSelected,
                  onClearSelection: () => setState(_selectedVideoIds.clear),
                  onSelectAll: _selectAll,
                  onSelectionActionChanged: (value) =>
                      setState(() => _selectionAction = value),
                  onExecuteSelection: () => _executeSelection(playlist),
                  onReorder: _reorder,
                  onReorderStart: () => setState(() => _isReordering = true),
                  onReorderEnd: () => setState(() => _isReordering = false),
                  onQuizSelected: _isEditing ? (_) {} : _openSingleQuiz,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startPlaylistQuiz(
    UserPlaylist playlist,
    List<QuizWithLiveStats> quizzes,
  ) {
    final videoIds = quizzes
        .map((item) => item.quiz.videoId)
        .toList(growable: false);
    ref.read(artistQuizSessionProvider.notifier).clear();
    ref.read(playlistQuizSessionProvider.notifier).start(playlist.id, videoIds);
    ref.read(minimizedQuizExperienceProvider.notifier).clear();
    context.openGame(videoIds.first);
  }

  void _openSingleQuiz(String videoId) {
    ref.read(artistQuizSessionProvider.notifier).clear();
    ref.read(playlistQuizSessionProvider.notifier).clear();
    ref.read(minimizedQuizExperienceProvider.notifier).clear();
    context.openGame(videoId);
  }

  Future<void> _toggleEditing(UserPlaylist playlist) async {
    if (_isEditing) {
      await ref
          .read(playlistRepositoryProvider)
          .reorderVideos(playlist.id, _draftOrder ?? playlist.videoIds);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        _returnsToWorksTab = true;
      }
      _draftOrder = _isEditing ? List.of(playlist.videoIds) : null;
      _selectedVideoIds.clear();
      _isReordering = false;
      _selectionAction = _PlaylistSelectionAction.moveTogether;
    });
    if (_isEditing) {
      _fullscreenEditController.show();
    } else {
      _fullscreenEditController.hide();
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _draftOrder = null;
      _selectedVideoIds.clear();
      _isReordering = false;
    });
    _fullscreenEditController.hide();
  }

  void _removeDraftItem(String videoId) {
    setState(() {
      _draftOrder?.remove(videoId);
      _selectedVideoIds.remove(videoId);
    });
  }

  void _toggleSelected(String videoId) {
    setState(() {
      if (!_selectedVideoIds.remove(videoId)) {
        if (_selectedVideoIds.isEmpty) {
          _selectionAction = _PlaylistSelectionAction.moveTogether;
        }
        _selectedVideoIds.add(videoId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      for (final videoId in _draftOrder ?? const <String>[]) {
        if (!_selectedVideoIds.contains(videoId)) {
          _selectedVideoIds.add(videoId);
        }
      }
    });
  }

  Future<void> _executeSelection(UserPlaylist playlist) async {
    switch (_selectionAction) {
      case _PlaylistSelectionAction.moveTogether:
        return;
      case _PlaylistSelectionAction.orderTogether:
        _applySelectionOrder();
        return;
      case _PlaylistSelectionAction.moveToPlaylist:
        final moved = await showBatchPlaylistSheet(
          context,
          ref,
          videoIds: List.of(_selectedVideoIds),
          sourcePlaylistId: playlist.id,
        );
        if (moved && mounted) {
          setState(() {
            _draftOrder?.removeWhere(_selectedVideoIds.contains);
            _selectedVideoIds.clear();
            _selectionAction = _PlaylistSelectionAction.moveTogether;
          });
        }
    }
  }

  void _applySelectionOrder() {
    if (_selectedVideoIds.length < 2 || _draftOrder == null) {
      return;
    }
    setState(() {
      final anchor = _draftOrder!.indexOf(_selectedVideoIds.first);
      final insertAt = _draftOrder!
          .take(anchor)
          .where((id) => !_selectedVideoIds.contains(id))
          .length;
      _draftOrder!.removeWhere(_selectedVideoIds.contains);
      _draftOrder!.insertAll(
        insertAt.clamp(0, _draftOrder!.length),
        _selectedVideoIds,
      );
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final order = _draftOrder!;
      final draggedId = order[oldIndex];
      final movingIds =
          _selectionAction == _PlaylistSelectionAction.moveTogether &&
              _selectedVideoIds.contains(draggedId)
          ? order.where(_selectedVideoIds.contains).toList(growable: false)
          : [draggedId];
      final orderWithoutDragged = List<String>.of(order)..removeAt(oldIndex);
      final idsBeforeTarget = orderWithoutDragged
          .take(newIndex)
          .where((id) => !movingIds.contains(id))
          .length;
      order.removeWhere(movingIds.contains);
      order.insertAll(idsBeforeTarget.clamp(0, order.length), movingIds);
    });
  }

  Future<void> _handleAction(
    _PlaylistAction action,
    UserPlaylist playlist,
    List<QuizWithLiveStats> quizzes,
  ) async {
    switch (action) {
      case _PlaylistAction.edit:
        final draft = await showPlaylistEditor(context, playlist: playlist);
        if (draft != null) {
          await ref
              .read(playlistRepositoryProvider)
              .updatePlaylist(playlist.id, draft);
        }
        return;
      case _PlaylistAction.share:
        final box = context.findRenderObject() as RenderBox?;
        await SharePlus.instance.share(
          ShareParams(
            subject: 'CommenTube: ${playlist.name}',
            text:
                '${playlist.name}\n${quizzes.map((item) => item.quiz.title).join('\n')}',
            sharePositionOrigin: box == null
                ? null
                : box.localToGlobal(Offset.zero) & box.size,
          ),
        );
        return;
      case _PlaylistAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('再生リストを削除'),
            content: Text('「${playlist.name}」を削除しますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('削除'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await ref
              .read(playlistRepositoryProvider)
              .deletePlaylist(playlist.id);
          if (mounted) {
            Navigator.pop(context);
          }
        }
        return;
      case _PlaylistAction.copy:
        await ref.read(playlistRepositoryProvider).copyPlaylist(playlist);
        return;
    }
  }
}

enum _PlaylistAction { edit, share, delete, copy }

enum _PlaylistSelectionAction { moveTogether, orderTogether, moveToPlaylist }

class _PlaylistQuizGrid extends StatelessWidget {
  const _PlaylistQuizGrid({
    required this.quizzes,
    required this.onQuizSelected,
  });

  final List<QuizWithLiveStats> quizzes;
  final ValueChanged<String> onQuizSelected;

  @override
  Widget build(BuildContext context) {
    if (quizzes.isEmpty) {
      return const Center(child: Text('再生リストに作品がありません'));
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 28),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: quizzes.length,
      itemBuilder: (context, index) {
        final quiz = quizzes[index];
        final color = HSLColor.fromAHSL(
          1,
          quiz.quiz.atmosphereColor.hue,
          quiz.quiz.atmosphereColor.saturation.clamp(0, 1).toDouble(),
          quiz.quiz.atmosphereColor.lightness.clamp(0, 1).toDouble(),
        ).toColor();
        return Material(
          color: color,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('playlist-quiz-${quiz.quiz.videoId}'),
            onTap: () => onQuizSelected(quiz.quiz.videoId),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    quiz.quiz.thumbnailHintType == ThumbnailHintType.lyric
                        ? Icons.music_note_rounded
                        : Icons.chat_bubble_outline_rounded,
                  ),
                  const SizedBox(height: 9),
                  Text(
                    quiz.quiz.thumbnailHint?.content ?? 'ヒントはありません',
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlaylistSongList extends StatelessWidget {
  const _PlaylistSongList({
    required this.quizzes,
    required this.isEditing,
    required this.isReordering,
    required this.selectedVideoIds,
    required this.selectionAction,
    required this.onToggleEdit,
    required this.onCancelEdit,
    required this.onRemove,
    required this.onToggleSelected,
    required this.onClearSelection,
    required this.onSelectAll,
    required this.onSelectionActionChanged,
    required this.onExecuteSelection,
    required this.onReorder,
    required this.onReorderStart,
    required this.onReorderEnd,
    required this.onQuizSelected,
  });

  final List<QuizWithLiveStats> quizzes;
  final bool isEditing;
  final bool isReordering;
  final List<String> selectedVideoIds;
  final _PlaylistSelectionAction selectionAction;
  final VoidCallback? onToggleEdit;
  final VoidCallback onCancelEdit;
  final ValueChanged<String> onRemove;
  final ValueChanged<String> onToggleSelected;
  final VoidCallback onClearSelection;
  final VoidCallback onSelectAll;
  final ValueChanged<_PlaylistSelectionAction> onSelectionActionChanged;
  final VoidCallback onExecuteSelection;
  final void Function(int, int) onReorder;
  final VoidCallback onReorderStart;
  final VoidCallback onReorderEnd;
  final ValueChanged<String> onQuizSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (onToggleEdit != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                if (isEditing)
                  TextButton(
                    key: const ValueKey('cancel-playlist-edit'),
                    onPressed: onCancelEdit,
                    child: const Text('元に戻す'),
                  ),
                const Spacer(),
                TextButton.icon(
                  key: const ValueKey('toggle-playlist-reorder'),
                  onPressed: onToggleEdit,
                  icon: Icon(
                    isEditing ? Icons.done_rounded : Icons.edit_rounded,
                  ),
                  label: Text(isEditing ? '完了' : '編集'),
                ),
              ],
            ),
          ),
        if (isEditing && selectedVideoIds.isNotEmpty)
          _SelectionToolbar(
            selectedCount: selectedVideoIds.length,
            action: selectionAction,
            onActionChanged: onSelectionActionChanged,
            onClear: onClearSelection,
            onSelectAll: onSelectAll,
            onExecute: selectionAction == _PlaylistSelectionAction.moveTogether
                ? null
                : onExecuteSelection,
          ),
        Expanded(
          child: quizzes.isEmpty
              ? const Center(child: Text('再生リストに作品がありません'))
              : AnimatedContainer(
                  key: const ValueKey('playlist-reorder-drop-zone'),
                  duration: const Duration(milliseconds: 120),
                  color: isReordering
                      ? const Color(0xFF16486E)
                      : Colors.transparent,
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    buildDefaultDragHandles: false,
                    itemCount: quizzes.length,
                    onReorderItem: isEditing ? onReorder : (_, _) {},
                    onReorderStart: isEditing ? (_) => onReorderStart() : null,
                    onReorderEnd: isEditing ? (_) => onReorderEnd() : null,
                    proxyDecorator: (child, index, animation) =>
                        AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) => Material(
                            color: Colors.transparent,
                            elevation: 12 * animation.value,
                            borderRadius: BorderRadius.circular(14),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF2F9CFF),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: child,
                            ),
                          ),
                          child: child,
                        ),
                    itemBuilder: (context, index) {
                      final quiz = quizzes[index];
                      final videoId = quiz.quiz.videoId;
                      final selectionIndex = selectedVideoIds.indexOf(videoId);
                      final showsDragHandle =
                          isEditing &&
                          (selectedVideoIds.isEmpty ||
                              (selectionAction ==
                                      _PlaylistSelectionAction.moveTogether &&
                                  videoId == selectedVideoIds.first));
                      return ColoredBox(
                        key: ValueKey('playlist-song-${quiz.quiz.videoId}'),
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              if (isEditing)
                                IconButton(
                                  key: ValueKey(
                                    'remove-playlist-item-$videoId',
                                  ),
                                  tooltip: '再生リストから削除',
                                  onPressed: () => onRemove(videoId),
                                  icon: const Icon(
                                    Icons.remove_circle,
                                    color: Colors.red,
                                  ),
                                ),
                              Expanded(
                                child: AnimatedOpacity(
                                  key: ValueKey(
                                    'playlist-item-opacity-$videoId',
                                  ),
                                  duration: const Duration(milliseconds: 150),
                                  opacity: selectionIndex > 0 ? 0.42 : 1,
                                  child: QuizSongTile(
                                    quiz: quiz,
                                    showActions: !isEditing,
                                    enabled: !isEditing,
                                    onOpen: () => onQuizSelected(videoId),
                                  ),
                                ),
                              ),
                              if (isEditing) ...[
                                const SizedBox(width: 10),
                                InkWell(
                                  key: ValueKey(
                                    'select-playlist-item-$videoId',
                                  ),
                                  onTap: () => onToggleSelected(videoId),
                                  borderRadius: BorderRadius.circular(99),
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: selectionIndex >= 0
                                          ? Colors.white
                                          : Colors.transparent,
                                      border: Border.all(color: Colors.white),
                                    ),
                                    child: selectionIndex >= 0
                                        ? Text(
                                            selectionAction ==
                                                    _PlaylistSelectionAction
                                                        .orderTogether
                                                ? '${selectionIndex + 1}'
                                                : '✓',
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (showsDragHandle)
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: const Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        4,
                                        10,
                                        10,
                                        10,
                                      ),
                                      child: Icon(Icons.drag_handle_rounded),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _SelectionToolbar extends StatelessWidget {
  const _SelectionToolbar({
    required this.selectedCount,
    required this.action,
    required this.onActionChanged,
    required this.onClear,
    required this.onSelectAll,
    required this.onExecute,
  });

  final int selectedCount;
  final _PlaylistSelectionAction action;
  final ValueChanged<_PlaylistSelectionAction> onActionChanged;
  final VoidCallback onClear;
  final VoidCallback onSelectAll;
  final VoidCallback? onExecute;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$selectedCount個選択中',
                style: const TextStyle(
                  color: Color(0xFFBDBDBD),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(
                key: const ValueKey('select-all-playlist-items'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFBDBDBD),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: onSelectAll,
                child: const Text('すべて選択'),
              ),
              TextButton(
                key: const ValueKey('clear-playlist-selection'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFBDBDBD),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: onClear,
                child: const Text('選択解除'),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ChoiceChip(
                label: const Text('まとめて移動'),
                selected: action == _PlaylistSelectionAction.moveTogether,
                onSelected: (_) =>
                    onActionChanged(_PlaylistSelectionAction.moveTogether),
              ),
              ChoiceChip(
                label: const Text('別のプレイリストへ移動'),
                selected: action == _PlaylistSelectionAction.moveToPlaylist,
                onSelected: (_) =>
                    onActionChanged(_PlaylistSelectionAction.moveToPlaylist),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ChoiceChip(
                label: const Text('選択順に並べる'),
                selected: action == _PlaylistSelectionAction.orderTogether,
                onSelected: (_) =>
                    onActionChanged(_PlaylistSelectionAction.orderTogether),
              ),
              OutlinedButton(
                key: const ValueKey('apply-playlist-selection'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: onExecute == null
                        ? const Color(0xFF666666)
                        : Colors.white,
                    width: onExecute == null ? 1 : 2.4,
                  ),
                  foregroundColor: Colors.white,
                ),
                onPressed: onExecute,
                child: const Text(
                  '実行',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
