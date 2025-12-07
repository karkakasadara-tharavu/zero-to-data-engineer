"""
Lab 01 Solution: Variables and Data Types
Module 10: Python Fundamentals

Complete solution with explanations
"""

# ============================================================================
# PART 1: Variable Assignment - SOLUTION
# ============================================================================

print("=" * 60)
print("PART 1: Variable Assignment")
print("=" * 60)

# Creating variables for a product
product_name: str = "Wireless Mouse"
product_id: int = 101
price: float = 29.99
in_stock: bool = True
supplier = None  # Type hint optional for None

# Print all variables with labels
print(f"Product Name: {product_name}")
print(f"Product ID: {product_id}")
print(f"Price: ${price:.2f}")  # .2f formats to 2 decimal places
print(f"In Stock: {in_stock}")
print(f"Supplier: {supplier}")

# ============================================================================
# PART 2: Data Types - SOLUTION
# ============================================================================

print("\n" + "=" * 60)
print("PART 2: Data Types")
print("=" * 60)

# Check types of variables
print(f"Type of product_name: {type(product_name)}")  # <class 'str'>
print(f"Type of product_id: {type(product_id)}")      # <class 'int'>
print(f"Type of price: {type(price)}")                # <class 'float'>
print(f"Type of in_stock: {type(in_stock)}")          # <class 'bool'>
print(f"Type of supplier: {type(supplier)}")          # <class 'NoneType'>

# Create variables of each basic type
my_integer = 42
my_float = 3.14159
my_string = "Hello, Python!"
my_boolean = False

print(f"\nmy_integer = {my_integer}, type: {type(my_integer)}")
print(f"my_float = {my_float}, type: {type(my_float)}")
print(f"my_string = {my_string}, type: {type(my_string)}")
print(f"my_boolean = {my_boolean}, type: {type(my_boolean)}")

# ============================================================================
# PART 3: Type Conversion - SOLUTION
# ============================================================================

print("\n" + "=" * 60)
print("PART 3: Type Conversion")
print("=" * 60)

# Given string variables
age_str = "28"
salary_str = "75000.50"
quantity_str = "100"

# Convert to appropriate types
age = int(age_str)           # "28" → 28
salary = float(salary_str)   # "75000.50" → 75000.5
quantity = int(quantity_str) # "100" → 100

# Print converted values and types
print(f"age = {age}, type: {type(age)}")
print(f"salary = {salary}, type: {type(salary)}")
print(f"quantity = {quantity}, type: {type(quantity)}")

# Convert numbers to strings
current_year = 2025
pi_value = 3.14159

year_str = str(current_year)  # 2025 → "2025"
pi_str = str(pi_value)        # 3.14159 → "3.14159"

# Verify they are strings
print(f"\nyear_str = '{year_str}', type: {type(year_str)}")
print(f"pi_str = '{pi_str}', type: {type(pi_str)}")

# Handle conversion errors
invalid_number = "abc123"

try:
    converted = int(invalid_number)
    print(f"Converted: {converted}")
except ValueError as e:
    print(f"\n❌ Conversion Error: Cannot convert '{invalid_number}' to integer")
    print(f"   Error details: {e}")

# ============================================================================
# PART 4: Arithmetic Operations - SOLUTION
# ============================================================================

print("\n" + "=" * 60)
print("PART 4: Arithmetic Operations")
print("=" * 60)

# Given values
item_price = 45.50
tax_rate = 0.08  # 8%
quantity = 5

# Calculate order totals
subtotal = item_price * quantity       # 45.50 * 5 = 227.50
tax_amount = subtotal * tax_rate       # 227.50 * 0.08 = 18.20
grand_total = subtotal + tax_amount    # 227.50 + 18.20 = 245.70

# Print formatted results
print(f"Subtotal: ${subtotal:.2f}")
print(f"Tax (8%): ${tax_amount:.2f}")
print(f"Grand Total: ${grand_total:.2f}")

# Division operations
total_items = 47
boxes = 6

items_per_box = total_items / boxes        # 7.833... (regular division)
full_boxes = total_items // boxes          # 7 (floor division)
remaining_items = total_items % boxes      # 5 (modulus - remainder)

print(f"\nItems per box: {items_per_box:.2f}")
print(f"Full boxes: {full_boxes}")
print(f"Remaining items: {remaining_items}")

# ============================================================================
# PART 5: String Operations - SOLUTION
# ============================================================================

print("\n" + "=" * 60)
print("PART 5: String Operations")
print("=" * 60)

# Given data
first_name = "John"
last_name = "Doe"
age = 30
city = "New York"

# String concatenation
full_name = first_name + " " + last_name  # "John Doe"
print(f"Full Name: {full_name}")

# f-string formatting (RECOMMENDED WAY)
message = f"{first_name} {last_name} is {age} years old and lives in {city}"
print(f"Message: {message}")

# Multi-line strings
address = f"""{full_name}
123 Main Street
{city}, NY 10001"""

print("Address:")
print(address)

# ============================================================================
# PART 6: Boolean Operations - SOLUTION
# ============================================================================

