"""
Module 10 - Lab 05 Solution: Loops and Iteration
================================================
Complete solutions with explanations.

கற்க கசடற - Learn Flawlessly

Estimated Time: 60 minutes
Concepts: for loops, while loops, range(), break, continue, nested loops
"""

# Part 1: Basic for Loops (10 minutes)
print("Part 1: Basic for Loops")
print("-" * 40)

# Print numbers 1-10 using for loop
print("Numbers 1-10:")
for i in range(1, 11):
    print(i, end=' ')
print("\n")

# Print each character in a string
text = "Python"
print(f"Characters in '{text}':")
for char in text:
    print(f"  '{char}'")

# Calculate sum of numbers 1-100
total = 0
for num in range(1, 101):
    total += num
print(f"\nSum of 1-100: {total}")
# Formula check: n*(n+1)/2 = 100*101/2 = 5050
print(f"Formula check: {100 * 101 // 2}")

# Print items with indices using enumerate()
fruits = ['apple', 'banana', 'cherry', 'date']
print("\nFruits with indices:")
for index, fruit in enumerate(fruits):
    print(f"  [{index}] {fruit}")

# Start enumerate from 1
print("\nFruits (starting from 1):")
for index, fruit in enumerate(fruits, 1):
    print(f"  {index}. {fruit}")

print()

# Part 2: While Loops (10 minutes)
print("Part 2: While Loops")
print("-" * 40)

# Print numbers 1-10 using while loop
print("Numbers 1-10 (while loop):")
count = 1
while count <= 10:
    print(count, end=' ')
    count += 1
print("\n")

# Find first number divisible by both 3 and 7
num = 1
while True:
    if num % 3 == 0 and num % 7 == 0:
        print(f"First number divisible by 3 and 7: {num}")
        break
    num += 1

# Alternative: calculate directly
# LCM of 3 and 7 = 21 (they're coprime)
print(f"Direct calculation: {3 * 7}")

# Guessing game simulation
import random
secret = random.randint(1, 10)
attempts = 0
max_attempts = 5

print(f"\nGuessing Game (secret number: {secret})")
print("Simulating guesses...")

guesses = [3, 7, 5, 8, secret]  # Simulated guesses
for guess in guesses:
    attempts += 1
    print(f"  Attempt {attempts}: Guessed {guess}", end='')
    
    if guess == secret:
        print(" → Correct! 🎉")
        break
    elif guess < secret:
        print(" → Too low")
    else:
        print(" → Too high")
    
    if attempts >= max_attempts:
        print(f"  Out of attempts! The number was {secret}")
        break

print()

# Part 3: Break and Continue (15 minutes)
print("Part 3: Break and Continue")
print("-" * 40)

# Find first prime number greater than 20
def is_prime(n):
    """Check if number is prime."""
    if n < 2:
        return False
    for i in range(2, int(n ** 0.5) + 1):
        if n % i == 0:
            return False
    return True

num = 21
while True:
    if is_prime(num):
        print(f"First prime > 20: {num}")
        break
    num += 1

# Print all numbers 1-20 except multiples of 3
print("\nNumbers 1-20 (skip multiples of 3):")
for num in range(1, 21):
    if num % 3 == 0:
        continue  # Skip this iteration
    print(num, end=' ')
print()

# Process list until finding a negative number
numbers = [5, 12, -3, 8, 15, -7, 20]
print(f"\nProcessing: {numbers}")
print("Summing until negative number:")
total = 0
for num in numbers:
    if num < 0:
        print(f"  Found negative number: {num}")
        print(f"  Stopping. Sum so far: {total}")
        break
    total += num
    print(f"  Added {num}, total: {total}")

print()

# Part 4: Nested Loops (15 minutes)
print("Part 4: Nested Loops")
print("-" * 40)

# Print multiplication table (1-10)
print("Multiplication Table (5x5):")
print("     ", end='')
for i in range(1, 6):
    print(f"{i:4}", end='')
print("\n" + "  " + "-" * 24)

