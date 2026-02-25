FROM python:3.11-slim

WORKDIR /app
COPY . .

# Install the required drivers
RUN pip install Flask sqlalchemy pg8000 cloud-sql-python-connector[pg8000]

CMD ["python", "main.py"]