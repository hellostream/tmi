defmodule TwitchChat.Events.Ban do
  @moduledoc """
  Twitch chat ban.
  Ban duration is a timeout.
  If ban_duration is `nil` than it is a perma-ban.
  """
  use TwitchChat.Event,
    fields: [
      :ban_duration,
      :channel,
      :user_login
    ]
end
