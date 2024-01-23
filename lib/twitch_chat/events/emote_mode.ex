defmodule TwitchChat.Events.EmoteMode do
  @moduledoc false
  use TwitchChat.Event,
    fields: [
      :channel,
      :emote_only?
    ]
end
