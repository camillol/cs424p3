import os
from google.appengine.ext import webapp
from google.appengine.ext.webapp.util import run_wsgi_app
from google.appengine.ext.webapp import template
from google.appengine.ext import db
from django.core import serializers

views_path = 'views/'
#execfile("db.py")
#execfile("db2.py")

class Sighting(db.Model):
      sighting_id = db.IntegerProperty()
      full_description = db.TextProperty()
      city_id = db.IntegerProperty()
      shape_id = db.IntegerProperty()
      summary_description = db.TextProperty()
      temperature = db.IntegerProperty()
      weather_conditions = db.StringProperty()
      occurred_at = db.DateTimeProperty
      reported_at = db.DateTimeProperty
      posted_at = db.DateTimeProperty

class Main(webapp.RequestHandler):
    def get(self):
        template_values = {'main': 'selected' }
        path = os.path.join(os.path.dirname(__file__), views_path + 'index.html')
        self.response.out.write(template.render(path, template_values))

class LoadSightings(webapp.RequestHandler):

    def get(self):
      self.response.out.write("DONE")

class Sightings(webapp.RequestHandler):

    def get(self):
        template_values = {'main': 'selected' }
        sighting_id = self.request.get("sighting_id")
        response = -1
        if sighting_id != '':
          response = db.GqlQuery("SELECT * FROM Sighting WHERE sighting_id = :1", int(sighting_id)).get().to_xml()
        self.response.out.write(response)

application = webapp.WSGIApplication([('/', Main), ('/sightings', Sightings), ('/_ah/remote_api', LoadSightings)],
                                     debug=True)

def main():
    run_wsgi_app(application)

if __name__ == "__main__":
    main()
