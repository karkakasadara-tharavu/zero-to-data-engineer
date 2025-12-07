# Lab 09: Game Character System with Composition

**Difficulty**: ⭐⭐⭐⭐⭐ (Advanced)  
**Estimated Time**: 70-90 minutes  
**Topics**: Composition, Strategy Pattern, Component-Based Design

---

## 🎯 Objectives

By completing this lab, you will:
- Apply composition over inheritance principle
- Implement component-based architecture
- Use strategy pattern for behavior variation
- Create flexible, extensible systems
- Avoid problems of deep inheritance hierarchies
- Build modular, reusable components

---

## 📋 Requirements

### Part 1: Component Classes

Create reusable component classes that can be composed:

**HealthComponent**:
- Attributes: `max_health`, `current_health`
- Methods: `take_damage(amount)`, `heal(amount)`, `is_alive()`, `get_health_percentage()`

**MovementComponent**:
- Attributes: `speed`, `position` (x, y coordinates)
- Methods: `move_to(x, y)`, `get_position()`, `get_distance_from(x, y)`

**AttackComponent**:
- Attributes: `attack_power`, `attack_range`, `attack_cooldown`
- Methods: `can_attack()`, `perform_attack()`, `reset_cooldown()`

**DefenseComponent**:
- Attributes: `armor`, `resistance` (percentage)
- Methods: `calculate_damage_reduction(incoming_damage)`, `upgrade_armor(amount)`

**InventoryComponent**:
- Attributes: `max_capacity`, `items` (list)
- Methods: `add_item(item)`, `remove_item(item)`, `has_item(item)`, `get_item_count()`, `is_full()`

**ExperienceComponent**:
- Attributes: `level`, `current_xp`, `xp_to_next_level`
- Methods: `add_xp(amount)`, `level_up()`, `get_level_progress()`

### Part 2: Strategy Pattern for Behaviors

Create strategy classes for varying behaviors:

**AttackStrategy** (Abstract Base):
- Abstract method: `execute_attack(attacker, target)`

**Concrete Strategies**:
- `MeleeAttackStrategy` - Close range, high damage
- `RangedAttackStrategy` - Long range, medium damage
- `MagicAttackStrategy` - Medium range, ignores armor
- `AreaAttackStrategy` - Damages multiple targets

**MovementStrategy** (Abstract Base):
- Abstract method: `execute_movement(character, destination)`

**Concrete Strategies**:
- `WalkMovementStrategy` - Normal speed, no restrictions
- `FlyMovementStrategy` - Faster, can cross obstacles
- `TeleportMovementStrategy` - Instant, limited by mana

### Part 3: Character Class Using Composition

Create a `GameCharacter` class that composes components:

**GameCharacter Class**:
- Compose all component classes
- Use strategy patterns for variable behavior
- Methods:
  - `attack(target)` - use attack strategy
  - `move(x, y)` - use movement strategy
  - `take_damage(amount)` - delegate to health and defense
  - `pick_up_item(item)` - delegate to inventory
  - `gain_experience(amount)` - delegate to experience
  - `get_stats()` - aggregate stats from all components
  - `change_attack_strategy(strategy)` - swap strategies at runtime
  - `change_movement_strategy(strategy)` - swap strategies at runtime

### Part 4: Character Factory

Create different character types using composition:

**CharacterFactory**:
- `create_warrior()` - High health, melee attack, heavy armor
- `create_mage()` - Low health, magic attack, low armor, teleport
- `create_archer()` - Medium health, ranged attack, medium armor
- `create_tank()` - Very high health, area attack, very heavy armor

---

## 💻 Starter Code

