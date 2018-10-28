# Этот модуль должен реализовать механизмы CRUD для хранения данных. Если одного модуля будет мало, то допускается создание модулей с префиксом "Storage" в названии.
defmodule KVstore.Storage do
  use GenServer

  # Client

  def start_link(args) when is_list(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def add(pid, key, value, ttl) do
    GenServer.call(pid, {:add, key, value, ttl})
  end

  def update(pid, key, value, ttl) do
    GenServer.call(pid, {:update, key, value, ttl})
  end

  def delete(pid, key) do
    GenServer.call(pid, {:delete, key})
  end

  def get(pid, key) do
    GenServer.call(pid, {:get, key})
  end

  def list(pid) do
    GenServer.call(pid, :list)
  end

  # Server (callbacks)

  def init(_args) do
    ensure_file_for_storage(Application.get_env(:kvstore, :database_path))
    term = restore_from_file(Application.get_env(:kvstore, :database_path))
    schedule_ttl_decrease(Application.get_env(:kvstore, :timeout))
    {:ok, term}
  end

# Adds a record only if ttl is integer
  def handle_call({:add, key, value, ttl}, _from, state) when is_integer(ttl) do
  {reply, state} = if Map.has_key?(state, key) do
      {nil, state}
    else
      {{key, {value, ttl}}, Map.put(state, key, {value, ttl})}
    end
    {:reply, reply, state}
  end

# Updates a record only if it exists and ttl is integer
  def handle_call({:update, key, value, ttl}, _from, state) when is_integer(ttl) do
    {reply, state} = unless Map.has_key?(state, key) do
      {nil, state}
    else
      {{key, {value, ttl}}, Map.put(state, key, {value, ttl})}
    end
    {:reply, reply, state}
  end

# Deletes a record by key
  def handle_call({:delete, key}, _from, state) do
    {reply, state} = unless Map.has_key?(state, key) do
      {nil, state}
    else
      {{key, Map.get(state, key)}, Map.delete(state, key)}
    end
    {:reply, reply, state}
  end

# Retrieves record's value by key
  def handle_call({:get, key}, _from, state) do
    {:reply, Map.get(state, key), state}
  end

# Retrieves all storage values
  def handle_call(:list, _from, state) do
    {:reply, state, state}
  end

# Decreases ttl of all records
  def handle_info({:decrease_ttl, amount}, state) do
    state = Enum.map(state, fn {key, {value, ttl}} -> {key, {value, ttl - amount}} end)
            |> Stream.filter(fn {_key, {_value, ttl}} -> ttl > 0 end)
            |> Enum.into(%{})
    store_to_file(Application.get_env(:kvstore, :database_path), state)
    schedule_ttl_decrease(amount)
    {:noreply, state}
  end

# Sends message to self on timeout
  defp schedule_ttl_decrease(timeout) do
    Process.send_after(self(), {:decrease_ttl, timeout}, timeout)
  end

# Tries to read storage from file, otherwise return empty map
  defp restore_from_file(path) do
    with {:ok, binary} <- File.read(path),
         {:ok, term} <- restore_map_from_binary(binary)
    do
      term
    else
      {:error, reason} ->
        IO.puts("!W: Unable to restore database: #{reason}")
        %{}
    end
  end

# Tries to restore term from binary and checks if it is a map
# returns {:ok, term} or {:error, reason}
  defp restore_map_from_binary(binary) do
    try do
      term = :erlang.binary_to_term(binary)
      if is_map(term) do
        {:ok, term}
      else
        {:error, :notamap}
      end
    rescue
      ArgumentError -> {:error, :corrupted}
    end
  end

# Stores storage to file
  defp store_to_file(path, state) do
    File.write(path, :erlang.term_to_binary(state))
  end

# Ensures that file for database storage exists
  defp ensure_file_for_storage(path) do
    with false <- File.exists?(path),
         :ok <- Path.dirname(path) |> File.mkdir,
         :ok <- File.touch(path)
    do
      IO.puts("!I: File for database wasn't there, created succesfully")
    else
      true -> IO.puts("!I: File for database exists")
      {:error, reason} -> IO.puts("!W: Unable to create file for database storage: #{reason}")
    end
  end

end