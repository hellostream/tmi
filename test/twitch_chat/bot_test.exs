defmodule TwitchChat.BotTest do
  use ExUnit.Case, async: true

  doctest TwitchChat.Bot, import: true

  @chat_data_path Path.expand("../support/data/messages", __DIR__)
  @chat_message_files File.ls!(@chat_data_path)

  defmodule TestBot do
    use TwitchChat.Bot
  end

  describe "chat" do
    # Generate a bunch of tests for every batch of messages in the messages test
    # data files. This just makes sure we don't have any breaking changes in our
    # tag and event parsing.
    for file <- @chat_message_files do
      test "#{file}" do
        {messages, []} = Code.eval_file(unquote(file), @chat_data_path)

        for message <- messages do
          assert TwitchChat.Bot.apply_incoming_to_bot(message, TestBot)
        end
      end
    end
  end
end
