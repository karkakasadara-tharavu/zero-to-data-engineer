# Lab 10: Full-Stack Application with Database

## Learning Objectives

- Build a complete REST API with Flask/FastAPI
- Implement authentication and authorization
- Apply all database concepts in a real application
- Deploy a production-ready application
- Monitor and optimize database performance

## Prerequisites

- Flask or FastAPI
- All concepts from Labs 01-09
- Understanding of REST API principles

## Tasks

### Task 1: Project Setup and Models (20 points)

Create a task management application with complete database schema.

**Project Structure:**
```
task_manager/
├── app/
│   ├── __init__.py
│   ├── models.py
│   ├── repositories.py
│   ├── services.py
│   ├── api/
│   │   ├── __init__.py
│   │   ├── auth.py
│   │   ├── tasks.py
│   │   ├── projects.py
│   │   └── users.py
│   ├── schemas.py
│   └── utils.py
├── alembic/
│   └── versions/
├── tests/
│   ├── test_models.py
│   ├── test_api.py
│   └── test_integration.py
├── config.py
├── requirements.txt
└── main.py
```

**models.py:**
```python
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Boolean, Enum, Text
from sqlalchemy.orm import relationship, declarative_base
from sqlalchemy.sql import func
import enum

Base = declarative_base()

class UserRole(enum.Enum):
    ADMIN = "admin"
    USER = "user"
    GUEST = "guest"

class TaskStatus(enum.Enum):
    TODO = "todo"
    IN_PROGRESS = "in_progress"
    REVIEW = "review"
    DONE = "done"

class TaskPriority(enum.Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

class User(Base):
    __tablename__ = 'users'
    
    id = Column(Integer, primary_key=True)
    username = Column(String(50), unique=True, nullable=False, index=True)
    email = Column(String(100), unique=True, nullable=False, index=True)
    password_hash = Column(String(128), nullable=False)
    role = Column(Enum(UserRole), default=UserRole.USER, nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    owned_projects = relationship('Project', back_populates='owner', foreign_keys='Project.owner_id')
    assigned_tasks = relationship('Task', back_populates='assignee', foreign_keys='Task.assignee_id')
    created_tasks = relationship('Task', back_populates='creator', foreign_keys='Task.creator_id')
    comments = relationship('Comment', back_populates='author')

class Project(Base):
    __tablename__ = 'projects'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(200), nullable=False)
    description = Column(Text)
    owner_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    owner = relationship('User', back_populates='owned_projects', foreign_keys=[owner_id])
    tasks = relationship('Task', back_populates='project', cascade='all, delete-orphan')
    members = relationship('ProjectMember', back_populates='project', cascade='all, delete-orphan')

class ProjectMember(Base):
    __tablename__ = 'project_members'
    
    id = Column(Integer, primary_key=True)
    project_id = Column(Integer, ForeignKey('projects.id'), nullable=False)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    role = Column(String(20), default='member')  # owner, admin, member
    joined_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    project = relationship('Project', back_populates='members')
    user = relationship('User')

class Task(Base):
    __tablename__ = 'tasks'
    
    id = Column(Integer, primary_key=True)
    title = Column(String(200), nullable=False)
    description = Column(Text)
    status = Column(Enum(TaskStatus), default=TaskStatus.TODO, nullable=False, index=True)
    priority = Column(Enum(TaskPriority), default=TaskPriority.MEDIUM, nullable=False)
    project_id = Column(Integer, ForeignKey('projects.id'), nullable=False)
    assignee_id = Column(Integer, ForeignKey('users.id'))
    creator_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    due_date = Column(DateTime(timezone=True))
    completed_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    project = relationship('Project', back_populates='tasks')
    assignee = relationship('User', back_populates='assigned_tasks', foreign_keys=[assignee_id])
    creator = relationship('User', back_populates='created_tasks', foreign_keys=[creator_id])
    comments = relationship('Comment', back_populates='task', cascade='all, delete-orphan')
    tags = relationship('TaskTag', back_populates='task', cascade='all, delete-orphan')

class Tag(Base):
    __tablename__ = 'tags'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(50), unique=True, nullable=False)
    color = Column(String(7))  # Hex color code
    
    tasks = relationship('TaskTag', back_populates='tag')

class TaskTag(Base):
    __tablename__ = 'task_tags'
    
    task_id = Column(Integer, ForeignKey('tasks.id'), primary_key=True)
    tag_id = Column(Integer, ForeignKey('tags.id'), primary_key=True)
    
    task = relationship('Task', back_populates='tags')
    tag = relationship('Tag', back_populates='tasks')

class Comment(Base):
    __tablename__ = 'comments'
    
    id = Column(Integer, primary_key=True)
    task_id = Column(Integer, ForeignKey('tasks.id'), nullable=False)
    author_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    content = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    task = relationship('Task', back_populates='comments')
    author = relationship('User', back_populates='comments')
```

### Task 2: Repository and Service Layers (20 points)

