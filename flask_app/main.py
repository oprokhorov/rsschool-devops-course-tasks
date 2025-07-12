from flask import Flask
from flask_wtf import CSRFProtect

app = Flask(__name__)
app.secret_key = "bla-blah-some-string-so-sonarqube-would-stop-complaining-about-CSRF"  # Required for CSRF protection

csrf = CSRFProtect()
csrf.init_app(app)

@app.route('/')
def hello():
    return 'Hello, World!'