# Lab 03: SQLAlchemy ORM - Models and CRUD

## Learning Objectives

- Define ORM models with relationships
- Implement CRUD operations using Session API
- Use query methods and filters
- Handle model lifecycle and state management
- Implement cascade operations and lazy loading

## Prerequisites

- SQLAlchemy 2.0+
- Understanding of OOP concepts
- Completion of Labs 01-02

## Tasks

### Task 1: Blog System Models (25 points)

Create a complete blog system with User, Post, Comment, and Tag models.

**Requirements:**
```python
from sqlalchemy import create_engine, Column, Integer, String, Text, DateTime, ForeignKey, Table
from sqlalchemy.orm import declarative_base, relationship, Session
from datetime import datetime

Base = declarative_base()
engine = create_engine('sqlite:///blog.db', echo=True)

# TODO: Define post_tags association table
post_tags = Table(
    'post_tags',
    Base.metadata,
    # Add columns
)

class User(Base):
    __tablename__ = 'users'
    
    # TODO: Add columns and relationships
    # id, username, email, password_hash, bio, created_at
    # posts relationship
    # comments relationship
    
    def __repr__(self):
        return f"<User(username='{self.username}')>"

class Post(Base):
    __tablename__ = 'posts'
    
    # TODO: Add columns and relationships
    # id, title, content, author_id, created_at, updated_at, published
    # author relationship
    # comments relationship
    # tags relationship (many-to-many)
    
    def __repr__(self):
        return f"<Post(title='{self.title}')>"

class Comment(Base):
    __tablename__ = 'comments'
    
    # TODO: Add columns and relationships
    # id, content, post_id, author_id, created_at
    # post relationship
    # author relationship
    
    def __repr__(self):
        return f"<Comment(id={self.id})>"

class Tag(Base):
    __tablename__ = 'tags'
    
    # TODO: Add columns and relationships
    # id, name
    # posts relationship (many-to-many)
    
    def __repr__(self):
        return f"<Tag(name='{self.name}')>"

Base.metadata.create_all(engine)
```

### Task 2: Repository Pattern Implementation (25 points)

Create repository classes for each model.

**Requirements:**
```python
from typing import List, Optional

class UserRepository:
    """Manage User CRUD operations"""
    
    def __init__(self, session: Session):
        self.session = session
    
    def create(self, username: str, email: str, password: str) -> User:
        """Create new user"""
        # TODO: Hash password and create user
        pass
    
    def get_by_id(self, user_id: int) -> Optional[User]:
        """Get user by ID"""
        # TODO: Implement
        pass
    
    def get_by_username(self, username: str) -> Optional[User]:
        """Get user by username"""
        # TODO: Implement
        pass
    
    def update(self, user_id: int, **kwargs) -> Optional[User]:
        """Update user fields"""
        # TODO: Implement
        pass
    
    def delete(self, user_id: int) -> bool:
        """Delete user"""
        # TODO: Implement
        pass
    
    def get_all(self, limit: int = 100, offset: int = 0) -> List[User]:
        """Get all users with pagination"""
        # TODO: Implement
        pass

class PostRepository:
    """Manage Post CRUD operations"""
    
    def __init__(self, session: Session):
        self.session = session
    
    def create(self, title: str, content: str, author_id: int) -> Post:
        """Create new post"""
        # TODO: Implement
        pass
    
    def get_by_id(self, post_id: int) -> Optional[Post]:
        """Get post by ID"""
        # TODO: Implement
        pass
    
    def get_published(self, limit: int = 10) -> List[Post]:
        """Get published posts"""
        # TODO: Implement with filter
        pass
    
    def get_by_author(self, author_id: int) -> List[Post]:
        """Get posts by author"""
        # TODO: Implement
        pass
    
    def search(self, query: str) -> List[Post]:
        """Search posts by title or content"""
        # TODO: Implement with LIKE
        pass
    
    def add_tag(self, post_id: int, tag_name: str) -> bool:
        """Add tag to post"""
        # TODO: Implement many-to-many add
        pass
    
    def publish(self, post_id: int) -> bool:
        """Publish post"""
        # TODO: Set published=True
        pass

class CommentRepository:
    """Manage Comment CRUD operations"""
    
    def __init__(self, session: Session):
        self.session = session
    
    def create(self, content: str, post_id: int, author_id: int) -> Comment:
        """Create new comment"""
        # TODO: Implement
        pass
    
    def get_by_post(self, post_id: int) -> List[Comment]:
        """Get comments for post"""
        # TODO: Implement with order by created_at
        pass
    
    def delete(self, comment_id: int) -> bool:
        """Delete comment"""
        # TODO: Implement
        pass
```

### Task 3: Service Layer (25 points)

Implement business logic in service classes.

