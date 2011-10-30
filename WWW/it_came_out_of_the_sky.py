import os
from google.appengine.ext import webapp
from google.appengine.ext.webapp.util import run_wsgi_app
from google.appengine.ext.webapp import template

views_path = 'views/'
execfile("db.py")
class Main(webapp.RequestHandler):
    def get(self):
        template_values = {'main': 'selected' }
        path = os.path.join(os.path.dirname(__file__), views_path + 'index.html')
        self.response.out.write(template.render(path, template_values))
class Sightings(webapp.RequestHandler):
    def get(self):
        template_values = {'main': 'selected' }
        sighting_id = self.request.get("sighting_id")
        response = "Bad Input"
        if sighting_id != '':
          response = getSighting(int(sighting_id))
        self.response.out.write(response)

application = webapp.WSGIApplication([('/', Main), ('/sightings', Sightings)],
                                     debug=True)

def main():
    run_wsgi_app(application)

if __name__ == "__main__":
    main()
