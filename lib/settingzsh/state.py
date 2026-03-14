from __future__ import annotations

from dataclasses import dataclass, field


@dataclass(slots=True)
class CliState:
    """Placeholder state model for upcoming tasks."""

    version: int = 1


@dataclass(slots=True)
class DoctorResult:
    """Read-only doctor result model."""

    status: str
    issues: list[str] = field(default_factory=list)
    modified_files: list[str] = field(default_factory=list)
