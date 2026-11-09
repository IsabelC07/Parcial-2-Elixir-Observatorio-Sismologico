defmodule Validacion do
  @moduledoc """
  Funciones para validar y convertir los campos que se leen de los archivos.
  Todas retornan `{:ok, valor}` cuando el dato es válido o `:error` cuando no lo es.
  - Autores: Isabel Cristina Guerra Guzmán y Jhonatan Mosquera Correa
  - Fecha: Noviembre del 2026
  - Licencia: GNU GPL v3
  """

  @digitos ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

  @doc """
  Valida que un campo obligatorio no esté vacío.

  ## Ejemplo

      Validacion.texto_obligatorio("C01")   # {:ok, "C01"}
      Validacion.texto_obligatorio("")      # :error
  """
  def texto_obligatorio(""), do: :error
  def texto_obligatorio(texto), do: {:ok, texto}

  @doc """
  Convierte un texto en un número entero mayor que cero (número de habitantes).

  ## Ejemplo

      Validacion.entero_positivo("304314")  # {:ok, 304314}
      Validacion.entero_positivo("-20")     # :error
  """
  def entero_positivo(texto) do
    if solo_digitos?(texto) do
      verificar_mayor_que_cero(String.to_integer(texto))
    else
      :error
    end
  end

  @doc """
  Convierte un texto en un número decimal (magnitud).
  Es válido si todo el texto se puede convertir en número, por ejemplo "3.4" o "3".

  ## Ejemplo

      Validacion.real("3.4")    # {:ok, 3.4}
      Validacion.real("abc")    # :error
  """
  def real(texto) do
    case Float.parse(texto) do
      {valor, ""} -> {:ok, valor}
      _ -> :error
    end
  end

  @doc """
  Convierte un texto en un número decimal mayor o igual a cero (profundidad).

  ## Ejemplo

      Validacion.real_no_negativo("18.0")   # {:ok, 18.0}
      Validacion.real_no_negativo("-3.0")   # :error
  """
  def real_no_negativo(texto) do
    case real(texto) do
      {:ok, valor} when valor >= 0 -> {:ok, valor}
      _ -> :error
    end
  end

  @doc """
  Valida que un texto sea una hora del día con formato HH:MM:SS
  (horas de 00 a 23, minutos y segundos de 00 a 59). Retorna la hora como texto.

  ## Ejemplo

      Validacion.hora("08:15:02")   # {:ok, "08:15:02"}
      Validacion.hora("25:10:00")   # :error
  """
  def hora(texto) do
    texto
    |> String.split(":")
    |> validar_partes_hora(texto)
  end

  @doc """
  Indica si un texto no vacío está formado únicamente por dígitos (0 a 9).
  """
  def solo_digitos?(""), do: false
  def solo_digitos?(texto), do: todos_son_digitos?(String.graphemes(texto))

  # Recorre recursivamente los caracteres.
  # Caso base: lista vacía (todos los caracteres revisados eran dígitos).
  defp todos_son_digitos?([]), do: true

  defp todos_son_digitos?([caracter | resto]) when caracter in @digitos,
    do: todos_son_digitos?(resto)

  defp todos_son_digitos?(_caracteres), do: false

  # Retorna el valor solo si es mayor que cero.
  defp verificar_mayor_que_cero(valor) when valor > 0, do: {:ok, valor}
  defp verificar_mayor_que_cero(_valor), do: :error

  # La hora debe tener exactamente tres partes separadas por ":".
  defp validar_partes_hora([horas, minutos, segundos], texto) do
    case {componente_hora(horas, 23), componente_hora(minutos, 59),
          componente_hora(segundos, 59)} do
      {:ok, :ok, :ok} -> {:ok, texto}
      _ -> :error
    end
  end

  defp validar_partes_hora(_partes, _texto), do: :error

  # Cada parte de la hora debe tener dos dígitos y no superar el máximo permitido.
  defp componente_hora(texto, maximo) do
    if String.length(texto) == 2 and solo_digitos?(texto) do
      verificar_rango(String.to_integer(texto), maximo)
    else
      :error
    end
  end

  defp verificar_rango(valor, maximo) when valor <= maximo, do: :ok
  defp verificar_rango(_valor, _maximo), do: :error
end
