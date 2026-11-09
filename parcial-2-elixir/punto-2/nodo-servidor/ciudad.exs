Code.require_file("validacion.exs", __DIR__)

defmodule Ciudad do
  @moduledoc """
  Estructura que representa una ciudad del catálogo (archivo ciudades.txt).
  Cada línea del archivo tiene el formato: idCiudad@nombre@numeroHabitantes
  - Autores: Isabel Cristina Guerra Guzmán y Jhonatan Mosquera Correa
  - Fecha: Noviembre del 2026
  - Licencia: GNU GPL v3
  """

  defstruct id: "", nombre: "", habitantes: 0

  @doc """
  Crea una ciudad con datos que ya fueron validados.

  ## Ejemplo

      Ciudad.crear("C01", "Armenia", 304314)
  """
  def crear(id, nombre, habitantes) do
    %Ciudad{id: id, nombre: nombre, habitantes: habitantes}
  end

  @doc """
  Convierte una línea del archivo en una ciudad.
  Retorna `{:ok, ciudad}` si la línea es válida o `{:error, motivo}` si se debe rechazar.

  ## Ejemplo

      Ciudad.desde_linea("C01@Armenia@304314")
      # {:ok, %Ciudad{id: "C01", nombre: "Armenia", habitantes: 304314}}
  """
  def desde_linea(linea) do
    linea
    |> String.split("@")
    |> Enum.map(&String.trim/1)
    |> validar_campos()
  end

  # Solo se aceptan líneas con exactamente tres campos válidos.
  defp validar_campos([id, nombre, habitantes]) do
    case {Validacion.texto_obligatorio(id), Validacion.texto_obligatorio(nombre),
          Validacion.entero_positivo(habitantes)} do
      {{:ok, id_valido}, {:ok, nombre_valido}, {:ok, habitantes_validos}} ->
        {:ok, crear(id_valido, nombre_valido, habitantes_validos)}

      _ ->
        {:error, "Campo vacío o dato inválido"}
    end
  end

  defp validar_campos(_campos),
    do: {:error, "La línea no tiene el formato idCiudad@nombre@numeroHabitantes"}
end
