require 'active_support/inflector'
require 'csv'

if ARGV.include?('--clobber') || !File.exist?('CAI_liste_resp_acces.pdf')
  `curl -O http://www.atipp.gov.nl.ca/info/atipp_coordinators_gov_agencies.pdf`
end
table_of_contents = nil
block = []
p `pdftotext -layout atipp_coordinators_gov_agencies.pdf -`
