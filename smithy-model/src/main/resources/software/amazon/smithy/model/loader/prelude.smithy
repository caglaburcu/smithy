$version: "2.0"

namespace smithy.api

string String

blob Blob

bigInteger BigInteger

bigDecimal BigDecimal

timestamp Timestamp

document Document

boolean Boolean

byte Byte

short Short

integer Integer

long Long

float Float

double Double

@unitType
structure Unit {}

/// Makes a shape a trait.
@trait(
    selector: ":is(simpleType, list, map, set, structure, union)",
    breakingChanges: [
        {change: "presence"},
        {path: "/structurallyExclusive", change: "any"},
        {path: "/conflicts", change: "update", severity: "NOTE", message:
            "Adding more conflicts to a trait could cause previously written models to fail validation."}
    ]
)
structure trait {
    /// The valid places in a model that the trait can be applied.
    selector: String,

    /// Whether or not only a single member in a structure can have this trait.
    structurallyExclusive: StructurallyExclusive,

    /// The traits that this trait conflicts with.
    conflicts: NonEmptyStringList,

    /// Defines the backward compatibility rules of the trait.
    breakingChanges: TraitDiffRules
}

@private
@length(min: 1)
list TraitDiffRules {
    member: TraitDiffRule
}

@private
structure TraitDiffRule {
    /// Defines a JSON Pointer to the value to evaluate.
    path: String,

    /// Defines the type of change that is not allowed.
    @required
    change: TraitChangeType,

    /// Defines the severity of the change. Defaults to ERROR if not defined.
    severity: TraitChangeSeverity,

    /// Provides a reason why the change is potentially backward incompatible.
    message: String
}

@private
@enum([
    {
        name: "UPDATE",
        value: "update",
        documentation: "Emit when a trait already existed, continues to exist, but it is modified."
    },
    {
        name: "ADD",
        value: "add",
        documentation: "Emit when a trait or value is added that previously did not exist."
    },
    {
        name: "REMOVE",
        value: "remove",
        documentation: "Emit when a trait or value is removed."
    },
    {
        name: "PRESENCE",
        value: "presence",
        documentation: "Emit when a trait is added or removed."
    },
    {
        name: "ANY",
        value: "any",
        documentation: "Emit when any change occurs."
    },
])
string TraitChangeType

@private
@enum([
    {
        name: "NOTE",
        value: "NOTE",
        documentation: "A minor infraction occurred."
    },
    {
        name: "WARNING",
        value: "WARNING",
        documentation: "An infraction occurred that needs attention."
    },
    {
        name: "DANGER",
        value: "DANGER",
        documentation: "An infraction occurred that must be resolved."
    },
    {
        name: "ERROR",
        value: "ERROR",
        documentation: "An unrecoverable infraction occurred."
    },
])
string TraitChangeSeverity

@private
@enum([
    {
        name: "MEMBER",
        value: "member",
        documentation: "Only a single member of a structure can be marked with the trait."
    },
    {
        name: "TARGET",
        value: "target",
        documentation: "Only a single member of a structure can target a shape marked with this trait."
    }
])
string StructurallyExclusive

/// Marks a shape or member as deprecated.
@trait
structure deprecated {
    /// The reason for deprecation.
    message: String,

    /// A description of when the shape was deprecated (e.g., a date or version).
    since: String,
}

/// Adds documentation to a shape or member using CommonMark syntax.
@trait
string documentation

/// Provides a link to additional documentation.
@trait
@length(min: 1)
map externalDocumentation {
    key: NonEmptyString,
    value: NonEmptyString
}

/// Defines the list of authentication schemes supported by a service or operation.
@trait(selector: ":is(service, operation)")
set auth {
    member: AuthTraitReference
}

/// A string that must target an auth trait.
@idRef(selector: "[trait|authDefinition]")
@private
string AuthTraitReference

