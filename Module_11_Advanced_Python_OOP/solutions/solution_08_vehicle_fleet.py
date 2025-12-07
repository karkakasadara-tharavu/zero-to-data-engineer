# Lab 08 Solution: Vehicle Fleet Manager

"""Complete solution for Vehicle Fleet Manager lab.
Demonstrates: ABC Hierarchy, Factory Pattern, Inheritance"""

from abc import ABC, abstractmethod
from datetime import datetime
from typing import List


class Vehicle(ABC):
    def __init__(self, vehicle_id: str, make: str, model: str, year: int, 
                 fuel_capacity: float, fuel_consumption: float):
        self.vehicle_id = vehicle_id
        self.make = make
        self.model = model
        self.year = year
        self.fuel_capacity = fuel_capacity
        self.fuel_consumption = fuel_consumption
        self.fuel_level = fuel_capacity
        self.odometer = 0.0
        self.maintenance_log = []
    
    @abstractmethod
    def start_engine(self) -> str:
        pass
    
    @abstractmethod
    def calculate_range(self) -> float:
        pass
    
    @abstractmethod
    def maintenance_cost(self) -> float:
        pass
    
    def refuel(self, amount: float):
        if amount < 0:
            raise ValueError("Refuel amount must be positive")
        new_level = self.fuel_level + amount
        if new_level > self.fuel_capacity:
            self.fuel_level = self.fuel_capacity
            return self.fuel_capacity - (new_level - amount)
        self.fuel_level = new_level
        return amount
    
    def drive(self, distance: float):
        if distance < 0:
            raise ValueError("Distance must be positive")
        
        max_range = self.calculate_range()
        if distance > max_range:
            raise ValueError(f"Not enough fuel. Max range: {max_range:.2f} km")
        
        fuel_used = distance * self.fuel_consumption / 100
        self.fuel_level -= fuel_used
        self.odometer += distance
    
    def add_maintenance(self, description: str, cost: float):
        maintenance = {
            'date': datetime.now().strftime("%Y-%m-%d"),
            'description': description,
            'cost': cost,
            'odometer': self.odometer
        }
        self.maintenance_log.append(maintenance)
    
    def __str__(self):
        return f"{self.year} {self.make} {self.model} (ID: {self.vehicle_id})"


class LandVehicle(Vehicle):
    def __init__(self, vehicle_id: str, make: str, model: str, year: int,
                 fuel_capacity: float, fuel_consumption: float, num_wheels: int):
        super().__init__(vehicle_id, make, model, year, fuel_capacity, fuel_consumption)
        self.num_wheels = num_wheels


class WaterVehicle(Vehicle):
    def __init__(self, vehicle_id: str, make: str, model: str, year: int,
                 fuel_capacity: float, fuel_consumption: float, displacement: float):
        super().__init__(vehicle_id, make, model, year, fuel_capacity, fuel_consumption)
        self.displacement = displacement


class Car(LandVehicle):
    def __init__(self, vehicle_id: str, make: str, model: str, year: int,
                 fuel_capacity: float, fuel_consumption: float, num_doors: int):
        super().__init__(vehicle_id, make, model, year, fuel_capacity, 
                        fuel_consumption, num_wheels=4)
        self.num_doors = num_doors
    
    def start_engine(self) -> str:
        return f"🚗 Car {self.vehicle_id} engine started with key"
    
    def calculate_range(self) -> float:
        return (self.fuel_level / self.fuel_consumption) * 100
    
    def maintenance_cost(self) -> float:
        base_cost = 100
        age_factor = (datetime.now().year - self.year) * 10
        mileage_factor = self.odometer * 0.01
        return base_cost + age_factor + mileage_factor


