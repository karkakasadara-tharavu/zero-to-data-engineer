# Lab 07: Temperature Converter with Properties

**Difficulty**: ⭐⭐⭐ (Intermediate)  
**Estimated Time**: 35-45 minutes  
**Topics**: Property Decorators, Validation, Descriptors

---

## 🎯 Objectives

By completing this lab, you will:
- Use `@property` decorator for computed properties
- Implement property setters with validation
- Create read-only and read-write properties
- Use descriptors for reusable validation
- Handle temperature conversions automatically
- Demonstrate cached/lazy properties

---

## 📋 Requirements

### Part 1: Temperature Class

Create a `Temperature` class that stores temperature and provides conversions:

**Storage**:
- Store temperature internally in Kelvin (absolute temperature scale)

**Properties** (all computed from Kelvin):
- `celsius` - getter and setter, converts to/from Kelvin
- `fahrenheit` - getter and setter, converts to/from Kelvin
- `kelvin` - getter and setter, validates >= 0
- `rankine` - getter only (Fahrenheit scale from absolute zero)

**Validation**:
- Kelvin cannot be negative (below absolute zero)
- Celsius cannot be below -273.15°C
- Fahrenheit cannot be below -459.67°F

**Conversion Formulas**:
- C = K - 273.15
- F = (K × 9/5) - 459.67
- R = K × 9/5

### Part 2: ValidatedNumber Descriptor

Create a `ValidatedNumber` descriptor class for reusable validation:

**Features**:
- Validate that values are numeric
- Optional min and max bounds
- Store unique values per instance
- Provide clear error messages

**Usage Example**:
```python
class Product:
    price = ValidatedNumber(min_value=0)
    quantity = ValidatedNumber(min_value=0, max_value=10000)
```

### Part 3: WeatherStation Class

Create a `WeatherStation` class with multiple properties:

**Attributes**:
- `_temperature` - Temperature object
- `_humidity` - percentage (0-100)
- `_pressure` - pressure in hPa

**Properties**:
- `temperature` - returns Temperature object
- `humidity` - getter/setter with 0-100 validation
- `pressure` - getter/setter with validation
- `conditions` - read-only, returns description based on data
- `data_summary` - cached property that's expensive to compute

**Methods**:
- `update_reading(temp_c, humidity, pressure)` - update all values
- `is_comfortable()` - return True if conditions are comfortable
- `clear_cache()` - clear cached properties

---

## 💻 Starter Code

