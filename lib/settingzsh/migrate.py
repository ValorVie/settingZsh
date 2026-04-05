from __future__ import annotations

import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable

from settingzsh.deprecations import DEPRECATED_GUIDANCE


@dataclass(slots=True)
class MigrateResult:
    status: str
    managed_sections: list[str] = field(default_factory=list)
    modified_files: list[str] = field(default_factory=list)
    issues: list[str] = field(default_factory=list)


def run_migrate(
    target_home: Path,
    *,
    validator: Callable[[Path], None] | None = None,
) -> MigrateResult:
    del target_home, validator
    message = DEPRECATED_GUIDANCE["migrate"]
    print(message, file=sys.stderr)
    return MigrateResult(status="deprecated", issues=[message])
