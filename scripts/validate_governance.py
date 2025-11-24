import sys, os
sys.path.append(os.getcwd())

from scout.scout import Scout
from executor.executor import Executor
from boardroom.boardroom import Boardroom


def main():
    print("\U0001F3DB\uFE0F  Booting Sovereign Governance...")
    scout = Scout()
    executor = Executor()
    boardroom = Boardroom()
    proposal = scout.propose_cleanup()
    print(f"\U0001F4DD Proposal: {proposal.description} (ID: {proposal.id[:8]})")
    result = executor.run_trial(proposal)
    print(f"\U0001F9EA Trial Result: {result}")
    decision = boardroom.evaluate(proposal, result)
    print(f"\u2696\uFE0F  Boardroom Decision: {decision.decision_type} (Approved: {decision.approved})")
    print(f"\U0001F512 Ledger Head: {boardroom.last_hash[:16]}...")

if __name__ == "__main__":
    main()
