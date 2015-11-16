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
      |> parse_commit_dates
      |> run_miners( num_pref, nodes )
  end

  defp run_miners( { author_date, committer_date }, preffix, nodes ) do
    IO.puts "the number of nodes: #{nodes}, #{author_date}, #{committer_date}"
    (1..nodes)
      |> Enum.map( fn( _ix ) ->
        IO.puts _ix
        spawn( Sha1Miner.Miner, :run, [ self, preffix, author_date, committer_date ] )
      end )
      |> listen_to_miners( [] )
  end

  defp listen_to_miners( miners, results ) do
    IO.puts "listening to the miners"
    receive do
      { :ready, pid } ->
        send( pid, { :calc, Sha1Miner.SequenceServer.next, self } )
        listen_to_miners( miners, results )
      { :result, { :not_found, _ }, pid } ->
        send( pid, { :calc, Sha1Miner.SequenceServer.next, self } )
        listen_to_miners( miners, results )
      { :result, { :done, the_hash }, pid } ->
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

  defp parse_commit_dates( commit_obj ) do
    author_date    = Regex.run( ~r/author.+>\s(.+)/m,    commit_obj ) |> Enum.at( 1 ) |> Integer.parse |> elem( 0 )
    committer_date = Regex.run( ~r/committer.+>\s(.+)/m, commit_obj ) |> Enum.at( 1 ) |> Integer.parse |> elem( 0 )
    { author_date, committer_date }
  end

end
