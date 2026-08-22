@REQ-EXP-5
Feature: Spend analytics and natural-language queries
  As a finance manager
  I want role-aware dashboards and NL Q&A over spend data
  So that I can monitor company-wide spend in real time

  Scenario: Finance dashboard shows company-wide spend
    Given I am logged in as finance
    When I open the analytics dashboard
    Then I see total spend by category cost centre and team
    And I see anomaly alerts for unusual patterns

  Scenario: Natural language query returns guarded read-only results
    Given I am logged in as finance
    When I ask "What was total travel spend last month?"
    Then the system compiles an allowlisted read-only SQL query
    And returns aggregated results without exposing PII

  Scenario: Low-confidence NL query falls back to canned report
    Given I am logged in as finance
    When I ask an ambiguous or unsafe natural language question
    Then the system returns a low-confidence fallback canned report
    And does not execute unrestricted SQL

  Scenario: Employee cannot access company-wide analytics
    Given I am logged in as an employee
    When I attempt to access finance analytics endpoints
    Then access is denied with HTTP 403
