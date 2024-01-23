defmodule TwitchChat.Events do
  @moduledoc false

  @events %{
    announcement: TwitchChat.Events.Announcement,
    charity_donation: TwitchChat.Events.CharityDonation,
    channel_update: TwitchChat.Events.ChannelUpdate,
    cheer: TwitchChat.Events.Cheer,
    ban: TwitchChat.Events.Ban,
    unban: TwitchChat.Events.Unban,
    moderator_add: TwitchChat.Events.ModeratorAdd,
    moderator_remove: TwitchChat.Events.ModeratorRemove,
    guest_star_session_begin: TwitchChat.Events.GuestStarSessionBegin,
    guest_star_session_end: TwitchChat.Events.GuestStarSessionEnd,
    guest_star_guest: TwitchChat.Events.GuestStarGuest,
    guest_star_settings_update: TwitchChat.Events.GuestStarSettingsUpdate,
    clear: TwitchChat.Events.Clear,
    clear_user_messages: TwitchChat.Events.ClearUserMessages,
    message_delete: TwitchChat.Events.MessageDelete,
    message: TwitchChat.Events.Message,
    chat_action: TwitchChat.Events.ChatAction,
    whisper: TwitchChat.Events.Whisper,
    cheermote: TwitchChat.Events.Cheermote,
    emote_mode: TwitchChat.Events.EmoteMode,
    mention: TwitchChat.Events.Mention,
    setting_update: TwitchChat.Events.SettingUpdate,
    ad_break: TwitchChat.Events.AdBreak,
    sub: TwitchChat.Events.Sub,
    sub_message: TwitchChat.Events.SubMessage,
    sub_end: TwitchChat.Events.SubEnd,
    resub: TwitchChat.Events.Resub,
    sub_gift: TwitchChat.Events.SubGift,
    community_sub_gift: TwitchChat.Events.CommunitySubGift,
    gift_paid_upgrade: TwitchChat.Events.GiftPaidUpgrade,
    prime_paid_upgrade: TwitchChat.Events.PrimePaidUpgrade,
    raid: TwitchChat.Events.Raid,
    unraid: TwitchChat.Events.Unraid,
    pay_it_forward: TwitchChat.Events.PayItForward,
    reward_add: TwitchChat.Events.RewardAdd,
    reward_remove: TwitchChat.Events.RewardRemove,
    reward_redemption: TwitchChat.Events.RewardRedemption,
    reward_redemption_update: TwitchChat.Events.RewardRedemptionUpdate,
    poll_begin: TwitchChat.Events.PollBegin,
    poll_progress: TwitchChat.Events.PollProgress,
    poll_end: TwitchChat.Events.PollEnd,
    prediction_begin: TwitchChat.Events.PredictionBegin,
    prediction_progress: TwitchChat.Events.PredictionProgress,
    prediction_end: TwitchChat.Events.PredictionEnd,
    charity_campaign_donate: TwitchChat.Events.CharityCampaignDonate,
    charity_campaign_progress: TwitchChat.Events.CharityCampaignProgress,
    charity_campaign_start: TwitchChat.Events.CharityCampaignStart,
    charity_campaign_stop: TwitchChat.Events.CharityCampaignStop,
    drop_entitlement_grant: TwitchChat.Events.DropEntitlementGrant,
    extension_bit_transaction: TwitchChat.Events.ExtensionBitTransaction,
    goal_begin: TwitchChat.Events.GoalBegin,
    goal_progress: TwitchChat.Events.GoalProgress,
    goal_end: TwitchChat.Events.GoalEnd,
    hype_train_begin: TwitchChat.Events.HypeTrainBegin,
    hype_train_progress: TwitchChat.Events.HypeTrainProgress,
    hype_train_end: TwitchChat.Events.HypeTrainEnd,
    shield_mode_begin: TwitchChat.Events.ShieldModeBegin,
    shield_mode_end: TwitchChat.Events.ShieldModeEnd,
    stream_online: TwitchChat.Events.StreamOnline,
    stream_offline: TwitchChat.Events.StreamOffline,
    user_auth_grant: TwitchChat.Events.UserAuthGrant,
    user_auth_revoke: TwitchChat.Events.UserAuthRevoke,
    user_update: TwitchChat.Events.UserUpdate,
    viewer_milestone: TwitchChat.Events.ViewerMilestone,
    unrecognized: TwitchChat.Events.Unrecognized
  }

  @event_names Map.keys(@events)

  # Generate the AST for all the module's struct types as a union
  # like `TwitchChat.Events.Cheer.t() | TwitchChat.Events.Cheermote` etc...
  event_types =
    Map.values(@events)
    |> Enum.sort()
    |> Enum.reduce(&{:|, [], [{{:., [], [&1, :t]}, [], []}, &2]})

  @typedoc """
  The event type union of event struct types.
  """
  @type event :: unquote(event_types)

  @typedoc """
  The params for an event as an atom-keyed map.
  """
  @type event_params :: %{required(atom()) => any()}

  @doc """
  Generate an event struct from the event params.
  """
  @spec from_map(event_params()) :: event()
  def from_map(params, extras \\ %{})

  # Matching on specific special-cases of events here.
  # Some events are _actually_ other events, with some extra fields.
  # For example, having events like `:highlighted_message` would be tedious to
  # match on all the different message variations instead of just having a
  # `Message` struct with a `:highlighted?` field.

  def from_map(%{event: :emote_only_off} = params, extras) do
    from_map_with_name(params, :emote_mode, Map.merge(extras, %{emote_only?: false}))
  end

  def from_map(%{event: :emote_only_on} = params, extras) do
    from_map_with_name(params, :emote_mode, Map.merge(extras, %{emote_only?: true}))
  end

  def from_map(%{event: :highlighted_message} = params, extras) do
    from_map_with_name(params, :message, Map.merge(extras, %{highlighted?: true}))
  end

  # Generate functions for all the general-cases of events.
  for {name, module} <- @events do
    def from_map(%{event: unquote(name)} = params, extras) do
      struct(unquote(module), Map.merge(params, extras))
    end
  end

  @doc """
  Generate an event struct from the event params, based on the passed in event
  name.
  """
  @spec from_map_with_name(event_params(), atom(), event_params()) :: event()
  def from_map_with_name(map, event_name, extras \\ %{}) when event_name in @event_names do
    @events
    |> Map.fetch!(event_name)
    |> struct(Map.merge(map, extras))
  end
end
