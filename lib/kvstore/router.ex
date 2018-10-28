# Для веб сервера нужен маршрутизатор, место ему именно тут.
defmodule KVstore.Router do
  use Plug.Router
  plug :match
  plug :dispatch

#  curl "http://localhost:8088/add?key=key01&value=value01&ttl=5000" -X POST
  post "/add" do
    %{"key" => key, "value" => value, "ttl" => ttl} = Plug.Conn.fetch_query_params(conn).params
    resp = KVstore.Storage.add(KVstore.Storage, key, value, String.to_integer(ttl))
           |> KVstore.Utils.map_entry_to_string()
    send_resp(conn, 200, "add entry: #{resp}")
  end

#  curl "http://localhost:8088/update?key=key01&value=value01&ttl=5000" -X POST
  post "/update" do
    %{"key" => key, "value" => value, "ttl" => ttl} = Plug.Conn.fetch_query_params(conn).params
    resp = KVstore.Storage.update(KVstore.Storage, key, value, String.to_integer(ttl))
           |> KVstore.Utils.map_entry_to_string()
    send_resp(conn, 200, "update entry: #{resp}")
  end

#  curl "http://localhost:8080/delete?key=key01"
  post "/delete" do
    key = Plug.Conn.fetch_query_params(conn).params["key"]
    resp = KVstore.Storage.delete(KVstore.Storage, key)
           |> KVstore.Utils.map_entry_to_string
    send_resp(conn, 200, "delete entry: #{resp}")
  end

#  curl http://localhost:8080/get?key=key01
  get "/get" do
    key = Plug.Conn.fetch_query_params(conn).params["key"]
    resp = KVstore.Storage.get(KVstore.Storage, key)
           |> KVstore.Utils.map_entry_value_to_string
    send_resp(conn, 200, "get entry for key #{key}: #{resp}")
  end

#  curl http://localhost:8080/list
  get "/list" do
    resp = KVstore.Storage.list(KVstore.Storage)
           |> KVstore.Utils.map_to_string
    send_resp(conn, 200, "all entries:\n#{resp}")
  end

  match _, do: send_resp(conn, 404, "Not found")

end