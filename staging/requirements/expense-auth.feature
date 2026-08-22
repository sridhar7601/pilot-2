@REQ-AUTH-1
Feature: SSO authentication and role-based access
  As any platform user
  I want SSO-first login with roles from the identity provider
  So that access is secure and role-appropriate

  Scenario: SSO login via Microsoft Entra ID
    Given I have a valid Entra ID account
    When I authenticate via SSO
    Then I am logged in without password storage in the platform
    And my role is assigned from the identity provider claims

  Scenario: Employee sees only own expenses
    Given I am logged in as an employee
    When I list expenses
    Then I see only expenses I submitted

  Scenario: Approver sees approval queue items
    Given I am logged in as an approver
    When I open my approval queue
    Then I see only expenses awaiting my approval action

  Scenario: Finance sees all expenses
    Given I am logged in as finance
    When I list expenses
    Then I can see expenses across the organisation
