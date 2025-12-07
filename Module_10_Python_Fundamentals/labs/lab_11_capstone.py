"""
Module 10 - Lab 11: Final Capstone Project
==========================================
Build a complete Python application.

கற்க கசடற - Learn Flawlessly

Estimated Time: 120 minutes
"""

"""
PROJECT: Contact and Task Management System

Requirements:
1. Manage contacts (add, update, delete, search)
2. Manage tasks (add, complete, prioritize)
3. Store data in JSON files
4. Comprehensive error handling
5. User-friendly menu interface
6. Data validation
7. Search and filter capabilities
8. Export reports to CSV

This project integrates all concepts from Module 10:
- Data structures (lists, dicts, sets)
- Control flow (if/elif/else, loops)
- Functions (parameters, return values)
- Strings (formatting, manipulation)
- Files (read/write CSV/JSON)
- Error handling (try/except, custom exceptions)
"""

import json
import csv
from datetime import datetime
from pathlib import Path

# TODO: Implement the complete contact and task management system

class ContactManager:
    """Manage contacts with CRUD operations."""
    
    def __init__(self, data_file="contacts.json"):
        self.data_file = data_file
        self.contacts = {}
        self.load_contacts()
    
    def load_contacts(self):
        """Load contacts from JSON file."""
        pass
    
    def save_contacts(self):
        """Save contacts to JSON file."""
        pass
    
    def add_contact(self, name, phone, email):
        """Add a new contact."""
        pass
    
    def update_contact(self, contact_id, **kwargs):
        """Update contact information."""
        pass
    
    def delete_contact(self, contact_id):
        """Delete a contact."""
        pass
    
    def search_contacts(self, query):
        """Search contacts by name, phone, or email."""
        pass
    
    def list_all_contacts(self):
        """List all contacts."""
        pass


class TaskManager:
    """Manage tasks with priority and status."""
    
    def __init__(self, data_file="tasks.json"):
        self.data_file = data_file
        self.tasks = {}
        self.load_tasks()
    
    def load_tasks(self):
        """Load tasks from JSON file."""
        pass
    
    def save_tasks(self):
        """Save tasks to JSON file."""
        pass
    
    def add_task(self, title, priority="medium"):
        """Add a new task."""
        pass
    
    def complete_task(self, task_id):
        """Mark task as complete."""
        pass
    
    def delete_task(self, task_id):
        """Delete a task."""
        pass
    
    def list_tasks(self, filter_by=None):
        """List tasks with optional filter."""
        pass


def main():
    """Main application loop."""
    contact_mgr = ContactManager()
    task_mgr = TaskManager()
    
    while True:
        print("\n" + "="*50)
        print("Contact & Task Management System")
        print("="*50)
        print("1. Manage Contacts")
        print("2. Manage Tasks")
        print("3. Export Report")
        print("4. Exit")
        print("="*50)
        
        choice = input("Enter choice (1-4): ")
        
        if choice == "1":
            # Contact management menu
            pass
        elif choice == "2":
            # Task management menu
            pass
        elif choice == "3":
            # Export report
            pass
        elif choice == "4":
            print("Goodbye!")
            break
        else:
            print("Invalid choice. Please try again.")


if __name__ == "__main__":
    main()


# TODO: Write comprehensive tests for all functionality
def test_capstone_project():
    """Test all features of the capstone project."""
    print("Running capstone tests...")
    
    # Test contact management
    # Test task management
    # Test file operations
    # Test error handling
    # Test search functionality
    
    print("✅ All tests passed!")


# Uncomment to run tests
# test_capstone_project()
