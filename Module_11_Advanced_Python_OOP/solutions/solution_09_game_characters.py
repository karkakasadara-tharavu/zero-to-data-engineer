# Lab 09 Solution: Game Characters System

"""Complete solution for Game Characters lab.
Demonstrates: Composition, Strategy Pattern, Component Architecture"""

from abc import ABC, abstractmethod
from typing import List, Dict
import random


# ===== COMPONENT CLASSES =====

class HealthComponent:
    def __init__(self, max_health: int = 100):
        self.max_health = max_health
        self.current_health = max_health
    
    def take_damage(self, amount: int):
        self.current_health = max(0, self.current_health - amount)
        return self.current_health <= 0
    
    def heal(self, amount: int):
        self.current_health = min(self.max_health, self.current_health + amount)
    
    def is_alive(self) -> bool:
        return self.current_health > 0
    
    def health_percentage(self) -> float:
        return (self.current_health / self.max_health) * 100


class MovementComponent:
    def __init__(self, speed: int = 10):
        self.speed = speed
        self.x = 0
        self.y = 0
    
    def move_to(self, x: int, y: int):
        self.x = x
        self.y = y
    
    def get_position(self) -> tuple:
        return (self.x, self.y)


class AttackComponent:
    def __init__(self, base_damage: int = 20):
        self.base_damage = base_damage
    
    def calculate_damage(self) -> int:
        return random.randint(int(self.base_damage * 0.8), int(self.base_damage * 1.2))


class DefenseComponent:
    def __init__(self, armor: int = 10):
        self.armor = armor
    
    def reduce_damage(self, incoming_damage: int) -> int:
        reduction = self.armor * 0.5
        return max(1, int(incoming_damage - reduction))


class InventoryComponent:
    def __init__(self, max_capacity: int = 20):
        self.max_capacity = max_capacity
        self.items: Dict[str, int] = {}
    
    def add_item(self, item: str, quantity: int = 1) -> bool:
        total_items = sum(self.items.values())
        if total_items + quantity > self.max_capacity:
            return False
        
        self.items[item] = self.items.get(item, 0) + quantity
        return True
    
    def remove_item(self, item: str, quantity: int = 1) -> bool:
        if item not in self.items or self.items[item] < quantity:
            return False
        
        self.items[item] -= quantity
        if self.items[item] == 0:
            del self.items[item]
        return True
    
    def has_item(self, item: str) -> bool:
        return item in self.items and self.items[item] > 0


class ExperienceComponent:
    def __init__(self):
        self.level = 1
        self.experience = 0
        self.experience_to_next_level = 100
    
    def add_experience(self, amount: int):
        self.experience += amount
        
        while self.experience >= self.experience_to_next_level:
            self.level_up()
    
    def level_up(self):
        self.experience -= self.experience_to_next_level
        self.level += 1
        self.experience_to_next_level = int(self.experience_to_next_level * 1.5)


# ===== STRATEGY INTERFACES =====

class AttackStrategy(ABC):
    @abstractmethod
    def attack(self, attacker, target) -> str:
        pass


class MovementStrategy(ABC):
    @abstractmethod
    def move(self, character, x: int, y: int) -> str:
        pass


# ===== ATTACK STRATEGIES =====

class MeleeAttackStrategy(AttackStrategy):
    def attack(self, attacker, target) -> str:
        damage = attacker.attack_component.calculate_damage()
        reduced_damage = target.defense_component.reduce_damage(damage)
        is_dead = target.health_component.take_damage(reduced_damage)
        
        result = f"{attacker.name} strikes {target.name} with melee for {reduced_damage} damage!"
        if is_dead:
            result += f" {target.name} has been defeated!"
        return result


class RangedAttackStrategy(AttackStrategy):
    def attack(self, attacker, target) -> str:
        damage = int(attacker.attack_component.calculate_damage() * 0.8)
        reduced_damage = target.defense_component.reduce_damage(damage)
        is_dead = target.health_component.take_damage(reduced_damage)
        
        result = f"{attacker.name} shoots {target.name} with a ranged attack for {reduced_damage} damage!"
        if is_dead:
            result += f" {target.name} has been defeated!"
        return result


class MagicAttackStrategy(AttackStrategy):
    def attack(self, attacker, target) -> str:
        damage = int(attacker.attack_component.calculate_damage() * 1.5)
        is_dead = target.health_component.take_damage(damage)
        
        result = f"{attacker.name} casts a spell on {target.name} for {damage} magic damage (ignores armor)!"
        if is_dead:
            result += f" {target.name} has been defeated!"
        return result


class AreaAttackStrategy(AttackStrategy):
    def attack(self, attacker, target) -> str:
        damage = int(attacker.attack_component.calculate_damage() * 0.6)
        reduced_damage = target.defense_component.reduce_damage(damage)
        is_dead = target.health_component.take_damage(reduced_damage)
        
        result = f"{attacker.name} unleashes area attack hitting {target.name} for {reduced_damage} damage!"
        if is_dead:
            result += f" {target.name} has been defeated!"
        return result


# ===== MOVEMENT STRATEGIES =====

class WalkMovementStrategy(MovementStrategy):
    def move(self, character, x: int, y: int) -> str:
        character.movement_component.move_to(x, y)
        return f"{character.name} walks to position ({x}, {y})"


class FlyMovementStrategy(MovementStrategy):
    def move(self, character, x: int, y: int) -> str:
        character.movement_component.move_to(x, y)
        return f"{character.name} flies swiftly to position ({x}, {y})"


