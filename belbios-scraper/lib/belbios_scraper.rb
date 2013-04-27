#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'
require 'chronic'

#<div class="movie-wide">
#	<div class="movie-wide-poster">
#		<a href="http://www.belbios.nl/bioscoopfilms/index/kid">
#							<img class="borderradius1" src="http://www.belbios.nl/media/posters/102670_thumbnail.jpg" width="120" height="165" alt="Kid">
#					</a>
#	</div>
#	<div class="movie-wide-info">
#		<h2><a href="http://www.belbios.nl/bioscoopfilms/index/kid">Kid</a></h2>
#		<div class="right movie-wide-kijkwijzer">
#			<a href="http://www.belbios.nl/kijkwijzers">
#															<img src="http://www.belbios.nl/resources/img/kijkwijzer/small/geweld.png" width="19" height="19" title="Bevat geweld" alt="Bevat geweld">
#																				<img src="http://www.belbios.nl/resources/img/kijkwijzer/small/leeftijd_12.png" width="19" height="19" title="12 jaar en ouder" alt="12 jaar en ouder">
#												</a>
#		</div>
#								<div class="clear movie-wide-vote" id="vote_5939417">
#							<img src="http://www.belbios.nl/resources/img/buttons/vote.png" width="16" height="16" alt=""><img src="http://www.belbios.nl/resources/img/buttons/vote.png" width="16" height="16" alt=""><img src="http://www.belbios.nl/resources/img/buttons/vote.png" width="16" height="16" alt=""><img src="http://www.belbios.nl/resources/img/buttons/vote.png" width="16" height="16" alt=""><img src="http://www.belbios.nl/resources/img/buttons/vote.png" width="16" height="16" alt="">				<p class="vote-value" id="test"></p>
#			</div>
#				<p>Kid brengt het verhaal van de vrolijke Kid, zijn broer Billy en hun moeder die samen op een boerderij wonen. Met weinig middelen probeert Mama er een warm liefdevol nest van te maken. Het noodlot…</p>
#		<div class="movie-info-links">
#			<a href="http://www.belbios.nl/bioscoopfilms/index/kid">Meer info</a>
#						<a class="open-trailer" id="kid" href="http://www.belbios.nl/bioscoopfilms/index/kid#trailer">Bekijk trailer</a>
#						<a href="http://www.belbios.nl/bioscoopfilms/index/kid#reacties">Reacties</a>
#			<a class="right res-nu" style="color: #444 !important;" id="movie_8081" href="http://www.belbios.nl/bioscoopfilms/index/kid">Koop / Reserveer</a>
#		</div>
#	</div>
#</div>


class BelbiosScraper
  
  class << self
    def parse(uri)
      scraper = BelbiosScraper.new(uri)
      scraper.parse
    end
  end
  
  def initialize uri
    @uri = uri

    @movie_detail_mapping = {
      "Releasedatum:" => 'release_date',
      "Duur:" => 'runtime',
      "Genre:" => 'genres',
      "Genres:" => 'genres',
      "Productiejaar:" => 'production_year',
      "Taal:" => 'language'
    }

    @movie_detail_proc = {
      :genres => Proc.new do |td|
        detail = []
        td.css('a').each do |child|
          detail << child.content.strip unless child.content =~ /^\s+/
        end
        detail
      end,
      :runtime => Proc.new {|runtime| runtime_in_minutes(runtime.at_css('td').content) }
    }
  
  end
  
  def parse
    doc = Nokogiri::HTML(open(@uri))
    raw_movies = doc.css('#bioscoopfilms-films .movie-wide')

    movies = []

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
    movies
  end

  def fetch_movie_details uri
    puts uri
    doc = Nokogiri::HTML(open(uri))
    info_doc = doc.css('#informatie .movie-detail-info')

    movie_info = {
      :description => info_doc.at_css('> p').content
    }

    detail_rows = info_doc.css('.movie-detail-table tr')

    movie_details = {}

    detail_rows.each do |row|
      puts row.at_css('th').content
      detail_sym = @movie_detail_mapping[row.at_css('th').content].to_sym
      movie_details[detail_sym] = process_detail(detail_sym, row)
    end

    movie_details
  end

  def process_detail symbol, row
    if @movie_detail_proc[symbol]
      @movie_detail_proc[symbol].call(row.css('td'))
    else
      row.at_css('td').content
    end
  end

  def runtime_in_minutes runtime
    # Normalize
    begin
      runtime.gsub!(/uur/, 'hours').gsub!(/minuten/, 'minutes')
      now = Time.now
      future = Chronic.parse("#{runtime} from now")
      ((future.to_time - now.to_time) / 60).to_i
    rescue
      runtime
    end
  end
end


current_movies = 'http://www.belbios.nl/bioscoopfilms/zoeken/2/alle/%d/-/-/alle'

uri = current_movies % [1]



