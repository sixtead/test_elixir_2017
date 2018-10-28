# Это точка входа в приложение.
defmodule KVstore do

    use Application

    def start(_type, _args) do
      children = [
        Plug.Adapters.Cowboy.child_spec(
          :http, KVstore.Router, [], [port: Application.get_env(:kvstore, :port)]
        ),
        {KVstore.Storage, name: KVstore.Storage}
      ]

      opts = [strategy: :one_for_one]
      Supervisor.start_link(children, opts)
    end
    
end