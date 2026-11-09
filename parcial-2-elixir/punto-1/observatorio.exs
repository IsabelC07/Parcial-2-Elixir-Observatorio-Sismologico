Code.require_file("coordinador.exs", __DIR__)
Code.require_file("reporte.exs", __DIR__)
Code.require_file("formato_reporte.exs", __DIR__)

defmodule Observatorio do
  @moduledoc """
  Programa principal del punto 1 (Observatorio Sismológico de la Universidad del Quindío).
  Lee los dos archivos de forma concurrente, genera el reporte de sismos por ciudad,
  lo muestra en consola y lo guarda en resources/reporte_sismos.txt.
  - Autores: Isabel Cristina Guerra Guzmán y Jhonatan Mosquera Correa
  - Fecha: Noviembre del 2026
  - Licencia: GNU GPL v3
  """

  @ruta_ciudades "resources/ciudades.txt"
  @ruta_movimientos "resources/movimientos.txt"
  @ruta_reporte "resources/reporte_sismos.txt"

  @doc """
  Función principal: coordina la lectura y, según el resultado, genera el reporte
  o informa qué archivo produjo el error.
  """
  def main do
    Coordinador.leer_archivos(@ruta_ciudades, @ruta_movimientos)
    |> procesar_lectura()
  end

  # Ambos archivos se leyeron: se calcula, se muestra y se guarda el reporte.
  defp procesar_lectura({:ok, lectura_ciudades, lectura_movimientos}) do
    texto =
      Reporte.generar(lectura_ciudades, lectura_movimientos)
      |> FormatoReporte.texto_general()

    Util.mostrar_mensaje(texto)
    guardar_reporte(texto)
  end

  # Algún archivo falló: se informa cuál y no se toca el reporte anterior.
  defp procesar_lectura({:error, errores}) do
    errores
    |> FormatoReporte.texto_errores()
    |> Util.mostrar_error()

    Util.mostrar_error("No se generó un nuevo reporte; se conserva el anterior (#{@ruta_reporte}).")
  end

  # Reemplaza el contenido del archivo de reporte o informa el error de escritura.
  defp guardar_reporte(texto) do
    case Archivos.guardar_texto(@ruta_reporte, texto) do
      :ok ->
        Util.mostrar_mensaje("\nReporte guardado en #{@ruta_reporte}")

      {:error, razon} ->
        Util.mostrar_error(
          "Error: no se pudo guardar el reporte en #{@ruta_reporte} " <>
            "(#{FormatoReporte.describir_error(razon)})."
        )
    end
  end
end

Observatorio.main()
