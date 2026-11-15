*** Settings ***
Documentation     Pruebas sinteticas de EspoCRM A (Ubuntu/Docker) y B (Windows/IIS).
...               Login -> Registro -> Consulta -> Busqueda por correo -> Verificacion.
...               Genera contactos unicos, mide tiempos y registra evidencias.

Library           Browser
Library           DateTime
Library           OperatingSystem
Library           Collections

Suite Setup       Preparar Suite
Suite Teardown    Close Browser


*** Variables ***

# DIRECCIONES CRM
${URL_A}              http://192.168.20.11:8080
${URL_B}              http://192.168.20.12/espocrm

# USUARIOS
${USER_A}             %{CRM_USER_A}
${USER_B}             %{CRM_USER_B}

# CONTRASEÑAS
${PASS_A}             %{CRM_PASS_A}
${PASS_B}             %{CRM_PASS_B}

# CONFIGURACION
${TIMEOUT}            30s
${NAV_TIMEOUT}        60s
${HEADLESS}           True

# HISTORIAL
${HISTORIAL_CSV}      /var/log/rpa/rpa_resultados.csv

# ESTADO DE LA CORRIDA (los actualiza Flujo Completo / Medir Paso)
${URL_ACTUAL}         ${EMPTY}
${AMB_ACTUAL}         ${EMPTY}
${ULTIMO_ESTADO}      PASS

# SELECTORES LOGIN
${LOGIN_USER}         id=field-userName
${LOGIN_PASS}         id=field-password
${LOGIN_BUTTON}       id=btn-login
${NAVBAR}             css=.navbar

# SELECTORES REGISTRO
${SAVE_BUTTON}        css=button[data-action='save']


*** Test Cases ***

Flujo CRM Ubuntu (A)
    [Documentation]    Pruebas sinteticas CRM Ubuntu.
    [Tags]    ambiente-A    ubuntu
    Flujo Completo    A    ${URL_A}

Flujo CRM Windows (B)
    [Documentation]    Pruebas sinteticas CRM Windows.
    [Tags]    ambiente-B    windows
    Flujo Completo    B    ${URL_B}


*** Keywords ***


# =====================================================
# PREPARACION
# =====================================================

Preparar Suite
    Log To Console    ========================================
    Log To Console    INICIANDO PRUEBAS SINTETICAS RPA
    Log To Console    ========================================

    New Browser    chromium    headless=${HEADLESS}
    Set Browser Timeout    ${NAV_TIMEOUT}

    Preparar Historial


Preparar Historial
    ${carpeta}=    Evaluate    os.path.dirname($HISTORIAL_CSV)    modules=os
    Create Directory    ${carpeta}

    ${existe}=    Evaluate    os.path.exists($HISTORIAL_CSV) and os.path.getsize($HISTORIAL_CSV) > 0    modules=os

    IF    not ${existe}
        Create File    ${HISTORIAL_CSV}    fecha,ambiente,paso,resultado,segundos,umbral,mensaje\n
    END


# =====================================================
# FLUJO PRINCIPAL
# =====================================================

Flujo Completo
    [Arguments]    ${amb}    ${url}
    [Teardown]    Cerrar Contexto Seguro

    Log To Console    ----------------------------------------
    Log To Console    INICIANDO CRM ${amb}
    Log To Console    ----------------------------------------

    New Context
    New Page    ${url}
    Set Test Variable    ${URL_ACTUAL}    ${url}
    Set Test Variable    ${AMB_ACTUAL}    ${amb}

    # PASO 1: LOGIN
    Medir Paso    ${amb}    login    Hacer Login    ${url}    ${amb}

    # PASO 2: REGISTRO
    ${correo}=    Medir Paso    ${amb}    registro    Hacer Registro    ${url}    ${amb}
    # Si el registro fallo, "correo" trae el texto del error: no se debe buscar eso.
    IF    '${ULTIMO_ESTADO}' != 'PASS'
        ${correo}=    Set Variable    ${EMPTY}
    END
    Log To Console    CORREO DEL CONTACTO: ${correo}

    # PASO 3: CONSULTA
    Medir Paso    ${amb}    consulta    Hacer Consulta    ${url}

    # PASO 4: BUSQUEDA POR CORREO
    ${resultado}=    Medir Paso    ${amb}    buscar_contacto    Buscar Contacto    ${url}    ${correo}    ${amb}

    Log To Console    ========================================
    Log To Console    CRM ${amb}: PRUEBA COMPLETADA
    Log To Console    CONTACTO: ${resultado}
    Log To Console    CORREO: ${correo}
    Log To Console    ========================================


