# Source: Design-Document_Final.pdf — Expense Management & Reimbursement Platform (June 2026)
# Pilot workspace — Gate G1 · solution-owner

@REQ-EXP-3
Feature: Policy-as-code enforcement
  As a finance administrator
  I want versioned policy rules evaluated deterministically at submission
  So that compliance is consistent, auditable, and never decided by AI alone

  Scenario: Policy evaluated at submission returns pass
    Given an active policy version with a $100 daily limit for travel
    And an employee submits an $80 travel expense
    When the policy engine evaluates the expense
    Then the verdict is "pass"
    And the expense proceeds to the approval chain

  Scenario: Policy evaluated at submission returns block
    Given an active policy version with a $75 per-person meal limit
    And an employee submits a $94 meal expense
    When the policy engine evaluates the expense
    Then the verdict is "block"
    And the LLM does not approve or move money
    And the deterministic policy engine is the sole authority for the verdict

  Scenario: In-flight expense keeps submission-time policy version
    Given an expense was submitted under policy version 2
    And policy version 3 is now active with stricter limits
    When the expense is still in approval
    Then it continues to be evaluated against policy version 2

  Scenario: Admin creates a new policy version
    Given I am logged in as an admin
    When I publish a new policy version with an effective date of tomorrow
    Then the new version is stored with an incremented version number
    And existing in-flight expenses retain their original policy version
    And the previous version is retained for audit history, not deleted

  Scenario: Missing receipt above threshold requires declaration
    Given the no-receipt threshold is $25
    And an employee submits a $50 expense without a receipt
    When they complete the missing-receipt declaration
    Then an extra approval step is added to the chain
    And the expense is flagged as "no-receipt-declared"

  Scenario: Missing receipt below threshold requires no declaration
    Given the no-receipt threshold is $25
    And an employee submits a $10 expense without a receipt
    When they submit the expense
    Then no declaration is required
    And the expense proceeds through the normal chain

  Scenario: Admin dry-runs a policy change before publishing
    Given I am logged in as an admin editing a draft policy version
    When I run a simulation against the last 30 days of submitted expenses
    Then I see how many would have passed, warned, or been blocked under the draft
    And no live expense evaluation is affected by the simulation

  Scenario: Cannot activate a policy version with a past effective date
    Given I am logged in as an admin
    When I attempt to publish a policy version with an effective date in the past
    Then publication is rejected
    And I am told the effective date must be today or later

  Scenario: Overlapping rules resolved by specificity
    Given a general travel policy limit of $100 per day
    And a more specific policy rule limiting international travel to $150 per day
    When an employee submits a $130 international travel expense
    Then the more specific rule is applied
    And the verdict is "pass"

  Scenario: Policy rule with currency-specific limits
    Given a policy defines a €50 meal limit for EU cost centres
    And an employee on a EU cost centre submits a €60 meal expense
    When the policy engine evaluates the expense
    Then the verdict is "block"
    And the explanation references the EU-specific limit, not the default currency limit
