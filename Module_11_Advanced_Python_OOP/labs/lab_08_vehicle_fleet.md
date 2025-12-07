# Lab 08: Vehicle Fleet Manager with ABC

**Difficulty**: ⭐⭐⭐⭐⭐ (Advanced)  
**Estimated Time**: 60-80 minutes  
**Topics**: Abstract Base Classes, Inheritance Hierarchy, Type Checking, Design Patterns

---

## 🎯 Objectives

By completing this lab, you will:
- Design complex inheritance hierarchies with ABC
- Implement multiple levels of abstraction
- Use abstract properties and methods
- Create type-safe collections
- Implement factory pattern for object creation
- Handle polymorphic collections effectively

---

## 📋 Requirements

### Part 1: Vehicle Hierarchy with ABC

Create an abstract vehicle hierarchy:

**Abstract Base: Vehicle**
- Abstract properties: `vehicle_type`, `max_speed`, `fuel_capacity`
- Abstract methods: `start_engine()`, `stop_engine()`, `refuel(amount)`
- Concrete method: `get_info()` - returns vehicle details
- Attributes: `make`, `model`, `year`, `current_fuel`

**Abstract Intermediate: LandVehicle** (inherits from Vehicle)
- Additional abstract property: `num_wheels`
- Abstract method: `drive(distance)`
- Concrete method: `calculate_fuel_needed(distance)`

**Abstract Intermediate: WaterVehicle** (inherits from Vehicle)
- Additional abstract property: `displacement`
- Abstract method: `sail(distance)`
- Concrete method: `anchor()`

**Concrete Classes**:

1. **Car** (LandVehicle):
   - Properties: num_wheels=4, vehicle_type="Car"
   - Attributes: `transmission_type` (manual/automatic)
   - Implement all abstract methods

2. **Motorcycle** (LandVehicle):
   - Properties: num_wheels=2, vehicle_type="Motorcycle"
   - Attributes: `has_sidecar` (boolean)
   - Implement all abstract methods

3. **Truck** (LandVehicle):
   - Properties: num_wheels=18, vehicle_type="Truck"
   - Attributes: `cargo_capacity`, `current_load`
   - Methods: `load_cargo(weight)`, `unload_cargo(weight)`
   - Implement all abstract methods

4. **Boat** (WaterVehicle):
   - Properties: vehicle_type="Boat", displacement
   - Attributes: `boat_type` (sailboat/motorboat)
   - Implement all abstract methods

### Part 2: VehicleFactory (Factory Pattern)

Create a factory class for vehicle creation:

**VehicleFactory Class**:
- Static method: `create_vehicle(vehicle_type, **kwargs)` - creates appropriate vehicle
- Supports creating: "car", "motorcycle", "truck", "boat"
- Validates required parameters for each type
- Returns properly initialized vehicle object

### Part 3: FleetManager

Create a comprehensive fleet management system:

**FleetManager Class**:
- Manage collection of vehicles
- Methods:
  - `add_vehicle(vehicle)` - add vehicle to fleet
  - `remove_vehicle(vehicle_id)` - remove by ID
  - `get_vehicle(vehicle_id)` - retrieve vehicle
  - `get_vehicles_by_type(vehicle_type)` - filter by type
  - `get_land_vehicles()` - all land vehicles
  - `get_water_vehicles()` - all water vehicles
  - `total_fleet_value()` - sum of all vehicle values
  - `refuel_all()` - refuel all vehicles to capacity
  - `get_fleet_report()` - comprehensive report
  - `get_vehicles_needing_fuel(threshold)` - vehicles below fuel threshold

---

## 💻 Starter Code