for i in range(1, 6):
    print(f"{i:2} | ", end='')
    for j in range(1, 6):
        print(f"{i*j:4}", end='')
    print()

# Create a pattern
print("\nPattern:")
for i in range(1, 6):
    print('*' * i)

# Reverse pattern
print("\nReverse Pattern:")
for i in range(5, 0, -1):
    print('*' * i)

# Pyramid pattern
print("\nPyramid:")
height = 5
for i in range(1, height + 1):
    spaces = ' ' * (height - i)
    stars = '*' * (2 * i - 1)
    print(spaces + stars)

# Find all pairs that sum to 10
print("\nPairs that sum to 10:")
target = 10
pairs = []
for i in range(target + 1):
    for j in range(i, target + 1):  # Start from i to avoid duplicates
        if i + j == target:
            pairs.append((i, j))
            print(f"  {i} + {j} = {target}")

print()

# Part 5: Loop with else (10 minutes)
print("Part 5: Loop with else")
print("-" * 40)

# Search for an item in a list
shopping_list = ['milk', 'bread', 'eggs', 'butter']
search_item = 'eggs'

print(f"Searching for '{search_item}' in {shopping_list}")
for item in shopping_list:
    if item == search_item:
        print(f"  Found '{search_item}'!")
        break
else:
    # This runs only if loop completed WITHOUT break
    print(f"  '{search_item}' not found")

# Search for non-existent item
search_item = 'cheese'
print(f"\nSearching for '{search_item}':")
for item in shopping_list:
    if item == search_item:
        print(f"  Found '{search_item}'!")
        break
else:
    print(f"  '{search_item}' not found in list")

# Check if a number is prime using for-else
def check_prime(n):
    """Check if number is prime using for-else."""
    if n < 2:
        return False
    
    for i in range(2, int(n ** 0.5) + 1):
        if n % i == 0:
            print(f"    {n} is divisible by {i}")
            return False
    else:
        # Loop completed without finding divisor
        return True

print("\nPrime checking:")
test_numbers = [17, 18, 19, 20, 23]
for num in test_numbers:
    print(f"  {num}: ", end='')
    if check_prime(num):
        print("Prime ✓")
    else:
        print("Not prime")

print()

# Part 6: List Comprehensions vs Loops (10 minutes)
print("Part 6: List Comprehensions vs Loops")
print("-" * 40)

# Create list of squares using loop
squares_loop = []
for x in range(1, 11):
    squares_loop.append(x ** 2)
print(f"Squares (loop): {squares_loop}")

# Using list comprehension
squares_comp = [x ** 2 for x in range(1, 11)]
print(f"Squares (comprehension): {squares_comp}")

# Filter even numbers using loop
evens_loop = []
for num in range(1, 21):
    if num % 2 == 0:
        evens_loop.append(num)
print(f"\nEvens (loop): {evens_loop}")

# Using list comprehension
evens_comp = [num for num in range(1, 21) if num % 2 == 0]
print(f"Evens (comprehension): {evens_comp}")

# Nested loop for matrix
matrix_loop = []
for i in range(3):
    row = []
    for j in range(3):
        row.append(i * 3 + j + 1)
    matrix_loop.append(row)

print(f"\nMatrix (nested loop):")
for row in matrix_loop:
    print(f"  {row}")

# Using nested comprehension
matrix_comp = [[i * 3 + j + 1 for j in range(3)] for i in range(3)]
print(f"Matrix (nested comprehension):")
for row in matrix_comp:
    print(f"  {row}")

# Performance comparison
import timeit

loop_time = timeit.timeit(
    '[x**2 for x in range(1000)]',
    number=10000
)
comp_time = timeit.timeit(
    'result = []\nfor x in range(1000):\n    result.append(x**2)',
    number=10000
)

print(f"\nPerformance (10,000 iterations):")
print(f"  Comprehension: {loop_time:.4f}s")
print(f"  Loop: {comp_time:.4f}s")
print(f"  Comprehension is {comp_time/loop_time:.2f}x faster")

