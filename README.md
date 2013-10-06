# Public Bodies: Scrapers

This repository contains scripts to scrape the basic information for each public body within each provincial, territorial and federal government in Canada. This information can be output to CSV, in formats compatible with:

* [Alaveteli](http://www.alaveteli.org/), a [mySociety](http://www.mysociety.org/) access to information platform
* [Nomenklatura](http://nomenklatura.okfnlabs.org/), an Open Knowledge Foundation data reconciliation service
* [publicbodies.org](http://publicbodies.org/), an [Open Knowledge Foundation](http://okfn.org/) project to set a URL for every part of government

Scrapers are written in [Pupa.rb](http://rdoc.info/gems/pupa), which requires Ruby 2.0.

To run a scraper, for example:

    ruby scrapers/ab.rb -h

## Bugs? Questions?

This project's main repository is on GitHub: [http://github.com/opennorth/publicbodies-scrapers](http://github.com/opennorth/publicbodies-scrapers), where your contributions, forks, bug reports, feature requests, and feedback are greatly welcomed.

Copyright (c) 2013 Open North Inc., released under the MIT license
