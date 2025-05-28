import difflib
import tomlkit

def unified_diff(from_str, to_str, fromfile, tofile):
    print(f"|----------------- Begin diff {fromfile} vs {tofile} -----------------|")
    diff = difflib.unified_diff(from_str, to_str, fromfile=fromfile, tofile=tofile)
    __print_colored_diff(diff)
    print(f"|----------------- End diff {fromfile} vs {tofile} -----------------|")


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



def prompt_or_assume_yes(message, assume_yes=False) -> bool:
    """
    Prompt the user for confirmation or assume 'yes' for all prompts
    """
    if not assume_yes:
        response = input(f"{message} [y/N]: ").strip().lower()
        return response in ('y', 'yes')
    else:
        print(f"{message} (assuming yes)")
        return True
    
def truncate(val, max_len=50):
    """
    Truncate a string representation of a value to a maximum length.
    """
    s = str(val)
    return s if len(s) <= max_len else s[:max_len - 3] + '...'


def scan_and_recommend_updates(original_data: tomlkit.items.Table, to_data: tomlkit.items.Table):
    """
    Scan the original data and recommend updates to the new version's data.
    """
    from .globals import ASSUME_YES


    
    for k, v in to_data.items():
        if not isinstance(v, tomlkit.items.AbstractTable):
            if k in original_data:
                if to_data[k] != original_data[k]:
                    use_recommended = prompt_or_assume_yes(
                        f"`{k}={truncate(original_data[k])}` is not recommended for new version.\n"
                        f"Do you want to apply the recommended config: `{k}={truncate(to_data[k])}`?",
                        ASSUME_YES,
                    )
                    if use_recommended:
                        print_with_checkmark(f"Apply recommended config: `{k}={truncate(to_data[k])}`")
                    else:
                        print_with_checkmark(f"Keep original config: `{k}={truncate(original_data[k])}`")
                        to_data[k] = original_data[k]
            else:
                print_with_checkmark(f"`{k}` not found in original config, using new version's default value: {truncate(v)}")