**Requirements:**
```python
class BlogService:
    """Business logic for blog operations"""
    
    def __init__(self, session: Session):
        self.user_repo = UserRepository(session)
        self.post_repo = PostRepository(session)
        self.comment_repo = CommentRepository(session)
        self.session = session
    
    def register_user(self, username: str, email: str, password: str) -> User:
        """Register new user with validation"""
        # TODO: Validate uniqueness, create user
        pass
    
    def create_post(self, title: str, content: str, author_username: str, tags: List[str]) -> Post:
        """Create post with tags"""
        # TODO: Get user, create post, add tags
        pass
    
    def add_comment(self, post_id: int, content: str, author_username: str) -> Comment:
        """Add comment to post"""
        # TODO: Validate post exists, create comment
        pass
    
    def get_post_with_comments(self, post_id: int) -> dict:
        """Get post with all comments"""
        # TODO: Use eager loading
        pass
    
    def get_user_dashboard(self, username: str) -> dict:
        """Get user stats and recent activity"""
        # TODO: Aggregate post count, comment count, recent posts
        pass
    
    def get_feed(self, limit: int = 10) -> List[Post]:
        """Get recent published posts with authors"""
        # TODO: Use eager loading for author
        pass
```

### Task 4: Advanced Features (25 points)

Implement advanced ORM features.

**Requirements:**
```python
from sqlalchemy.orm import validates
from sqlalchemy.ext.hybrid import hybrid_property

class User(Base):
    # ... existing code ...
    
    @validates('email')
    def validate_email(self, key, email):
        """Validate email format"""
        # TODO: Implement email validation
        pass
    
    @validates('username')
    def validate_username(self, key, username):
        """Validate username"""
        # TODO: Check length, characters
        pass
    
    @hybrid_property
    def post_count(self):
        """Count of user's posts"""
        # TODO: Implement
        pass
    
    @post_count.expression
    def post_count(cls):
        """Query-level post count"""
        # TODO: Implement for queries
        pass

class Post(Base):
    # ... existing code ...
    
    @hybrid_property
    def is_recent(self):
        """Check if post is less than 7 days old"""
        # TODO: Implement
        pass
    
    @hybrid_property
    def comment_count(self):
        """Count of comments"""
        # TODO: Implement
        pass
    
    def get_excerpt(self, length: int = 200) -> str:
        """Get post excerpt"""
        # TODO: Return first N characters
        pass
```

## Testing

```python
import unittest
from sqlalchemy.orm import Session

class TestBlogSystem(unittest.TestCase):
    """Test blog ORM functionality"""
    
    @classmethod
    def setUpClass(cls):
        """Set up test database"""
        cls.engine = create_engine('sqlite:///test_blog.db')
        Base.metadata.create_all(cls.engine)
    
    def setUp(self):
        """Create session for each test"""
        self.session = Session(self.engine)
        self.service = BlogService(self.session)
    
    def test_user_registration(self):
        """Test user registration"""
        user = self.service.register_user('testuser', 'test@example.com', 'password123')
        self.assertIsNotNone(user.id)
        self.assertEqual(user.username, 'testuser')
    
    def test_create_post(self):
        """Test post creation with tags"""
        user = self.service.register_user('author', 'author@example.com', 'pass')
        self.session.commit()
        
        post = self.service.create_post(
            'Test Post',
            'This is test content',
            'author',
            ['python', 'testing']
        )
        self.session.commit()
        
        self.assertIsNotNone(post.id)
        self.assertEqual(len(post.tags), 2)
    
    def test_add_comment(self):
        """Test adding comment"""
        # Create user and post
        author = self.service.register_user('author', 'author@example.com', 'pass')
        post = self.service.create_post('Post', 'Content', 'author', [])
        self.session.commit()
        
        # Add comment
        comment = self.service.add_comment(post.id, 'Great post!', 'author')
        self.session.commit()
        
        self.assertIsNotNone(comment.id)
        self.assertEqual(comment.content, 'Great post!')
    
    def test_relationships(self):
        """Test relationship navigation"""
        author = self.service.register_user('author', 'author@example.com', 'pass')
        post = self.service.create_post('Post', 'Content', 'author', [])
        comment = self.service.add_comment(post.id, 'Comment', 'author')
        self.session.commit()
        
        # Navigate relationships
        self.assertEqual(post.author.username, 'author')
        self.assertEqual(comment.post.title, 'Post')
        self.assertEqual(len(author.posts), 1)
    
    def tearDown(self):
        """Clean up session"""
        self.session.rollback()
        self.session.close()
    
    @classmethod
    def tearDownClass(cls):
        """Remove test database"""
        import os
        if os.path.exists('test_blog.db'):
            os.remove('test_blog.db')

if __name__ == '__main__':
    unittest.main()
```

## Deliverables

1. **models.py**: Complete ORM models
2. **repositories.py**: Repository implementations
3. **services.py**: Business logic layer
4. **tests.py**: Comprehensive tests
5. **demo.py**: Demo script showing functionality
6. **README.md**: Documentation

## Evaluation Criteria

| Component | Points | Criteria |
|-----------|--------|----------|
| Task 1 | 25 | Models correctly defined with relationships |
| Task 2 | 25 | Repositories implement all CRUD operations |
| Task 3 | 25 | Service layer handles business logic |
| Task 4 | 25 | Advanced features work correctly |

**Total: 100 points**

## Bonus Challenges (+25 points)

1. **Pagination** (+10 points): Implement cursor-based pagination
2. **Full-Text Search** (+10 points): Add SQLite FTS5 integration
3. **Caching** (+5 points): Add simple query result caching
