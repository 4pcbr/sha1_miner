defmodule Sha1Miner.CLI do

  @batch_size 200

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
      |> make_blob
      |> run_miners( preffix, nodes )
  end

  defp run_miners( blob, preffix, nodes ) do
    IO.puts "Running the miners"
    (1..nodes)
      |> Enum.map( fn( _ix ) ->
        spawn( Sha1Miner.Miner, :run, [ self, blob, preffix, { 0, 0 } ] )
      end )
      |> listen_to_miners( [], 0 )
  end

  defp listen_to_miners( miners, results, offset ) do
    receive do
      { :ready, pid } ->
        send( pid, { :next_round, offset, offset + @batch_size - 1, self } )
        listen_to_miners( miners, results, offset + @batch_size )
      { :result, { :not_found } } ->
        listen_to_miners( miners, results, offset + @batch_size )
      { :result, { :done, the_hash } } ->
        Enum.each( miners, &(Process.exit( &1, :kill )) )
        IO.puts "*** done ***"
        [ the_hash | results ]
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

  def make_blob( commit_obj ) do
    blob = "commit #{byte_size( commit_obj )}\x00#{commit_obj}"
  end

end

# Sha1Miner.CLI.main(["--nodes", "4", "--preffix", "aaaa"])

# git hash-object -t commit -w --stdin
