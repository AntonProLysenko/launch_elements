defmodule StripeCartWeb.StripeCartChannel do
  use LiveState.Channel, web_module: StripeCartWeb

  alias StripeCart.Carts
  alias StripeCart.Stores.Store
  alias StripeCart.Stores
  alias LiveState.Event

  def init("stripe_cart:new", %{"store_id" => store_id}, socket) do
    case Stores.get_store!(store_id) do
      %Store{id: store_id} -> {:ok, %{}, socket |> assign(:store_id, store_id)}
      nil -> {:error, "Store not found"}
    end
  end

  def init("stripe_cart:" <> cart_id, _payload, _socket) do
    {:ok, %{cart: Carts.get_cart!(cart_id)}}
  end

  def handle_event("add_cart_item", %{"stripe_price" => stripe_price}, %{cart: cart} = state, _socket) do
    case Carts.add_item(cart, stripe_price) do
      {:ok, cart} -> {:noreply, Map.put(state, :cart, cart)}
    end
  end

  def handle_event(
        "add_cart_item",
        %{"stripe_price" => stripe_price},
        state,
        %{assigns: %{store_id: store_id}} = socket
      ) do
    with {:ok, cart} <- Carts.create_cart(store_id),
         {:ok, cart} <- Carts.add_item(cart, stripe_price) do
      {:reply, %Event{name: "cart_created", detail: %{cart_id: cart.id}},
       Map.put(state, :cart, cart)}
    end
  end

  def handle_event("checkout", %{"return_url" => return_url}, %{cart: cart} = state) do
    case Carts.checkout(return_url, cart) |> IO.inspect() do
      {:ok, %Stripe.Session{url: checkout_url}} ->
        {:reply, %Event{name: "checkout_redirect", detail: %{checkout_url: checkout_url}},
         Map.put(state, :cart, nil)}
    end
  end
end