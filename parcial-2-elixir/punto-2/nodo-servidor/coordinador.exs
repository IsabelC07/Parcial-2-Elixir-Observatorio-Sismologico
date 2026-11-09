Code.require_file("ciudad.exs", __DIR__)
Code.require_file("movimiento.exs", __DIR__)
Code.require_file("archivos.exs", __DIR__)

defmodule Coordinador do
  @moduledoc """
  Responsabilidad: coordinar la lectura concurrente de los dos archivos.
  El proceso que llama a `leer_archivos/2` actúa como coordinador: crea dos procesos
  trabajadores con `spawn`, cada uno le envía su resultado con `send`, y el coordinador
  los recibe con `receive` en cualquier orden.
  - Autores: Isabel Cristina Guerra Guzmán y Jhonatan Mosquera Correa
  - Fecha: Noviembre del 2026
  - Licencia: GNU GPL v3
  """

  # Tiempo máximo (en milisegundos) que se espera cada respuesta de un trabajador.
  @tiempo_espera 10_000

  @doc """
  Inicia los dos trabajadores (ciudades y movimientos) y luego espera sus respuestas.

  ## Retorna

    - `{:ok, lectura_ciudades, lectura_movimientos}` si ambos archivos se leyeron.
    - `{:error, errores}`, donde `errores` es una lista de `{ruta, razon}`
      con los archivos que no se pudieron leer.
  """
  def leer_archivos(ruta_ciudades, ruta_movimientos) do
    # Se guarda el PID del coordinador ANTES de crear los hijos:
    # dentro de un hijo, self() sería el PID del hijo.
    coordinador = self()

    # Referencia única para reconocer solo las respuestas de esta lectura.
    referencia = make_ref()

    iniciar_trabajador(coordinador, referencia, ruta_ciudades, &Ciudad.desde_linea/1)
    iniciar_trabajador(coordinador, referencia, ruta_movimientos, &Movimiento.desde_linea/1)

    recibir_resultados(2, referencia, %{})
    |> consolidar(ruta_ciudades, ruta_movimientos)
  end

  # Crea un proceso trabajador que lee un archivo y envía al coordinador un mensaje
  # que identifica el archivo procesado (ruta) y el resultado o el error de la lectura.
  defp iniciar_trabajador(coordinador, referencia, ruta, convertidor) do
    spawn(fn ->
      resultado = Archivos.leer_registros(ruta, convertidor)
      send(coordinador, {:archivo_procesado, referencia, ruta, resultado})
    end)
  end

  # Caso base: ya no hay respuestas pendientes.
  defp recibir_resultados(0, _referencia, resultados), do: resultados

  # Caso recursivo: recibe la respuesta de cualquier trabajador (sin importar el orden)
  # y la guarda en un mapa cuya llave es la ruta del archivo.
  defp recibir_resultados(pendientes, referencia, resultados) do
    receive do
      {:archivo_procesado, ^referencia, ruta, resultado} ->
        recibir_resultados(pendientes - 1, referencia, Map.put(resultados, ruta, resultado))
    after
      @tiempo_espera -> resultados
    end
  end

  # Solo hay éxito si ambos archivos se leyeron correctamente.
  # Si un trabajador no respondió, su archivo se reporta como :sin_respuesta.
  defp consolidar(resultados, ruta_ciudades, ruta_movimientos) do
    lectura_ciudades = Map.get(resultados, ruta_ciudades, {:error, :sin_respuesta})
    lectura_movimientos = Map.get(resultados, ruta_movimientos, {:error, :sin_respuesta})

    case {lectura_ciudades, lectura_movimientos} do
      {{:ok, ciudades}, {:ok, movimientos}} ->
        # Se agrega la ruta de cada archivo para mostrar los rechazados por archivo.
        {:ok, Map.put(ciudades, :archivo, ruta_ciudades),
         Map.put(movimientos, :archivo, ruta_movimientos)}

      _ ->
        {:error,
         obtener_errores([
           {ruta_ciudades, lectura_ciudades},
           {ruta_movimientos, lectura_movimientos}
         ])}
    end
  end

  # Deja solo las lecturas que fallaron, con la forma {ruta, razon}.
  defp obtener_errores(lecturas) do
    lecturas
    |> Enum.filter(fn {_ruta, {estado, _dato}} -> estado == :error end)
    |> Enum.map(fn {ruta, {:error, razon}} -> {ruta, razon} end)
  end
end