```python
from abc import ABC, abstractmethod
from typing import List

class Vehicle(ABC):
    """Abstract base class for all vehicles"""
    
    _id_counter = 1000
    
    def __init__(self, make, model, year, fuel_capacity, purchase_price):
        """Initialize vehicle"""
        self.vehicle_id = Vehicle._id_counter
        Vehicle._id_counter += 1
        self.make = make
        self.model = model
        self.year = year
        self.fuel_capacity = fuel_capacity
        self.current_fuel = fuel_capacity  # Start with full tank
        self.purchase_price = purchase_price
        self.is_running = False
    
    @property
    @abstractmethod
    def vehicle_type(self):
        """Return the type of vehicle"""
        pass
    
    @property
    @abstractmethod
    def max_speed(self):
        """Return maximum speed in km/h"""
        pass
    
    @abstractmethod
    def start_engine(self):
        """Start the vehicle engine"""
        pass
    
    @abstractmethod
    def stop_engine(self):
        """Stop the vehicle engine"""
        pass
    
    @abstractmethod
    def refuel(self, amount):
        """Add fuel to vehicle"""
        pass
    
    def get_info(self):
        """Return vehicle information"""
        return f"{self.year} {self.make} {self.model} ({self.vehicle_type}) - ID: {self.vehicle_id}"
    
    def __str__(self):
        return self.get_info()
    
    def __repr__(self):
        return f"{self.__class__.__name__}(id={self.vehicle_id}, make='{self.make}')"

class LandVehicle(Vehicle):
    """Abstract class for land vehicles"""
    
    @property
    @abstractmethod
    def num_wheels(self):
        """Number of wheels"""
        pass
    
    @abstractmethod
    def drive(self, distance):
        """Drive the vehicle"""
        pass
    
    def calculate_fuel_needed(self, distance, fuel_efficiency):
        """Calculate fuel needed for distance"""
        # TODO: Calculate fuel needed
        # fuel_needed = distance / fuel_efficiency
        pass

class WaterVehicle(Vehicle):
    """Abstract class for water vehicles"""
    
    @property
    @abstractmethod
    def displacement(self):
        """Water displacement in tons"""
        pass
    
    @abstractmethod
    def sail(self, distance):
        """Sail the vessel"""
        pass
    
    def anchor(self):
        """Drop anchor"""
        if self.is_running:
            self.stop_engine()
        return f"{self.get_info()} has dropped anchor"

class Car(LandVehicle):
    """Concrete Car class"""
    
    def __init__(self, make, model, year, transmission_type="automatic", 
                 fuel_capacity=50, max_speed=180, purchase_price=25000):
        super().__init__(make, model, year, fuel_capacity, purchase_price)
        self.transmission_type = transmission_type
        self._max_speed = max_speed
        self.fuel_efficiency = 12  # km per liter
    
    @property
    def vehicle_type(self):
        return "Car"
    
    @property
    def max_speed(self):
        return self._max_speed
    
    @property
    def num_wheels(self):
        return 4
    
    def start_engine(self):
        # TODO: Implement start engine
        pass
    
    def stop_engine(self):
        # TODO: Implement stop engine
        pass
    
    def refuel(self, amount):
        # TODO: Implement refuel with validation
        pass
    
    def drive(self, distance):
        # TODO: Implement drive
        # Check if engine is running
        # Calculate fuel needed
        # Check if enough fuel
        # Consume fuel and return message
        pass

class Motorcycle(LandVehicle):
    """Concrete Motorcycle class"""
    
    def __init__(self, make, model, year, has_sidecar=False,
                 fuel_capacity=15, max_speed=200, purchase_price=12000):
        super().__init__(make, model, year, fuel_capacity, purchase_price)
        self.has_sidecar = has_sidecar
        self._max_speed = max_speed
        self.fuel_efficiency = 20  # km per liter
    
    @property
    def vehicle_type(self):
        return "Motorcycle"
    
    @property
    def max_speed(self):
        return self._max_speed
    
    @property
    def num_wheels(self):
        return 3 if self.has_sidecar else 2
    
    def start_engine(self):
        # TODO: Implement
        pass
    
    def stop_engine(self):
        # TODO: Implement
        pass
    
    def refuel(self, amount):
        # TODO: Implement
        pass
    
    def drive(self, distance):
        # TODO: Implement similar to Car
        pass

class Truck(LandVehicle):
    """Concrete Truck class"""
    
    def __init__(self, make, model, year, cargo_capacity=10000,
                 fuel_capacity=200, max_speed=120, purchase_price=75000):
        super().__init__(make, model, year, fuel_capacity, purchase_price)
        self.cargo_capacity = cargo_capacity  # kg
        self.current_load = 0
        self._max_speed = max_speed
        self.fuel_efficiency = 6  # km per liter
    
    @property
    def vehicle_type(self):
        return "Truck"
    
    @property
    def max_speed(self):
        return self._max_speed
    
    @property
    def num_wheels(self):
        return 18
    
    def load_cargo(self, weight):
        """Load cargo onto truck"""
        # TODO: Check capacity and add weight
        pass
    
    def unload_cargo(self, weight):
        """Unload cargo from truck"""
        # TODO: Check current load and remove weight
        pass
    
    def start_engine(self):
        # TODO: Implement
        pass
    
    def stop_engine(self):
        # TODO: Implement
        pass
    
    def refuel(self, amount):
        # TODO: Implement
        pass
    
    def drive(self, distance):
        # TODO: Implement (consider current load affecting fuel efficiency)
        pass

class Boat(WaterVehicle):
    """Concrete Boat class"""
    
    def __init__(self, make, model, year, boat_type="motorboat", 
                 displacement=2.5, fuel_capacity=100, max_speed=50, 
                 purchase_price=50000):
        super().__init__(make, model, year, fuel_capacity, purchase_price)
        self.boat_type = boat_type
        self._displacement = displacement
        self._max_speed = max_speed
        self.fuel_efficiency = 8  # km per liter
    
    @property
    def vehicle_type(self):
        return "Boat"
    
    @property
    def max_speed(self):
        return self._max_speed
    
    @property
    def displacement(self):
        return self._displacement
    
    def start_engine(self):
        # TODO: Implement
        pass
    
    def stop_engine(self):
        # TODO: Implement
        pass
    
    def refuel(self, amount):
        # TODO: Implement
        pass
    
    def sail(self, distance):
        # TODO: Implement similar to drive()
        pass

class VehicleFactory:
    """Factory for creating vehicles"""
    
    @staticmethod
    def create_vehicle(vehicle_type, **kwargs):
        """Create vehicle of specified type"""
        # TODO: Implement factory logic
        # Handle: "car", "motorcycle", "truck", "boat"
        # Validate required parameters
        # Return appropriate vehicle instance
        pass

class FleetManager:
    """Manages a fleet of vehicles"""
    
    def __init__(self, company_name):
        self.company_name = company_name
        self.vehicles = {}
    
    def add_vehicle(self, vehicle):
        """Add vehicle to fleet"""
        # TODO: Add to vehicles dictionary using vehicle_id as key
        pass
    
    def remove_vehicle(self, vehicle_id):
        """Remove vehicle from fleet"""
        # TODO: Remove from dictionary
        pass
    
    def get_vehicle(self, vehicle_id):
        """Get vehicle by ID"""
        # TODO: Return vehicle or None
        pass
    
    def get_vehicles_by_type(self, vehicle_type):
        """Get all vehicles of a specific type"""
        # TODO: Filter and return list
        pass
    
    def get_land_vehicles(self):
        """Get all land vehicles"""
        # TODO: Return list of LandVehicle instances
        pass
    
    def get_water_vehicles(self):
        """Get all water vehicles"""
        # TODO: Return list of WaterVehicle instances
        pass
    
    def total_fleet_value(self):
        """Calculate total value of fleet"""
        # TODO: Sum all vehicle purchase prices
        pass
    
    def refuel_all(self):
        """Refuel all vehicles to capacity"""
        # TODO: Refuel each vehicle
        pass
    
    def get_vehicles_needing_fuel(self, threshold=0.25):
        """Get vehicles below fuel threshold"""
        # TODO: Return vehicles with fuel < threshold * capacity
        pass
    
    def get_fleet_report(self):
        """Generate comprehensive fleet report"""
        # TODO: Create detailed report with statistics
        pass

# Test your implementation
if __name__ == "__main__":
    print("=== Creating Fleet Manager ===")
    fleet = FleetManager("TransGlobal Logistics")
    
    # Create vehicles using factory
    print("\n=== Adding Vehicles ===")
    car1 = VehicleFactory.create_vehicle("car", make="Toyota", model="Camry", year=2022)
    car2 = VehicleFactory.create_vehicle("car", make="Honda", model="Accord", year=2023)
    moto = VehicleFactory.create_vehicle("motorcycle", make="Harley", model="Street 750", year=2021)
    truck = VehicleFactory.create_vehicle("truck", make="Volvo", model="FH16", year=2023)
    boat = VehicleFactory.create_vehicle("boat", make="Sea Ray", model="Sundancer", year=2022)
    
    fleet.add_vehicle(car1)
    fleet.add_vehicle(car2)
    fleet.add_vehicle(moto)
    fleet.add_vehicle(truck)
    fleet.add_vehicle(boat)
    
    print(f"Fleet size: {len(fleet.vehicles)}")
    
    # Test driving
    print("\n=== Testing Vehicles ===")
    car1.drive(100)
    moto.drive(50)
    truck.load_cargo(5000)
    truck.drive(200)
    boat.sail(30)
    
    # Fleet report
    print("\n=== Fleet Report ===")
    print(fleet.get_fleet_report())
    
    # Vehicles needing fuel
    print("\n=== Vehicles Needing Fuel ===")
    low_fuel = fleet.get_vehicles_needing_fuel(0.5)
    for vehicle in low_fuel:
        print(f"  {vehicle.get_info()} - Fuel: {vehicle.current_fuel:.1f}L")
```

