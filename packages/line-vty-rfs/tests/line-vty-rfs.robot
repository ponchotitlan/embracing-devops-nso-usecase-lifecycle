*** Settings ***
Documentation     This is a very simple Robot test case intended to showcase NSO rfs CRUD interactions
...    Target package: router-rfs
...    Target service: line-template-vty-router-rfs
Library    REST
Library    String
Library    OperatingSystem
Library    Collections
Library    JSONLibrary

# Regardless of the request type, set the same header
Suite Setup    Set my HTTP Request Header

*** Variables ***
${test_device_container}    ciscolive-iosxr-dummy-02
${url_acl_service}    http://localhost:8080/restconf/data/line-vty-rfs:line-template-vty-line-vty-rfs

*** Test Cases ***
Create line-template-vty-router-rfs
    [Documentation]    Create a new line-template-vty-router-rfs entry
    ${create_acl_payload}   Get File   input_create.json
    Log    ${create_acl_payload}
    ${result}    PATCH    ${url_acl_service}    ${create_acl_payload}
    ${acl_cdb}    Run    echo 'show running-config devices device ${test_device_container} config line template' | ncs_cli -Cu admin
    ${acl_expected}    Get File    expected_create.txt
    Should Be Equal As Strings    ${acl_cdb}    ${acl_expected}
      
Change line-template-vty-router-rfs
    [Documentation]    Change an existing line-template-vty-router-rfs entry
    ${create_acl_payload}   Get File   input_change.json
    Log    ${create_acl_payload}
    ${result}    PATCH    ${url_acl_service}    ${create_acl_payload}
    ${acl_cdb}    Run    echo 'show running-config devices device ${test_device_container} config line template' | ncs_cli -Cu admin
    ${acl_expected}    Get File    expected_change.txt
    Should Be Equal As Strings    ${acl_cdb}    ${acl_expected}  

*** Keywords ***
Set my HTTP Request Header
    [Documentation]    Set the headers for NSO REST requests
    Set Headers	{ "Authorization": "Basic YWRtaW46YWRtaW4="}
    Set Headers	{ "Accept": "application/yang-data+json"}
    Set Headers	{ "Content-type": "application/yang-data+json"}