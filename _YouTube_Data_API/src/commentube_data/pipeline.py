from __future__ import annotations

import csv
import difflib
import json
import re
import uuid
from datetime import datetime, timezone
from pathlib import Path

from .models import (
    ArtistDraft,
    ArtistVideoJunctionDraft,
    DraftComment,
    DraftPackage,
    ExistingQuizCandidate,
    QuizDraft,
    ReviewRecord,
    RuleReviewCandidate,
    RuleReviewPackage,
    VideoSnapshot,
)
from .rules import prefilter_comments
from .selectors import EditorialSelector, build_jev_scoring_payload


def save_snapshot(snapshot: VideoSnapshot, raw_dir: Path) -> Path:
    raw_dir.mkdir(parents=True, exist_ok=True)
    path = raw_dir / f"{snapshot.video_id}.json"
    _write_json(path, snapshot.model_dump(mode="json"))
    return path


def load_snapshot(path: Path) -> VideoSnapshot:
    return VideoSnapshot.model_validate_json(path.read_text(encoding="utf-8"))


def prepare_jev(snapshot: VideoSnapshot, output_path: Path) -> Path:
    candidates = prefilter_comments(snapshot)
    _write_json(output_path, build_jev_scoring_payload(snapshot, candidates))
    return output_path


def make_rule_review(
    snapshot: VideoSnapshot,
    *,
    source_snapshot: Path,
    existing_quizzes: list[dict] | None = None,
) -> RuleReviewPackage:
    candidates = prefilter_comments(snapshot)
    existing_candidates = find_existing_quiz_candidates(
        snapshot,
        existing_quizzes or [],
    )
    return RuleReviewPackage(
        generated_at=datetime.now(timezone.utc),
        source_snapshot=str(source_snapshot),
        video_id=snapshot.video_id,
        youtube_title=snapshot.youtube_title,
        channel_title=snapshot.channel_title,
        default_language=snapshot.default_language,
        default_audio_language=snapshot.default_audio_language,
        possible_existing_video_ids=[
            item.video_id for item in existing_candidates
        ],
        candidates=[
            RuleReviewCandidate(
                comment=item.comment,
                assessment=item.assessment,
            )
            for item in candidates
        ],
    )


def make_draft(
    snapshot: VideoSnapshot,
    selector: EditorialSelector,
    *,
    source_snapshot: Path,
    existing_quizzes: list[dict] | None = None,
) -> DraftPackage:
    candidates = prefilter_comments(snapshot)
    existing_candidates = find_existing_quiz_candidates(
        snapshot,
        existing_quizzes or [],
    )
    decision = selector.decide(snapshot, candidates, existing_candidates)
    candidate_by_id = {item.comment.comment_id: item.comment for item in candidates}
    selected_ids = [
        item.comment_id
        for item in decision.comment_assessments
        if item.selected and not item.answer_leak and not item.spam_or_noise
    ][:5]
    selected_comments = [
        candidate_by_id[item] for item in selected_ids if item in candidate_by_id
    ]
    if not selected_comments:
        raise ValueError("採用可能なコメントがありません。候補または判定を見直してください")

    today = datetime.now(timezone.utc).date().isoformat()
    quiz = QuizDraft(
        video_id=snapshot.video_id,
        content_genres=decision.content_genres,
        video_genre=decision.video_genre,
        title=decision.display_title,
        languages=decision.languages,
        posted_at=snapshot.posted_at,
        video_favorite_count=snapshot.like_count,
        video_view_count=snapshot.view_count,
        video_favorite_count_last_updated_at=today,
        video_view_count_last_updated_at=today,
        thumbnail_hint_type="comment",
        comments=[
            DraftComment(
                comment_id=item.comment_id,
                commented_at=item.commented_at,
                content=item.content,
                comment_favorite_count=item.like_count,
                comment_favorite_count_last_updated_at=today,
            )
            for item in selected_comments
        ],
        meta_data={
            "keywords": decision.keywords,
            "related_works": [],
        },
    )
    artists = [
        ArtistDraft(
            artist_id=str(uuid.uuid5(uuid.NAMESPACE_URL, f"commentube:artist:{item.name.casefold()}")),
            name=item.name,
            sub_names=item.sub_names,
        )
        for item in decision.artists
    ]
    junctions = [
        ArtistVideoJunctionDraft(artist_id=item.artist_id, video_id=snapshot.video_id)
        for item in artists
    ]
    known = {item.video_id for item in existing_candidates}
    possible_existing = sorted(
        set(decision.possible_existing_video_ids).intersection(known)
    )
    warnings = list(decision.review_notes)
    if len({item.language for item in decision.comment_assessments if item.selected}) == 1:
        warnings.append("選択コメントの言語が1種類だけです。元動画の視聴者言語と照合してください")
    if decision.thumbnail_hint_type == "lyric":
        warnings.append("歌詞は自動採用しません。権利と原文を確認後に手動入力してください")
    return DraftPackage(
        quiz=quiz,
        artists=artists,
        artist_videos_junction=junctions,
        comment_assessments=decision.comment_assessments,
        review=ReviewRecord(
            provider=selector.provider_name,
            generated_at=datetime.now(timezone.utc),
            source_snapshot=str(source_snapshot),
            warnings=warnings,
            possible_existing_video_ids=possible_existing,
        ),
    )


