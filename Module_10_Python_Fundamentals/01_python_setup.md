# Python Installation & Setup Guide

## 🎯 Objective
Set up a complete Python development environment on Windows for data engineering.

---

## 📋 Prerequisites

- Windows 10/11
- Administrator rights
- 5GB free disk space
- Internet connection

---

## 🔧 Step-by-Step Installation

### Step 1: Install Python 3.11

#### Method 1: Using Microsoft Store (Easiest)
1. Open **Microsoft Store**
2. Search for "Python 3.11"
3. Click **Get** or **Install**
4. Wait for installation to complete

#### Method 2: Using Official Installer (Recommended)
1. Go to https://www.python.org/downloads/
2. Click **Download Python 3.11.x** (latest version)
3. Run the downloaded `.exe` file
4. **IMPORTANT**: ✅ Check "**Add Python to PATH**"
5. Click "Install Now"
6. Wait for installation
7. Click "Close" when done

![Add to PATH](https://docs.python.org/3/_images/win_installer.png)

---

### Step 2: Verify Python Installation

Open **PowerShell** or **Command Prompt**:

```powershell
# Check Python version
python --version
# Expected output: Python 3.11.x

# Check pip (package manager)
pip --version
# Expected output: pip 23.x.x from ...

# Test Python interactive shell
python
>>> print("Hello, Data Engineering!")
Hello, Data Engineering!
>>> exit()
```

✅ **Success!** Python is installed correctly.

---

### Step 3: Install VS Code

1. Download from https://code.visualstudio.com/
2. Run installer
3. **Recommended options**:
   - ✅ Add "Open with Code" to context menu
   - ✅ Register Code as editor for supported file types
   - ✅ Add to PATH
4. Complete installation
5. Launch VS Code

---

### Step 4: Install VS Code Extensions

In VS Code:
1. Click **Extensions** icon (Ctrl+Shift+X)
2. Search and install:
   - **Python** (by Microsoft) - Essential
   - **Pylance** (by Microsoft) - IntelliSense
   - **Python Indent** - Auto-indentation
   - **Error Lens** - Inline error messages
   - **Jupyter** (optional for notebooks)

![VS Code Extensions](../assets/images/vscode_python_extensions.png)

---

### Step 5: Create a Python Project

```powershell
# Create project folder
mkdir C:\Projects\PythonDataEngineering
cd C:\Projects\PythonDataEngineering

# Create virtual environment
python -m venv venv

# Activate virtual environment
.\venv\Scripts\Activate

# Your prompt should now show: (venv)
```

---

### Step 6: Upgrade pip and Install Essential Packages

```powershell
# Upgrade pip
python -m pip install --upgrade pip

# Install essential packages
pip install ipython pytest

# Verify installations
pip list
```

---

## 🐍 Understanding Virtual Environments

### What is a Virtual Environment?
A virtual environment is an isolated Python environment with its own packages, separate from the system Python.

### Why Use Virtual Environments?
- ✅ Avoid package conflicts between projects
- ✅ Easy dependency management
- ✅ Clean project setup
- ✅ Industry best practice

### Commands:

```powershell
# Create venv
python -m venv venv

# Activate (Windows PowerShell)
.\venv\Scripts\Activate

# Activate (Windows Command Prompt)
venv\Scripts\activate.bat

# Deactivate
deactivate

# Delete venv (just delete the folder)
Remove-Item -Recurse -Force venv
```

---

## 🎨 VS Code Configuration

### Create `.vscode/settings.json` in your project:

```json
{
    "python.defaultInterpreterPath": "${workspaceFolder}/venv/Scripts/python.exe",
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": true,
    "python.formatting.provider": "black",
    "python.testing.pytestEnabled": true,
    "editor.formatOnSave": true,
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 1000
}
```

---

## ✅ First Python Script

Create `hello_world.py`:

```python
"""
First Python Script
Author: [Your Name]
Date: 2025-12-07
"""

def main():
    print("Hello, Data Engineering!")
    print("Python version check complete.")
    
    # Your first calculation
    sql_modules = 10
    python_modules = 8
    total = sql_modules + python_modules
    
    print(f"\nTotal curriculum modules: {total}")

if __name__ == "__main__":
    main()
```

### Run the script:

```powershell
# Method 1: From terminal
python hello_world.py

# Method 2: In VS Code
# Right-click in editor → Run Python File in Terminal

# Method 3: VS Code shortcut
# Press F5 (Debug mode)
```

---

## 🔍 Troubleshooting

### Issue 1: "python is not recognized"
**Solution**: Python not added to PATH
```powershell
# Find Python installation
Get-Command python

# If not found, reinstall Python and CHECK "Add to PATH"
```

### Issue 2: Virtual environment activation fails
**Solution**: PowerShell execution policy
```powershell
# Run as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Issue 3: pip install fails with SSL error
**Solution**: Upgrade pip
```powershell
python -m pip install --upgrade pip --trusted-host pypi.org --trusted-host files.pythonhosted.org
```

### Issue 4: VS Code doesn't detect Python
**Solution**: Select interpreter manually
1. Ctrl+Shift+P
2. Type "Python: Select Interpreter"
3. Choose the venv interpreter

---

## 📚 Python Basics - First Concepts

### The Python REPL (Interactive Shell)

```powershell
# Start Python interactive mode
python

>>> 2 + 2
4

>>> name = "Data Engineer"
>>> print(f"Hello, {name}!")
Hello, Data Engineer!

>>> exit()
```

### Comments in Python

```python
# Single-line comment

"""
Multi-line comment
or docstring
"""

# Use comments to explain WHY, not WHAT
x = 5  # Number of retries (WHY this value)
```

### Indentation Matters!

```python
# ✅ Correct
if True:
    print("Indented with 4 spaces")

# ❌ Wrong - IndentationError
if True:
print("Not indented")
```

---

## 🎯 Practice Exercise

Create a file called `setup_test.py`:

```python
"""
Setup Verification Script
Tests that Python environment is correctly configured
"""

import sys
import os

def verify_setup():
    """Verify Python installation and environment"""
    
    print("=== Python Environment Check ===\n")
    
    # Python version
    print(f"Python Version: {sys.version}")
    print(f"Python Executable: {sys.executable}\n")
    
    # Virtual environment check
    if hasattr(sys, 'real_prefix') or (hasattr(sys, 'base_prefix') and sys.base_prefix != sys.prefix):
        print("✅ Running in virtual environment")
    else:
        print("⚠️  Not in virtual environment")
    
    # Package check
    print("\n=== Installed Packages ===")
    try:
        import pip
        installed_packages = pip.get_installed_distributions()
        print(f"Total packages: {len(installed_packages)}")
    except:
        print("pip module not found")
    
    print("\n✅ Setup verification complete!")

if __name__ == "__main__":
    verify_setup()
```

Run it: `python setup_test.py`

---

## 🎓 Key Takeaways

1. ✅ Python is interpreted (no compilation needed)
2. ✅ Indentation defines code blocks
3. ✅ Virtual environments keep projects isolated
4. ✅ pip manages packages
5. ✅ VS Code is the industry-standard IDE

---

## 🚀 Next Steps

- ✅ Python installed and verified
- ✅ VS Code configured
- ✅ First script executed

**Next Section**: 02_variables_datatypes.md

---

**கற்க கசடற** - Learn Flawlessly

