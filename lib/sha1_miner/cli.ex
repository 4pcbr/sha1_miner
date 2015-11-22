defmodule Sha1Miner.CLI do

  @batch_size 200

  epoch = {{1970, 1, 1}, {0, 0, 0}}
  @epoch :calendar.datetime_to_gregorian_seconds(epoch)


  def main( argv ) do
    argv
      |> parse_args
      |> process
  end

  def parse_args( argv ) do

    IO.inspect OptionParser.parse(
      argv,
      switches: [ preffix: :string, nodes: :integer]
    )

    case OptionParser.parse(
      argv,
      switches: [ preffix: :string, nodes: :integer]
    ) do
      { [ nodes: nodes, preffix: preffix ], _, _ } -> [ preffix: preffix, nodes: nodes ]
    end
  end

  def process( [ preffix: preffix, nodes: nodes ] ) do
    { num_pref, _ } = Integer.parse( preffix, 0x10 )
    cur_hash
      |> cat_file
      |> Sha1Miner.Commit.make_blob
      |> run_miners( preffix, nodes )
      |> amend_with_new_time
  end

  defp run_miners( blob, preffix, nodes ) do
    IO.puts "Running the miners"
    (1..nodes)
      |> Enum.map( fn( _ix ) ->
        spawn( Sha1Miner.Miner, :run, [ self, blob, preffix, { 0, 0 } ] )
      end )
      |> listen_to_miners( 0 )
  end

  defp listen_to_miners( miners, offset ) do
    receive do
      { :ready, pid } ->
        send( pid, { :next_round, offset, offset + @batch_size - 1, self } )
        listen_to_miners( miners, offset + @batch_size )
      { :result, { :not_found } } ->
        listen_to_miners( miners, offset + @batch_size )
      { :result, { :done, result } } ->
        Enum.each( miners, &(Process.exit( &1, :kill )) )
        result
    end
  end

  defp cur_hash do
    case System.cmd( "git", [ "rev-parse", "HEAD" ] ) do
      { hash, 0 } -> String.strip( hash )
      { error, error_code } -> 
        IO.puts error
        exit error_code
    end
  end

  defp cat_file( hash ) do
    case System.cmd( "git", [ "cat-file", "-p", hash ] ) do
      { blob, 0 } -> blob
      { error, error_code } ->
        IO.puts error
        exit error_code
    end
  end


  defp amend_with_new_time({ blob, mod_a, mod_c }) do
    {{ a_time, a_tz, _, _ }, { c_time, c_tz, _, _ }} = Sha1Miner.Commit.parse_commit_dates( blob )

    IO.puts """
The new author date is: #{mod_a} (was #{a_time})"
        committer date: #{mod_c} (was #{c_time})
"""
    case IO.gets("Proceed?(y/n): ") |> String.strip do
      "y" ->
        a_date = "#{mod_a} #{a_tz}"
        c_date = "#{mod_c} #{c_tz}"
        IO.puts "Amending the commit"
        { res, ret_code } = System.cmd( "git", [ "commit", "--amend", "--date=#{a_date}", "-C", "HEAD" ],
            env: [ { "GIT_COMMITTER_DATE", c_date } ], stderr_to_stdout: true )
        IO.puts res
      "n"  ->
        IO.puts "No changes applied"
    end
    exit :shutdown
  end


  defp from_timestamp(timestamp) do
    timestamp
    |> +(@epoch)
    |> :calendar.gregorian_seconds_to_datetime
  end


  defp format_datetime( {{ y, m, d }, { h, i, s }} ) do
    :lists.flatten(
      :io_lib.format(
        "~4..0b-~2..0b-~2..0b ~2..0b:~2..0b:~2..0b",
        [ y, m, d, h, i, s ]
      )
    )
  end


end

# Sha1Miner.CLI.main(["--nodes", "4", "--preffix", "aaaa"])
