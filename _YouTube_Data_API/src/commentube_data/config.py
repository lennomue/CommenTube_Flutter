from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv


PROJECT_DIR = Path(__file__).resolve().parents[2]


@dataclass(frozen=True)
class Settings:
    youtube_api_key: str | None
    openai_api_key: str | None
    openai_model: str | None
    typesafe_api_key: str | None
    jev_model: str

    @classmethod
    def load(cls) -> "Settings":
        load_dotenv(PROJECT_DIR / ".env")
        return cls(
            youtube_api_key=_clean(os.getenv("YOUTUBE_API_KEY")),
            openai_api_key=_clean(os.getenv("OPENAI_API_KEY")),
            openai_model=_clean(os.getenv("OPENAI_MODEL")),
            typesafe_api_key=_clean(os.getenv("TYPESAFE_API_KEY")),
            jev_model=_clean(os.getenv("JEV_MODEL")) or "jev-latest",
        )

    def require_youtube(self) -> str:
        if not self.youtube_api_key:
            raise RuntimeError(".env に YOUTUBE_API_KEY を設定してください")
        return self.youtube_api_key

    def require_openai(self) -> tuple[str, str]:
        if not self.openai_api_key:
            raise RuntimeError(".env に OPENAI_API_KEY を設定してください")
        if not self.openai_model:
            raise RuntimeError(".env に利用可能な OPENAI_MODEL を設定してください")
        return self.openai_api_key, self.openai_model


def _clean(value: str | None) -> str | None:
    if value is None:
        return None
    stripped = value.strip()
    return stripped or None
