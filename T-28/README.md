# T-28: Pruebas RPA en ambos CRM

Scripts de Robot Framework para automatizar las pruebas de login, consulta y registro de contactos en las dos instancias de EspoCRM del proyecto.

## Estructura

| Archivo | Descripción |
| :--- | :--- |
| `variables_comunes.robot` | Variables y keywords compartidos |
| `guion_rpa_ubuntu.robot` | Flujo completo para VM-01 (Ubuntu) |
| `guion_rpa_windows.robot` | Flujo completo para VM-02 (Windows) |
| `run_t28.sh` | Script de ejecución de ambos guiones |
| `.gitignore` | Excluye credenciales y resultados del repositorio |

## Requisitos

- Python 3.12+
- Robot Framework 7.5+
- SeleniumLibrary 6.9+
- Selenium 4.50+
- Chromium o Google Chrome

## Configuración

1. Crear el archivo `credenciales.py` en la raíz de `T-28/` con el siguiente contenido:

```python
USER_UBUNTU = "rpaubuntu"
PASS_UBUNTU = "tu_contraseña_real"

USER_WINDOWS = "rpawindows"
PASS_WINDOWS = "tu_contraseña_real"
