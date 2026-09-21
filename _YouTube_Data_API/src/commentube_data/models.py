from __future__ import annotations

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field, field_validator


class YouTubeComment(BaseModel):
    comment_id: str
    content: str
    commented_at: datetime
    like_count: int = 0
    author_channel_id: str | None = None


class VideoSnapshot(BaseModel):
    video_id: str
    fetched_at: datetime
    youtube_title: str
    channel_title: str
    description: str
    posted_at: datetime
    default_language: str | None = None
    default_audio_language: str | None = None
    view_count: int = 0
    like_count: int = 0
    comments: list[YouTubeComment]


class CommentAssessment(BaseModel):
    comment_id: str
    selected: bool
    clue_score: int = Field(ge=0, le=100)
    uniqueness_score: int = Field(ge=0, le=100)
    answer_leak: bool
    spam_or_noise: bool
    language: str
    reason: str


class ArtistProposal(BaseModel):
    name: str
    sub_names: list[str] = Field(default_factory=list)
    role: str
    evidence: str


class ExistingQuizCandidate(BaseModel):
    video_id: str
    title: str
    keywords: list[str] = Field(default_factory=list)
    similarity_score: int = Field(default=0, ge=0, le=100)


class EditorialDecision(BaseModel):
    display_title: str
    video_genre: str
    content_genres: list[str]
    languages: list[str]
    thumbnail_hint_type: Literal["comment", "lyric"] = "comment"
    comment_assessments: list[CommentAssessment]
    artists: list[ArtistProposal]
    keywords: list[str] = Field(default_factory=list)
    possible_existing_video_ids: list[str] = Field(default_factory=list)
    review_notes: list[str] = Field(default_factory=list)

    @field_validator("content_genres", "languages")
    @classmethod
    def reject_empty_required_lists(cls, value: list[str]) -> list[str]:
        if not value:
            raise ValueError("at least one value is required")
        return value


class DraftComment(BaseModel):
    comment_id: str
    commented_at: datetime
    content: str
    comment_favorite_count: int
    comment_favorite_count_last_updated_at: str


class QuizDraft(BaseModel):
    video_id: str
    video_atmosphere_color: dict[str, float] = Field(
        default_factory=lambda: {"h": 220.0, "s": 0.6, "l": 0.08}
    )
    content_genres: list[str]
    video_genre: str
    title: str
    languages: list[str]
    posted_at: datetime
    video_favorite_count: int
    video_view_count: int
    video_favorite_count_last_updated_at: str
    video_view_count_last_updated_at: str
    music_released_at: dict[str, str] | None = None
    thumbnail_hint_type: Literal["comment", "lyric"]
    music_lyrics: list[str] | None = None
    comments: list[DraftComment]
    meta_data: dict[str, list[str]]
    embedding: None = None


class ArtistDraft(BaseModel):
    artist_id: str
    name: str
    sub_names: list[str]
    embedding: None = None


class ArtistVideoJunctionDraft(BaseModel):
    artist_id: str
    video_id: str


class ReviewRecord(BaseModel):
    status: Literal["needs_review", "approved", "rejected"] = "needs_review"
    provider: str
    generated_at: datetime
    source_snapshot: str
    warnings: list[str] = Field(default_factory=list)
    possible_existing_video_ids: list[str] = Field(default_factory=list)
    reviewer: str = ""
    reviewer_notes: str = ""


class DraftPackage(BaseModel):
    quiz: QuizDraft
    artists: list[ArtistDraft]
    artist_videos_junction: list[ArtistVideoJunctionDraft]
    comment_assessments: list[CommentAssessment]
    review: ReviewRecord


class RuleReviewCandidate(BaseModel):
    comment: YouTubeComment
    assessment: CommentAssessment
    reviewer_selected: bool | None = None
    reviewer_notes: str = ""


class RuleReviewPackage(BaseModel):
    status: Literal["needs_review", "approved", "rejected"] = "needs_review"
    provider: Literal["deterministic_rules"] = "deterministic_rules"
    generated_at: datetime
    source_snapshot: str
    video_id: str
    youtube_title: str
    channel_title: str
    default_language: str | None = None
    default_audio_language: str | None = None
    possible_existing_video_ids: list[str] = Field(default_factory=list)
    candidates: list[RuleReviewCandidate]
    reviewer: str = ""
    reviewer_notes: str = ""
