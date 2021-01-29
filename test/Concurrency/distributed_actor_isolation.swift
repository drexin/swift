// RUN: %target-typecheck-verify-swift -enable-experimental-concurrency
// REQUIRES: concurrency

actor class LocalActor_1 {
  let name: String = "alice"
  var mutable: String = "" // expected-note{{mutable state is only available within the actor instance}}
}

struct NotCodableValue { }

distributed struct StructNope {} // expected-error{{distributed' modifier cannot be applied to this declaration}}
distributed class ClassNope {} // expected-error{{'distributed' can only be applied to 'actor class' definitions, and distributed actor-isolated async functions}}
distributed enum EnumNope {} // expected-error{{distributed' modifier cannot be applied to this declaration}}

distributed actor class DistributedActor_1 {

  let name: String = "alice" // expected-note{{mutable state is only available within the actor instance}}
  var mutable: String = "alice" // expected-note{{mutable state is only available within the actor instance}}
  var computedMutable: String {
    get {
      "hey"
    }
    set {
      _ = newValue
    }
  }

  distributed let letProperty: String = "" // expected-error{{'distributed' modifier cannot be applied to this declaration}}
  distributed var varProperty: String = "" // expected-error{{'distributed' modifier cannot be applied to this declaration}}
  distributed var computedProperty: String { // expected-error{{'distributed' modifier cannot be applied to this declaration}}
    ""
  }

  distributed static func distributedStatic() {} // expected-error{{'distributed' functions cannot be 'static'}}

  func hello() {} // ok
  func helloAsync() async {} // ok
  func helloAsyncThrows() async throws {} // ok

  distributed func distHello() { } // ok
  distributed func distHelloAsync() async { } // ok
  distributed func distHelloThrows() throws { } // ok
  distributed func distHelloAsyncThrows() async throws { } // ok

  distributed func distInt() async throws -> Int { 42 } // ok
  distributed func distInt(int: Int) async throws -> Int { int } // ok

  distributed func dist(notCodable: NotCodableValue) async throws {
    // expected-error@-1 {{distributed function parameter 'notCodable' of type 'NotCodableValue' does not conform to 'Codable'}}
  }
  distributed func distBadReturn(int: Int) async throws -> NotCodableValue {
    // expected-error@-1 {{distributed function result type 'NotCodableValue' does not conform to 'Codable'}}
    fatalError()
  }

  distributed func distReturnGeneric<T: Codable>(int: Int) async throws -> T { // ok
    fatalError()
  }
  distributed func distReturnGenericWhere<T>(int: Int) async throws -> T where T: Codable { // ok
    fatalError()
  }
  distributed func distBadReturnGeneric<T>(int: Int) async throws -> T {
    // expected-error@-1 {{distributed function result type 'T' does not conform to 'Codable'}}
    fatalError()
  }

  distributed func distGenericParam<T: Codable>(value: T) async throws { // ok
    fatalError()
  }
  distributed func distGenericParamWhere<T>(value: T) async throws -> T where T: Codable { // ok
    fatalError()
  }
  distributed func distBadGenericParam<T>(int: T) async throws {
    // expected-error@-1 {{distributed function parameter 'int' of type 'T' does not conform to 'Codable'}}
    fatalError()
  }

  func test() async throws {
    _ = self.name
    _ = self.computedMutable

    _ = try await self.distInt()
    _ = try await self.distInt(int: 42)

    self.hello()
    _ = await self.helloAsync()
    _ = try await self.helloAsyncThrows()

    self.distHello()
    await self.distHelloAsync()
    try self.distHelloThrows()
    try await self.distHelloAsyncThrows()
  }
}

func test(
  local: LocalActor_1,
  distributed: DistributedActor_1
) async throws {
  _ = local.name // ok, special case that let constants are okey
  _ = distributed.name // expected-error{{distributed actor-isolated property 'name' can only be referenced inside the distributed actor}}
  _ = local.mutable // expected-error{{actor-isolated property 'mutable' can only be referenced inside the actor}}
  _ = distributed.mutable // expected-error{{distributed actor-isolated property 'mutable' can only be referenced inside the distributed actor}}

//  try await distributed.distHello()
//  try await distributed.distHelloAsync()
//  try await distributed.distHelloThrows()
//  try await distributed.distHelloAsyncThrows()
  
  // special: the actorAddress may always be referred to
  _ = distributed.actorAddress
}

// ==== Codable parameters and return types ------------------------------------

func test_params(
  distributed: DistributedActor_1
) async throws {
  _ = try await distributed.distInt() // ok
  _ = try await distributed.distInt(int: 42) // ok
  _ = try await distributed.dist(notCodable: .init())
}
