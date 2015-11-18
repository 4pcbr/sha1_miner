defmodule Sha1Miner.CLI do

  def main( argv ) do
    init_self
    argv
      |> parse_args
      |> process
  end

  defp init_self do
    Sha1Miner.SequenceServer.start_link
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
    Sha1Miner.SequenceServer.reset
    cur_hash
      |> cat_file
      |> run_miners( preffix, nodes )
  end

  defp run_miners( commit_obj, preffix, nodes ) do
    IO.puts "Running the miners"
    (1..nodes)
      |> Enum.map( fn( _ix ) ->
        spawn( Sha1Miner.Miner, :run, [ self, commit_obj, preffix ] )
      end )
      |> listen_to_miners( [] )
  end

  defp listen_to_miners( miners, results ) do
    receive do
      { :ready, pid } ->
        send( pid, { :next_round, self } )
        listen_to_miners( miners, results )
      { :result, { :not_found, pid } } ->
        listen_to_miners( miners, results )
      { :result, { :done, the_hash, pid } } ->
        Enum.each( miners, &(send( &1, :terminate )) )
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

  

end

# Sha1Miner.CLI.main(["--nodes", "4", "--preffix", "aaa"])
