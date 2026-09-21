from __future__ import annotations

from datetime import datetime, timezone

import requests

from .models import VideoSnapshot, YouTubeComment


class YouTubeDataClient:
    _base_url = "https://www.googleapis.com/youtube/v3"

    def __init__(self, api_key: str, timeout_seconds: int = 20) -> None:
        self._api_key = api_key
        self._timeout_seconds = timeout_seconds

    def fetch_snapshot(
        self,
        video_id: str,
        *,
        max_comments: int = 200,
        comment_order: str = "relevance",
    ) -> VideoSnapshot:
        video = self._get(
            "videos",
            {"part": "snippet,statistics", "id": video_id},
        ).get("items", [])
        if not video:
            raise ValueError(f"YouTube video not found: {video_id}")
        item = video[0]
        snippet = item["snippet"]
        statistics = item.get("statistics", {})
        comments = self._fetch_comments(
            video_id,
            max_comments=max_comments,
            order=comment_order,
        )
        return VideoSnapshot(
            video_id=video_id,
            fetched_at=datetime.now(timezone.utc),
            youtube_title=snippet["title"],
            channel_title=snippet["channelTitle"],
            description=snippet.get("description", ""),
            posted_at=snippet["publishedAt"],
            default_language=snippet.get("defaultLanguage"),
            default_audio_language=snippet.get("defaultAudioLanguage"),
            view_count=int(statistics.get("viewCount", 0)),
            like_count=int(statistics.get("likeCount", 0)),
            comments=comments,
        )

    def _fetch_comments(
        self,
        video_id: str,
        *,
        max_comments: int,
        order: str,
    ) -> list[YouTubeComment]:
        comments: list[YouTubeComment] = []
        page_token: str | None = None
        while len(comments) < max_comments:
            params: dict[str, str | int] = {
                "part": "snippet",
                "videoId": video_id,
                "maxResults": min(100, max_comments - len(comments)),
                "order": order,
                "textFormat": "plainText",
            }
            if page_token:
                params["pageToken"] = page_token
            payload = self._get("commentThreads", params)
            for item in payload.get("items", []):
                top = item["snippet"]["topLevelComment"]
                snippet = top["snippet"]
                author = snippet.get("authorChannelId") or {}
                comments.append(
                    YouTubeComment(
                        comment_id=top["id"],
                        content=snippet.get("textOriginal", ""),
                        commented_at=snippet["publishedAt"],
                        like_count=int(snippet.get("likeCount", 0)),
                        author_channel_id=author.get("value"),
                    )
                )
            page_token = payload.get("nextPageToken")
            if not page_token:
                break
        return comments[:max_comments]

    def _get(self, resource: str, params: dict[str, str | int]) -> dict:
        try:
            response = requests.get(
                f"{self._base_url}/{resource}",
                params={**params, "key": self._api_key},
                timeout=self._timeout_seconds,
            )
            response.raise_for_status()
            return response.json()
        except requests.RequestException as error:
            status_code = (
                error.response.status_code if error.response is not None else None
            )
            status = f" (HTTP {status_code})" if status_code is not None else ""
            raise RuntimeError(
                f"YouTube Data API request failed for {resource}{status}"
            ) from None
