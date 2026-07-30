# ---------- Builder stage ----------
FROM python:3.11-slim AS builder

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

COPY . .

# ---------- Runtime stage ----------
FROM gcr.io/distroless/python3-debian12

WORKDIR /app

COPY --from=builder /install /usr/local
COPY --from=builder /app /app

EXPOSE 8080

USER 1000

ENV PYTHONPATH=/usr/local/lib/python3.11/site-packages

ENTRYPOINT ["/usr/bin/python3.11", "-m", "gunicorn.app.wsgiapp"]

CMD ["--bind", "0.0.0.0:8080", "app:app"]
