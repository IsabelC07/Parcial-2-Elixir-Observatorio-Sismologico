defmodule NodoCliente do
  @moduledoc """
  Nodo cliente del punto 2. Registra el proceso :servicio_respuesta, se conecta con el
  nodo servidor, envía las solicitudes en orden y muestra las respuestas hasta recibir :fin.
  - Autores: Isabel Cristina Guerra Guzmán y Jhonatan Mosquera Correa
  - Fecha: Noviembre del 2026
  - Licencia: GNU GPL v3
  """

  @nombre_servicio_local :servicio_respuesta
  @nodo_remoto :nodoservidor@localhost
  @servicio_remoto {:servicio_sismos, @nodo_remoto}

  # Tiempo máximo (en milisegundos) que se espera cada respuesta del servidor.
  @tiempo_espera 15_000

  # Solicitudes en el orden exigido:
  # 1. ciudad con movimientos, 2. ciudad sin movimientos,
  # 3. ciudad inexistente, 4. reporte general, 5. fin.
  @solicitudes [
    {:reporte_ciudad, "C01"},
    {:reporte_ciudad, "C03"},
    {:reporte_ciudad, "C99"},
    :reporte_general,
    :fin
  ]

  @doc """
  Función principal: registra el servicio local, se conecta con el servidor
  y, si la conexión es exitosa, envía las solicitudes y recibe las respuestas.
  """
  def main() do
    Util.mostrar_mensaje("NODO CLIENTE (#{node()}) - Consulta de reportes sísmicos")

    @nombre_servicio_local
    |> registrar_servicio()

    @nodo_remoto
    |> establecer_conexion()
    |> iniciar_consultas()
  end

  defp registrar_servicio(nombre_servicio_local),
    do: Process.register(self(), nombre_servicio_local)

  # Node.connect/1 retorna true (conectado), false (falló) o :ignored (nodo no distribuido).
  defp establecer_conexion(nodo_remoto), do: Node.connect(nodo_remoto)

  defp iniciar_consultas(true) do
    enviar_solicitudes(@solicitudes, 1)
    recibir_respuestas(1)
  end

  defp iniciar_consultas(false) do
    Util.mostrar_error("Error: no se pudo conectar con el nodo servidor #{@nodo_remoto}.")
  end

  defp iniciar_consultas(:ignored) do
    Util.mostrar_error(
      "Error: el nodo cliente no se inició como nodo distribuido (use --sname y --cookie)."
    )
  end

  # Identifica el proceso registrado y el nodo cliente, para que el servidor sepa
  # a dónde enviar la respuesta. node() retorna el nombre real de este nodo.
  defp destino_respuesta(), do: {@nombre_servicio_local, node()}

  # Caso base: ya se enviaron todas las solicitudes.
  defp enviar_solicitudes([], _numero), do: :ok

  # Caso recursivo: envía la primera solicitud con la forma {destino_respuesta, solicitud}.
  defp enviar_solicitudes([solicitud | resto], numero) do
    Util.mostrar_mensaje("Enviando solicitud #{numero}: #{inspect(solicitud)}")
    send(@servicio_remoto, {destino_respuesta(), solicitud})
    enviar_solicitudes(resto, numero + 1)
  end

  # Recibe y muestra las respuestas de forma recursiva hasta recibir :fin.
  defp recibir_respuestas(numero) do
    receive do
      :fin ->
        Util.mostrar_mensaje("\nEl servidor confirmó :fin. Consulta terminada.")

      respuesta ->
        Util.mostrar_mensaje("\n---------- Respuesta #{numero} ----------\n#{respuesta}")
        recibir_respuestas(numero + 1)
    after
      @tiempo_espera ->
        Util.mostrar_error("Error: el servidor no respondió (tiempo de espera agotado).")
    end
  end
end

NodoCliente.main()
