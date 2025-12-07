# Lab 10 Solution: OOP Capstone - Student Information System

"""Complete solution for OOP Capstone Project.
Demonstrates: Complete OOP Integration - Inheritance, Composition, 
Patterns (Observer, Strategy, Factory), ABC, Properties, Special Methods"""

from abc import ABC, abstractmethod
from datetime import datetime
from typing import List, Dict, Optional
import json


# ===== PART 1: PERSON HIERARCHY =====

class Person(ABC):
    _id_counter = 1000
    
    def __init__(self, name: str, email: str, phone: str):
        self.person_id = Person._id_counter
        Person._id_counter += 1
        self.name = name
        self._email = email
        self.phone = phone
        self.created_at = datetime.now()
    
    @property
    def email(self):
        return self._email
    
    @email.setter
    def email(self, value):
        if '@' not in value or '.' not in value:
            raise ValueError("Invalid email format")
        self._email = value
    
    @abstractmethod
    def get_role(self) -> str:
        pass
    
    def __str__(self):
        return f"{self.name} ({self.get_role()}) - ID: {self.person_id}"
    
    def __repr__(self):
        return f"Person(id={self.person_id}, name='{self.name}')"


class Student(Person):
    def __init__(self, name: str, email: str, phone: str, major: str):
        super().__init__(name, email, phone)
        self.major = major
        self.gpa = 0.0
        self.enrolled_courses = []
        self.grades = {}
    
    def get_role(self) -> str:
        return "Student"
    
    def enroll_course(self, course):
        if course not in self.enrolled_courses:
            self.enrolled_courses.append(course)
    
    def drop_course(self, course):
        if course in self.enrolled_courses:
            self.enrolled_courses.remove(course)
    
    def add_grade(self, course_code: str, grade: float):
        self.grades[course_code] = grade
        self.calculate_gpa()
    
    def calculate_gpa(self):
        if self.grades:
            self.gpa = sum(self.grades.values()) / len(self.grades)


class Instructor(Person):
    def __init__(self, name: str, email: str, phone: str, department: str):
        super().__init__(name, email, phone)
        self.department = department
        self.courses_teaching = []
    
    def get_role(self) -> str:
        return "Instructor"
    
    def assign_course(self, course):
        if course not in self.courses_teaching:
            self.courses_teaching.append(course)
    
    def remove_course(self, course):
        if course in self.courses_teaching:
            self.courses_teaching.remove(course)


class Administrator(Person):
    def __init__(self, name: str, email: str, phone: str, title: str):
        super().__init__(name, email, phone)
        self.title = title
        self.access_level = "admin"
    
    def get_role(self) -> str:
        return f"Administrator ({self.title})"


# ===== PART 2: COURSE SYSTEM WITH COMPOSITION =====

class ScheduleComponent:
    def __init__(self, days: List[str], start_time: str, end_time: str, room: str):
        self.days = days
        self.start_time = start_time
        self.end_time = end_time
        self.room = room
    
    def get_schedule_string(self) -> str:
        days_str = ", ".join(self.days)
        return f"{days_str} {self.start_time}-{self.end_time} in {self.room}"


class GradingComponent:
    def __init__(self, max_students: int = 30):
        self.max_students = max_students
        self.enrolled_students = {}
        self.grades = {}
    
    def add_student(self, student: Student) -> bool:
        if len(self.enrolled_students) >= self.max_students:
            return False
        self.enrolled_students[student.person_id] = student
        return True
    
    def assign_grade(self, student_id: int, grade: float):
        if student_id in self.enrolled_students:
            self.grades[student_id] = grade
    
    def get_average_grade(self) -> float:
        if not self.grades:
            return 0.0
        return sum(self.grades.values()) / len(self.grades)


class Course:
    def __init__(self, course_code: str, title: str, credits: int,
                 schedule: ScheduleComponent, grading: GradingComponent):
        self.course_code = course_code
        self.title = title
        self.credits = credits
        self.schedule = schedule
        self.grading = grading
        self.instructor = None
    
    def assign_instructor(self, instructor: Instructor):
        self.instructor = instructor
        instructor.assign_course(self)
    
    def enroll_student(self, student: Student) -> bool:
        if self.grading.add_student(student):
            student.enroll_course(self)
            return True
        return False
    
    def __str__(self):
        return f"{self.course_code}: {self.title} ({self.credits} credits)"