print()

# Part 7: Practical Challenge - Data Processing (15 minutes)
print("Part 7: Practical Challenge - Data Processing")
print("-" * 40)

def process_sales_data(sales):
    """
    Process sales data and generate report.
    
    Args:
        sales: List of tuples (product, quantity, price)
    
    Returns:
        dict: Statistics (total_revenue, best_product, total_items)
    """
    if not sales:
        return {
            'total_revenue': 0,
            'best_product': None,
            'total_items': 0,
            'average_sale': 0,
            'products_sold': 0
        }
    
    total_revenue = 0
    total_items = 0
    product_revenues = {}
    
    # Process each sale
    for product, quantity, price in sales:
        sale_amount = quantity * price
        total_revenue += sale_amount
        total_items += quantity
        
        # Track revenue per product
        if product in product_revenues:
            product_revenues[product] += sale_amount
        else:
            product_revenues[product] = sale_amount
    
    # Find best-selling product by revenue
    best_product = max(product_revenues, key=product_revenues.get)
    best_revenue = product_revenues[best_product]
    
    # Calculate average
    average_sale = total_revenue / len(sales)
    
    return {
        'total_revenue': round(total_revenue, 2),
        'best_product': best_product,
        'best_product_revenue': round(best_revenue, 2),
        'total_items': total_items,
        'average_sale': round(average_sale, 2),
        'products_sold': len(product_revenues),
        'product_breakdown': product_revenues
    }

# Test data
sales = [
    ("Laptop", 5, 1200.00),
    ("Mouse", 15, 25.00),
    ("Keyboard", 10, 75.00),
    ("Monitor", 8, 300.00),
    ("Headset", 20, 50.00),
    ("Laptop", 3, 1200.00),  # More laptops
    ("Mouse", 10, 25.00),    # More mice
]

print("Sales Data Processing:")
print(f"  Processing {len(sales)} sales transactions...")

result = process_sales_data(sales)

print(f"\n📊 Sales Report:")
print(f"  Total Revenue: ${result['total_revenue']:,.2f}")
print(f"  Total Items Sold: {result['total_items']}")
print(f"  Average Sale: ${result['average_sale']:,.2f}")
print(f"  Unique Products: {result['products_sold']}")
print(f"  Best Product: {result['best_product']} (${result['best_product_revenue']:,.2f})")

print(f"\n  Product Breakdown:")
for product, revenue in sorted(result['product_breakdown'].items(), 
                                key=lambda x: x[1], reverse=True):
    print(f"    {product:<15} ${revenue:>10,.2f}")

# Additional analysis
print(f"\n  Detailed Analysis:")
for product, quantity, price in sales:
    print(f"    {product:<15} x{quantity:>3} @ ${price:>7.2f} = ${quantity*price:>10,.2f}")

# ============================================================================
# Verification Code
# ============================================================================

