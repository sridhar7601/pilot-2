# Gherkin requirement template. Copy to <area>-<slug>.feature and fill in.
# The tag carries the requirement ID and is the anchor for downstream tests/UAT and traceability.

@REQ-AREA-1
Feature: <capability name>
  As a <stakeholder>
  I want <capability>
  So that <business value>

  # Acceptance criteria become Scenarios. Cover the happy path AND the edge cases the Architect
  # must design for and the Tester must automate.

  Scenario: <happy path>
    Given <precondition>
    When <action>
    Then <expected outcome>

  Scenario: <edge case>
    Given <precondition>
    When <boundary/error action>
    Then <expected handling>