# ===== PART 3: GRADING STRATEGIES =====

class GradingStrategy(ABC):
    @abstractmethod
    def calculate_final_grade(self, raw_score: float) -> float:
        pass
    
    @abstractmethod
    def get_letter_grade(self, score: float) -> str:
        pass


class StandardGradingStrategy(GradingStrategy):
    def calculate_final_grade(self, raw_score: float) -> float:
        return min(100, max(0, raw_score))
    
    def get_letter_grade(self, score: float) -> str:
        if score >= 90: return "A"
        elif score >= 80: return "B"
        elif score >= 70: return "C"
        elif score >= 60: return "D"
        else: return "F"


class CurveGradingStrategy(GradingStrategy):
    def __init__(self, curve_factor: float = 5.0):
        self.curve_factor = curve_factor
    
    def calculate_final_grade(self, raw_score: float) -> float:
        curved = raw_score + self.curve_factor
        return min(100, max(0, curved))
    
    def get_letter_grade(self, score: float) -> str:
        curved = self.calculate_final_grade(score)
        if curved >= 90: return "A"
        elif curved >= 80: return "B"
        elif curved >= 70: return "C"
        elif curved >= 60: return "D"
        else: return "F"


class PassFailGradingStrategy(GradingStrategy):
    def __init__(self, passing_score: float = 60.0):
        self.passing_score = passing_score
    
    def calculate_final_grade(self, raw_score: float) -> float:
        return 100 if raw_score >= self.passing_score else 0
    
    def get_letter_grade(self, score: float) -> str:
        return "P" if score >= self.passing_score else "F"


# ===== PART 4: OBSERVER PATTERN =====

class Observer(ABC):
    @abstractmethod
    def update(self, message: str):
        pass


class Subject:
    def __init__(self):
        self._observers = []
    
    def attach(self, observer: Observer):
        if observer not in self._observers:
            self._observers.append(observer)
    
    def detach(self, observer: Observer):
        if observer in self._observers:
            self._observers.remove(observer)
    
    def notify(self, message: str):
        for observer in self._observers:
            observer.update(message)


class EmailNotifier(Observer):
    def update(self, message: str):
        print(f"📧 EMAIL: {message}")


class SMSNotifier(Observer):
    def update(self, message: str):
        print(f"📱 SMS: {message}")


class LogNotifier(Observer):
    def __init__(self):
        self.logs = []
    
    def update(self, message: str):
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_entry = f"[{timestamp}] {message}"
        self.logs.append(log_entry)
        print(f"📝 LOG: {log_entry}")


# ===== PART 5: UNIVERSITY SYSTEM =====

