Code.require_file("validacion.exs", __DIR__)

defmodule Movimiento do
  @moduledoc """
  Estructura que representa un movimiento sísmico (archivo movimientos.txt).
  Cada línea del archivo tiene el formato:
  código@idCiudad@horaInicio@horaFinal@magnitud@profundidad
  - Autores: Isabel Cristina Guerra Guzmán y Jhonatan Mosquera Correa
  - Fecha: Noviembre del 2026
  - Licencia: GNU GPL v3
  """

  defstruct codigo: "",
            id_ciudad: "",
            hora_inicio: "",
            hora_final: "",
            magnitud: 0.0,
            profundidad: 0.0

  @doc """
  Crea un movimiento sísmico con datos que ya fueron validados.

  ## Ejemplo

      Movimiento.crear("S001", "C01", "08:15:02", "08:15:18", 3.4, 18.0)
  """
  def crear(codigo, id_ciudad, hora_inicio, hora_final, magnitud, profundidad) do
    %Movimiento{
      codigo: codigo,
      id_ciudad: id_ciudad,
      hora_inicio: hora_inicio,
      hora_final: hora_final,
      magnitud: magnitud,
      profundidad: profundidad
    }
  end

  @doc """
  Convierte una línea del archivo en un movimiento sísmico.
  Retorna `{:ok, movimiento}` si la línea es válida o `{:error, motivo}` si se debe rechazar.
  (La existencia de la ciudad se revisa después, en el módulo Reporte,
  porque requiere el catálogo de ciudades).

  ## Ejemplo

      Movimiento.desde_linea("S001@C01@08:15:02@08:15:18@3.4@18.0")
  """
  def desde_linea(linea) do
    linea
    |> String.split("@")
    |> Enum.map(&String.trim/1)
    |> validar_campos()
  end

  # Solo se aceptan líneas con exactamente seis campos válidos.
  defp validar_campos([codigo, id_ciudad, hora_inicio, hora_final, magnitud, profundidad]) do
    case {
           Validacion.texto_obligatorio(codigo),
           Validacion.texto_obligatorio(id_ciudad),
           Validacion.hora(hora_inicio),
           Validacion.hora(hora_final),
           Validacion.real(magnitud),
           Validacion.real_no_negativo(profundidad)
         } do
      {{:ok, codigo_valido}, {:ok, id_ciudad_valido}, {:ok, inicio_valido}, {:ok, final_valido},
       {:ok, magnitud_valida}, {:ok, profundidad_valida}} ->
        {:ok,
         crear(
           codigo_valido,
           id_ciudad_valido,
           inicio_valido,
           final_valido,
           magnitud_valida,
           profundidad_valida
         )}

      _ ->
        {:error, "Campo vacío o dato inválido"}
    end
  end

  defp validar_campos(_campos),
    do:
      {:error,
       "La línea no tiene el formato código@idCiudad@horaInicio@horaFinal@magnitud@profundidad"}
end