Implement clean architecture with repositories and services.

**repositories.py:**
```python
from sqlalchemy.orm import Session, joinedload
from models import User, Project, Task, Comment, Tag
from typing import List, Optional

class UserRepository:
    """User data access"""
    
    def __init__(self, session: Session):
        self.session = session
    
    def create(self, username: str, email: str, password_hash: str, role: UserRole = UserRole.USER) -> User:
        # TODO: Implement user creation
        pass
    
    def get_by_id(self, user_id: int) -> Optional[User]:
        # TODO: Get user by ID with relationships
        pass
    
    def get_by_username(self, username: str) -> Optional[User]:
        # TODO: Get user by username
        pass
    
    def list_all(self, skip: int = 0, limit: int = 100) -> List[User]:
        # TODO: List users with pagination
        pass

class TaskRepository:
    """Task data access"""
    
    def __init__(self, session: Session):
        self.session = session
    
    def create(self, title: str, project_id: int, creator_id: int, **kwargs) -> Task:
        # TODO: Create task
        pass
    
    def get_by_id(self, task_id: int) -> Optional[Task]:
        # TODO: Get task with all relationships eagerly loaded
        return self.session.query(Task)\
            .options(
                joinedload(Task.project),
                joinedload(Task.assignee),
                joinedload(Task.creator),
                joinedload(Task.comments).joinedload(Comment.author),
                joinedload(Task.tags).joinedload(TaskTag.tag)
            )\
            .filter(Task.id == task_id)\
            .first()
    
    def list_by_project(self, project_id: int, status: Optional[TaskStatus] = None) -> List[Task]:
        # TODO: List tasks in project, optionally filtered by status
        pass
    
    def list_by_assignee(self, user_id: int) -> List[Task]:
        # TODO: List tasks assigned to user
        pass
    
    def update_status(self, task_id: int, status: TaskStatus):
        # TODO: Update task status
        pass
```

**services.py:**
```python
from repositories import UserRepository, TaskRepository, ProjectRepository
from passlib.hash import bcrypt
from datetime import datetime, timedelta
import jwt

class AuthService:
    """Authentication service"""
    
    def __init__(self, user_repo: UserRepository, secret_key: str):
        self.user_repo = user_repo
        self.secret_key = secret_key
    
    def register(self, username: str, email: str, password: str) -> User:
        """Register new user"""
        # TODO: Hash password, create user
        password_hash = bcrypt.hash(password)
        return self.user_repo.create(username, email, password_hash)
    
    def authenticate(self, username: str, password: str) -> Optional[str]:
        """Authenticate user and return JWT token"""
        # TODO: Verify credentials, generate token
        user = self.user_repo.get_by_username(username)
        if user and bcrypt.verify(password, user.password_hash):
            token = jwt.encode({
                'user_id': user.id,
                'username': user.username,
                'role': user.role.value,
                'exp': datetime.utcnow() + timedelta(hours=24)
            }, self.secret_key, algorithm='HS256')
            return token
        return None
    
    def verify_token(self, token: str) -> Optional[dict]:
        """Verify JWT token"""
        try:
            payload = jwt.decode(token, self.secret_key, algorithms=['HS256'])
            return payload
        except jwt.ExpiredSignatureError:
            return None
        except jwt.InvalidTokenError:
            return None

class TaskService:
    """Task business logic"""
    
    def __init__(self, task_repo: TaskRepository, project_repo: ProjectRepository):
        self.task_repo = task_repo
        self.project_repo = project_repo
    
    def create_task(self, user_id: int, project_id: int, title: str, **kwargs) -> Task:
        """Create new task"""
        # TODO: Verify user has access to project
        project = self.project_repo.get_by_id(project_id)
        if not project:
            raise ValueError("Project not found")
        
        # TODO: Create task
        return self.task_repo.create(title, project_id, user_id, **kwargs)
    
    def assign_task(self, task_id: int, assignee_id: int, assigner_id: int):
        """Assign task to user"""
        # TODO: Verify permissions, assign task
        pass
    
    def complete_task(self, task_id: int, user_id: int):
        """Mark task as complete"""
        # TODO: Update status, set completed_at
        pass
    
    def get_overdue_tasks(self) -> List[Task]:
        """Get overdue tasks"""
        # TODO: Query tasks with due_date < now and status != DONE
        pass
```

### Task 3: REST API Implementation (30 points)

Build REST API with FastAPI.

