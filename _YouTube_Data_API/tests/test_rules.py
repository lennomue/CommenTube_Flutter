import csv
import tempfile
import unittest
from datetime import datetime, timezone
from pathlib import Path

from commentube_data.models import VideoSnapshot, YouTubeComment
from commentube_data.pipeline import (
    find_existing_quiz_candidates,
    make_rule_review,
    save_rule_review,
)
from commentube_data.rules import detect_language, prefilter_comments
from commentube_data.selectors import build_jev_scoring_payload


def _snapshot() -> VideoSnapshot:
    now = datetime.now(timezone.utc)
    return VideoSnapshot(
        video_id="abc123",
        fetched_at=now,
        youtube_title="Exact Answer Song",
        channel_title="Answer Artist",
        description="",
        posted_at=now,
        view_count=100,
        like_count=10,
        comments=[
            YouTubeComment(
                comment_id="jp",
                content="子どもの頃の記憶が一瞬で戻ってきた",
                commented_at=now,
                like_count=30,
            ),
            YouTubeComment(
                comment_id="leak",
                content="Exact Answer Song by Answer Artist is perfect",
                commented_at=now,
                like_count=100,
            ),
            YouTubeComment(
                comment_id="spam",
                content="https://example.com aaaaaaaa",
                commented_at=now,
                like_count=1000,
            ),
        ],
    )


class RuleTests(unittest.TestCase):
    def test_prefilter_keeps_useful_japanese_comment_and_rejects_leaks(self) -> None:
        candidates = prefilter_comments(_snapshot())
        by_id = {item.comment.comment_id: item.assessment for item in candidates}
        self.assertTrue(by_id["jp"].selected)
        self.assertEqual(by_id["jp"].language, "japanese")
        self.assertFalse(by_id["leak"].selected)
        self.assertTrue(by_id["leak"].answer_leak)
        self.assertFalse(by_id["spam"].selected)
        self.assertTrue(by_id["spam"].spam_or_noise)

    def test_language_detection_and_jev_payload_are_auditable(self) -> None:
        snapshot = _snapshot()
        candidates = prefilter_comments(snapshot)
        payload = build_jev_scoring_payload(snapshot, candidates)
        self.assertEqual(detect_language("This brings back memories"), "english")
        self.assertEqual(payload["task"], "score_comment_clues")
        self.assertEqual(
            {item["comment_id"] for item in payload["comments"]},
            {"jp", "leak", "spam"},
        )

    def test_existing_quizzes_are_shortlisted_without_deciding_relation(self) -> None:
        candidates = find_existing_quiz_candidates(
            _snapshot(),
            [
                {
                    "video_id": "same-song-video",
                    "title": "Exact Answer Song (Live)",
                    "meta_data": {"keywords": ["Answer Artist"]},
                },
                {
                    "video_id": "unrelated-video",
                    "title": "Cooking Tutorial",
                    "meta_data": {"keywords": ["kitchen"]},
                },
            ],
        )
        self.assertEqual([item.video_id for item in candidates], ["same-song-video"])
        self.assertGreater(candidates[0].similarity_score, 18)

    def test_rule_review_csv_keeps_decisions_editable_without_openai(self) -> None:
        source = Path("data/raw/abc123.json")
        package = make_rule_review(
            _snapshot(),
            source_snapshot=source,
            existing_quizzes=[
                {
                    "video_id": "same-song-video",
                    "title": "Exact Answer Song (Live)",
                    "meta_data": {"keywords": ["Answer Artist"]},
                }
            ],
        )
        with tempfile.TemporaryDirectory() as directory:
            json_path, csv_path = save_rule_review(package, Path(directory))
            self.assertTrue(json_path.exists())
            with csv_path.open(encoding="utf-8-sig", newline="") as handle:
                rows = list(csv.DictReader(handle))

        by_id = {row["comment_id"]: row for row in rows}
        self.assertEqual(by_id["jp"]["rule_selected"], "True")
        self.assertEqual(by_id["leak"]["rule_selected"], "False")
        self.assertEqual(by_id["leak"]["answer_leak"], "True")
        self.assertEqual(
            by_id["jp"]["possible_existing_video_ids"],
            "same-song-video",
        )
        self.assertIn("reviewer_selected", rows[0])
        self.assertIn("reviewer_notes", rows[0])


if __name__ == "__main__":
    unittest.main()
