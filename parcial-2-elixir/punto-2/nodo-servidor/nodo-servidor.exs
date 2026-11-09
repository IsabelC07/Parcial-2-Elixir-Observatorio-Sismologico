# Se reutilizan los structs, las validaciones, la lectura concurrente y los cálculos
# del punto 1 (copias de los mismos módulos ubicadas en esta carpeta).
Code.require_file("coordinador.exs", __DIR__)
Code.require_file("reporte.exs", __DIR__)
Code.require_file("formato_reporte.exs", __DIR__)

defmodule NodoServidor do
  @moduledoc """
  Nodo servidor del punto 2. Registra el proceso :servicio_sismos y atiende,
  una por una, las solicitudes de los clientes:

    - `{:reporte_ciudad, id_ciudad}`: reporte de una ciudad.
    - `:reporte_general`: reporte de todas las ciudades y registros rechazados.
    - `:fin`: confirma :fin al cliente y vuelve a esperar solicitudes.

  En cada solicitud de reporte se leen de nuevo, de forma concurrente,
  resources/ciudades.txt y resources/movimientos.txt.
  - Autores: Isabel Cristina Guerra Guzmán y Jhonatan Mosquera Correa
  - Fecha: Noviembre del 2026
  - Licencia: GNU GPL v3
  """

  @nombre_servicio_local :servicio_sismos
  @ruta_ciudades "resources/ciudades.txt"
  @ruta_movimientos "resources/movimientos.txt"

  @doc """
  Función principal: registra el servicio y comienza a atender solicitudes.
  """
  def main() do
    Util.mostrar_mensaje("NODO SERVIDOR (#{node()}) - Servicio de reportes sísmicos")
    registrar_servicio(@nombre_servicio_local)
    Util.mostrar_mensaje("Esperando solicitudes en #{inspect(@nombre_servicio_local)}...")
    procesar_mensajes()
  end

  defp registrar_servicio(nombre_servicio_local),
    do: Process.register(self(), nombre_servicio_local)

  # Atiende un mensaje a la vez. Como cada solicitud se responde antes de recibir la
  # siguiente, las respuestas salen en el mismo orden en que llegaron las solicitudes.
  # Siempre se llama recursivamente para seguir atendiendo (incluso después de :fin).
  defp procesar_mensajes() do
    receive do
      {destino_respuesta, solicitud} ->
        Util.mostrar_mensaje("Solicitud recibida: #{inspect(solicitud)}")
        respuesta = procesar_solicitud(solicitud)
        send(destino_respuesta, respuesta)
        mostrar_estado(solicitud)
        procesar_mensajes()

      _mensaje_desconocido ->
        # Mensajes con otra forma se descartan para no llenar el buzón.
        procesar_mensajes()
    end
  end

  # Confirmación de fin: se envía después de las respuestas anteriores.
  defp procesar_solicitud(:fin), do: :fin

  defp procesar_solicitud({:reporte_ciudad, id_ciudad}) do
    generar_respuesta(fn reporte -> responder_ciudad(reporte, id_ciudad) end)
  end

  defp procesar_solicitud(:reporte_general) do
    generar_respuesta(&FormatoReporte.texto_general/1)
  end

  defp procesar_solicitud(solicitud) do
    "La solicitud #{inspect(solicitud)} es desconocida."
  end

  # Lee la versión actual de ambos archivos (de forma concurrente, como en el punto 1)
  # y aplica la función `formatear` al reporte. Si un archivo falla, responde cuál fue.
  defp generar_respuesta(formatear) do
    case Coordinador.leer_archivos(@ruta_ciudades, @ruta_movimientos) do
      {:ok, lectura_ciudades, lectura_movimientos} ->
        Reporte.generar(lectura_ciudades, lectura_movimientos)
        |> formatear.()

      {:error, errores} ->
        FormatoReporte.texto_errores(errores)
    end
  end

  defp responder_ciudad(reporte, id_ciudad) do
    case Reporte.buscar_ciudad(reporte, id_ciudad) do
      {:ok, resumen} -> FormatoReporte.texto_ciudad(resumen)
      :error -> "La ciudad no está registrada"
    end
  end

  defp mostrar_estado(:fin),
    do: Util.mostrar_mensaje("Cliente atendido. Esperando nuevas solicitudes...\n")

  defp mostrar_estado(_solicitud), do: :ok
end

NodoServidor.main()
