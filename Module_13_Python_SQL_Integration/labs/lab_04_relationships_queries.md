# Lab 04: Relationships and Complex Queries

## Learning Objectives

- Implement all relationship types (one-to-many, many-to-many, one-to-one)
- Use eager and lazy loading strategies
- Write complex queries with multiple joins
- Implement association objects with additional data
- Handle bidirectional relationships

## Prerequisites

- SQLAlchemy ORM fundamentals
- Understanding of database normalization
- Completion of Labs 01-03

## Tasks

### Task 1: University System Schema (20 points)

Create a university management system with complex relationships.

**Schema Requirements:**
- **Students**: id, name, email, enrollment_date, gpa
- **Courses**: id, code, name, credits, department
- **Instructors**: id, name, email, department, hire_date
- **Enrollments**: student_id, course_id, semester, grade, enrollment_date
- **Departments**: id, name, building
- **Prerequisites**: course_id, prerequisite_id

**Relationships:**
- Student ↔ Course (many-to-many through Enrollment)
- Instructor ↔ Course (one-to-many)
- Course ↔ Course (self-referential for prerequisites)
- Department ↔ Instructor (one-to-many)
- Department ↔ Course (one-to-many)

**Starter Code:**
```python
from sqlalchemy import create_engine, Column, Integer, String, Float, Date, ForeignKey, Table
from sqlalchemy.orm import declarative_base, relationship, Session
from datetime import date

Base = declarative_base()
engine = create_engine('sqlite:///university.db', echo=True)

# TODO: Define prerequisites association table with extra data
prerequisites = Table(
    'prerequisites',
    Base.metadata,
    Column('course_id', Integer, ForeignKey('courses.id'), primary_key=True),
    Column('prerequisite_id', Integer, ForeignKey('courses.id'), primary_key=True),
    Column('is_required', Boolean, default=True)
)

class Department(Base):
    __tablename__ = 'departments'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(100), unique=True, nullable=False)
    building = Column(String(50))
    
    # TODO: Add relationships to instructors and courses
    
    def __repr__(self):
        return f"<Department(name='{self.name}')>"

class Instructor(Base):
    __tablename__ = 'instructors'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(100), nullable=False)
    email = Column(String(100), unique=True, nullable=False)
    department_id = Column(Integer, ForeignKey('departments.id'))
    hire_date = Column(Date)
    
    # TODO: Add relationships
    
    def __repr__(self):
        return f"<Instructor(name='{self.name}')>"

class Course(Base):
    __tablename__ = 'courses'
    
    id = Column(Integer, primary_key=True)
    code = Column(String(20), unique=True, nullable=False)
    name = Column(String(200), nullable=False)
    credits = Column(Integer, nullable=False)
    department_id = Column(Integer, ForeignKey('departments.id'))
    instructor_id = Column(Integer, ForeignKey('instructors.id'))
    
    # TODO: Add relationships including self-referential prerequisites
    # Use secondary for many-to-many, back_populates for bidirectional
    
    def __repr__(self):
        return f"<Course(code='{self.code}', name='{self.name}')>"

class Student(Base):
    __tablename__ = 'students'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(100), nullable=False)
    email = Column(String(100), unique=True, nullable=False)
    enrollment_date = Column(Date, default=date.today)
    gpa = Column(Float)
    
    # TODO: Add relationship to enrollments
    
    def __repr__(self):
        return f"<Student(name='{self.name}', gpa={self.gpa})>"

class Enrollment(Base):
    """Association object with additional data"""
    __tablename__ = 'enrollments'
    
    student_id = Column(Integer, ForeignKey('students.id'), primary_key=True)
    course_id = Column(Integer, ForeignKey('courses.id'), primary_key=True)
    semester = Column(String(20), nullable=False)  # e.g., "Fall 2024"
    grade = Column(String(2))  # A, B, C, D, F
    enrollment_date = Column(Date, default=date.today)
    
    # TODO: Add relationships to student and course
    
    def __repr__(self):
        return f"<Enrollment(student_id={self.student_id}, course_id={self.course_id}, grade='{self.grade}')>"

Base.metadata.create_all(engine)
```

### Task 2: Loading Strategies (20 points)

Implement functions demonstrating different loading strategies.

