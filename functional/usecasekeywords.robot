*** Keywords ***

I execute the process
    [Arguments]  ${program}      @{rest}
    ${output} =     Run Process    ${program}   run   @{rest}
    Set test variable    ${output}

The return code is nonzero
    Should not be equal as integers     ${output.rc}       0

The return code is zero
    Should be equal as integers     ${output.rc}       0

Stdout shows
    [Arguments]  ${content}
    Should Contain    ${output.rc}    ${content}

Stdout shows help
    Should not be equal as integers     ${output.stdout}       0


I have a mock repo
    [Arguments]  ${location}
    Directory Should Exist   ${location}

I cd into the mock repo
    [Arguments]  ${location}
    Run   cd ${location}

I execute the process in the repo
    [Arguments]  ${program}      @{rest}
    ${output} =  Run Process  ${program}        @{rest}    cwd=${CURDIR}/../fixture/test-tap-repo
    Log To Console  ${output.stdout}
    Log To Console  ${output.stderr}
    Set test variable    ${output}

Calculation will match expected output
    [Arguments]     ${file_name}    ${calc_type}    ${expected_output}
    ${result} =     Read CSV File   ${file_name}    ${calc_type}
    Should be Equal     ${result}   ${expected_output}
