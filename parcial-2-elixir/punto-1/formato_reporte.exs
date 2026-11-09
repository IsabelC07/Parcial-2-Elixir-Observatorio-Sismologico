defmodule FormatoReporte do
  @moduledoc """
  Responsabilidad: construir los textos que se muestran al usuario
  (reporte general, reporte de una ciudad y mensajes de error).
  - Autores: Isabel Cristina Guerra Guzmán y Jhonatan Mosquera Correa
  - Fecha: Noviembre del 2026
  - Licencia: GNU GPL v3
  """

  @linea_doble "================================================================"
  @linea_simple "----------------------------------------------------------------"

  @doc """
  Genera el texto del reporte general: todas las ciudades válidas con su detalle
  y, al final, los registros rechazados por archivo.
  """
  def texto_general(reporte) do
    encabezado() <>
      texto_ciudades(reporte.ciudades) <>
      @linea_doble <>
      "\n" <>
      texto_rechazados(reporte.rechazados) <>
      @linea_doble
  end

  @doc """
  Genera el texto de una ciudad: nombre, habitantes, detalle de movimientos,
  total, movimiento de mayor magnitud y profundidad promedio.
  """
  def texto_ciudad(resumen) do
    ciudad = resumen.ciudad

    "Ciudad: #{ciudad.nombre} (#{ciudad.id})\n" <>
      "Habitantes: #{ciudad.habitantes}\n" <>
      texto_movimientos(resumen.movimientos) <>
      "Total de movimientos: #{resumen.cantidad}\n" <>
      "Movimiento de mayor magnitud: #{texto_mayor(resumen.mayor)}\n" <>
      "Profundidad promedio: #{texto_promedio(resumen.profundidad_promedio)}\n"
  end

  @doc """
  Genera el texto de los archivos que no se pudieron leer.
  Recibe una lista de `{ruta, razon}`.
  """
  def texto_errores(errores) do
    errores
    |> Enum.map(fn {ruta, razon} ->
      "Error: no se pudo leer el archivo #{ruta} (#{describir_error(razon)})."
    end)
    |> Enum.join("\n")
  end

  @doc """
  Traduce a un texto comprensible la razón de un error de archivo.
  """
  def describir_error(:sin_respuesta), do: "el proceso trabajador no respondió a tiempo"
  def describir_error(razon), do: Archivos.describir_error(razon)

  defp encabezado() do
    @linea_doble <>
      "\n" <>
      "REPORTE DE SISMOS POR CIUDAD\n" <>
      "Observatorio Sismológico - Universidad del Quindío\n" <>
      @linea_doble <>
      "\n"
  end

  # Une el texto de todas las ciudades separándolas con una línea.
  defp texto_ciudades([]), do: "No hay ciudades válidas en el catálogo.\n"

  defp texto_ciudades(resumenes) do
    resumenes
    |> Enum.map(&texto_ciudad/1)
    |> Enum.join(@linea_simple <> "\n")
  end

  defp texto_movimientos([]), do: "Movimientos: Sin movimientos registrados\n"

  defp texto_movimientos(movimientos) do
    detalle =
      movimientos
      |> Enum.map(&texto_movimiento/1)
      |> Enum.join()

    "Movimientos:\n" <> detalle
  end

  defp texto_movimiento(movimiento) do
    "  - #{movimiento.codigo} | Inicio: #{movimiento.hora_inicio}" <>
      " | Final: #{movimiento.hora_final} | Magnitud: #{movimiento.magnitud}" <>
      " | Profundidad: #{movimiento.profundidad} km\n"
  end

  defp texto_mayor(nil), do: "No aplica"
  defp texto_mayor(movimiento), do: "#{movimiento.codigo} · #{movimiento.magnitud}"

  defp texto_promedio(nil), do: "No aplica"
  defp texto_promedio(promedio), do: "#{Util.formatter(promedio)} km"

  # Muestra cuántas líneas se rechazaron en cada archivo y el total.
  defp texto_rechazados(rechazados) do
    detalle =
      rechazados
      |> Enum.map(fn {archivo, cantidad} -> "  #{archivo}: #{cantidad}\n" end)
      |> Enum.join()

    total = Enum.reduce(rechazados, 0, fn {_archivo, cantidad}, acumulado -> acumulado + cantidad end)

    "REGISTROS RECHAZADOS\n" <> detalle <> "  Total: #{total}\n"
  end
end
