#!/usr/bin/env ruby

require 'nokogiri'
require 'uri'
require 'open-uri'
require 'open_uri_redirections'
require 'addressable/uri'
require 'etc'

uname = Etc.getlogin

REFERER = 'http://scholar.google.com'
PREFIX = 'https://www.academia.edu/download'
OPEN_URI_OPTIONS = {"Referer" => REFERER, :allow_redirections => :all}

download_dir = "/Users/#{uname}/Downloads"

ARGV.each do |academia_url|
  doc = nil
  tries = 0
  begin
    uri = Addressable::URI.parse(academia_url).normalize.to_s
    doc = Nokogiri::HTML(URI.open(uri))
  rescue OpenURI::HTTPError => e
    tries += 1
    if tries < 5
      sleep(5)
      retry
    else
      $stderr.puts 'URL problem:\n' + e.inspect
      exit
    end
  end
  begin
	download_url = doc.css('a.js-swp-download-button').first['href']
	download_id = download_url.split('/')[-2]
	filename = "#{URI(uri).path.split('/').last[0..250]}.pdf"
	url = "#{PREFIX}/#{download_id}/#{filename}"
  rescue
    $stderr.puts "Problem with the download. Here's what I was trying to get:\n<#{url}>"
    exit
  end
#   $stderr.puts "Resolved download URL: #{url}"
  if File.exist?("#{download_dir}/#{filename}")
    $stderr.puts "File already exists" #", skipping:\n#{filename}"
  else
    IO.copy_stream(open(url, OPEN_URI_OPTIONS), "#{download_dir}/#{filename}")
#     $stderr.puts "Downloaded #{filename}"
  end
end
