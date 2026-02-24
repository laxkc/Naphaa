import json
from pathlib import Path

from app.main import app


def main() -> None:
    root = Path(__file__).resolve().parents[2]
    out_path = root / "docs" / "openapi.v1.json"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(
        json.dumps(app.openapi(), indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote OpenAPI contract to {out_path}")


if __name__ == "__main__":
    main()
