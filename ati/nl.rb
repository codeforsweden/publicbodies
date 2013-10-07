require File.expand_path(File.join('..', 'utils.rb'), __dir__)

URL = "http://www.gov.nl.ca/departments.html"

doc = Nokogiri::HTML(Faraday.get(URL).body)

doc.xpath('//div[@class = "content"]').each do |column|
  category = column.at_xpath('.//h2').text
  column.xpath('./ul/li').each do |link|
    title = link.xpath('./p/a').text
    contact_link = link.at_xpath('.//a')['href']

    add_record(csv, title, category, nil, contact_link)
    if not link.xpath('./ul/li').nil?
      parent = title
      link.xpath('./ul/li//a').each do |sub_link|
        title = sub_link.text
        add_record(csv, title, category, parent, sub_link['href'])
      end
    end
  end
end

def add_record(csv, title, category, parent, url)
  page = Nokogiri::HTML(Faraday.get(url).body)
  address = page.xpath('//div[@class="adr"]').text
  address = address.gsub(/\s{2,}/,' ').gsub(/(Phone:|Toll Free:).*/,'') if address

  email = page.xpath('//div[@class="adr"]/following-sibling::div/a')[0]
  email = email.text if email

  description = page.xpath('//div[@class="aboutsite"]/p').text.gsub(/\s{2,}/,' ')

  csv << [
    title,                                   #title
    category,                                #category
    parent,                                  #parent
    description,                      #description
    url,                              #url
    "Newfoundland and Labrador Departments and Agencies",     #source
    URL,                                     #source_url
    address,                          #address
    email,                            #email
  ]
end

