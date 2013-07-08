require 'csv'
require 'active_support/inflector'

require 'open-uri'
require 'nokogiri'

BASE_URL = 'http://www.gov.pe.ca' 

CSV.open(File.expand_path(".",Dir.pwd)+'/data/'+'pe.csv', 'w') do |csv|
  csv << %w(title abbr key category parent parent_key description url jurisdiction jurisdiction_code source source_url address contact email tags created_at updated_at)

  doc = Nokogiri::HTML(open(BASE_URL+'/government/governmentindex.php3'))
  doc.xpath('//div[@id="content_2c"]/a').drop(1).each do |org|
    url = (org['href'].include? 'http') ? org['href'] : BASE_URL + org['href']
    page = Nokogiri::HTML(open(url))
    info = page.xpath('//div[@id="content_2c"]/div[3]')
   
    addr = info.text.match(/(.*)([A-Z0-9]{3} ?){2}/m)
    addr = addr ? addr[0].gsub(/\s{2,}/,' ').strip : nil
    body_url = info.xpath('..//a[contains(text(),"Website")]') 
    contact = page.xpath('//div[@class="indent"]/span/a').text
    parent = page.xpath('//head/title').text.split(':')[0]

    csv << [
      org.text,                                #title
      nil,                                     #abbr
      'pe/' << org.text.parameterize,          #key
      nil,                                     #category
      parent,                                  #parent
      'pe/' << parent.parameterize,            #parent_key
      nil,                                     #description
      url,                                     #url
      'Prince Edward Island',                  #jurisdiction
      'ocd-division/country:ca/province:pe',   #jurisdiction_code
      "Index of Departments, Disivions and Sections", #source
      BASE_URL,                                #source_url
      addr,                                    #address
      contact,                                 #contact
      nil,                                     #email
      nil,                                     #tags
      '6/7/13',                                #created at
      Date.today.strftime('%-m/%-d/%y')        #updated at
    ]

    
  end



end