---

## 🎯 Expected Output

```
=== Creating Fleet Manager ===

=== Adding Vehicles ===
Fleet size: 5

=== Testing Vehicles ===
✓ 2022 Toyota Camry started
→ Drove 100 km, consumed 8.3L of fuel
✓ 2021 Harley Street 750 started
→ Drove 50 km, consumed 2.5L of fuel
✓ Loaded 5000 kg cargo
✓ 2023 Volvo FH16 started
→ Drove 200 km, consumed 33.3L of fuel
✓ 2022 Sea Ray Sundancer started
→ Sailed 30 km, consumed 3.8L of fuel

=== Fleet Report ===
TransGlobal Logistics Fleet Report
===================================
Total Vehicles: 5
  - Land Vehicles: 4
  - Water Vehicles: 1

By Type:
  - Car: 2
  - Motorcycle: 1
  - Truck: 1
  - Boat: 1

Total Fleet Value: $174,000
Average Vehicle Value: $34,800

Fuel Status:
  - Total Fuel Capacity: 415L
  - Current Total Fuel: 370.1L
  - Average Fill Level: 89.2%

=== Vehicles Needing Fuel ===
  2023 Volvo FH16 (Truck) - ID: 1003 - Fuel: 166.7L
```

---

## ✅ Validation Checklist

