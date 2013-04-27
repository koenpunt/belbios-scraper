#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'
require 'chronic'
require 'json'

def runtime_in_minutes runtime
  runtime.gsub!(/uur/, 'hours')
  runtime.gsub!(/minuten/, 'minutes')
  now = Time.now
  future = Chronic.parse("#{runtime} from now")
  ((future.to_time - now.to_time) / 60).to_i
end

class BelbiosScraper

  class << self
    def parse
      scraper = BelbiosScraper.new
      scraper.uri = File.join(File.expand_path(File.join(File.dirname(__FILE__), '..')), 'spec', 'fixtures', 'index.html')
      scraper.movie_detail_mapping = {
        "Releasedatum:" => 'release_date',
        "Duur:" => 'runtime',
        "Genre:" => 'genres',
        "Genres:" => 'genres',
        "Productiejaar:" => 'production_year',
        "Taal:" => 'language'
      }
      scraper.pages = 2
      scraper.movie_detail_proc = {
        :genres => Proc.new do |td|
          detail = []
          td.css('a').each do |child|
            detail << child.content.strip unless child.content =~ /^\s+/
          end
          detail
        end,
        :runtime => Proc.new {|td| runtime_in_minutes(td.content) },
        :release_date => Proc.new {|release_date| Date.parse(release_date.content)},
        :production_year => Proc.new {|production_year| production_year.content.to_i}
      }

      scraper.init
    end
  end

  def initialize
    @uri = 'http://www.belbios.nl/bioscoopfilms/zoeken/2/alle/%d/-/-/alle'
    @page = 1
    @pages = 10
    @movie_detail_mapping = {}
    @movie_detail_proc = {}
  end

  attr_accessor :uri, :page, :pages, :movie_detail_mapping, :movie_detail_proc

  def init
    movies = []
    @page.upto(@pages) do |page|
      doc = Nokogiri::HTML(open(@uri % [page]))
      raw_movies = doc.css('#bioscoopfilms-films .movie-wide')

      raw_movies.each do |data|
        a = data.at_css('h2 a')
        movie_uri = a.get_attribute('href')
        movie = {
          :title => a.content,
          :img => data.at_css('.movie-wide-poster img').get_attribute('src'),
          :description => data.at_css('.movie-wide-info > p').content,
          :url => movie_uri
        }
        movie.merge!(fetch_movie_details(movie_uri))
        movies << movie
      end
    end
    movies
  end

  def fetch_movie_details uri
    doc = Nokogiri::HTML(open(uri))
    info_doc = doc.css('#informatie .movie-detail-info')
    detail_rows = info_doc.css('.movie-detail-table tr')

    movie_details = {
      :full_description => info_doc.at_css('> p').content
    }

    detail_rows.each do |row|
      detail_sym = @movie_detail_mapping[row.at_css('th').content].to_sym
      movie_details[detail_sym] = process_detail(detail_sym, row)
    end
    movie_details
  end

  def process_detail symbol, row
    if @movie_detail_proc[symbol]
      @movie_detail_proc[symbol].call(row.at_css('td'))
    else
      row.at_css('td').content
    end
  end
end



puts BelbiosScraper.parse.to_json