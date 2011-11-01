import os
from google.appengine.ext import webapp
from google.appengine.ext.webapp.util import run_wsgi_app
from google.appengine.ext.webapp import template
from google.appengine.ext import db
from django.core import serializers
import datetime

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
      def summary_description_short(self):
        shortened = self.summary_description
        if len(self.summary_description) > 50:
          shortened = (self.summary_description[:50] + '..') 
        return shortened
      def created_at_formatted(self):
        return self.occurred_at.datetime.strftime("%m-%d-%y")
      def show_date(self):
        return False #hasattr(self.sighting.occurred_at.datetime, 'month')

class City(db.Model):
      city_id = db.IntegerProperty()
      county_id= db.IntegerProperty()
      state_id = db.IntegerProperty()
      name = db.StringProperty()
      lat = db.FloatProperty()
      lon = db.FloatProperty()

class Index(webapp.RequestHandler):
    def get(self):
        template_values = {'current_page': 'home' }
        path = os.path.join(os.path.dirname(__file__), views_path + 'index.html')
        self.response.out.write(template.render(path, template_values))

class Screenshots(webapp.RequestHandler):
    def get(self):
        template_values = {'current_page': 'screenshots' }
        path = os.path.join(os.path.dirname(__file__), views_path + 'screenshots.html')
        self.response.out.write(template.render(path, template_values))

class Download(webapp.RequestHandler):
    def get(self):
        template_values = {'current_page': 'download' }
        path = os.path.join(os.path.dirname(__file__), views_path + 'download.html')
        self.response.out.write(template.render(path, template_values))
class Search(webapp.RequestHandler):
    def get(self):
        city_name = self.request.get("city_name")
        shape_id = self.request.get("shape_id")
        cities = City.all().filter("name = ", city_name.lower().capitalize()).fetch(limit=10)
        sightings = []
        if len(cities) > 0:
          sightings = Sighting.all().filter("city_id IN ", map((lambda x: x.city_id), cities)).fetch(limit=100) 
        if len(shape_id) > 0:
          sightings = Sighting.all().filter("shape_id = ", int(shape_id)).fetch(limit=100) 
        template_values = {'current_page': 'search', 'sightings': sightings, 'city_name': city_name }
        path = os.path.join(os.path.dirname(__file__), views_path + 'search.html')
        self.response.out.write(template.render(path, template_values))

class DataExtraction(webapp.RequestHandler):
    def get(self):
        template_values = {'current_page': 'data_extraction'}
        path = os.path.join(os.path.dirname(__file__), views_path + 'data_extraction.html')
        self.response.out.write(template.render(path, template_values))

class Observations(webapp.RequestHandler):
    def get(self):
        template_values = {'current_page': 'observations'}
        path = os.path.join(os.path.dirname(__file__), views_path + 'observations.html')
        self.response.out.write(template.render(path, template_values))

class Sightings(webapp.RequestHandler):
    def get(self):
        template_values = {'main': 'selected' }
        sighting_id = self.request.get("sighting_id")
        response = -1
        if sighting_id != '':
          response = db.GqlQuery("SELECT * FROM Sighting WHERE sighting_id = :1", int(sighting_id)).get().to_xml()
        self.response.out.write('<?xml version="1.0"?>');
        self.response.out.write(response)

class Applet(webapp.RequestHandler):
    def get(self):
        template_values = {'current_page': 'applet' }
        path = os.path.join(os.path.dirname(__file__), views_path + 'applet.html')
        self.response.out.write(template.render(path, template_values))

application = webapp.WSGIApplication([('/', Index), 
                                      ('/sightings', Sightings), 
                                      ('/screenshots', Screenshots),
                                      ('/search', Search),
                                      ('/data_extraction', DataExtraction),
                                      ('/observations', Observations),
                                      ('/download', Download),
                                      ('/applet', Applet)],
                                     debug=True)

def main():
    run_wsgi_app(application)

if __name__ == "__main__":
    main()
