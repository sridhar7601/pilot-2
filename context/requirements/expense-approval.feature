# Source: Design-Document_Final.pdf — Expense Management & Reimbursement Platform (June 2026)
# Pilot workspace — Gate G1 · solution-owner

@REQ-EXP-2
Feature: Multi-level approval workflow
  As an approver
  I want a risk-sorted queue with batch approval for clean items
  So that I can process expenses efficiently without compromising control

  Scenario: Approver sees queue sorted by risk
    Given I am logged in as an approver
    And there are expenses with and without AI-raised flags awaiting my action
    When I open the approval queue
    Then AI-flagged expenses appear before clean items
    And each flagged item shows the reason for the flag

  Scenario: Batch approve clean expenses
    Given I am logged in as an approver
    And I have selected multiple clean, unflagged expenses
    When I batch approve them with a single action
    Then all selected expenses move to status "approved"
    And an approval event is recorded for each expense individually

  Scenario: Batch approval excludes flagged items
    Given I am logged in as an approver
    And my selection includes one clean expense and one AI-flagged expense
    When I attempt to batch approve the selection
    Then the flagged expense is rejected from the batch action
    And I am told it requires individual review
    And the clean expense is approved

  Scenario: Self-approval is blocked
    Given I am logged in as an approver who submitted an expense
    When I view that expense in my approval queue
    Then I cannot approve my own submission
    And the chain routes the step to an alternate approver

  Scenario: Required comment on rejection
    Given I am logged in as an approver reviewing a flagged expense
    When I reject the expense without providing a comment
    Then the rejection is blocked until a comment is entered
    When I reject the expense with a comment
    Then the expense moves to status "rejected"

  Scenario: Return expense for edit preserves history
    Given an expense is in status "in_approval"
    When I return it for edit with a comment
    Then the expense moves to status "returned_for_edit"
    And the event timeline records the return action with my comment
    And resubmission restarts only the remaining chain steps, not steps already approved

  Scenario: SLA escalation when approver unavailable
    Given an approval step has exceeded its SLA due date
    And the assigned approver has an active out-of-office delegation
    When the SLA timer fires
    Then the step escalates to the delegated approver
    And an escalation event is recorded on the timeline

  Scenario: SLA escalation with no delegation configured
    Given an approval step has exceeded its SLA due date
    And the assigned approver has no delegation configured
    When the SLA timer fires
    Then the step escalates to the next node up the reporting chain
    And the original approver is notified of the escalation

  Scenario: Approver leaves the organisation mid-chain
    Given an expense is awaiting action from an approver marked as deactivated
    When the approval engine detects the deactivated approver
    Then the step is reassigned to that approver's designated backup or manager
    And the reassignment is recorded on the timeline

  Scenario: Concurrent approval and rejection on the same step
    Given two authorised approvers open the same pending step at the same time
    When one approver approves and the other submits a rejection moments later
    Then only the first recorded decision is applied
    And the second approver is informed the step was already resolved

  Scenario: Chain with a single approval step
    Given an expense's policy evaluation requires only one approval step
    When the sole approver approves the expense
    Then the expense moves directly to status "approved"
