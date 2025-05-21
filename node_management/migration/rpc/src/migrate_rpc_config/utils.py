import difflib


def unified_diff(from_str, to_str, fromfile, tofile):
    diff = difflib.unified_diff(from_str, to_str, fromfile=fromfile, tofile=tofile)
    __print_colored_diff(diff)


def __print_colored_diff(diff):
    # The color is added here manually using ANSI escape codes.
    for line in diff:
        if line.startswith("+") and not line.startswith("+++"):
            print(f"\033[32m{line}\033[0m", end="")  # Green for additions
        elif line.startswith("-") and not line.startswith("---"):
            print(f"\033[31m{line}\033[0m", end="")  # Red for deletions
        elif line.startswith("@@"):
            print(f"\033[36m{line}\033[0m", end="")  # Cyan for hunk headers
        else:
            print(line, end="")


def print_with_checkmark(message):
    """
    Print a message with a checkmark.
    """
    print(f"✓ {message}")
