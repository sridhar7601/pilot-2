# Source: Design-Document_Final.pdf — Expense Management & Reimbursement Platform (June 2026)
# Pilot workspace — Gate G1 · solution-owner

@REQ-EXP-4
Feature: Event-sourced reimbursement status tracking
  As an employee
  I want an event-sourced timeline with a predicted payout date
  So that I always know where my reimbursement stands

  Scenario: Employee views expense timeline
    Given I am logged in as an employee
    And I have a submitted expense with approval events
    When I open the expense detail page
    Then I see a human-readable event timeline
    And each event shows the actor, timestamp, and description

  Scenario: Timeline updates on every state transition
    Given an expense is in status "in_approval"
    When an approver approves the expense
    Then a new event is appended to the expense event log
    And the employee's timeline reflects the approval immediately

  Scenario: Predicted payout date shown for approved expenses
    Given an expense is in status "approved"
    When I view the expense detail
    Then I see a predicted payout date
    And the prediction is clearly labelled as an estimate, not a guarantee

  Scenario: Finance batch reimbursement updates timeline
    Given approved expenses are included in a payout run
    When finance marks the batch as paid
    Then each expense moves to status "reimbursed"
    And the employee timeline shows the reimbursement event with the payout reference

  Scenario: Employee raises dispute from timeline
    Given I am logged in as an employee
    And my expense was reimbursed for a disputed amount
    When I raise a dispute from the timeline
    Then the dispute routes to the finance queue with the expense's full event history
    And the expense moves to status "disputed"

  Scenario: Partial reimbursement recorded distinctly
    Given an approved expense of $200 is only partially paid $150 in a payout run
    When finance records the partial payment
    Then the expense moves to status "partially_reimbursed"
    And the timeline shows the amount paid and the amount outstanding

  Scenario: Reimbursement failure is retried and recorded
    Given an expense payout attempt fails due to a bank transfer error
    When the payout system retries the transfer
    Then a "reimbursement_failed" event is recorded with the failure reason
    And a subsequent successful retry appends a "reimbursed" event
    And the expense does not silently remain in status "approved"

  Scenario: Timeline access is restricted to authorised parties
    Given an expense belongs to a different employee than me
    And I am not that employee's approver or a member of finance
    When I attempt to view that expense's timeline
    Then access is denied with HTTP 403

  Scenario: Event log is immutable and append-only
    Given an expense has recorded events for submission and approval
    When any actor attempts to modify a past event directly
    Then the modification is rejected
    And corrections are only possible via a new compensating event
