import unittest
from unittest.mock import patch

import requests

from commentube_data.youtube_client import YouTubeDataClient


class YouTubeDataClientTests(unittest.TestCase):
    def test_request_error_does_not_include_api_key_or_request_url(self) -> None:
        api_key = "AIza" + ("x" * 35)
        leaked_error = requests.ConnectionError(
            f"connection failed: https://example.invalid?key={api_key}"
        )
        client = YouTubeDataClient(api_key)

        with patch("commentube_data.youtube_client.requests.get", side_effect=leaked_error):
            with self.assertRaises(RuntimeError) as caught:
                client._get("videos", {"id": "video-id"})

        message = str(caught.exception)
        self.assertEqual(message, "YouTube Data API request failed for videos")
        self.assertNotIn(api_key, message)
        self.assertNotIn("https://", message)

    def test_http_error_keeps_status_but_not_api_key(self) -> None:
        api_key = "AIza" + ("x" * 35)
        response = requests.Response()
        response.status_code = 403
        response.url = f"https://example.invalid?key={api_key}"
        client = YouTubeDataClient(api_key)

        with patch(
            "commentube_data.youtube_client.requests.get",
            return_value=response,
        ):
            with self.assertRaises(RuntimeError) as caught:
                client._get("commentThreads", {"videoId": "video-id"})

        message = str(caught.exception)
        self.assertEqual(
            message,
            "YouTube Data API request failed for commentThreads (HTTP 403)",
        )
        self.assertNotIn(api_key, message)
        self.assertNotIn("https://", message)


if __name__ == "__main__":
    unittest.main()
