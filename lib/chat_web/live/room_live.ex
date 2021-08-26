defmodule ChatWeb.RoomLive do
  use ChatWeb, :live_view
  require Logger

  @impl true
  def mount(%{"id" => room_id}, _session, socket) do
    topic = "room:" <> room_id
    username = MnemonicSlugs.generate_slug(1)
    if connected?(socket) do
      ChatWeb.Endpoint.subscribe(topic)
      ChatWeb.Presence.track(self(), topic, username, %{})
    end

    {:ok,
     assign(socket,
       room_id: room_id,
       topic: topic,
       username: username,
       message: "",
       users_list: [],
       messages: [],
       temporary_assigns: [messages: []]
     )}
  end

  @impl true
  def handle_event("submit_message", %{"chat" => %{"message" => message}}, socket) do
    Logger.info(handle_event: message)
    Logger.info(message: message)
    message = %{uuid: UUID.uuid4(), content: message, username: socket.assigns.username}
    ChatWeb.Endpoint.broadcast(socket.assigns.topic, "new-message", message)
    {:noreply, assign(socket, message: "")}
  end

  @impl true
  def handle_event("form_update", %{"chat" => %{"message" => message}}, socket) do
    Logger.info(Form_Update: message)
    {:noreply, assign(socket, message: message)}
  end
  @impl true
  def handle_info(%{event: "new-message", payload: message, topic: topic}, socket) do
    Logger.info(message: message)
    Logger.info(topic: topic)
    {:noreply, assign(socket, messages: [message])}
  end

  @impl true
  def handle_info(%{event: "presence_diff", payload: %{joins: joins, leaves: leaves}}, socket) do
    join_messages =
      joins
      |> Map.keys()
      |> Enum.map(fn username -> %{type: :system, uuid: UUID.uuid4(), content: "#{username} joined"} end)

      leave_messages =
        leaves
        |> Map.keys()
        |> Enum.map(fn username -> %{type: :system, uuid: UUID.uuid4(), content: "#{username} left"} end)

      users_list = ChatWeb.Presence.list(socket.assigns.topic)
      |> Map.keys()

    {:noreply, assign(socket, messages: join_messages ++ leave_messages, users_list: users_list )}
  end

  def display_messages(%{type: :system, uuid: uuid, content: content}) do
    ~E"""
    <p id="<%=uuid%>"><i><%=content%></i></p>
    """
  end

  def display_messages(%{uuid: uuid, content: content, username: username}) do
    ~E"""
    <p id="<%=uuid%>"><strong><%=username%></strong>:<span><%=content%></span></p>
    """
  end
end