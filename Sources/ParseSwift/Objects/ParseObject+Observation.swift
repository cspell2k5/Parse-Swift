    //
    //  ParseObjectObservable.swift
    //  ParseSwift
    //
    //  Created by Craig Spell on 2/10/26.
    //

import SwiftUI

    /// A lightweight, observable wrapper around a ParseObject that integrates with SwiftUI’s Observation framework.
    ///
    /// ParseObjectObservable enables two key capabilities when working with types conforming to `ParseObject`:
    /// - Observation: It uses the `@Observable` macro (iOS 17, macOS 14 and later) so SwiftUI views can automatically
    ///   update when properties on the underlying object change.
    /// - Dynamic member lookup: It forwards property access to the wrapped `ParseObject` using `@dynamicMemberLookup`,
    ///   allowing you to read and write properties directly as if they were defined on this wrapper.
    ///
    /// Usage:
    /// - Wrap any `ParseObject` instance using the `asObservable` convenience property:
    ///   - Example: `@State private var todo = Todo().asObservable`
    /// - Access and mutate properties as usual:
    ///   - Example: `todo.title = "New Title"`
    /// - Call async persistence methods (`fetch`, `save`, `create`, `replace`, `update`, `delete`) on the wrapper to
    ///   keep the observable state in sync with the server. Successful mutating operations automatically replace the
    ///   internal value and trigger view updates.
    ///
    /// Notes:
    /// - Availability: iOS 17.0+, macOS 14.0+, tvOS 17.0+, watchOS 10.0+.
    /// - Threading: Isolated to the main actor in UI code; ensure you call async methods appropriately
    ///   within Swift concurrency contexts.
    /// - Identity: This wrapper holds and replaces the underlying value on successful network operations. If your UI
    ///   depends on object identity (e.g., `id`, `objectId`, `hashValue`), be mindful that the wrapped instance may be
    ///   replaced after calls like `save()` or `fetch()`.
    ///
    /// - Generic Parameter:
    ///   - T: A type conforming to `ParseObject` that represents the underlying Parse model.
@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
@MainActor
@Observable @dynamicMemberLookup
public class ParseObjectObservable<T: ParseObject> {
    public var wrappedValue: T
    
    public init(_ value: T) {
        self.wrappedValue = value
    }
    
        /// Provides dynamic member lookup into the wrapped ParseObject.
        ///
        /// This subscript enables forwarding property access from the observable wrapper
        /// directly to the underlying `ParseObject` using key path-based dynamic member
        /// lookup. It allows reading and writing properties as if they were defined on
        /// `ParseObjectObservable` itself.
        ///
        /// - Parameter keyPath: A writable key path referencing a property on the
        ///   underlying `ParseObject` type `T`.
        /// - Returns: The value of the property referenced by `keyPath`.
        ///
        /// Usage:
        /// - Read a property: `let title = todo.title`
        /// - Write a property: `todo.title = "New Title"`
        ///
        /// Notes:
        /// - Because the key path is writable, setting a value mutates the wrapped
        ///   `ParseObject`. This mutation participates in SwiftUI’s Observation system
        ///   via the `@Observable` macro on this wrapper, causing dependent views to
        ///   update.
        /// - The generic `V` is the property type referenced by the provided key path.
        /// - This is intended for use with properties defined on `T` that are exposed
        ///   via `WritableKeyPath`.
    public subscript<V>(dynamicMember keyPath: WritableKeyPath<T, V>) -> V {
        get { wrappedValue[keyPath: keyPath] }
        set { wrappedValue[keyPath: keyPath] = newValue }
    }
    
        /// Provides read-only dynamic member lookup into the wrapped ParseObject.
        ///
        /// This subscript forwards property access from the observable wrapper
        /// directly to the underlying `ParseObject` using key path–based dynamic
        /// member lookup. It enables reading properties as if they were defined
        /// on `ParseObjectObservable` itself, without allowing mutation.
        ///
        /// Use this overload when you only need to read a property (i.e., when
        /// the property on `T` is exposed via a non-writable `KeyPath`). For
        /// properties that can be mutated, see the writable
        /// `subscript(dynamicMember:)` that accepts a `WritableKeyPath`.
        ///
        /// - Parameter keyPath: A read-only key path referencing a property on the
        ///   underlying `ParseObject` type `T`.
        /// - Returns: The value of the property referenced by `keyPath`.
        ///
        /// Example:
        /// - Read a property:
        ///   `let title = todo.title`
        ///
        /// Notes:
        /// - This subscript does not permit mutation. To write through to the
        ///   wrapped object, use the writable dynamic member subscript.
        /// - Accessing properties through this subscript participates in SwiftUI’s
        ///   Observation system because the wrapper is annotated with `@Observable`.
    public subscript<V>(dynamicMember keyPath: KeyPath<T, V>) -> V {
        get { wrappedValue[keyPath: keyPath] }
    }

}