Cerrar Contexto Seguro
    Run Keyword And Ignore Error    Close Context


# =====================================================
# UMBRALES DE RENDIMIENTO
# =====================================================

Obtener Umbrales
    [Arguments]    ${paso}

    IF    '${paso}' == 'login'
        RETURN    ${3}    ${5}    ${8}
    ELSE IF    '${paso}' == 'consulta'
        RETURN    ${4}    ${6}    ${8}
    ELSE IF    '${paso}' == 'registro'
        RETURN    ${5}    ${8}    ${12}
    ELSE IF    '${paso}' == 'buscar_contacto'
        RETURN    ${6}    ${9}    ${14}
    ELSE
        RETURN    ${999999}    ${999999}    ${999999}
    END


Clasificar Umbral
    [Arguments]    ${paso}    ${duracion}

    ${normal}    ${advertencia}    ${critico}=    Obtener Umbrales    ${paso}

    IF    ${duracion} <= ${normal}
        RETURN    NORMAL
    ELSE IF    ${duracion} <= ${advertencia}
        RETURN    ADVERTENCIA
    ELSE IF    ${duracion} <= ${critico}
        RETURN    CRITICO
    ELSE
        RETURN    CRITICO_EXCEDIDO
    END


# =====================================================
# MEDICION DE TIEMPOS (NUNCA SE DETIENE)
# =====================================================

Medir Paso
    [Arguments]    ${amb}    ${paso}    ${kw}    @{args}

    Log To Console    ========================================
    Log To Console    EJECUTANDO: ${paso}
    Log To Console    AMBIENTE: ${amb}

    ${t0}=    Get Current Date    result_format=epoch

    # EJECUTAMOS EL PASO IGNORANDO SI FALLA O DA ERROR
    ${estado}    ${msg}=    Run Keyword And Ignore Error    ${kw}    @{args}

    ${t1}=    Get Current Date    result_format=epoch

    ${dur}=    Evaluate    round(float(${t1}) - float(${t0}), 2)

    # CLASIFICAR TIEMPO
    ${nivel}=    Clasificar Umbral    ${paso}    ${dur}

    # LIMPIAR MENSAJE PARA CSV
    ${mensaje}=    Evaluate    str($msg).replace(',', ';').replace(chr(10), ' ').replace(chr(13), ' ')

    ${fecha}=    Get Current Date    result_format=%Y-%m-%d %H:%M:%S

    # REGISTRAR RESULTADO
    Append To File    ${HISTORIAL_CSV}    ${fecha},${amb},${paso},${estado},${dur},${nivel},${mensaje}\n

    Log To Console    ----------------------------------------
    Log To Console    PASO: ${paso}
    Log To Console    TIEMPO: ${dur} segundos
    Log To Console    RESULTADO: ${estado}
    Log To Console    UMBRAL: ${nivel}
    Log To Console    ----------------------------------------

    # EVIDENCIA PROPIA DEL PASO: se toma justo al terminar el paso, ANTES de cualquier
    # recuperacion, para que muestre el estado real de ESTE paso (y no el de otro).
    Run Keyword And Ignore Error    Take Screenshot    filename=${OUTPUT DIR}/evidencia_${amb}_${paso}.png

    Set Test Variable    ${ULTIMO_ESTADO}    ${estado}

    # SI EL PASO FALLO: se reporta, se limpia el navegador y se continua con el siguiente
    IF    '${estado}' == 'FAIL'
        Log To Console    [FALLO] El paso ${paso} falló, pero se continúa con el siguiente.
        Recuperar Tras Fallo    ${paso}
    END

    RETURN    ${msg}


