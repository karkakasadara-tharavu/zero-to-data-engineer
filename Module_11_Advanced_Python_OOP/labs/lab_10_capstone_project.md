# Lab 10: OOP Capstone Project - Complete Application

**Difficulty**: ⭐⭐⭐⭐⭐ (Advanced - Comprehensive)  
**Estimated Time**: 120-180 minutes  
**Topics**: All OOP Concepts, Design Patterns, Real-World Application

---

## 🎯 Project Overview

Build a comprehensive **Student Information System (SIS)** that integrates all OOP concepts you've learned. This capstone project brings together:
- Classes and objects
- Inheritance hierarchies
- Polymorphism
- Encapsulation with properties
- Abstract base classes
- Special methods
- Composition
- Design patterns
- Error handling

---

## 📋 System Requirements

### Part 1: Person Hierarchy (Inheritance & ABC)

**Abstract Base: Person**
- Abstract properties: `role`, `id_prefix`
- Attributes: `name`, `email`, `age`, `id` (auto-generated)
- Abstract method: `get_responsibilities()`
- Methods: `send_email(message)`, `update_profile(**kwargs)`
- Implement `__str__`, `__repr__`, `__eq__`

**Student** (inherits from Person):
- Properties: `gpa` (computed from grades)
- Attributes: `grades` (dict: course -> grade), `major`, `year`
- Methods: `enroll_course(course)`, `add_grade(course, grade)`, `calculate_gpa()`
- Implement grade validation (0.0-4.0 scale)

**Instructor** (inherits from Person):
- Attributes: `department`, `courses_taught`, `salary`
- Properties: `annual_salary` (with property decorator)
- Methods: `assign_course(course)`, `grade_student(student, course, grade)`

**Administrator** (inherits from Person):
- Attributes: `department`, `clearance_level`
- Methods: `generate_report(report_type)`, `manage_user(user, action)`

### Part 2: Course System (Composition)

**Course Class**:
- Attributes: `course_code`, `course_name`, `credits`, `instructor`, `enrolled_students`, `max_capacity`
- Components:
  - `ScheduleComponent` - manages time slots
  - `GradingComponent` - manages grading policies
- Methods:
  - `enroll_student(student)` - with capacity check
  - `drop_student(student)`
  - `get_enrollment_count()`
  - `is_full()`
  - `calculate_average_grade()`
- Implement `__len__` for enrollment count
- Implement `__contains__` to check student enrollment

**CourseFactory**:
- Create different course types with pre-configured settings
- Methods: `create_lecture()`, `create_lab()`, `create_seminar()`

### Part 3: Grading System (Strategy Pattern)

**GradingStrategy** (Abstract Base):
- Abstract method: `calculate_letter_grade(numeric_grade)`

**Concrete Strategies**:
- `StandardGradingStrategy` - 90+=A, 80+=B, 70+=C, 60+=D
- `CurveGradingStrategy` - Adjusts based on class average
- `PassFailGradingStrategy` - Only Pass(>=60) or Fail

### Part 4: Notification System (Observer Pattern)

**Subject** (for notifications):
- Methods: `attach(observer)`, `detach(observer)`, `notify()`

**Observer** (Abstract Base):
- Abstract method: `update(message)`

**Concrete Observers**:
- `EmailNotifier` - Sends email notifications
- `SMSNotifier` - Sends SMS notifications
- `LogNotifier` - Logs notifications to file

### Part 5: University Manager (Main System)

**UniversitySystem Class**:
- Manages all students, instructors, courses
- Private attributes with encapsulation
- Methods:
  - `register_student(name, email, major, year)`
  - `hire_instructor(name, email, department, salary)`
  - `create_course(code, name, credits, instructor)`
  - `enroll_student_in_course(student_id, course_code)`
  - `submit_grade(instructor, student, course, grade)`
  - `generate_transcript(student_id)`
  - `get_course_roster(course_code)`
  - `get_department_courses(department)`
  - `calculate_department_gpa(department)`
  - `export_data_to_json(filename)`
  - `import_data_from_json(filename)`

### Part 6: Advanced Features

**Database Simulation**:
- `DatabaseConnection` - Context manager for data operations
- Implement `__enter__` and `__exit__`

**Transaction Log**:
- Use special methods to make it iterable and indexable
- Track all system operations with timestamps

**Search System**:
- Search students by name, major, GPA range
- Search courses by department, instructor, availability
- Use descriptors for search criteria validation

---

## 💻 Starter Code Structure

