"""
Module 10 - Lab 11 Solution: Capstone Project
==============================================
Contact and Task Management System - Complete Implementation

கற்க கசடற - Learn Flawlessly

Estimated Time: 120 minutes
Project: Full-featured CLI application with data persistence
"""

import json
import csv
import re
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Optional

# ============================================================================
# Custom Exceptions
# ============================================================================

class ContactError(Exception):
    """Base exception for contact operations."""
    pass

class DuplicateContactError(ContactError):
    """Raised when trying to add duplicate contact."""
    pass

class ContactNotFoundError(ContactError):
    """Raised when contact is not found."""
    pass

class TaskError(Exception):
    """Base exception for task operations."""
    pass

class InvalidDateError(TaskError):
    """Raised when date format is invalid."""
    pass

# ============================================================================
# Data Models
# ============================================================================

class Contact:
    """Represents a contact with validation."""
    
    def __init__(self, name: str, email: str, phone: str, category: str = "General"):
        self.id = None  # Set by manager
        self.name = self._validate_name(name)
        self.email = self._validate_email(email)
        self.phone = self._validate_phone(phone)
        self.category = category.strip().title()
        self.created_at = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        self.notes = []
    
    def _validate_name(self, name: str) -> str:
        """Validate contact name."""
        if not name or not name.strip():
            raise ValueError("Name cannot be empty")
        if len(name.strip()) < 2:
            raise ValueError("Name must be at least 2 characters")
        return name.strip().title()
    
    def _validate_email(self, email: str) -> str:
        """Validate email format."""
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(pattern, email):
            raise ValueError(f"Invalid email format: {email}")
        return email.lower()
    
    def _validate_phone(self, phone: str) -> str:
        """Validate and format phone number."""
        # Remove all non-digits
        digits = re.sub(r'\D', '', phone)
        
        if len(digits) != 10:
            raise ValueError("Phone must be 10 digits")
        
        # Format as XXX-XXX-XXXX
        return f"{digits[:3]}-{digits[3:6]}-{digits[6:]}"
    
    def add_note(self, note: str):
        """Add a note to contact."""
        self.notes.append({
            'text': note,
            'timestamp': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        })
    
    def to_dict(self) -> Dict:
        """Convert to dictionary for serialization."""
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'phone': self.phone,
            'category': self.category,
            'created_at': self.created_at,
            'notes': self.notes
        }
    
    @classmethod
    def from_dict(cls, data: Dict) -> 'Contact':
        """Create contact from dictionary."""
        contact = cls(
            data['name'],
            data['email'],
            data.get('phone', '0000000000'),
            data.get('category', 'General')
        )
        contact.id = data.get('id')
        contact.created_at = data.get('created_at', contact.created_at)
        contact.notes = data.get('notes', [])
        return contact
    
    def __str__(self) -> str:
        """String representation."""
        return f"{self.name} ({self.email}) - {self.phone}"
    
    def __repr__(self) -> str:
        """Debug representation."""
        return f"Contact(id={self.id}, name={self.name}, email={self.email})"


