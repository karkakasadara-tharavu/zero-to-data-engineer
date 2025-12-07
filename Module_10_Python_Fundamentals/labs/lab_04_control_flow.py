"""
Module 10 - Lab 04: Control Flow and Conditionals
=================================================
Practice working with if/elif/else statements.

கற்க கசடற - Learn Flawlessly

Estimated Time: 60 minutes
Concepts: Conditionals, comparison operators, logical operators, nested if
"""

# Part 1: Basic Conditionals (10 minutes)
# ---------------------------------------
# TODO: Get user's age and check if they can vote (18+)


# TODO: Check if a number is positive, negative, or zero


# TODO: Check if a number is even or odd


# TODO: Check if a year is a leap year
# Leap year rules: divisible by 4, except years divisible by 100 (unless also divisible by 400)


# Part 2: Comparison Operators (10 minutes)
# -----------------------------------------
# TODO: Compare two numbers and print which is greater


# TODO: Check if a string is equal to another (case-insensitive)


# TODO: Check if a value is within a range (10-20 inclusive)


# TODO: Check if a list is empty


# Part 3: Logical Operators (15 minutes)
# --------------------------------------
# TODO: Check if a number is between 1 and 100 (inclusive) using and


# TODO: Check if a character is a vowel using or


# TODO: Check if a number is NOT divisible by 3


# TODO: Check login credentials (username and password)


# Part 4: Ternary Operator (10 minutes)
# -------------------------------------
# TODO: Assign 'adult' or 'minor' based on age using ternary operator


# TODO: Get the maximum of two numbers using ternary


# TODO: Convert boolean to 'Yes'/'No' string using ternary


# Part 5: Nested Conditionals (15 minutes)
# ----------------------------------------
# TODO: Grade calculator based on score
# A: 90-100, B: 80-89, C: 70-79, D: 60-69, F: below 60


# TODO: Ticket pricing based on age
# Child (under 12): $10, Adult (12-64): $20, Senior (65+): $15


# TODO: BMI calculator and category
# Underweight: <18.5, Normal: 18.5-24.9, Overweight: 25-29.9, Obese: 30+


# Part 6: Truthiness and Falsiness (10 minutes)
# ---------------------------------------------
# TODO: Check if a list has items (using truthiness)


# TODO: Check if a string is not empty


# TODO: Check if a number is non-zero


# TODO: Use short-circuit evaluation with or


# Part 7: Practical Challenge - User Validation System (15 minutes)
# -----------------------------------------------------------------
"""
Create a user registration validation system.

Requirements:
1. Validate username (6-20 characters, alphanumeric)
2. Validate password (8+ characters, has uppercase, lowercase, digit)
3. Validate email (contains @ and .)
4. Validate age (13-120)
5. Return validation results and errors
"""

def validate_username(username):
    """
    Validate username.
    
    Args:
        username: Username string
    
    Returns:
        tuple: (is_valid: bool, error_message: str or None)
    """
    pass  # Replace with your code


def validate_password(password):
    """
    Validate password.
    
    Args:
        password: Password string
    
    Returns:
        tuple: (is_valid: bool, error_message: str or None)
    """
    pass  # Replace with your code


def validate_email(email):
    """
    Validate email address.
    
    Args:
        email: Email string
    
    Returns:
        tuple: (is_valid: bool, error_message: str or None)
    """
    pass  # Replace with your code


def validate_age(age):
    """
    Validate age.
    
    Args:
        age: Age integer
    
    Returns:
        tuple: (is_valid: bool, error_message: str or None)
    """
    pass  # Replace with your code


def validate_user(username, password, email, age):
    """
    Validate all user information.
    
    Args:
        username: Username string
        password: Password string
        email: Email string
        age: Age integer
    
    Returns:
        tuple: (is_valid: bool, list of error messages)
    """
    pass  # Replace with your code


# TODO: Test the validation system
# Uncomment to test:
# is_valid, errors = validate_user("john123", "Pass123", "john@email.com", 25)
# if is_valid:
#     print("✅ User validation passed!")
# else:
#     print("❌ Validation errors:")
#     for error in errors:
#         print(f"  - {error}")


# ============================================================================
# DO NOT MODIFY BELOW THIS LINE - Verification Code
# ============================================================================

def verify_lab_04():
    """
    Verify that all lab exercises are completed correctly.
    
    Returns:
        None
    """
    print("\n" + "="*50)
    print("Lab 04 Verification")
    print("="*50)
    
    try:
        # Verify functions exist
        assert callable(validate_username), "❌ validate_username not created"
        assert callable(validate_password), "❌ validate_password not created"
        assert callable(validate_email), "❌ validate_email not created"
        assert callable(validate_age), "❌ validate_age not created"
        assert callable(validate_user), "❌ validate_user not created"
        
        print("✅ All validation functions created")
        
        # Test validation functions
        valid, _ = validate_username("john123")
        assert valid == True, "❌ validate_username: valid username rejected"
        
        valid, _ = validate_username("ab")
        assert valid == False, "❌ validate_username: too short username accepted"
        
        print("✅ Username validation working")
        
        valid, _ = validate_password("Pass123word")
        assert valid == True, "❌ validate_password: valid password rejected"
        
        valid, _ = validate_password("short")
        assert valid == False, "❌ validate_password: short password accepted"
        
        print("✅ Password validation working")
        
        valid, _ = validate_email("user@example.com")
        assert valid == True, "❌ validate_email: valid email rejected"
        
        valid, _ = validate_email("invalid-email")
        assert valid == False, "❌ validate_email: invalid email accepted"
        
        print("✅ Email validation working")
        
        valid, _ = validate_age(25)
        assert valid == True, "❌ validate_age: valid age rejected"
        
        valid, _ = validate_age(10)
        assert valid == False, "❌ validate_age: underage accepted"
        
        print("✅ Age validation working")
        
        # Test complete validation
        is_valid, errors = validate_user("john123", "Pass123", "john@email.com", 25)
        assert is_valid == True, "❌ validate_user: valid user rejected"
        
        is_valid, errors = validate_user("ab", "short", "bad-email", 10)
        assert is_valid == False, "❌ validate_user: invalid user accepted"
        assert len(errors) >= 4, "❌ validate_user: not all errors detected"
        
        print("✅ Complete validation working")
        
    except (AssertionError, NameError, TypeError) as e:
        print(f"❌ {e}")
        return
    
    print("="*50)
    print("✅ All verifications passed!")
    print("="*50)

# Uncomment to run verification
# verify_lab_04()
