defmodule Sha1Miner.Miner do

  def run( scheduler, blob, preffix, author, committer ) do
    send scheduler, { :ready, self }
    receive do
      { :calc, { i, j }, client } ->
        send client, { :result, do_mine( blob, preffix, author, committer, i, j ) }
      { :terminate } ->
        exit( :normal )
    end
    run( scheduler, blob, preffix, author, committer )
  end

  defp _inspect(v) do
    IO.inspect v
    v
  end


  defp do_mine( blob, preffix, { author_date, author_tz }, { committer_date, committer_tz }, i, j ) do
    { macro_sec, sec, _ } = :erlang.now
    cur_timestamp = macro_sec + 1_000_000 * sec
    a_delta = cur_timestamp - i
    c_delta = cur_timestamp - j
    case "#{blob}#{a_delta}#{c_delta}"
            |> :crypto.sha
            |> :binary.part( { 0, byte_size( preffix ) } ) do
      k when k == preffix ->
        { :done, { { a_delta, author_tz }, { c_delta, committer_tz } }, self }
      default ->
        { :not_found, self }
    end
  end

end