# =====================================================
# RECUPERACION TRAS UN PASO FALLIDO
# =====================================================
# Deja el navegador en un estado limpio para que el SIGUIENTE paso empiece bien
# y su evidencia muestre su propia pantalla (no la del paso que fallo).

Recuperar Tras Fallo
    [Arguments]    ${paso}

    Log To Console    LIMPIANDO ESTADO DEL NAVEGADOR TRAS FALLO EN ${paso}

    # 1. Salir de la pantalla donde se quedo el paso fallido
    Run Keyword And Ignore Error    Go To    ${URL_ACTUAL}/#

    # 2. Aceptar el aviso "¿Realmente desea salir del formulario?" si aparece
    Run Keyword And Ignore Error    Resolver Confirmacion Salida

    # 3. Si la sesion se perdio (aparece el login), iniciar sesion otra vez
    ${hay_login}=    Run Keyword And Return Status
    ...    Wait For Elements State    ${LOGIN_USER}    visible    timeout=3s

    IF    ${hay_login}
        Log To Console    SESION PERDIDA: se vuelve a iniciar sesion
        Run Keyword And Ignore Error    Hacer Login    ${URL_ACTUAL}    ${AMB_ACTUAL}
    END


# =====================================================
# LOGIN
# =====================================================

Hacer Login
    [Arguments]    ${url}    ${amb}

    Go To    ${url}

    Wait For Elements State    ${LOGIN_USER}    visible    timeout=${NAV_TIMEOUT}

    # OJO: Fill Secret exige la contraseña SIN llaves ($PASS_A, no ${PASS_A}); con llaves
    # la libreria Browser rechaza el valor, la contraseña queda vacia y el login falla.
    IF    '${amb}' == 'A'
        Fill Text    ${LOGIN_USER}    ${USER_A}
        Fill Secret    ${LOGIN_PASS}    $PASS_A
    ELSE
        Fill Text    ${LOGIN_USER}    ${USER_B}
        Fill Secret    ${LOGIN_PASS}    $PASS_B
    END

    Click    ${LOGIN_BUTTON}

    Wait For Elements State    ${NAVBAR}    visible    timeout=${NAV_TIMEOUT}

    Log To Console    LOGIN CORRECTO CRM ${amb}


# =====================================================
# REGISTRO DE CONTACTOS
# =====================================================

