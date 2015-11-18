defmodule Sha1Miner.IncServer do

  use GenServer

  def start_link do
    GenServer.start_link( __MODULE__, 0, name: __MODULE__ )
  end

  def reset do
    GenServer.cast( __MODULE__, :reset )
  end

  def handle_call( :next, _from, i ) do
    { :reply, i, i + 1 }
  end

  def handle_cast( :reset, _ ) do
    { :noreply, 0 }
  end

  def next do
    GenServer.call( __MODULE__, :next )
  end

end