/// Marks a trait as a protocol defining trait.
///
/// The targeted trait must only be applied to service shapes, must be a
/// structure, and must have the `trait` trait.
@trait(
    selector: "structure[trait|trait]",
    breakingChanges: [{change: "presence"}]
)
structure protocolDefinition {
    /// Defines a list of traits that protocol implementations must
    /// understand in order to successfully use the protocol.
    traits: TraitShapeIdList,

    /// Set to true if inline documents are not supported by this protocol.
    noInlineDocumentSupport: Boolean,
}

@private
list TraitShapeIdList {
    member: TraitShapeId,
}

@private
@idRef(failWhenMissing: true, selector: "[trait|trait]")
string TraitShapeId

/// Marks a trait as an auth scheme defining trait.
///
/// The targeted trait must only be applied to service shapes or operation
/// shapes, must be a structure, and must have the `trait` trait.
@trait(
    selector: "structure[trait|trait]",
    breakingChanges: [{change: "presence"}]
)
structure authDefinition {
    /// Defines a list of traits that auth implementations must
    /// understand in order to successfully use the scheme.
    traits: TraitShapeIdList,
}

/// Enables HTTP Basic Authentication as defined in RFC 2617
/// on a service or operation.
@trait(
    selector: "service",
    breakingChanges: [{change: "remove"}]
)
@authDefinition
@externalDocumentation("RFC 2617": "https://tools.ietf.org/html/rfc2617.html")
structure httpBasicAuth {}

/// Enables HTTP Digest Authentication as defined in RFC 2617
/// on a service or operation.
@trait(
    selector: "service",
    breakingChanges: [{change: "remove"}]
)
@authDefinition
@externalDocumentation("RFC 2617": "https://tools.ietf.org/html/rfc2617.html")
structure httpDigestAuth {}

/// Enables HTTP Bearer Authentication as defined in RFC 6750
/// on a service or operation.
@trait(
    selector: "service",
    breakingChanges: [{change: "remove"}]
)
@authDefinition
@externalDocumentation("RFC 6750": "https://tools.ietf.org/html/rfc6750.html")
structure httpBearerAuth {}

/// An HTTP-specific authentication scheme that sends an arbitrary
/// API key in a header or query string parameter.
@trait(
    selector: "service",
    breakingChanges: [{change: "remove"}]
)
@authDefinition
structure httpApiKeyAuth {
    /// Defines the name of the HTTP header or query string parameter
    /// that contains the API key.
    @required
    name: NonEmptyString,

    /// Defines the location of where the key is serialized. This value
    /// can be set to `"header"` or `"query"`.
    @required
    in: HttpApiKeyLocations,

    /// Defines the security scheme to use on the ``Authorization`` header value
    /// This can only be set if the "in" property is set to ``header``.
    scheme: NonEmptyString,
}

@trait(selector: "structure > member :not(> :test(union, structure > :test([trait|required])))",
       conflicts: [required])
@tags(["diff.error.remove"])
structure default {}

@private
@enum([
    {
        name: "HEADER",
        value: "header",
    },
    {
        name: "QUERY",
        value: "query",
    },
])
string HttpApiKeyLocations

/// Indicates that an operation can be called without authentication.
@trait(
    selector: "operation",
    breakingChanges: [{change: "remove"}]
)
structure optionalAuth {}

/// Provides example inputs and outputs for operations.
@trait(selector: "operation")
list examples {
    member: Example,
}

@private
structure Example {
    @required
    title: String,

    documentation: String,

    input: Document,

    output: Document,

    error: ExampleError,
}

@private
structure ExampleError {
    @idRef(selector: "structure[trait|error]")
    shapeId: String,

    content: Document,
}

/// Indicates that a structure shape represents an error.
///
/// All shapes referenced by the errors list of an operation MUST be
/// targeted with this trait.
@trait(
    selector: "structure",
    conflicts: [trait],
    breakingChanges: [{change: "any"}]
)
@enum([
    {value: "client", name: "CLIENT"},
    {value: "server", name: "SERVER"}])
string error

/// Indicates that an error MAY be retried by the client.
@trait(
    selector: "structure[trait|error]",
    breakingChanges: [{change: "remove"}]
)
structure retryable {
    /// Classifies the retry as throttling.
    throttling: Boolean,
}