class Task:
    """Represents a task with validation."""
    
    VALID_STATUSES = ['pending', 'in_progress', 'completed']
    VALID_PRIORITIES = ['low', 'medium', 'high']
    
    def __init__(self, title: str, description: str = "", due_date: str = None,
                 priority: str = "medium", status: str = "pending"):
        self.id = None  # Set by manager
        self.title = self._validate_title(title)
        self.description = description.strip()
        self.due_date = self._validate_date(due_date) if due_date else None
        self.priority = self._validate_priority(priority)
        self.status = self._validate_status(status)
        self.created_at = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        self.completed_at = None
    
    def _validate_title(self, title: str) -> str:
        """Validate task title."""
        if not title or not title.strip():
            raise ValueError("Title cannot be empty")
        if len(title.strip()) < 3:
            raise ValueError("Title must be at least 3 characters")
        return title.strip()
    
    def _validate_date(self, date_str: str) -> str:
        """Validate date format (YYYY-MM-DD)."""
        try:
            datetime.strptime(date_str, '%Y-%m-%d')
            return date_str
        except ValueError:
            raise InvalidDateError(f"Invalid date format: {date_str}. Use YYYY-MM-DD")
    
    def _validate_priority(self, priority: str) -> str:
        """Validate priority level."""
        priority = priority.lower()
        if priority not in self.VALID_PRIORITIES:
            raise ValueError(f"Priority must be one of {self.VALID_PRIORITIES}")
        return priority
    
    def _validate_status(self, status: str) -> str:
        """Validate task status."""
        status = status.lower()
        if status not in self.VALID_STATUSES:
            raise ValueError(f"Status must be one of {self.VALID_STATUSES}")
        return status
    
    def mark_completed(self):
        """Mark task as completed."""
        self.status = 'completed'
        self.completed_at = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    def to_dict(self) -> Dict:
        """Convert to dictionary for serialization."""
        return {
            'id': self.id,
            'title': self.title,
            'description': self.description,
            'due_date': self.due_date,
            'priority': self.priority,
            'status': self.status,
            'created_at': self.created_at,
            'completed_at': self.completed_at
        }
    
    @classmethod
    def from_dict(cls, data: Dict) -> 'Task':
        """Create task from dictionary."""
        task = cls(
            data['title'],
            data.get('description', ''),
            data.get('due_date'),
            data.get('priority', 'medium'),
            data.get('status', 'pending')
        )
        task.id = data.get('id')
        task.created_at = data.get('created_at', task.created_at)
        task.completed_at = data.get('completed_at')
        return task
    
    def __str__(self) -> str:
        """String representation."""
        return f"[{self.priority.upper()}] {self.title} - {self.status}"
    
    def __repr__(self) -> str:
        """Debug representation."""
        return f"Task(id={self.id}, title={self.title}, status={self.status})"

# ============================================================================
# Management Classes
# ============================================================================

