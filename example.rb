#!/usr/bin/env ruby

require 'belbios_scraper'
require 'json'

def runtime_in_minutes runtime
  runtime.gsub!(/uur/, 'hours')
  runtime.gsub!(/minuten/, 'minutes')
  now = Time.now
  future = Chronic.parse("#{runtime} from now")
  ((future.to_time - now.to_time) / 60).to_i
end

scraper = BelbiosScraper.new
scraper.movie_detail_mapping = {
  "Releasedatum:" => 'release_date',
  "Duur:" => 'runtime',
  "Genre:" => 'genres',
  "Genres:" => 'genres',
  "Productiejaar:" => 'production_year',
  "Taal:" => 'language'
}
scraper.pages = 1
scraper.movie_detail_proc = {
  :genres => Proc.new do |td|
    detail = []
    td.css('a').each do |child|
      detail << child.content.strip unless child.content =~ /^\s+/
    end
    detail
  end,
  :runtime => Proc.new {|runtime| runtime_in_minutes(runtime.content) },
  :release_date => Proc.new {|release_date| Date.parse(release_date.content)},
  :production_year => Proc.new {|production_year| production_year.content.to_i}
}

puts scraper.init.to_json