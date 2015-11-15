defmodule Sha1Miner.CLI do

  def main( argv ) do
    argv
      |> parse_args
      |> process
  end

  def parse_args( argv ) do
    case OptionParser.parse(
      argv,
      switches: [ preffix: :string, nodes: :string ],
      aliases:  [ px: :preffix, n: :nodes ]
    ) do
      { [ preffix: preffix ], _, _ } -> preffix
    end
  end

  def process( preffix ) do
    IO.puts "The preffix is: #{preffix}"
    { num_pref, _ } = Integer.parse( preffix, 0x10 )
    cur_hash
  end

  defp cur_hash do
    case System.cmd( "git", [ "rev-parse", "HEAD" ] ) do
      { hash, 0 } -> String.strip( hash )
      { error, error_code } -> 
        IO.puts error
        exit error_code
    end
  end

end
