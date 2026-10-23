// Zabbix > Alertas > Tipos de medios > Crear > Tipo: Webhook > pegar este script en "Script".
// Parametros del tipo de medio (pestana Parametros):
//   url     = http://192.168.50.11:5678/webhook/crm-incidente
//   token   = <valor del token del webhook>  (se guarda en el tipo de medio, NO en este archivo)
//   message = {ALERT.MESSAGE}
var p = JSON.parse(value);
var datos;
try {
    datos = JSON.parse(p.message);
} catch (e) {
    throw 'El mensaje de la accion no es JSON valido: ' + p.message;
}
var req = new HttpRequest();
req.addHeader('Content-Type: application/json');
req.addHeader('X-Token: ' + p.token);
var resp = req.post(p.url, JSON.stringify(datos));
if (req.getStatus() < 200 || req.getStatus() >= 300) {
    throw 'n8n respondio HTTP ' + req.getStatus() + ': ' + resp;
}
return 'OK';
