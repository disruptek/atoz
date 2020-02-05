
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS CodeStar connections
## version: 2019-12-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>This AWS CodeStar Connections API Reference provides descriptions and usage examples of the operations and data types for the AWS CodeStar Connections API. You can use the Connections API to work with connections and installations.</p> <p> <i>Connections</i> are configurations that you use to connect AWS resources to external code repositories. Each connection is a resource that can be given to services such as CodePipeline to connect to a third-party repository such as Bitbucket. For example, you can add the connection in CodePipeline so that it triggers your pipeline when a code change is made to your third-party code repository. Each connection is named and associated with a unique ARN that is used to reference the connection.</p> <p>When you create a connection, the console initiates a third-party connection handshake. <i>Installations</i> are the apps that are used to conduct this handshake. For example, the installation for the Bitbucket provider type is the Bitbucket Cloud app. When you create a connection, you can choose an existing installation or create one.</p> <p>You can work with connections by calling:</p> <ul> <li> <p> <a>CreateConnection</a>, which creates a uniquely named connection that can be referenced by services such as CodePipeline.</p> </li> <li> <p> <a>DeleteConnection</a>, which deletes the specified connection.</p> </li> <li> <p> <a>GetConnection</a>, which returns information about the connection, including the connection status.</p> </li> <li> <p> <a>ListConnections</a>, which lists the connections associated with your account.</p> </li> </ul> <p>For information about how to use AWS CodeStar Connections, see the <a href="https://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html">AWS CodePipeline User Guide</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/codestar-connections/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_612649 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612649](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612649): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "codestar-connections.ap-northeast-1.amazonaws.com", "ap-southeast-1": "codestar-connections.ap-southeast-1.amazonaws.com", "us-west-2": "codestar-connections.us-west-2.amazonaws.com", "eu-west-2": "codestar-connections.eu-west-2.amazonaws.com", "ap-northeast-3": "codestar-connections.ap-northeast-3.amazonaws.com", "eu-central-1": "codestar-connections.eu-central-1.amazonaws.com", "us-east-2": "codestar-connections.us-east-2.amazonaws.com", "us-east-1": "codestar-connections.us-east-1.amazonaws.com", "cn-northwest-1": "codestar-connections.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "codestar-connections.ap-south-1.amazonaws.com", "eu-north-1": "codestar-connections.eu-north-1.amazonaws.com", "ap-northeast-2": "codestar-connections.ap-northeast-2.amazonaws.com", "us-west-1": "codestar-connections.us-west-1.amazonaws.com", "us-gov-east-1": "codestar-connections.us-gov-east-1.amazonaws.com", "eu-west-3": "codestar-connections.eu-west-3.amazonaws.com", "cn-north-1": "codestar-connections.cn-north-1.amazonaws.com.cn", "sa-east-1": "codestar-connections.sa-east-1.amazonaws.com", "eu-west-1": "codestar-connections.eu-west-1.amazonaws.com", "us-gov-west-1": "codestar-connections.us-gov-west-1.amazonaws.com", "ap-southeast-2": "codestar-connections.ap-southeast-2.amazonaws.com", "ca-central-1": "codestar-connections.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "codestar-connections.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "codestar-connections.ap-southeast-1.amazonaws.com",
      "us-west-2": "codestar-connections.us-west-2.amazonaws.com",
      "eu-west-2": "codestar-connections.eu-west-2.amazonaws.com",
      "ap-northeast-3": "codestar-connections.ap-northeast-3.amazonaws.com",
      "eu-central-1": "codestar-connections.eu-central-1.amazonaws.com",
      "us-east-2": "codestar-connections.us-east-2.amazonaws.com",
      "us-east-1": "codestar-connections.us-east-1.amazonaws.com",
      "cn-northwest-1": "codestar-connections.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "codestar-connections.ap-south-1.amazonaws.com",
      "eu-north-1": "codestar-connections.eu-north-1.amazonaws.com",
      "ap-northeast-2": "codestar-connections.ap-northeast-2.amazonaws.com",
      "us-west-1": "codestar-connections.us-west-1.amazonaws.com",
      "us-gov-east-1": "codestar-connections.us-gov-east-1.amazonaws.com",
      "eu-west-3": "codestar-connections.eu-west-3.amazonaws.com",
      "cn-north-1": "codestar-connections.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "codestar-connections.sa-east-1.amazonaws.com",
      "eu-west-1": "codestar-connections.eu-west-1.amazonaws.com",
      "us-gov-west-1": "codestar-connections.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "codestar-connections.ap-southeast-2.amazonaws.com",
      "ca-central-1": "codestar-connections.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "codestar-connections"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateConnection_612987 = ref object of OpenApiRestCall_612649
