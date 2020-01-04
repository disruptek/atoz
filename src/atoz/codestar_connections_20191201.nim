
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

  OpenApiRestCall_601380 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601380](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601380): Option[Scheme] {.used.} =
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
  Call_CreateConnection_601718 = ref object of OpenApiRestCall_601380
proc url_CreateConnection_601720(protocol: Scheme; host: string; base: string;
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

proc validate_CreateConnection_601719(path: JsonNode; query: JsonNode;
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
  var valid_601845 = header.getOrDefault("X-Amz-Target")
  valid_601845 = validateParameter(valid_601845, JString, required = true, default = newJString("com.amazonaws.codestar.connections.CodeStar_connections_20191201.CreateConnection"))
  if valid_601845 != nil:
    section.add "X-Amz-Target", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-Signature")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Signature", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-Content-Sha256", valid_601847
  var valid_601848 = header.getOrDefault("X-Amz-Date")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "X-Amz-Date", valid_601848
  var valid_601849 = header.getOrDefault("X-Amz-Credential")
  valid_601849 = validateParameter(valid_601849, JString, required = false,
                                 default = nil)
  if valid_601849 != nil:
    section.add "X-Amz-Credential", valid_601849
  var valid_601850 = header.getOrDefault("X-Amz-Security-Token")
  valid_601850 = validateParameter(valid_601850, JString, required = false,
                                 default = nil)
  if valid_601850 != nil:
    section.add "X-Amz-Security-Token", valid_601850
  var valid_601851 = header.getOrDefault("X-Amz-Algorithm")
  valid_601851 = validateParameter(valid_601851, JString, required = false,
                                 default = nil)
  if valid_601851 != nil:
    section.add "X-Amz-Algorithm", valid_601851
  var valid_601852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601852 = validateParameter(valid_601852, JString, required = false,
                                 default = nil)
  if valid_601852 != nil:
    section.add "X-Amz-SignedHeaders", valid_601852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601876: Call_CreateConnection_601718; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a connection that can then be given to other AWS services like CodePipeline so that it can access third-party code repositories. The connection is in pending status until the third-party connection handshake is completed from the console.
  ## 
  let valid = call_601876.validator(path, query, header, formData, body)
  let scheme = call_601876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601876.url(scheme.get, call_601876.host, call_601876.base,
                         call_601876.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601876, url, valid)

proc call*(call_601947: Call_CreateConnection_601718; body: JsonNode): Recallable =
  ## createConnection
  ## Creates a connection that can then be given to other AWS services like CodePipeline so that it can access third-party code repositories. The connection is in pending status until the third-party connection handshake is completed from the console.
  ##   body: JObject (required)
  var body_601948 = newJObject()
  if body != nil:
    body_601948 = body
  result = call_601947.call(nil, nil, nil, nil, body_601948)

var createConnection* = Call_CreateConnection_601718(name: "createConnection",
    meth: HttpMethod.HttpPost, host: "codestar-connections.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.codestar.connections.CodeStar_connections_20191201.CreateConnection",
    validator: validate_CreateConnection_601719, base: "/",
    url: url_CreateConnection_601720, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnection_601987 = ref object of OpenApiRestCall_601380
proc url_DeleteConnection_601989(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteConnection_601988(path: JsonNode; query: JsonNode;
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
  var valid_601990 = header.getOrDefault("X-Amz-Target")
  valid_601990 = validateParameter(valid_601990, JString, required = true, default = newJString("com.amazonaws.codestar.connections.CodeStar_connections_20191201.DeleteConnection"))
  if valid_601990 != nil:
    section.add "X-Amz-Target", valid_601990
  var valid_601991 = header.getOrDefault("X-Amz-Signature")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "X-Amz-Signature", valid_601991
  var valid_601992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = nil)
  if valid_601992 != nil:
    section.add "X-Amz-Content-Sha256", valid_601992
  var valid_601993 = header.getOrDefault("X-Amz-Date")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "X-Amz-Date", valid_601993
  var valid_601994 = header.getOrDefault("X-Amz-Credential")
  valid_601994 = validateParameter(valid_601994, JString, required = false,
                                 default = nil)
  if valid_601994 != nil:
    section.add "X-Amz-Credential", valid_601994
  var valid_601995 = header.getOrDefault("X-Amz-Security-Token")
  valid_601995 = validateParameter(valid_601995, JString, required = false,
                                 default = nil)
  if valid_601995 != nil:
    section.add "X-Amz-Security-Token", valid_601995
  var valid_601996 = header.getOrDefault("X-Amz-Algorithm")
  valid_601996 = validateParameter(valid_601996, JString, required = false,
                                 default = nil)
  if valid_601996 != nil:
    section.add "X-Amz-Algorithm", valid_601996
  var valid_601997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601997 = validateParameter(valid_601997, JString, required = false,
                                 default = nil)
  if valid_601997 != nil:
    section.add "X-Amz-SignedHeaders", valid_601997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601999: Call_DeleteConnection_601987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The connection to be deleted.
  ## 
  let valid = call_601999.validator(path, query, header, formData, body)
  let scheme = call_601999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601999.url(scheme.get, call_601999.host, call_601999.base,
                         call_601999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601999, url, valid)

proc call*(call_602000: Call_DeleteConnection_601987; body: JsonNode): Recallable =
  ## deleteConnection
  ## The connection to be deleted.
  ##   body: JObject (required)
  var body_602001 = newJObject()
  if body != nil:
    body_602001 = body
  result = call_602000.call(nil, nil, nil, nil, body_602001)

var deleteConnection* = Call_DeleteConnection_601987(name: "deleteConnection",
    meth: HttpMethod.HttpPost, host: "codestar-connections.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.codestar.connections.CodeStar_connections_20191201.DeleteConnection",
    validator: validate_DeleteConnection_601988, base: "/",
    url: url_DeleteConnection_601989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnection_602002 = ref object of OpenApiRestCall_601380
proc url_GetConnection_602004(protocol: Scheme; host: string; base: string;
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

proc validate_GetConnection_602003(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602005 = header.getOrDefault("X-Amz-Target")
  valid_602005 = validateParameter(valid_602005, JString, required = true, default = newJString("com.amazonaws.codestar.connections.CodeStar_connections_20191201.GetConnection"))
  if valid_602005 != nil:
    section.add "X-Amz-Target", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Signature")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Signature", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Content-Sha256", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-Date")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Date", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-Credential")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Credential", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-Security-Token")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-Security-Token", valid_602010
  var valid_602011 = header.getOrDefault("X-Amz-Algorithm")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "X-Amz-Algorithm", valid_602011
  var valid_602012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "X-Amz-SignedHeaders", valid_602012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602014: Call_GetConnection_602002; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the connection ARN and details such as status, owner, and provider type.
  ## 
  let valid = call_602014.validator(path, query, header, formData, body)
  let scheme = call_602014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602014.url(scheme.get, call_602014.host, call_602014.base,
                         call_602014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602014, url, valid)

proc call*(call_602015: Call_GetConnection_602002; body: JsonNode): Recallable =
  ## getConnection
  ## Returns the connection ARN and details such as status, owner, and provider type.
  ##   body: JObject (required)
  var body_602016 = newJObject()
  if body != nil:
    body_602016 = body
  result = call_602015.call(nil, nil, nil, nil, body_602016)

var getConnection* = Call_GetConnection_602002(name: "getConnection",
    meth: HttpMethod.HttpPost, host: "codestar-connections.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.codestar.connections.CodeStar_connections_20191201.GetConnection",
    validator: validate_GetConnection_602003, base: "/", url: url_GetConnection_602004,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConnections_602017 = ref object of OpenApiRestCall_601380
proc url_ListConnections_602019(protocol: Scheme; host: string; base: string;
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

proc validate_ListConnections_602018(path: JsonNode; query: JsonNode;
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
  var valid_602020 = query.getOrDefault("MaxResults")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "MaxResults", valid_602020
  var valid_602021 = query.getOrDefault("NextToken")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "NextToken", valid_602021
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
  var valid_602022 = header.getOrDefault("X-Amz-Target")
  valid_602022 = validateParameter(valid_602022, JString, required = true, default = newJString("com.amazonaws.codestar.connections.CodeStar_connections_20191201.ListConnections"))
  if valid_602022 != nil:
    section.add "X-Amz-Target", valid_602022
  var valid_602023 = header.getOrDefault("X-Amz-Signature")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-Signature", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Content-Sha256", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Date")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Date", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-Credential")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Credential", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-Security-Token")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-Security-Token", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-Algorithm")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-Algorithm", valid_602028
  var valid_602029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-SignedHeaders", valid_602029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602031: Call_ListConnections_602017; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the connections associated with your account.
  ## 
  let valid = call_602031.validator(path, query, header, formData, body)
  let scheme = call_602031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602031.url(scheme.get, call_602031.host, call_602031.base,
                         call_602031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602031, url, valid)

proc call*(call_602032: Call_ListConnections_602017; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listConnections
  ## Lists the connections associated with your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602033 = newJObject()
  var body_602034 = newJObject()
  add(query_602033, "MaxResults", newJString(MaxResults))
  add(query_602033, "NextToken", newJString(NextToken))
  if body != nil:
    body_602034 = body
  result = call_602032.call(nil, query_602033, nil, nil, body_602034)

var listConnections* = Call_ListConnections_602017(name: "listConnections",
    meth: HttpMethod.HttpPost, host: "codestar-connections.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.codestar.connections.CodeStar_connections_20191201.ListConnections",
    validator: validate_ListConnections_602018, base: "/", url: url_ListConnections_602019,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
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
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
