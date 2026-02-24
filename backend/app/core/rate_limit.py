from collections import defaultdict, deque
from time import time
from threading import Lock

from fastapi import Request, status

from app.core.errors import raise_api_error


class InMemoryRateLimiter:
    def __init__(self, max_requests: int, window_seconds: int) -> None:
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self._requests: defaultdict[str, deque[float]] = defaultdict(deque)
        self._lock = Lock()

    def hit(self, key: str) -> None:
        now = time()
        with self._lock:
            q = self._requests[key]
            cutoff = now - self.window_seconds
            while q and q[0] < cutoff:
                q.popleft()
            if len(q) >= self.max_requests:
                raise_api_error(
                    status.HTTP_429_TOO_MANY_REQUESTS,
                    "RATE_LIMITED",
                    "Too many requests. Please try again later.",
                )
            q.append(now)


_auth_limiter = InMemoryRateLimiter(max_requests=30, window_seconds=60)


def auth_rate_limit(request: Request) -> None:
    ip = request.client.host if request.client else "unknown"
    key = f"auth:{ip}:{request.url.path}"
    _auth_limiter.hit(key)
