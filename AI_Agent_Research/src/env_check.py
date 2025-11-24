import sys
import platform
import importlib
from textwrap import indent

REQUIRED_LIBS = [
    "httpx",
    "dotenv",
    "ipykernel",
]


def check_lib(name: str) -> str:
    try:
        module = importlib.import_module(name)
        version = getattr(module, "__version__", "unknown")
        return f"[OK] {name} ({version})"
    except Exception as exc:
        return f"[MISSING] {name} – {type(exc).__name__}: {exc}"


def main() -> None:
    print("=== AI Agent Research – Environment Check ===")
    print(f"Python executable: {sys.executable}")
    print(f"Python version:    {sys.version.split()[0]}")
    print(f"Platform:          {platform.system()} {platform.release()}")
    print("")

    print("Library status:")
    results = [check_lib(lib) for lib in REQUIRED_LIBS]
    print(indent("\n".join(results), "  "))

    missing = [r for r in results if r.startswith("[MISSING]")]
    print("")
    if missing:
        print("Result: environment INCOMPLETE – install the missing packages above.")
        sys.exit(1)
    else:
        print("Result: environment READY for sandbox use.")
        sys.exit(0)


if __name__ == "__main__":
    main()
