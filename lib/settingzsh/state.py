from __future__ import annotations

from dataclasses import dataclass


@dataclass(slots=True)
class CliState:
    """Placeholder state model for upcoming tasks."""

    version: int = 1