class Motorcycle(LandVehicle):
    def __init__(self, vehicle_id: str, make: str, model: str, year: int,
                 fuel_capacity: float, fuel_consumption: float, engine_cc: int):
        super().__init__(vehicle_id, make, model, year, fuel_capacity,
                        fuel_consumption, num_wheels=2)
        self.engine_cc = engine_cc
    
    def start_engine(self) -> str:
        return f"🏍️ Motorcycle {self.vehicle_id} engine roaring to life"
    
    def calculate_range(self) -> float:
        return (self.fuel_level / self.fuel_consumption) * 100
    
    def maintenance_cost(self) -> float:
        base_cost = 75
        age_factor = (datetime.now().year - self.year) * 8
        mileage_factor = self.odometer * 0.008
        return base_cost + age_factor + mileage_factor


class Truck(LandVehicle):
    def __init__(self, vehicle_id: str, make: str, model: str, year: int,
                 fuel_capacity: float, fuel_consumption: float, cargo_capacity: float):
        super().__init__(vehicle_id, make, model, year, fuel_capacity,
                        fuel_consumption, num_wheels=6)
        self.cargo_capacity = cargo_capacity
        self.current_cargo = 0.0
    
    def start_engine(self) -> str:
        return f"🚚 Truck {self.vehicle_id} diesel engine started"
    
    def calculate_range(self) -> float:
        cargo_penalty = 1 + (self.current_cargo / self.cargo_capacity) * 0.3
        effective_consumption = self.fuel_consumption * cargo_penalty
        return (self.fuel_level / effective_consumption) * 100
    
    def maintenance_cost(self) -> float:
        base_cost = 200
        age_factor = (datetime.now().year - self.year) * 15
        mileage_factor = self.odometer * 0.015
        return base_cost + age_factor + mileage_factor
    
    def load_cargo(self, weight: float):
        if weight < 0:
            raise ValueError("Weight must be positive")
        if self.current_cargo + weight > self.cargo_capacity:
            raise ValueError(f"Exceeds capacity. Available: {self.cargo_capacity - self.current_cargo} kg")
        self.current_cargo += weight
    
    def unload_cargo(self, weight: float):
        if weight < 0:
            raise ValueError("Weight must be positive")
        if weight > self.current_cargo:
            self.current_cargo = 0
        else:
            self.current_cargo -= weight


class Boat(WaterVehicle):
    def __init__(self, vehicle_id: str, make: str, model: str, year: int,
                 fuel_capacity: float, fuel_consumption: float, displacement: float,
                 boat_type: str):
        super().__init__(vehicle_id, make, model, year, fuel_capacity,
                        fuel_consumption, displacement)
        self.boat_type = boat_type
    
    def start_engine(self) -> str:
        return f"⛵ {self.boat_type} {self.vehicle_id} engine started"
    
    def calculate_range(self) -> float:
        return (self.fuel_level / self.fuel_consumption) * 100 * 0.5396
    
    def maintenance_cost(self) -> float:
        base_cost = 300
        age_factor = (datetime.now().year - self.year) * 20
        usage_factor = self.odometer * 0.02
        return base_cost + age_factor + usage_factor


class VehicleFactory:
    @staticmethod
    def create_vehicle(vehicle_type: str, **kwargs) -> Vehicle:
        vehicle_types = {
            'car': Car,
            'motorcycle': Motorcycle,
            'truck': Truck,
            'boat': Boat
        }
        
        vehicle_class = vehicle_types.get(vehicle_type.lower())
        if not vehicle_class:
            raise ValueError(f"Unknown vehicle type: {vehicle_type}")
        
        return vehicle_class(**kwargs)


