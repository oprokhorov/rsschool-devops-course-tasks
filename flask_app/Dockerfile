FROM python:3.13.5-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY main.py .
EXPOSE 8080
ENV FLASK_APP=main.py

RUN useradd -m flaskuser
USER flaskuser

ENTRYPOINT ["flask"]
CMD ["run", "--host=0.0.0.0", "--port=8080"]