```python
from abc import ABC, abstractmethod
import math

# ============ Component Classes ============

class HealthComponent:
    """Manages character health"""
    
    def __init__(self, max_health):
        self.max_health = max_health
        self.current_health = max_health
    
    def take_damage(self, amount):
        """Reduce health by damage amount"""
        # TODO: Reduce current_health, minimum 0
        pass
    
    def heal(self, amount):
        """Increase health"""
        # TODO: Increase current_health, maximum max_health
        pass
    
    def is_alive(self):
        """Check if character is alive"""
        return self.current_health > 0
    
    def get_health_percentage(self):
        """Return health as percentage"""
        # TODO: Calculate percentage
        pass

class MovementComponent:
    """Manages character position and movement"""
    
    def __init__(self, speed):
        self.speed = speed
        self.position = (0, 0)
    
    def move_to(self, x, y):
        """Move to new position"""
        # TODO: Update position
        self.position = (x, y)
    
    def get_position(self):
        """Get current position"""
        return self.position
    
    def get_distance_from(self, x, y):
        """Calculate distance from given point"""
        # TODO: Use Euclidean distance formula
        pass

class AttackComponent:
    """Manages attack capabilities"""
    
    def __init__(self, attack_power, attack_range):
        self.attack_power = attack_power
        self.attack_range = attack_range
        self.cooldown_remaining = 0
    
    def can_attack(self):
        """Check if attack is ready"""
        return self.cooldown_remaining == 0
    
    def perform_attack(self):
        """Execute attack and set cooldown"""
        if self.can_attack():
            self.cooldown_remaining = 2  # 2 turns cooldown
            return self.attack_power
        return 0
    
    def reset_cooldown(self):
        """Reduce cooldown"""
        if self.cooldown_remaining > 0:
            self.cooldown_remaining -= 1

class DefenseComponent:
    """Manages defense and damage reduction"""
    
    def __init__(self, armor, resistance=0):
        self.armor = armor
        self.resistance = resistance  # Percentage (0-100)
    
    def calculate_damage_reduction(self, incoming_damage):
        """Calculate actual damage after defense"""
        # TODO: Apply armor and resistance
        # Formula: damage * (1 - resistance/100) - armor
        pass
    
    def upgrade_armor(self, amount):
        """Increase armor"""
        self.armor += amount

class InventoryComponent:
    """Manages character inventory"""
    
    def __init__(self, max_capacity=10):
        self.max_capacity = max_capacity
        self.items = []
    
    def add_item(self, item):
        """Add item to inventory"""
        # TODO: Check capacity and add item
        pass
    
    def remove_item(self, item):
        """Remove item from inventory"""
        # TODO: Remove item if exists
        pass
    
    def has_item(self, item):
        """Check if item exists"""
        return item in self.items
    
    def get_item_count(self):
        """Return number of items"""
        return len(self.items)
    
    def is_full(self):
        """Check if inventory is full"""
        return len(self.items) >= self.max_capacity

class ExperienceComponent:
    """Manages character level and experience"""
    
    def __init__(self):
        self.level = 1
        self.current_xp = 0
        self.xp_to_next_level = 100
    
    def add_xp(self, amount):
        """Add experience points"""
        # TODO: Add XP and check for level up
        pass
    
    def level_up(self):
        """Increase level"""
        self.level += 1
        self.current_xp = 0
        self.xp_to_next_level = int(self.xp_to_next_level * 1.5)
        return f"Level up! Now level {self.level}"
    
    def get_level_progress(self):
        """Return XP progress percentage"""
        return (self.current_xp / self.xp_to_next_level) * 100

# ============ Strategy Pattern Classes ============

class AttackStrategy(ABC):
    """Abstract base for attack strategies"""
    
    @abstractmethod
    def execute_attack(self, attacker, target):
        """Execute attack on target"""
        pass

class MeleeAttackStrategy(AttackStrategy):
    """Close range physical attack"""
    
    def execute_attack(self, attacker, target):
        """Execute melee attack"""
        # TODO: Check range, perform attack, apply damage
        # Melee range should be <= 2 units
        pass

class RangedAttackStrategy(AttackStrategy):
    """Long range physical attack"""
    
    def execute_attack(self, attacker, target):
        """Execute ranged attack"""
        # TODO: Check range (up to 10 units), perform attack
        # Ranged does 80% damage
        pass

class MagicAttackStrategy(AttackStrategy):
    """Magical attack that ignores armor"""
    
    def execute_attack(self, attacker, target):
        """Execute magic attack"""
        # TODO: Check range (up to 8 units), ignore armor
        pass

class AreaAttackStrategy(AttackStrategy):
    """Attack that hits multiple targets"""
    
    def execute_attack(self, attacker, targets):
        """Execute area attack on multiple targets"""
        # TODO: Attack all targets in range
        # Deals 60% damage to each
        pass

class MovementStrategy(ABC):
    """Abstract base for movement strategies"""
    
    @abstractmethod
    def execute_movement(self, character, x, y):
        """Move character to destination"""
        pass

class WalkMovementStrategy(MovementStrategy):
    """Normal walking movement"""
    
    def execute_movement(self, character, x, y):
        """Walk to destination"""
        # TODO: Move using character's speed
        pass

class FlyMovementStrategy(MovementStrategy):
    """Flying movement (faster)"""
    
    def execute_movement(self, character, x, y):
        """Fly to destination"""
        # TODO: Move at 1.5x speed
        pass

class TeleportMovementStrategy(MovementStrategy):
    """Instant teleportation"""
    
    def execute_movement(self, character, x, y):
        """Teleport to destination"""
        # TODO: Instant movement
        pass

# ============ Game Character Class ============

class GameCharacter:
    """Character class using composition"""
    
    def __init__(self, name, health, speed, attack_power, attack_range, armor):
        self.name = name
        
        # Compose components
        self.health = HealthComponent(health)
        self.movement = MovementComponent(speed)
        self.attack = AttackComponent(attack_power, attack_range)
        self.defense = DefenseComponent(armor)
        self.inventory = InventoryComponent()
        self.experience = ExperienceComponent()
        
        # Strategy patterns (can be changed at runtime)
        self.attack_strategy = MeleeAttackStrategy()
        self.movement_strategy = WalkMovementStrategy()
    
    def attack_target(self, target):
        """Attack another character"""
        # TODO: Use attack_strategy to execute attack
        pass
    
    def move(self, x, y):
        """Move to position"""
        # TODO: Use movement_strategy
        pass
    
    def take_damage(self, amount):
        """Take damage from attack"""
        # TODO: Use defense to calculate actual damage
        # TODO: Use health to apply damage
        pass
    
    def pick_up_item(self, item):
        """Pick up an item"""
        # TODO: Use inventory component
        pass
    
    def gain_experience(self, amount):
        """Gain XP"""
        # TODO: Use experience component
        pass
    
    def change_attack_strategy(self, strategy):
        """Change attack behavior at runtime"""
        self.attack_strategy = strategy
        return f"{self.name} changed attack strategy to {strategy.__class__.__name__}"
    
    def change_movement_strategy(self, strategy):
        """Change movement behavior at runtime"""
        self.movement_strategy = strategy
        return f"{self.name} changed movement strategy to {strategy.__class__.__name__}"
    
    def get_stats(self):
        """Get character statistics"""
        return {
            'name': self.name,
            'level': self.experience.level,
            'health': f"{self.health.current_health}/{self.health.max_health}",
            'attack_power': self.attack.attack_power,
            'armor': self.defense.armor,
            'position': self.movement.position,
            'items': self.inventory.get_item_count()
        }
    
    def __str__(self):
        stats = self.get_stats()
        return f"{stats['name']} (Lv.{stats['level']}) - HP: {stats['health']}, ATK: {stats['attack_power']}"

# ============ Character Factory ============

class CharacterFactory:
    """Factory for creating pre-configured characters"""
    
    @staticmethod
    def create_warrior(name):
        """Create warrior character"""
        # TODO: High health, melee attack, heavy armor
        char = GameCharacter(name, health=150, speed=5, attack_power=25, 
                           attack_range=2, armor=15)
        char.attack_strategy = MeleeAttackStrategy()
        return char
    
    @staticmethod
    def create_mage(name):
        """Create mage character"""
        # TODO: Low health, magic attack, teleport
        char = GameCharacter(name, health=80, speed=4, attack_power=35,
                           attack_range=8, armor=5)
        char.attack_strategy = MagicAttackStrategy()
        char.movement_strategy = TeleportMovementStrategy()
        return char
    
    @staticmethod
    def create_archer(name):
        """Create archer character"""
        # TODO: Medium health, ranged attack
        char = GameCharacter(name, health=100, speed=6, attack_power=20,
                           attack_range=10, armor=8)
        char.attack_strategy = RangedAttackStrategy()
        return char
    
    @staticmethod
    def create_tank(name):
        """Create tank character"""
        # TODO: Very high health, area attack, heavy armor
        char = GameCharacter(name, health=200, speed=3, attack_power=15,
                           attack_range=3, armor=25)
        char.attack_strategy = AreaAttackStrategy()
        return char

# Test your implementation
if __name__ == "__main__":
    print("=== Creating Characters ===")
    warrior = CharacterFactory.create_warrior("Thorin")
    mage = CharacterFactory.create_mage("Gandalf")
    archer = CharacterFactory.create_archer("Legolas")
    
    print(warrior)
    print(mage)
    print(archer)
    
    print("\n=== Testing Movement ===")
    warrior.move(5, 5)
    mage.move(10, 10)
    print(f"Warrior at {warrior.movement.get_position()}")
    print(f"Mage at {mage.movement.get_position()}")
    
    print("\n=== Testing Combat ===")
    warrior.attack_target(mage)
    archer.attack_target(warrior)
    
    print(f"Mage health: {mage.health.get_health_percentage():.1f}%")
    print(f"Warrior health: {warrior.health.get_health_percentage():.1f}%")
    
    print("\n=== Changing Strategies ===")
    print(warrior.change_attack_strategy(RangedAttackStrategy()))
    print(mage.change_movement_strategy(FlyMovementStrategy()))
    
    print("\n=== Character Stats ===")
    for char in [warrior, mage, archer]:
        print(f"\n{char.name}:")
        for key, value in char.get_stats().items():
            print(f"  {key}: {value}")
```

