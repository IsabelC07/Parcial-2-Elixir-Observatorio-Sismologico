Code.require_file("ciudad.exs", __DIR__)
Code.require_file("movimiento.exs", __DIR__)

defmodule Reporte do
  @moduledoc """
  Responsabilidad: calcular el reporte de sismos por ciudad.
  No lee archivos ni muestra mensajes; solo trabaja con los datos ya leídos.
  - Autores: Isabel Cristina Guerra Guzmán y Jhonatan Mosquera Correa
  - Fecha: Noviembre del 2026
  - Licencia: GNU GPL v3
  """

  @doc """
  Construye el reporte a partir de las lecturas de ciudades y de movimientos
  (cada una con la forma `%{archivo: ruta, registros: lista, rechazados: cantidad}`).

  Los movimientos cuya ciudad no está en el catálogo válido se excluyen y se suman
  a los rechazados del archivo de movimientos.

  ## Retorna

      %{
        ciudades: [resumen_ciudad, ...],
        rechazados: [{ruta_ciudades, cantidad}, {ruta_movimientos, cantidad}]
      }
  """
  def generar(lectura_ciudades, lectura_movimientos) do
    ciudades = lectura_ciudades.registros
    movimientos = filtrar_movimientos_validos(lectura_movimientos.registros, ciudades)
    sin_ciudad_valida = length(lectura_movimientos.registros) - length(movimientos)

    # Agrupa por ciudad conservando el orden en que aparecen en el archivo.
    movimientos_por_ciudad = Enum.group_by(movimientos, fn movimiento -> movimiento.id_ciudad end)

    %{
      ciudades:
        Enum.map(ciudades, fn ciudad ->
          resumir_ciudad(ciudad, Map.get(movimientos_por_ciudad, ciudad.id, []))
        end),
      rechazados: [
        {lectura_ciudades.archivo, lectura_ciudades.rechazados},
        {lectura_movimientos.archivo, lectura_movimientos.rechazados + sin_ciudad_valida}
      ]
    }
  end

  @doc """
  Busca el resumen de una ciudad dentro de un reporte ya generado.
  Retorna `{:ok, resumen}` o `:error` si la ciudad no es válida o no existe.
  """
  def buscar_ciudad(reporte, id_ciudad) do
    case Enum.filter(reporte.ciudades, fn resumen -> resumen.ciudad.id == id_ciudad end) do
      [resumen | _] -> {:ok, resumen}
      [] -> :error
    end
  end

  @doc """
  Genera el resumen de una ciudad: sus movimientos, la cantidad, el movimiento de mayor
  magnitud y la profundidad promedio (`nil` cuando no hay movimientos, es decir, "No aplica").
  """
  def resumir_ciudad(ciudad, movimientos) do
    estadisticas = calcular_estadisticas(movimientos)

    %{
      ciudad: ciudad,
      movimientos: movimientos,
      cantidad: estadisticas.cantidad,
      mayor: estadisticas.mayor,
      profundidad_promedio:
        calcular_promedio(estadisticas.suma_profundidades, estadisticas.cantidad)
    }
  end

  @doc """
  Recorre recursivamente los movimientos de una ciudad y calcula, en un mismo recorrido,
  la cantidad de movimientos, el de mayor magnitud y la suma de profundidades.

  ## Ejemplo

      Reporte.calcular_estadisticas([s001, s003])
      # %{cantidad: 2, mayor: s001, suma_profundidades: 28.0}
  """
  def calcular_estadisticas(movimientos), do: calcular_estadisticas(movimientos, 0, nil, 0.0)

  # Caso base: no quedan movimientos por recorrer.
  defp calcular_estadisticas([], cantidad, mayor, suma_profundidades) do
    %{cantidad: cantidad, mayor: mayor, suma_profundidades: suma_profundidades}
  end

  # Caso recursivo (de cola): procesa el primer movimiento y continúa con el resto.
  defp calcular_estadisticas([movimiento | resto], cantidad, mayor, suma_profundidades) do
    calcular_estadisticas(
      resto,
      cantidad + 1,
      elegir_mayor(mayor, movimiento),
      suma_profundidades + movimiento.profundidad
    )
  end

  # Primer movimiento: todavía no hay un mayor.
  defp elegir_mayor(nil, movimiento), do: movimiento

  # Solo se reemplaza si la magnitud es estrictamente mayor;
  # así, en caso de empate se conserva el primero que aparece en el archivo.
  defp elegir_mayor(%Movimiento{magnitud: magnitud_mayor}, %Movimiento{magnitud: magnitud} = movimiento)
       when magnitud > magnitud_mayor,
       do: movimiento

  defp elegir_mayor(mayor, _movimiento), do: mayor

  # Sin movimientos no hay promedio ("No aplica").
  defp calcular_promedio(_suma, 0), do: nil
  defp calcular_promedio(suma, cantidad), do: suma / cantidad

  # Deja solo los movimientos cuya ciudad pertenece al catálogo de ciudades válidas.
  defp filtrar_movimientos_validos(movimientos, ciudades) do
    ids_validos = Enum.map(ciudades, fn ciudad -> ciudad.id end)
    Enum.filter(movimientos, fn movimiento -> movimiento.id_ciudad in ids_validos end)
  end
end
