# Mini Blog - Flutter Web + FastAPI

Aplicación de notas desplegada en Render.

## Estructura

- `backend/` - API REST con FastAPI + SQLite
- `frontend/` - Aplicación Flutter Web

## Desarrollo local

### Backend
```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload
```
API en `http://localhost:8000` - docs en `http://localhost:8000/docs`

### Frontend
```bash
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_URL=http://localhost:8000
```

## Despliegue en Render

- **Backend**: Web Service apuntando a la carpeta `backend/`
- **Frontend**: Static Site con build de Flutter Web (`build/web`)