```python
from abc import ABC, abstractmethod
from datetime import datetime
import json
from typing import List, Dict, Optional

# ========== Base Classes ==========

class Person(ABC):
    """Abstract base class for all people in the system"""
    
    _id_counter = 10000
    
    def __init__(self, name: str, email: str, age: int):
        self.id = self._generate_id()
        self.name = name
        self._email = None
        self.email = email  # Use property setter
        self.age = age
        self.created_at = datetime.now()
    
    @classmethod
    def _generate_id(cls):
        """Generate unique ID"""
        cls._id_counter += 1
        return f"{cls.id_prefix}{cls._id_counter}"
    
    @property
    @abstractmethod
    def role(self):
        """Return role type"""
        pass
    
    @property
    @abstractmethod
    def id_prefix(self):
        """Return ID prefix for this person type"""
        pass
    
    @property
    def email(self):
        return self._email
    
    @email.setter
    def email(self, value):
        """Validate and set email"""
        # TODO: Implement email validation
        pass
    
    @abstractmethod
    def get_responsibilities(self):
        """Return list of responsibilities"""
        pass
    
    def send_email(self, message):
        """Send email to this person"""
        # TODO: Simulate email sending
        pass
    
    def update_profile(self, **kwargs):
        """Update profile attributes"""
        # TODO: Update allowed attributes
        pass
    
    def __str__(self):
        return f"{self.name} ({self.role}) - {self.id}"
    
    def __repr__(self):
        return f"{self.__class__.__name__}(id='{self.id}', name='{self.name}')"
    
    def __eq__(self, other):
        if not isinstance(other, Person):
            return False
        return self.id == other.id

class Student(Person):
    """Student class"""
    
    id_prefix = "STU"
    
    def __init__(self, name: str, email: str, age: int, major: str, year: int):
        super().__init__(name, email, age)
        self.major = major
        self.year = year
        self.grades = {}  # course_code -> grade
        self.enrolled_courses = []
    
    @property
    def role(self):
        return "Student"
    
    @property
    def gpa(self):
        """Calculate GPA from grades"""
        # TODO: Calculate GPA from self.grades
        pass
    
    def enroll_course(self, course):
        """Enroll in a course"""
        # TODO: Add course to enrolled_courses
        pass
    
    def add_grade(self, course_code, grade):
        """Add grade for a course"""
        # TODO: Validate grade (0.0-4.0) and add
        pass
    
    def calculate_gpa(self):
        """Calculate current GPA"""
        # TODO: Average of all grades
        pass
    
    def get_responsibilities(self):
        return ["Attend classes", "Complete assignments", "Take exams"]

class Instructor(Person):
    """Instructor class"""
    
    id_prefix = "INS"
    
    def __init__(self, name: str, email: str, age: int, department: str, salary: float):
        super().__init__(name, email, age)
        self.department = department
        self._salary = salary
        self.courses_taught = []
    
    @property
    def role(self):
        return "Instructor"
    
    @property
    def annual_salary(self):
        """Get annual salary"""
        return self._salary * 12
    
    @annual_salary.setter
    def annual_salary(self, value):
        """Set monthly salary from annual"""
        self._salary = value / 12
    
    def assign_course(self, course):
        """Assign instructor to course"""
        # TODO: Add course to courses_taught
        pass
    
    def grade_student(self, student, course, grade):
        """Assign grade to student"""
        # TODO: Validate instructor teaches course
        # TODO: Add grade to student
        pass
    
    def get_responsibilities(self):
        return ["Teach courses", "Grade assignments", "Hold office hours"]

# TODO: Implement Administrator class

# ========== Course System ==========

class ScheduleComponent:
    """Component for managing course schedule"""
    
    def __init__(self, days: List[str], start_time: str, end_time: str):
        # TODO: Implement schedule management
        pass

class GradingComponent:
    """Component for managing grading policies"""
    
    def __init__(self, strategy):
        self.strategy = strategy
    
    def calculate_grade(self, numeric_grade):
        return self.strategy.calculate_letter_grade(numeric_grade)

class Course:
    """Course class using composition"""
    
    def __init__(self, course_code: str, course_name: str, credits: int, 
                 instructor: Instructor, max_capacity: int = 30):
        self.course_code = course_code
        self.course_name = course_name
        self.credits = credits
        self.instructor = instructor
        self.max_capacity = max_capacity
        self.enrolled_students = []
        self.grades = {}  # student_id -> grade
        
        # Components
        self.schedule = None
        self.grading = GradingComponent(StandardGradingStrategy())
    
    def enroll_student(self, student: Student):
        """Enroll student in course"""
        # TODO: Check capacity and enroll
        pass
    
    def drop_student(self, student: Student):
        """Drop student from course"""
        # TODO: Remove from enrolled_students
        pass
    
    def get_enrollment_count(self):
        """Return number of enrolled students"""
        return len(self.enrolled_students)
    
    def is_full(self):
        """Check if course is at capacity"""
        return len(self.enrolled_students) >= self.max_capacity
    
    def calculate_average_grade(self):
        """Calculate average grade for course"""
        # TODO: Calculate average from self.grades
        pass
    
    def __len__(self):
        """Return enrollment count"""
        return self.get_enrollment_count()
    
    def __contains__(self, student):
        """Check if student is enrolled"""
        return student in self.enrolled_students
    
    def __str__(self):
        return f"{self.course_code}: {self.course_name} ({len(self)}/{self.max_capacity})"

# ========== Grading Strategies ==========

class GradingStrategy(ABC):
    """Abstract grading strategy"""
    
    @abstractmethod
    def calculate_letter_grade(self, numeric_grade: float) -> str:
        pass

class StandardGradingStrategy(GradingStrategy):
    """Standard 90/80/70/60 grading"""
    
    def calculate_letter_grade(self, numeric_grade: float) -> str:
        # TODO: Implement standard grading scale
        pass

class CurveGradingStrategy(GradingStrategy):
    """Curve-based grading"""
    
    def __init__(self, class_average: float):
        self.class_average = class_average
    
    def calculate_letter_grade(self, numeric_grade: float) -> str:
        # TODO: Implement curved grading
        pass

# TODO: Implement PassFailGradingStrategy

# ========== Observer Pattern ==========

class Observer(ABC):
    """Abstract observer for notifications"""
    
    @abstractmethod
    def update(self, message: str):
        pass

class EmailNotifier(Observer):
    """Email notification observer"""
    
    def update(self, message: str):
        print(f"📧 Email: {message}")

# TODO: Implement SMSNotifier and LogNotifier

class Subject:
    """Subject for observer pattern"""
    
    def __init__(self):
        self._observers = []
    
    def attach(self, observer: Observer):
        # TODO: Add observer
        pass
    
    def detach(self, observer: Observer):
        # TODO: Remove observer
        pass
    
    def notify(self, message: str):
        # TODO: Notify all observers
        pass

# ========== Main System ==========

class UniversitySystem(Subject):
    """Main university management system"""
    
    def __init__(self, university_name: str):
        super().__init__()
        self.university_name = university_name
        self.__students = {}  # student_id -> Student
        self.__instructors = {}  # instructor_id -> Instructor
        self.__courses = {}  # course_code -> Course
        self._transaction_log = []
    
    def register_student(self, name: str, email: str, age: int, major: str, year: int) -> Student:
        """Register new student"""
        # TODO: Create student and add to __students
        # TODO: Log transaction
        # TODO: Notify observers
        pass
    
    def hire_instructor(self, name: str, email: str, age: int, department: str, salary: float) -> Instructor:
        """Hire new instructor"""
        # TODO: Similar to register_student
        pass
    
    def create_course(self, code: str, name: str, credits: int, instructor: Instructor) -> Course:
        """Create new course"""
        # TODO: Create course and add to __courses
        pass
    
    def enroll_student_in_course(self, student_id: str, course_code: str):
        """Enroll student in course"""
        # TODO: Get student and course, perform enrollment
        pass
    
    def submit_grade(self, instructor: Instructor, student: Student, course: Course, grade: float):
        """Submit grade for student"""
        # TODO: Validate instructor teaches course
        # TODO: Add grade to student and course
        pass
    
    def generate_transcript(self, student_id: str) -> Dict:
        """Generate student transcript"""
        # TODO: Create comprehensive transcript
        pass
    
    def get_course_roster(self, course_code: str) -> List[Student]:
        """Get list of students in course"""
        # TODO: Return enrolled students
        pass
    
    def export_data_to_json(self, filename: str):
        """Export all data to JSON"""
        # TODO: Serialize and save data
        pass
    
    def import_data_from_json(self, filename: str):
        """Import data from JSON"""
        # TODO: Load and deserialize data
        pass
    
    def __str__(self):
        return f"{self.university_name} - {len(self.__students)} students, {len(self.__courses)} courses"

# ========== Testing ==========

if __name__ == "__main__":
    print("=" * 60)
    print("STUDENT INFORMATION SYSTEM - CAPSTONE PROJECT")
    print("=" * 60)
    
    # Create university system
    university = UniversitySystem("Tech University")
    
    # Attach observers
    university.attach(EmailNotifier())
    
    # Register students
    print("\n=== Registering Students ===")
    student1 = university.register_student("Alice Johnson", "alice@tech.edu", 20, "Computer Science", 2)
    student2 = university.register_student("Bob Smith", "bob@tech.edu", 19, "Mathematics", 1)
    
    # Hire instructors
    print("\n=== Hiring Instructors ===")
    prof_jones = university.hire_instructor("Dr. Jones", "jones@tech.edu", 45, "CS", 8000)
    prof_smith = university.hire_instructor("Dr. Smith", "smith@tech.edu", 50, "Math", 8500)
    
    # Create courses
    print("\n=== Creating Courses ===")
    cs101 = university.create_course("CS101", "Intro to Programming", 3, prof_jones)
    cs201 = university.create_course("CS201", "Data Structures", 4, prof_jones)
    math101 = university.create_course("MATH101", "Calculus I", 4, prof_smith)
    
    # Enroll students
    print("\n=== Enrolling Students ===")
    university.enroll_student_in_course(student1.id, "CS101")
    university.enroll_student_in_course(student1.id, "CS201")
    university.enroll_student_in_course(student2.id, "MATH101")
    
    # Submit grades
    print("\n=== Submitting Grades ===")
    university.submit_grade(prof_jones, student1, cs101, 3.7)
    university.submit_grade(prof_jones, student1, cs201, 3.9)
    
    # Generate transcript
    print("\n=== Student Transcript ===")
    transcript = university.generate_transcript(student1.id)
    print(json.dumps(transcript, indent=2))
    
    # Course roster
    print("\n=== Course Roster: CS101 ===")
    roster = university.get_course_roster("CS101")
    for student in roster:
        print(f"  {student}")
    
    # System summary
    print("\n=== System Summary ===")
    print(university)
```

