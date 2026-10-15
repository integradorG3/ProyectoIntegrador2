*** Settings ***
Documentation     T-28: Flujo RPA completo para CRM Ubuntu (VM-01)
...               Prueba login, consulta y registro de contacto
Library           SeleniumLibrary
Resource          variables_comunes.robot
Variables         credenciales.py

*** Variables ***
${URL}                ${URL_VM01}
${USUARIO}            ${USER_UBUNTU}
${CONTRASENA}         ${PASS_UBUNTU}
${FIRST_NAME}         Prueba
${LAST_NAME}          UbuntuCRM
${EMAIL}              test.ubuntu@pi2.local

*** Test Cases ***
Flujo Completo CRM Ubuntu
    [Documentation]    Ejecuta login, consulta y registro en VM-01
    [Tags]    VM01    Ubuntu    RPA

    Log    --- Iniciando prueba de LOGIN en VM-01 ---
    Realizar Login    ${URL}    ${USUARIO}    ${CONTRASENA}
    Capture Page Screenshot    t28_ubuntu_01_login.png

    Log    --- Iniciando prueba de CONSULTA en VM-01 ---
    Navegar A Contactos    ${URL}
    Capture Page Screenshot    t28_ubuntu_02_consulta.png

    Log    --- Iniciando prueba de REGISTRO en VM-01 ---
    Crear Contacto    ${URL}    ${FIRST_NAME}    ${LAST_NAME}    ${EMAIL}
    Capture Page Screenshot    t28_ubuntu_03_registro.png

    Log    --- Iniciando prueba de VERIFICACIÓN en VM-01 ---
    Navegar A Contactos    ${URL}
    Wait Until Page Contains    ${LAST_NAME}    timeout=15s
    Capture Page Screenshot    t28_ubuntu_04_verificacion.png

    Cerrar Sesion
