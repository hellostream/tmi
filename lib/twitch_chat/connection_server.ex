defmodule TwitchChat.ConnectionServer do
  @moduledoc """
  Handles connections to Twitch chat.
  """
  use GenServer

  require Logger

  alias TwitchChat.ChannelServer
  alias TwitchChat.Client
  alias TwitchChat.Conn

  @tmi_capabilities [~c"membership", ~c"tags", ~c"commands"]

  @hibernate_after_ms 20_000

  @doc """
  Start the connection handler.
  """
  @spec start_link({module(), Conn.t()}) :: GenServer.on_start()
  def start_link({bot, conn}) do
    GenServer.start_link(__MODULE__, {bot, conn},
      name: module_name(bot),
      hibernate_after: @hibernate_after_ms
    )
  end

  @doc """
  Get the bot-specific module name.
  """
  @spec module_name(module()) :: module()
  def module_name(bot) do
    Module.concat([bot, "ConnectionServer"])
  end

  # ----------------------------------------------------------------------------
  # GenServer callbacks
  # ----------------------------------------------------------------------------

  @doc false
  @impl GenServer
  def init({bot, conn}) do
    Client.add_handler(conn, self())
    {:ok, %{bot: bot, conn: conn}, {:continue, :connect}}
  end

  @doc false
  @impl GenServer
  def handle_continue(:connect, state) do
    connect(state.conn)
    {:noreply, state}
  end

  @doc false
  @impl GenServer
  def handle_info(:connect, state) do
    unless Client.is_connected?(state.conn.client) do
      connect(state.conn)
    end

    {:noreply, state}
  end

  def handle_info({:connected, _server, _port}, %{conn: conn} = state) do
    case Client.logon(conn) do
      :ok ->
        Logger.info("[TwitchChat.ConnectionServer] LOGGED IN as #{conn.user}")

      {:error, :not_connected} ->
        Logger.error("[TwitchChat.ConnectionServer] Cannot LOG IN, not connected")
    end

    {:noreply, state}
  end

  def handle_info(:logged_in, %{conn: conn} = state) do
    Logger.debug("[TwitchChat] Logged in to #{conn.server}:#{conn.port}")
    Enum.each(conn.caps, &request_capabilities(conn, &1))
    Enum.each(conn.channels, &join_channel(state.bot, &1))
    {:noreply, state}
  end

  def handle_info(:disconnected, %{conn: conn} = state) do
    Logger.info("[TwitchChat.ConnectionServer] Disconnected from #{conn.server}:#{conn.port}")
    {:stop, :normal, state}
  end

  def handle_info({:disconnected, "@" <> _cmd, _msg}, %{conn: conn} = state) do
    Logger.info("[TwitchChat.ConnectionServer] Disconnected from #{conn.server}:#{conn.port}")
    {:noreply, state}
  end

  def handle_info({:notice, msg, _sender}, state) do
    Logger.error("[TwitchChat.ConnectionServer] NOTICE: #{msg}")
    {:noreply, state}
  end

  # Catch-all for unhandled.
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # Quit the channels and close the underlying client connection when the
  # process is terminating.
  @doc false
  @impl GenServer
  def terminate(_, %{conn: conn}) do
    Logger.warning("[TwitchChat.ConnectionServer] Terminating...")
    Client.quit(conn, "[TwitchChat.ConnectionServer] Goodbye, cruel world.")
    Client.stop!(conn)
  end

  # ----------------------------------------------------------------------------
  # Internal API
  # ----------------------------------------------------------------------------

  defp connect(%Conn{} = conn) do
    case Client.connect_ssl(conn) do
      :ok ->
        Logger.info("[TwitchChat.ConnectionServer] Connected to #{conn.server}:#{conn.port}...")
        :ok

      {:error, reason} ->
        Logger.error("[TwitchChat.ConnectionServer] Unable to connect: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp request_capabilities(conn, cap) when cap in @tmi_capabilities do
    Logger.info("[TwitchChat.ConnectionServer] Requesting #{cap} capability...")
    Client.command(conn, [~c"CAP REQ :twitch.tv/", cap])
  end

  # If you know what you're doing, you can request other capabilities ¯\_(ツ)_/¯
  defp request_capabilities(conn, cap) do
    Logger.warning(
      "[TwitchChat.ConnectionServer] Requesting NON-TwitchChat capability: #{cap}..."
    )

    Client.command(conn, to_charlist(cap))
  end

  defp join_channel(bot, channel) do
    Logger.debug("[TwitchChat.ConnectionServer] Joining channel #{channel}...")
    ChannelServer.join(bot, channel)
  end
end
