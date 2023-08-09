FROM python:3.8

RUN pip install aiohttp

COPY . /app

WORKDIR /app

CMD ["python", "cloudflareddns.py"]