**Requirements:**
```python
from sqlalchemy.orm import selectinload, joinedload, subqueryload, lazyload

def demo_lazy_loading(session):
    """Demonstrate N+1 problem with lazy loading"""
    print("\\n=== Lazy Loading (N+1 Problem) ===")
    # TODO: Query students and access their enrollments
    # Count how many queries are executed
    pass

def demo_eager_loading_joined(session):
    """Demonstrate joinedload to avoid N+1"""
    print("\\n=== Joined Load (Single Query) ===")
    # TODO: Use joinedload to load students with enrollments
    # Show that it uses a single query with JOIN
    pass

def demo_eager_loading_selectin(session):
    """Demonstrate selectinload (modern approach)"""
    print("\\n=== Select IN Load (Two Queries) ===")
    # TODO: Use selectinload to load students with enrollments and courses
    # Show that it uses one query per relationship
    pass

def demo_nested_loading(session):
    """Load nested relationships"""
    print("\\n=== Nested Loading ===")
    # TODO: Load students -> enrollments -> courses -> instructor
    # Use chained options
    pass

def compare_loading_performance(session):
    """Compare performance of different strategies"""
    import time
    
    # TODO: Measure time for each strategy
    # Return results dictionary
    pass
```

### Task 3: Complex Queries (30 points)

Implement complex queries with multiple joins and aggregations.

**Requirements:**
```python
from sqlalchemy import func, and_, or_, case, distinct
from sqlalchemy.orm import aliased

def get_student_transcript(session, student_id):
    """
    Get complete transcript for student
    
    Returns: List of courses with grades, credits, and instructors
    """
    # TODO: Join enrollments, courses, instructors
    # Order by semester
    pass

def find_students_by_prerequisites(session, target_course_id):
    """
    Find students who have completed all prerequisites for a course
    
    Args:
        session: Database session
        target_course_id: Course ID to check prerequisites for
    
    Returns:
        List of eligible students
    """
    # TODO: Complex query with subqueries
    # 1. Get all prerequisites for target course
    # 2. Find students who completed all of them
    # 3. Exclude students already enrolled in target course
    pass

def get_department_statistics(session):
    """
    Get statistics for each department
    
    Returns:
        List with: department, student_count, course_count, avg_gpa, instructor_count
    """
    # TODO: Multiple aggregations with group by
    pass

def find_popular_courses(session, min_enrollments=20):
    """Find courses with high enrollment"""
    # TODO: Aggregate enrollment counts
    pass

def get_instructor_workload(session):
    """Calculate teaching load for each instructor"""
    # TODO: Sum credits for courses taught
    # Join courses and instructors
    pass

def find_honor_students(session, min_gpa=3.5, min_credits=12):
    """Find students with high GPA and sufficient credits"""
    # TODO: Filter by GPA
    # Calculate total credits from enrollments
    pass

def get_course_waitlist(session, course_id, capacity=30):
    """
    Get students on waitlist for course
    
    Assumes first N enrollments get in, rest are waitlist
    """
    # TODO: Order by enrollment_date, use limit and offset
    pass
```

### Task 4: Self-Referential Queries (30 points)

Work with prerequisite relationships and course chains.

**Requirements:**
```python
def get_all_prerequisites(session, course_id, recursive=True):
    """
    Get all prerequisites for a course
    
    Args:
        course_id: Course to check
        recursive: If True, get prerequisites of prerequisites
    
    Returns:
        List of prerequisite courses
    """
    # TODO: Handle recursive prerequisite chains
    # Use manual recursion or CTE (if database supports)
    pass

def find_prerequisite_chains(session, course_id):
    """
    Find all possible prerequisite paths to a course
    
    Returns:
        List of course chains (lists)
    """
    # TODO: Find all paths from courses with no prerequisites to target
    pass

def validate_prerequisites(session, student_id, course_id):
    """
    Check if student has completed all prerequisites
    
    Returns:
        (eligible: bool, missing: List[Course])
    """
    # TODO: Get student's completed courses
    # Get required prerequisites
    # Find missing prerequisites
    pass

def suggest_next_courses(session, student_id):
    """
    Suggest courses student is now eligible for
    
    Based on completed courses and prerequisites
    """
    # TODO: Find courses where student completed all prerequisites
    # Exclude courses already taken
    pass

def find_circular_prerequisites(session):
    """
    Detect circular prerequisite dependencies
    
    Returns:
        List of course cycles
    """
    # TODO: Implement cycle detection
    pass
```

## Testing

