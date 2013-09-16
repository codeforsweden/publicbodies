require 'csv'

desc 'Output organizations to CSV in PublicBodies.org format'
task :public_bodies do
  puts CSV.generate_line %w(
    title
    abbr
    key
    category
    parent
    parent_key
    description
    url
    jurisdiction
    jurisdiction_code
    source
    source_url
    address
    contact
    email
    tags
  )

  session = Moped::Session.new(['localhost:27017'], database: 'publicbodies')
  collection = session['organizations']

  names = {}

  collection.find.each do |organizations|
    names[organization.parent_id] ||= collection.find(_id: organization.parent_id).first['name']

    puts CSV.generate_line [
      organization.name,
      nil,
      organization._id,
      organization.classification,
      nil,
      nil,
      nil,
      names[organization.parent_id],
      organization.parent_id,
      organization.sources[0][:note],
      organization.sources[0][:url],
      organization.contact_details.address,
      organization.extras[:contact_point],
      organization.contact_details.email,
      nil,
      nil,
      nil,
    ]
  end
end

task :scrape do
  Dir[File.expand_path(File.join('scrapers', '*.rb'), __dir__)].each do |path|
    require path
  end
end

task default: :scrape
