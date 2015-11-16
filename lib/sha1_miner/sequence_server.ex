defmodule Sha1Miner.SequenceServer do
  
  use GenServer

  def start_link do
    GenServer.start_link( __MODULE__, { 0, 0 }, name: __MODULE__ )
  end

  def reset do
    GenServer.cast( __MODULE__, :reset )
  end

  def handle_call( :next, _from, { i, j } ) do
    { i0, j0 } = { i, j }
    { i, j } = case i do
      k when k < j and j - k == 1 -> { i + 1, 0 }
      k when k <  j               -> { i + 1, j }
      k when k == j               -> { 0, j + 1 }
      k when k >  j               -> { i, j + 1 }
    end
    { :reply, { i0, j0 }, { i, j } }
  end

  def handle_cast( :reset, _ ) do
    { :noreply, { 0, 0 } }
  end

  def next do
    GenServer.call( __MODULE__, :next )
  end

end