@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
public extension ParseObject {
        /// A lightweight convenience property that wraps a `ParseObject` in an observable
        /// wrapper compatible with SwiftUI’s Observation framework.
        ///
        /// This property returns a `ParseObjectObservable<Self>` which:
        /// - Enables SwiftUI views to automatically update when properties on the object change,
        ///   leveraging the `@Observable` macro (iOS 17, macOS 14 and later).
        /// - Supports dynamic member lookup so you can access and mutate properties directly
        ///   on the wrapper as if they were defined on the original `ParseObject`.
        ///
        /// Usage:
        /// - Create an observable instance for use in SwiftUI state:
        ///   - `@State private var todo = Todo().asObservable`
        /// - Read and write properties as usual:
        ///   - `todo.title = "New Title"`
        /// - Call async persistence methods on the wrapper to keep state in sync with the server:
        ///   - `try await todo.save()`
        ///
        /// Notes:
        /// - Availability: iOS 17.0+, macOS 14.0+, tvOS 17.0+, watchOS 10.0+.
        /// - Identity: Successful network operations like `save()` or `fetch()` may replace the
        ///   underlying value inside the wrapper. If your UI depends on identity (e.g., `objectId`),
        ///   account for this behavior.
        /// - Threading: Isolated to the main actor; call async methods
        ///   within appropriate Swift concurrency contexts.
        ///
        /// - Returns: An observable wrapper around the receiver that integrates with SwiftUI Observation.
    @MainActor
    var asObservable: ParseObjectObservable<Self> {
        ParseObjectObservable(self)
    }
}


@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
@MainActor
public extension ParseObjectObservable {
    
        /// Fetches the latest state of the underlying Parse object from the server and updates this observable wrapper.
        ///
        /// This method issues a network request to retrieve the most current representation of the wrapped object (`T`)
        /// from your Parse backend. On success, the internal `value` is replaced with the fetched instance, which
        /// automatically notifies SwiftUI’s Observation system (via `@Observable`) so any dependent views are refreshed.
        ///
        /// - Parameters:
        ///   - includeKeys: An optional array of key names to include in the fetch. Use this to eagerly load related objects
        ///                  or specific fields that are not returned by default. Pass `nil` to use the server’s defaults.
        ///   - options: Additional request options to control networking behavior, caching, and other Parse client features.
        ///              Defaults to an empty set.
        /// - Returns: The freshly fetched object of type `T`.
        /// - Throws: An error if the network request fails, the object cannot be found, or if the response cannot be decoded.
        /// - Important: This method replaces the wrapped object on success. If your UI or logic depends on identity
        ///              (e.g., `objectId` or hashing), be aware the instance may change after the call completes.
        /// - Availability: iOS 17.0+, macOS 14.0+, tvOS 17.0+, watchOS 10.0+.
        /// - Concurrency: Intended for use on the main actor in UI contexts; call from an async context.
    @discardableResult func fetch(includeKeys: [String]? = nil,
                                  options: API.Options = []) async throws -> T {
        let newValue = try await wrappedValue.fetch(includeKeys: includeKeys, options: options)
        self.wrappedValue = newValue
        return newValue
    }
    
