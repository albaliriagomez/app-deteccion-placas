from datetime import datetime

def obtener_estado_parqueo(parking):

    # Si no hay registro
    if parking is None:
        return "No Registrado"

    # hora actual
    ahora = datetime.now()

    # fecha del registro
    fecha_registro = parking["date_register"]

    # hora fin
    hora_fin = parking["hour_end"]

    # unir fecha + hora
    fecha_hora_fin = datetime.strptime(
        fecha_registro[:10] + " " + hora_fin,
        "%Y-%m-%d %H:%M:%S"
    )

    # comparar
    if ahora > fecha_hora_fin:
        return "Pago Vencido"
    else:
        return "Pago Vigente"