---

## 🎯 Expected Deliverables

1. **Complete Implementation** (500-800 lines):
   - All classes fully implemented
   - All TODOs completed
   - Comprehensive error handling

2. **Test Suite**:
   - Test all major functionality
   - Edge case handling
   - Invalid input testing

3. **Documentation**:
   - Docstrings for all classes and methods
   - Inline comments for complex logic
   - README with usage examples

4. **Design Document**:
   - Class diagram
   - Explanation of design decisions
   - OOP principles applied

---

## ✅ Grading Rubric

**Implementation (60 points)**:
- [ ] All classes implemented correctly (20 pts)
- [ ] All abstract methods implemented (10 pts)
- [ ] Properties and encapsulation (10 pts)
- [ ] Special methods (__str__, __eq__, etc.) (10 pts)
- [ ] Error handling and validation (10 pts)

**Design Patterns (20 points)**:
- [ ] Inheritance hierarchy (5 pts)
- [ ] Composition (5 pts)
- [ ] Strategy pattern (5 pts)
- [ ] Observer pattern (5 pts)

**Code Quality (10 points)**:
- [ ] Clean, readable code (3 pts)
- [ ] Proper naming conventions (2 pts)
- [ ] Documentation (3 pts)
- [ ] DRY principle (2 pts)