class ContactManager:
    """Manages contact operations."""
    
    def __init__(self, data_file: str = "contacts.json"):
        self.data_file = Path(data_file)
        self.contacts: List[Contact] = []
        self.next_id = 1
        self.load_data()
    
    def add_contact(self, contact: Contact) -> int:
        """Add new contact."""
        # Check for duplicates
        if self.find_by_email(contact.email):
            raise DuplicateContactError(f"Contact with email {contact.email} already exists")
        
        contact.id = self.next_id
        self.contacts.append(contact)
        self.next_id += 1
        self.save_data()
        
        return contact.id
    
    def get_contact(self, contact_id: int) -> Optional[Contact]:
        """Get contact by ID."""
        for contact in self.contacts:
            if contact.id == contact_id:
                return contact
        return None
    
    def find_by_email(self, email: str) -> Optional[Contact]:
        """Find contact by email."""
        email = email.lower()
        for contact in self.contacts:
            if contact.email == email:
                return contact
        return None
    
    def search_contacts(self, query: str) -> List[Contact]:
        """Search contacts by name, email, or phone."""
        query = query.lower()
        results = []
        
        for contact in self.contacts:
            if (query in contact.name.lower() or
                query in contact.email.lower() or
                query in contact.phone):
                results.append(contact)
        
        return results
    
    def get_by_category(self, category: str) -> List[Contact]:
        """Get all contacts in a category."""
        category = category.strip().title()
        return [c for c in self.contacts if c.category == category]
    
    def update_contact(self, contact_id: int, **kwargs) -> bool:
        """Update contact fields."""
        contact = self.get_contact(contact_id)
        if not contact:
            raise ContactNotFoundError(f"Contact ID {contact_id} not found")
        
        if 'name' in kwargs:
            contact.name = contact._validate_name(kwargs['name'])
        if 'email' in kwargs:
            # Check if new email conflicts with existing
            new_email = kwargs['email'].lower()
            existing = self.find_by_email(new_email)
            if existing and existing.id != contact_id:
                raise DuplicateContactError(f"Email {new_email} already in use")
            contact.email = contact._validate_email(kwargs['email'])
        if 'phone' in kwargs:
            contact.phone = contact._validate_phone(kwargs['phone'])
        if 'category' in kwargs:
            contact.category = kwargs['category'].strip().title()
        
        self.save_data()
        return True
    
    def delete_contact(self, contact_id: int) -> bool:
        """Delete contact."""
        contact = self.get_contact(contact_id)
        if not contact:
            raise ContactNotFoundError(f"Contact ID {contact_id} not found")
        
        self.contacts.remove(contact)
        self.save_data()
        return True
    
    def get_all_contacts(self) -> List[Contact]:
        """Get all contacts."""
        return self.contacts.copy()
    
    def get_categories(self) -> List[str]:
        """Get all unique categories."""
        return sorted(set(c.category for c in self.contacts))
    
    def save_data(self):
        """Save contacts to JSON file."""
        data = {
            'contacts': [c.to_dict() for c in self.contacts],
            'next_id': self.next_id,
            'last_saved': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        }
        
        with open(self.data_file, 'w') as f:
            json.dump(data, f, indent=2)
    
    def load_data(self):
        """Load contacts from JSON file."""
        if not self.data_file.exists():
            return
        
        try:
            with open(self.data_file, 'r') as f:
                data = json.load(f)
            
            self.contacts = [Contact.from_dict(c) for c in data.get('contacts', [])]
            self.next_id = data.get('next_id', 1)
        
        except json.JSONDecodeError:
            print(f"Warning: Could not load {self.data_file}. Starting fresh.")
    
    def export_to_csv(self, filename: str):
        """Export contacts to CSV."""
        fieldnames = ['id', 'name', 'email', 'phone', 'category', 'created_at']
        
        with open(filename, 'w', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            
            for contact in self.contacts:
                row = {k: contact.to_dict()[k] for k in fieldnames}
                writer.writerow(row)


class TaskManager:
    """Manages task operations."""
    
    def __init__(self, data_file: str = "tasks.json"):
        self.data_file = Path(data_file)
        self.tasks: List[Task] = []
        self.next_id = 1
        self.load_data()
    
    def add_task(self, task: Task) -> int:
        """Add new task."""
        task.id = self.next_id
        self.tasks.append(task)
        self.next_id += 1
        self.save_data()
        
        return task.id
    
    def get_task(self, task_id: int) -> Optional[Task]:
        """Get task by ID."""
        for task in self.tasks:
            if task.id == task_id:
                return task
        return None
    
    def search_tasks(self, query: str) -> List[Task]:
        """Search tasks by title or description."""
        query = query.lower()
        results = []
        
        for task in self.tasks:
            if (query in task.title.lower() or
                query in task.description.lower()):
                results.append(task)
        
        return results
    
    def get_by_status(self, status: str) -> List[Task]:
        """Get tasks by status."""
        status = status.lower()
        return [t for t in self.tasks if t.status == status]
    
    def get_by_priority(self, priority: str) -> List[Task]:
        """Get tasks by priority."""
        priority = priority.lower()
        return [t for t in self.tasks if t.priority == priority]
    
    def update_task(self, task_id: int, **kwargs) -> bool:
        """Update task fields."""
        task = self.get_task(task_id)
        if not task:
            raise TaskError(f"Task ID {task_id} not found")
        
        if 'title' in kwargs:
            task.title = task._validate_title(kwargs['title'])
        if 'description' in kwargs:
            task.description = kwargs['description'].strip()
        if 'due_date' in kwargs:
            task.due_date = task._validate_date(kwargs['due_date']) if kwargs['due_date'] else None
        if 'priority' in kwargs:
            task.priority = task._validate_priority(kwargs['priority'])
        if 'status' in kwargs:
            task.status = task._validate_status(kwargs['status'])
            if task.status == 'completed' and not task.completed_at:
                task.completed_at = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        
        self.save_data()
        return True
    
    def complete_task(self, task_id: int) -> bool:
        """Mark task as completed."""
        task = self.get_task(task_id)
        if not task:
            raise TaskError(f"Task ID {task_id} not found")
        
        task.mark_completed()
        self.save_data()
        return True
    
    def delete_task(self, task_id: int) -> bool:
        """Delete task."""
        task = self.get_task(task_id)
        if not task:
            raise TaskError(f"Task ID {task_id} not found")
        
        self.tasks.remove(task)
        self.save_data()
        return True
    
    def get_all_tasks(self) -> List[Task]:
        """Get all tasks."""
        return self.tasks.copy()
    
    def save_data(self):
        """Save tasks to JSON file."""
        data = {
            'tasks': [t.to_dict() for t in self.tasks],
            'next_id': self.next_id,
            'last_saved': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        }
        
        with open(self.data_file, 'w') as f:
            json.dump(data, f, indent=2)
    
    def load_data(self):
        """Load tasks from JSON file."""
        if not self.data_file.exists():
            return
        
        try:
            with open(self.data_file, 'r') as f:
                data = json.load(f)
            
            self.tasks = [Task.from_dict(t) for t in data.get('tasks', [])]
            self.next_id = data.get('next_id', 1)
        
        except json.JSONDecodeError:
            print(f"Warning: Could not load {self.data_file}. Starting fresh.")

# ============================================================================
# Application
# ============================================================================

class ContactTaskApp:
    """Main application class."""
    
    def __init__(self):
        self.contact_manager = ContactManager()
        self.task_manager = TaskManager()
    
    def display_menu(self):
        """Display main menu."""
        print("\n" + "="*60)
        print("CONTACT & TASK MANAGEMENT SYSTEM")
        print("="*60)
        print("\nCONTACTS:")
        print("  1. Add Contact")
        print("  2. View All Contacts")
        print("  3. Search Contacts")
        print("  4. Update Contact")
        print("  5. Delete Contact")
        print("  6. Export Contacts to CSV")
        print("\nTASKS:")
        print("  7. Add Task")
        print("  8. View All Tasks")
        print("  9. View Tasks by Status")
        print(" 10. Complete Task")
        print(" 11. Delete Task")
        print("\nREPORTS:")
        print(" 12. Generate Summary Report")
        print("\n  0. Exit")
        print("-"*60)
    
    def add_contact_interactive(self):
        """Interactive contact addition."""
        print("\n--- Add New Contact ---")
        try:
            name = input("Name: ").strip()
            email = input("Email: ").strip()
            phone = input("Phone (10 digits): ").strip()
            category = input("Category (default: General): ").strip() or "General"
            
            contact = Contact(name, email, phone, category)
            contact_id = self.contact_manager.add_contact(contact)
            
            print(f"✓ Contact added successfully! ID: {contact_id}")
        
        except (ValueError, DuplicateContactError) as e:
            print(f"✗ Error: {e}")
    
    def view_all_contacts(self):
        """Display all contacts."""
        contacts = self.contact_manager.get_all_contacts()
        
        if not contacts:
            print("\nNo contacts found.")
            return
        
        print(f"\n--- All Contacts ({len(contacts)}) ---")
        print(f"{'ID':<5} {'Name':<25} {'Email':<30} {'Phone':<15} {'Category':<15}")
        print("-" * 95)
        
        for contact in sorted(contacts, key=lambda c: c.name):
            print(f"{contact.id:<5} {contact.name:<25} {contact.email:<30} {contact.phone:<15} {contact.category:<15}")
    
    def add_task_interactive(self):
        """Interactive task addition."""
        print("\n--- Add New Task ---")
        try:
            title = input("Title: ").strip()
            description = input("Description (optional): ").strip()
            due_date = input("Due date (YYYY-MM-DD, optional): ").strip() or None
            priority = input("Priority (low/medium/high, default: medium): ").strip() or "medium"
            
            task = Task(title, description, due_date, priority)
            task_id = self.task_manager.add_task(task)
            
            print(f"✓ Task added successfully! ID: {task_id}")
        
        except (ValueError, InvalidDateError) as e:
            print(f"✗ Error: {e}")
    
    def view_all_tasks(self):
        """Display all tasks."""
        tasks = self.task_manager.get_all_tasks()
        
        if not tasks:
            print("\nNo tasks found.")
            return
        
        print(f"\n--- All Tasks ({len(tasks)}) ---")
        print(f"{'ID':<5} {'Title':<30} {'Priority':<10} {'Status':<15} {'Due Date':<12}")
        print("-" * 75)
        
        for task in sorted(tasks, key=lambda t: (t.status, t.priority)):
            due = task.due_date or "N/A"
            print(f"{task.id:<5} {task.title[:29]:<30} {task.priority.upper():<10} {task.status.upper():<15} {due:<12}")
    
    def generate_report(self):
        """Generate comprehensive summary report."""
        contacts = self.contact_manager.get_all_contacts()
        tasks = self.task_manager.get_all_tasks()
        
        print("\n" + "="*60)
        print("SUMMARY REPORT")
        print("="*60)
        
        # Contact statistics
        print(f"\nCONTACTS:")
        print(f"  Total: {len(contacts)}")
        
        categories = self.contact_manager.get_categories()
        if categories:
            print(f"  By Category:")
            for cat in categories:
                count = len(self.contact_manager.get_by_category(cat))
                print(f"    {cat}: {count}")
        
        # Task statistics
        print(f"\nTASKS:")
        print(f"  Total: {len(tasks)}")
        
        pending = self.task_manager.get_by_status('pending')
        in_progress = self.task_manager.get_by_status('in_progress')
        completed = self.task_manager.get_by_status('completed')
        
        print(f"  By Status:")
        print(f"    Pending: {len(pending)}")
        print(f"    In Progress: {len(in_progress)}")
        print(f"    Completed: {len(completed)}")
        
        high_priority = self.task_manager.get_by_priority('high')
        if high_priority:
            print(f"\n  High Priority Tasks: {len(high_priority)}")
            for task in high_priority[:5]:
                print(f"    - {task.title}")
        
        print("="*60)
    
    def run(self):
        """Run the application."""
        print("\n🚀 Welcome to Contact & Task Management System")
        print("கற்க கசடற - Learn Flawlessly\n")
        
        while True:
            self.display_menu()
            
            try:
                choice = input("\nSelect option: ").strip()
                
                if choice == '1':
                    self.add_contact_interactive()
                elif choice == '2':
                    self.view_all_contacts()
                elif choice == '7':
                    self.add_task_interactive()
                elif choice == '8':
                    self.view_all_tasks()
                elif choice == '12':
                    self.generate_report()
                elif choice == '0':
                    print("\nThank you for using the system. Goodbye!")
                    break
                else:
                    print("\n✗ Invalid option. Please try again.")
            
            except KeyboardInterrupt:
                print("\n\nExiting...")
                break
            except Exception as e:
                print(f"\n✗ Unexpected error: {e}")

# ============================================================================
# Demo and Testing
# ============================================================================

def run_demo():
    """Run automated demonstration."""
    print("="*70)
    print("CAPSTONE PROJECT DEMONSTRATION")
    print("="*70)
    
    # Initialize managers with test files
    contact_mgr = ContactManager("demo_contacts.json")
    task_mgr = TaskManager("demo_tasks.json")
    
    print("\n1. Adding Sample Contacts...")
    try:
        contacts_data = [
            ("Alice Johnson", "alice@example.com", "2125551234", "Work"),
            ("Bob Smith", "bob@example.com", "3105555678", "Personal"),
            ("Charlie Davis", "charlie@example.com", "4155559012", "Work"),
            ("Diana Prince", "diana@example.com", "6175553456", "Personal"),
        ]
        
        for name, email, phone, category in contacts_data:
            contact = Contact(name, email, phone, category)
            contact_id = contact_mgr.add_contact(contact)
            print(f"  ✓ Added: {name} (ID: {contact_id})")
    
    except Exception as e:
        print(f"  ✗ Error: {e}")
    
    print("\n2. Adding Sample Tasks...")
    try:
        tasks_data = [
            ("Complete project report", "Write final report for Q1", "2024-02-15", "high", "pending"),
            ("Team meeting", "Weekly sync with team", "2024-01-20", "medium", "pending"),
            ("Code review", "Review pull requests", None, "high", "in_progress"),
            ("Update documentation", "Update API docs", "2024-01-25", "low", "pending"),
        ]
        
        for title, desc, due, priority, status in tasks_data:
            task = Task(title, desc, due, priority, status)
            task_id = task_mgr.add_task(task)
            print(f"  ✓ Added: {title} (ID: {task_id})")
    
    except Exception as e:
        print(f"  ✗ Error: {e}")
    
    print("\n3. Searching Contacts...")
    results = contact_mgr.search_contacts("alice")
    print(f"  Found {len(results)} contact(s) matching 'alice':")
    for contact in results:
        print(f"    - {contact}")
    
    print("\n4. Filtering Tasks by Priority...")
    high_tasks = task_mgr.get_by_priority("high")
    print(f"  Found {len(high_tasks)} high-priority task(s):")
    for task in high_tasks:
        print(f"    - {task}")
    
    print("\n5. Completing a Task...")
    if task_mgr.tasks:
        task = task_mgr.tasks[0]
        task_mgr.complete_task(task.id)
        print(f"  ✓ Completed: {task.title}")
    
    print("\n6. Exporting Contacts to CSV...")
    csv_file = "demo_contacts_export.csv"
    contact_mgr.export_to_csv(csv_file)
    print(f"  ✓ Exported to {csv_file}")
    
    print("\n7. Generating Statistics...")
    print(f"  Total Contacts: {len(contact_mgr.contacts)}")
    print(f"  Total Tasks: {len(task_mgr.tasks)}")
    print(f"  Completed Tasks: {len(task_mgr.get_by_status('completed'))}")
    print(f"  Pending Tasks: {len(task_mgr.get_by_status('pending'))}")
    
    categories = contact_mgr.get_categories()
    print(f"\n  Contacts by Category:")
    for cat in categories:
        count = len(contact_mgr.get_by_category(cat))
        print(f"    {cat}: {count}")
    
    print("\n8. Cleanup...")
    # Clean up demo files
    for file in ["demo_contacts.json", "demo_tasks.json", "demo_contacts_export.csv"]:
        path = Path(file)
        if path.exists():
            path.unlink()
            print(f"  ✓ Removed: {file}")
    
    print("\n" + "="*70)
    print("DEMONSTRATION COMPLETE")
    print("="*70)

# ============================================================================
# Main Execution
# ============================================================================

if __name__ == "__main__":
    print("\nModule 10 - Capstone Project")
    print("Contact & Task Management System")
    print("\nRunning demonstration...\n")
    
    run_demo()
    
    print("\n" + "="*70)
    print("🎉 CAPSTONE PROJECT COMPLETE!")
    print("="*70)
    print("\n📚 Skills Demonstrated:")
    print("  ✓ Object-Oriented Programming (Classes, Inheritance)")
    print("  ✓ Data Validation and Error Handling")
    print("  ✓ Custom Exceptions")
    print("  ✓ File I/O (JSON, CSV)")
    print("  ✓ Regular Expressions")
    print("  ✓ Data Structures (Lists, Dictionaries)")
    print("  ✓ String Processing")
    print("  ✓ Date/Time Handling")
    print("  ✓ Type Hints")
    print("  ✓ Documentation (Docstrings)")
    print("\n🎯 Application Features:")
    print("  ✓ Contact Management (CRUD operations)")
    print("  ✓ Task Management with priorities")
    print("  ✓ Search and filtering")
    print("  ✓ Data persistence (JSON)")
    print("  ✓ CSV export functionality")
    print("  ✓ Comprehensive error handling")
    print("  ✓ Input validation")
    print("  ✓ Duplicate detection")
    print("\n🚀 Ready for Module 11: Advanced Python & OOP!")
    print("="*70)