/// Indicates that an operation is effectively read-only.
@trait(
    selector: "operation",
    conflicts: [idempotent],
    breakingChanges: [{change: "remove"}]
)
structure readonly {}

/// Indicates that the intended effect on the server of multiple identical
/// requests with an operation is the same as the effect for a single
/// such request.
@trait(
    selector: "operation",
    conflicts: [readonly],
    breakingChanges: [{change: "remove"}]
)
structure idempotent {}

/// Defines the input member of an operation that is used by the server to
/// identify and discard replayed requests.
@trait(
    selector: "structure > :test(member > string)",
    structurallyExclusive: "member",
    breakingChanges: [{change: "remove"}]
)
structure idempotencyToken {}

/// Shapes marked with the internal trait are meant only for internal use and
/// must not be exposed to customers.
@trait(breakingChanges: [{
    change: "remove",
    severity: "WARNING",
    message: "Removing the @internal trait makes a shape externally visible."}
])
structure internal {}

/// The jsonName trait allows a serialized object property name to differ
/// from a structure member name used in the model.
@trait(
    selector: ":is(structure, union) > member",
    breakingChanges: [{change: "any"}]
)
string jsonName

/// Serializes an object property as an XML attribute rather than a nested XML element.
@trait(
    selector: "structure > :test(member > :test(boolean, number, string, timestamp))",
    conflicts: [xmlNamespace],
    breakingChanges: [{change: "any"}]
)
structure xmlAttribute {}

/// Unwraps the values of a list, set, or map into the containing structure/union.
@trait(
    selector: ":is(structure, union) > :test(member > :test(collection, map))",
    breakingChanges: [{change: "any"}]
)
structure xmlFlattened {}

/// Changes the serialized element or attribute name of a structure, union, or member.
@trait(
    selector: ":is(structure, union, member)",
    breakingChanges: [{change: "any"}]
)
@pattern("^[a-zA-Z_][a-zA-Z_0-9-]*(:[a-zA-Z_][a-zA-Z_0-9-]*)?$")
string xmlName

/// Adds an xmlns namespace definition URI to an XML element.
@trait(
    selector: ":is(service, member, simpleType, collection, map, structure, union)",
    conflicts: [xmlAttribute],
    breakingChanges: [{change: "any"}]
)
structure xmlNamespace {
    /// The namespace URI for scoping this XML element.
    @required
    uri: NonEmptyString,
    /// The prefix for the given namespace.
    @pattern("^[a-zA-Z_][a-zA-Z_0-9-]*$")
    prefix: NonEmptyString,
}

@private
@length(min: 1)
string NonEmptyString

/// Indicates that the put lifecycle operation of a resource
/// can only be used to create a resource and cannot replace
/// an existing resource.
@trait(selector: "resource:test(-[put]->)")
structure noReplace {}

/// Describes the contents of a blob shape using a media type as defined by
/// RFC 6838 (e.g., "video/quicktime").
@trait(
    selector: ":is(blob, string)",
    breakingChanges: [{change: "remove"}]
)
string mediaType

/// Defines the resource shapes that are referenced by a string shape or a
/// structure shape and the members of the structure that provide values for
/// the identifiers of the resource.
@trait(selector: ":is(structure, string)")
list references {
    member: Reference
}

@private
structure Reference {
    /// The shape ID of the referenced resource.
    @required
    resource: NonEmptyString,

    /// Defines a mapping of each resource identifier name to a structure member
    /// name that provides its value. Each key in the map MUST refer to one of the
    /// identifier names in the identifiers property of the resource, and each
    /// value in the map MUST refer to a valid structure member name that targets
    /// a string shape.
    ids: NonEmptyStringMap,

    /// Providing a service makes the reference specific to a particular binding
    /// of the resource to a service. When omitted, the reference is late-bound to
    /// a service, meaning the reference is assumed to be a reference to the
    /// resource bound to the service currently in use by the client or server.
    service: NonEmptyString,

    /// Defines the semantics of the relationship. The rel property SHOULD
    /// contain a link relation as defined in RFC 5988#section-4.
    rel: NonEmptyString,
}

