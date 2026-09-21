from __future__ import annotations

import json
from pathlib import Path
from typing import Protocol

from openai import OpenAI

from .models import EditorialDecision, ExistingQuizCandidate, VideoSnapshot
from .rules import RuleCandidate


class EditorialSelector(Protocol):
    provider_name: str

    def decide(
        self,
        snapshot: VideoSnapshot,
        candidates: list[RuleCandidate],
        existing_quiz_candidates: list[ExistingQuizCandidate],
    ) -> EditorialDecision: ...


class OpenAIEditorialSelector:
    provider_name = "openai_structured_outputs"

    def __init__(self, *, api_key: str, model: str, prompt_path: Path) -> None:
        self._client = OpenAI(api_key=api_key)
        self._model = model
        self._instructions = prompt_path.read_text(encoding="utf-8")

    def decide(
        self,
        snapshot: VideoSnapshot,
        candidates: list[RuleCandidate],
        existing_quiz_candidates: list[ExistingQuizCandidate],
    ) -> EditorialDecision:
        candidate_payload = [
            {
                "comment_id": item.comment.comment_id,
                "content": item.comment.content,
                "like_count": item.comment.like_count,
                "commented_at": item.comment.commented_at.isoformat(),
                "rule_assessment": item.assessment.model_dump(mode="json"),
            }
            for item in candidates
        ]
        response = self._client.responses.parse(
            model=self._model,
            input=[
                {"role": "system", "content": self._instructions},
                {
                    "role": "user",
                    "content": json.dumps(
                        {
                            "video": snapshot.model_dump(
                                mode="json", exclude={"comments"}
                            ),
                            "candidate_comments": candidate_payload,
                            "existing_quiz_candidates": [
                                item.model_dump(mode="json")
                                for item in existing_quiz_candidates
                            ],
                        },
                        ensure_ascii=False,
                    ),
                },
            ],
            text_format=EditorialDecision,
        )
        if response.output_parsed is None:
            raise RuntimeError("OpenAIから構造化された判定を取得できませんでした")
        return response.output_parsed


def build_jev_scoring_payload(
    snapshot: VideoSnapshot,
    candidates: list[RuleCandidate],
) -> dict:
    """Build a provider-neutral Jev experiment input without making a request.

    Jev is used only as a semantic scorer. It must not create titles, artist facts,
    or relations. Keeping this boundary makes its output replaceable and auditable.
    """

    return {
        "schema_version": 1,
        "task": "score_comment_clues",
        "video_context": {
            "video_id": snapshot.video_id,
            "youtube_title": snapshot.youtube_title,
            "channel_title": snapshot.channel_title,
        },
        "criteria": {
            "specific_to_video_without_revealing_answer": "score_0_to_100",
            "memorable_or_informative": "score_0_to_100",
            "spam_or_noise": "boolean",
            "answer_leak": "boolean",
        },
        "comments": [
            {
                "comment_id": item.comment.comment_id,
                "content": item.comment.content,
                "deterministic_score": item.assessment.clue_score,
                "detected_language": item.assessment.language,
            }
            for item in candidates
        ],
    }
