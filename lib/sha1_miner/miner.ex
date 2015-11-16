defmodule Sha1Miner.Miner do

  def run( scheduler, preffix, author_date, committer_date ) do
    IO.puts "ololo"
    send scheduler, { :ready, self }
    receive do
      { :calc, { i, j }, client } ->
        send client, { :result, do_mine( preffix, author_date, committer_date, i, j ), self }
      { :terminate } ->
        exit( :normal )
    end
  end

  defp do_mine( preffix, author_date, committer_date, i, j ) do
    IO.puts "I do mine"
    #XXX
    { :done, :blahblah }
  end

end