```python
class ValidatedNumber:
    """Descriptor for validated numeric attributes"""
    
    def __init__(self, min_value=None, max_value=None):
        self.min_value = min_value
        self.max_value = max_value
    
    def __set_name__(self, owner, name):
        """Called when descriptor is assigned to class attribute"""
        self.name = name
        self.private_name = f'_{name}'
    
    def __get__(self, instance, owner):
        """Get the value"""
        if instance is None:
            return self
        # TODO: Return the private attribute value
        pass
    
    def __set__(self, instance, value):
        """Set the value with validation"""
        # TODO: Validate that value is a number
        # TODO: Check min_value constraint
        # TODO: Check max_value constraint
        # TODO: Set the private attribute
        pass

class Temperature:
    """Temperature class with automatic conversions"""
    
    def __init__(self, kelvin=0):
        """Initialize with Kelvin temperature"""
        # TODO: Validate and set kelvin
        self._kelvin = None
        self.kelvin = kelvin
    
    @property
    def kelvin(self):
        """Get temperature in Kelvin"""
        return self._kelvin
    
    @kelvin.setter
    def kelvin(self, value):
        """Set temperature in Kelvin with validation"""
        # TODO: Validate >= 0 (absolute zero)
        # TODO: Set _kelvin
        pass
    
    @property
    def celsius(self):
        """Get temperature in Celsius"""
        # TODO: Convert from Kelvin: C = K - 273.15
        pass
    
    @celsius.setter
    def celsius(self, value):
        """Set temperature from Celsius"""
        # TODO: Validate >= -273.15
        # TODO: Convert to Kelvin: K = C + 273.15
        # TODO: Set kelvin property
        pass
    
    @property
    def fahrenheit(self):
        """Get temperature in Fahrenheit"""
        # TODO: Convert: F = (K × 9/5) - 459.67
        pass
    
    @fahrenheit.setter
    def fahrenheit(self, value):
        """Set temperature from Fahrenheit"""
        # TODO: Validate >= -459.67
        # TODO: Convert to Kelvin: K = (F + 459.67) × 5/9
        pass
    
    @property
    def rankine(self):
        """Get temperature in Rankine (read-only)"""
        # TODO: Convert: R = K × 9/5
        pass
    
    def __str__(self):
        return f"{self.celsius:.2f}°C / {self.fahrenheit:.2f}°F / {self.kelvin:.2f}K"
    
    def __repr__(self):
        return f"Temperature(kelvin={self.kelvin})"

class WeatherStation:
    """Weather station with multiple validated properties"""
    
    # Use ValidatedNumber descriptors
    humidity = ValidatedNumber(min_value=0, max_value=100)
    pressure = ValidatedNumber(min_value=870, max_value=1085)
    
    def __init__(self, temp_celsius=20, humidity=50, pressure=1013):
        """Initialize weather station"""
        self._temperature = Temperature()
        self._temperature.celsius = temp_celsius
        self.humidity = humidity
        self.pressure = pressure
        self._data_summary_cache = None
    
    @property
    def temperature(self):
        """Get Temperature object"""
        return self._temperature
    
    @property
    def conditions(self):
        """Get current weather conditions (read-only)"""
        # TODO: Return description based on:
        # - Temperature: cold (<10°C), mild (10-25°C), warm (>25°C)
        # - Humidity: dry (<30%), comfortable (30-60%), humid (>60%)
        # - Pressure: low (<1000), normal (1000-1020), high (>1020)
        pass
    
    @property
    def data_summary(self):
        """Expensive computed property (cached)"""
        if self._data_summary_cache is None:
            # TODO: Create comprehensive summary
            # In real world, this might involve complex calculations
            self._data_summary_cache = {
                'temperature_c': self.temperature.celsius,
                'temperature_f': self.temperature.fahrenheit,
                'humidity': self.humidity,
                'pressure': self.pressure,
                'conditions': self.conditions,
                'comfortable': self.is_comfortable()
            }
        return self._data_summary_cache
    
    def update_reading(self, temp_c, humidity, pressure):
        """Update all sensor readings"""
        # TODO: Update temperature, humidity, pressure
        # TODO: Clear cache
        pass
    
    def is_comfortable(self):
        """Check if conditions are comfortable"""
        # TODO: Return True if:
        # - Temperature between 18-24°C
        # - Humidity between 30-60%
        # - Pressure between 1000-1020 hPa
        pass
    
    def clear_cache(self):
        """Clear cached properties"""
        self._data_summary_cache = None
    
    def __str__(self):
        return f"Weather: {self.temperature}, Humidity: {self.humidity}%, Pressure: {self.pressure} hPa"

# Test your implementation
if __name__ == "__main__":
    print("=== Testing Temperature Class ===")
    temp = Temperature()
    
    # Set in Celsius
    temp.celsius = 25
    print(f"Set to 25°C: {temp}")
    
    # Set in Fahrenheit
    temp.fahrenheit = 32
    print(f"Set to 32°F: {temp}")
    
    # Try invalid temperature
    try:
        temp.celsius = -300
        print("ERROR: Should have raised exception!")
    except ValueError as e:
        print(f"✓ Validation worked: {e}")
    
    print("\n=== Testing WeatherStation ===")
    station = WeatherStation(temp_celsius=22, humidity=45, pressure=1015)
    print(station)
    print(f"Conditions: {station.conditions}")
    print(f"Comfortable: {station.is_comfortable()}")
    
    # Test property access
    print(f"\nTemperature object: {station.temperature}")
    print(f"In Fahrenheit: {station.temperature.fahrenheit:.2f}°F")
    
    # Update reading
    print("\n=== Updating Readings ===")
    station.update_reading(15, 75, 995)
    print(station)
    print(f"Conditions: {station.conditions}")
    
    # Test data summary (cached)
    print("\n=== Testing Cached Property ===")
    print("First call (computes):")
    summary = station.data_summary
    print(summary)
    
    print("\nSecond call (cached):")
    summary = station.data_summary
    print(summary)
    
    # Test validation
    print("\n=== Testing Validation ===")
    try:
        station.humidity = 150
        print("ERROR: Should have raised exception!")
    except ValueError as e:
        print(f"✓ Humidity validation: {e}")
    
    try:
        station.pressure = 500
        print("ERROR: Should have raised exception!")
    except ValueError as e:
        print(f"✓ Pressure validation: {e}")
```