Hacer Registro
    [Arguments]    ${url}    ${amb}

    @{nombres}=    Create List    Ivan    Monserrat    Estefania    Luis    Manuel    Fabricio    Ana    Pedro    Laura    Carlos    Sofia    Diego
    @{apellidos}=    Create List    Ramirez    Moreno    Mendez    Vasquez    Chavarria    Pena    Gomez    Rodriguez    Fernandez    Lopez    Martinez    Sanchez
    @{dominios}=    Create List    gmail.com    hotmail.com    pi2.local

    # GENERAR DATOS UNICOS
    ${epoch}=    Get Current Date    result_format=epoch
    ${epoch_int}=    Evaluate    int(float(${epoch}))

    ${indice_n}=    Evaluate    ${epoch_int} % 12
    ${indice_a}=    Evaluate    (${epoch_int} + 5) % 12
    ${indice_d}=    Evaluate    ${epoch_int} % 3

    ${nombre}=    Set Variable    ${nombres}[${indice_n}]
    ${apellido_base}=    Set Variable    ${apellidos}[${indice_a}]

    ${apellido}=    Set Variable    ${apellido_base}-${epoch_int}
    ${nombre_completo}=    Set Variable    ${nombre} ${apellido}

    # CORREO UNICO
    ${correo}=    Set Variable    rpa.${amb}.${epoch_int}@${dominios}[${indice_d}]

    # TELEFONO
    ${tel_short}=    Evaluate    str(${epoch_int})[-8:]
    ${telefono}=    Set Variable    +506 ${tel_short}

    Log To Console    ========================================
    Log To Console    REGISTRANDO CONTACTO
    Log To Console    AMBIENTE: ${amb}
    Log To Console    NOMBRE: ${nombre_completo}
    Log To Console    CORREO: ${correo}
    Log To Console    ========================================

    # ABRIR FORMULARIO
    Go To    ${url}/#Contact/create
    Wait For Elements State    css=input[data-name='firstName']    visible    timeout=${NAV_TIMEOUT}

    # LLENAR CAMPOS
    Fill Text    css=input[data-name='firstName']    ${nombre}
    Fill Text    css=input[data-name='lastName']    ${apellido}
    Fill Text    css=div[data-name='emailAddress'] input >> nth=0    ${correo}
    Fill Text    css=input[data-intl-tel-input-id='0']    ${telefono}

    # GUARDAR
    Click    ${SAVE_BUTTON}

    Wait For Elements State    text=${nombre_completo} >> nth=0    visible    timeout=${NAV_TIMEOUT}

    # MEJOR ESFUERZO: si la pantalla no muestra el contacto recien creado, se abre desde el
    # listado. NUNCA hace fallar el registro (el contacto ya esta guardado).
    Run Keyword And Ignore Error    Mostrar Contacto Creado    ${url}    ${correo}

    Sleep    2s

    # EVIDENCIA EXCLUSIVA DEL REGISTRO
    Take Screenshot    filename=${OUTPUT DIR}/registro_contacto_${amb}.png

    Log To Console    ----------------------------------------
    Log To Console    CONTACTO REGISTRADO CORRECTAMENTE
    Log To Console    ${nombre_completo}
    Log To Console    CORREO: ${correo}
    Log To Console    EVIDENCIA: registro_contacto_${amb}.png
    Log To Console    ----------------------------------------

    # DEVOLVER CORREO PARA LA BUSQUEDA
    RETURN    ${correo}


# =====================================================
# MOSTRAR EL CONTACTO RECIEN CREADO (solo para que la evidencia sea la correcta)
# =====================================================

Mostrar Contacto Creado
    [Arguments]    ${url}    ${correo}
    ${ya}=    Run Keyword And Return Status
    ...    Wait For Elements State    text=${correo} >> nth=0    visible    timeout=4s
    IF    ${ya}
        RETURN
    END
    Go To    ${url}/#Contact
    Resolver Confirmacion Salida
    ${b}=    Detectar Buscador
    Click    ${b}
    Clear Text    ${b}
    Fill Text    ${b}    ${correo}
    Press Keys    ${b}    Enter
    Wait For Elements State    css=tr.list-row:not(:has-text("${correo}"))    detached    timeout=8s
    Click    css=tr.list-row:has-text("${correo}") td[data-name='name'] a >> nth=0
    Wait For Elements State    text=${correo} >> nth=0    visible    timeout=8s


# =====================================================
# RESOLVER CONFIRMACION DE SALIDA
# =====================================================

Resolver Confirmacion Salida
    ${confirmacion}=    Run Keyword And Return Status
    ...    Wait For Elements State    text=¿Realmente desea salir del formulario?    visible    timeout=3s

    IF    ${confirmacion}
        Log To Console    CONFIRMACION DE SALIDA DETECTADA
        Click    text=Sí
        Sleep    2s
        Log To Console    CONFIRMACION ACEPTADA
    END


# =====================================================
# DETECTAR BUSCADOR
# =====================================================

Detectar Buscador
    Sleep    2s

    ${cantidad}=    Get Element Count    css=input[data-name='textFilter']
    IF    ${cantidad} > 0
        RETURN    css=input[data-name='textFilter']
    END

    ${cantidad}=    Get Element Count    css=input.text-filter
    IF    ${cantidad} > 0
        RETURN    css=input.text-filter
    END

    ${cantidad}=    Get Element Count    css=.text-filter input
    IF    ${cantidad} > 0
        RETURN    css=.text-filter input
    END

    ${cantidad}=    Get Element Count    css=.text-filter-container input
    IF    ${cantidad} > 0
        RETURN    css=.text-filter-container input
    END

    Take Screenshot    filename=${OUTPUT DIR}/error_buscador.png
    Fail    No se encontro el campo de busqueda de EspoCRM.


