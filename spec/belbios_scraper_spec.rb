require 'spec_helper'
require 'belbios_scraper'

describe 'BelBios Scraper' do
  
  before(:each) do
    @scraper = BelbiosScraper.new
  end

  it 'should correctly convert runtime to minutes' do
    @scraper.runtime_in_minutes('1 uur 32 minuten').should eq(92)
    @scraper.runtime_in_minutes('30 minuten').should eq(30)
  end

end