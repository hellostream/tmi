defmodule TwitchChat.Tags do
  @moduledoc """
  Parse Twitch IRC tag strings.
  """

  require Logger

  @tag_fields %{
    "badge-info" => :badge_info,
    "badges" => :badges,
    "ban-duration" => :ban_duration,
    "bits" => :bits,
    "client-nonce" => :client_nonce,
    "color" => :color,
    "custom-reward-id" => :reward_id,
    "display-name" => :display_name,
    "emotes" => :emotes,
    "emote-only" => :emote_only?,
    "emote-sets" => :emote_sets,
    "first-msg" => :first_message?,
    "flags" => :flags,
    "followers-only" => :followers_only?,
    "id" => :id,
    "login" => :login,
    "message-id" => :message_id,
    "mod" => :is_mod?,
    "msg-id" => :event,
    "msg-param-category" => :milestone,
    "msg-param-copoReward" => :channel_points,
    "msg-param-id" => :ignore,
    "msg-param-value" => :total,
    "msg-param-community-gift-id" => :community_gift_id,
    "msg-param-cumulative-months" => :cumulative_months,
    "msg-param-displayName" => :display_name,
    "msg-param-gift-months" => :gift_months,
    "msg-param-gift-theme" => :gift_theme,
    "msg-param-goal-contribution-type" => :goal_type,
    "msg-param-goal-current-contributions" => :goal_current,
    "msg-param-goal-description" => :goal_description,
    "msg-param-goal-target-contributions" => :goal_target,
    "msg-param-goal-user-contributions" => :goal_contributions,
    "msg-param-login" => :login,
    "msg-param-mass-gift-count" => :total,
    "msg-param-months" => :months,
    # Not sure about these next two.
    "msg-param-multimonth-duration" => :multimonth_duration,
    "msg-param-multimonth-tenure" => :multimonth_tenure,
    # I don't know what multimonth-tenure is. I have a message
    # that has cumulative-months=1 and multimonth-tenure=0.
    # "msg-param-multimonth-tenure" => :what?,
    "msg-param-origin-id" => :origin_id,
    "msg-param-profileImageURL" => :profile_image_url,
    "msg-param-prior-gifter-anonymous" => :prior_gifter_anon?,
    "msg-param-prior-gifter-display-name" => :prior_gifter_display_name,
    "msg-param-prior-gifter-id" => :prior_gifter_id,
    "msg-param-prior-gifter-user-name" => :prior_gifter_login,
    "msg-param-promo-gift-total" => :promo_gift_total,
    "msg-param-promo-name" => :promo_name,
    "msg-param-recipient-display-name" => :recipient_display_name,
    "msg-param-recipient-id" => :recipient_id,
    "msg-param-recipient-user-name" => :recipient_login,
    "msg-param-ritual-name" => :ritual_name,
    "msg-param-sender-count" => :cumulative_total,
    "msg-param-sender-login" => :sender_login,
    "msg-param-sender-name" => :sender_display_name,
    "msg-param-should-share-streak" => :share_streak?,
    "msg-param-streak-months" => :streak_months,
    "msg-param-sub-plan" => :plan,
    "msg-param-sub-plan-name" => :plan_name,
    "msg-param-threshold" => :bits_badge_tier,
    "msg-param-viewerCount" => :viewer_count,
    "msg-param-was-gifted" => :gifted?,
    "pinned-chat-paid-amount" => :amount,
    "pinned-chat-paid-currency" => :currency,
    "pinned-chat-paid-exponent" => :exponent,
    "pinned-chat-paid-is-system-message" => :system_message?,
    "pinned-chat-paid-level" => :level,
    "r9k" => :unique_only?,
    "reply-parent-display-name" => :parent_user_display_name,
    "reply-parent-msg-body" => :parent_message,
    "reply-parent-msg-id" => :parent_id,
    "reply-parent-user-id" => :parent_user_id,
    "reply-parent-user-login" => :parent_user_login,
    "reply-thread-parent-display-name" => :thread_parent_user_display_name,
    "reply-thread-parent-msg-id" => :thread_parent_id,
    "reply-thread-parent-user-id" => :thread_parent_user_id,
    "reply-thread-parent-user-login" => :thread_parent_user_login,
    "returning-chatter" => :returning_chatter?,
    "room-id" => :channel_id,
    "slow" => :slow_delay,
    "subs-only" => :subs_only?,
    "subscriber" => :is_sub?,
    "system-msg" => :system_message,
    "target-msg-id" => :target_message_id,
    "target-user-id" => :target_user_id,
    "thread-id" => :thread_id,
    "tmi-sent-ts" => :timestamp,
    "turbo" => :is_turbo?,
    "user-id" => :user_id,
    "user-type" => :user_type,
    "vip" => :is_vip?
  }

  @supported_tags Map.keys(@tag_fields)

  @events %{
    #   "" => :announcement,
    #   "" => :charity_donation,
    #   "" => :channel_update,
    #   "" => :cheer,
    #   "" => :ban,
    #   "" => :unban,
    #   "" => :moderator_add,
    #   "" => :moderator_remove,
    #   "" => :guest_star_session_begin,
    #   "" => :guest_star_session_end,
    #   "" => :guest_star_guest,
    #   "" => :guest_star_settings_update,
    #   "" => :clear,
    #   "" => :clear_user_messages,
    #   "" => :message_delete,
    #   "" => :message,
    #   "" => :cheermote,
    "emote_only_on" => :emote_only_on,
    "emote_only_off" => :emote_only_off,
    #   "" => :mention,
    #   "" => :setting_update,
    #   "" => :follow,
    #   "" => :ad_break,
    #   "" => :sub,
    #   "" => :sub_message,
    #   "" => :sub_end,
    "resub" => :resub,
    #   "" => :sub_gift,
    "submysterygift" => :community_sub_gift,
    "subgift" => :sub_gift,
    "sub" => :sub,
    "giftpaidupgrade" => :gift_paid_upgrade,
    "primepaidupgrade" => :prime_paid_upgrade,
    "raid" => :raid,
    "unraid" => :unraid,
    "communitypayforward" => :pay_it_forward,
    "highlighted-message" => :highlighted_message,
    #   "" => :messge,
    #   "" => :reward_add,
    #   "" => :reward_remove,
    #   "" => :reward_redemption,
    #   "" => :reward_redemption_update,
    #   "" => :poll_begin,
    #   "" => :poll_progress,
    #   "" => :poll_end,
    #   "" => :prediction_begin,
    #   "" => :prediction_progress,
    #   "" => :prediction_end,
    #   "" => :charity_campaign_donate,
    #   "" => :charity_campaign_progress,
    #   "" => :charity_campaign_start,
    #   "" => :charity_campaign_stop,
    #   "" => :drop_entitlement_grant,
    #   "" => :extension_bit_transaction,
    #   "" => :goal_begin,
    #   "" => :goal_progress,
    #   "" => :goal_end,
    #   "" => :hype_train_begin,
    #   "" => :hype_train_progress,
    #   "" => :hype_train_end,
    #   "" => :shield_mode_begin,
    #   "" => :shield_mode_end,
    #   "" => :shoutout_create,
    #   "" => :shoutout_receive,
    #   "" => :stream_online,
    #   "" => :stream_offline,
    #   "" => :user_auth_grant,
    #   "" => :user_auth_revoke,
    #   "" => :user_update,
    "viewermilestone" => :viewer_milestone,
    # WTF ಠ_ಠ; Got this once but never again...
    # Need to figure out how to reproduce.
    "msg_emoteonly" => :unrecognized
  }

  # The Twitch IRC tag name to a TwitchChat field name.
  defp tag_name(tag), do: Map.fetch!(@tag_fields, tag)

  # Get the event name from the IRC `msg-id` tag event identifier.
  defp event_name!(irc_event), do: Map.fetch!(@events, irc_event)

  @doc """
  Decode a tag value according to
  [IRCv3](https://ircv3.net/specs/extensions/message-tags.html) message tags.

  ## Examples

      iex> Tags.decode("hello\\schat")
      "hello chat"

  """
  def decode(nil), do: nil
  def decode(value), do: decode(value, <<>>)

  defp decode(<<"\\:", rest::binary>>, acc), do: decode(rest, [acc | ";"])
  defp decode(<<"\\s", rest::binary>>, acc), do: decode(rest, [acc | " "])
  defp decode(<<"\\\\", rest::binary>>, acc), do: decode(rest, [acc | "\\"])
  defp decode(<<c::binary-1, rest::binary>>, acc), do: decode(rest, [acc | c])
  defp decode(<<>>, acc), do: IO.iodata_to_binary(acc)

  @doc """
  Parses tags.

  ## Examples

      iex> tags = "@badge-info=subscriber/47;badges=broadcaster/1,subscriber/0,sub-gifter/1;color=#5DA5D9;display-name=ShyRyan"
      iex> Tags.parse!(tags)
      %{
        color: "#5DA5D9",
        badge_info: [{"subscriber", 47}],
        badges: [{"broadcaster", 1}, {"subscriber", 0}, {"sub-gifter", 1}],
        display_name: "ShyRyan"
      }

  """
  def parse!("@" <> tag_string) do
    tag_string
    |> :binary.split(";", [:global])
    |> Enum.map(fn tag ->
      case :binary.split(tag, "=") do
        [key, ""] -> tag_map({key, nil})
        [key, val] -> tag_map({key, val})
      end
    end)
    |> Map.new()
  end

  defp tag_map({"badge-info" = key, val}) when is_binary(val) do
    info =
      val
      |> String.split(",")
      |> Enum.map(fn item ->
        [badge, n] = String.split(item, "/")
        {badge, String.to_integer(n)}
      end)

    {tag_name(key), info}
  end

  defp tag_map({"badges" = key, val}) when is_binary(val) do
    info =
      val
      |> String.split(",")
      |> Enum.map(fn item ->
        [badge, n] = String.split(item, "/")
        {badge, String.to_integer(n)}
      end)

    {tag_name(key), info}
  end

  defp tag_map({"msg-param-sub-plan" = key, val}) do
    plan =
      case val do
        "1000" -> :t1
        "2000" -> :t2
        "3000" -> :t3
        "Prime" -> :prime
      end

    {tag_name(key), plan}
  end

  defp tag_map({"msg-param-gift-theme" = key, val}) do
    plan =
      case val do
        nil ->
          nil

        "love" ->
          :love

        "party" ->
          :party

        "lul" ->
          :lul

        "biblethump" ->
          :biblethump

        theme ->
          Logger.warning("""
          [TwitchChat.Tags] You found an unsupported gift theme: `#{inspect(theme)}`
          Please report it as an issue at: <https://github.com/ryanwinchester/tmi.ex>
          """)

          {:unknown, theme}
      end

    {tag_name(key), plan}
  end

  defp tag_map({"msg-param-category" = key, val}) do
    milestone =
      case val do
        "watch-streak" ->
          :watch_streak

        milestone ->
          Logger.warning("""
          [TwitchChat.Tags] You found an unsupported milestone: `#{inspect(milestone)}`
          Please report it as an issue at: <https://github.com/ryanwinchester/tmi.ex>
          """)

          {:unknown, milestone}
      end

    {tag_name(key), milestone}
  end

  defp tag_map({"emotes" = key, nil}), do: {tag_name(key), []}

  defp tag_map({"emotes" = key, val}) do
    emotes =
      val
      |> String.split("/")
      |> Enum.map(fn str ->
        [emote, ranges] = String.split(str, ":")

        ranges =
          String.split(ranges, ",")
          |> Enum.map(fn range ->
            [start, stop] = String.split(range, "-")
            String.to_integer(start)..String.to_integer(stop)
          end)

        {emote, ranges}
      end)

    {tag_name(key), emotes}
  end

  defp tag_map({"msg-id" = key, val}) do
    {tag_name(key), event_name!(val)}
  end

  defp tag_map({"flags" = key, val}) do
    {tag_name(key), val || []}
  end

  defp tag_map({"system-msg" = key, val}) do
    {tag_name(key), decode(val)}
  end

  defp tag_map({"msg-param-value" = key, val}) do
    {tag_name(key), String.to_integer(val)}
  end

  defp tag_map({"ban-duration" = key, val}) do
    {tag_name(key), String.to_integer(val)}
  end

  defp tag_map({"bits" = key, val}) do
    {tag_name(key), String.to_integer(val)}
  end

  defp tag_map({"msg-param-threshold" = key, val}) do
    {tag_name(key), String.to_integer(val)}
  end

  defp tag_map({"msg-param-mass-gift-count" = key, val}) do
    {tag_name(key), String.to_integer(val)}
  end

  defp tag_map({"msg-param-gift-months" = key, val}) do
    {tag_name(key), String.to_integer(val)}
  end

  defp tag_map({"msg-param-months" = key, val}) do
    {tag_name(key), String.to_integer(val)}
  end

  defp tag_map({"msg-param-sender-count" = key, val}) do
    {tag_name(key), String.to_integer(val)}
  end

  defp tag_map({"msg-param-viewerCount" = key, val}) do
    {tag_name(key), String.to_integer(val)}
  end

  defp tag_map({"msg-param-promo-gift-total" = key, val}) do
    {tag_name(key), String.to_integer(val)}
  end

  defp tag_map({"msg-param-streak-months" = key, val}) do
    {tag_name(key), String.to_integer(val)}
  end

  defp tag_map({"msg-param-cumulative-months" = key, val}) do
    {tag_name(key), String.to_integer(val)}
  end

  defp tag_map({"msg-param-multimonth-duration" = key, val}) do
    {tag_name(key), String.to_integer(val)}
  end

  defp tag_map({"msg-param-multimonth-tenure" = key, val}) do
    {tag_name(key), String.to_integer(val)}
  end

  defp tag_map({"slow" = key, val}) do
    {tag_name(key), String.to_integer(val)}
  end

  defp tag_map({"user-type" = key, val}) do
    type =
      case val do
        nil -> :normal
        "mod" -> :mod
        "admin" -> :admin
        "global_mod" -> :global_mod
        "staff" -> :staff
        type -> {:unknown, type}
      end

    {tag_name(key), type}
  end

  defp tag_map({"msg-param-goal-contribution-type" = key, val}) do
    type =
      case val do
        "SUBS" -> :subs
        "FOLLOWERS" -> :followers
      end

    {tag_name(key), type}
  end

  defp tag_map({"msg-param-goal-current-contributions" = key, val}) do
    {tag_name(key), String.to_integer(val)}
  end

  defp tag_map({"msg-param-goal-target-contributions" = key, val}) do
    {tag_name(key), String.to_integer(val)}
  end

  defp tag_map({"msg-param-goal-user-contributions" = key, val}) do
    {tag_name(key), String.to_integer(val)}
  end

  defp tag_map({"msg-param-should-share-streak" = key, val}) do
    {tag_name(key), val == "1"}
  end

  defp tag_map({"first-msg" = key, val}) do
    {tag_name(key), val == "1"}
  end

  defp tag_map({"returning-chatter" = key, val}) do
    {tag_name(key), val == "1"}
  end

  defp tag_map({"subscriber" = key, val}) do
    {tag_name(key), val == "1"}
  end

  defp tag_map({"mod" = key, val}) do
    {tag_name(key), val == "1"}
  end

  defp tag_map({"turbo" = key, val}) do
    {tag_name(key), val == "1"}
  end

  defp tag_map({"vip" = key, val}) do
    {tag_name(key), val == "1"}
  end

  defp tag_map({"emote-only" = key, val}) do
    {tag_name(key), val == "1"}
  end

  defp tag_map({"followers-only" = key, val}) do
    {tag_name(key), val == "1"}
  end

  defp tag_map({"subs-only" = key, val}) do
    {tag_name(key), val == "1"}
  end

  defp tag_map({"r9k" = key, val}) do
    {tag_name(key), val == "1"}
  end

  defp tag_map({"msg-param-prior-gifter-anonymous" = key, val}) do
    {tag_name(key), val == "true"}
  end

  defp tag_map({"msg-param-was-gifted" = key, val}) do
    {tag_name(key), val == "true"}
  end

  defp tag_map({"tmi-sent-ts" = key, val}) do
    timestamp = String.to_integer(val) |> DateTime.from_unix!(:millisecond)
    {tag_name(key), timestamp}
  end

  defp tag_map({"reply-parent-msg-body" = key, val}) do
    {tag_name(key), decode(val)}
  end

  defp tag_map({key, val}) when key in @supported_tags do
    {tag_name(key), decode(val)}
  end

  defp tag_map(tag) do
    # We want to log unsupported tags so we know which ones we need to
    # add support for in the future.
    Logger.warning("""
    [TwitchChat.Tags] You found an unsupported tag: `#{inspect(tag)}`
    Please report it as an issue at: <https://github.com/ryanwinchester/tmi.ex>
    """)

    tag
  end
end