def load_existing_quizzes(path: Path | None) -> list[dict]:
    if path is None:
        return []
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, list):
        raise ValueError("既存クイズJSONのルートは配列である必要があります")
    return [item for item in payload if isinstance(item, dict)]


def find_existing_quiz_candidates(
    snapshot: VideoSnapshot,
    existing_quizzes: list[dict],
    *,
    limit: int = 12,
) -> list[ExistingQuizCandidate]:
    source = _search_tokens(
        " ".join(
            [snapshot.youtube_title, snapshot.channel_title, snapshot.description[:500]]
        )
    )
    source_text = " ".join(sorted(source))
    ranked: list[ExistingQuizCandidate] = []
    for item in existing_quizzes:
        video_id = str(item.get("video_id", "")).strip()
        title = str(item.get("title", "")).strip()
        if not video_id or not title or video_id == snapshot.video_id:
            continue
        meta = item.get("meta_data")
        keywords = meta.get("keywords", []) if isinstance(meta, dict) else []
        keywords = [str(value) for value in keywords if str(value).strip()]
        target = _search_tokens(" ".join([title, *keywords]))
        overlap = len(source.intersection(target)) / max(1, len(target))
        sequence = difflib.SequenceMatcher(
            None,
            source_text,
            " ".join(sorted(target)),
        ).ratio()
        score = round(max(overlap, sequence) * 100)
        if score < 18:
            continue
        ranked.append(
            ExistingQuizCandidate(
                video_id=video_id,
                title=title,
                keywords=keywords,
                similarity_score=score,
            )
        )
    ranked.sort(key=lambda item: (-item.similarity_score, item.video_id))
    return ranked[:limit]


def save_draft(package: DraftPackage, output_dir: Path) -> tuple[Path, Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    json_path = output_dir / f"{package.quiz.video_id}.review.json"
    csv_path = output_dir / f"{package.quiz.video_id}.review.csv"
    _write_json(json_path, package.model_dump(mode="json"))
    with csv_path.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "status",
                "video_id",
                "title",
                "video_genre",
                "content_genres",
                "languages",
                "artist_names",
                "selected_comment_ids",
                "selected_comments",
                "possible_existing_video_ids",
                "warnings",
                "reviewer",
                "reviewer_notes",
            ],
        )
        writer.writeheader()
        writer.writerow(
            {
                "status": package.review.status,
                "video_id": package.quiz.video_id,
                "title": package.quiz.title,
                "video_genre": package.quiz.video_genre,
                "content_genres": " | ".join(package.quiz.content_genres),
                "languages": " | ".join(package.quiz.languages),
                "artist_names": " | ".join(item.name for item in package.artists),
                "selected_comment_ids": " | ".join(
                    item.comment_id for item in package.quiz.comments
                ),
                "selected_comments": " | ".join(
                    item.content.replace("\n", " ") for item in package.quiz.comments
                ),
                "possible_existing_video_ids": " | ".join(
                    package.review.possible_existing_video_ids
                ),
                "warnings": " | ".join(package.review.warnings),
                "reviewer": package.review.reviewer,
                "reviewer_notes": package.review.reviewer_notes,
            }
        )
    return json_path, csv_path


def save_rule_review(
    package: RuleReviewPackage,
    output_dir: Path,
) -> tuple[Path, Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    json_path = output_dir / f"{package.video_id}.rules-review.json"
    csv_path = output_dir / f"{package.video_id}.rules-review.csv"
    _write_json(json_path, package.model_dump(mode="json"))
    with csv_path.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "status",
                "video_id",
                "youtube_title",
                "channel_title",
                "comment_id",
                "comment",
                "like_count",
                "commented_at",
                "detected_language",
                "rule_selected",
                "clue_score",
                "uniqueness_score",
                "answer_leak",
                "spam_or_noise",
                "rule_reason",
                "possible_existing_video_ids",
                "reviewer_selected",
                "reviewer_notes",
            ],
        )
        writer.writeheader()
        for item in package.candidates:
            writer.writerow(
                {
                    "status": package.status,
                    "video_id": package.video_id,
                    "youtube_title": package.youtube_title,
                    "channel_title": package.channel_title,
                    "comment_id": item.comment.comment_id,
                    "comment": item.comment.content.replace("\n", " "),
                    "like_count": item.comment.like_count,
                    "commented_at": item.comment.commented_at.isoformat(),
                    "detected_language": item.assessment.language,
                    "rule_selected": item.assessment.selected,
                    "clue_score": item.assessment.clue_score,
                    "uniqueness_score": item.assessment.uniqueness_score,
                    "answer_leak": item.assessment.answer_leak,
                    "spam_or_noise": item.assessment.spam_or_noise,
                    "rule_reason": item.assessment.reason,
                    "possible_existing_video_ids": " | ".join(
                        package.possible_existing_video_ids
                    ),
                    "reviewer_selected": item.reviewer_selected,
                    "reviewer_notes": item.reviewer_notes,
                }
            )
    return json_path, csv_path


def _write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def _search_tokens(value: str) -> set[str]:
    normalized = re.sub(r"[^\wぁ-んァ-ン一-龯]+", " ", value.casefold())
    return {token for token in normalized.split() if len(token) >= 2}