print("\n" + "=" * 60)
print("PART 6: Boolean Operations")
print("=" * 60)

# Customer data
customer_age = 25
account_balance = 5000
has_credit_card = True
credit_score = 720

# Comparison operations
is_adult = customer_age >= 18              # True
has_sufficient_funds = account_balance >= 1000  # True
is_senior = customer_age >= 65             # False

print(f"Is Adult: {is_adult}")
print(f"Has Sufficient Funds: {has_sufficient_funds}")
print(f"Is Senior: {is_senior}")

# Logical operations
# Premium qualification: adult AND credit card AND good credit
qualifies_for_premium = (is_adult and 
                        has_credit_card and 
                        credit_score >= 700)  # True

# Discount eligibility: senior OR has credit card
gets_discount = is_senior or has_credit_card  # True

# Needs review: insufficient funds OR bad credit
needs_review = (not has_sufficient_funds) or (credit_score < 650)  # False

print(f"\nQualifies for Premium: {qualifies_for_premium}")
print(f"Gets Discount: {gets_discount}")
print(f"Needs Review: {needs_review}")

# ============================================================================
# PART 7: Sales Commission Calculator - SOLUTION
# ============================================================================

print("\n" + "=" * 60)
print("PART 7: Sales Commission Calculator")
print("=" * 60)

# Given data
employee_name = "Sarah Johnson"
base_salary = 50000
total_sales = 250000
standard_commission_rate = 0.05  # 5%
bonus_commission_rate = 0.07     # 7%
sales_threshold = 200000
tax_rate = 0.22  # 22%

# Calculate commission on first $200k
commission_standard = sales_threshold * standard_commission_rate  # $10,000

# Calculate commission on sales above $200k
sales_above_threshold = total_sales - sales_threshold  # $50,000
commission_bonus = sales_above_threshold * bonus_commission_rate  # $3,500

# Total commission
total_commission = commission_standard + commission_bonus  # $13,500

# Gross income
gross_income = base_salary + total_commission  # $63,500

# Tax amount
tax_amount = gross_income * tax_rate  # $13,970

# Net income
net_income = gross_income - tax_amount  # $49,530

# Print formatted report
print("=" * 40)
print("SALES COMMISSION REPORT")
print("=" * 40)
print(f"Employee: {employee_name}")
print(f"Base Salary: ${base_salary:,.2f}")
print(f"Total Sales: ${total_sales:,.2f}")
print()
print("Commission Breakdown:")
print(f"- First ${sales_threshold:,} @ {standard_commission_rate*100:.0f}%: ${commission_standard:,.2f}")
print(f"- Remaining ${sales_above_threshold:,} @ {bonus_commission_rate*100:.0f}%: ${commission_bonus:,.2f}")
print(f"- Total Commission: ${total_commission:,.2f}")
print()
print("Income Summary:")
print(f"- Gross Income: ${gross_income:,.2f}")
print(f"- Tax ({tax_rate*100:.0f}%): ${tax_amount:,.2f}")
print(f"- Net Income: ${net_income:,.2f}")
print("=" * 40)

# ============================================================================
# KEY LEARNINGS FROM THIS LAB
# ============================================================================

print("\n" + "=" * 60)
print("KEY LEARNINGS")
print("=" * 60)

print("""
1. ✅ Variable Naming: Use descriptive, snake_case names
2. ✅ Type Hints: Add type annotations for clarity
3. ✅ Type Conversion: Use int(), float(), str() carefully
4. ✅ f-strings: Best way to format strings in Python
5. ✅ Boolean Logic: Combine conditions with and, or, not
6. ✅ Formatting: Use :.2f for currency, :, for thousands
7. ✅ Error Handling: Always validate before type conversion

Common Formatting Patterns:
- Currency: ${value:,.2f}
- Percentage: {value*100:.1f}%
- Thousands separator: {value:,}
- Zero-padded: {value:05d} → 00042
""")

# ============================================================================
# VERIFICATION
# ============================================================================

print("\n" + "=" * 60)
print("SOLUTION VERIFICATION")
print("=" * 60)

# Verify key calculations
assert subtotal == 227.50, "Subtotal calculation error"
assert tax_amount == 18.20, "Tax calculation error"
assert grand_total == 245.70, "Grand total calculation error"
assert full_boxes == 7, "Floor division error"
assert remaining_items == 5, "Modulus error"
assert full_name == "John Doe", "String concatenation error"
assert qualifies_for_premium == True, "Boolean logic error"
assert total_commission == 13500.00, "Commission calculation error"
assert net_income == 49530.00, "Net income calculation error"

print("✅ All assertions passed!")
print("🎉 Lab 01 completed successfully!")

# ============================================================================
# NEXT STEPS
# ============================================================================

print("\n" + "=" * 60)
print("NEXT STEPS")
print("=" * 60)

print("""
Congratulations on completing Lab 01! 🎉

You've mastered:
✅ Creating and using variables
✅ Working with different data types
✅ Type conversion and error handling
✅ Arithmetic and boolean operations
✅ String formatting with f-strings

Ready for Lab 02: Lists and List Comprehensions!

கற்க கசடற - Learn Flawlessly
""")
