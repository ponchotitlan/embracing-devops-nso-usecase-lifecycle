*** Settings ***
Documentation     This is a very simple Robot test case intended to showcase NSO rfs CRUD interactions
...    Target service: acl-rfs
Library    REST
Library    String
Library    OperatingSystem
Library    Collections
Library    JSONLibrary

# Regardless of the request type, set the same header
Suite Setup    Set my HTTP Request Header

*** Variables ***
${test_device_container}    ciscolive-iosxr-dummy-01
${url_acl_service}    http://localhost:8080/restconf/data/acl-rfs:access-list-acl-rfs

*** Test Cases ***
Create access-list-acl-rfs
    [Documentation]    Create a new access-list-acl-rfs entry
    ${create_acl_payload}   Get File   input_create.json
    Log    ${create_acl_payload}
    ${result}    PATCH    ${url_acl_service}    ${create_acl_payload}
    ${acl_cdb}    Run    echo "show running-config devices device ${test_device_container} config ipv4 access-list" | ncs_cli -Cu admin
    ${acl_expected}    Get File    expected_create.txt
    Should Be Equal As Strings    ${acl_cdb}    ${acl_expected}
      
Change access-list-acl-rfs
    [Documentation]    Change an existing access-list-acl-rfs entry
    ${create_acl_payload}   Get File   input_change.json
    Log    ${create_acl_payload}
    ${result}    PATCH    ${url_acl_service}    ${create_acl_payload}
    ${acl_cdb}    Run    echo "show running-config devices device ${test_device_container} config ipv4 access-list" | ncs_cli -Cu admin
    ${acl_expected}    Get File    expected_change.txt
    Should Be Equal As Strings    ${acl_cdb}    ${acl_expected}  

*** Keywords ***
Set my HTTP Request Header
    [Documentation]    Set the headers for NSO REST requests
    Set Headers	{ "Authorization": "Basic YWRtaW46YWRtaW4="}
    Set Headers	{ "Accept": "application/yang-data+json"}
    Set Headers	{ "Content-type": "application/yang-data+json"}