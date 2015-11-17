defmodule Sha1Miner.Miner do

  def run( scheduler, commit_obj, preffix, author, committer ) do
    blob = "commit #{byte_size( commit_obj )}\x00#{commit_obj}"
    #TODO
    author_pos    = :binary.match( commit_obj, author_date )
    committer_pos = :binary.match( commit_obj, committer_date )
    cb = fn( cb ) ->
      send scheduler, { :ready, self }
      receive do
        { :next_round, client } ->
          { i, j } = Sha1Miner.SequenceServer.next
          send client, { :result, do_mine( blob, preffix, author, committer, i, j ) }
        { :terminate } ->
          exit( :normal )
      end
      cb.( cb )
    end
    cb.( cb )
  end

  defp _inspect(v) do
    IO.inspect v
    v
  end


  defp do_mine( blob, preffix, { author_date, author_tz, author_pos }, { committer_date, committer_tz, committer_pos }, i, j ) do
    { macro_sec, sec, _ } = :erlang.now
    cur_timestamp = macro_sec * 1_000_000 + sec
    a_delta = cur_timestamp - i
    c_delta = cur_timestamp - j
    case blob
          |> str_replace_at( Integer.to_string( a_delta ), author_pos )
          |> str_replace_at( Integer.to_string( c_delta ), committer_pos )
          |> :crypto.sha
          |> :binary.part( { 0, byte_size( preffix ) } ) do
      k when k == preffix ->
        IO.inspect { i, j }
        { :done, { { a_delta, author_tz }, { c_delta, committer_tz } }, self }
      default ->
        { :not_found, self }
    end
  end

  defp str_replace_at( str1, str2, { start, len }) do
    :binary.part( str1, 0, start ) <> str2 <> :binary.part( str1, start + len, byte_size( str1 ) - start - len )
  end


end

