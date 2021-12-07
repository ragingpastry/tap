*** Settings ***

Library           Process
Library           OperatingSystem
Resource          functional/usecasekeywords.robot

*** Test Cases ***
Display Help With No Input
    [Tags]  RR13-20     Invalid_Input_Tests
    [Documentation]  Program must show help with insufficient argument count
    Given I have a mock repo   fixture/test-tap-repo
    WHEN I execute the process      %{BIN}

    Then the return code is nonzero


Display Help With Invalid Flag
    [Tags]  RR13-20     Invalid_Input_Tests
    [Documentation]  Program must show help when given invalid flags
    Given I have a mock repo   fixture/test-tap-repo
    WHEN I execute the process      %{BIN}  --run
    Then the return code is nonzero
