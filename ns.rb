require 'csv'
require 'active_support/inflector'

require 'open-uri'
require 'nokogiri'
require 'rest_client'

BASE_URL = 'http://novascotia.ca' 
BAD_LINKS = {
  'Advisory Council on the Status of Women' => nil,
  'Art Gallery of Nova Scotia' => 'http://www.artgalleryofnovascotia.ca/en/landing.aspx',
  'Chief Medical Examiner' => nil,
  'Council on African Canadian Education' => 'http://www.cace.ns.ca/',
  'Community Services' => 'http://novascotia.ca/coms/',
  'Disabled Persons Commission' => 'http://disability.novascotia.ca/',
  'Halifax-Dartmouth Bridge Commission' => 'https://www.hdbc.ca/Default.asp',
  'Highway 104 Western Alignment Corporation' => nil,
  'Nova Scotia Museum' => 'http://museum.gov.ns.ca/en/home/default.aspx',
  'Provincial Library' => 'https://www.library.ns.ca/',
  "Queen's Printer" => nil,
  'Status of Women, Advisory Council on the' => nil,
  'Waterfront Development Corporation' => nil,
  }

def get_contact_page(url)
  begin
    response = RestClient.get(url)
  rescue => e
    if e.response.code == 404 
      if url.include? '.ns'
        get_contact_page(url.gsub('.ns',''))
      end
    end
    nil
  end
end

def get_address(page)
  page.xpath('//p').each do |p|
    p = p.text

    if p.match /[A-Z][0-9][A-Z] [0-9][A-Z][0-9]/
      info = p.strip.split(/\n|\n\r|\r/)
      info.reject! {|x| !x.match(/[0-9]/)}
      info = info.join(' ').strip 
      info.gsub!(/(?<=[A-Z][0-9][A-Z] [0-9][A-Z][0-9])(.*)/,'')
      if info.match(/PO|P.O./)
        info.gsub!(/(.*)(?=PO|P.O.)/,'')
      else
        info.gsub!(/\A(.*?)(?=\d|suite|ste)/i,'')
      end 
      return info.squeeze(' ').strip
    end
  end
  nil
end

def new_record(title, category, url, address, email)
  [
    title,                               #title
    nil,                                     #abbr
    'ns/' << title.parameterize,         #key
    category,                                #category
    nil,                                     #parent
    nil,                                     #parent_key
    nil,                                     #description
    url,                                     #url
    'Nova Scotia',                           #jurisdiction
    'NS',                                    #jurisdiction_code
    "Government Directory",                  #source
    BASE_URL+'/government/gov_index.asp',    #source_url
    address,                                 #address
    nil,                                     #contact
    email,                                   #email
    nil,                                     #tags
    '6/10/13',                               #created at
    Date.today.strftime('%-m/%-d/%y')        #updated at
  ]
end

CSV.open('ns.csv', 'w') do |csv|
  csv << %w(title abbr key category parent parent_key description url jurisdiction jurisdiction_code source source_url address contact email tags created_at updated_at)

  doc = Nokogiri::HTML(open(BASE_URL+'/government/gov_index.asp'))
  doc.xpath('//div[@id="main"]/ul/li/a').each do |body|
    title = body.text
    category = body.xpath('ancestor::ul//preceding-sibling::h2[1]').text
    url = (body['href'].include? 'http') ? body['href'] : BASE_URL+body['href']
    
    if BAD_LINKS.include? title
      if BAD_LINKS[title].nil?
        csv << new_record(body.text, category, nil, nil, nil)
        next
      else
        url = BAD_LINKS[title]
      end
    end
    p url
    page = Nokogiri::HTML(RestClient.get(url, 'User-Agent' => 'ruby'))
    contact_url = page.xpath('//a[contains(text(),"Contact")]')

    if contact_url.empty?
      csv << new_record(body.text, category, url, nil, nil)
      next
    end 
    

    ## if there is a contact link on this page, try to find the url
    ## for the contacts page

    domain = (contact_url[0]['href'].include?('/')) ? url.match(/.*\.[a-z]{2,3}/)[0] : url
    contact_url = (contact_url[0]['href'].include? 'http') ? contact_url[0]['href'] : domain+'/'+contact_url[0]['href']
    contact_url.gsub!(/(?<=[^:])(\/\/)/,'/')

    if get_contact_page(contact_url).nil?
      address = nil
    else
      page = Nokogiri::HTML(get_contact_page(contact_url))
      address = get_address(page)
    end
    
    email = page.xpath('//a[contains(@href,"mailto:")]')
    email = (email.empty? || !email[0]['href'].include?('@')) ? nil : email[0]['href'].gsub('mailto:','').gsub(/\?.*/,'')
    csv << new_record(body.text, category, url, address, email)
  end
    
end