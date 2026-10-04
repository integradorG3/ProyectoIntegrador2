*** Settings ***
Documentation     Pruebas sinteticas de EspoCRM A (Ubuntu/Docker) y B (Windows/IIS).
...               Mide duracion y resultado de login, consulta y registro.
...               Credenciales por variables de entorno CRM_USER y CRM_PASS (ver robot/.env.example).
...               El historial de resultados se CONSERVA: cada ejecucion agrega filas al CSV
...               definido en HISTORIAL_CSV y nunca lo sobrescribe.
...               VERIFICAR los selectores con F12 en la version instalada de EspoCRM.
Library           Browser
Library           DateTime
Library           OperatingSystem
Suite Setup       Preparar Suite
Suite Teardown    Close Browser

*** Variables ***
${URL_A}            http://192.168.20.11:8080
${URL_B}            http://192.168.20.12
${USER}             %{CRM_USER}
${PASS}             %{CRM_PASS}
${TIMEOUT}          15s
# Ruta fija y persistente, fuera de la carpeta de salida de Robot (que cambia en cada ejecucion).
# Se puede cambiar con: robot --variable HISTORIAL_CSV:/ruta/archivo.csv crm_synthetic.robot
${HISTORIAL_CSV}    /var/log/rpa/rpa_resultados.csv

*** Test Cases ***
Flujo CRM Ubuntu (A)
    [Tags]    ambiente-A
    Flujo Completo    A    ${URL_A}

Flujo CRM Windows (B)
    [Tags]    ambiente-B
    Flujo Completo    B    ${URL_B}

*** Keywords ***
Preparar Suite
    New Browser    chromium    headless=True
    Preparar Historial

Preparar Historial
    [Documentation]    Crea el directorio y el encabezado solo si el CSV no existe o esta vacio.
    ...                Si ya tiene datos, no se toca: el historial se conserva.
    ${carpeta}=    Evaluate    os.path.dirname($HISTORIAL_CSV)    modules=os
    Create Directory    ${carpeta}
    ${con_datos}=    Evaluate    os.path.exists($HISTORIAL_CSV) and os.path.getsize($HISTORIAL_CSV) > 0    modules=os
    IF    not ${con_datos}
        Create File    ${HISTORIAL_CSV}    fecha,ambiente,paso,resultado,segundos,mensaje\n
    END

Flujo Completo
    [Arguments]    ${amb}    ${url}
    New Context
    New Page    ${url}
    Medir Paso    ${amb}    login       Hacer Login       ${url}
    Medir Paso    ${amb}    consulta    Hacer Consulta    ${url}
    Medir Paso    ${amb}    registro    Hacer Registro    ${url}
    [Teardown]    Close Context

Medir Paso
    [Arguments]    ${amb}    ${paso}    ${kw}    @{args}
    ${t0}=    Get Current Date    result_format=epoch
    ${estado}    ${msg}=    Run Keyword And Ignore Error    ${kw}    @{args}
    ${t1}=    Get Current Date    result_format=epoch
    ${dur}=    Evaluate    round(${t1} - ${t0}, 2)
    ${msg}=    Evaluate    str($msg).replace(',', ';').replace('\n', ' ')
    ${fecha}=    Get Current Date    result_format=%Y-%m-%d %H:%M:%S
    Append To File    ${HISTORIAL_CSV}    ${fecha},${amb},${paso},${estado},${dur},${msg}\n
    IF    '${estado}' == 'FAIL'
        Take Screenshot    filename=fallo_${amb}_${paso}
    END
    Should Be Equal    ${estado}    PASS    Fallo en ${paso} (ambiente ${amb}): ${msg}

Hacer Login
    [Arguments]    ${url}
    Go To    ${url}
    Fill Text      id=field-userName    ${USER}
    Fill Secret    id=field-password    $PASS
    Click          id=btn-login
    Wait For Elements State    css=.navbar    visible    timeout=${TIMEOUT}

Hacer Consulta
    [Arguments]    ${url}
    Go To    ${url}/#Contact
    Wait For Elements State    css=.list-container    visible    timeout=${TIMEOUT}

Hacer Registro
    [Arguments]    ${url}
    ${epoch}=    Get Current Date    result_format=epoch
    ${apellido}=    Set Variable    RPA-${epoch}
    Go To    ${url}/#Contact/create
    Wait For Elements State    css=input[data-name='lastName']    visible    timeout=${TIMEOUT}
    Fill Text    css=input[data-name='lastName']    ${apellido}
    Click        css=button[data-action='save']
    Wait For Elements State    css=.record    visible    timeout=${TIMEOUT}