**Testing (10 points)**:
- [ ] Comprehensive test cases (5 pts)
- [ ] Edge case handling (3 pts)
- [ ] Output validation (2 pts)

---

## 🚀 Extension Ideas

1. **Web Interface**: Build Flask/Django web UI
2. **Database**: Integrate with real database (SQLite/PostgreSQL)
3. **Authentication**: Add secure login system
4. **Reports**: Generate PDF transcripts and reports
5. **Analytics**: Student performance analytics and visualizations
6. **Scheduling**: Automatic course scheduling system
7. **Financial**: Add tuition and payment tracking
8. **Mobile App**: Create mobile interface

---

## 💡 OOP Concepts Checklist

Make sure your implementation demonstrates:
- [ ] Classes and Objects
- [ ] Instance and Class Attributes
- [ ] Instance, Class, and Static Methods
- [ ] Inheritance (single and multiple)
- [ ] Polymorphism
- [ ] Encapsulation (private attributes, properties)
- [ ] Abstract Base Classes
- [ ] Special/Magic Methods
- [ ] Composition
- [ ] Design Patterns

---

## 📚 Resources

Review these theory sections:
- All sections 01-10 from Module 11
- Focus on `09_abstract_base_classes.md`
- Review `10_composition_vs_inheritance.md`
- Refer to `07_special_methods.md` for operator overloading

---

**Good luck with your capstone project! 🎓🚀**

This is your opportunity to demonstrate mastery of all OOP concepts in a real-world application!
