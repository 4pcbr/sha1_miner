defmodule Sha1Miner.Miner do

  @timestamp :os.timestamp
                |> (fn({ macro, sec, _ }) ->
                  macro * 1_000_000 + sec
                end).()
                

  def run( scheduler, blob, preffix, { a_start, c_start }) do
    if ( a_start == 0 && c_start == 0 ) do
      { a_start, c_start } = parse_commit_dates( blob )
    end
    send scheduler, { :ready, self }
    receive do
      { :next_round, from, up_to, client } ->
        send client, { :result, do_mine2( blob, preffix, a_start, c_start, { 0, from }, up_to ) }
    end
    run( scheduler, blob, preffix, { a_start, c_start } )
  end


  defp do_mine2( blob, preffix, a_start, c_start, { i, j }, up_to) do
    if j > up_to do
      { :not_found }
    else
      mod_a = @timestamp - i
      mod_c = @timestamp - j
      new_blob = blob
              |> str_replace_at( Integer.to_string( mod_a ), { a_start, 10 } )
              |> str_replace_at( Integer.to_string( mod_c ), { c_start, 10 } )
      cur_preffix = new_blob |> sha1 |> :binary.part({ 0, byte_size( preffix ) })
      if ( cur_preffix == preffix ) do
        IO.inspect { i, j }
        IO.puts new_blob
        { :done, { { mod_a }, { mod_c } } }
      else
        do_mine2( blob, preffix, a_start, c_start, _next_i_j({ i, j }), up_to )
      end
    end
  end


  defp _next_i_j({ i, j }) when i < j and i - j == 1, do: { i + 1, 0 }
  defp _next_i_j({ i, j }) when i < j,                do: { i + 1, j }
  defp _next_i_j({ i, j }) when i == j,               do: { 0, j + 1 }
  defp _next_i_j({ i, j }) when i > j,                do: { i, j + 1 }


  defp sha1( key ), do: :crypto.hash( :sha, key )


  defp str_replace_at( str1, str2, { start, len }) do
    :binary.part( str1, 0, start ) <> str2 <> :binary.part( str1, start + len, byte_size( str1 ) - start - len )
  end


  defp parse_commit_dates( commit_obj ) do
    [ _, { a_start, _ } ] = Regex.run( ~r/author.+>\s(.+)/m,    commit_obj, return: :index )
    [ _, { c_start, _ } ] = Regex.run( ~r/committer.+>\s(.+)/m, commit_obj, return: :index )
    { a_start, c_start }
  end


end