---

## 🎯 Expected Output

```
=== Testing Temperature Class ===
Set to 25°C: 25.00°C / 77.00°F / 298.15K
Set to 32°F: 0.00°C / 32.00°F / 273.15K
✓ Validation worked: Temperature cannot be below -273.15°C

=== Testing WeatherStation ===
Weather: 22.00°C / 71.60°F / 295.15K, Humidity: 45%, Pressure: 1015 hPa
Conditions: Mild temperature, Comfortable humidity, Normal pressure
Comfortable: True

Temperature object: 22.00°C / 71.60°F / 295.15K
In Fahrenheit: 71.60°F

=== Updating Readings ===
Weather: 15.00°C / 59.00°F / 288.15K, Humidity: 75%, Pressure: 995 hPa
Conditions: Mild temperature, Humid, Low pressure

=== Testing Cached Property ===
First call (computes):
{'temperature_c': 15.0, 'temperature_f': 59.0, 'humidity': 75, 'pressure': 995, 'conditions': 'Mild temperature, Humid, Low pressure', 'comfortable': False}

Second call (cached):
{'temperature_c': 15.0, 'temperature_f': 59.0, 'humidity': 75, 'pressure': 995, 'conditions': 'Mild temperature, Humid, Low pressure', 'comfortable': False}

=== Testing Validation ===
✓ Humidity validation: humidity must be between 0 and 100
✓ Pressure validation: pressure must be between 870 and 1085
```

---

## ✅ Validation Checklist

Your implementation should:
- [ ] Temperature conversions are mathematically correct
- [ ] Cannot set temperatures below absolute zero
- [ ] All four temperature scales work correctly
- [ ] `rankine` property is read-only (no setter)
- [ ] ValidatedNumber descriptor works for any numeric field
- [ ] Descriptor stores unique values per instance
- [ ] WeatherStation validates humidity (0-100%)
- [ ] WeatherStation validates pressure (870-1085 hPa)
- [ ] `conditions` property is read-only
- [ ] `data_summary` is cached and not recomputed
- [ ] `clear_cache()` invalidates cached properties
- [ ] All properties provide appropriate error messages
- [ ] Properties allow both getting and setting (where appropriate)

---

## 🚀 Extension Challenges

1. **More Scales**: Add Réaumur, Delisle, or Newton temperature scales
2. **Property History**: Track history of property changes
3. **Lazy Loading**: Implement lazy properties that compute on first access
4. **Property Validation**: Add more complex cross-property validation
5. **Unit Conversion**: Generalize to support other unit conversions
6. **Property Change Events**: Notify listeners when properties change
7. **Undo/Redo**: Add ability to undo property changes
8. **Property Serialization**: Save/load property values to JSON

---

## 💡 Key Concepts Demonstrated

- **@property Decorator**: Creating computed properties
- **Property Setters**: Validation on assignment
- **Read-only Properties**: Properties with only getters
- **Descriptors**: Reusable property-like behavior
- **Cached Properties**: Avoiding expensive recomputation
- **Data Validation**: Ensuring data integrity
- **Unit Conversion**: Automatic conversion between scales

---

## 📚 Related Theory Sections

- `08_property_decorators.md` - Complete guide to @property
- `06_encapsulation.md` - Data hiding and validation

---

**Good luck! 🌡️☀️**
