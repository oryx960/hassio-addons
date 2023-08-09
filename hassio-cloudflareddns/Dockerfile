# Use an official Python runtime as the parent image
FROM python:3.8-slim

# Set the maintainer label
LABEL maintainer="Oryx960"

# Set environment variables
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV PATH /usr/local/bin:$PATH
ENV PYTHONUNBUFFERED 1

# Set work directory
WORKDIR /usr/src/app

# Copy main.py into the container
COPY cloudflareddns.py .

# Install necessary dependencies
RUN pip install --no-cache-dir aiohttp

# Specify the command to run on boot
CMD [ "python", "./cloudflareddns.py" ]
