# Source: Design-Document_Final.pdf — Expense Management & Reimbursement Platform (June 2026)
# Pilot workspace — Gate G1 · solution-owner

@REQ-EXP-1
Feature: Expense submission with receipt capture and AI pre-fill
  As an employee
  I want to submit expenses with receipt attachments and AI pre-fill
  So that reimbursements are fast and accurate without manual re-typing

  Background:
    Given I am logged in as an employee with role "Employee"

  Scenario: Submit expense with AI-extracted receipt fields
    Given I have uploaded a valid receipt image for a meal expense of $45.00
    When I submit the expense with the extracted fields confirmed
    Then the expense is created in status "submitted"
    And each extracted field has a confidence score between 0 and 1
    And a policy verdict is returned before submission completes

  Scenario: Block submission when policy blocks an over-limit meal
    Given my per-person meal limit is $75
    And I have a meal expense of $94.00 for one person
    When I attempt to submit the expense
    Then submission is blocked
    And I receive a plain-language policy explanation
    And no expense record is created in status "submitted"

  Scenario: Warn on submission near policy threshold
    Given my per-person meal limit is $75
    And I have a meal expense of $72.00
    When I submit the expense
    Then submission succeeds with verdict "warn"
    And I see a plain-language warning explanation
    And the expense is created in status "submitted"

  Scenario: Duplicate receipt detection at submission
    Given a receipt with matching merchant, amount, and date already exists for me
    When I upload the duplicate receipt and attempt to submit
    Then I am warned about a possible duplicate before submission completes
    And if I proceed, the expense is flagged for approver review

  Scenario: Manual entry when receipt extraction fails
    Given I have uploaded an unreadable receipt image
    When AI extraction fails with confidence below the minimum threshold
    Then I can enter expense details manually
    And the original image is retained and linked to the expense for approver review

  Scenario: Multi-line expense split across cost centres
    Given I have an expense with two line items on different cost centres
    When I submit the expense
    Then each line item routes to its respective cost centre's approval chain
    And the overall expense reflects the combined total

  Scenario: Reject unsupported receipt file type
    Given I attempt to upload a receipt file of type ".exe"
    When I submit the upload
    Then the upload is rejected
    And I am told which file types are accepted (JPEG, PNG, PDF)

  Scenario: Reject receipt exceeding maximum file size
    Given I attempt to upload a receipt file larger than 10MB
    When I submit the upload
    Then the upload is rejected with a file-size error
    And no expense is created

  Scenario Outline: Required field validation before submission
    Given I have a draft expense missing "<field>"
    When I attempt to submit the expense
    Then submission is blocked
    And I am told "<field>" is required

    Examples:
      | field         |
      | amount        |
      | date          |
      | category       |
      | cost centre   |

  Scenario: Reject expense with a future date
    Given I have a draft expense dated 3 days in the future
    When I attempt to submit the expense
    Then submission is blocked
    And I am told the expense date cannot be in the future

  Scenario: Foreign currency expense converted at submission-time rate
    Given I have a receipt in a currency other than my home currency
    When I submit the expense
    Then the expense stores both the original currency amount and the converted home-currency amount
    And the conversion rate and its timestamp are recorded on the expense
