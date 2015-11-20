defmodule Sha1Miner.Miner do

  @timestamp = :os.timestamp
                |> (fn({ macro, sec, _ }) ->
                  macro * 1_000_000 + sec
                end).()
                

  def run( scheduler, commit_obj, preffix ) do
    blob = "commit #{byte_size( commit_obj )}\x00#{commit_obj}"
    { author, committer } = parse_commit_dates( blob )

    loop = fn( loop ) ->
      send scheduler, { :ready, self }
      receive do
        { :next_round, from..to, client } ->
          send client, { :result, do_mine( blob, preffix, author, committer, from, to ) }
        { :terminate } ->
          exit( :normal )
      end
      loop.( loop )
    end
    cb.( cb )
  end


  defp _inspect(v1, v2) do
    IO.inspect v1
    IO.inspect v2
    v1
  end


  defp do_mine2( blob, preffix, timestamp,
                  { _, author_tz, a_start, a_len },
                  { _, committer_tz, c_start, c_len }, from, to) do
    #TODO
  end



  defp do_mine( blob, preffix, { _, author_tz, a_start, a_len }, { _, committer_tz, c_start, c_len }, i, j ) do
    a_delta = @timestamp - i
    c_delta = @timestamp - j
    blob = blob
          |> str_replace_at( Integer.to_string( a_delta ), { a_start, 10 } )
          |> str_replace_at( Integer.to_string( c_delta ), { c_start, 10 } )
    case blob
          |> sha1
          |> :binary.part( { 0, byte_size( preffix ) } ) do
      k when k == preffix ->
        IO.inspect { i, j }
        IO.puts blob
        { :done, { { a_delta, author_tz }, { c_delta, committer_tz } }, self }
      << a, a, a, _::binary>> ->
        IO.inspect <<a, a, a>>
        { :not_found, self }
      << a, a, a, a, _::binary>> ->
        IO.inspect <<a, a, a, a>>
        { :not_found, self }
      << a, a, a, a, a, _::binary>> ->
        IO.inspect <<a, a, a, a, a>>
        { :not_found, self }
      _ ->
        { :not_found, self }
    end
  end


  defp sha1( key ), do: :crypto.hash( :sha, key )


  defp str_replace_at( str1, str2, { start, len }) do
    :binary.part( str1, 0, start ) <> str2 <> :binary.part( str1, start + len, byte_size( str1 ) - start - len )
  end


  defp parse_commit_dates( commit_obj ) do
    [ author_date, author_tz ]       = Regex.run( ~r/author.+>\s(.+)/m,    commit_obj ) |> Enum.at( 1 ) |> String.split( " " )
    [ { _, _ }, { a_start, a_len } ] = Regex.run( ~r/author.+>\s(.+)/m,    commit_obj, return: :index )
    [ committer_date, committer_tz ] = Regex.run( ~r/committer.+>\s(.+)/m, commit_obj ) |> Enum.at( 1 ) |> String.split( " " )
    [ { _, _ }, { c_start, c_len } ] = Regex.run( ~r/committer.+>\s(.+)/m, commit_obj, return: :index )
    { author_date,    _ } = Integer.parse( author_date,    10 )
    { committer_date, _ } = Integer.parse( committer_date, 10 )
    { { author_date, author_tz, a_start, a_len }, { committer_date, committer_tz, c_start, c_len } }
  end


end

