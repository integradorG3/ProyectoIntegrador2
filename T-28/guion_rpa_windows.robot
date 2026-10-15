*** Settings ***
Documentation     T-28: Flujo RPA completo para CRM Windows (VM-02)
...               Prueba login, consulta y registro de contacto
Library           SeleniumLibrary
Resource          variables_comunes.robot
Variables         credenciales.py

*** Variables ***
${URL}                ${URL_VM02}
${USUARIO}            ${USER_WINDOWS}
${CONTRASENA}         ${PASS_WINDOWS}
${FIRST_NAME}         Prueba
${LAST_NAME}          WindowsCRM
${EMAIL}              prueba.windows@pi2.local

*** Test Cases ***
Flujo Completo CRM Windows
    [Documentation]    Ejecuta login, consulta y registro en VM-02
    [Tags]    VM02    Windows    RPA

    Log    --- Iniciando prueba de LOGIN en VM-02 ---
    Realizar Login    ${URL}    ${USUARIO}    ${CONTRASENA}
    Capture Page Screenshot    t28_windows_01_login.png

    Log    --- Iniciando prueba de CONSULTA en VM-02 ---
    Navegar A Contactos    ${URL}
    Capture Page Screenshot    t28_windows_02_consulta.png

    Log    --- Iniciando prueba de REGISTRO en VM-02 ---
    Crear Contacto    ${URL}    ${FIRST_NAME}    ${LAST_NAME}    ${EMAIL}
    Capture Page Screenshot    t28_windows_03_registro.png

    Log    --- Iniciando prueba de VERIFICACIÓN en VM-02 ---
    Navegar A Contactos    ${URL}
    Wait Until Page Contains    ${LAST_NAME}    timeout=15s
    Capture Page Screenshot    t28_windows_04_verificacion.png

    Cerrar Sesion
