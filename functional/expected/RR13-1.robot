*** Settings ***

Library           Process
Library           OperatingSystem
Resource          functional/usecasekeywords.robot


*** Test Cases ***
Pipeline is Triggered
    [Tags]  Expected_Tests
    [Documentation]  Program should execute without errors when executed with correct inputs
    WHEN I execute the process in the repo      %{BIN}    run  --api-key=%{GITLAB_API_KEY}   "TEST_VAR=test"
    Then the return code is zero
