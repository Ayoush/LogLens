from dataclasses import dataclass
from datetime import datetime


@dataclass(frozen=True)
class LogEntry:
    timestamp: datetime
    level: str
    source: str
    message: str
    raw_text: str
