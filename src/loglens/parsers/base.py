from abc import ABC, abstractmethod

from loglens.models import LogEntry


class LogParser(ABC):
    @abstractmethod
    def parse_line(self, line: str) -> LogEntry: ...
