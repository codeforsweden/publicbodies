require 'csv'
require 'active_support/inflector'

require 'open-uri'
require 'nokogiri'
require 'rest_client'

BASE_URL = 'http://www.servicealberta.ca/foip/directory-of-public-bodies.cfm'

page = RestClient.get(BASE_URL, 'fuseaction'=>'SearchResults')
page = RestClient.post(BASE_URL, 'fuseaction=SearchResults&first_name=&last_name=&pb_name=&pbtype=&city=')
doc = Nokogiri::HTML(page)

num_records = doc.at_xpath('//b').text.match(/(?<=of )([0-9]{4})/)[0].to_i


CSV.open(File.expand_path(".",Dir.pwd)+'/data/'+'ab.csv','w') do |csv|
  csv << %w(title abbr key category parent parent_key description url jurisdiction jurisdiction_code source source_url address contact email tags created_at updated_at)

  (1..num_records).step(10) do |n|
    page = RestClient.post(BASE_URL, "CITY=&FIRST_NAME=&FUSEACTION=SearchResults&LAST_NAME=&PAGESTARTROW=#{n}&PB_NAME=&PBTYPE=")
    doc = Nokogiri::HTML(page)
    doc.xpath('//div[@id="content"]//table[1]//tr')[2...-2].each do |row|
      cells = row.xpath('.//td')

      contact = cells[0].text
      title = cells[1].text.gsub(/^[[:space:]]|[[:space:]]$/, '')
      category = cells[3].text

      contact_url = row.at_xpath('.//a')['href']
      

      doc = Nokogiri::HTML(open("http://www.servicealberta.ca/foip/"+contact_url))
      
      address = doc.xpath('//form/table//table//tr[2]/td')[0].text
      address.gsub!(/\s{2,}/,' ').strip!
      

      boundary = title.gsub(/\(/,'\(').gsub(/\)/,'\)').gsub(/ {2,}/,' ')
      address = address.match(/(?<=#{boundary})(.*)/)[0].to_s.strip
      address.gsub!(/Phone.*/,'')

      email = doc.at_xpath('//a[contains(@href, "mailto:")]')

      email = email.text if email
      

      csv << [
        title,                                   #title
        title.parameterize,                      #abbr
        'ab/' << title.parameterize,             #key
        category,                                #category
        nil,                                     #parent
        nil,                                     #parent_key
        nil,                                     #description
        nil,                                     #url
        'Alberta',                               #jurisdiction
        'ocd-division/country:ca/province:ab',   #jurisdiction_code
        "Alberta Directory of Public Bodies",     #source
        BASE_URL,                                #source_url
        address,                                 #address
        contact,                                 #contact
        email,                                   #email
        nil,                                     #tags
        '7/5/13',                                #created at
        Date.today.strftime('%-m/%-d/%y')        #updated at
      ]



    end
  end
end