@private
map NonEmptyStringMap {
    key: NonEmptyString,
    value: NonEmptyString
}

/// Indicates that the targeted structure member provides an identifier for a resource.
@trait(
    selector: "structure > :test(member[trait|required] > string)",
    breakingChanges: [{change: "remove"}]
)
@length(min: 1)
string resourceIdentifier

/// Prevents models defined in a different namespace from referencing the targeted shape.
@trait
structure private {}

/// Indicates that the data stored in the shape or member is sensitive and MUST be handled with care.
@trait(selector: ":not(:test(service, operation, resource))")
structure sensitive {}

/// Defines the version or date in which a shape or member was added to the model.
@trait
string since

/// Indicates that the data stored in the shape is very large and should not
/// be stored in memory, or that the size of the data stored in the shape is
/// unknown at the start of a request. If the target is a union then the shape
/// represents a stream of events.
@trait(
    selector: ":is(blob, union)",
    structurallyExclusive: "target",
    breakingChanges: [{change: "any"}]
)
structure streaming {}

/// Indicates that the streaming blob must be finite and has a known size.
@trait(
    selector: "blob[trait|streaming]",
    breakingChanges: [{change: "presence"}]
)
structure requiresLength {}

/// Tags a shape with arbitrary tag names that can be used to filter and
/// group shapes in the model.
@trait
list tags {
    member: String
}

/// Defines a proper name for a service or resource shape.
///
/// This title can be used in automatically generated documentation
/// and other contexts to provide a user friendly name for services
/// and resources.
@trait(selector: ":is(service, resource)")
string title

/// Constrains the acceptable values of a string to a fixed set
/// of constant values.
@trait(
    selector: "string",
    // It's a breaking change to change values or enums or the ordering of enums,
    // but that validation happens in code to provide better error messages.
    breakingChanges: [
        {change: "presence"}
    ]
)
@length(min: 1)
list enum {
    member: EnumDefinition
}

/// An enum definition for the enum trait.
@private
structure EnumDefinition {
    /// Defines the enum value that is sent over the wire.
    @required
    value: NonEmptyString,

    /// Defines the name, or label, that is used in code to represent this variant.
    name: EnumConstantBodyName,

    /// Provides optional documentation about the enum constant value.
    documentation: String,

    /// Applies a list of tags to the enum constant.
    tags: NonEmptyStringList,

    /// Whether the enum value should be considered deprecated.
    deprecated: Boolean,
}

/// The optional name or label of the enum constant value.
///
/// This property is used in code generation to provide a label for
/// each enum value. No two enums can have the same 'name' value.
@private
@pattern("^[a-zA-Z_]+[a-zA-Z_0-9]*$")
string EnumConstantBodyName

/// Defines the value of an enum entry.
@trait(selector: "enum > member")
union enumValue {
    /// The value for the enum entry if it is a string.
    string: String

    /// The value for the enum entry if it is an integer.
    int: Integer
}

/// Constrains a shape to minimum and maximum number of elements or size.
@trait(selector: ":test(collection, map, string, blob, member > :is(collection, map, string, blob))")
structure length {
    /// Integer value that represents the minimum inclusive length of a shape.
    min: Long,

    /// Integer value that represents the maximum inclusive length of a shape.
    max: Long,
}

/// Restricts allowed values of byte, short, integer, long, float, double,
/// bigDecimal, and bigInteger shapes within an acceptable lower and upper bound.
@trait(selector: ":test(number, member > number)")
structure range {
    /// Specifies the allowed inclusive minimum value.
    min: BigDecimal,

    /// Specifies the allowed inclusive maximum value.
    max: BigDecimal,
}

/// Restricts string shape values to a specified regular expression.
@trait(
    selector: ":test(string, member > string)",
    breakingChanges: [
        {
            change: "add",
            severity: "WARNING",
            message: "The @pattern trait should only be added if the string already had adhered to the pattern."
        },
        {
            change: "update",
            severity: "NOTE",
            message: "Changes to the @pattern trait should generally make the string more permissive, not less."
        }
    ]
)
string pattern

