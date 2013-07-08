require 'csv'
require 'active_support/inflector'

require 'open-uri'
require 'nokogiri'


CSV.open(File.expand_path(".",Dir.pwd)+'/data/'+'nb.csv', 'w') do |csv|
  csv << %w(title abbr key category parent parent_key description url jurisdiction jurisdiction_code source source_url address contact email tags created_at updated_at)

  doc = Nokogiri::HTML(open("http://www1.gnb.ca/cnb/DsS/display-e.asp?typyofPublicBodyID=1"))

  doc.xpath('//table[4]//table').each do |td|
    title = td.at_xpath('.//u').text
    addr, contact = td.at_xpath('.//td/div').text.gsub(/\s{2,}/,' ').split('Co-ordinator:')
    contact.gsub!(/Email: .*/,'')
    email = td.at_xpath('.//a')

    csv << [
      title,                                   #title
      title.parameterize,                      #abbr
      'nb/' << title.parameterize,             #key
      nil,                                     #category
      nil,                                     #parent
      nil,                                     #parent_key
      nil,                                     #description
      nil,                                     #url
      'New Brunswick',                         #jurisdiction
      'ocd-division/country:ca/province:nb',   #jurisdiction_code
      "New Brunswick Directory of Public Bodies",     #source
      "http://www1.gnb.ca/cnb/DsS/display-e.asp?typyofPublicBodyID=1",  #source_url
      addr,                                    #address
      contact,                                 #contact
      email,                                   #email
      nil,                                     #tags
      '7/8/13',                                #created at
      Date.today.strftime('%-m/%-d/%y')        #updated at
    ]

  end


end

