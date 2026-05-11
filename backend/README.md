# Rento Django Backend

Django REST API server for the Rento Flutter mobile application.

## Prerequisites
- Python 3.9+

## Setup

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## Running the Backend

```bash
cd backend
source venv/bin/activate
# Once the virtualenv is activated, `python` points to the venv's Python.
python manage.py migrate
PORT=8000 python manage.py runserver
```

The backend will start on http://localhost:8000

### Check DB connection

```bash
python manage.py dbstatus
```

## Environment Variables

Create a `.env` file in `backend/` if needed:

```
SECRET_KEY=your_secret_key
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_DB_NAME=postgres
SUPABASE_DB_USER=postgres
SUPABASE_DB_PASSWORD=your_db_password
SUPABASE_DB_HOST=your_db_host
SUPABASE_DB_HOSTADDR=optional_ipv6_address_if_hostname_resolution_fails
SUPABASE_DB_PORT=5432
SUPABASE_DB_SSLMODE=require
PORT=8000
```

### Local dev without Supabase Postgres (SQLite)

If your machine can't reach/resolve the Supabase DB host (DNS/network issues), you can run the backend locally using SQLite:

```bash
# backend/.env
DB_ENGINE=sqlite
```

## Endpoints

- `GET /`
- `GET /health`
- `GET /api/users/`
- `GET /api/rooms/`

## Notes

- CORS is open in development (`CORS_ALLOW_ALL_ORIGINS=True`).
- Database is PostgreSQL by default (configured via `SUPABASE_DB_*` in `backend/.env`).
