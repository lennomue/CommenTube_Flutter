import 'package:flutter/material.dart';

import '../../../core/models/quiz_filter.dart';

class HomeFilterBar extends StatelessWidget {
  const HomeFilterBar({
    super.key,
    required this.filter,
    required this.onChanged,
    required this.onOpenDetails,
  });

  final QuizFilter filter;
  final ValueChanged<QuizFilter> onChanged;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final is2010sSelected =
        filter.publishedFromYear == 2010 && filter.publishedToYear == 2019;
    return Container(
      height: 58,
      decoration: const BoxDecoration(
        color: Color(0xFF101010),
        border: Border(bottom: BorderSide(color: Color(0xFF2B2B2B))),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          ActionChip(
            key: const ValueKey('open-detailed-filters'),
            avatar: const Icon(Icons.manage_search_rounded, size: 18),
            label: Text(
              filter.isEmpty ? '絞り込み' : '絞り込み ${filter.activeConditionCount}',
            ),
            onPressed: onOpenDetails,
          ),
          const SizedBox(width: 8),
          _QuickFilterChip(
            filterKey: 'j-pop',
            label: 'J-Pop',
            selected: filter.contentGenres.contains('j_pop'),
            onSelected: () => onChanged(filter.toggleContentGenre('j_pop')),
          ),
          _QuickFilterChip(
            filterKey: 'rock',
            label: 'ロック',
            selected: filter.contentGenres.contains('rock'),
            onSelected: () => onChanged(filter.toggleContentGenre('rock')),
          ),
          _QuickFilterChip(
            filterKey: 'english',
            label: '英語（洋楽）',
            selected: filter.languages.contains('english'),
            onSelected: () => onChanged(filter.toggleLanguage('english')),
          ),
          _QuickFilterChip(
            filterKey: 'japanese',
            label: '日本語（邦楽）',
            selected: filter.languages.contains('japanese'),
            onSelected: () => onChanged(filter.toggleLanguage('japanese')),
          ),
          _QuickFilterChip(
            filterKey: '2010s',
            label: "2010's",
            selected: is2010sSelected,
            onSelected: () => onChanged(
              is2010sSelected
                  ? filter.withPublishedYears(from: null, to: null)
                  : filter.withPublishedYears(from: 2010, to: 2019),
            ),
          ),
          if (!filter.isEmpty) ...[
            const SizedBox(width: 4),
            ActionChip(
              key: const ValueKey('clear-filters'),
              avatar: const Icon(Icons.close_rounded, size: 18),
              label: const Text('解除'),
              onPressed: () => onChanged(QuizFilter.empty),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  const _QuickFilterChip({
    required this.filterKey,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String filterKey;
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        key: ValueKey('quick-filter-$filterKey'),
        label: Text(
          label,
          style: TextStyle(color: selected ? Colors.black : Colors.white),
        ),
        selected: selected,
        selectedColor: Colors.white,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

Future<QuizFilter?> showDetailedQuizFilters(
  BuildContext context,
  QuizFilter initialFilter, {
  ValueChanged<QuizFilter>? onChanged,
}) {
  return showModalBottomSheet<QuizFilter>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _DetailedFilterSheet(
      initialFilter: initialFilter,
      onChanged: onChanged,
    ),
  );
}

class _DetailedFilterSheet extends StatefulWidget {
  const _DetailedFilterSheet({
    required this.initialFilter,
    required this.onChanged,
  });

  final QuizFilter initialFilter;
  final ValueChanged<QuizFilter>? onChanged;

  @override
  State<_DetailedFilterSheet> createState() => _DetailedFilterSheetState();
}

class _DetailedFilterSheetState extends State<_DetailedFilterSheet> {
  static const _minimumYear = 2005.0;
  static const _maximumYear = 2029.0;

  late QuizFilter _filter;
  late bool _usesPublishedYears;
  late RangeValues _publishedYears;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _usesPublishedYears =
        _filter.publishedFromYear != null || _filter.publishedToYear != null;
    _publishedYears = RangeValues(
      (_filter.publishedFromYear ?? _minimumYear.toInt()).toDouble().clamp(
        _minimumYear,
        _maximumYear,
      ),
      (_filter.publishedToYear ?? _maximumYear.toInt()).toDouble().clamp(
        _minimumYear,
        _maximumYear,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF6A6A6A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '詳細な絞り込み',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _FilterSection(
                  title: '内容ジャンル',
                  options: _contentGenreOptions,
                  selectedValues: _filter.contentGenres,
                  onToggle: (value) => setState(() {
                    _filter = _filter.toggleContentGenre(value);
                    widget.onChanged?.call(_filter);
                  }),
                ),
                _FilterSection(
                  title: '言語',
                  options: _languageOptions,
                  selectedValues: _filter.languages,
                  onToggle: (value) => setState(() {
                    _filter = _filter.toggleLanguage(value);
                    widget.onChanged?.call(_filter);
                  }),
                ),
                _FilterSection(
                  title: '動画ジャンル',
                  options: _videoGenreOptions,
                  selectedValues: _filter.videoGenres,
                  onToggle: (value) => setState(() {
                    _filter = _filter.toggleVideoGenre(value);
                    widget.onChanged?.call(_filter);
                  }),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    '投稿年の範囲',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  value: _usesPublishedYears,
                  onChanged: (value) {
                    setState(() {
                      _usesPublishedYears = value;
                      _syncPublishedYears();
                      widget.onChanged?.call(_filter);
                    });
                  },
                ),
                if (_usesPublishedYears) ...[
                  Text(
                    '${_publishedYears.start.round()}年 〜 '
                    '${_publishedYears.end.round()}年',
                    textAlign: TextAlign.center,
                  ),
                  RangeSlider(
                    values: _publishedYears,
                    min: _minimumYear,
                    max: _maximumYear,
                    divisions: 24,
                    labels: RangeLabels(
                      '${_publishedYears.start.round()}年',
                      '${_publishedYears.end.round()}年',
                    ),
                    onChanged: (values) {
                      setState(() {
                        _publishedYears = values;
                        _syncPublishedYears();
                        widget.onChanged?.call(_filter);
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filter = QuizFilter.empty;
                      _usesPublishedYears = false;
                      _publishedYears = const RangeValues(
                        _minimumYear,
                        _maximumYear,
                      );
                      widget.onChanged?.call(_filter);
                    });
                  },
                  child: const Text('すべて解除'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('apply-detailed-filters'),
                    onPressed: () => Navigator.of(context).pop(_filter),
                    child: const Text('この条件で表示'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _syncPublishedYears() {
    _filter = _filter.withPublishedYears(
      from: _usesPublishedYears ? _publishedYears.start.round() : null,
      to: _usesPublishedYears ? _publishedYears.end.round() : null,
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.options,
    required this.selectedValues,
    required this.onToggle,
  });

  final String title;
  final List<_FilterOption> options;
  final List<String> selectedValues;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                FilterChip(
                  label: Text(
                    option.label,
                    style: TextStyle(
                      color: selectedValues.contains(option.value)
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                  selected: selectedValues.contains(option.value),
                  selectedColor: Colors.white,
                  onSelected: (_) => onToggle(option.value),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterOption {
  const _FilterOption(this.value, this.label);

  final String value;
  final String label;
}

const _languageOptions = [
  _FilterOption('japanese', '日本語'),
  _FilterOption('english', '英語'),
  _FilterOption('korean', '韓国語'),
  _FilterOption('spanish', 'スペイン語'),
];

const _videoGenreOptions = [
  _FilterOption('release', '楽曲'),
  _FilterOption('music_video', 'ミュージックビデオ'),
  _FilterOption('cover_video', 'カバー動画'),
  _FilterOption('lyric_video', '歌詞動画'),
  _FilterOption('live_performance_video', 'ライブ映像'),
  _FilterOption('fan_made_video', '合成MAD'),
  _FilterOption('non_music', '非音楽'),
];

const _contentGenreOptions = [
  _FilterOption('j_pop', 'J-Pop'),
  _FilterOption('j_rock', 'J-Rock'),
  _FilterOption('k_pop', 'K-Pop'),
  _FilterOption('r_and_b_soul', 'R&B・ソウル'),
  _FilterOption('anime_soundtrack', 'アニメ・サントラ'),
  _FilterOption('afro', 'アフリカ音楽'),
  _FilterOption('arabic', 'アラブ音楽'),
  _FilterOption('indie_alternative', 'インディー・オルタナ'),
  _FilterOption('country', 'カントリー'),
  _FilterOption('classical', 'クラシック'),
  _FilterOption('jazz', 'ジャズ'),
  _FilterOption('dance_electronic', 'ダンス・エレクトロニック'),
  _FilterOption('hiphop', 'ヒップホップ'),
  _FilterOption('family', 'ファミリー'),
  _FilterOption('folk_acoustic', 'フォーク・アコースティック'),
  _FilterOption('blues', 'ブルース'),
  _FilterOption('vocaloid_utaite', 'ボカロ・歌い手'),
  _FilterOption('pop', 'ポップ'),
  _FilterOption('bollywood_indian', 'ボリウッド・インド音楽'),
  _FilterOption('mandopop_cantopop', 'マンドポップ・香港ポップス'),
  _FilterOption('metal', 'メタル'),
  _FilterOption('latin', 'ラテン'),
  _FilterOption('reggae_caribbean', 'レゲエ・カリビアン'),
  _FilterOption('rock', 'ロック'),
  _FilterOption('traditional_japanese_pop', '演歌・歌謡曲'),
  _FilterOption('seasonal_spring', '春の音楽'),
  _FilterOption('seasonal_summer', '夏の音楽'),
  _FilterOption('seasonal_autumn', '秋の音楽'),
  _FilterOption('seasonal_winter', '冬の音楽'),
  _FilterOption('fan_made_video', '合成MAD'),
  _FilterOption('non_music', 'その他'),
];
