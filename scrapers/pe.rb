require File.expand_path(File.join('..', 'utils.rb'), __dir__)

class PE < OrganizationProcessor
  URL = 'http://www.gov.pe.ca/jps/index.php3?number=1024337&lang=E'
  self.jurisdiction_code = 'CA-PE'

  def scrape_organizations
    id = 'ocd-organization/country:ca/province:pe'
    parent = Pupa::Organization.new(_id: id, name: 'Government of Prince Edward Island')
    Fiber.yield(parent)

    get(URL).at_css('#content_2c').to_s.split(/<br>(?=<strong>)/).drop(1).each do |html|
      fragment = Nokogiri::HTML(html)
      text = fragment.text
      a = fragment.at_css('a')
      href = a[:href]

      # The vCard at the person's URL does not have the *mailing* address.
      address = adr(text[/#{Regexp.escape(a.text)}(.+?)(?=Tel:|Fax:)/m, 1].strip.gsub(' ', ' ')) # non-breaking space

      organization = Pupa::Organization.new
      organization.parent_id = parent._id
      organization.name = fragment.at_css('strong').text
      organization.add_contact_detail('address', address)
      organization.add_source(URL, note: 'Index of Departments, Divisions and Sections')

      if href[/\Amailto:/]
        organization.add_contact_detail('email', href.sub(/\Amailto:/, ''))
        organization.add_contact_detail('voice', tel(text[/Tel:(.+?)(?:Fax:|\z)/m, 1]))
        organization.add_contact_detail('fax', tel(text[/Fax:(.+?)\z/m, 1]))
        organization.add_extra(:contact_point, a.text)
      else
        url = URI.join(URL, href)
        doc = get(url)
        url = URI.join(url, doc.at_xpath('//a[starts-with(@href,"vcard")]')[:href])
        vcard = Vcard::Vcard.decode(get(url)).first

        organization.add_contact_detail('email', vcard.email.to_s)
        organization.add_contact_detail('voice', tel(vcard.telephones.find{|x| x.location == ['work']}))
        organization.add_contact_detail('fax', tel(vcard.telephones.find{|x| x.capability == ['fax']}))
        organization.add_extra(:contact_point, [{name: vcard.name.fullname}])
      end

      unless valid_postal_code?(address)
        warn("Invalid postal code #{address[POSTAL_CODE_RE]} for #{organization.name}")
      end

      Fiber.yield(organization)
    end
  end
end

Pupa::Runner.new(PE, database: 'publicbodies', expires_in: 604800).run(ARGV) # 1 week
