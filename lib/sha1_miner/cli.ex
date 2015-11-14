defmodule Sha1Miner.CLI do

  def main( argv ) do
    argv
      |> parse_args
      |> process
  end

  def parse_args( argv ) do
    case OptionParser.parse(
      argv,
      switches: [ preffix: :string ],
      aliases:  [ :px, :preffix ]
    ) do
      { [ preffix: preffix ], _, _ } -> preffix
    end
  end

  def process( preffix ) do
    IO.puts "The preffix is: #{preffix}"
    { num_pref, _ } = Integer.parse( preffix, 0x10 )
  end

end