- [ ] Vehicle is truly abstract and cannot be instantiated
- [ ] LandVehicle and WaterVehicle are abstract intermediate classes
- [ ] All concrete classes implement all abstract methods
- [ ] Abstract properties work correctly
- [ ] start_engine() and stop_engine() change is_running state
- [ ] refuel() validates amount and doesn't exceed capacity
- [ ] drive()/sail() check if engine is running
- [ ] drive()/sail() check sufficient fuel before moving
- [ ] Fuel consumption calculations are accurate
- [ ] Truck cargo loading validates capacity
- [ ] VehicleFactory creates correct vehicle types
- [ ] FleetManager properly manages vehicle collection
- [ ] Type filtering (land vs water) works correctly
- [ ] Fleet statistics are calculated accurately

---

## 🚀 Extension Challenges

1. **Maintenance System**: Add maintenance tracking and schedules
2. **GPS Tracking**: Add location tracking for vehicles
3. **Fuel Cards**: Implement fuel card system with spending limits
4. **Driver Assignment**: Assign drivers to vehicles with licensing
5. **Route Planning**: Calculate optimal routes and fuel stops
6. **Depreciation**: Calculate vehicle depreciation over time
7. **Insurance**: Add insurance policies and premium calculations
8. **Hybrid Vehicles**: Create AmphibiousVehicle class

---

## 💡 Key Concepts Demonstrated

- **Multi-level ABC Hierarchy**: Abstract → Abstract → Concrete
- **Abstract Properties**: Using @property with @abstractmethod
- **Factory Pattern**: Centralized object creation
- **Type Checking**: Using isinstance() for polymorphic collections
- **Domain Modeling**: Real-world vehicle fleet system
- **Inheritance Best Practices**: Proper use of super() and method overriding

---

## 📚 Related Theory Sections

- `09_abstract_base_classes.md` - Complete ABC guide
- `04_inheritance.md` - Inheritance hierarchies
- `05_polymorphism.md` - Polymorphic collections

---

**Good luck! 🚗🏍️🚛⛵**