        /// Persists the current state of the wrapped Parse object to the server and updates this observable wrapper on success.
        ///
        /// This method forwards to `T.save(ignoringCustomObjectIdConfig:options:)` on the underlying `ParseObject`,
        /// replacing the internal value with the server-returned instance when the save completes successfully.
        /// Because `ParseObjectObservable` is annotated with `@Observable`, replacing the value automatically
        /// notifies SwiftUI’s Observation system, causing dependent views to refresh.
        ///
        /// - Parameters:
        ///   - ignoringCustomObjectIdConfig: When `true`, bypasses any client-side configuration that enforces custom
        ///     objectId behavior and allows the server to determine or accept the provided `objectId`. Leave as `false`
        ///     to respect the SDK’s configured custom objectId rules. Defaults to `false`.
        ///   - options: Additional request options that control networking behavior, caching, and other Parse client
        ///     features. Defaults to an empty set.
        /// - Returns: The saved object of type `T` as returned by the server. This is also assigned to the wrapper’s
        ///   internal value, which triggers observation updates.
        /// - Throws: An error if the save operation fails due to networking issues, validation errors, or decoding problems.
        /// - Important: Successful saves replace the wrapped instance. If your UI or logic depends on identity (e.g.,
        ///   `objectId`, equality, or hashing), be aware the instance may change after this call completes.
        /// - Availability: iOS 17.0+, macOS 14.0+, tvOS 17.0+, watchOS 10.0+.
        /// - Concurrency: Intended for use in async contexts on the main actor in UI code.
    @discardableResult func save(ignoringCustomObjectIdConfig: Bool = false,
                                 options: API.Options = []) async throws -> T {
        let newValue = try await wrappedValue.save(ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig, options: options)
        self.wrappedValue = newValue
        return newValue
    }
    
        /// Creates a new instance of the underlying Parse object on the server and updates this observable wrapper.
        ///
        /// This method forwards to `T.create(options:)` on the wrapped `ParseObject`, issuing a network request to persist
        /// the object as a brand-new record (typically one without an existing `objectId`). On success, the server-returned
        /// instance replaces the internal `value`, which, because this wrapper is annotated with `@Observable`, triggers
        /// SwiftUI Observation updates so any dependent views refresh automatically.
        ///
        /// - Parameter options: Additional request options that control networking behavior, caching, and other Parse client
        ///   features. Defaults to an empty set.
        /// - Returns: The newly created object of type `T` as returned by the server. This instance also replaces the wrapper’s
        ///   internal value, causing observers to be notified.
        /// - Throws: An error if the create operation fails due to networking issues, validation errors, permissions, or
        ///   decoding problems.
        ///
        /// - Important:
        ///   - This method is intended for creating brand-new objects. If the object already has an `objectId`, consider using
        ///     `save`, `replace`, or `update` as appropriate.
        ///   - Successful creation replaces the wrapped instance. If your UI or logic depends on identity (e.g., `objectId`,
        ///     equality, or hashing), be aware the instance may change after this call completes.
        ///
        /// - Availability: iOS 17.0+, macOS 14.0+, tvOS 17.0+, watchOS 10.0+.
        /// - Concurrency: Intended for use from async contexts on the main actor in UI code.
    @discardableResult func create(options: API.Options = []) async throws -> T {
        let newValue = try await wrappedValue.create(options: options)
        self.wrappedValue = newValue
        return newValue
    }
    
        /// Replaces the existing server-side representation of the wrapped Parse object and updates this observable wrapper.
        ///
        /// This method forwards to `T.replace(options:)` on the underlying `ParseObject`, performing a full replacement
        /// of the object on the server (typically used when you want the server record to match the current local state
        /// exactly). On success, the server-returned instance replaces the internal `value`. Because this wrapper is
        /// annotated with `@Observable`, replacing the value automatically triggers SwiftUI Observation updates so
        /// dependent views refresh.
        ///
        /// - Parameter options: Additional request options that control networking behavior, caching, and other Parse client
        ///   features. Defaults to an empty set.
        /// - Returns: The replaced object of type `T` as returned by the server. This instance also replaces the wrapper’s
        ///   internal value, notifying observers of the change.
        /// - Throws: An error if the replace operation fails due to networking issues, permissions, validation errors,
        ///   or decoding problems.
        /// - Important:
        ///   - Use `replace` when you intend to overwrite the server’s state with the current local state of the object.
        ///     If you only need to modify specific fields, consider using `update` instead; to create a new record, use `create`.
        ///   - Successful replacement replaces the wrapped instance. If your UI or logic depends on identity (e.g., `objectId`,
        ///     equality, or hashing), be aware the instance may change after this call completes.
        /// - Availability: iOS 17.0+, macOS 14.0+, tvOS 17.0+, watchOS 10.0+.
        /// - Concurrency: Intended for use from async contexts on the main actor in UI code.
    @discardableResult func replace(options: API.Options = []) async throws -> T {
        let newValue = try await wrappedValue.replace(options: options)
        self.wrappedValue = newValue
        return newValue
    }
    
