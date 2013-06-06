require 'csv'
require 'active_support/inflector'

require 'open-uri'
require 'nokogiri'

BASE_URL = 'http://dir.gov.bc.ca' 

CSV.open('bc.csv', 'w') do |csv|
  csv << %w(title abbr key category parent parent_key description url jurisdiction jurisdiction_code source source_url address contact email tags created_at updated_at)


  doc = Nokogiri::HTML(open(BASE_URL+'/gtds.cgi?Index=ByUnitHier'))
  doc.xpath('//table[@width="360"]//td//a').each do |org|
    page = Nokogiri::HTML(open(BASE_URL+org['href']))
    href = page.xpath('//table[@width="725"]//td//a').each do |division|
      page = Nokogiri::HTML(open(BASE_URL+division['href']))
      info = page.xpath('//table[@width="744"]')
      p division.text
      
      email = info.xpath('.//tr[2]//td[6]').text
      one, two, three = email.scan(/(?<=')([^',]*)(?=')/)
      email = one[0] + '@' + three[0] + '.' + two[0] if one 
      if email == "Not Available" then email = nil end   
      
      address = info.at_xpath('.//tr[6]/td[3]').text.gsub(/\s{2,}/,' ').strip
      if address == "Not Available" then address = nil end

      csv << [
        division,                                #title
        nil,                                     #abbr
        'bc/' << division.text.parameterize,     #key
        nil,                                     #category
        org,                                     #parent
        'bc/' << org.text.parameterize,          #parent_key
        nil,                                     #description
        info.xpath('.//tr[3]/td[6]/a/@href'),     #url
        'British Columbia',                      #jurisdiction
        'BC',                                    #jurisdiction_code
        "B.C. Government directory",             #source
        BASE_URL+'/gtds.cgi?Index=ByUnitHier',   #source_url
        info.at_xpath('.//tr[6]/td[3]').text.gsub(/\s{2,}/,' ').strip,  #address
        nil,                                     #contact
        email,                                   #email
        nil,                                     #tags
        '6/6/13',                                #created at
        Date.today.strftime('%-m/%-d/%y')        #updated at
      ]
    end
  end
 # /html/body/div[2]/table[3]/tbody/tr[12]/td[2]/table/tbody/tr[1]/td[2]/table/tbody/tr[2]/td[6]/a


  



=begin    csv << [

    ]
=end
 
end