```python
import unittest
from sqlalchemy.orm import Session

class TestUniversitySystem(unittest.TestCase):
    """Test complex relationships and queries"""
    
    @classmethod
    def setUpClass(cls):
        """Create test database with sample data"""
        cls.engine = create_engine('sqlite:///test_university.db')
        Base.metadata.create_all(cls.engine)
        cls.populate_test_data()
    
    @classmethod
    def populate_test_data(cls):
        """Insert test data"""
        with Session(cls.engine) as session:
            # Create departments
            cs_dept = Department(name='Computer Science', building='Tech Center')
            math_dept = Department(name='Mathematics', building='Science Hall')
            
            # Create instructors
            prof_smith = Instructor(name='Dr. Smith', email='smith@uni.edu', department=cs_dept)
            prof_jones = Instructor(name='Dr. Jones', email='jones@uni.edu', department=math_dept)
            
            # Create courses
            intro_cs = Course(code='CS101', name='Intro to CS', credits=3, 
                            department=cs_dept, instructor=prof_smith)
            data_struct = Course(code='CS201', name='Data Structures', credits=4,
                               department=cs_dept, instructor=prof_smith)
            calculus = Course(code='MATH101', name='Calculus I', credits=4,
                            department=math_dept, instructor=prof_jones)
            
            # Set prerequisites
            data_struct.prerequisites.append(intro_cs)
            
            # Create students
            alice = Student(name='Alice Johnson', email='alice@student.edu', gpa=3.8)
            bob = Student(name='Bob Smith', email='bob@student.edu', gpa=3.2)
            
            # Enroll students
            enroll1 = Enrollment(student=alice, course=intro_cs, semester='Fall 2024', grade='A')
            enroll2 = Enrollment(student=alice, course=calculus, semester='Fall 2024', grade='A')
            enroll3 = Enrollment(student=bob, course=intro_cs, semester='Fall 2024', grade='B')
            
            session.add_all([cs_dept, math_dept, prof_smith, prof_jones,
                           intro_cs, data_struct, calculus, alice, bob])
            session.commit()
    
    def test_relationships(self):
        """Test relationship navigation"""
        with Session(self.engine) as session:
            student = session.query(Student).filter_by(name='Alice Johnson').first()
            
            # Test enrollments
            self.assertGreater(len(student.enrollments), 0)
            
            # Test nested navigation
            first_enrollment = student.enrollments[0]
            self.assertIsNotNone(first_enrollment.course)
            self.assertIsNotNone(first_enrollment.course.instructor)
    
    def test_loading_strategies(self):
        """Test different loading approaches"""
        with Session(self.engine) as session:
            # Test that functions run without error
            demo_lazy_loading(session)
            demo_eager_loading_joined(session)
            demo_eager_loading_selectin(session)
    
    def test_complex_queries(self):
        """Test complex query functions"""
        with Session(self.engine) as session:
            # Transcript
            transcript = get_student_transcript(session, 1)
            self.assertIsInstance(transcript, list)
            
            # Department stats
            stats = get_department_statistics(session)
            self.assertGreater(len(stats), 0)
            
            # Honor students
            honor = find_honor_students(session, min_gpa=3.5)
            self.assertIsInstance(honor, list)
    
    def test_prerequisites(self):
        """Test prerequisite handling"""
        with Session(self.engine) as session:
            # Get course with prerequisites
            course = session.query(Course).filter_by(code='CS201').first()
            
            # Check prerequisites exist
            prereqs = get_all_prerequisites(session, course.id)
            self.assertGreater(len(prereqs), 0)
            
            # Validate student eligibility
            eligible, missing = validate_prerequisites(session, 1, course.id)
            self.assertIsInstance(eligible, bool)
    
    @classmethod
    def tearDownClass(cls):
        """Clean up test database"""
        import os
        if os.path.exists('test_university.db'):
            os.remove('test_university.db')

if __name__ == '__main__':
    unittest.main()
```

## Deliverables

1. **models.py**: Complete schema with all relationships
2. **queries.py**: All query implementations
3. **loading_demos.py**: Loading strategy demonstrations
4. **prerequisites.py**: Prerequisite logic
5. **tests.py**: Comprehensive test suite
6. **performance_report.md**: Analysis of loading strategies

## Evaluation Criteria

| Component | Points | Criteria |
|-----------|--------|----------|
| Task 1 | 20 | Schema correctly models relationships |
| Task 2 | 20 | Loading strategies implemented correctly |
| Task 3 | 30 | Complex queries return accurate results |
| Task 4 | 30 | Prerequisite logic handles edge cases |

**Total: 100 points**

## Bonus Challenges (+30 points)

1. **Course Scheduler** (+15 points): Algorithm to find optimal course schedule avoiding conflicts
2. **GPA Calculator** (+10 points): Calculate semester and cumulative GPA with grade weights
3. **Degree Progress** (+5 points): Track progress toward degree requirements
