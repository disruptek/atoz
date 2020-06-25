
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625426): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateConnection_21625770 = ref object of OpenApiRestCall_21625426
proc url_CreateConnection_21625772(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConnection_21625771(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a connection that can then be given to other AWS services like CodePipeline so that it can access third-party code repositories. The connection is in pending status until the third-party connection handshake is completed from the console.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625873 = header.getOrDefault("X-Amz-Date")
  valid_21625873 = validateParameter(valid_21625873, JString, required = false,
                                   default = nil)
  if valid_21625873 != nil:
    section.add "X-Amz-Date", valid_21625873
  var valid_21625874 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625874 = validateParameter(valid_21625874, JString, required = false,
                                   default = nil)
  if valid_21625874 != nil:
    section.add "X-Amz-Security-Token", valid_21625874
  var valid_21625889 = header.getOrDefault("X-Amz-Target")
  valid_21625889 = validateParameter(valid_21625889, JString, required = true, default = newJString("com.amazonaws.codestar.connections.CodeStar_connections_20191201.CreateConnection"))
  if valid_21625889 != nil:
    section.add "X-Amz-Target", valid_21625889
  var valid_21625890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625890 = validateParameter(valid_21625890, JString, required = false,
                                   default = nil)
  if valid_21625890 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625890
  var valid_21625891 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625891 = validateParameter(valid_21625891, JString, required = false,
                                   default = nil)
  if valid_21625891 != nil:
    section.add "X-Amz-Algorithm", valid_21625891
  var valid_21625892 = header.getOrDefault("X-Amz-Signature")
  valid_21625892 = validateParameter(valid_21625892, JString, required = false,
                                   default = nil)
  if valid_21625892 != nil:
    section.add "X-Amz-Signature", valid_21625892
  var valid_21625893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625893 = validateParameter(valid_21625893, JString, required = false,
                                   default = nil)
  if valid_21625893 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625893
  var valid_21625894 = header.getOrDefault("X-Amz-Credential")
  valid_21625894 = validateParameter(valid_21625894, JString, required = false,
                                   default = nil)
  if valid_21625894 != nil:
    section.add "X-Amz-Credential", valid_21625894
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21625920: Call_CreateConnection_21625770; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a connection that can then be given to other AWS services like CodePipeline so that it can access third-party code repositories. The connection is in pending status until the third-party connection handshake is completed from the console.
  ## 
  let valid = call_21625920.validator(path, query, header, formData, body, _)
  let scheme = call_21625920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625920.makeUrl(scheme.get, call_21625920.host, call_21625920.base,
                               call_21625920.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625920, uri, valid, _)

proc call*(call_21625983: Call_CreateConnection_21625770; body: JsonNode): Recallable =
  ## createConnection
  ## Creates a connection that can then be given to other AWS services like CodePipeline so that it can access third-party code repositories. The connection is in pending status until the third-party connection handshake is completed from the console.
  ##   body: JObject (required)
  var body_21625984 = newJObject()
  if body != nil:
    body_21625984 = body
  result = call_21625983.call(nil, nil, nil, nil, body_21625984)

var createConnection* = Call_CreateConnection_21625770(name: "createConnection",
    meth: HttpMethod.HttpPost, host: "codestar-connections.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.codestar.connections.CodeStar_connections_20191201.CreateConnection",
    validator: validate_CreateConnection_21625771, base: "/",
    makeUrl: url_CreateConnection_21625772, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnection_21626020 = ref object of OpenApiRestCall_21625426
proc url_DeleteConnection_21626022(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteConnection_21626021(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## The connection to be deleted.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626023 = header.getOrDefault("X-Amz-Date")
  valid_21626023 = validateParameter(valid_21626023, JString, required = false,
                                   default = nil)
  if valid_21626023 != nil:
    section.add "X-Amz-Date", valid_21626023
  var valid_21626024 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626024 = validateParameter(valid_21626024, JString, required = false,
                                   default = nil)
  if valid_21626024 != nil:
    section.add "X-Amz-Security-Token", valid_21626024
  var valid_21626025 = header.getOrDefault("X-Amz-Target")
  valid_21626025 = validateParameter(valid_21626025, JString, required = true, default = newJString("com.amazonaws.codestar.connections.CodeStar_connections_20191201.DeleteConnection"))
  if valid_21626025 != nil:
    section.add "X-Amz-Target", valid_21626025
  var valid_21626026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626026 = validateParameter(valid_21626026, JString, required = false,
                                   default = nil)
  if valid_21626026 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626026
  var valid_21626027 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626027 = validateParameter(valid_21626027, JString, required = false,
                                   default = nil)
  if valid_21626027 != nil:
    section.add "X-Amz-Algorithm", valid_21626027
  var valid_21626028 = header.getOrDefault("X-Amz-Signature")
  valid_21626028 = validateParameter(valid_21626028, JString, required = false,
                                   default = nil)
  if valid_21626028 != nil:
    section.add "X-Amz-Signature", valid_21626028
  var valid_21626029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626029 = validateParameter(valid_21626029, JString, required = false,
                                   default = nil)
  if valid_21626029 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626029
  var valid_21626030 = header.getOrDefault("X-Amz-Credential")
  valid_21626030 = validateParameter(valid_21626030, JString, required = false,
                                   default = nil)
  if valid_21626030 != nil:
    section.add "X-Amz-Credential", valid_21626030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626032: Call_DeleteConnection_21626020; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## The connection to be deleted.
  ## 
  let valid = call_21626032.validator(path, query, header, formData, body, _)
  let scheme = call_21626032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626032.makeUrl(scheme.get, call_21626032.host, call_21626032.base,
                               call_21626032.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626032, uri, valid, _)

proc call*(call_21626033: Call_DeleteConnection_21626020; body: JsonNode): Recallable =
  ## deleteConnection
  ## The connection to be deleted.
  ##   body: JObject (required)
  var body_21626034 = newJObject()
  if body != nil:
    body_21626034 = body
  result = call_21626033.call(nil, nil, nil, nil, body_21626034)

var deleteConnection* = Call_DeleteConnection_21626020(name: "deleteConnection",
    meth: HttpMethod.HttpPost, host: "codestar-connections.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.codestar.connections.CodeStar_connections_20191201.DeleteConnection",
    validator: validate_DeleteConnection_21626021, base: "/",
    makeUrl: url_DeleteConnection_21626022, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnection_21626035 = ref object of OpenApiRestCall_21625426
proc url_GetConnection_21626037(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetConnection_21626036(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Returns the connection ARN and details such as status, owner, and provider type.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626038 = header.getOrDefault("X-Amz-Date")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-Date", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Security-Token", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-Target")
  valid_21626040 = validateParameter(valid_21626040, JString, required = true, default = newJString("com.amazonaws.codestar.connections.CodeStar_connections_20191201.GetConnection"))
  if valid_21626040 != nil:
    section.add "X-Amz-Target", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626041
  var valid_21626042 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "X-Amz-Algorithm", valid_21626042
  var valid_21626043 = header.getOrDefault("X-Amz-Signature")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-Signature", valid_21626043
  var valid_21626044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626044
  var valid_21626045 = header.getOrDefault("X-Amz-Credential")
  valid_21626045 = validateParameter(valid_21626045, JString, required = false,
                                   default = nil)
  if valid_21626045 != nil:
    section.add "X-Amz-Credential", valid_21626045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626047: Call_GetConnection_21626035; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the connection ARN and details such as status, owner, and provider type.
  ## 
  let valid = call_21626047.validator(path, query, header, formData, body, _)
  let scheme = call_21626047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626047.makeUrl(scheme.get, call_21626047.host, call_21626047.base,
                               call_21626047.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626047, uri, valid, _)

proc call*(call_21626048: Call_GetConnection_21626035; body: JsonNode): Recallable =
  ## getConnection
  ## Returns the connection ARN and details such as status, owner, and provider type.
  ##   body: JObject (required)
  var body_21626049 = newJObject()
  if body != nil:
    body_21626049 = body
  result = call_21626048.call(nil, nil, nil, nil, body_21626049)

var getConnection* = Call_GetConnection_21626035(name: "getConnection",
    meth: HttpMethod.HttpPost, host: "codestar-connections.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.codestar.connections.CodeStar_connections_20191201.GetConnection",
    validator: validate_GetConnection_21626036, base: "/",
    makeUrl: url_GetConnection_21626037, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConnections_21626050 = ref object of OpenApiRestCall_21625426
proc url_ListConnections_21626052(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConnections_21626051(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the connections associated with your account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626053 = query.getOrDefault("NextToken")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "NextToken", valid_21626053
  var valid_21626054 = query.getOrDefault("MaxResults")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "MaxResults", valid_21626054
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626055 = header.getOrDefault("X-Amz-Date")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-Date", valid_21626055
  var valid_21626056 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-Security-Token", valid_21626056
  var valid_21626057 = header.getOrDefault("X-Amz-Target")
  valid_21626057 = validateParameter(valid_21626057, JString, required = true, default = newJString("com.amazonaws.codestar.connections.CodeStar_connections_20191201.ListConnections"))
  if valid_21626057 != nil:
    section.add "X-Amz-Target", valid_21626057
  var valid_21626058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626058
  var valid_21626059 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "X-Amz-Algorithm", valid_21626059
  var valid_21626060 = header.getOrDefault("X-Amz-Signature")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "X-Amz-Signature", valid_21626060
  var valid_21626061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626061
  var valid_21626062 = header.getOrDefault("X-Amz-Credential")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Credential", valid_21626062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626064: Call_ListConnections_21626050; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the connections associated with your account.
  ## 
  let valid = call_21626064.validator(path, query, header, formData, body, _)
  let scheme = call_21626064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626064.makeUrl(scheme.get, call_21626064.host, call_21626064.base,
                               call_21626064.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626064, uri, valid, _)

proc call*(call_21626065: Call_ListConnections_21626050; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listConnections
  ## Lists the connections associated with your account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626067 = newJObject()
  var body_21626068 = newJObject()
  add(query_21626067, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626068 = body
  add(query_21626067, "MaxResults", newJString(MaxResults))
  result = call_21626065.call(nil, query_21626067, nil, nil, body_21626068)

var listConnections* = Call_ListConnections_21626050(name: "listConnections",
    meth: HttpMethod.HttpPost, host: "codestar-connections.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.codestar.connections.CodeStar_connections_20191201.ListConnections",
    validator: validate_ListConnections_21626051, base: "/",
    makeUrl: url_ListConnections_21626052, schemes: {Scheme.Https, Scheme.Http})
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}