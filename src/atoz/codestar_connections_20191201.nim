
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

  OpenApiRestCall_605580 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605580](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605580): Option[Scheme] {.used.} =
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
  Call_CreateConnection_605918 = ref object of OpenApiRestCall_605580
proc url_CreateConnection_605920(protocol: Scheme; host: string; base: string;
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

proc validate_CreateConnection_605919(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606045 = header.getOrDefault("X-Amz-Target")
  valid_606045 = validateParameter(valid_606045, JString, required = true, default = newJString("com.amazonaws.codestar.connections.CodeStar_connections_20191201.CreateConnection"))
  if valid_606045 != nil:
    section.add "X-Amz-Target", valid_606045
  var valid_606046 = header.getOrDefault("X-Amz-Signature")
  valid_606046 = validateParameter(valid_606046, JString, required = false,
                                 default = nil)
  if valid_606046 != nil:
    section.add "X-Amz-Signature", valid_606046
  var valid_606047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606047 = validateParameter(valid_606047, JString, required = false,
                                 default = nil)
  if valid_606047 != nil:
    section.add "X-Amz-Content-Sha256", valid_606047
  var valid_606048 = header.getOrDefault("X-Amz-Date")
  valid_606048 = validateParameter(valid_606048, JString, required = false,
                                 default = nil)
  if valid_606048 != nil:
    section.add "X-Amz-Date", valid_606048
  var valid_606049 = header.getOrDefault("X-Amz-Credential")
  valid_606049 = validateParameter(valid_606049, JString, required = false,
                                 default = nil)
  if valid_606049 != nil:
    section.add "X-Amz-Credential", valid_606049
  var valid_606050 = header.getOrDefault("X-Amz-Security-Token")
  valid_606050 = validateParameter(valid_606050, JString, required = false,
                                 default = nil)
  if valid_606050 != nil:
    section.add "X-Amz-Security-Token", valid_606050
  var valid_606051 = header.getOrDefault("X-Amz-Algorithm")
  valid_606051 = validateParameter(valid_606051, JString, required = false,
                                 default = nil)
  if valid_606051 != nil:
    section.add "X-Amz-Algorithm", valid_606051
  var valid_606052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606052 = validateParameter(valid_606052, JString, required = false,
                                 default = nil)
  if valid_606052 != nil:
    section.add "X-Amz-SignedHeaders", valid_606052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606076: Call_CreateConnection_605918; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a connection that can then be given to other AWS services like CodePipeline so that it can access third-party code repositories. The connection is in pending status until the third-party connection handshake is completed from the console.
  ## 
  let valid = call_606076.validator(path, query, header, formData, body)
  let scheme = call_606076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606076.url(scheme.get, call_606076.host, call_606076.base,
                         call_606076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606076, url, valid)

proc call*(call_606147: Call_CreateConnection_605918; body: JsonNode): Recallable =
  ## createConnection
  ## Creates a connection that can then be given to other AWS services like CodePipeline so that it can access third-party code repositories. The connection is in pending status until the third-party connection handshake is completed from the console.
  ##   body: JObject (required)
  var body_606148 = newJObject()
  if body != nil:
    body_606148 = body
  result = call_606147.call(nil, nil, nil, nil, body_606148)

var createConnection* = Call_CreateConnection_605918(name: "createConnection",
    meth: HttpMethod.HttpPost, host: "codestar-connections.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.codestar.connections.CodeStar_connections_20191201.CreateConnection",
    validator: validate_CreateConnection_605919, base: "/",
    url: url_CreateConnection_605920, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnection_606187 = ref object of OpenApiRestCall_605580
proc url_DeleteConnection_606189(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteConnection_606188(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606190 = header.getOrDefault("X-Amz-Target")
  valid_606190 = validateParameter(valid_606190, JString, required = true, default = newJString("com.amazonaws.codestar.connections.CodeStar_connections_20191201.DeleteConnection"))
  if valid_606190 != nil:
    section.add "X-Amz-Target", valid_606190
  var valid_606191 = header.getOrDefault("X-Amz-Signature")
  valid_606191 = validateParameter(valid_606191, JString, required = false,
                                 default = nil)
  if valid_606191 != nil:
    section.add "X-Amz-Signature", valid_606191
  var valid_606192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606192 = validateParameter(valid_606192, JString, required = false,
                                 default = nil)
  if valid_606192 != nil:
    section.add "X-Amz-Content-Sha256", valid_606192
  var valid_606193 = header.getOrDefault("X-Amz-Date")
  valid_606193 = validateParameter(valid_606193, JString, required = false,
                                 default = nil)
  if valid_606193 != nil:
    section.add "X-Amz-Date", valid_606193
  var valid_606194 = header.getOrDefault("X-Amz-Credential")
  valid_606194 = validateParameter(valid_606194, JString, required = false,
                                 default = nil)
  if valid_606194 != nil:
    section.add "X-Amz-Credential", valid_606194
  var valid_606195 = header.getOrDefault("X-Amz-Security-Token")
  valid_606195 = validateParameter(valid_606195, JString, required = false,
                                 default = nil)
  if valid_606195 != nil:
    section.add "X-Amz-Security-Token", valid_606195
  var valid_606196 = header.getOrDefault("X-Amz-Algorithm")
  valid_606196 = validateParameter(valid_606196, JString, required = false,
                                 default = nil)
  if valid_606196 != nil:
    section.add "X-Amz-Algorithm", valid_606196
  var valid_606197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606197 = validateParameter(valid_606197, JString, required = false,
                                 default = nil)
  if valid_606197 != nil:
    section.add "X-Amz-SignedHeaders", valid_606197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606199: Call_DeleteConnection_606187; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The connection to be deleted.
  ## 
  let valid = call_606199.validator(path, query, header, formData, body)
  let scheme = call_606199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606199.url(scheme.get, call_606199.host, call_606199.base,
                         call_606199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606199, url, valid)

proc call*(call_606200: Call_DeleteConnection_606187; body: JsonNode): Recallable =
  ## deleteConnection
  ## The connection to be deleted.
  ##   body: JObject (required)
  var body_606201 = newJObject()
  if body != nil:
    body_606201 = body
  result = call_606200.call(nil, nil, nil, nil, body_606201)

var deleteConnection* = Call_DeleteConnection_606187(name: "deleteConnection",
    meth: HttpMethod.HttpPost, host: "codestar-connections.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.codestar.connections.CodeStar_connections_20191201.DeleteConnection",
    validator: validate_DeleteConnection_606188, base: "/",
    url: url_DeleteConnection_606189, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnection_606202 = ref object of OpenApiRestCall_605580
proc url_GetConnection_606204(protocol: Scheme; host: string; base: string;
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

proc validate_GetConnection_606203(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606205 = header.getOrDefault("X-Amz-Target")
  valid_606205 = validateParameter(valid_606205, JString, required = true, default = newJString("com.amazonaws.codestar.connections.CodeStar_connections_20191201.GetConnection"))
  if valid_606205 != nil:
    section.add "X-Amz-Target", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Signature")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Signature", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Content-Sha256", valid_606207
  var valid_606208 = header.getOrDefault("X-Amz-Date")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-Date", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-Credential")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-Credential", valid_606209
  var valid_606210 = header.getOrDefault("X-Amz-Security-Token")
  valid_606210 = validateParameter(valid_606210, JString, required = false,
                                 default = nil)
  if valid_606210 != nil:
    section.add "X-Amz-Security-Token", valid_606210
  var valid_606211 = header.getOrDefault("X-Amz-Algorithm")
  valid_606211 = validateParameter(valid_606211, JString, required = false,
                                 default = nil)
  if valid_606211 != nil:
    section.add "X-Amz-Algorithm", valid_606211
  var valid_606212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606212 = validateParameter(valid_606212, JString, required = false,
                                 default = nil)
  if valid_606212 != nil:
    section.add "X-Amz-SignedHeaders", valid_606212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606214: Call_GetConnection_606202; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the connection ARN and details such as status, owner, and provider type.
  ## 
  let valid = call_606214.validator(path, query, header, formData, body)
  let scheme = call_606214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606214.url(scheme.get, call_606214.host, call_606214.base,
                         call_606214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606214, url, valid)

proc call*(call_606215: Call_GetConnection_606202; body: JsonNode): Recallable =
  ## getConnection
  ## Returns the connection ARN and details such as status, owner, and provider type.
  ##   body: JObject (required)
  var body_606216 = newJObject()
  if body != nil:
    body_606216 = body
  result = call_606215.call(nil, nil, nil, nil, body_606216)

var getConnection* = Call_GetConnection_606202(name: "getConnection",
    meth: HttpMethod.HttpPost, host: "codestar-connections.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.codestar.connections.CodeStar_connections_20191201.GetConnection",
    validator: validate_GetConnection_606203, base: "/", url: url_GetConnection_606204,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConnections_606217 = ref object of OpenApiRestCall_605580
proc url_ListConnections_606219(protocol: Scheme; host: string; base: string;
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

proc validate_ListConnections_606218(path: JsonNode; query: JsonNode;
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
  var valid_606220 = query.getOrDefault("MaxResults")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "MaxResults", valid_606220
  var valid_606221 = query.getOrDefault("NextToken")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "NextToken", valid_606221
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606222 = header.getOrDefault("X-Amz-Target")
  valid_606222 = validateParameter(valid_606222, JString, required = true, default = newJString("com.amazonaws.codestar.connections.CodeStar_connections_20191201.ListConnections"))
  if valid_606222 != nil:
    section.add "X-Amz-Target", valid_606222
  var valid_606223 = header.getOrDefault("X-Amz-Signature")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-Signature", valid_606223
  var valid_606224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Content-Sha256", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-Date")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-Date", valid_606225
  var valid_606226 = header.getOrDefault("X-Amz-Credential")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "X-Amz-Credential", valid_606226
  var valid_606227 = header.getOrDefault("X-Amz-Security-Token")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "X-Amz-Security-Token", valid_606227
  var valid_606228 = header.getOrDefault("X-Amz-Algorithm")
  valid_606228 = validateParameter(valid_606228, JString, required = false,
                                 default = nil)
  if valid_606228 != nil:
    section.add "X-Amz-Algorithm", valid_606228
  var valid_606229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606229 = validateParameter(valid_606229, JString, required = false,
                                 default = nil)
  if valid_606229 != nil:
    section.add "X-Amz-SignedHeaders", valid_606229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606231: Call_ListConnections_606217; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the connections associated with your account.
  ## 
  let valid = call_606231.validator(path, query, header, formData, body)
  let scheme = call_606231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606231.url(scheme.get, call_606231.host, call_606231.base,
                         call_606231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606231, url, valid)

proc call*(call_606232: Call_ListConnections_606217; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listConnections
  ## Lists the connections associated with your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606233 = newJObject()
  var body_606234 = newJObject()
  add(query_606233, "MaxResults", newJString(MaxResults))
  add(query_606233, "NextToken", newJString(NextToken))
  if body != nil:
    body_606234 = body
  result = call_606232.call(nil, query_606233, nil, nil, body_606234)

var listConnections* = Call_ListConnections_606217(name: "listConnections",
    meth: HttpMethod.HttpPost, host: "codestar-connections.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.codestar.connections.CodeStar_connections_20191201.ListConnections",
    validator: validate_ListConnections_606218, base: "/", url: url_ListConnections_606219,
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
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