def verify_lab_05():
    """Verify that all lab exercises are completed correctly."""
    print("\n" + "="*60)
    print("Lab 05 Verification")
    print("="*60)
    
    passed = 0
    total = 7
    
    # Test basic loop understanding
    try:
        # Sum using loop
        test_sum = sum(range(1, 11))
        assert test_sum == 55, f"Sum calculation wrong: {test_sum}"
        
        # Enumerate understanding
        items = ['a', 'b', 'c']
        indexed = list(enumerate(items))
        assert indexed == [(0, 'a'), (1, 'b'), (2, 'c')], "enumerate wrong"
        
        print("✅ Basic loops - PASSED")
        passed += 1
    except AssertionError as e:
        print(f"❌ Basic loops - FAILED: {e}")
    
    # Test break and continue
    try:
        # Find first even number
        for i in range(1, 20):
            if i % 2 == 0:
                first_even = i
                break
        assert first_even == 2, f"Break logic wrong: {first_even}"
        
        # Count odd numbers using continue
        odd_count = 0
        for i in range(1, 11):
            if i % 2 == 0:
                continue
            odd_count += 1
        assert odd_count == 5, f"Continue logic wrong: {odd_count}"
        
        print("✅ Break and continue - PASSED")
        passed += 1
    except AssertionError as e:
        print(f"❌ Break and continue - FAILED: {e}")
    
    # Test nested loops
    try:
        # Create multiplication pairs
        pairs = []
        for i in range(1, 4):
            for j in range(1, 4):
                pairs.append((i, j, i*j))
        assert len(pairs) == 9, f"Nested loop wrong: {len(pairs)} pairs"
        assert pairs[0] == (1, 1, 1), "First pair wrong"
        assert pairs[-1] == (3, 3, 9), "Last pair wrong"
        
        print("✅ Nested loops - PASSED")
        passed += 1
    except AssertionError as e:
        print(f"❌ Nested loops - FAILED: {e}")
    
    # Test loop-else
    try:
        # Search with else
        found = False
        for i in [1, 2, 3, 4, 5]:
            if i == 10:
                found = True
                break
        else:
            not_found = True
        
        assert not found, "Search logic wrong"
        assert not_found, "Loop-else not working"
        
        print("✅ Loop-else clause - PASSED")
        passed += 1
    except (AssertionError, NameError) as e:
        print(f"❌ Loop-else clause - FAILED: {e}")
    
    # Test comprehensions
    try:
        # List comprehension
        squares = [x**2 for x in range(5)]
        assert squares == [0, 1, 4, 9, 16], f"Comprehension wrong: {squares}"
        
        # With condition
        evens = [x for x in range(10) if x % 2 == 0]
        assert evens == [0, 2, 4, 6, 8], f"Filtered comprehension wrong: {evens}"
        
        print("✅ List comprehensions - PASSED")
        passed += 1
    except AssertionError as e:
        print(f"❌ List comprehensions - FAILED: {e}")
    
    # Test is_prime function
    try:
        assert is_prime(2) == True, "2 should be prime"
        assert is_prime(17) == True, "17 should be prime"
        assert is_prime(4) == False, "4 should not be prime"
        assert is_prime(1) == False, "1 should not be prime"
        assert is_prime(23) == True, "23 should be prime"
        
        print("✅ Prime checking - PASSED")
        passed += 1
    except (AssertionError, NameError) as e:
        print(f"❌ Prime checking - FAILED: {e}")
    
    # Test sales processing
    try:
        test_sales = [
            ("A", 10, 5.00),
            ("B", 5, 10.00),
            ("A", 5, 5.00),
        ]
        
        result = process_sales_data(test_sales)
        
        assert result['total_revenue'] == 175.00, f"Revenue wrong: {result['total_revenue']}"
        assert result['total_items'] == 20, f"Items wrong: {result['total_items']}"
        assert result['best_product'] in ['A', 'B'], f"Best product wrong: {result['best_product']}"
        
        # Empty case
        empty_result = process_sales_data([])
        assert empty_result['total_revenue'] == 0, "Empty sales handling wrong"
        
        print("✅ Sales processing - PASSED")
        passed += 1
    except (AssertionError, NameError) as e:
        print(f"❌ Sales processing - FAILED: {e}")
    
    print("="*60)
    print(f"Score: {passed}/{total} ({passed/total*100:.0f}%)")
    print("="*60)
    
    if passed == total:
        print("🎉 Congratulations! All tests passed!")
        print("\n📚 Key Learnings:")
        print("  1. for loops iterate over sequences")
        print("  2. while loops repeat until condition is false")
        print("  3. break exits loop, continue skips iteration")
        print("  4. enumerate() provides index and value")
        print("  5. Nested loops for multi-dimensional operations")
        print("  6. Loop-else runs if loop completes without break")
        print("  7. List comprehensions are concise and fast")
        print("\n🚀 Next Steps:")
        print("  - Try Lab 06: Functions")
        print("  - Review Section 08: Loops")
        print("  - Practice more complex iteration patterns")
    else:
        print("📝 Keep practicing! Review the sections and try again.")

# Run verification
verify_lab_05()