/// Marks a structure member as required, meaning a value for the member MUST be present.
@trait(
    selector: "structure > member",
    breakingChanges: [{change: "add"}]
)
structure required {}

/// Indicates that a structure member SHOULD be set.
@trait(selector: "structure > member", conflicts: [required])
structure recommended {
    /// Provides a reason why the member is recommended.
    reason: String,
}

/// Marks a list or map as sparse.
@trait(
    selector: ":is(list, map)",
    breakingChanges: [{change: "presence"}]
)
structure sparse {}

/// Indicates that the items in a list MUST be unique.
@trait(selector: "list")
@deprecated(message: "The uniqueItems trait has been deprecated in favor of using sets.", since: "2.0")
structure uniqueItems {}

/// Indicates that the shape is unstable and could change in the future.
@trait
structure unstable {}

/// The paginated trait indicates that an operation intentionally limits the number
/// of results returned in a single response and that multiple invocations might be
/// necessary to retrieve all results.
@trait(
    selector: ":is(service, operation)",
    breakingChanges: [
        {change: "remove"},
        {path: "/inputToken",  change: "update"},
        {path: "/outputToken", change: "update"},
        {path: "/items",       change: "any"},
        {path: "/pageSize",    change: "update"},
        {path: "/pageSize",    change: "remove"},
    ]
)
structure paginated {
    /// The name of the operation input member that represents the continuation token.
    ///
    /// When this value is provided as operation input, the service returns results
    /// from where the previous response left off. This input member MUST NOT be
    /// required and MUST target a string shape.
    inputToken: NonEmptyString,

    /// The name of the operation output member that represents the continuation token.
    ///
    /// When this value is present in operation output, it indicates that there are more
    /// results to retrieve. To get the next page of results, the client uses the output
    /// token as the input token of the next request. This output member MUST NOT be
    /// required and MUST target a string shape.
    outputToken: NonEmptyString,

    /// The name of a top-level output member of the operation that is the data
    /// that is being paginated across many responses.
    ///
    /// The named output member, if specified, MUST target a list or map.
    items: NonEmptyString,

    /// The name of an operation input member that limits the maximum number of
    /// results to include in the operation output. This input member MUST NOT be
    /// required and MUST target an integer shape.
    pageSize: NonEmptyString,
}

/// Configures the HTTP bindings of an operation.
@trait(
    selector: "operation",
    breakingChanges: [
        {change: "remove"},
        {path: "/method", change: "update"},
        {path: "/uri", change: "update"},
        {path: "/code", change: "update"},
        {path: "/code", change: "presence", severity: "DANGER", message: "Adding or removing is backward compatible only if the value is the default value of 200"}
    ]
)
structure http {
    /// The HTTP method of the operation.
    @required
    method: NonEmptyString,

    /// The URI pattern of the operation.
    ///
    /// Labels defined in the URI pattern are used to bind operation input
    /// members to the URI.
    @required
    uri: NonEmptyString,

    /// The HTTP status code of a successful response.
    ///
    /// Defaults to 200 if not provided.
    @range(min: 100, max: 999)
    code: Integer,
}

/// Binds an operation input structure member to an HTTP label.
@trait(
    selector: "structure > member[trait|required] :test(> :test(string, number, boolean, timestamp))",
    conflicts: [httpHeader, httpQuery, httpPrefixHeaders, httpPayload, httpResponseCode, httpQueryParams],
    breakingChanges: [{change: "presence"}]
)
structure httpLabel {}

/// Binds an operation input structure member to a query string parameter.
@trait(
    selector: """
        structure > member
        :test(> :test(string, number, boolean, timestamp),
              > collection > member > :test(string, number, boolean, timestamp))""",
    conflicts: [httpLabel, httpHeader, httpPrefixHeaders, httpPayload, httpResponseCode, httpQueryParams],
    breakingChanges: [{change: "any"}]
)
@length(min: 1)
string httpQuery

