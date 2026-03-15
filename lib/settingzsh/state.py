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


@dataclass(slots=True)
class ShellValidationResult:
    """Result of syntax + interactive shell validation."""

    status: str
    issues: list[str] = field(default_factory=list)
    syntax_stdout: str = ""
    syntax_stderr: str = ""
    interactive_stdout: str = ""
    interactive_stderr: str = ""


@dataclass(slots=True)
class PreflightResult:
    """Blocking adoption gate result."""

    status: str
    issues: list[str] = field(default_factory=list)
    details: dict[str, list[str]] = field(default_factory=dict)
    modified_files: list[str] = field(default_factory=list)


@dataclass(slots=True)
class AdoptResult:
    """Read-only adopt report result with backup side effects only."""

    status: str
    issues: list[str] = field(default_factory=list)
    modified_files: list[str] = field(default_factory=list)


@dataclass(slots=True)
class LegacyImportResult:
    """Draft legacy import result."""

    status: str
    issues: list[str] = field(default_factory=list)
    modified_files: list[str] = field(default_factory=list)
