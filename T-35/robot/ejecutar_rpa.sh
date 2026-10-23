#!/bin/bash
# Ejecuta el RPA de UN ambiente y devuelve como ULTIMA linea de stdout un JSON con
# resultado, tiempo y pasos. Lo invoca n8n por SSH:
#   sudo -u rpa-runner /opt/rpa/ejecutar_rpa.sh A      (CRM Ubuntu)   |   ... B   (CRM Windows)
# Segundo argumento opcional: SI (por defecto, crea el contacto de prueba) o NO (solo login y consulta).
# Codigo de salida: 0 = PASS, 1 = FAIL/ERROR. n8n usa el JSON, no el codigo.
set -u
AMB="${1:-}"
REGISTRO="${2:-SI}"
case "$AMB" in A|B) ;; *) echo '{"resultado":"ERROR","segundos":null,"pasos":[],"mensaje":"Uso: ejecutar_rpa.sh A|B [SI|NO]"}'; exit 2;; esac
case "$REGISTRO" in SI|NO) ;; *) echo '{"resultado":"ERROR","segundos":null,"pasos":[],"mensaje":"El segundo argumento debe ser SI o NO"}'; exit 2;; esac

ROBOT_BIN="${ROBOT_BIN:-/opt/rpa/venv/bin/robot}"
RPA_DIR="${RPA_DIR:-/opt/rpa}"
ENV_FILE="${ENV_FILE:-/etc/rpa/crm.env}"
HIST="${HISTORIAL_CSV:-/var/log/rpa/rpa_resultados.csv}"
LIMITE="${LIMITE_SEGUNDOS:-150}"
export PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-/opt/rpa/browsers}"

# Credenciales (CRM_USER_A/B, CRM_PASS_A/B) desde el archivo de entorno; nunca se imprimen.
if [ -r "$ENV_FILE" ]; then set -a; . "$ENV_FILE"; set +a; fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
CSV_RUN="$TMP/corrida.csv"      # CSV solo de esta corrida (evita mezclar filas con el timer)
SALIDA="$RPA_DIR/resultados/remediacion"
mkdir -p "$SALIDA"

T0=$(date +%s.%N)
timeout "$LIMITE" "$ROBOT_BIN" --nostatusrc --timestampoutputs --outputdir "$SALIDA" \
  --include "ambiente-$AMB" --variable REGISTRO:"$REGISTRO" --variable HISTORIAL_CSV:"$CSV_RUN" \
  "$RPA_DIR/crm_synthetic.robot" > "$TMP/robot.out" 2>&1
RC=$?
T1=$(date +%s.%N)

# Se agregan las filas de esta corrida al historial central (sin repetir el encabezado, con candado).
if [ -s "$CSV_RUN" ]; then
  mkdir -p "$(dirname "$HIST")" 2>/dev/null
  {
    flock 9
    if [ ! -s "$HIST" ]; then head -n 1 "$CSV_RUN" >> "$HIST"; fi
    tail -n +2 "$CSV_RUN" >> "$HIST"
  } 9>>"$HIST.lock" 2>/dev/null
fi

export CSV_RUN RC AMB T0 T1 SALIDA ROBOT_OUT="$TMP/robot.out"
python3 - << 'PY'
import csv, json, os
filas = []
try:
    with open(os.environ["CSV_RUN"], newline="", encoding="utf-8") as f:
        filas = list(csv.DictReader(f))
except OSError:
    pass
pasos = [{"paso": r["paso"], "resultado": r["resultado"], "segundos": float(r["segundos"] or 0)}
         for r in filas if r.get("ambiente") == os.environ["AMB"]]
fallos = [r for r in filas if r["resultado"] == "FAIL"]
rc = int(os.environ["RC"])
total = round(float(os.environ["T1"]) - float(os.environ["T0"]), 1)
out = {"ambiente": os.environ["AMB"], "segundos": total, "pasos": pasos}
if rc == 124:
    out.update(resultado="ERROR", mensaje="Tiempo maximo excedido; el RPA se detuvo")
elif not pasos:
    # Sin filas: casi siempre falta una credencial o Robot no pudo arrancar. Se busca la causa en su salida.
    causa = ""
    try:
        lineas = open(os.environ["ROBOT_OUT"], encoding="utf-8", errors="replace").read().splitlines()
        for i, l in enumerate(lineas):
            if "| FAIL |" in l and i + 1 < len(lineas):
                sig = lineas[i + 1].strip()
                if sig and not set(sig) <= set("-="):
                    causa = sig[:150]
                    break
        if not causa:
            causa = next((l.strip()[:150] for l in lineas if l.strip().startswith(("[ ERROR ]", "Error", "bash:")) or "No such file" in l), "")
    except OSError:
        pass
    out.update(resultado="ERROR", mensaje=("Robot no genero resultados" + (": " + causa if causa else " (codigo %d)" % rc)) + ". Revisar " + os.environ["SALIDA"])
elif fallos:
    out.update(resultado="FAIL", mensaje="%s: %s" % (fallos[0]["paso"], fallos[0]["mensaje"][:150]))
else:
    out.update(resultado="PASS")
print(json.dumps(out, ensure_ascii=False))
raise SystemExit(0 if out["resultado"] == "PASS" else 1)
PY