# =====================================================
# CONSULTA
# =====================================================

Hacer Consulta
    [Arguments]    ${url}

    Log To Console    ABRIENDO LISTADO DE CONTACTOS

    Go To    ${url}/#Contact

    Resolver Confirmacion Salida

    ${buscador}=    Detectar Buscador

    Wait For Elements State    ${buscador}    visible    timeout=${NAV_TIMEOUT}

    Log To Console    LISTADO DISPONIBLE
    Log To Console    BUSCADOR: ${buscador}


# =====================================================
# BUSCAR CONTACTO POR CORREO ELECTRONICO
# =====================================================

Buscar Contacto
    [Arguments]    ${url}    ${correo}    ${amb}

    Log To Console    ========================================
    Log To Console    BUSCANDO CONTACTO POR CORREO
    Log To Console    AMBIENTE: ${amb}
    Log To Console    CORREO: ${correo}
    Log To Console    ========================================

    # ABRIR LISTADO
    Go To    ${url}/#Contact
    Resolver Confirmacion Salida

    # Sin correo (el registro fallo) no hay nada que buscar: el paso se marca como fallido,
    # pero su evidencia muestra el listado de contactos, no la pantalla del registro.
    IF    '${correo}' == ''
        Fail    Omitido: el paso registro fallo, no hay correo que buscar.
    END

    ${buscador}=    Detectar Buscador
    Wait For Elements State    ${buscador}    visible    timeout=${NAV_TIMEOUT}

    # ESCRIBIR CORREO (se limpia el campo y se comprueba que el correo quedo escrito)
    Click    ${buscador}
    Clear Text    ${buscador}
    Fill Text    ${buscador}    ${correo}
    Get Property    ${buscador}    value    ==    ${correo}
    Log To Console    CORREO ESCRITO EN BUSCADOR

    # PRESIONAR ENTER
    Press Keys    ${buscador}    Enter
    Log To Console    ENTER PRESIONADO

    # ESPERAR A QUE EL FILTRO SE APLIQUE: ya no debe quedar ninguna fila sin ese correo.
    # Si Enter no lo aplico, se usa el boton de busqueda.
    ${filtrado}=    Run Keyword And Return Status
    ...    Wait For Elements State    css=tr.list-row:not(:has-text("${correo}"))    detached    timeout=8s
    IF    not ${filtrado}
        Log To Console    ENTER NO APLICO EL FILTRO: se usa el boton de busqueda
        Click    css=.search-container button[data-action='search'] >> nth=0
        Wait For Elements State    css=tr.list-row:not(:has-text("${correo}"))    detached    timeout=${NAV_TIMEOUT}
    END

    # ESPERAR RESULTADO QUE CONTENGA EL CORREO
    ${fila_locator}=    Set Variable    css=tr.list-row:has-text("${correo}")
    Wait For Elements State    ${fila_locator}    visible    timeout=${NAV_TIMEOUT}

    # CONTAR COINCIDENCIAS
    ${cantidad}=    Get Element Count    ${fila_locator}
    Log To Console    COINCIDENCIAS ENCONTRADAS: ${cantidad}

    Should Be Equal As Integers    ${cantidad}    1    Se esperaba exactamente un contacto, pero aparecieron ${cantidad}.

    # LEER RESULTADO
    ${fila}=    Get Text    ${fila_locator}
    Should Contain    ${fila}    ${correo}

    # EVIDENCIA DE BUSQUEDA
    Take Screenshot    filename=${OUTPUT DIR}/contacto_encontrado_${amb}.png

    Log To Console    ========================================
    Log To Console    CONTACTO ENCONTRADO CORRECTAMENTE
    Log To Console    CORREO: ${correo}
    Log To Console    EVIDENCIA: contacto_encontrado_${amb}.png
    Log To Console    ========================================

    RETURN    ${correo}