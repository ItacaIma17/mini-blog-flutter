"""
Mini Blog - Backend FastAPI
CRUD de notas con SQLite y CORS habilitado para el frontend Flutter Web.
"""
import os
import sqlite3
from contextlib import contextmanager
from datetime import datetime
from typing import Optional

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# --- Configuración -----------------------------------------------------------
DB_PATH = os.environ.get("DB_PATH", "notes.db")

app = FastAPI(title="Mini Blog API", version="1.0.0")

# CORS abierto para que el frontend Flutter Web pueda llamar al backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# --- Base de datos -----------------------------------------------------------
@contextmanager
def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
        conn.commit()
    finally:
        conn.close()


def init_db():
    with get_db() as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS notes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                content TEXT NOT NULL,
                created_at TEXT NOT NULL
            )
            """
        )


@app.on_event("startup")
def on_startup():
    init_db()


# --- Modelos -----------------------------------------------------------------
class NoteIn(BaseModel):
    title: str = Field(..., min_length=1, max_length=120)
    content: str = Field(..., min_length=1, max_length=5000)


class Note(NoteIn):
    id: int
    created_at: str


# --- Endpoints ---------------------------------------------------------------
@app.get("/")
def root():
    return {"status": "ok", "service": "mini-blog-api"}


@app.get("/health")
def health():
    return {"status": "healthy"}


@app.get("/api/notes", response_model=list[Note])
def list_notes():
    with get_db() as conn:
        rows = conn.execute(
            "SELECT id, title, content, created_at FROM notes ORDER BY id DESC"
        ).fetchall()
        return [dict(r) for r in rows]


@app.post("/api/notes", response_model=Note, status_code=201)
def create_note(note: NoteIn):
    created_at = datetime.utcnow().isoformat()
    with get_db() as conn:
        cur = conn.execute(
            "INSERT INTO notes (title, content, created_at) VALUES (?, ?, ?)",
            (note.title, note.content, created_at),
        )
        new_id = cur.lastrowid
        return {
            "id": new_id,
            "title": note.title,
            "content": note.content,
            "created_at": created_at,
        }


@app.get("/api/notes/{note_id}", response_model=Note)
def get_note(note_id: int):
    with get_db() as conn:
        row = conn.execute(
            "SELECT id, title, content, created_at FROM notes WHERE id = ?",
            (note_id,),
        ).fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Note not found")
        return dict(row)


@app.delete("/api/notes/{note_id}", status_code=204)
def delete_note(note_id: int):
    with get_db() as conn:
        cur = conn.execute("DELETE FROM notes WHERE id = ?", (note_id,))
        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="Note not found")
        return None