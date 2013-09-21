require File.expand_path(File.join('..', '..', 'utils.rb'), __FILE__)

class NB < OrganizationProcessor
  URL = 'http://www1.gnb.ca/cnb/DsS/index-e.asp'
  # There may be multiple Co-ordinator blocks.
  END_RE = /(?=Co-ordinator:|Email:|Phone:|Fax:|\z)/

  def scrape_organizations
    id = 'ocd-organization/country:ca/province:nb'
    parent = Pupa::Organization.new(_id: id, name: names[id])
    Fiber.yield(parent)

    paths = get(URL).xpath('//table[2]//a/@href').map(&:value) - [
      # These pages have the same public bodies as subpages.
      'display-e.asp?typyofPublicBodyID=4',
      'education-e.asp?typyofPublicBodyID=4&group_E=Education',
      'healthCare-e.asp?typyofPublicBodyID=4&group_E=Healthcare',
      'LocalGovernment-e.asp?typyofPublicBodyID=4&group_E=Local Government',
    ]

    paths.each do |path|
      url = URI.join(URL, path.gsub(' ', '%20'))
      doc = get(url)

      doc.xpath('//table[4]//table').each do |table|
        div = table.at_xpath('.//div')
        div.css('br').each{|br| br.replace "[BR]"}
        text = clean(div.text).gsub('[BR]', "\n").gsub(/ +(?=,|\n)/, '').gsub(/(?<=\n) +/, '')
        address = adr(text[/\A(.+?)#{END_RE}/m, 1])
        href = table.at_xpath('.//a/@href')
        contact_point = text[/Co-ordinator:(.+?)#{END_RE}/m, 1]

        organization = Pupa::Organization.new
        organization.parent_id = parent._id
        organization.name = clean(table.at_xpath('.//u').text)
        organization.classification = clean(doc.at_xpath('//span[@class="Body_TxT_Black_Small"]').text.split('>').last)
        organization.add_contact_detail('address', address)
        organization.add_contact_detail('email', href.value.sub('mailto:', '')) if href
        organization.add_contact_detail('voice', tel(text[/Phone:(.+?)#{END_RE}/m, 1]))
        organization.add_contact_detail('fax', tel(text[/Fax:(.+?)#{END_RE}/m, 1]))
        organization.add_source(url.to_s, note: 'Directory of Public Bodies')
        organization.add_extra(:contact_point, clean(contact_point)) if contact_point

        unless valid_postal_code?(address)
          warn("Invalid postal code #{address[POSTAL_CODE_RE]} for #{organization.name}")
        end

        Fiber.yield(organization)
      end
    end
  end
end

Pupa::Runner.new(NB, database: 'publicbodies', expires_in: 604800).run(ARGV) # 1 week