class UniversitySystem(Subject):
    def __init__(self, name: str):
        super().__init__()
        self.name = name
        self.students = {}
        self.instructors = {}
        self.administrators = {}
        self.courses = {}
        self.grading_strategy = StandardGradingStrategy()
    
    def add_student(self, student: Student):
        self.students[student.person_id] = student
        self.notify(f"New student registered: {student.name} (ID: {student.person_id})")
    
    def add_instructor(self, instructor: Instructor):
        self.instructors[instructor.person_id] = instructor
        self.notify(f"New instructor added: {instructor.name} (Department: {instructor.department})")
    
    def add_course(self, course: Course):
        self.courses[course.course_code] = course
        self.notify(f"New course created: {course.course_code} - {course.title}")
    
    def enroll_student_in_course(self, student_id: int, course_code: str) -> bool:
        if student_id not in self.students or course_code not in self.courses:
            return False
        
        student = self.students[student_id]
        course = self.courses[course_code]
        
        if course.enroll_student(student):
            self.notify(f"{student.name} enrolled in {course.course_code}")
            return True
        return False
    
    def assign_grade(self, student_id: int, course_code: str, raw_score: float):
        if student_id not in self.students or course_code not in self.courses:
            return
        
        student = self.students[student_id]
        course = self.courses[course_code]
        
        final_grade = self.grading_strategy.calculate_final_grade(raw_score)
        letter_grade = self.grading_strategy.get_letter_grade(raw_score)
        
        course.grading.assign_grade(student_id, final_grade)
        student.add_grade(course_code, final_grade)
        
        self.notify(f"Grade assigned: {student.name} - {course_code}: {final_grade:.1f} ({letter_grade})")
    
    def set_grading_strategy(self, strategy: GradingStrategy):
        self.grading_strategy = strategy
        self.notify(f"Grading strategy changed to {strategy.__class__.__name__}")
    
    def generate_transcript(self, student_id: int) -> str:
        if student_id not in self.students:
            return "Student not found"
        
        student = self.students[student_id]
        transcript = f"\n{'='*50}\n"
        transcript += f"TRANSCRIPT - {self.name}\n"
        transcript += f"{'='*50}\n"
        transcript += f"Student: {student.name}\n"
        transcript += f"ID: {student.person_id}\n"
        transcript += f"Major: {student.major}\n"
        transcript += f"GPA: {student.gpa:.2f}\n"
        transcript += f"\nCourses:\n"
        
        for course_code, grade in student.grades.items():
            letter = self.grading_strategy.get_letter_grade(grade)
            transcript += f"  {course_code}: {grade:.1f} ({letter})\n"
        
        transcript += f"{'='*50}\n"
        return transcript
    
    def get_statistics(self) -> Dict:
        return {
            'total_students': len(self.students),
            'total_instructors': len(self.instructors),
            'total_courses': len(self.courses),
            'average_class_size': sum(len(c.grading.enrolled_students) 
                                     for c in self.courses.values()) / max(len(self.courses), 1)
        }


# ===== TESTING =====

if __name__ == "__main__":
    print("=== Initializing University System ===")
    
    # Create university
    university = UniversitySystem("Tech University")
    
    # Add observers
    email_notifier = EmailNotifier()
    sms_notifier = SMSNotifier()
    log_notifier = LogNotifier()
    
    university.attach(email_notifier)
    university.attach(sms_notifier)
    university.attach(log_notifier)
    
    print("\n=== Adding People ===")
    
    # Create students
    alice = Student("Alice Johnson", "alice@tech.edu", "555-0101", "Computer Science")
    bob = Student("Bob Smith", "bob@tech.edu", "555-0102", "Data Science")
    
    # Create instructor
    prof_jones = Instructor("Dr. Sarah Jones", "sjones@tech.edu", "555-0201", "Computer Science")
    
    # Create administrator
    admin = Administrator("John Admin", "admin@tech.edu", "555-0301", "Registrar")
    
    # Add to university
    university.add_student(alice)
    university.add_student(bob)
    university.add_instructor(prof_jones)
    
    print("\n=== Creating Courses ===")
    
    # Create course components
    schedule = ScheduleComponent(["Mon", "Wed", "Fri"], "10:00 AM", "11:30 AM", "CS-101")
    grading = GradingComponent(max_students=30)
    
    # Create course
    cs101 = Course("CS101", "Introduction to Programming", 3, schedule, grading)
    cs101.assign_instructor(prof_jones)
    
    university.add_course(cs101)
    
    print("\n=== Enrolling Students ===")
    university.enroll_student_in_course(alice.person_id, "CS101")
    university.enroll_student_in_course(bob.person_id, "CS101")
    
    print("\n=== Assigning Grades (Standard) ===")
    university.assign_grade(alice.person_id, "CS101", 92)
    university.assign_grade(bob.person_id, "CS101", 78)
    
    print("\n=== Switching to Curve Grading ===")
    university.set_grading_strategy(CurveGradingStrategy(curve_factor=10))
    university.assign_grade(alice.person_id, "CS101", 85)
    
    print("\n=== Generating Transcript ===")
    print(university.generate_transcript(alice.person_id))
    
    print("\n=== University Statistics ===")
    stats = university.get_statistics()
    for key, value in stats.items():
        print(f"{key}: {value}")
    
    print("\n=== Notification Log ===")
    print(f"Total notifications logged: {len(log_notifier.logs)}")
