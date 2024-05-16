### SOLID Principles
Based on decades of academic and developer experience
Purpose is to avoid software rot that leads to rigid and fragile code

**Single Responsibility Principle**
  * Does not really mean "should only have one reason to change"
  * Focus on stakeholders, who is most likely to request changes in your code
  * A module should be responsible to one and only one stakeholder
  * Keep your classes as small as possible

**Open Close Principle**
  * "A software artifact should only be open for extension but closed for modification"
  * Avoid introducing breaking changes into your and other's code

**Liskov Substitution Principle**
  * Contravariance of arguments
  * Covariance of result
  * Exception Rule - Exceptions thrown from a subclass method should be a subset of those thrown in the supertype method
  * Pre-Condition Rules - Arguments are not allowed to be more restrictive than superclass methods
  * Post-Condition Rules - Return type is not allowed to be weaker or less restrictive than super type method
  * Invariant Rules - Any assertion should always be true of super and sub class
  * Constraint Rules - Any constraint on superclass should be on sub class too

**Interface Segregation Principle**
  * "A client should never be forced to depend opn methods they do not use"
  * "A client should never be forced to implement an interface that it does not use"
  * Built around the principle of least knowledge

**Dependency Inversion Principle**
  * "High level modules should not depend on low level modules.  Both should depend upon abstractions"
  * Protects your code from changes in low level modules
  * Reduces coupling
  * Increases testability

### Other Principles
**DRY Principle**
  * "Don't Repeat Yourself"
  * Every piece of knowledge must have a single, unambiguous, authoritative representation in a system

**YAGNI**
  * You Ain't Gonna Need It
  * You cannot accurately predict the future
  * Stick to single responsibility
  * Do not increase complexity in an attempt to help future you

**KISS**
  * "Keep it simple, stupid"
  * Simple means a better user experience

**The Boy Scout Rule**
  * Leave your code better than when you found it

**Principle of Least Surprise**
  * Every component should behave in a way that most users expect it to behave
  * Consumers should trust their intuition
  * Obvious behaviors should be implemented