# Public Bodies: Scrapers

These scripts output CSV files listing public bodies in Canadian jurisdictions for use in [Alaveteli](http://www.alaveteli.org/), [PublicBodies.org](http://publicbodies.org/) or other services.

To run all scrapers (which will output both to a file within data and to ca.csv) simply run `rake` from the projects root directory. 

If you wish to update an individual provincial or federal scraper and regenerate ca.csv, you can run  `rake scrape:update[abbreviation]` where abbreviation is either the abbreviation for a province for which there is a scraper, or `ca`. You can pass multiple abbreviations into these brackets, e.g. `rake scrape:update[sk qc ca]`If you wish simply to regenerate ca.csv from the provincial csv files you can run `rake scrape:update`.


## Data Gathered

At the time of this post, Manitoba does not offer a centralized location from which to scrape the needed data for public bodies. 

The following jurisdictions offer well organized, centralized data on public bodies:

*  [Alberta](http://www.servicealberta.ca/foip/directory-of-public-bodies.cfm)
*  [British Columbia](http://dir.gov.bc.ca/gtds.cgi?show=Branch&organizationCode=ALC&organizationalUnitCode=AGLANCOM)
*  [Nova Scotia](http://novascotia.ca/government/gov_index.asp)
*  [Ontario](https://www.pas.gov.on.ca/scripts/en/BoardsList.asp)
*  [Prince Edward Island](http://www.gov.pe.ca/government/governmentindex.php3)
*  [Saskatchewan](http://www.gov.pe.ca/government/governmentindex.php3)
*  [Quebec](http://www.cai.gouv.qc.ca/documents/CAI_liste_resp_acces.pdf)


The following jurisdictions offer limited centralized data on public bodies:
* [New Brunswick](http://www1.gnb.ca/cnb/DsS/display-e.asp?typyofPublicBodyID=1)
* [Newfoundland and Labrador](http://www.gov.nl.ca/departments.html)

## Bugs? Questions?

This project's main repository is on GitHub: [http://github.com/opennorth/publicbodies-scrapers](http://github.com/opennorth/publicbodies-scrapers), where your contributions, forks, bug reports, feature requests, and feedback are greatly welcomed.

Copyright (c) 2013 Open North Inc., released under the MIT license
