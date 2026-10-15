
---

## 3. `variables_comunes.robot`

```robot
*** Settings ***
Documentation     T-28: Variables y keywords compartidos para los guiones RPA
...               Usado por guion_rpa_ubuntu.robot y guion_rpa_windows.robot
Library           SeleniumLibrary
Library           OperatingSystem

*** Variables ***
# ==========================================
# URLs de los CRM
# ==========================================
${URL_VM01}              http://192.168.20.11:8080
${URL_VM02}              http://192.168.20.12/espocrm

# ==========================================
# Selectores del LOGIN (confirmados con DevTools)
# ==========================================
${LOGIN_USERNAME}        id=field-userName
${LOGIN_PASSWORD}        id=field-password
${LOGIN_BUTTON}          id=btn-login

# ==========================================
# Selectores de NAVEGACIÓN
# ==========================================
${MENU_CONTACTOS}        xpath=//a[contains(@href,'#Contact')]

# ==========================================
# Selectores del FORMULARIO DE CONTACTO
# (Confirmados con DevTools el 15/10/2026)
# ==========================================
${CAMPO_FIRST_NAME}      css=input[data-name='firstName']
${CAMPO_LAST_NAME}       css=input[data-name='lastName']
${CAMPO_EMAIL}           css=input.email-address
${BOTON_GUARDAR}         css=button[data-action='save']

# ==========================================
# Opciones de Chrome para headless
# ==========================================
${CHROME_HEADLESS}       --headless
${CHROME_NO_SANDBOX}     --no-sandbox
${CHROME_DISABLE_SHM}    --disable-dev-shm-usage

*** Keywords ***
Configurar Chrome Headless
    [Documentation]    Configura las opciones de Chrome para ejecución headless
    ${options}=    Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys, selenium.webdriver
    Call Method    ${options}    add_argument    ${CHROME_HEADLESS}
    Call Method    ${options}    add_argument    ${CHROME_NO_SANDBOX}
    Call Method    ${options}    add_argument    ${CHROME_DISABLE_SHM}
    RETURN    ${options}

Realizar Login
    [Documentation]    Realiza el login en el CRM especificado
    [Arguments]    ${url}    ${usuario}    ${contrasena}
    ${options}=    Configurar Chrome Headless
    Open Browser    ${url}    chrome    options=${options}
    Maximize Browser Window
    Wait Until Element Is Visible    ${LOGIN_USERNAME}    timeout=15s
    Input Text       ${LOGIN_USERNAME}    ${usuario}
    Input Text       ${LOGIN_PASSWORD}    ${contrasena}
    Click Button     ${LOGIN_BUTTON}
    Sleep    5s

Navegar A Contactos
    [Documentation]    Navega a la sección de Contactos
    [Arguments]    ${url}
    Go To    ${url}/#Contact
    Sleep    3s

Crear Contacto
    [Documentation]    Crea un nuevo contacto con los datos especificados
    [Arguments]    ${url}    ${first_name}    ${last_name}    ${email}
    Go To    ${url}/#Contact/create
    Sleep    5s
    Wait Until Element Is Visible    ${CAMPO_FIRST_NAME}    timeout=20s
    Click Element    ${CAMPO_FIRST_NAME}
    Input Text       ${CAMPO_FIRST_NAME}    ${first_name}
    Click Element    ${CAMPO_LAST_NAME}
    Input Text       ${CAMPO_LAST_NAME}     ${last_name}
    Click Element    ${CAMPO_EMAIL}
    Input Text       ${CAMPO_EMAIL}         ${email}
    Sleep    2s
    Execute JavaScript    document.querySelector('button[data-action="save"]').click()
    Sleep    5s

Cerrar Sesion
    [Documentation]    Cierra el navegador
    Close All Browsers
