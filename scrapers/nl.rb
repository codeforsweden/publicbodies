require 'active_support/inflector'
require 'csv'

require 'open-uri'
require 'nokogiri'


def get_info(url)
  page = Nokogiri::HTML(open(url))
  address = page.xpath('//div[@class="adr"]').text
  address = address.gsub(/\s{2,}/,' ').gsub(/(Phone:|Toll Free:).*/,'') if address

  email = page.xpath('//div[@class="adr"]/following-sibling::div/a')[0]
  email = email.text if email
  
  description = page.xpath('//div[@class="aboutsite"]/p').text.gsub(/\s{2,}/,' ')
  
  {
    :address => address,
    :email => email,
    :description => description,
    :url => url
  }

end

def add_record(csv, title, category, parent, info)
  parent_key = 'nl/' << parent.parameterize if parent
  csv << [
    title,                                   #title
    title.parameterize,                      #abbr
    'nl/' << title.parameterize,             #key
    category,                                #category
    parent,                                  #parent
    parent_key,                              #parent_key
    info[:description],                      #description
    info[:url],                              #url
    'Newfoundland and Labrador',             #jurisdiction
    'ocd-division/country:ca/province:nl',   #jurisdiction_code
    "Newfoundland and Labrador Departments and Agencies",     #source
    URL,                                     #source_url
    info[:address],                          #address
    nil,                                     #contact
    info[:email],                            #email
    nil,                                     #tags
    '7/8/13',                                #created at
    Date.today.strftime('%-m/%-d/%y')        #updated at
  ]
end

URL = "http://www.gov.nl.ca/departments.html"

doc = Nokogiri::HTML(open(URL))

CSV.open(File.expand_path(".",Dir.pwd)+'/data/'+'nl.csv','w') do |csv|
  csv << %w(title abbr key category parent parent_key description url jurisdiction jurisdiction_code source source_url address contact email tags created_at updated_at)

  doc.xpath('//div[@class = "content"]').each do |column|
    category = column.at_xpath('.//h2').text
    column.xpath('./ul/li').each do |link|
      
      title = link.xpath('./p/a').text
      contact_link = link.at_xpath('.//a')['href']

      add_record(csv, title, category, nil, get_info(contact_link))
      if not link.xpath('./ul/li').nil?
        parent = title
        link.xpath('./ul/li//a').each do |sub_link|
          title = sub_link.text
          add_record(csv, title, category, parent, get_info(sub_link['href']))
        end
      end


    end
  end
end