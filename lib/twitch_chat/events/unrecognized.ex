defmodule TwitchChat.Events.Unrecognized do
  @moduledoc false
  use TwitchChat.Event,
    fields: [
      :msg
    ]
end