/// Binds an operation input structure member to the HTTP query string.
@trait(
    selector: """
        structure > member
        :test(> map > member[id|member=value] > :test(string, collection > member > string))""",
        structurallyExclusive: "member",
    conflicts: [httpLabel, httpQuery, httpHeader, httpPayload, httpResponseCode, httpPrefixHeaders],
    breakingChanges: [{change: "any"}]
)
structure httpQueryParams {}

/// Binds a structure member to an HTTP header.
@trait(
    selector: """
        structure > :test(member > :test(boolean, number, string, timestamp,
                collection > member > :test(boolean, number, string, timestamp)))""",
    conflicts: [httpLabel, httpQuery, httpPrefixHeaders, httpPayload, httpResponseCode, httpQueryParams],
    breakingChanges: [{change: "any"}]
)
@length(min: 1)
string httpHeader

/// Binds a map of key-value pairs to prefixed HTTP headers.
@trait(
    selector: """
        structure > member
        :test(> map > member[id|member=value] > string)""",
    structurallyExclusive: "member",
    conflicts: [httpLabel, httpQuery, httpHeader, httpPayload, httpResponseCode, httpQueryParams],
    breakingChanges: [{change: "any"}]
)
string httpPrefixHeaders

/// Binds a single structure member to the body of an HTTP request.
@trait(
    selector: "structure > :test(member > :test(string, blob, structure, union, document, list, set, map))",
    conflicts: [httpLabel, httpQuery, httpHeader, httpPrefixHeaders, httpResponseCode, httpQueryParams],
    structurallyExclusive: "member",
    breakingChanges: [{change: "presence"}]
)
structure httpPayload {}

/// Defines an HTTP response code for an operation error.
@trait(
    selector: "structure[trait|error]",
    breakingChanges: [{change: "any"}]
)
integer httpError

/// Indicates that the structure member represents the HTTP response
/// status code. The value MAY differ from the HTTP status code provided
/// on the response.
@trait(
    selector: "structure > member :test(> integer)",
    structurallyExclusive: "member",
    conflicts: [httpLabel, httpQuery, httpHeader, httpPrefixHeaders, httpPayload, httpQueryParams],
    breakingChanges: [{change: "any"}]
)
structure httpResponseCode {}

/// Defines how a service supports cross-origin resource sharing.
@trait(
    selector: "service",
    breakingChanges: [{change: "remove"}]
)
structure cors {
    /// The origin from which browser script-originating requests will be allowed.
    ///
    /// Defaults to *.
    origin: NonEmptyString,

    /// The maximum number of seconds for which browsers are allowed to cache
    /// the results of a preflight OPTIONS request.
    ///
    /// Defaults to 600, the maximum age permitted by several browsers.
    /// Set to -1 to disable caching entirely.
    maxAge: Integer,

    /// The names of headers that should be included in the
    /// Access-Control-Allow-Headers header in responses to preflight OPTIONS
    /// requests. This list will be used in addition to the names of all
    /// request headers bound to an input data member via the httpHeader, as
    /// well as any headers required by the protocol or authentication scheme.
    additionalAllowedHeaders: NonEmptyStringList,

    /// The names of headers that should be included in the
    /// Access-Control-Expose-Headers header in all responses sent by the
    /// service. This list will be used in addition to the names of all
    /// request headers bound to an output data member via the httpHeader,
    /// as well as any headers required by the protocol or authentication
    /// scheme.
    additionalExposedHeaders: NonEmptyStringList,
}

@private
list NonEmptyStringList {
    member: NonEmptyString,
}

/// Marks a member as the payload of an event.
@trait(
    selector: "structure > :test(member > :test(blob, string, structure, union))",
    conflicts: [eventHeader],
    structurallyExclusive: "member",
    breakingChanges: [{change: "any"}]
)
structure eventPayload {}

/// Marks a member as a header of an event.
@trait(
    selector: """
        structure >
        :test(member > :test(boolean, byte, short, integer, long, blob, string, timestamp))""",
    conflicts: [eventPayload],
    breakingChanges: [{change: "any"}]
)
structure eventHeader {}

