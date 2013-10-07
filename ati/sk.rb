require File.expand_path(File.join('..', '..', 'utils.rb'), __FILE__)

BASE_URL = 'http://gtds.gov.sk.ca'
categories = ['Ministries', 'Crown Corporations', 'Agencies, Boards and Commissions']

CSV.open(File.expand_path(".",Dir.pwd)+'/data/'+'sk.csv', 'w') do |csv|
  csv << %w(title abbr key category parent parent_key description url jurisdiction jurisdiction_code source source_url address contact email tags created_at updated_at)

  doc = Nokogiri::HTML(Faraday.get(BASE_URL).body)
  doc.xpath('//div[@id="ctl00_ctl00_ContentPlaceHolder1_GTDSContentPlaceHolder2_tvMove"]//td//a').each do |category|
    next unless categories.include? category.text
    list_page = Nokogiri::HTML(Faraday.get(BASE_URL+category['href']).body)
    list_page.xpath('//div[@class="PageHeaderModule"][2]/following-sibling::table//a').each do |body|
      next if body.text.include? 'Saskatchewan Government'
      page = Nokogiri::HTML(Faraday.get(BASE_URL+'/Pages/'+body['href']).body)
      info = page.xpath('//div[@class="PageHeaderModule"][2]/following-sibling::table')

      title = body.text.gsub(/\s{2,}/,' ').strip
      abbr = info.xpath('./tr[2]/td/span[1]').text.split('--')[1]
      if (abbr && abbr.include?('See') || abbr.nil?) then abbr = title.parameterize end

      contact_info = info.xpath('.//tr[4]//table//tr[2]//td[2]')
      url = contact_info.xpath('.//a').text
      contact_info = contact_info.text.split(url)
      address = contact_info[0].strip
      email = contact_info[1].strip

      #p info.xpath('.//tr//td//table//td[contains]').text
      csv << [
        title,                                   #title
        abbr,                                    #abbr
        'sk/' << abbr,                           #key
        category.text.gsub(/\s{2,}/,' ').strip,  #category
        nil,                                     #parent
        nil,                                     #parent_key
        nil,                                     #description
        url,                                     #url
        'Saskatchewan',                          #jurisdiction
        'ocd-division/country:ca/province:sk',   #jurisdiction_code
        "Saskatchewan Government Telephone Directory",             #source
        BASE_URL,                                #source_url
        address,                                 #address
        nil,                                     #contact
        email,                                   #email
        nil,                                     #tags
        '6/7/13',                                #created at
        Date.today.strftime('%-m/%-d/%y')        #updated at
      ]
    end

  end



=begin

=end
end