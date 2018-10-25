# Этот модуль должен реализовать механизмы CRUD для хранения данных. Если одного модуля будет мало, то допускается создание модулей с префиксом "Storage" в названии.
defmodule KVstore.Storage do
  use GenServer

  # Client

  def start_link(args) when is_list(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def add(pid, key, value, ttl) do
    GenServer.cast(pid, {:add, key, value, ttl})
  end

  def update(pid, key, value, ttl) do
    GenServer.cast(pid, {:update, key, value, ttl})
  end

  def delete(pid, key) do
    GenServer.cast(pid, {:delete, key})
  end

  def get(pid, key) do
    GenServer.call(pid, {:get, key})
  end

   def list(pid) do
    GenServer.call(pid, :list)
  end

  # Server (callbacks)

  def init(_args) do
    {:ok, %{}}
  end

  # Adds a record only if ttl is integer
  def handle_cast({:add, key, value, ttl}, state) when is_integer(ttl) do
    {:noreply, Map.put_new(state, key, {value, ttl})}
  end

  def handle_cast({:add, _key, _value, _ttl}, state) do
    {:noreply, state}
  end

  # Updates a record only if it exists and ttl is integer
  def handle_cast({:update, key, value, ttl}, state) when is_integer(ttl) do
    state = if Map.has_key?(state, key) do
      Map.put(state, key, {value, ttl})
    else
      state
    end
    {:noreply, state}
  end

  def handle_cast({:update, _key, _value, _ttl}, state) do
    {:noreply, state}
  end

  # Deletes a record by key
  def handle_cast({:delete, key}, state) do
    {:noreply, Map.delete(state, key)}
  end

  # Retrieves record's value by key
  def handle_call({:get, key}, _from, state) do
    {:reply, Map.get(state, key), state}
  end

  # Retrieves all storage values
  def handle_call(:list, _from, state) do
    {:reply, state, state}
  end

end