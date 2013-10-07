require File.expand_path(File.join('..', 'utils.rb'), __dir__)

class AB < OrganizationProcessor
  self.jurisdiction_code = 'CA-AB'

  URL = 'http://www.servicealberta.ca/foip/directory-of-public-bodies.cfm'

  def scrape_organizations
    id = 'ocd-organization/country:ca/province:ab'
    parent = Pupa::Organization.new(_id: id, name: 'Government of Alberta')
    dispatch(parent)

    doc = post(URL, 'fuseaction=SearchResults&first_name=&last_name=&pb_name=&pbtype=&city=')
    limit = doc.at_xpath('//b').text[/(?<=of )\d+/].to_i

    1.step(limit, 10).each do |n|
      # Has organization name, classification, person name
      doc = post(URL, "CITY=&FIRST_NAME=&FUSEACTION=SearchResults&LAST_NAME=&PAGESTARTROW=#{n}&PB_NAME=&PBTYPE=")

      doc.xpath('//table//table/tr')[1..-3].each do |row|
        query = URI.parse(row.at_xpath('.//@href').value).query
        doc = get(URL, query) # Has address, voice, fax, email

        tds = row.xpath('.//td')
        td = doc.at_xpath('//table//table//tr[2]/td')
        href = td.at_xpath('./a[contains(@href, "mailto:")]/@href')
        text = clean(td.text) # invalid HTML </br>
        name = clean(tds[1].text)
        address = text[/#{Regexp.escape(name)} (.+?)(?: (?:Phone|Fax|Email):|\z)/, 1]
        url = URI.parse(URL)
        url.query = query

        organization = Pupa::Organization.new
        organization.parent_id = parent._id
        organization.name = name
        organization.classification = clean(tds[3].text)
        organization.add_contact_detail('address', address)
        organization.add_contact_detail('email', href.value.sub('mailto:', '')) if href
        organization.add_contact_detail('voice', tel(text[/Phone:(.+?)(?:Fax:|Email:|\z)/, 1]))
        organization.add_contact_detail('fax', tel(text[/Fax:(.+?)(?:Email:|\z)/, 1]))
        organization.add_source(url.to_s, note: 'Directory of Public Bodies')
        organization.add_extra(:jurisdiction_code, self.class.jurisdiction_code)
        organization.add_extra(:contact_point, [{name: clean(tds[0].text)}])

        unless valid_postal_code?(address)
          warn("Invalid postal code #{address[POSTAL_CODE_RE]} for #{organization.name}")
        end

        dispatch(organization)
      end
    end
  end
end

run(AB)