**main.py:**
```python
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from config import settings
import uvicorn

app = FastAPI(title="Task Manager API", version="1.0.0")

# Database setup
engine = create_engine(settings.DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)

security = HTTPBearer()

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
):
    """Get current authenticated user"""
    # TODO: Verify token, get user
    from services import AuthService
    from repositories import UserRepository
    
    auth_service = AuthService(UserRepository(db), settings.SECRET_KEY)
    payload = auth_service.verify_token(credentials.credentials)
    
    if not payload:
        raise HTTPException(status_code=401, detail="Invalid token")
    
    user_repo = UserRepository(db)
    user = user_repo.get_by_id(payload['user_id'])
    
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    
    return user

# Routes
@app.post("/api/auth/register")
def register(username: str, email: str, password: str, db: Session = Depends(get_db)):
    """Register new user"""
    # TODO: Implement registration
    pass

@app.post("/api/auth/login")
def login(username: str, password: str, db: Session = Depends(get_db)):
    """Login user"""
    # TODO: Implement login
    pass

@app.get("/api/projects")
def list_projects(
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """List user's projects"""
    # TODO: Get projects user is member of
    pass

@app.post("/api/projects")
def create_project(
    name: str,
    description: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create new project"""
    # TODO: Create project
    pass

@app.get("/api/projects/{project_id}/tasks")
def list_tasks(
    project_id: int,
    status: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """List tasks in project"""
    # TODO: List tasks with filters
    pass

@app.post("/api/tasks")
def create_task(
    title: str,
    project_id: int,
    description: Optional[str] = None,
    priority: Optional[str] = "medium",
    assignee_id: Optional[int] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create new task"""
    # TODO: Create task
    pass

@app.put("/api/tasks/{task_id}/status")
def update_task_status(
    task_id: int,
    status: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update task status"""
    # TODO: Update status
    pass

@app.get("/api/tasks/my-tasks")
def my_tasks(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get current user's assigned tasks"""
    # TODO: List user's tasks
    pass

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

### Task 4: Deployment and Monitoring (30 points)

Prepare for production deployment.

**config.py:**
```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql://user:pass@localhost/taskdb"
    SECRET_KEY: str = "your-secret-key-here"
    DEBUG: bool = False
    
    # Database pool settings
    DB_POOL_SIZE: int = 20
    DB_MAX_OVERFLOW: int = 10
    DB_POOL_TIMEOUT: int = 30
    
    # Redis cache
    REDIS_URL: str = "redis://localhost:6379/0"
    
    class Config:
        env_file = ".env"

settings = Settings()
```

**Database optimization:**
```python
# Add indexes
from sqlalchemy import Index

# In models
Index('idx_task_status_project', Task.status, Task.project_id)
Index('idx_task_assignee_status', Task.assignee_id, Task.status)
Index('idx_project_owner', Project.owner_id, Project.is_active)

# Connection pooling
engine = create_engine(
    settings.DATABASE_URL,
    pool_size=settings.DB_POOL_SIZE,
    max_overflow=settings.DB_MAX_OVERFLOW,
    pool_timeout=settings.DB_POOL_TIMEOUT,
    pool_pre_ping=True,  # Verify connections
    echo=settings.DEBUG
)
```

**Monitoring:**
```python
from prometheus_client import Counter, Histogram, generate_latest
import time

# Metrics
request_count = Counter('api_requests_total', 'Total API requests', ['method', 'endpoint'])
request_duration = Histogram('api_request_duration_seconds', 'Request duration')

@app.middleware("http")
async def monitor_requests(request, call_next):
    """Monitor API requests"""
    start_time = time.time()
    
    response = await call_next(request)
    
    duration = time.time() - start_time
    request_count.labels(method=request.method, endpoint=request.url.path).inc()
    request_duration.observe(duration)
    
    return response

@app.get("/metrics")
def metrics():
    """Prometheus metrics endpoint"""
    return Response(generate_latest(), media_type="text/plain")
```

## Testing

```python
# test_api.py
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_register():
    response = client.post("/api/auth/register", json={
        "username": "testuser",
        "email": "test@example.com",
        "password": "password123"
    })
    assert response.status_code == 200

def test_login():
    response = client.post("/api/auth/login", json={
        "username": "testuser",
        "password": "password123"
    })
    assert response.status_code == 200
    assert "access_token" in response.json()

def test_create_project():
    # Login first
    login_response = client.post("/api/auth/login", json={
        "username": "testuser",
        "password": "password123"
    })
    token = login_response.json()["access_token"]
    
    # Create project
    response = client.post(
        "/api/projects",
        json={"name": "Test Project", "description": "Test"},
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
```

## Deliverables

1. **Complete application** with all files
2. **API documentation** (OpenAPI/Swagger)
3. **Database migrations** (Alembic)
4. **Docker setup** (Dockerfile, docker-compose.yml)
5. **Deployment guide** (README.md)
6. **Test suite** with >80% coverage

## Evaluation Criteria

| Component | Points | Criteria |
|-----------|--------|----------|
| Task 1 | 20 | Models complete with relationships |
| Task 2 | 20 | Clean architecture implemented |
| Task 3 | 30 | API functional with auth |
| Task 4 | 30 | Production-ready with monitoring |

**Total: 100 points**

## Bonus Challenges (+30 points)

1. **GraphQL API** (+10 points): Add GraphQL alongside REST
2. **WebSocket Support** (+10 points): Real-time task updates
3. **Caching Layer** (+10 points): Redis caching for performance
