defmodule Archivos do
  @moduledoc """
  Lectura y escritura de los archivos de texto del observatorio.
  Separa el manejo de archivos del cálculo del reporte y de la coordinación de procesos.
  - Autores: Isabel Cristina Guerra Guzmán y Jhonatan Mosquera Correa
  - Fecha: Noviembre del 2026
  - Licencia: GNU GPL v3
  """

  @doc """
  Lee un archivo sin encabezado y convierte cada línea con la función recibida.
  Las líneas vacías se ignoran y las líneas inválidas se cuentan como rechazadas.
  ## Parámetros
    - ruta: ruta del archivo, por ejemplo "resources/ciudades.txt"
    - convertidor: función que recibe una línea y retorna {:ok, registro} o {:error, motivo}
  ## Retorna
    - {:ok, %{registros: lista_de_structs, rechazados: cantidad}}
    - {:error, razon} si el archivo no se puede leer
  """
  def leer_registros(ruta, convertidor) do
    case File.read(ruta) do
      {:ok, contenido} -> {:ok, procesar_contenido(contenido, convertidor)}
      {:error, razon} -> {:error, razon}
    end
  end

  # Divide el contenido en líneas, quita las vacías y separa los registros válidos de los rechazados.
  # También quita la marca BOM que algunos editores de Windows agregan al inicio del archivo.
  defp procesar_contenido(contenido, convertidor) do
    resultados =
      contenido
      |> String.replace("\uFEFF", "")
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.filter(fn linea -> linea != "" end)
      |> Enum.map(convertidor)

    {validos, rechazados} =
      Enum.split_with(resultados, fn resultado -> elem(resultado, 0) == :ok end)

    %{
      registros: Enum.map(validos, fn {:ok, registro} -> registro end),
      rechazados: length(rechazados)
    }
  end

  @doc """
  Guarda un texto en un archivo y reemplaza su contenido anterior.
  Retorna :ok o {:error, razon}.
  """
  def guardar_texto(ruta, texto) do
    File.write(ruta, texto)
  end

  @doc """
  Traduce el motivo de un error de archivo a un texto entendible.
  ## Ejemplo
      iex> Archivos.describir_error(:enoent)
      "el archivo o la carpeta no existe"
  """
  def describir_error(:enoent), do: "el archivo o la carpeta no existe"
  def describir_error(:eacces), do: "no hay permisos para acceder al archivo"
  def describir_error(:eisdir), do: "la ruta corresponde a una carpeta"
  def describir_error(razon), do: "#{inspect(razon)}"
end
