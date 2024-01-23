defmodule TwitchChat.Utils do
  @moduledoc false

  require Logger

  @doc """
  Debug log.
  """
  @spec debug(module(), String.t()) :: :ok
  def debug(module, message) do
    Logger.debug(["[#{module_string(module)}] " | message])
  end

  @doc """
  Takes a module and returns the string version without the `Elixir` prepended
  to the front. Makes it nicer to read in log messages.

  ## Example

      iex> TwitchChat.Utils.module_string(Foo.Bar.Bot)
      "Foo.Bar.Bot"

  """
  def module_string(module) do
    module
    |> to_string()
    |> String.split(".")
    |> List.delete_at(0)
    |> Enum.join(".")
  end
end
