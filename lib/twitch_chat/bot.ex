defmodule TwitchChat.Bot do
  @moduledoc ~S"""
  The basis of your Twitch chat bot.

  Defines the behaviour and a way to implement it.

  ## Usage

  Create a module and `use TwitchChat.Bot`.
  Then you can implement the callbacks you care about.

  For example you can implement `handle_event/1` and pattern-match on only the
  events you care about. Any functions that don't match will just fallback to
  the default implementation (which does a debug log).

      defmodule MyBot do
        use TwitchChat.Bot

        alias TwitchChat.Events.Message

        @impl TwitchChat.Bot
        def handle_event(%Message{message: "!" <> cmd} = msg) do
          case cmd do
            "roll" -> say(msg.channel, "#{msg.user_name} rolled a #{Enum.random(1..6)}!")
            "echo " <> rest -> say(msg.channel, rest)
            _ -> nil
          end
        end
      end

  """

  require Logger

  import TwitchChat.Utils, only: [debug: 2]

  ## Handle event is what most bot implementations will care about.

  @callback handle_event(event :: TwitchChat.event()) :: any

  ## IRC-related callbacks, most won't care about.

  @callback handle_connected(server :: String.t(), port :: :inet.port_number()) :: any
  @callback handle_disconnected() :: any
  @callback handle_join(channel :: String.t()) :: any
  @callback handle_join(channel :: String.t(), user :: String.t()) :: any
  @callback handle_logged_in() :: any
  @callback handle_login_failed(reason :: atom()) :: any
  @callback handle_part(channel :: String.t()) :: any
  @callback handle_part(channel :: String.t(), user :: String.t()) :: any
  @callback handle_unrecognized(msg :: any) :: any

  @doc false
  defmacro __using__(_opts) do
    quote location: :keep do
      use GenServer

      import TwitchChat.Utils, only: [debug: 2]

      @behaviour TwitchChat.Bot

      @doc """
      Starts the bot.
      """
      @spec start_link(TwitchChat.Conn.t()) :: GenServer.on_start()
      def start_link(conn) do
        GenServer.start_link(__MODULE__, conn, name: __MODULE__)
      end

      @doc """
      Check if the bot is connected to the server.
      """
      @spec connected?() :: boolean()
      def connected? do
        GenServer.call(__MODULE__, :connected?)
      end

      @doc """
      Check if the bot is logged into the server.
      """
      @spec logged_in?() :: boolean()
      def logged_in? do
        GenServer.call(__MODULE__, :logged_in?)
      end

      @doc """
      Join a channel.
      """
      @spec join(String.t()) :: :ok
      def join(channel) do
        TwitchChat.ChannelServer.join(__MODULE__, channel)
      end

      @doc """
      Leave a channel.
      """
      @spec part(String.t()) :: :ok
      def part(channel) do
        TwitchChat.ChannelServer.part(__MODULE__, channel)
      end

      @doc """
      List all the channels we are in.
      """
      @spec list_channels() :: MapSet.t()
      def list_channels do
        TwitchChat.ChannelServer.list_channels(__MODULE__)
      end

      @doc """
      Perform an action in chat. Equivalent to typing `/me` in chat.
      """
      @spec me(String.t(), String.t()) :: :ok
      def me(channel, message) do
        GenServer.cast(__MODULE__, {:me, channel, message})
      end

      @doc """
      Send a message to a channel.
      """
      @spec say(String.t(), String.t()) :: :ok
      def say(channel, message) do
        TwitchChat.MessageServer.add_message(__MODULE__, channel, message)
      end

      @doc """
      Whisper a user.
      """
      @spec whisper(String.t(), String.t()) :: :ok
      def whisper(user, message) do
        GenServer.cast(__MODULE__, {:whisper, user, message})
      end

      ## -----------------------------------------------------------------------
      ## GenServer callbacks
      ## -----------------------------------------------------------------------

      @doc false
      @impl GenServer
      def init(conn) do
        TwitchChat.Client.add_handler(conn, self())
        {:ok, conn}
      end

      @doc false
      @impl GenServer
      def handle_call(:connected?, _from, conn) do
        {:reply, TwitchChat.Client.is_connected?(conn), conn}
      end

      def handle_call(:logged_in?, _from, conn) do
        case TwitchChat.Client.is_logged_on?(conn) do
          {:error, :not_connected} ->
            {:reply, false, conn}

          logged_in ->
            {:reply, logged_in, conn}
        end
      end

      @doc false
      @impl GenServer
      def handle_cast({:kick, channel, user, message}, conn) do
        TwitchChat.Client.kick(conn, channel, user, message)
        {:noreply, conn}
      end

      def handle_cast({:me, channel, message}, conn) do
        TwitchChat.Client.me(conn, channel, message)
        {:noreply, conn}
      end

      def handle_cast({:part, channel}, conn) do
        TwitchChat.Client.part(conn, channel)
        {:noreply, conn}
      end

      def handle_cast({:whisper, to, message}, conn) do
        TwitchChat.WhisperServer.add_whisper(__MODULE__, conn.user, to, message)
        {:noreply, conn}
      end

      @doc false
      @impl GenServer
      def handle_info(msg, conn) do
        TwitchChat.Bot.apply_incoming_to_bot(msg, __MODULE__)
        {:noreply, conn}
      end

      ## -----------------------------------------------------------------------
      ## Bot callbacks
      ## -----------------------------------------------------------------------

      @impl TwitchChat.Bot
      def handle_connected(server, port) do
        debug(__MODULE__, "Connected to #{server} on #{port}")
      end

      @impl TwitchChat.Bot
      def handle_disconnected() do
        debug(__MODULE__, "Disconnected")
      end

      @impl TwitchChat.Bot
      def handle_event(event) do
        TwitchChat.Bot.default_handle_event(event, __MODULE__)
      end

      # Add a fall-through `handle_event/1` to avoid match errors on events the
      # bot implementer doesn't care about.
      @before_compile {TwitchChat.Bot, :add_handle_event_fallback}

      @impl TwitchChat.Bot
      def handle_join(channel) do
        debug(__MODULE__, "[#{channel}] you joined")
      end

      @impl TwitchChat.Bot
      def handle_join(channel, user) do
        debug(__MODULE__, "[#{channel}] #{user} joined")
      end

      @impl TwitchChat.Bot
      def handle_logged_in() do
        debug(__MODULE__, "Logged in")
      end

      @impl TwitchChat.Bot
      def handle_login_failed(reason) do
        debug(__MODULE__, "Login failed: #{reason}")
      end

      @impl TwitchChat.Bot
      def handle_part(channel) do
        # If you get banned or timed out
        if MapSet.member?(list_channels(), channel), do: part(channel)
        debug(__MODULE__, "[#{channel}] you left")
      end

      @impl TwitchChat.Bot
      def handle_part(channel, user) do
        debug(__MODULE__, "[#{channel}] #{user} left")
      end

      @impl TwitchChat.Bot
      def handle_unrecognized(msg) do
        debug(__MODULE__, "UNRECOGNIZED: #{inspect(msg, pretty: true)}")
      end

      defoverridable(
        handle_connected: 2,
        handle_disconnected: 0,
        handle_event: 1,
        handle_join: 1,
        handle_join: 2,
        handle_logged_in: 0,
        handle_login_failed: 1,
        handle_part: 1,
        handle_part: 2,
        handle_unrecognized: 1
      )
    end
  end

  # This is the macro that is called to inject a `handle_event/1` callback that
  # gets inserted after the other ones during compile, so any non-matching
  # events can fall through without a match error getting raised.
  @doc false
  defmacro add_handle_event_fallback(_env) do
    quote do
      def handle_event(event) do
        TwitchChat.Bot.default_handle_event(event, __MODULE__)
      end
    end
  end

  # This is the default implementation of `handle_event/1` that generally just
  # does a debug log of the events in different formats, depending on the event.
  @doc false
  def default_handle_event(%TwitchChat.Events.Message{highlighted?: true} = event, module) do
    debug(module, [
      "[#{event.channel}] ",
      IO.ANSI.magenta_background(),
      IO.ANSI.black(),
      "<#{event.user_login}> #{event.message}",
      IO.ANSI.default_background()
    ])
  end

  def default_handle_event(%TwitchChat.Events.Message{} = event, module) do
    debug(module, "[#{event.channel}] <#{event.user_login}> #{event.message}")
  end

  def default_handle_event(%TwitchChat.Events.ChatAction{} = event, module) do
    debug(module, "[#{event.channel}] * <#{event.user_id}> #{event.message}")
  end

  def default_handle_event(%TwitchChat.Events.Whisper{} = event, module) do
    debug(module, "WHISPER - <#{event.user_login}> #{event.message}")
  end

  def default_handle_event(%TwitchChat.Events.Ban{ban_duration: :infinity} = event, module) do
    debug(module, "BANNED [#{event.channel}] - <#{event.user_login}>")
  end

  def default_handle_event(%TwitchChat.Events.Ban{} = event, module) do
    debug(module, "TIMEOUT [#{event.channel}] - <#{event.user_login}> for #{event.ban_duration}s")
  end

  def default_handle_event(%TwitchChat.Events.Unrecognized{msg: %ExIRC.Message{} = msg}, module) do
    debug(module, "[#{msg.cmd}] #{inspect(msg.args)}")
  end

  def default_handle_event(event, module) do
    debug(module, "EVENT\n#{inspect(event, pretty: true)}")
  end

  ## Apply the incoming IRC messages to the bot callbacks.

  @doc false
  def apply_incoming_to_bot({:unrecognized, _tag_string, %ExIRC.Message{}} = msg, bot) do
    parse_message(msg) |> bot.handle_event()
  end

  def apply_incoming_to_bot({:connected, server, port}, bot) do
    bot.handle_connected(server, port)
  end

  def apply_incoming_to_bot(:logged_in, bot) do
    bot.handle_logged_in()
  end

  def apply_incoming_to_bot({:login_failed, reason}, bot) do
    bot.handle_login_failed(reason)
  end

  def apply_incoming_to_bot(:disconnected, bot) do
    bot.handle_disconnected()
  end

  def apply_incoming_to_bot({:joined, channel}, bot) do
    bot.handle_join(channel)
  end

  def apply_incoming_to_bot({:joined, channel, user}, bot) do
    bot.handle_join(channel, user.user)
  end

  def apply_incoming_to_bot({:parted, channel}, bot) do
    bot.handle_part(channel)
  end

  def apply_incoming_to_bot({:parted, channel, user}, bot) do
    bot.handle_part(channel, user.user)
  end

  def apply_incoming_to_bot({:kicked, _user, _channel} = msg, _bot) do
    Logger.warning("We got a kick/2 event? #{inspect(msg)}")
  end

  def apply_incoming_to_bot({:kicked, _user, _kicker, _channel} = msg, _bot) do
    Logger.warning("We got a kick/3 event? #{inspect(msg)}")
  end

  def apply_incoming_to_bot({:received, message, sender}, bot) do
    bot.handle_whisper(message, sender.user)
  end

  def apply_incoming_to_bot({:received, message, sender, channel}, bot) do
    bot.handle_message(message, sender.user, channel)
  end

  def apply_incoming_to_bot({:mentioned, _message, _sender, _channel} = msg, _bot) do
    Logger.warning("We got a mentioned/3 event? #{inspect(msg)}")
  end

  def apply_incoming_to_bot({:me, message, sender, channel}, bot) do
    bot.handle_action(message, sender.user, channel)
  end

  def apply_incoming_to_bot(msg, bot) do
    bot.handle_unrecognized(msg)
  end

  ## Message Parsing

  @doc """
  Convert the ExIRC message to an event.

  NOTE: I may want to recursively parse the message args until I get one of the
  `PRIVMSG`, `USERNOTICE`, etc. messages.
  As it is now, if we get a message or system_msg or anything that has that
  text, we could get unexpected results since `String.contains?/2` could match.
  """
  @spec parse_message({atom(), String.t(), struct()}) :: TwitchChat.Events.event()
  def parse_message({:unrecognized, tag_string, %ExIRC.Message{args: [arg]} = msg}) do
    cond do
      String.contains?(arg, "PRIVMSG") ->
        case message_args_to_map(arg) do
          %{message: <<0x01, "ACTION ", message::binary>>} = params ->
            tag_string
            |> TwitchChat.Tags.parse!()
            |> TwitchChat.Events.from_map_with_name(:chat_action, %{
              params
              | message: String.trim_trailing(message, <<0x01>>)
            })

          params ->
            tag_string
            |> TwitchChat.Tags.parse!()
            |> TwitchChat.Events.from_map_with_name(:message, params)
        end

      String.contains?(arg, "USERNOTICE") ->
        tag_string
        |> TwitchChat.Tags.parse!()
        |> TwitchChat.Events.from_map(usernotice_args_to_map(arg))

      String.contains?(arg, "NOTICE") ->
        tag_string
        |> TwitchChat.Tags.parse!()
        |> TwitchChat.Events.from_map(notice_args_to_map(arg))

      String.contains?(arg, "ROOMSTATE") ->
        tag_string
        |> TwitchChat.Tags.parse!()
        |> TwitchChat.Events.from_map_with_name(:channel_update, roomstate_args_to_map(arg))

      String.contains?(arg, "WHISPER") ->
        tag_string
        |> TwitchChat.Tags.parse!()
        |> TwitchChat.Events.from_map_with_name(:whisper, whisper_args_to_map(arg))

      String.contains?(arg, "CLEARCHAT") ->
        tag_string
        |> TwitchChat.Tags.parse!()
        |> Map.update(:ban_duration, :infinity, & &1)
        |> TwitchChat.Events.from_map_with_name(:ban, clearchat_args_to_map(arg))

      true ->
        tag_string
        |> TwitchChat.Tags.parse!()
        |> TwitchChat.Events.from_map_with_name(:unrecognized, %{msg: msg})
    end
  end

  def parse_message({:unrecognized, _cmd, %ExIRC.Message{} = msg}) do
    TwitchChat.Events.from_map_with_name(%{}, :unrecognized, %{msg: msg})
  end

  @doc """
  Parse a PRIVMSG message.

  ## Example

      iex> message_args_to_map("shyryan!johndoe@johndoe.tmi.twitch.tv PRIVMSG #shyryan :Hello World")
      %{message: "Hello World", user_login: "shyryan", channel: "#shyryan"}

  """
  @spec message_args_to_map(String.t()) :: %{
          channel: String.t(),
          message: String.t(),
          user_login: String.t()
        }
  def message_args_to_map(message) do
    [full_sender, channel_message] = :binary.split(message, " PRIVMSG ")
    [channel, message] = :binary.split(channel_message, " :")
    [sender, _] = :binary.split(full_sender, "!")
    %{channel: channel, message: message, user_login: sender}
  end

  @doc """
  Parse a WHISPER message.

  ## Example:

      iex> whisper_args_to_map("johndoe!johndoe@johndoe.tmi.twitch.tv WHISPER janedoe :Hello World")
      %{message: "Hello World", user_login: "johndoe"}

  """
  @spec whisper_args_to_map(String.t()) :: %{message: String.t(), user_login: String.t()}
  def whisper_args_to_map(message) do
    [full_sender, recipient_message] = :binary.split(message, " WHISPER ")
    [_recipient, message] = :binary.split(recipient_message, " :")
    [sender, _] = :binary.split(full_sender, "!")
    %{message: message, user_login: sender}
  end

  @doc """
  Parse a USERNOTICE message.

  ## Example:

      iex> usernotice_args_to_map("tmi.twitch.tv USERNOTICE #ryanwinchester_")
      %{channel: "#ryanwinchester_"}

  """
  @spec usernotice_args_to_map(String.t()) :: %{channel: String.t()}
  def usernotice_args_to_map(message) do
    [_server, channel] = :binary.split(message, " USERNOTICE ")
    %{channel: channel}
  end

  @doc """
  Parse a NOTICE message.

  ## Example:

      iex> args = "tmi.twitch.tv NOTICE #ryanwinchester_ :This room is no longer in emote-only mode."
      iex> notice_args_to_map(args)
      %{channel: "#ryanwinchester_"}

  """
  @spec notice_args_to_map(String.t()) :: %{channel: String.t()}
  def notice_args_to_map(message) do
    [_server, notice] = :binary.split(message, " NOTICE ")
    [channel, _rest] = :binary.split(notice, " :")
    %{channel: channel}
  end

  @doc """
  Parse a ROOMSTATE message.

  ## Example:

      iex> roomstate_args_to_map("tmi.twitch.tv ROOMSTATE #ryanwinchester_")
      %{channel: "#ryanwinchester_"}

  """
  @spec roomstate_args_to_map(String.t()) :: %{channel: String.t()}
  def roomstate_args_to_map(message) do
    [_server, channel] = :binary.split(message, " ROOMSTATE ")
    %{channel: channel}
  end

  @doc """
  Parse a CLEARCHAT message.

  ## Example:

      iex> clearchat_args_to_map("tmi.twitch.tv CLEARCHAT #ryanwinchester_ :abesaibot")
      %{channel: "#ryanwinchester_", user_login: "abesaibot"}

  """
  @spec clearchat_args_to_map(String.t()) :: %{channel: String.t(), user_login: String.t()}
  def clearchat_args_to_map(message) do
    [_server, clearchat] = :binary.split(message, " CLEARCHAT ")
    [channel, user] = :binary.split(clearchat, " :")
    %{channel: channel, user_login: user}
  end
end
