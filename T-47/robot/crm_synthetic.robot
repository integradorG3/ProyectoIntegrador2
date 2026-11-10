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
${URL_B}            http://192.168.20.12/espocrm
${USER_A}           %{CRM_USER_A}
${PASS_A}           %{CRM_PASS_A}
${USER_B}           %{CRM_USER_B}
${PASS_B}           %{CRM_PASS_B}
# Espera maxima de elementos de pantalla (antes 15s).
${TIMEOUT}          30s
# Espera maxima de navegacion (New Page / Go To). Por defecto Browser usa 10s y falla
# en el arranque en frio de IIS tras reiniciar W3SVC.
${NAV_TIMEOUT}      60s
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
    Set Browser Timeout    ${NAV_TIMEOUT}
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
    Medir Paso    ${amb}    login       Hacer Login       ${url}    ${amb}
    Medir Paso    ${amb}    consulta    Hacer Consulta    ${url}
    Medir Paso    ${amb}    registro    Hacer Registro    ${url}
    [Teardown]    Close Context

Medir Paso
    [Arguments]    ${amb}    ${paso}    ${kw}    @{args}
    ${t0}=    Get Current Date    result_format=epoch
    ${estado}    ${msg}=    Run Keyword And Ignore Error    ${kw}    @{args}
    ${t1}=    Get Current Date    result_format=epoch
    ${dur}=    Evaluate    round(${t1} - ${t0}, 2)
    ${msg}=    Evaluate    str($msg).replace(',', ';').replace(chr(10), ' ')
    ${fecha}=    Get Current Date    result_format=%Y-%m-%d %H:%M:%S
    Append To File    ${HISTORIAL_CSV}    ${fecha},${amb},${paso},${estado},${dur},${msg}\n
    
    # NUEVO: Tomar captura SIEMPRE, en la carpeta del reporte
    Take Screenshot    filename=${OUTPUT DIR}/evidencia_${amb}_${paso}
    
    Should Be Equal    ${estado}    PASS    Fallo en ${paso} (ambiente ${amb}): ${msg}

Hacer Login
    [Arguments]    ${url}    ${amb}
    Go To    ${url}
    IF    '${amb}' == 'A'
        Fill Text      id=field-userName    ${USER_A}
        Fill Secret    id=field-password    $PASS_A
    ELSE
        Fill Text      id=field-userName    ${USER_B}
        Fill Secret    id=field-password    $PASS_B
    END
    Click          id=btn-login
    Wait For Elements State    css=.navbar    visible    timeout=${TIMEOUT}

Hacer Consulta
    [Arguments]    ${url}
    Go To    ${url}/#Contact
    Wait For Elements State    css=.list-container    visible    timeout=${TIMEOUT}

Hacer Registro
    [Arguments]    ${url}
    # 1. Listas separadas para nombre y apellido de los integrantes
    @{nombres}=     Create List    Ivan    Monserrat    Estefania    Luis    Manuel    Fabricio
    @{apellidos}=   Create List    Ramirez    Moreno    Mendez    Vasquez    Chavarria    Pena
    @{dominios}=    Create List    gmail.com    hotmail.com    pi2.local
    
    # 2. Selección aleatoria basada en el tiempo
    ${epoch}=       Get Current Date    result_format=epoch
    ${epoch_int}=   Evaluate    int(${epoch})
    ${indice_n}=    Evaluate    ${epoch_int} % 6
    ${indice_d}=    Evaluate    ${epoch_int} % 3
    
    ${nombre}=      Set Variable    ${nombres}[${indice_n}]
    ${apellido}=    Set Variable    ${apellidos}[${indice_n}]
    ${correo}=      Set Variable    rpa.${epoch}@${dominios}[${indice_d}]
    
    # 3. Generamos un teléfono de 8 dígitos válido para evitar error "too long/short"
    ${tel_short}=   Evaluate    str(${epoch_int})[:8]
    ${telefono}=    Set Variable    +506 ${tel_short}
    
    Go To    ${url}/#Contact/create
    
    # 4. Esperamos a que el formulario cargue
    Wait For Elements State    css=input[data-name='firstName']    visible    timeout=${TIMEOUT}
    
    # 5. Llenamos los campos usando los selectores exactos de EspoCRM
    Fill Text    css=input[data-name='firstName']    ${nombre}
    Fill Text    css=input[data-name='lastName']     ${apellido}
    Fill Text    css=div[data-name='emailAddress'] input >> nth=0    ${correo}
    Fill Text    css=input[data-intl-tel-input-id='0']    ${telefono}
    
    # 6. Damos un pequeño respiro para que el CRM valide
    Sleep    1s
    
    # 7. Guardamos y verificamos
    Click    css=button[data-action='save']
    Wait For Elements State    css=.record    visible    timeout=${TIMEOUT}
