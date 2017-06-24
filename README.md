# Flatiron School bootcamp: Sinatra Portfolio Project
### Librivox Explorer WEB v0.1 (simple web front end with HTML5/CSS)

This project is produced in partial fulfillment of the requirements of the final summative assessment of the Sinatra unit of study in the Flatiron School's online "full stack developer" bootcamp.

It pointedly goes beyond the requirements for the web-based front end, in that it utilizes more extensive HTML5 and CSS tools than stipulated by the project requirements.

However, it pointedly does NOT fulfill the requirements for usage of a SQL-based datastore managed by ActiveRecord, since my choice of project builds upon [my previous CLI front-ended project for scraping and presenting Librivox.org and Gutenberg.org data](https://github.com/dvimont/flatiron-bootcamp--project-based-assessment-1--ruby--scraper-indexer-w-CLI-frontend). That infrastructure directly loads its OO models from the locally stored HTML (copies of Librivox.org webpages, and a tar file provided by Gutenberg.org), and has no need for RDBMS storage/retrieval.

When the project is finalized, it is intended that it a live version of it will be hosted on [Heroku](https://devcenter.heroku.com/).

Note that this project is an intermediate step towards a more elaborate "Librivox Explorer" web application, which will be utilizing Javascript (particularly Ajax) in the front-end and a JSON-based API on the back-end.
