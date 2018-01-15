defmodule CaishenMQ.MQConsumer do
  @moduledoc """
  GenServer module listening handling communication with RabbitMQ.
  """
  alias CaishenMQ.{Operator, ErrorHandler}

  def handle(payload, correlation_id) do
    Operator.operate(payload, correlation_id)
  rescue
    exception ->
      ErrorHandler.internal_server_error(exception)
  end
end
