# Public Bodies: Scrapers

These scripts output CSV files listing public bodies in Canadian jurisdictions for use in [Alaveteli](http://www.alaveteli.org/), [PublicBodies.org](http://publicbodies.org/) or other services.

To run all scrapers (which will output both to a file within data and to ca.csv) simply run `rake` from the projects root directory. If you wish to update an individual provincial or federal scraper and regenerate ca.csv, you can run  `rake scrape:update[abbreviation]` where abbreviation is either the abbreviation for a province for which there is a scraper, or `ca_federal`. If you wish simply to regenerate ca.csv from the provincial csv files you can run `rake scrape:update`.

## Bugs? Questions?

This project's main repository is on GitHub: [http://github.com/opennorth/publicbodies-scrapers](http://github.com/opennorth/publicbodies-scrapers), where your contributions, forks, bug reports, feature requests, and feedback are greatly welcomed.

Copyright (c) 2013 Open North Inc., released under the MIT license
