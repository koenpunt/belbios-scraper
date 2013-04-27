require "belbios_scraper/version"

require 'open-uri'
require 'nokogiri'
require 'chronic'

class BelbiosScraper
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
          :thumbnail => data.at_css('.movie-wide-poster img').get_attribute('src'),
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
    info_doc = doc.css('#informatie')
    detail_rows = info_doc.css('.movie-detail-info .movie-detail-table tr')

    movie_details = {
      :full_description => info_doc.at_css('.movie-detail-info > p').content,
      :image => info_doc.at_css('.movie-detail-poster .movie-poster a').get_attribute('href')
    }

    detail_rows.each do |row|
      detail_mapping = @movie_detail_mapping[row.at_css('th').content]

      if detail_mapping
        detail_sym = detail_mapping.to_sym
      else
        detail_sym = row.at_css('th').content.gsub(/:/, '').downcase.to_sym
      end

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