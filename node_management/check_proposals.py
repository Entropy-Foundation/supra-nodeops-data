import os
import re
import sys

"""
This script parses the given log file or directory to find the block proposals made by this validator
and classify them as either committed or not committed.

If your node is consistently producing proposals that are marked with `committed: False`, then either:
    1. Your local consensus key might not match the key that is registered on chain, or:
    2. Your node is not able to deliver its proposal to enough of the members of the current
       validator committee within the (as of 2025-05-15) 3.5s consensus timeout. This might happen
       if your node is under-provisioned, or if you are running multiple nodes on the same machine,
       or if your node is experiencing network issues.

In the former case, please use the `supra node rotate-consensus-key` command to register a new consensus
key on-chain and wait for the next epoch to begin. If the transaction was successful then your node
should start generating committed proposals again.

In the latter case, please review your node's configuration and ensure that it matches the outlined in
your SLA. If issues persist, please contact Supra support via Discord.

Example usage:
```
python3 check_proposals.py <host_supra_home>/smr_node_logs/
```
"""

def extract_proposal_info(line: str):
    proposal_match = re.search(r'proposal:\s+([a-f0-9]{64})', line)
    epoch_match = re.search(r'epoch:\s+(\d+)', line)
    round_match = re.search(r'round:\s+(\d+)', line)
    height_match = re.search(r'height:\s+(\d+)', line)
    local_dt_match = re.search(r'local_date_time:\s+"([^"]+)"', line)

    if proposal_match and epoch_match and round_match and height_match and local_dt_match:
        return {
            "hash": proposal_match.group(1),
            "epoch": int(epoch_match.group(1)),
            "round": int(round_match.group(1)),
            "height": int(height_match.group(1)),
            "local_date_time": local_dt_match.group(1)
        }
    return None


def extract_committed_block_info(line: str):
    block_match = re.search(r'block:\s+([a-f0-9]{64})', line)
    epoch_match = re.search(r'epoch:\s+(\d+)', line)
    round_match = re.search(r'round:\s+(\d+)', line)
    height_match = re.search(r'height:\s+(\d+)', line)

    if block_match and epoch_match and round_match and height_match:
        return {
            "hash": block_match.group(1),
            "epoch": int(epoch_match.group(1)),
            "round": int(round_match.group(1)),
            "height": int(height_match.group(1))
        }
    return None


def parse_log_file(filepath, proposals, committed_blocks):
    try:
        with open(filepath, 'r') as f:
            for line in f:
                if "Proposing" in line and "SmrBlock" in line:
                    info = extract_proposal_info(line)
                    if info:
                        proposals[info["local_date_time"]] = info["hash"], info["epoch"], info["round"], info["height"]
                elif "Committing" in line and "CertifiedBlock" in line:
                    info = extract_committed_block_info(line)
                    if info:
                        committed_blocks.add((info["hash"], info["epoch"], info["round"], info["height"]))
    except Exception as e:
        print(f"Error reading file {filepath}: {e}")


def main(path):
    proposals = {}
    committed_blocks = set()
    
    # If the path is a directory, get all files
    if os.path.isdir(path):
        filepaths = [os.path.join(path, f) for f in os.listdir(path) if os.path.isfile(os.path.join(path, f))]
    elif os.path.isfile(path):
        filepaths = [path]
    else:
        print(f"Error: {path} is not a valid file or directory.")
        sys.exit(1)

    for filepath in filepaths:
        parse_log_file(filepath, proposals, committed_blocks)

    # Sort by height
    proposals = sorted(proposals.items(), key=lambda e: e[1][3])

    # Report all proposals with committed status
    for local_date_time, (block_hash, epoch, round, height) in proposals:
        is_committed = (block_hash, epoch, round, height) in committed_blocks
        print({
            "block_timestamp_local_date_time": local_date_time,
            "block_hash": block_hash,
            "epoch": epoch,
            "round": round,
            "height": height,
            "committed": is_committed
        })


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python extract_proposals_with_commit_status.py <log_file_path>")
        sys.exit(1)

    main(sys.argv[1])