/// Indicates that a string value MUST contain a valid shape ID.
///
/// The provided shape ID MAY be absolute or relative to the shape to which
/// the trait is applied. A relative shape ID that does not resolve to a
/// shape defined in the same namespace resolves to a shape defined in the
/// prelude if the prelude shape is not marked with the private trait.
@trait(selector: ":test(string, member > string)")
structure idRef {
    /// Defines the selector that the resolved shape, if found, MUST match.
    ///
    /// selector defaults to * when not defined.
    selector: String,

    /// When set to `true`, the shape ID MUST target a shape that can be
    /// found in the model.
    failWhenMissing: Boolean,

    /// Defines a custom error message to use when the shape ID cannot be
    /// found or does not match the selector.
    ///
    /// A default message is generated when errorMessage is not defined.
    errorMessage: String,
}

@trait(
    selector: ":test(timestamp, member > timestamp)",
    breakingChanges: [{change: "any"}]
)
@enum([
    {
        value: "date-time",
        name: "DATE_TIME",
        documentation: """
            Date time as defined by the date-time production in RFC3339 section 5.6
            with no UTC offset (for example, 1985-04-12T23:20:50.52Z)."""
    },
    {
        value: "epoch-seconds",
        name: "EPOCH_SECONDS",
        documentation: """
            Also known as Unix time, the number of seconds that have elapsed since
            00:00:00 Coordinated Universal Time (UTC), Thursday, 1 January 1970,
            with decimal precision (for example, 1515531081.1234)."""
    },
    {
        value: "http-date",
        name: "HTTP_DATE",
        documentation: """
            An HTTP date as defined by the IMF-fixdate production in
            RFC 7231#section-7.1.1.1 (for example, Tue, 29 Apr 2014 18:30:38 GMT)."""
    }
])
string timestampFormat

/// Configures a custom operation endpoint.
@trait(
    selector: "operation",
    breakingChanges: [{change: "any"}]
)
structure endpoint {
    /// A host prefix pattern for the operation.
    ///
    /// Labels defined in the host pattern are used to bind top-level
    /// operation input members to the host.
    @required
    hostPrefix: NonEmptyString,
}

/// Binds a top-level operation input structure member to a label
/// in the hostPrefix of an endpoint trait.
@trait(
    selector: "structure > :test(member[trait|required] > string)",
    breakingChanges: [{change: "any"}]
)
structure hostLabel {}

/// Suppresses validation events by ID for a given shape.
@trait
list suppress {
    @pattern("^[_a-zA-Z][A-Za-z0-9]*$")
    @length(min: 1)
    member: String
}

/// Marks an operation as requiring checksum in its HTTP request.
/// By default, the checksum used for a service is a MD5 checksum
/// passed in the Content-MD5 header.
@unstable
@trait(selector: "operation")
structure httpChecksumRequired {}

/// Specializes a structure for use only as the input of a single operation.
@trait(
    selector: "structure",
    conflicts: [output, error],
    breakingChanges: [{change: "presence"}]
)
structure input {}

/// Specializes a structure for use only as the output of a single operation.
@trait(
    selector: "structure",
    conflicts: [input, error],
    breakingChanges: [{change: "presence"}]
)
structure output {}

/// Specializes a structure as a unit type that has no meaningful value.
/// This trait can only be applied to smithy.api#Unit, which ensures that
/// only a single Unit shape can be created.
@trait(selector: "[id=smithy.api#Unit]")
structure unitType {}

/// Makes a structure or union a mixin.
@trait(selector: ":not(member)")
structure mixin {
    localTraits: LocalMixinTraitList
}

@private
list LocalMixinTraitList {
    member: LocalMixinTrait
}

@idRef(
    selector: "[trait|trait]",
    failWhenMissing: true,
    errorMessage: """
            Strings provided to the localTraits property of a mixin trait
            must target a valid trait.""")
@private
string LocalMixinTrait
