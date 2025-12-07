# Lab 07 Solution: Temperature Converter

"""Complete solution for Temperature Converter lab.
Demonstrates: Property Decorators, Descriptors, Validation"""


class ValidatedNumber:
    def __init__(self, min_value=None, max_value=None):
        self.min_value = min_value
        self.max_value = max_value
    
    def __set_name__(self, owner, name):
        self.name = name
        self.private_name = f'_{name}'
    
    def __get__(self, instance, owner):
        if instance is None:
            return self
        return getattr(instance, self.private_name)
    
    def __set__(self, instance, value):
        if not isinstance(value, (int, float)):
            raise TypeError(f"{self.name} must be a number")
        
        if self.min_value is not None and value < self.min_value:
            raise ValueError(f"{self.name} must be >= {self.min_value}")
        
        if self.max_value is not None and value > self.max_value:
            raise ValueError(f"{self.name} must be <= {self.max_value}")
        
        setattr(instance, self.private_name, value)


class Temperature:
    def __init__(self, kelvin=273.15):
        self._kelvin = None
        self.kelvin = kelvin
    
    @property
    def kelvin(self):
        return self._kelvin
    
    @kelvin.setter
    def kelvin(self, value):
        if value < 0:
            raise ValueError("Temperature cannot be below absolute zero (0 K)")
        self._kelvin = value
    
    @property
    def celsius(self):
        return self._kelvin - 273.15
    
    @celsius.setter
    def celsius(self, value):
        if value < -273.15:
            raise ValueError("Temperature cannot be below -273.15°C")
        self._kelvin = value + 273.15
    
    @property
    def fahrenheit(self):
        return (self._kelvin * 9/5) - 459.67
    
    @fahrenheit.setter
    def fahrenheit(self, value):
        if value < -459.67:
            raise ValueError("Temperature cannot be below -459.67°F")
        self._kelvin = (value + 459.67) * 5/9
    
    @property
    def rankine(self):
        return self._kelvin * 9/5
    
    def __str__(self):
        return f"{self.celsius:.2f}°C / {self.fahrenheit:.2f}°F / {self.kelvin:.2f}K"
    
    def __repr__(self):
        return f"Temperature(kelvin={self.kelvin})"


class WeatherStation:
    humidity = ValidatedNumber(min_value=0, max_value=100)
    pressure = ValidatedNumber(min_value=870, max_value=1085)
    
    def __init__(self, temp_celsius=20, humidity=50, pressure=1013):
        self._temperature = Temperature()
        self._temperature.celsius = temp_celsius
        self.humidity = humidity
        self.pressure = pressure
        self._data_summary_cache = None
    
    @property
    def temperature(self):
        return self._temperature
    
    @property
    def conditions(self):
        temp_c = self.temperature.celsius
        
        # Temperature condition
        if temp_c < 10:
            temp_desc = "Cold temperature"
        elif temp_c <= 25:
            temp_desc = "Mild temperature"
        else:
            temp_desc = "Warm temperature"
        
        # Humidity condition
        if self.humidity < 30:
            humid_desc = "Dry"
        elif self.humidity <= 60:
            humid_desc = "Comfortable humidity"
        else:
            humid_desc = "Humid"
        
        # Pressure condition
        if self.pressure < 1000:
            press_desc = "Low pressure"
        elif self.pressure <= 1020:
            press_desc = "Normal pressure"
        else:
            press_desc = "High pressure"
        
        return f"{temp_desc}, {humid_desc}, {press_desc}"
    
    @property
    def data_summary(self):
        if self._data_summary_cache is None:
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
        self.temperature.celsius = temp_c
        self.humidity = humidity
        self.pressure = pressure
        self.clear_cache()
    
    def is_comfortable(self):
        return (18 <= self.temperature.celsius <= 24 and 
                30 <= self.humidity <= 60 and 
                1000 <= self.pressure <= 1020)
    
    def clear_cache(self):
        self._data_summary_cache = None
    
    def __str__(self):
        return f"Weather: {self.temperature}, Humidity: {self.humidity}%, Pressure: {self.pressure} hPa"


if __name__ == "__main__":
    print("=== Testing Temperature Class ===")
    temp = Temperature()
    temp.celsius = 25
    print(f"Set to 25°C: {temp}")
    
    temp.fahrenheit = 32
    print(f"Set to 32°F: {temp}")
    
    try:
        temp.celsius = -300
    except ValueError as e:
        print(f"✓ Validation worked: {e}")
    
    print("\n=== Testing WeatherStation ===")
    station = WeatherStation(temp_celsius=22, humidity=45, pressure=1015)
    print(station)
    print(f"Conditions: {station.conditions}")
    print(f"Comfortable: {station.is_comfortable()}")
    
    print(f"\nTemperature object: {station.temperature}")
    print(f"In Fahrenheit: {station.temperature.fahrenheit:.2f}°F")
    
    print("\n=== Updating Readings ===")
    station.update_reading(15, 75, 995)
    print(station)
    print(f"Conditions: {station.conditions}")
    
    print("\n=== Testing Cached Property ===")
    print("First call (computes):")
    summary = station.data_summary
    print(summary)
    
    print("\nSecond call (cached):")
    summary = station.data_summary
    print(summary)
    
    print("\n=== Testing Validation ===")
    try:
        station.humidity = 150
    except ValueError as e:
        print(f"✓ Humidity validation: {e}")
    
    try:
        station.pressure = 500
    except ValueError as e:
        print(f"✓ Pressure validation: {e}")