---

## 🎯 Expected Output

```
=== Creating Characters ===
Thorin (Lv.1) - HP: 150/150, ATK: 25
Gandalf (Lv.1) - HP: 80/80, ATK: 35
Legolas (Lv.1) - HP: 100/100, ATK: 20

=== Testing Movement ===
Warrior at (5, 5)
Mage at (10, 10)

=== Testing Combat ===
✓ Thorin attacks Gandalf with Melee for 25 damage!
  Gandalf takes 20 damage after defense
✗ Legolas is too far to attack Thorin

Mage health: 75.0%
Warrior health: 100.0%

=== Changing Strategies ===
Thorin changed attack strategy to RangedAttackStrategy
Gandalf changed movement strategy to FlyMovementStrategy

=== Character Stats ===

Thorin:
  name: Thorin
  level: 1
  health: 150/150
  attack_power: 25
  armor: 15
  position: (5, 5)
  items: 0

Gandalf:
  name: Gandalf
  level: 1
  health: 60/80
  attack_power: 35
  armor: 5
  position: (10, 10)
  items: 0

Legolas:
  name: Legolas
  level: 1
  health: 100/100
  attack_power: 20
  armor: 8
  position: (0, 0)
  items: 0
```

---

## ✅ Validation Checklist

- [ ] All components are independent and reusable
- [ ] Character uses composition, not inheritance
- [ ] Strategy pattern allows runtime behavior changes
- [ ] Attack strategies work correctly with different ranges
- [ ] Movement strategies provide different movement capabilities
- [ ] Damage calculation considers armor and resistance
- [ ] Health component prevents negative health
- [ ] Inventory enforces capacity limits
- [ ] Experience component handles level-ups correctly
- [ ] Character factory creates properly configured characters
- [ ] Components can be easily added/removed
- [ ] System is flexible and extensible

---

## 🚀 Extension Challenges

1. **Skill System**: Add skill components with cooldowns
2. **Status Effects**: Add buff/debuff system (poison, stun, etc.)
3. **Equipment System**: Add equipment that modifies components
4. **AI Behavior**: Add AI strategy pattern for NPCs
5. **Quest System**: Add quest component with objectives
6. **Party System**: Create party/team management
7. **Persistence**: Save/load character state to JSON
8. **Combat System**: Full turn-based combat system

---

## 💡 Key Concepts Demonstrated

- **Composition Over Inheritance**: Building complex objects from simple parts
- **Component-Based Architecture**: Modular, reusable components
- **Strategy Pattern**: Swappable behaviors at runtime
- **Separation of Concerns**: Each component has single responsibility
- **Flexibility**: Easy to add new components or strategies
- **Code Reuse**: Components work with any character type

---

## 📚 Related Theory Sections

- `10_composition_vs_inheritance.md` - When to use composition
- `05_polymorphism.md` - Strategy pattern examples
- `09_abstract_base_classes.md` - Abstract strategy classes

---

**Good luck! ⚔️🏹🧙‍♂️**
