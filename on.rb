
require 'csv'
require 'json'
require 'active_support/inflector'

require 'open-uri'
require 'nokogiri'
CSV.open('on.csv', 'w') do |csv|
  csv << %w(title abbr key category parent parent_key description url jurisdiction jurisdiction_code source source_url address contact email tags created_at updated_at)
  
  doc = Nokogiri::HTML(open('https://www.pas.gov.on.ca/scripts/en/BoardsList.asp'))
  doc.xpath('//div[@class="MiddleList"]//ul//li/a').each do |li|
    title = li.text.downcase
    p title
    next if title.include? "ministry responsibilities"
    page = Nokogiri::HTML(open("https://www.pas.gov.on.ca/scripts/en/#{li['href'].strip}"))
    page.xpath('//div[@class="MiddleList"]').each do |info|
      text = info.text
      parent = text.match(/(?<=Ministry:)(.*)(?=Agency:)/)[0].downcase.strip
      description = text.gsub(/\s{2,}/,' ').gsub("\n",'').match(/(?<=Function:)(.*)(?=Membership)/)[0].strip if text.include?("Function:")
      url = text.match(/(?<=Agency URL:)(.*)(?=Address)/)[0].strip
      address = text.match(/(?<=Address:)(.*)(?=Tel.:)/)[0].strip
      unless info.xpath('.//table//td')[1].nil? || info.xpath('.//table//td')[1].text != "VACANCY" 
        name = info.xpath('.//table//td')[2].text.downcase 
      end

      csv << [
        title,                                                   #title
        nil,                                                     #abbr
        'on/' << title.parameterize,                             #key
        'agency',                                                #category
        parent,                                                  #parent
        parent.parameterize,                                     #parent_key
        description,                                             #description
        url,                                                     #url
        'Ontario',                                               #jurisdiction
        'On',                                                    #jurisdiction_code
        "Ontario Public Appointments Secretariat",               #source
        'https://www.pas.gov.on.ca/scripts/en/BoardsList.asp',   #source_url
        address,                                                 #address
        name,                                                    #contact
        nil,                                                     #email
        nil,                                                     #tags
        '6/5/13',                                                #created at
        Date.today.strftime('%-m/%-d/%y')                        #updated at
      ]  
    end
  end   
end
