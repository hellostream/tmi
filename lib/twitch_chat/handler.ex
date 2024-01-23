defmodule TwitchChat.Handler do
  @moduledoc """
  Handler behaviour for TwitchChat.
  """

  ## The common bits...

  @callback handle_event(event :: TwitchChat.event()) :: any

  @callback handle_mention(message :: String.t(), sender :: String.t(), channel :: String.t()) ::
              any

  ## IRC-related callbacks, you probably don't care about.

  @callback handle_connected(server :: String.t(), port :: integer) :: any
  @callback handle_disconnected() :: any
  @callback handle_join(channel :: String.t()) :: any
  @callback handle_join(channel :: String.t(), user :: String.t()) :: any
  @callback handle_logged_in() :: any
  @callback handle_login_failed(reason :: atom) :: any
  @callback handle_part(channel :: String.t()) :: any
  @callback handle_part(channel :: String.t(), user :: String.t()) :: any
  @callback handle_unrecognized(msg :: any) :: any
end
