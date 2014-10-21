require File.expand_path(File.join('..', 'utils.rb'), __dir__)

class NL < OrganizationProcessor
  self.jurisdiction_code = 'CA-NL'

  URL = 'http://www.atipp.gov.nl.ca/info/coordinators.html'

  # @todo change to indices
  TABLE_HEADERS = {
    ['Name ', 'Address ', 'Town ', 'Postal Code ', 'ATIPP Coordinator ', 'Phone ', 'Fax ', 'Email ', 'Back-Up Coordinator ', 'Phone ', 'Email '] =>
    {
      copy: [],
      merge: ['Address '],
    },
    ['Name ', 'Address ', 'Town ', 'Postal Code ', 'ATIPP Coordinator ', 'Phone ', 'Email '] =>
    {
      copy: [],
      merge: ['Address '],
    },
    ['Department Name ', 'ATIPP Coordinator ', 'Phone ', 'Email ', 'Backup Coordinator ', 'Phone ', 'Email ', 'Department Address ', 'Town ', 'Postal Code '] =>
    {
      copy: ['Department Name ', 'ATIPP Coordinator ', 'Phone ', 'Email ', 'Department Address ', 'Town ', 'Postal Code '],
      merge: [],
    },
    ['Name ', 'ATIPP Coordinator ', 'Phone ', 'Toll Free ', 'Fax ', 'Email ', 'Back-up ATIPP Coordinator ', 'Phone ', 'Email ', 'Address ', 'Town ', 'Postal Code '] =>
    {
      copy: [],
      merge: ['Address '],
    },
    ['Municpality Name ', 'Municipality Address ', 'Town ', 'Postal Code ', 'ATIPP Coordinator ', 'Phone ', 'Fax ', 'Title ', 'Email '] =>
    {
      copy: ['ATIPP Coordinator ', 'Phone ', 'Fax ', 'Title ', 'Email '],
      merge: [],
    },
  }

  HEADERS_AND_FOOTERS = [
    'List of ATIPP Coordinators (Healthcare Bodies) Government of Newfoundland and Labrador ',
    'ATIPP Office',
    /\ADepartment of Justice UPDATED: \w+ \d{1,2}, \d{4} \z/,
  ]

  def scrape_organizations
    id = 'ocd-organization/country:ca/province:nl'
    parent = Pupa::Organization.new(_id: id, name: 'Government of Newfoundland and Labrador')
    dispatch(parent)


    get(URL).css('#gnlcontent li li a').each do |a|
      classification = a.text.sub(/\AFor /, '')

      pdf = tempfile { get(URI.join(URL, a[:href])) }
      #pdf = tempfile { Faraday.get('http://www.atipp.gov.nl.ca/info/atipp_coordinators_health_bodies.pdf').body }
      csv = tempfile { }
      `copy-paste-pdf.applescript #{pdf.path} #{csv.path} true`

      table = CopyPastePDF::Table.new(CSV.read(csv.path, encoding: 'macRoman:utf-8'))
      table.remove_empty_rows!
      table.reject! do |row|
        HEADERS_AND_FOOTERS.any? do |pattern|
          row[0] && row[0][pattern] && row.drop(1).all?(&:nil?)
        end
      end

      # @todo each file has a different header
      table.copy_into_cell_below(0, 1, 2, 3, 7, 8, 9) do |row|
        !row.drop(1).all?(&:nil?) || !row[0][/\A[A-Z ]+ -/]
      end

      table.merge_into_cell_above(1)

      table.each do |row|
        # adopt classification from classification rows?
        organization = Pupa::Organization.new
        organization.parent_id = parent._id
        # @todo
      end
    end
  end
end

run(NL)
