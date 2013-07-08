require 'net/http'
require 'csv'

require 'open-uri'
require 'nokogiri'

require 'active_support/inflector'


BASE_URL = 'http://www.tbs-sct.gc.ca'


doc = Nokogiri::HTML(open(BASE_URL+'/reports-rapports/cc-se/data-eng.asp'))

crown_url = doc.at_xpath('//h4[contains(text(),"Crown corporations")]/following-sibling::ul//a[text()="CSV"]')['href']
fed_inst_url = doc.at_xpath('//h4[contains(text(),"Federal institutions")]/following-sibling::ul//a[text()="CSV"]')['href']
relevant_url = doc.at_xpath('//h4[contains(text(),"Relevant corporate")]/following-sibling::ul//a[text()="CSV"]')['href']

def add_record(record,csv)
  category = (record['Institutional Form']) ? record['Institutional Form'] : 'Crown Corporation'
  abbreviation = (!record['Abbreviation'] || record['Abbreviation']=="N/A") ? record['Legal Title'].parameterize : record['Abbreviation']
  address = record['Head Office Address Line 1']<<','<<record['Head Office Address Line 2']<<
    record['Head Office Address Line 3']<<','<<record['Head Office City']<<','<<record['Head Office Province']<<
    ','<<record['Head Office Postal Code']<< ',' << record['Head Office Country']
  address = address.squeeze(',').gsub(',',', ')

  return if category == 'International Organizations'

  csv << [
    record['Legal Title'],                                 #title
    abbreviation,                                          #abbr
    'ca/'<<abbreviation,                                   #key
    category,                                              #category
    record['Ministerial Portfolio'],                       #parent
    'ca/'<<record['Ministerial Portfolio'].parameterize,   #parent_key
    nil,                                                   #description
    record['Website'],                                     #url
    'Canada',                                              #jurisdiction
    'CA',                                                  #jurisdiction_code
    "Inventory of Government of Canada Organizations",     #source
    BASE_URL+'/reports-rapports/cc-se/data-eng.asp',       #source_url
    address,                                               #address
    nil,                                                   #contact
    record['Email'],                                       #email
    nil,                                                   #tags
    '6/18/13',                                             #created at
    Date.today.strftime('%-m/%-d/%y')                      #updated at
  ]
end

CSV.open(File.expand_path(".",Dir.pwd)+'/data/'+'ca_federal.csv','w') do |csv|
  csv << %w(title abbr key category parent parent_key description url jurisdiction jurisdiction_code source source_url address contact email tags created_at updated_at)
  ## insert crown corporations

  Net::HTTP.start(BASE_URL.gsub('http://','')) do |http|

    file = http.get(crown_url)
    p file
    CSV.parse(file.body, :headers => true) do |record|
      add_record(record.encode('utf-8'),csv)
    end

    file = http.get(fed_inst_url)
    CSV.parse(file.body, :headers => true) do |record|
      add_record(record,csv)
    end

    file = http.get(relevant_url)
    CSV.parse(file.body, :headers => true) do |record|
      add_record(record,csv)
    end
  end
end
  


