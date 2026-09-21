from __future__ import annotations

import argparse
from pathlib import Path

from .config import PROJECT_DIR, Settings
from .pipeline import (
    load_existing_quizzes,
    load_snapshot,
    make_draft,
    make_rule_review,
    prepare_jev,
    save_draft,
    save_rule_review,
    save_snapshot,
)
from .selectors import OpenAIEditorialSelector
from .youtube_client import YouTubeDataClient


def main() -> None:
    parser = argparse.ArgumentParser(description="CommenTube data preparation")
    subparsers = parser.add_subparsers(dest="command", required=True)

    collect = subparsers.add_parser("collect", help="YouTubeから動画とコメントを取得")
    collect.add_argument("video_id")
    collect.add_argument("--max-comments", type=int, default=200)

    draft = subparsers.add_parser("draft-openai", help="OpenAIでレビュー用草案を作成")
    draft.add_argument("snapshot", type=Path)
    draft.add_argument(
        "--existing-quizzes",
        type=Path,
        help="重複・関連候補を探す既存quizzes.json",
    )

    rules = subparsers.add_parser(
        "review-rules",
        help="API追加課金なしでルール判定のレビューJSON/CSVを作成",
    )
    rules.add_argument("snapshot", type=Path)
    rules.add_argument(
        "--existing-quizzes",
        type=Path,
        help="重複・関連候補を探す既存quizzes.json",
    )

    jev = subparsers.add_parser(
        "prepare-jev", help="Jev評価実験用の監査可能な入力JSONを作成"
    )
    jev.add_argument("snapshot", type=Path)

    args = parser.parse_args()
    settings = Settings.load()
    raw_dir = PROJECT_DIR / "data" / "raw"
    generated_dir = PROJECT_DIR / "data" / "generated"

    if args.command == "collect":
        snapshot = YouTubeDataClient(settings.require_youtube()).fetch_snapshot(
            args.video_id,
            max_comments=args.max_comments,
        )
        print(save_snapshot(snapshot, raw_dir))
        return

    snapshot = load_snapshot(args.snapshot)
    if args.command == "prepare-jev":
        print(prepare_jev(snapshot, generated_dir / f"{snapshot.video_id}.jev-input.json"))
        return

    if args.command == "review-rules":
        package = make_rule_review(
            snapshot,
            source_snapshot=args.snapshot,
            existing_quizzes=load_existing_quizzes(args.existing_quizzes),
        )
        for path in save_rule_review(package, generated_dir):
            print(path)
        return

    api_key, model = settings.require_openai()
    existing_quizzes = load_existing_quizzes(args.existing_quizzes)
    selector = OpenAIEditorialSelector(
        api_key=api_key,
        model=model,
        prompt_path=PROJECT_DIR / "prompts" / "comment_selection.md",
    )
    package = make_draft(
        snapshot,
        selector,
        source_snapshot=args.snapshot,
        existing_quizzes=existing_quizzes,
    )
    for path in save_draft(package, generated_dir):
        print(path)
if __name__ == "__main__":
    main()