        /// Applies partial changes to the existing server-side representation of the wrapped Parse object and updates this observable wrapper.
        ///
        /// This method forwards to `T.update(options:)` on the underlying `ParseObject`, sending only the fields that have
        /// changed since the object was last fetched or saved. On success, the server-returned instance replaces the internal
        /// `value`. Because this wrapper is annotated with `@Observable`, replacing the value automatically triggers SwiftUI
        /// Observation updates so dependent views refresh.
        ///
        /// Use this when you need to modify specific fields rather than replace the entire object. For full replacement,
        /// consider using `replace(options:)`; to create a new record, use `create(options:)`; and to let the SDK decide the
        /// appropriate operation based on object state, use `save(ignoringCustomObjectIdConfig:options:)`.
        ///
        /// - Parameter options: Additional request options that control networking behavior, caching, and other Parse client
        ///   features. Defaults to an empty set.
        /// - Returns: The updated object of type `T` as returned by the server. This instance also replaces the wrapper’s
        ///   internal value, notifying observers of the change.
        /// - Throws: An error if the update operation fails due to networking issues, permissions, validation errors, or
        ///   decoding problems.
        ///
        /// - Important:
        ///   - This performs a partial update. Only changed fields are sent to the server.
        ///   - Successful updates replace the wrapped instance. If your UI or logic depends on identity (e.g., `objectId`,
        ///     equality, or hashing), be aware the instance may change after this call completes.
        ///
        /// - Availability: iOS 17.0+, macOS 14.0+, tvOS 17.0+, watchOS 10.0+.
        /// - Concurrency: Intended for use from async contexts on the main actor in UI code.
    @discardableResult func update(options: API.Options = []) async throws -> T {
        let newValue = try await wrappedValue.update(options: options)
        self.wrappedValue = newValue
        return newValue
    }
    
        /// Deletes the underlying Parse object from the server.
        ///
        /// This method forwards to `T.delete(options:)` on the wrapped `ParseObject`, issuing a network
        /// request to remove the object from your Parse backend. Unlike other mutating operations in this
        /// wrapper, a successful delete does not replace the internal `value`; it simply completes if the
        /// server confirms deletion.
        ///
        /// - Parameter options: Additional request options that control networking behavior, caching, and
        ///   other Parse client features. Defaults to an empty set.
        /// - Throws: An error if the delete operation fails due to networking issues, permissions, or if
        ///   the object cannot be deleted on the server.
        ///
        /// - Important:
        ///   - After a successful delete, the server no longer has a record for this object. Any subsequent
        ///     operations that assume server existence (e.g., `fetch`, `update`, `replace`) may fail unless
        ///     the object is recreated.
        ///   - If your UI or logic depends on the presence of this object, make sure to update state and
        ///     navigation accordingly after deletion.
        ///
        /// - Availability: iOS 17.0+, macOS 14.0+, tvOS 17.0+, watchOS 10.0+.
        /// - Concurrency: Intended for use from async contexts on the main actor in UI code.
    func delete(options: API.Options = []) async throws {
        try await wrappedValue.delete(options: options)
    }
}

    // TODO: - (cspell2k5) Extract Binding.default(to:) to a shared SwiftUI utility module
extension Binding {
        /// Provides a non-optional Binding by supplying a default value when the original Binding is optional and currently nil.
        ///
        /// This helper transforms a `Binding<V?>` into a `Binding<V>` by returning the provided `defaultValue` in the getter
        /// whenever the wrapped optional is `nil`. Assignments to the returned binding write the new value back into the
        /// original optional binding, replacing its `nil` with the assigned value.
        ///
        /// Use this when your UI requires a non-optional `Binding` (e.g., for SwiftUI controls that don’t accept optionals),
        /// but your model stores the value as optional.
        ///
        /// - Parameter defaultValue: The value to use when the underlying optional binding is `nil`.
        /// - Returns: A `Binding<V>` that reads as the underlying value or `defaultValue` if `nil`, and writes directly to the underlying optional.
        /// - Note: The default value is only used for reading. Once a non-nil value is written through the returned binding,
        ///         that value will be read thereafter.
        /// - Example:
        ///   ```swift
        ///   @State private var nickname: String? = nil
        ///
        ///   TextField("Nickname", text: $nickname.parseDefault(to: "Guest"))
        ///   // When nickname is nil, the TextField reads "Guest".
        ///   // Editing the field writes the new value back into `nickname`.
        ///   // If Guest were a variable that variable will not be changed.
        ///   ```
    @available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *)
    public func parseDefault<V>(to defaultValue: V) -> Binding<V> where Value == V? {
        .init(get: { self.wrappedValue ?? defaultValue },
              set: { self.wrappedValue = $0 })
    }
}


