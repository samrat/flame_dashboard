defmodule FLAMEDashboard do
  @moduledoc """
  FLAME statistics visualization for the Phoenix LiveDashboard.
  """
  use Phoenix.LiveDashboard.PageBuilder

  defstruct pools: []

  @impl true
  def init(pools) do
    {:ok, %FLAMEDashboard{pools: pools}, []}
  end

  @impl true
  def menu_link(_session, _caps) do
    {:ok, "FLAME"}
  end

  @impl true
  def mount(_params, %{pools: pools}, socket) do
    Process.send_after(self(), :update_stats, 1_000)

    {:ok,
     assign(socket,
       pools: pools,
       pool_states: get_pool_states(pools),
       selected_pool: List.first(pools)
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @pools == [] do %>
      No FLAME pools configured. You need to manually list FLAME pools when adding this page to the LiveDashboard.
    <% else %>
      <.live_nav_bar id="pools_nav" page={@page}>
        <:item
          :for={{name, pool_state} <- Enum.zip(@pools, @pool_states)}
          name={name |> to_string()}
          label={"Pool #{name}"}
          method="redirect"
        >
          <.pool_stats name={name} pool={pool_state} />
        </:item>
      </.live_nav_bar>
    <% end %>
    """
  end

  @impl true
  def handle_info(:update_stats, socket) do
    Process.send_after(self(), :update_stats, 1_000)
    pool_states = get_pool_states(socket.assigns.pools)

    # Update graphs for each pool
    for {name, state} <- Enum.zip(socket.assigns.pools, pool_states) do
      # Update total runners graph
      send_data_to_chart(
        "pool-runners-#{name}",
        [{nil, state.runner_count, System.system_time(:microsecond)}]
      )

      # Update active calls graph for each runner
      for {pid, stats} <- state.runners do
        send_data_to_chart(
          "runner-calls-#{name}-#{inspect(pid)}",
          [{nil, stats.count, System.system_time(:microsecond)}]
        )
      end
    end

    {:noreply, assign(socket, pool_states: pool_states)}
  end

  defp pool_stats(assigns) do
    ~H"""
    <div class="mt-4">
      <.row>
        <:col>
          <.card inner_title="Backend">
            <%= @pool.backend %>
          </.card>
        </:col>
      </.row>

      <.row>
        <:col>
          <.card inner_title="Active Runners">
            <%= @pool.runner_count %>/<%= @pool.max %>
          </.card>
        </:col>
        <:col>
          <.card inner_title="Waiting Callers">
            <%= @pool.waiting_count %>
          </.card>
        </:col>
        <:col>
          <.card inner_title="Active Callers">
            <%= @pool.caller_count %>
          </.card>
        </:col>
      </.row>

      <div class="mt-4">
        <h5>Pool Runners Over Time</h5>
        <div class="row">
          <.live_chart
            id={"pool-runners-#{@name}"}
            title="Active Runners"
            kind={:last_value}
            prune_threshold={300}
            full_width={true}
          />
        </div>
      </div>

      <div :if={map_size(@pool.runners) > 0} class="mt-4">
        <h5>Runner Statistics</h5>
        <%= for {ref, stats} <- @pool.runners do %>
          <div class="row">
            <div class="mb-4">
              <.card inner_title={"Runner #{inspect(ref)}"}>
                <%= stats.count %>/<%= @pool.max_concurrency %> calls
                (<%= runner_status(stats) %>)
              </.card>
            </div>

            <.live_chart
              id={"runner-calls-#{@name}-#{inspect(ref)}"}
              title="Active Calls"
              kind={:last_value}
              prune_threshold={300}
              full_width={true}
            />
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def get_pool_states(pools) do
    for pool <- pools,
        pool_pid = Process.whereis(pool),
        pool_pid != nil,
        do: get_pool_info(pool_pid)
  end

  defp get_pool_info(pool_pid) do
    # Get pool state via sys.get_state - for monitoring only
    state = :sys.get_state(pool_pid)
    {backend, _} = Keyword.get(state.runner_opts, :backend)

    %{
      backend: backend,
      runner_count: map_size(state.runners),
      max: state.max,
      max_concurrency: state.max_concurrency,
      waiting_count: map_size(state.waiting.keys),
      caller_count: map_size(state.callers),
      runners: state.runners
    }
  end

  defp runner_status(%{count: count}) when count > 0, do: "Active"
  defp runner_status(_), do: "Idle"
end