proc url_CreateConnection_612989(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConnection_612988(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a connection that can then be given to other AWS services like CodePipeline so that it can access third-party code repositories. The connection is in pending status until the third-party connection handshake is completed from the console.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613114 = header.getOrDefault("X-Amz-Target")
  valid_613114 = validateParameter(valid_613114, JString, required = true, default = newJString("com.amazonaws.codestar.connections.CodeStar_connections_20191201.CreateConnection"))
  if valid_613114 != nil:
    section.add "X-Amz-Target", valid_613114
  var valid_613115 = header.getOrDefault("X-Amz-Signature")
  valid_613115 = validateParameter(valid_613115, JString, required = false,
                                 default = nil)
  if valid_613115 != nil:
    section.add "X-Amz-Signature", valid_613115
  var valid_613116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613116 = validateParameter(valid_613116, JString, required = false,
                                 default = nil)
  if valid_613116 != nil:
    section.add "X-Amz-Content-Sha256", valid_613116
  var valid_613117 = header.getOrDefault("X-Amz-Date")
  valid_613117 = validateParameter(valid_613117, JString, required = false,
                                 default = nil)
  if valid_613117 != nil:
    section.add "X-Amz-Date", valid_613117
  var valid_613118 = header.getOrDefault("X-Amz-Credential")
  valid_613118 = validateParameter(valid_613118, JString, required = false,
                                 default = nil)
  if valid_613118 != nil:
    section.add "X-Amz-Credential", valid_613118
  var valid_613119 = header.getOrDefault("X-Amz-Security-Token")
  valid_613119 = validateParameter(valid_613119, JString, required = false,
                                 default = nil)
  if valid_613119 != nil:
    section.add "X-Amz-Security-Token", valid_613119
  var valid_613120 = header.getOrDefault("X-Amz-Algorithm")
  valid_613120 = validateParameter(valid_613120, JString, required = false,
                                 default = nil)
  if valid_613120 != nil:
    section.add "X-Amz-Algorithm", valid_613120
  var valid_613121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613121 = validateParameter(valid_613121, JString, required = false,
                                 default = nil)
  if valid_613121 != nil:
    section.add "X-Amz-SignedHeaders", valid_613121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613145: Call_CreateConnection_612987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a connection that can then be given to other AWS services like CodePipeline so that it can access third-party code repositories. The connection is in pending status until the third-party connection handshake is completed from the console.
  ## 
  let valid = call_613145.validator(path, query, header, formData, body)
  let scheme = call_613145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613145.url(scheme.get, call_613145.host, call_613145.base,
                         call_613145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613145, url, valid)

proc call*(call_613216: Call_CreateConnection_612987; body: JsonNode): Recallable =
  ## createConnection
  ## Creates a connection that can then be given to other AWS services like CodePipeline so that it can access third-party code repositories. The connection is in pending status until the third-party connection handshake is completed from the console.
  ##   body: JObject (required)
  var body_613217 = newJObject()
  if body != nil:
    body_613217 = body
  result = call_613216.call(nil, nil, nil, nil, body_613217)

var createConnection* = Call_CreateConnection_612987(name: "createConnection",
    meth: HttpMethod.HttpPost, host: "codestar-connections.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.codestar.connections.CodeStar_connections_20191201.CreateConnection",
    validator: validate_CreateConnection_612988, base: "/",
    url: url_CreateConnection_612989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnection_613256 = ref object of OpenApiRestCall_612649
proc url_DeleteConnection_613258(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteConnection_613257(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## The connection to be deleted.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613259 = header.getOrDefault("X-Amz-Target")
  valid_613259 = validateParameter(valid_613259, JString, required = true, default = newJString("com.amazonaws.codestar.connections.CodeStar_connections_20191201.DeleteConnection"))
  if valid_613259 != nil:
    section.add "X-Amz-Target", valid_613259
  var valid_613260 = header.getOrDefault("X-Amz-Signature")
  valid_613260 = validateParameter(valid_613260, JString, required = false,
                                 default = nil)
  if valid_613260 != nil:
    section.add "X-Amz-Signature", valid_613260
  var valid_613261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613261 = validateParameter(valid_613261, JString, required = false,
                                 default = nil)
  if valid_613261 != nil:
    section.add "X-Amz-Content-Sha256", valid_613261
  var valid_613262 = header.getOrDefault("X-Amz-Date")
  valid_613262 = validateParameter(valid_613262, JString, required = false,
                                 default = nil)
  if valid_613262 != nil:
    section.add "X-Amz-Date", valid_613262
  var valid_613263 = header.getOrDefault("X-Amz-Credential")
  valid_613263 = validateParameter(valid_613263, JString, required = false,
                                 default = nil)
  if valid_613263 != nil:
    section.add "X-Amz-Credential", valid_613263
  var valid_613264 = header.getOrDefault("X-Amz-Security-Token")
  valid_613264 = validateParameter(valid_613264, JString, required = false,
                                 default = nil)
  if valid_613264 != nil:
    section.add "X-Amz-Security-Token", valid_613264
  var valid_613265 = header.getOrDefault("X-Amz-Algorithm")
  valid_613265 = validateParameter(valid_613265, JString, required = false,
                                 default = nil)
  if valid_613265 != nil:
    section.add "X-Amz-Algorithm", valid_613265
  var valid_613266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613266 = validateParameter(valid_613266, JString, required = false,
                                 default = nil)
  if valid_613266 != nil:
    section.add "X-Amz-SignedHeaders", valid_613266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613268: Call_DeleteConnection_613256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The connection to be deleted.
  ## 
  let valid = call_613268.validator(path, query, header, formData, body)
  let scheme = call_613268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613268.url(scheme.get, call_613268.host, call_613268.base,
                         call_613268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613268, url, valid)

proc call*(call_613269: Call_DeleteConnection_613256; body: JsonNode): Recallable =
  ## deleteConnection
  ## The connection to be deleted.
  ##   body: JObject (required)
  var body_613270 = newJObject()
  if body != nil:
    body_613270 = body
  result = call_613269.call(nil, nil, nil, nil, body_613270)

var deleteConnection* = Call_DeleteConnection_613256(name: "deleteConnection",
    meth: HttpMethod.HttpPost, host: "codestar-connections.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.codestar.connections.CodeStar_connections_20191201.DeleteConnection",
    validator: validate_DeleteConnection_613257, base: "/",
    url: url_DeleteConnection_613258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnection_613271 = ref object of OpenApiRestCall_612649
proc url_GetConnection_613273(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetConnection_613272(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the connection ARN and details such as status, owner, and provider type.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613274 = header.getOrDefault("X-Amz-Target")
  valid_613274 = validateParameter(valid_613274, JString, required = true, default = newJString("com.amazonaws.codestar.connections.CodeStar_connections_20191201.GetConnection"))
  if valid_613274 != nil:
    section.add "X-Amz-Target", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Signature")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Signature", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Content-Sha256", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-Date")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Date", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-Credential")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-Credential", valid_613278
  var valid_613279 = header.getOrDefault("X-Amz-Security-Token")
  valid_613279 = validateParameter(valid_613279, JString, required = false,
                                 default = nil)
  if valid_613279 != nil:
    section.add "X-Amz-Security-Token", valid_613279
  var valid_613280 = header.getOrDefault("X-Amz-Algorithm")
  valid_613280 = validateParameter(valid_613280, JString, required = false,
                                 default = nil)
  if valid_613280 != nil:
    section.add "X-Amz-Algorithm", valid_613280
  var valid_613281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613281 = validateParameter(valid_613281, JString, required = false,
                                 default = nil)
  if valid_613281 != nil:
    section.add "X-Amz-SignedHeaders", valid_613281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613283: Call_GetConnection_613271; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the connection ARN and details such as status, owner, and provider type.
  ## 
  let valid = call_613283.validator(path, query, header, formData, body)
  let scheme = call_613283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613283.url(scheme.get, call_613283.host, call_613283.base,
                         call_613283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613283, url, valid)

proc call*(call_613284: Call_GetConnection_613271; body: JsonNode): Recallable =
  ## getConnection
  ## Returns the connection ARN and details such as status, owner, and provider type.
  ##   body: JObject (required)
  var body_613285 = newJObject()
  if body != nil:
    body_613285 = body
  result = call_613284.call(nil, nil, nil, nil, body_613285)

var getConnection* = Call_GetConnection_613271(name: "getConnection",
    meth: HttpMethod.HttpPost, host: "codestar-connections.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.codestar.connections.CodeStar_connections_20191201.GetConnection",
    validator: validate_GetConnection_613272, base: "/", url: url_GetConnection_613273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConnections_613286 = ref object of OpenApiRestCall_612649
proc url_ListConnections_613288(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConnections_613287(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Lists the connections associated with your account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_613289 = query.getOrDefault("MaxResults")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "MaxResults", valid_613289
  var valid_613290 = query.getOrDefault("NextToken")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "NextToken", valid_613290
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613291 = header.getOrDefault("X-Amz-Target")
  valid_613291 = validateParameter(valid_613291, JString, required = true, default = newJString("com.amazonaws.codestar.connections.CodeStar_connections_20191201.ListConnections"))
  if valid_613291 != nil:
    section.add "X-Amz-Target", valid_613291
  var valid_613292 = header.getOrDefault("X-Amz-Signature")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-Signature", valid_613292
  var valid_613293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-Content-Sha256", valid_613293
  var valid_613294 = header.getOrDefault("X-Amz-Date")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "X-Amz-Date", valid_613294
  var valid_613295 = header.getOrDefault("X-Amz-Credential")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-Credential", valid_613295
  var valid_613296 = header.getOrDefault("X-Amz-Security-Token")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "X-Amz-Security-Token", valid_613296
  var valid_613297 = header.getOrDefault("X-Amz-Algorithm")
  valid_613297 = validateParameter(valid_613297, JString, required = false,
                                 default = nil)
  if valid_613297 != nil:
    section.add "X-Amz-Algorithm", valid_613297
  var valid_613298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613298 = validateParameter(valid_613298, JString, required = false,
                                 default = nil)
  if valid_613298 != nil:
    section.add "X-Amz-SignedHeaders", valid_613298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613300: Call_ListConnections_613286; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the connections associated with your account.
  ## 
  let valid = call_613300.validator(path, query, header, formData, body)
  let scheme = call_613300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613300.url(scheme.get, call_613300.host, call_613300.base,
                         call_613300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613300, url, valid)

proc call*(call_613301: Call_ListConnections_613286; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listConnections
  ## Lists the connections associated with your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613302 = newJObject()
  var body_613303 = newJObject()
  add(query_613302, "MaxResults", newJString(MaxResults))
  add(query_613302, "NextToken", newJString(NextToken))
  if body != nil:
    body_613303 = body
  result = call_613301.call(nil, query_613302, nil, nil, body_613303)

var listConnections* = Call_ListConnections_613286(name: "listConnections",
    meth: HttpMethod.HttpPost, host: "codestar-connections.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.codestar.connections.CodeStar_connections_20191201.ListConnections",
    validator: validate_ListConnections_613287, base: "/", url: url_ListConnections_613288,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
