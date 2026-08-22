# Source: Design-Document_Final.pdf — Expense Management & Reimbursement Platform (June 2026)
# Pilot workspace — Gate G1 · solution-owner
# Covers spend analytics/NL-query (REQ-EXP-5) and SSO/RBAC (REQ-AUTH-1) together as the
# access-and-visibility area: who may see what, and how they authenticate to see it.

@REQ-EXP-5
Feature: Spend analytics and natural-language queries
  As a finance manager
  I want role-aware dashboards and guarded NL Q&A over spend data
  So that I can monitor company-wide spend in real time without a BI analyst

  Scenario: Finance dashboard shows company-wide spend
    Given I am logged in as finance
    When I open the analytics dashboard
    Then I see total spend broken down by category, cost centre, and team
    And I see anomaly alerts for unusual spend patterns

  Scenario: Natural language query returns guarded read-only results
    Given I am logged in as finance
    When I ask "What was total travel spend last month?"
    Then the system compiles an allowlisted, read-only SQL query
    And returns aggregated results without exposing individual employees' PII

  Scenario: Low-confidence NL query falls back to a canned report
    Given I am logged in as finance
    When I ask an ambiguous or unsafe natural language question
    Then the system returns a low-confidence fallback canned report
    And does not execute unrestricted SQL against the database

  Scenario: NL query attempting a write is refused
    Given I am logged in as finance
    When I ask a question phrased to request deleting or modifying expense records
    Then the request is refused
    And only read-only aggregate queries are ever executed

  Scenario: Employee cannot access company-wide analytics
    Given I am logged in as an employee
    When I attempt to access finance analytics endpoints
    Then access is denied with HTTP 403

@REQ-AUTH-1
Feature: SSO authentication and role-based access control
  As any platform user
  I want SSO-first login with roles sourced from the identity provider
  So that access is secure and scoped to my role

  Scenario: SSO login via Microsoft Entra ID
    Given I have a valid Entra ID account
    When I authenticate via SSO
    Then I am logged in without any password being stored in the platform
    And my role is assigned from the identity provider's claims

  Scenario: Demo auth fallback when SSO tenant is unavailable
    Given the pilot environment has no production Entra ID tenant configured
    When I log in using the demo auth fallback
    Then I am assigned a role explicitly mapped for the pilot demo
    And the platform clearly marks the session as using non-production auth

  Scenario: Employee sees only their own expenses
    Given I am logged in as an employee
    When I list expenses
    Then I see only expenses I submitted

  Scenario: Approver sees only queue items awaiting their action
    Given I am logged in as an approver
    When I open my approval queue
    Then I see only expenses awaiting my approval action

  Scenario: Finance sees all expenses
    Given I am logged in as finance
    When I list expenses
    Then I see expenses across the organisation

  Scenario: Expired session requires re-authentication
    Given my SSO session token has expired
    When I attempt to submit an expense
    Then I am redirected to re-authenticate
    And no action is taken on my behalf until I am re-authenticated

  Scenario: Deactivated account is denied access
    Given my account has been deactivated in the identity provider
    When I attempt to log in
    Then access is denied
    And I am shown a message directing me to contact an administrator

  Scenario: Role change takes effect on next session
    Given I am logged in as an employee
    And my role is changed to approver in the identity provider mid-session
    When my current session expires and I log in again
    Then my new permissions as approver take effect
    And my prior session's permissions are not retroactively altered
