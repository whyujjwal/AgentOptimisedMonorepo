"""Structured logging setup.

Usage in any module:
    from app.core.logging import get_logger
    logger = get_logger(__name__)

    logger.info("user signed up", user_id=42, plan="pro")
    logger.error("payment failed", order_id="abc", exc_info=True)

This gives you:
  - Human-readable colored output in development (LOG_JSON=False)
  - Machine-parseable JSON lines in production (LOG_JSON=True)
  - Automatic context: timestamp, level, logger name, module, line number
"""

import logging
import json
import sys
from typing import Any

from app.core.config import settings


class StructuredFormatter(logging.Formatter):
    """JSON formatter for production — one JSON object per log line."""

    def format(self, record: logging.LogRecord) -> str:
        log_entry: dict[str, Any] = {
            "timestamp": self.formatTime(record, self.datefmt),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "line": record.lineno,
        }

        # Merge extra structured fields passed via logger.info("msg", extra={...})
        if hasattr(record, "structured_data"):
            log_entry.update(record.structured_data)

        if record.exc_info and record.exc_info[1]:
            log_entry["exception"] = self.formatException(record.exc_info)

        return json.dumps(log_entry, default=str)


class DevFormatter(logging.Formatter):
    """Colored, human-readable formatter for local development."""

    COLORS = {
        "DEBUG": "\033[36m",     # cyan
        "INFO": "\033[32m",      # green
        "WARNING": "\033[33m",   # yellow
        "ERROR": "\033[31m",     # red
        "CRITICAL": "\033[1;31m",  # bold red
    }
    RESET = "\033[0m"

    def format(self, record: logging.LogRecord) -> str:
        color = self.COLORS.get(record.levelname, self.RESET)
        timestamp = self.formatTime(record, "%H:%M:%S")
        base = (
            f"{color}{record.levelname:<8}{self.RESET} "
            f"{timestamp} "
            f"[{record.name}:{record.lineno}] "
            f"{record.getMessage()}"
        )

        # Append structured key=value pairs if present
        if hasattr(record, "structured_data"):
            extras = " ".join(
                f"{k}={v!r}" for k, v in record.structured_data.items()
            )
            base += f"  | {extras}"

        if record.exc_info and record.exc_info[1]:
            base += "\n" + self.formatException(record.exc_info)

        return base


class StructuredLogger(logging.Logger):
    """Logger subclass that accepts keyword arguments as structured data."""

    def _log(
        self,
        level: int,
        msg: object,
        args: Any,
        exc_info: Any = None,
        extra: dict | None = None,
        stack_info: bool = False,
        stacklevel: int = 1,
        **kwargs: Any,
    ) -> None:
        if extra is None:
            extra = {}
        if kwargs:
            extra["structured_data"] = kwargs
        super()._log(level, msg, args, exc_info, extra, stack_info, stacklevel + 1)


# Register our custom logger class
logging.setLoggerClass(StructuredLogger)


def setup_logging() -> None:
    """Configure root logging. Called once at app startup."""
    root = logging.getLogger()
    root.setLevel(settings.LOG_LEVEL.upper())

    # Remove existing handlers to avoid duplicates on reload
    root.handlers.clear()

    handler = logging.StreamHandler(sys.stdout)

    if settings.LOG_JSON:
        handler.setFormatter(StructuredFormatter())
    else:
        handler.setFormatter(DevFormatter())

    root.addHandler(handler)

    # Quiet noisy third-party loggers
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    logging.getLogger("sqlalchemy.engine").setLevel(
        logging.DEBUG if settings.DEBUG else logging.WARNING
    )


def get_logger(name: str) -> StructuredLogger:
    """Get a structured logger by name.

    Usage:
        logger = get_logger(__name__)
        logger.info("something happened", key="value", count=42)
    """
    return logging.getLogger(name)  # type: ignore[return-value]
