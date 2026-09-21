from __future__ import annotations

import re
import unicodedata
from dataclasses import dataclass

from .models import CommentAssessment, VideoSnapshot, YouTubeComment


_URL = re.compile(r"(?:https?://|www\.)", re.IGNORECASE)
_REPEATED = re.compile(r"(.)\1{7,}", re.DOTALL)
_SPACE = re.compile(r"\s+")


@dataclass(frozen=True)
class RuleCandidate:
    comment: YouTubeComment
    assessment: CommentAssessment


def normalize_text(value: str) -> str:
    return _SPACE.sub(" ", unicodedata.normalize("NFKC", value)).strip().casefold()


def prefilter_comments(
    snapshot: VideoSnapshot,
    *,
    answer_terms: list[str] | None = None,
    limit: int = 40,
) -> list[RuleCandidate]:
    terms = [
        normalize_text(term)
        for term in (answer_terms or [snapshot.youtube_title, snapshot.channel_title])
        if len(normalize_text(term)) >= 3
    ]
    seen: set[str] = set()
    candidates: list[RuleCandidate] = []
    for comment in snapshot.comments:
        normalized = normalize_text(comment.content)
        if not normalized or normalized in seen:
            continue
        seen.add(normalized)
        answer_leak = any(term in normalized for term in terms)
        spam = _URL.search(comment.content) is not None or _REPEATED.search(comment.content) is not None
        useful_length = 8 <= len(normalized) <= 220
        language = detect_language(comment.content)
        uniqueness = min(100, max(0, len(set(normalized)) * 3))
        clue_score = 30
        clue_score += min(25, comment.like_count.bit_length() * 3)
        clue_score += 20 if useful_length else -25
        clue_score += 10 if language != "unknown" else 0
        clue_score -= 70 if answer_leak else 0
        clue_score -= 60 if spam else 0
        clue_score = max(0, min(100, clue_score))
        assessment = CommentAssessment(
            comment_id=comment.comment_id,
            selected=useful_length and not answer_leak and not spam,
            clue_score=clue_score,
            uniqueness_score=uniqueness,
            answer_leak=answer_leak,
            spam_or_noise=spam,
            language=language,
            reason=_reason(useful_length, answer_leak, spam),
        )
        candidates.append(RuleCandidate(comment=comment, assessment=assessment))
    candidates.sort(
        key=lambda item: (
            item.assessment.selected,
            item.assessment.clue_score,
            item.assessment.uniqueness_score,
            item.comment.like_count,
        ),
        reverse=True,
    )
    return candidates[:limit]


def detect_language(text: str) -> str:
    if re.search(r"[ぁ-んァ-ン一-龯]", text):
        return "japanese"
    if re.search(r"[A-Za-z]", text):
        return "english"
    return "unknown"


def _reason(useful_length: bool, answer_leak: bool, spam: bool) -> str:
    reasons = []
    if not useful_length:
        reasons.append("length_out_of_range")
    if answer_leak:
        reasons.append("contains_answer_term")
    if spam:
        reasons.append("url_or_repetition")
    return ",".join(reasons) or "passed_deterministic_prefilter"
