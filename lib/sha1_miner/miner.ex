defmodule Sha1Miner.Miner do

  def run( scheduler, preffix, author_date, committer_date ) do
    send scheduler, { :ready, self }
    receive do
      { :calc, { i, j }, client } -> send client, { :result, do_mine( preffix, author_date, committer_date, i, j ), self }
      { :terminate } -> exit( :normal )
    end
  end

  defp do_mine( preffix, author_date, committer_date, i, j ) do
    #XXX
  end

end

