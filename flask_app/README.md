To run this application, use Docker source image with python3.9+
INstall requirements with `pip install -r requirements.txt`

Run application with:

```
FLASK_APP=main.py
flask run --host=0.0.0.0 --port=8080
```

to build docker container run

```
docker build -t flask-hello:latest .
```

to run container

```
docker run -d -p 8081:8080 flask-hello:latest
```

access application in the browser on http://localhost:8081