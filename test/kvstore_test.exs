#Тестируем как можно больше кейсов.
defmodule KVstoreTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, storage} = KVstore.Storage.start_link([])
    %{storage: storage}
  end

#  Tests of basic storage operations like put, delete, get, update

  test "can add and retrieve records", %{storage: storage} do
    assert KVstore.Storage.get(storage, "key") == nil

    KVstore.Storage.add(storage, "key", "value", 1000)
    assert KVstore.Storage.get(storage, "key") == {"value", 1000}
  end

  test "can add record with integer ttl only", %{storage: storage} do
    KVstore.Storage.add(storage, "key", "value", "1000")
    assert KVstore.Storage.get(storage, "key") == nil

    KVstore.Storage.add(storage, "key", "value", 1000)
    assert KVstore.Storage.get(storage, "key") == {"value", 1000}
  end

  test "can update existing records", %{storage: storage} do
    KVstore.Storage.add(storage, "key", "value", 1000)

    KVstore.Storage.update(storage, "key", "newvalue", 1000)
    assert KVstore.Storage.get(storage, "key") == {"newvalue", 1000}

    KVstore.Storage.update(storage, "key", "oldvalue", 1500)
    assert KVstore.Storage.get(storage, "key") == {"oldvalue", 1500}
  end

  test "cannot update non existing records", %{storage: storage} do
    KVstore.Storage.update(storage, "key", "newvalue", 1000)
    assert KVstore.Storage.get(storage, "key") == nil
  end

  test "cannot update record with non integer ttl", %{storage: storage} do
    KVstore.Storage.add(storage, "key", "value", 1000)

    KVstore.Storage.update(storage, "key", "newvalue", "1500")
    assert KVstore.Storage.get(storage, "key") != {"newvalue", "1500"}
    assert KVstore.Storage.get(storage, "key") == {"value", 1000}
  end

  test "can retrieve entire storage", %{storage: storage} do
    assert KVstore.Storage.list(storage) == %{}

    KVstore.Storage.add(storage, "key01", "value01", 1000)
    KVstore.Storage.add(storage, "key02", "value02", 2000)
    assert KVstore.Storage.list(storage) == %{"key01" => {"value01", 1000}, "key02" => {"value02", 2000}}
  end

#  Test TTL

  test "record gets deleted after ttl is passed", %{storage: storage} do
    KVstore.Storage.add(storage, "key", "value", 1000)

    assert KVstore.Storage.get(storage, "key") != nil
    :timer.sleep(1000)
    assert KVstore.Storage.get(storage, "key") == nil
  end

  test "when ttl ticks actual value of record is not changed", %{storage: storage} do
    KVstore.Storage.add(storage, "key", "value", 2000)

    :timer.sleep(1000)
    assert {"value", _ttl} = KVstore.Storage.get(storage, "key")
  end

  test "record gets deleted not earlier than ttl gets to zero", %{storage: storage} do
    KVstore.Storage.add(storage, "key", "value", 2000)

    :timer.sleep(1000)
    assert KVstore.Storage.get(storage, "key") != nil

    :timer.sleep(1000)
    assert KVstore.Storage.get(storage, "key") == nil
  end

  test "deleting a record does not cause any problems", %{storage: storage} do
    KVstore.Storage.add(storage, "key", "value", 2000)
    KVstore.Storage.delete(storage, "key")

    assert KVstore.Storage.get(storage, "key") == nil

    :timer.sleep(2000)
  end


#  Test storage persistency

  test "can write storage state to file and read it back", %{storage: storage} do

  end

end