class TeleportMovementStrategy(MovementStrategy):
    def move(self, character, x: int, y: int) -> str:
        character.movement_component.move_to(x, y)
        return f"{character.name} teleports instantly to position ({x}, {y})"


# ===== GAME CHARACTER =====

class GameCharacter:
    def __init__(self, name: str, max_health: int, base_damage: int, 
                 armor: int, speed: int, attack_strategy: AttackStrategy,
                 movement_strategy: MovementStrategy):
        self.name = name
        
        # Initialize all components
        self.health_component = HealthComponent(max_health)
        self.movement_component = MovementComponent(speed)
        self.attack_component = AttackComponent(base_damage)
        self.defense_component = DefenseComponent(armor)
        self.inventory_component = InventoryComponent()
        self.experience_component = ExperienceComponent()
        
        # Set strategies
        self.attack_strategy = attack_strategy
        self.movement_strategy = movement_strategy
    
    def attack(self, target):
        if not self.health_component.is_alive():
            return f"{self.name} is defeated and cannot attack!"
        return self.attack_strategy.attack(self, target)
    
    def move(self, x: int, y: int):
        if not self.health_component.is_alive():
            return f"{self.name} is defeated and cannot move!"
        return self.movement_strategy.move(self, x, y)
    
    def change_attack_strategy(self, new_strategy: AttackStrategy):
        self.attack_strategy = new_strategy
        return f"{self.name} changed attack strategy to {new_strategy.__class__.__name__}"
    
    def change_movement_strategy(self, new_strategy: MovementStrategy):
        self.movement_strategy = new_strategy
        return f"{self.name} changed movement strategy to {new_strategy.__class__.__name__}"
    
    def get_status(self) -> str:
        status = f"\n=== {self.name} ===\n"
        status += f"Level: {self.experience_component.level}\n"
        status += f"Health: {self.health_component.current_health}/{self.health_component.max_health} "
        status += f"({self.health_component.health_percentage():.1f}%)\n"
        status += f"Attack: {self.attack_component.base_damage} | Armor: {self.defense_component.armor}\n"
        status += f"Position: {self.movement_component.get_position()}\n"
        status += f"Attack Style: {self.attack_strategy.__class__.__name__}\n"
        status += f"Movement: {self.movement_strategy.__class__.__name__}\n"
        status += f"Inventory: {len(self.inventory_component.items)} item types\n"
        return status


# ===== CHARACTER FACTORY =====

class CharacterFactory:
    @staticmethod
    def create_warrior(name: str) -> GameCharacter:
        return GameCharacter(
            name=name,
            max_health=150,
            base_damage=30,
            armor=20,
            speed=8,
            attack_strategy=MeleeAttackStrategy(),
            movement_strategy=WalkMovementStrategy()
        )
    
    @staticmethod
    def create_mage(name: str) -> GameCharacter:
        return GameCharacter(
            name=name,
            max_health=80,
            base_damage=40,
            armor=5,
            speed=10,
            attack_strategy=MagicAttackStrategy(),
            movement_strategy=TeleportMovementStrategy()
        )
    
    @staticmethod
    def create_archer(name: str) -> GameCharacter:
        return GameCharacter(
            name=name,
            max_health=100,
            base_damage=25,
            armor=10,
            speed=12,
            attack_strategy=RangedAttackStrategy(),
            movement_strategy=WalkMovementStrategy()
        )
    
    @staticmethod
    def create_tank(name: str) -> GameCharacter:
        return GameCharacter(
            name=name,
            max_health=200,
            base_damage=20,
            armor=30,
            speed=6,
            attack_strategy=MeleeAttackStrategy(),
            movement_strategy=WalkMovementStrategy()
        )


# ===== TESTING =====

if __name__ == "__main__":
    print("=== Creating Characters ===")
    
    warrior = CharacterFactory.create_warrior("Conan")
    mage = CharacterFactory.create_mage("Gandalf")
    archer = CharacterFactory.create_archer("Legolas")
    tank = CharacterFactory.create_tank("Reinhardt")
    
    print(warrior.get_status())
    print(mage.get_status())
    
    print("\n=== Combat Testing ===")
    print(warrior.attack(mage))
    print(mage.attack(warrior))
    print(archer.attack(warrior))
    
    print(mage.get_status())
    print(warrior.get_status())
    
    print("\n=== Movement Testing ===")
    print(warrior.move(10, 5))
    print(mage.move(20, 15))
    print(archer.move(30, 25))
    
    print("\n=== Strategy Change Testing ===")
    print(warrior.change_attack_strategy(AreaAttackStrategy()))
    print(warrior.attack(mage))
    
    print(archer.change_movement_strategy(FlyMovementStrategy()))
    print(archer.move(50, 50))
    
    print("\n=== Inventory Testing ===")
    warrior.inventory_component.add_item("Health Potion", 3)
    warrior.inventory_component.add_item("Sword", 1)
    print(f"Warrior inventory: {warrior.inventory_component.items}")
    
    print("\n=== Experience Testing ===")
    warrior.experience_component.add_experience(120)
    print(f"Warrior level: {warrior.experience_component.level}")
    print(f"Warrior XP: {warrior.experience_component.experience}/{warrior.experience_component.experience_to_next_level}")
    
    print("\n=== Final Status ===")
    print(warrior.get_status())
    print(mage.get_status())
