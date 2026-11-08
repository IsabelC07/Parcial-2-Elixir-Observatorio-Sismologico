defmodule Util do
  def mostrar_mensaje(mensaje) do
    IO.puts(mensaje)
    mensaje
  end

  def mostrar_error(mensaje) do
    IO.puts(:standard_error, mensaje)
    mensaje
  end

  def mostrar_mensaje_java(mensaje) do
    System.cmd("java", ["-cp", ".", "Mensaje", mensaje])
  end

  # Ingresar texto
  def ingresar(mensaje, :texto) do
    case IO.gets(mensaje) do
      texto when is_binary(texto) ->
        String.trim(texto)

      # IO.gets devuelve :eof o {:error, _} si se cierra la entrada
      _ ->
        mostrar_error("Entrada finalizada. Cerrando el programa.")
        System.halt(1)
    end
  end

  # Ingresar entero
  def ingresar(mensaje, :entero) do
    ingresar(mensaje, &String.to_integer/1, :entero)
  end

  # Ingresar real
  def ingresar(mensaje, :real) do
    ingresar(mensaje, &parsear_real/1, :real)
  end

  # Ingresar booleano / lógico
  def ingresar(mensaje, :booleano) do
    respuesta = mensaje |> ingresar(:texto) |> String.downcase()

    if respuesta == "true" or respuesta == "s" or respuesta == "si" or respuesta == "1" do
      true
    else
      if respuesta == "false" or respuesta == "n" or respuesta == "no" or respuesta == "0" do
        false
      else
        mostrar_error("Error, se esperaba un valor lógico (true/false o si/no)")
        ingresar(mensaje, :booleano)
      end
    end
  end

  def ingresar(mensaje, parser, tipo_dato) do
    try do
      mensaje
      |> ingresar(:texto)
      |> parser.()
    rescue
      ArgumentError ->
        "Error, se esperaba un número #{tipo_dato}"
        |> mostrar_error()

        ingresar(mensaje, parser, tipo_dato)
    end
  end

  # String.to_float("5") lanza error; Float.parse acepta "5", "5.5" y "4,5"
  defp parsear_real(texto) do
    case texto |> String.replace(",", ".") |> Float.parse() do
      {valor, ""} -> valor
      _ -> raise ArgumentError, "no es un número real"
    end
  end

  def formatter(valor) do
    # "* 1.0" evita el error cuando el valor es entero
    :erlang.float_to_binary(valor * 1.0, decimals: 2)
  end
end