class FleetManager:
    def __init__(self):
        self.vehicles = {}
    
    def add_vehicle(self, vehicle: Vehicle):
        if vehicle.vehicle_id in self.vehicles:
            raise ValueError(f"Vehicle {vehicle.vehicle_id} already exists")
        self.vehicles[vehicle.vehicle_id] = vehicle
    
    def remove_vehicle(self, vehicle_id: str):
        if vehicle_id not in self.vehicles:
            raise ValueError(f"Vehicle {vehicle_id} not found")
        del self.vehicles[vehicle_id]
    
    def get_vehicle(self, vehicle_id: str) -> Vehicle:
        if vehicle_id not in self.vehicles:
            raise ValueError(f"Vehicle {vehicle_id} not found")
        return self.vehicles[vehicle_id]
    
    def list_vehicles(self, vehicle_type: type = None) -> List[Vehicle]:
        if vehicle_type:
            return [v for v in self.vehicles.values() if isinstance(v, vehicle_type)]
        return list(self.vehicles.values())
    
    def total_fleet_value(self) -> float:
        total = 0
        for vehicle in self.vehicles.values():
            base_value = 20000
            depreciation = (datetime.now().year - vehicle.year) * 0.1
            value = base_value * (1 - min(depreciation, 0.8))
            total += value
        return total
    
    def vehicles_needing_maintenance(self, threshold_km: float = 10000) -> List[Vehicle]:
        return [v for v in self.vehicles.values() if v.odometer > threshold_km]
    
    def total_maintenance_cost(self) -> float:
        return sum(v.maintenance_cost() for v in self.vehicles.values())
    
    def generate_report(self) -> str:
        report = "=== FLEET REPORT ===\n"
        report += f"Total Vehicles: {len(self.vehicles)}\n"
        report += f"Fleet Value: ${self.total_fleet_value():,.2f}\n"
        report += f"Total Maintenance Cost: ${self.total_maintenance_cost():,.2f}\n\n"
        
        report += "Vehicle Breakdown:\n"
        for vehicle_type in [Car, Motorcycle, Truck, Boat]:
            count = len(self.list_vehicles(vehicle_type))
            report += f"  {vehicle_type.__name__}s: {count}\n"
        
        report += f"\nVehicles Needing Maintenance: {len(self.vehicles_needing_maintenance())}\n"
        
        return report


if __name__ == "__main__":
    print("=== Testing Vehicle Factory ===")
    
    car = VehicleFactory.create_vehicle(
        'car', vehicle_id='C001', make='Toyota', model='Camry', year=2020,
        fuel_capacity=60, fuel_consumption=7.5, num_doors=4
    )
    
    motorcycle = VehicleFactory.create_vehicle(
        'motorcycle', vehicle_id='M001', make='Honda', model='CBR', year=2021,
        fuel_capacity=15, fuel_consumption=4.0, engine_cc=600
    )
    
    truck = VehicleFactory.create_vehicle(
        'truck', vehicle_id='T001', make='Ford', model='F-150', year=2019,
        fuel_capacity=100, fuel_consumption=12.0, cargo_capacity=1000
    )
    
    boat = VehicleFactory.create_vehicle(
        'boat', vehicle_id='B001', make='SeaRay', model='Sundancer', year=2018,
        fuel_capacity=200, fuel_consumption=20.0, displacement=5000, boat_type='Yacht'
    )
    
    print("=== Testing Vehicle Operations ===")
    print(car.start_engine())
    print(f"Range: {car.calculate_range():.2f} km")
    
    car.drive(100)
    print(f"After 100km: Odometer={car.odometer}, Fuel={car.fuel_level:.2f}L")
    
    car.refuel(20)
    print(f"After refuel: Fuel={car.fuel_level:.2f}L")
    
    print("\n=== Testing Fleet Manager ===")
    fleet = FleetManager()
    fleet.add_vehicle(car)
    fleet.add_vehicle(motorcycle)
    fleet.add_vehicle(truck)
    fleet.add_vehicle(boat)
    
    print(fleet.generate_report())
    
    print("\n=== Testing Truck Cargo ===")
    print(f"Truck range (empty): {truck.calculate_range():.2f} km")
    truck.load_cargo(500)
    print(f"Truck range (loaded 500kg): {truck.calculate_range():.2f} km")
    
    print("\n=== Testing Maintenance ===")
    car.add_maintenance("Oil change", 75.00)
    car.add_maintenance("Tire rotation", 50.00)
    print(f"Car maintenance log: {len(car.maintenance_log)} entries")
    print(f"Estimated maintenance cost: ${car.maintenance_cost():.2f}")
