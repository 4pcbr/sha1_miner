defmodule Sha1Miner.Commit do

  def parse_commit_dates( commit_obj ) do
    [ _, a_time_and_tz ] = Regex.run( ~r/author.+>\s(.+)/m,    commit_obj )
    [ _, { a_start, a_len } ] = Regex.run( ~r/author.+>\s(.+)/m,    commit_obj, return: :index )

    [ _, c_time_and_tz ] = Regex.run( ~r/committer.+>\s(.+)/m, commit_obj )
    [ _, { c_start, c_len } ] = Regex.run( ~r/committer.+>\s(.+)/m, commit_obj, return: :index )

    [ a_time, a_tz ] = String.split( a_time_and_tz, " " )
    [ c_time, c_tz ] = String.split( c_time_and_tz, " " )
    { a_time, _ } = Integer.parse( a_time )
    { c_time, _ } = Integer.parse( c_time )

    {
      { a_time, a_tz, a_start, a_len },
      { c_time, c_tz, c_start, c_len }
    }
  end

  def make_blob( commit_obj ) do
    "commit #{byte_size( commit_obj )}\x00#{commit_obj}"
  end

end

