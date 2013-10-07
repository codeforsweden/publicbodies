require File.expand_path(File.join('..', 'utils.rb'), __dir__)

class BC < OrganizationProcessor
  URL = 'http://dir.gov.bc.ca'

  # @see http://dir.gov.bc.ca/gtds.cgi?Index=ByUnitHier
  def scrape_organizations
    id = 'ocd-organization/country:ca/province:bc'
    parent = Pupa::Organization.new(_id: id, name: names[id])
    Fiber.yield(parent)

    doc = get(URI.join(URL, '/gtds.cgi?Index=ByUnitHier'))
    doc.xpath('//table[@width="360"]//td//a').each do |org|
      page = Nokogiri::HTML(Faraday.get(BASE_URL+org['href']).body)
      href = page.xpath('//table[@width="725"]//td//a').each do |division|
        page = Nokogiri::HTML(Faraday.get(BASE_URL+division['href']).body)
        info = page.xpath('//table[@width="744"]')

        email = info.xpath('.//tr[2]//td[6]').text
        one, two, three = email.scan(/(?<=')([^',]*)(?=')/)
        email = one[0] + '@' + three[0] + '.' + two[0] if one
        if email == "Not Available" then email = nil end

        address = info.at_xpath('.//tr[6]/td[3]').text.gsub(/\s{2,}/,' ').strip
        if address == "Not Available" then address = nil end

          division.text.downcase.capitalize,            #title
          org,                                     #parent
          'bc/' << org.text.parameterize,          #parent_key
          info.xpath('.//tr[3]/td[6]/a/@href'),     #url
          'British Columbia',                      #jurisdiction
          'ocd-division/country:ca/province:bc',   #jurisdiction_code
          "B.C. Government directory",             #source
          BASE_URL+'/gtds.cgi?Index=ByUnitHier',   #source_url
          address,                                 #address
          email,                                   #email
      end
    end
  end
 # /html/body/div[2]/table[3]/tbody/tr[12]/td[2]/table/tbody/tr[1]/td[2]/table/tbody/tr[2]/td[6]/a
end
