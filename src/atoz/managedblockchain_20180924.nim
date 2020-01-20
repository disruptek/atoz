
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Managed Blockchain
## version: 2018-09-24
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p/> <p>Amazon Managed Blockchain is a fully managed service for creating and managing blockchain networks using open source frameworks. Blockchain allows you to build applications where multiple parties can securely and transparently run transactions and share data without the need for a trusted, central authority. Currently, Managed Blockchain supports the Hyperledger Fabric open source framework. </p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/managedblockchain/
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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "managedblockchain.ap-northeast-1.amazonaws.com", "ap-southeast-1": "managedblockchain.ap-southeast-1.amazonaws.com", "us-west-2": "managedblockchain.us-west-2.amazonaws.com", "eu-west-2": "managedblockchain.eu-west-2.amazonaws.com", "ap-northeast-3": "managedblockchain.ap-northeast-3.amazonaws.com", "eu-central-1": "managedblockchain.eu-central-1.amazonaws.com", "us-east-2": "managedblockchain.us-east-2.amazonaws.com", "us-east-1": "managedblockchain.us-east-1.amazonaws.com", "cn-northwest-1": "managedblockchain.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "managedblockchain.ap-south-1.amazonaws.com", "eu-north-1": "managedblockchain.eu-north-1.amazonaws.com", "ap-northeast-2": "managedblockchain.ap-northeast-2.amazonaws.com", "us-west-1": "managedblockchain.us-west-1.amazonaws.com", "us-gov-east-1": "managedblockchain.us-gov-east-1.amazonaws.com", "eu-west-3": "managedblockchain.eu-west-3.amazonaws.com", "cn-north-1": "managedblockchain.cn-north-1.amazonaws.com.cn", "sa-east-1": "managedblockchain.sa-east-1.amazonaws.com", "eu-west-1": "managedblockchain.eu-west-1.amazonaws.com", "us-gov-west-1": "managedblockchain.us-gov-west-1.amazonaws.com", "ap-southeast-2": "managedblockchain.ap-southeast-2.amazonaws.com", "ca-central-1": "managedblockchain.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "managedblockchain.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "managedblockchain.ap-southeast-1.amazonaws.com",
      "us-west-2": "managedblockchain.us-west-2.amazonaws.com",
      "eu-west-2": "managedblockchain.eu-west-2.amazonaws.com",
      "ap-northeast-3": "managedblockchain.ap-northeast-3.amazonaws.com",
      "eu-central-1": "managedblockchain.eu-central-1.amazonaws.com",
      "us-east-2": "managedblockchain.us-east-2.amazonaws.com",
      "us-east-1": "managedblockchain.us-east-1.amazonaws.com",
      "cn-northwest-1": "managedblockchain.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "managedblockchain.ap-south-1.amazonaws.com",
      "eu-north-1": "managedblockchain.eu-north-1.amazonaws.com",
      "ap-northeast-2": "managedblockchain.ap-northeast-2.amazonaws.com",
      "us-west-1": "managedblockchain.us-west-1.amazonaws.com",
      "us-gov-east-1": "managedblockchain.us-gov-east-1.amazonaws.com",
      "eu-west-3": "managedblockchain.eu-west-3.amazonaws.com",
      "cn-north-1": "managedblockchain.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "managedblockchain.sa-east-1.amazonaws.com",
      "eu-west-1": "managedblockchain.eu-west-1.amazonaws.com",
      "us-gov-west-1": "managedblockchain.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "managedblockchain.ap-southeast-2.amazonaws.com",
      "ca-central-1": "managedblockchain.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "managedblockchain"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateMember_606218 = ref object of OpenApiRestCall_605589
proc url_CreateMember_606220(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "networkId" in path, "`networkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/networks/"),
               (kind: VariableSegment, value: "networkId"),
               (kind: ConstantSegment, value: "/members")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateMember_606219(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a member within a Managed Blockchain network.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   networkId: JString (required)
  ##            : The unique identifier of the network in which the member is created.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `networkId` field"
  var valid_606221 = path.getOrDefault("networkId")
  valid_606221 = validateParameter(valid_606221, JString, required = true,
                                 default = nil)
  if valid_606221 != nil:
    section.add "networkId", valid_606221
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606222 = header.getOrDefault("X-Amz-Signature")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "X-Amz-Signature", valid_606222
  var valid_606223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-Content-Sha256", valid_606223
  var valid_606224 = header.getOrDefault("X-Amz-Date")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Date", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-Credential")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-Credential", valid_606225
  var valid_606226 = header.getOrDefault("X-Amz-Security-Token")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "X-Amz-Security-Token", valid_606226
  var valid_606227 = header.getOrDefault("X-Amz-Algorithm")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "X-Amz-Algorithm", valid_606227
  var valid_606228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606228 = validateParameter(valid_606228, JString, required = false,
                                 default = nil)
  if valid_606228 != nil:
    section.add "X-Amz-SignedHeaders", valid_606228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606230: Call_CreateMember_606218; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a member within a Managed Blockchain network.
  ## 
  let valid = call_606230.validator(path, query, header, formData, body)
  let scheme = call_606230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606230.url(scheme.get, call_606230.host, call_606230.base,
                         call_606230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606230, url, valid)

proc call*(call_606231: Call_CreateMember_606218; networkId: string; body: JsonNode): Recallable =
  ## createMember
  ## Creates a member within a Managed Blockchain network.
  ##   networkId: string (required)
  ##            : The unique identifier of the network in which the member is created.
  ##   body: JObject (required)
  var path_606232 = newJObject()
  var body_606233 = newJObject()
  add(path_606232, "networkId", newJString(networkId))
  if body != nil:
    body_606233 = body
  result = call_606231.call(path_606232, nil, nil, nil, body_606233)

var createMember* = Call_CreateMember_606218(name: "createMember",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/members", validator: validate_CreateMember_606219,
    base: "/", url: url_CreateMember_606220, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_605927 = ref object of OpenApiRestCall_605589
proc url_ListMembers_605929(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "networkId" in path, "`networkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/networks/"),
               (kind: VariableSegment, value: "networkId"),
               (kind: ConstantSegment, value: "/members")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListMembers_605928(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a listing of the members in a network and properties of their configurations.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   networkId: JString (required)
  ##            : The unique identifier of the network for which to list members.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `networkId` field"
  var valid_606055 = path.getOrDefault("networkId")
  valid_606055 = validateParameter(valid_606055, JString, required = true,
                                 default = nil)
  if valid_606055 != nil:
    section.add "networkId", valid_606055
  result.add "path", section
  ## parameters in `query` object:
  ##   name: JString
  ##       : The optional name of the member to list.
  ##   nextToken: JString
  ##            : The pagination token that indicates the next set of results to retrieve.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   isOwned: JBool
  ##          : An optional Boolean value. If provided, the request is limited either to members that the current AWS account owns (<code>true</code>) or that other AWS accounts own (<code>false</code>). If omitted, all members are listed.
  ##   status: JString
  ##         : An optional status specifier. If provided, only members currently in this status are listed.
  ##   maxResults: JInt
  ##             : The maximum number of members to return in the request.
  section = newJObject()
  var valid_606056 = query.getOrDefault("name")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "name", valid_606056
  var valid_606057 = query.getOrDefault("nextToken")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "nextToken", valid_606057
  var valid_606058 = query.getOrDefault("MaxResults")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "MaxResults", valid_606058
  var valid_606059 = query.getOrDefault("NextToken")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "NextToken", valid_606059
  var valid_606060 = query.getOrDefault("isOwned")
  valid_606060 = validateParameter(valid_606060, JBool, required = false, default = nil)
  if valid_606060 != nil:
    section.add "isOwned", valid_606060
  var valid_606074 = query.getOrDefault("status")
  valid_606074 = validateParameter(valid_606074, JString, required = false,
                                 default = newJString("CREATING"))
  if valid_606074 != nil:
    section.add "status", valid_606074
  var valid_606075 = query.getOrDefault("maxResults")
  valid_606075 = validateParameter(valid_606075, JInt, required = false, default = nil)
  if valid_606075 != nil:
    section.add "maxResults", valid_606075
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606076 = header.getOrDefault("X-Amz-Signature")
  valid_606076 = validateParameter(valid_606076, JString, required = false,
                                 default = nil)
  if valid_606076 != nil:
    section.add "X-Amz-Signature", valid_606076
  var valid_606077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606077 = validateParameter(valid_606077, JString, required = false,
                                 default = nil)
  if valid_606077 != nil:
    section.add "X-Amz-Content-Sha256", valid_606077
  var valid_606078 = header.getOrDefault("X-Amz-Date")
  valid_606078 = validateParameter(valid_606078, JString, required = false,
                                 default = nil)
  if valid_606078 != nil:
    section.add "X-Amz-Date", valid_606078
  var valid_606079 = header.getOrDefault("X-Amz-Credential")
  valid_606079 = validateParameter(valid_606079, JString, required = false,
                                 default = nil)
  if valid_606079 != nil:
    section.add "X-Amz-Credential", valid_606079
  var valid_606080 = header.getOrDefault("X-Amz-Security-Token")
  valid_606080 = validateParameter(valid_606080, JString, required = false,
                                 default = nil)
  if valid_606080 != nil:
    section.add "X-Amz-Security-Token", valid_606080
  var valid_606081 = header.getOrDefault("X-Amz-Algorithm")
  valid_606081 = validateParameter(valid_606081, JString, required = false,
                                 default = nil)
  if valid_606081 != nil:
    section.add "X-Amz-Algorithm", valid_606081
  var valid_606082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606082 = validateParameter(valid_606082, JString, required = false,
                                 default = nil)
  if valid_606082 != nil:
    section.add "X-Amz-SignedHeaders", valid_606082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606105: Call_ListMembers_605927; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a listing of the members in a network and properties of their configurations.
  ## 
  let valid = call_606105.validator(path, query, header, formData, body)
  let scheme = call_606105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606105.url(scheme.get, call_606105.host, call_606105.base,
                         call_606105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606105, url, valid)

proc call*(call_606176: Call_ListMembers_605927; networkId: string;
          name: string = ""; nextToken: string = ""; MaxResults: string = "";
          NextToken: string = ""; isOwned: bool = false; status: string = "CREATING";
          maxResults: int = 0): Recallable =
  ## listMembers
  ## Returns a listing of the members in a network and properties of their configurations.
  ##   name: string
  ##       : The optional name of the member to list.
  ##   nextToken: string
  ##            : The pagination token that indicates the next set of results to retrieve.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   networkId: string (required)
  ##            : The unique identifier of the network for which to list members.
  ##   isOwned: bool
  ##          : An optional Boolean value. If provided, the request is limited either to members that the current AWS account owns (<code>true</code>) or that other AWS accounts own (<code>false</code>). If omitted, all members are listed.
  ##   status: string
  ##         : An optional status specifier. If provided, only members currently in this status are listed.
  ##   maxResults: int
  ##             : The maximum number of members to return in the request.
  var path_606177 = newJObject()
  var query_606179 = newJObject()
  add(query_606179, "name", newJString(name))
  add(query_606179, "nextToken", newJString(nextToken))
  add(query_606179, "MaxResults", newJString(MaxResults))
  add(query_606179, "NextToken", newJString(NextToken))
  add(path_606177, "networkId", newJString(networkId))
  add(query_606179, "isOwned", newJBool(isOwned))
  add(query_606179, "status", newJString(status))
  add(query_606179, "maxResults", newJInt(maxResults))
  result = call_606176.call(path_606177, query_606179, nil, nil, nil)

var listMembers* = Call_ListMembers_605927(name: "listMembers",
                                        meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
                                        route: "/networks/{networkId}/members",
                                        validator: validate_ListMembers_605928,
                                        base: "/", url: url_ListMembers_605929,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNetwork_606254 = ref object of OpenApiRestCall_605589
proc url_CreateNetwork_606256(protocol: Scheme; host: string; base: string;
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

proc validate_CreateNetwork_606255(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new blockchain network using Amazon Managed Blockchain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606257 = header.getOrDefault("X-Amz-Signature")
  valid_606257 = validateParameter(valid_606257, JString, required = false,
                                 default = nil)
  if valid_606257 != nil:
    section.add "X-Amz-Signature", valid_606257
  var valid_606258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606258 = validateParameter(valid_606258, JString, required = false,
                                 default = nil)
  if valid_606258 != nil:
    section.add "X-Amz-Content-Sha256", valid_606258
  var valid_606259 = header.getOrDefault("X-Amz-Date")
  valid_606259 = validateParameter(valid_606259, JString, required = false,
                                 default = nil)
  if valid_606259 != nil:
    section.add "X-Amz-Date", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-Credential")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Credential", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Security-Token")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Security-Token", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Algorithm")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Algorithm", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-SignedHeaders", valid_606263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606265: Call_CreateNetwork_606254; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new blockchain network using Amazon Managed Blockchain.
  ## 
  let valid = call_606265.validator(path, query, header, formData, body)
  let scheme = call_606265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606265.url(scheme.get, call_606265.host, call_606265.base,
                         call_606265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606265, url, valid)

proc call*(call_606266: Call_CreateNetwork_606254; body: JsonNode): Recallable =
  ## createNetwork
  ## Creates a new blockchain network using Amazon Managed Blockchain.
  ##   body: JObject (required)
  var body_606267 = newJObject()
  if body != nil:
    body_606267 = body
  result = call_606266.call(nil, nil, nil, nil, body_606267)

var createNetwork* = Call_CreateNetwork_606254(name: "createNetwork",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks", validator: validate_CreateNetwork_606255, base: "/",
    url: url_CreateNetwork_606256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNetworks_606234 = ref object of OpenApiRestCall_605589
proc url_ListNetworks_606236(protocol: Scheme; host: string; base: string;
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

proc validate_ListNetworks_606235(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about the networks in which the current AWS account has members.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   framework: JString
  ##            : An optional framework specifier. If provided, only networks of this framework type are listed.
  ##   name: JString
  ##       : The name of the network.
  ##   nextToken: JString
  ##            : The pagination token that indicates the next set of results to retrieve.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   status: JString
  ##         : An optional status specifier. If provided, only networks currently in this status are listed.
  ##   maxResults: JInt
  ##             : The maximum number of networks to list.
  section = newJObject()
  var valid_606237 = query.getOrDefault("framework")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = newJString("HYPERLEDGER_FABRIC"))
  if valid_606237 != nil:
    section.add "framework", valid_606237
  var valid_606238 = query.getOrDefault("name")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "name", valid_606238
  var valid_606239 = query.getOrDefault("nextToken")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "nextToken", valid_606239
  var valid_606240 = query.getOrDefault("MaxResults")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "MaxResults", valid_606240
  var valid_606241 = query.getOrDefault("NextToken")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "NextToken", valid_606241
  var valid_606242 = query.getOrDefault("status")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = newJString("CREATING"))
  if valid_606242 != nil:
    section.add "status", valid_606242
  var valid_606243 = query.getOrDefault("maxResults")
  valid_606243 = validateParameter(valid_606243, JInt, required = false, default = nil)
  if valid_606243 != nil:
    section.add "maxResults", valid_606243
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606244 = header.getOrDefault("X-Amz-Signature")
  valid_606244 = validateParameter(valid_606244, JString, required = false,
                                 default = nil)
  if valid_606244 != nil:
    section.add "X-Amz-Signature", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Content-Sha256", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Date")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Date", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Credential")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Credential", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Security-Token")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Security-Token", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Algorithm")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Algorithm", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-SignedHeaders", valid_606250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606251: Call_ListNetworks_606234; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the networks in which the current AWS account has members.
  ## 
  let valid = call_606251.validator(path, query, header, formData, body)
  let scheme = call_606251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606251.url(scheme.get, call_606251.host, call_606251.base,
                         call_606251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606251, url, valid)

proc call*(call_606252: Call_ListNetworks_606234;
          framework: string = "HYPERLEDGER_FABRIC"; name: string = "";
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          status: string = "CREATING"; maxResults: int = 0): Recallable =
  ## listNetworks
  ## Returns information about the networks in which the current AWS account has members.
  ##   framework: string
  ##            : An optional framework specifier. If provided, only networks of this framework type are listed.
  ##   name: string
  ##       : The name of the network.
  ##   nextToken: string
  ##            : The pagination token that indicates the next set of results to retrieve.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   status: string
  ##         : An optional status specifier. If provided, only networks currently in this status are listed.
  ##   maxResults: int
  ##             : The maximum number of networks to list.
  var query_606253 = newJObject()
  add(query_606253, "framework", newJString(framework))
  add(query_606253, "name", newJString(name))
  add(query_606253, "nextToken", newJString(nextToken))
  add(query_606253, "MaxResults", newJString(MaxResults))
  add(query_606253, "NextToken", newJString(NextToken))
  add(query_606253, "status", newJString(status))
  add(query_606253, "maxResults", newJInt(maxResults))
  result = call_606252.call(nil, query_606253, nil, nil, nil)

var listNetworks* = Call_ListNetworks_606234(name: "listNetworks",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks", validator: validate_ListNetworks_606235, base: "/",
    url: url_ListNetworks_606236, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNode_606289 = ref object of OpenApiRestCall_605589
proc url_CreateNode_606291(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "networkId" in path, "`networkId` is a required path parameter"
  assert "memberId" in path, "`memberId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/networks/"),
               (kind: VariableSegment, value: "networkId"),
               (kind: ConstantSegment, value: "/members/"),
               (kind: VariableSegment, value: "memberId"),
               (kind: ConstantSegment, value: "/nodes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateNode_606290(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a peer node in a member.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   memberId: JString (required)
  ##           : The unique identifier of the member that owns this node.
  ##   networkId: JString (required)
  ##            : The unique identifier of the network in which this node runs.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `memberId` field"
  var valid_606292 = path.getOrDefault("memberId")
  valid_606292 = validateParameter(valid_606292, JString, required = true,
                                 default = nil)
  if valid_606292 != nil:
    section.add "memberId", valid_606292
  var valid_606293 = path.getOrDefault("networkId")
  valid_606293 = validateParameter(valid_606293, JString, required = true,
                                 default = nil)
  if valid_606293 != nil:
    section.add "networkId", valid_606293
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606294 = header.getOrDefault("X-Amz-Signature")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Signature", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Content-Sha256", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-Date")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-Date", valid_606296
  var valid_606297 = header.getOrDefault("X-Amz-Credential")
  valid_606297 = validateParameter(valid_606297, JString, required = false,
                                 default = nil)
  if valid_606297 != nil:
    section.add "X-Amz-Credential", valid_606297
  var valid_606298 = header.getOrDefault("X-Amz-Security-Token")
  valid_606298 = validateParameter(valid_606298, JString, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "X-Amz-Security-Token", valid_606298
  var valid_606299 = header.getOrDefault("X-Amz-Algorithm")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "X-Amz-Algorithm", valid_606299
  var valid_606300 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "X-Amz-SignedHeaders", valid_606300
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606302: Call_CreateNode_606289; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a peer node in a member.
  ## 
  let valid = call_606302.validator(path, query, header, formData, body)
  let scheme = call_606302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606302.url(scheme.get, call_606302.host, call_606302.base,
                         call_606302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606302, url, valid)

proc call*(call_606303: Call_CreateNode_606289; memberId: string; networkId: string;
          body: JsonNode): Recallable =
  ## createNode
  ## Creates a peer node in a member.
  ##   memberId: string (required)
  ##           : The unique identifier of the member that owns this node.
  ##   networkId: string (required)
  ##            : The unique identifier of the network in which this node runs.
  ##   body: JObject (required)
  var path_606304 = newJObject()
  var body_606305 = newJObject()
  add(path_606304, "memberId", newJString(memberId))
  add(path_606304, "networkId", newJString(networkId))
  if body != nil:
    body_606305 = body
  result = call_606303.call(path_606304, nil, nil, nil, body_606305)

var createNode* = Call_CreateNode_606289(name: "createNode",
                                      meth: HttpMethod.HttpPost,
                                      host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes",
                                      validator: validate_CreateNode_606290,
                                      base: "/", url: url_CreateNode_606291,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNodes_606268 = ref object of OpenApiRestCall_605589
proc url_ListNodes_606270(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "networkId" in path, "`networkId` is a required path parameter"
  assert "memberId" in path, "`memberId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/networks/"),
               (kind: VariableSegment, value: "networkId"),
               (kind: ConstantSegment, value: "/members/"),
               (kind: VariableSegment, value: "memberId"),
               (kind: ConstantSegment, value: "/nodes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListNodes_606269(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about the nodes within a network.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   memberId: JString (required)
  ##           : The unique identifier of the member who owns the nodes to list.
  ##   networkId: JString (required)
  ##            : The unique identifier of the network for which to list nodes.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `memberId` field"
  var valid_606271 = path.getOrDefault("memberId")
  valid_606271 = validateParameter(valid_606271, JString, required = true,
                                 default = nil)
  if valid_606271 != nil:
    section.add "memberId", valid_606271
  var valid_606272 = path.getOrDefault("networkId")
  valid_606272 = validateParameter(valid_606272, JString, required = true,
                                 default = nil)
  if valid_606272 != nil:
    section.add "networkId", valid_606272
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The pagination token that indicates the next set of results to retrieve.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   status: JString
  ##         : An optional status specifier. If provided, only nodes currently in this status are listed.
  ##   maxResults: JInt
  ##             : The maximum number of nodes to list.
  section = newJObject()
  var valid_606273 = query.getOrDefault("nextToken")
  valid_606273 = validateParameter(valid_606273, JString, required = false,
                                 default = nil)
  if valid_606273 != nil:
    section.add "nextToken", valid_606273
  var valid_606274 = query.getOrDefault("MaxResults")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "MaxResults", valid_606274
  var valid_606275 = query.getOrDefault("NextToken")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "NextToken", valid_606275
  var valid_606276 = query.getOrDefault("status")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = newJString("CREATING"))
  if valid_606276 != nil:
    section.add "status", valid_606276
  var valid_606277 = query.getOrDefault("maxResults")
  valid_606277 = validateParameter(valid_606277, JInt, required = false, default = nil)
  if valid_606277 != nil:
    section.add "maxResults", valid_606277
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606278 = header.getOrDefault("X-Amz-Signature")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Signature", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Content-Sha256", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Date")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Date", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-Credential")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-Credential", valid_606281
  var valid_606282 = header.getOrDefault("X-Amz-Security-Token")
  valid_606282 = validateParameter(valid_606282, JString, required = false,
                                 default = nil)
  if valid_606282 != nil:
    section.add "X-Amz-Security-Token", valid_606282
  var valid_606283 = header.getOrDefault("X-Amz-Algorithm")
  valid_606283 = validateParameter(valid_606283, JString, required = false,
                                 default = nil)
  if valid_606283 != nil:
    section.add "X-Amz-Algorithm", valid_606283
  var valid_606284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "X-Amz-SignedHeaders", valid_606284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606285: Call_ListNodes_606268; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the nodes within a network.
  ## 
  let valid = call_606285.validator(path, query, header, formData, body)
  let scheme = call_606285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606285.url(scheme.get, call_606285.host, call_606285.base,
                         call_606285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606285, url, valid)

proc call*(call_606286: Call_ListNodes_606268; memberId: string; networkId: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          status: string = "CREATING"; maxResults: int = 0): Recallable =
  ## listNodes
  ## Returns information about the nodes within a network.
  ##   nextToken: string
  ##            : The pagination token that indicates the next set of results to retrieve.
  ##   memberId: string (required)
  ##           : The unique identifier of the member who owns the nodes to list.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   networkId: string (required)
  ##            : The unique identifier of the network for which to list nodes.
  ##   status: string
  ##         : An optional status specifier. If provided, only nodes currently in this status are listed.
  ##   maxResults: int
  ##             : The maximum number of nodes to list.
  var path_606287 = newJObject()
  var query_606288 = newJObject()
  add(query_606288, "nextToken", newJString(nextToken))
  add(path_606287, "memberId", newJString(memberId))
  add(query_606288, "MaxResults", newJString(MaxResults))
  add(query_606288, "NextToken", newJString(NextToken))
  add(path_606287, "networkId", newJString(networkId))
  add(query_606288, "status", newJString(status))
  add(query_606288, "maxResults", newJInt(maxResults))
  result = call_606286.call(path_606287, query_606288, nil, nil, nil)

var listNodes* = Call_ListNodes_606268(name: "listNodes", meth: HttpMethod.HttpGet,
                                    host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes",
                                    validator: validate_ListNodes_606269,
                                    base: "/", url: url_ListNodes_606270,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProposal_606325 = ref object of OpenApiRestCall_605589
proc url_CreateProposal_606327(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "networkId" in path, "`networkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/networks/"),
               (kind: VariableSegment, value: "networkId"),
               (kind: ConstantSegment, value: "/proposals")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateProposal_606326(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a proposal for a change to the network that other members of the network can vote on, for example, a proposal to add a new member to the network. Any member can create a proposal.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   networkId: JString (required)
  ##            :  The unique identifier of the network for which the proposal is made.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `networkId` field"
  var valid_606328 = path.getOrDefault("networkId")
  valid_606328 = validateParameter(valid_606328, JString, required = true,
                                 default = nil)
  if valid_606328 != nil:
    section.add "networkId", valid_606328
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606329 = header.getOrDefault("X-Amz-Signature")
  valid_606329 = validateParameter(valid_606329, JString, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "X-Amz-Signature", valid_606329
  var valid_606330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606330 = validateParameter(valid_606330, JString, required = false,
                                 default = nil)
  if valid_606330 != nil:
    section.add "X-Amz-Content-Sha256", valid_606330
  var valid_606331 = header.getOrDefault("X-Amz-Date")
  valid_606331 = validateParameter(valid_606331, JString, required = false,
                                 default = nil)
  if valid_606331 != nil:
    section.add "X-Amz-Date", valid_606331
  var valid_606332 = header.getOrDefault("X-Amz-Credential")
  valid_606332 = validateParameter(valid_606332, JString, required = false,
                                 default = nil)
  if valid_606332 != nil:
    section.add "X-Amz-Credential", valid_606332
  var valid_606333 = header.getOrDefault("X-Amz-Security-Token")
  valid_606333 = validateParameter(valid_606333, JString, required = false,
                                 default = nil)
  if valid_606333 != nil:
    section.add "X-Amz-Security-Token", valid_606333
  var valid_606334 = header.getOrDefault("X-Amz-Algorithm")
  valid_606334 = validateParameter(valid_606334, JString, required = false,
                                 default = nil)
  if valid_606334 != nil:
    section.add "X-Amz-Algorithm", valid_606334
  var valid_606335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-SignedHeaders", valid_606335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606337: Call_CreateProposal_606325; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a proposal for a change to the network that other members of the network can vote on, for example, a proposal to add a new member to the network. Any member can create a proposal.
  ## 
  let valid = call_606337.validator(path, query, header, formData, body)
  let scheme = call_606337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606337.url(scheme.get, call_606337.host, call_606337.base,
                         call_606337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606337, url, valid)

proc call*(call_606338: Call_CreateProposal_606325; networkId: string; body: JsonNode): Recallable =
  ## createProposal
  ## Creates a proposal for a change to the network that other members of the network can vote on, for example, a proposal to add a new member to the network. Any member can create a proposal.
  ##   networkId: string (required)
  ##            :  The unique identifier of the network for which the proposal is made.
  ##   body: JObject (required)
  var path_606339 = newJObject()
  var body_606340 = newJObject()
  add(path_606339, "networkId", newJString(networkId))
  if body != nil:
    body_606340 = body
  result = call_606338.call(path_606339, nil, nil, nil, body_606340)

var createProposal* = Call_CreateProposal_606325(name: "createProposal",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals", validator: validate_CreateProposal_606326,
    base: "/", url: url_CreateProposal_606327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProposals_606306 = ref object of OpenApiRestCall_605589
proc url_ListProposals_606308(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "networkId" in path, "`networkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/networks/"),
               (kind: VariableSegment, value: "networkId"),
               (kind: ConstantSegment, value: "/proposals")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListProposals_606307(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a listing of proposals for the network.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   networkId: JString (required)
  ##            :  The unique identifier of the network. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `networkId` field"
  var valid_606309 = path.getOrDefault("networkId")
  valid_606309 = validateParameter(valid_606309, JString, required = true,
                                 default = nil)
  if valid_606309 != nil:
    section.add "networkId", valid_606309
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  The pagination token that indicates the next set of results to retrieve. 
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             :  The maximum number of proposals to return. 
  section = newJObject()
  var valid_606310 = query.getOrDefault("nextToken")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "nextToken", valid_606310
  var valid_606311 = query.getOrDefault("MaxResults")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "MaxResults", valid_606311
  var valid_606312 = query.getOrDefault("NextToken")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "NextToken", valid_606312
  var valid_606313 = query.getOrDefault("maxResults")
  valid_606313 = validateParameter(valid_606313, JInt, required = false, default = nil)
  if valid_606313 != nil:
    section.add "maxResults", valid_606313
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606314 = header.getOrDefault("X-Amz-Signature")
  valid_606314 = validateParameter(valid_606314, JString, required = false,
                                 default = nil)
  if valid_606314 != nil:
    section.add "X-Amz-Signature", valid_606314
  var valid_606315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606315 = validateParameter(valid_606315, JString, required = false,
                                 default = nil)
  if valid_606315 != nil:
    section.add "X-Amz-Content-Sha256", valid_606315
  var valid_606316 = header.getOrDefault("X-Amz-Date")
  valid_606316 = validateParameter(valid_606316, JString, required = false,
                                 default = nil)
  if valid_606316 != nil:
    section.add "X-Amz-Date", valid_606316
  var valid_606317 = header.getOrDefault("X-Amz-Credential")
  valid_606317 = validateParameter(valid_606317, JString, required = false,
                                 default = nil)
  if valid_606317 != nil:
    section.add "X-Amz-Credential", valid_606317
  var valid_606318 = header.getOrDefault("X-Amz-Security-Token")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "X-Amz-Security-Token", valid_606318
  var valid_606319 = header.getOrDefault("X-Amz-Algorithm")
  valid_606319 = validateParameter(valid_606319, JString, required = false,
                                 default = nil)
  if valid_606319 != nil:
    section.add "X-Amz-Algorithm", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-SignedHeaders", valid_606320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606321: Call_ListProposals_606306; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a listing of proposals for the network.
  ## 
  let valid = call_606321.validator(path, query, header, formData, body)
  let scheme = call_606321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606321.url(scheme.get, call_606321.host, call_606321.base,
                         call_606321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606321, url, valid)

proc call*(call_606322: Call_ListProposals_606306; networkId: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listProposals
  ## Returns a listing of proposals for the network.
  ##   nextToken: string
  ##            :  The pagination token that indicates the next set of results to retrieve. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   networkId: string (required)
  ##            :  The unique identifier of the network. 
  ##   maxResults: int
  ##             :  The maximum number of proposals to return. 
  var path_606323 = newJObject()
  var query_606324 = newJObject()
  add(query_606324, "nextToken", newJString(nextToken))
  add(query_606324, "MaxResults", newJString(MaxResults))
  add(query_606324, "NextToken", newJString(NextToken))
  add(path_606323, "networkId", newJString(networkId))
  add(query_606324, "maxResults", newJInt(maxResults))
  result = call_606322.call(path_606323, query_606324, nil, nil, nil)

var listProposals* = Call_ListProposals_606306(name: "listProposals",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals", validator: validate_ListProposals_606307,
    base: "/", url: url_ListProposals_606308, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMember_606341 = ref object of OpenApiRestCall_605589
proc url_GetMember_606343(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "networkId" in path, "`networkId` is a required path parameter"
  assert "memberId" in path, "`memberId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/networks/"),
               (kind: VariableSegment, value: "networkId"),
               (kind: ConstantSegment, value: "/members/"),
               (kind: VariableSegment, value: "memberId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetMember_606342(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns detailed information about a member.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   memberId: JString (required)
  ##           : The unique identifier of the member.
  ##   networkId: JString (required)
  ##            : The unique identifier of the network to which the member belongs.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `memberId` field"
  var valid_606344 = path.getOrDefault("memberId")
  valid_606344 = validateParameter(valid_606344, JString, required = true,
                                 default = nil)
  if valid_606344 != nil:
    section.add "memberId", valid_606344
  var valid_606345 = path.getOrDefault("networkId")
  valid_606345 = validateParameter(valid_606345, JString, required = true,
                                 default = nil)
  if valid_606345 != nil:
    section.add "networkId", valid_606345
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606346 = header.getOrDefault("X-Amz-Signature")
  valid_606346 = validateParameter(valid_606346, JString, required = false,
                                 default = nil)
  if valid_606346 != nil:
    section.add "X-Amz-Signature", valid_606346
  var valid_606347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "X-Amz-Content-Sha256", valid_606347
  var valid_606348 = header.getOrDefault("X-Amz-Date")
  valid_606348 = validateParameter(valid_606348, JString, required = false,
                                 default = nil)
  if valid_606348 != nil:
    section.add "X-Amz-Date", valid_606348
  var valid_606349 = header.getOrDefault("X-Amz-Credential")
  valid_606349 = validateParameter(valid_606349, JString, required = false,
                                 default = nil)
  if valid_606349 != nil:
    section.add "X-Amz-Credential", valid_606349
  var valid_606350 = header.getOrDefault("X-Amz-Security-Token")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-Security-Token", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-Algorithm")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Algorithm", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-SignedHeaders", valid_606352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606353: Call_GetMember_606341; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a member.
  ## 
  let valid = call_606353.validator(path, query, header, formData, body)
  let scheme = call_606353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606353.url(scheme.get, call_606353.host, call_606353.base,
                         call_606353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606353, url, valid)

proc call*(call_606354: Call_GetMember_606341; memberId: string; networkId: string): Recallable =
  ## getMember
  ## Returns detailed information about a member.
  ##   memberId: string (required)
  ##           : The unique identifier of the member.
  ##   networkId: string (required)
  ##            : The unique identifier of the network to which the member belongs.
  var path_606355 = newJObject()
  add(path_606355, "memberId", newJString(memberId))
  add(path_606355, "networkId", newJString(networkId))
  result = call_606354.call(path_606355, nil, nil, nil, nil)

var getMember* = Call_GetMember_606341(name: "getMember", meth: HttpMethod.HttpGet,
                                    host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}",
                                    validator: validate_GetMember_606342,
                                    base: "/", url: url_GetMember_606343,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMember_606356 = ref object of OpenApiRestCall_605589
proc url_DeleteMember_606358(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "networkId" in path, "`networkId` is a required path parameter"
  assert "memberId" in path, "`memberId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/networks/"),
               (kind: VariableSegment, value: "networkId"),
               (kind: ConstantSegment, value: "/members/"),
               (kind: VariableSegment, value: "memberId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteMember_606357(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a member. Deleting a member removes the member and all associated resources from the network. <code>DeleteMember</code> can only be called for a specified <code>MemberId</code> if the principal performing the action is associated with the AWS account that owns the member. In all other cases, the <code>DeleteMember</code> action is carried out as the result of an approved proposal to remove a member. If <code>MemberId</code> is the last member in a network specified by the last AWS account, the network is deleted also.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   memberId: JString (required)
  ##           : The unique identifier of the member to remove.
  ##   networkId: JString (required)
  ##            : The unique identifier of the network from which the member is removed.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `memberId` field"
  var valid_606359 = path.getOrDefault("memberId")
  valid_606359 = validateParameter(valid_606359, JString, required = true,
                                 default = nil)
  if valid_606359 != nil:
    section.add "memberId", valid_606359
  var valid_606360 = path.getOrDefault("networkId")
  valid_606360 = validateParameter(valid_606360, JString, required = true,
                                 default = nil)
  if valid_606360 != nil:
    section.add "networkId", valid_606360
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606361 = header.getOrDefault("X-Amz-Signature")
  valid_606361 = validateParameter(valid_606361, JString, required = false,
                                 default = nil)
  if valid_606361 != nil:
    section.add "X-Amz-Signature", valid_606361
  var valid_606362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606362 = validateParameter(valid_606362, JString, required = false,
                                 default = nil)
  if valid_606362 != nil:
    section.add "X-Amz-Content-Sha256", valid_606362
  var valid_606363 = header.getOrDefault("X-Amz-Date")
  valid_606363 = validateParameter(valid_606363, JString, required = false,
                                 default = nil)
  if valid_606363 != nil:
    section.add "X-Amz-Date", valid_606363
  var valid_606364 = header.getOrDefault("X-Amz-Credential")
  valid_606364 = validateParameter(valid_606364, JString, required = false,
                                 default = nil)
  if valid_606364 != nil:
    section.add "X-Amz-Credential", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-Security-Token")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-Security-Token", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Algorithm")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Algorithm", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-SignedHeaders", valid_606367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606368: Call_DeleteMember_606356; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a member. Deleting a member removes the member and all associated resources from the network. <code>DeleteMember</code> can only be called for a specified <code>MemberId</code> if the principal performing the action is associated with the AWS account that owns the member. In all other cases, the <code>DeleteMember</code> action is carried out as the result of an approved proposal to remove a member. If <code>MemberId</code> is the last member in a network specified by the last AWS account, the network is deleted also.
  ## 
  let valid = call_606368.validator(path, query, header, formData, body)
  let scheme = call_606368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606368.url(scheme.get, call_606368.host, call_606368.base,
                         call_606368.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606368, url, valid)

proc call*(call_606369: Call_DeleteMember_606356; memberId: string; networkId: string): Recallable =
  ## deleteMember
  ## Deletes a member. Deleting a member removes the member and all associated resources from the network. <code>DeleteMember</code> can only be called for a specified <code>MemberId</code> if the principal performing the action is associated with the AWS account that owns the member. In all other cases, the <code>DeleteMember</code> action is carried out as the result of an approved proposal to remove a member. If <code>MemberId</code> is the last member in a network specified by the last AWS account, the network is deleted also.
  ##   memberId: string (required)
  ##           : The unique identifier of the member to remove.
  ##   networkId: string (required)
  ##            : The unique identifier of the network from which the member is removed.
  var path_606370 = newJObject()
  add(path_606370, "memberId", newJString(memberId))
  add(path_606370, "networkId", newJString(networkId))
  result = call_606369.call(path_606370, nil, nil, nil, nil)

var deleteMember* = Call_DeleteMember_606356(name: "deleteMember",
    meth: HttpMethod.HttpDelete, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/members/{memberId}",
    validator: validate_DeleteMember_606357, base: "/", url: url_DeleteMember_606358,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNode_606371 = ref object of OpenApiRestCall_605589
proc url_GetNode_606373(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "networkId" in path, "`networkId` is a required path parameter"
  assert "memberId" in path, "`memberId` is a required path parameter"
  assert "nodeId" in path, "`nodeId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/networks/"),
               (kind: VariableSegment, value: "networkId"),
               (kind: ConstantSegment, value: "/members/"),
               (kind: VariableSegment, value: "memberId"),
               (kind: ConstantSegment, value: "/nodes/"),
               (kind: VariableSegment, value: "nodeId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetNode_606372(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns detailed information about a peer node.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   memberId: JString (required)
  ##           : The unique identifier of the member that owns the node.
  ##   networkId: JString (required)
  ##            : The unique identifier of the network to which the node belongs.
  ##   nodeId: JString (required)
  ##         : The unique identifier of the node.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `memberId` field"
  var valid_606374 = path.getOrDefault("memberId")
  valid_606374 = validateParameter(valid_606374, JString, required = true,
                                 default = nil)
  if valid_606374 != nil:
    section.add "memberId", valid_606374
  var valid_606375 = path.getOrDefault("networkId")
  valid_606375 = validateParameter(valid_606375, JString, required = true,
                                 default = nil)
  if valid_606375 != nil:
    section.add "networkId", valid_606375
  var valid_606376 = path.getOrDefault("nodeId")
  valid_606376 = validateParameter(valid_606376, JString, required = true,
                                 default = nil)
  if valid_606376 != nil:
    section.add "nodeId", valid_606376
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606377 = header.getOrDefault("X-Amz-Signature")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "X-Amz-Signature", valid_606377
  var valid_606378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "X-Amz-Content-Sha256", valid_606378
  var valid_606379 = header.getOrDefault("X-Amz-Date")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "X-Amz-Date", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Credential")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Credential", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-Security-Token")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Security-Token", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Algorithm")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Algorithm", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-SignedHeaders", valid_606383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606384: Call_GetNode_606371; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a peer node.
  ## 
  let valid = call_606384.validator(path, query, header, formData, body)
  let scheme = call_606384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606384.url(scheme.get, call_606384.host, call_606384.base,
                         call_606384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606384, url, valid)

proc call*(call_606385: Call_GetNode_606371; memberId: string; networkId: string;
          nodeId: string): Recallable =
  ## getNode
  ## Returns detailed information about a peer node.
  ##   memberId: string (required)
  ##           : The unique identifier of the member that owns the node.
  ##   networkId: string (required)
  ##            : The unique identifier of the network to which the node belongs.
  ##   nodeId: string (required)
  ##         : The unique identifier of the node.
  var path_606386 = newJObject()
  add(path_606386, "memberId", newJString(memberId))
  add(path_606386, "networkId", newJString(networkId))
  add(path_606386, "nodeId", newJString(nodeId))
  result = call_606385.call(path_606386, nil, nil, nil, nil)

var getNode* = Call_GetNode_606371(name: "getNode", meth: HttpMethod.HttpGet,
                                host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes/{nodeId}",
                                validator: validate_GetNode_606372, base: "/",
                                url: url_GetNode_606373,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNode_606387 = ref object of OpenApiRestCall_605589
proc url_DeleteNode_606389(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "networkId" in path, "`networkId` is a required path parameter"
  assert "memberId" in path, "`memberId` is a required path parameter"
  assert "nodeId" in path, "`nodeId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/networks/"),
               (kind: VariableSegment, value: "networkId"),
               (kind: ConstantSegment, value: "/members/"),
               (kind: VariableSegment, value: "memberId"),
               (kind: ConstantSegment, value: "/nodes/"),
               (kind: VariableSegment, value: "nodeId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteNode_606388(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a peer node from a member that your AWS account owns. All data on the node is lost and cannot be recovered.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   memberId: JString (required)
  ##           : The unique identifier of the member that owns this node.
  ##   networkId: JString (required)
  ##            : The unique identifier of the network that the node belongs to.
  ##   nodeId: JString (required)
  ##         : The unique identifier of the node.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `memberId` field"
  var valid_606390 = path.getOrDefault("memberId")
  valid_606390 = validateParameter(valid_606390, JString, required = true,
                                 default = nil)
  if valid_606390 != nil:
    section.add "memberId", valid_606390
  var valid_606391 = path.getOrDefault("networkId")
  valid_606391 = validateParameter(valid_606391, JString, required = true,
                                 default = nil)
  if valid_606391 != nil:
    section.add "networkId", valid_606391
  var valid_606392 = path.getOrDefault("nodeId")
  valid_606392 = validateParameter(valid_606392, JString, required = true,
                                 default = nil)
  if valid_606392 != nil:
    section.add "nodeId", valid_606392
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606393 = header.getOrDefault("X-Amz-Signature")
  valid_606393 = validateParameter(valid_606393, JString, required = false,
                                 default = nil)
  if valid_606393 != nil:
    section.add "X-Amz-Signature", valid_606393
  var valid_606394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606394 = validateParameter(valid_606394, JString, required = false,
                                 default = nil)
  if valid_606394 != nil:
    section.add "X-Amz-Content-Sha256", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-Date")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-Date", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-Credential")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-Credential", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-Security-Token")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Security-Token", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Algorithm")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Algorithm", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-SignedHeaders", valid_606399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606400: Call_DeleteNode_606387; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a peer node from a member that your AWS account owns. All data on the node is lost and cannot be recovered.
  ## 
  let valid = call_606400.validator(path, query, header, formData, body)
  let scheme = call_606400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606400.url(scheme.get, call_606400.host, call_606400.base,
                         call_606400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606400, url, valid)

proc call*(call_606401: Call_DeleteNode_606387; memberId: string; networkId: string;
          nodeId: string): Recallable =
  ## deleteNode
  ## Deletes a peer node from a member that your AWS account owns. All data on the node is lost and cannot be recovered.
  ##   memberId: string (required)
  ##           : The unique identifier of the member that owns this node.
  ##   networkId: string (required)
  ##            : The unique identifier of the network that the node belongs to.
  ##   nodeId: string (required)
  ##         : The unique identifier of the node.
  var path_606402 = newJObject()
  add(path_606402, "memberId", newJString(memberId))
  add(path_606402, "networkId", newJString(networkId))
  add(path_606402, "nodeId", newJString(nodeId))
  result = call_606401.call(path_606402, nil, nil, nil, nil)

var deleteNode* = Call_DeleteNode_606387(name: "deleteNode",
                                      meth: HttpMethod.HttpDelete,
                                      host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes/{nodeId}",
                                      validator: validate_DeleteNode_606388,
                                      base: "/", url: url_DeleteNode_606389,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNetwork_606403 = ref object of OpenApiRestCall_605589
proc url_GetNetwork_606405(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "networkId" in path, "`networkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/networks/"),
               (kind: VariableSegment, value: "networkId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetNetwork_606404(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns detailed information about a network.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   networkId: JString (required)
  ##            : The unique identifier of the network to get information about.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `networkId` field"
  var valid_606406 = path.getOrDefault("networkId")
  valid_606406 = validateParameter(valid_606406, JString, required = true,
                                 default = nil)
  if valid_606406 != nil:
    section.add "networkId", valid_606406
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606407 = header.getOrDefault("X-Amz-Signature")
  valid_606407 = validateParameter(valid_606407, JString, required = false,
                                 default = nil)
  if valid_606407 != nil:
    section.add "X-Amz-Signature", valid_606407
  var valid_606408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606408 = validateParameter(valid_606408, JString, required = false,
                                 default = nil)
  if valid_606408 != nil:
    section.add "X-Amz-Content-Sha256", valid_606408
  var valid_606409 = header.getOrDefault("X-Amz-Date")
  valid_606409 = validateParameter(valid_606409, JString, required = false,
                                 default = nil)
  if valid_606409 != nil:
    section.add "X-Amz-Date", valid_606409
  var valid_606410 = header.getOrDefault("X-Amz-Credential")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-Credential", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-Security-Token")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-Security-Token", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-Algorithm")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Algorithm", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-SignedHeaders", valid_606413
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606414: Call_GetNetwork_606403; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a network.
  ## 
  let valid = call_606414.validator(path, query, header, formData, body)
  let scheme = call_606414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606414.url(scheme.get, call_606414.host, call_606414.base,
                         call_606414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606414, url, valid)

proc call*(call_606415: Call_GetNetwork_606403; networkId: string): Recallable =
  ## getNetwork
  ## Returns detailed information about a network.
  ##   networkId: string (required)
  ##            : The unique identifier of the network to get information about.
  var path_606416 = newJObject()
  add(path_606416, "networkId", newJString(networkId))
  result = call_606415.call(path_606416, nil, nil, nil, nil)

var getNetwork* = Call_GetNetwork_606403(name: "getNetwork",
                                      meth: HttpMethod.HttpGet,
                                      host: "managedblockchain.amazonaws.com",
                                      route: "/networks/{networkId}",
                                      validator: validate_GetNetwork_606404,
                                      base: "/", url: url_GetNetwork_606405,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProposal_606417 = ref object of OpenApiRestCall_605589
proc url_GetProposal_606419(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "networkId" in path, "`networkId` is a required path parameter"
  assert "proposalId" in path, "`proposalId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/networks/"),
               (kind: VariableSegment, value: "networkId"),
               (kind: ConstantSegment, value: "/proposals/"),
               (kind: VariableSegment, value: "proposalId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetProposal_606418(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns detailed information about a proposal.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   proposalId: JString (required)
  ##             : The unique identifier of the proposal.
  ##   networkId: JString (required)
  ##            : The unique identifier of the network for which the proposal is made.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `proposalId` field"
  var valid_606420 = path.getOrDefault("proposalId")
  valid_606420 = validateParameter(valid_606420, JString, required = true,
                                 default = nil)
  if valid_606420 != nil:
    section.add "proposalId", valid_606420
  var valid_606421 = path.getOrDefault("networkId")
  valid_606421 = validateParameter(valid_606421, JString, required = true,
                                 default = nil)
  if valid_606421 != nil:
    section.add "networkId", valid_606421
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606422 = header.getOrDefault("X-Amz-Signature")
  valid_606422 = validateParameter(valid_606422, JString, required = false,
                                 default = nil)
  if valid_606422 != nil:
    section.add "X-Amz-Signature", valid_606422
  var valid_606423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606423 = validateParameter(valid_606423, JString, required = false,
                                 default = nil)
  if valid_606423 != nil:
    section.add "X-Amz-Content-Sha256", valid_606423
  var valid_606424 = header.getOrDefault("X-Amz-Date")
  valid_606424 = validateParameter(valid_606424, JString, required = false,
                                 default = nil)
  if valid_606424 != nil:
    section.add "X-Amz-Date", valid_606424
  var valid_606425 = header.getOrDefault("X-Amz-Credential")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-Credential", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-Security-Token")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-Security-Token", valid_606426
  var valid_606427 = header.getOrDefault("X-Amz-Algorithm")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-Algorithm", valid_606427
  var valid_606428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "X-Amz-SignedHeaders", valid_606428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606429: Call_GetProposal_606417; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a proposal.
  ## 
  let valid = call_606429.validator(path, query, header, formData, body)
  let scheme = call_606429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606429.url(scheme.get, call_606429.host, call_606429.base,
                         call_606429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606429, url, valid)

proc call*(call_606430: Call_GetProposal_606417; proposalId: string;
          networkId: string): Recallable =
  ## getProposal
  ## Returns detailed information about a proposal.
  ##   proposalId: string (required)
  ##             : The unique identifier of the proposal.
  ##   networkId: string (required)
  ##            : The unique identifier of the network for which the proposal is made.
  var path_606431 = newJObject()
  add(path_606431, "proposalId", newJString(proposalId))
  add(path_606431, "networkId", newJString(networkId))
  result = call_606430.call(path_606431, nil, nil, nil, nil)

var getProposal* = Call_GetProposal_606417(name: "getProposal",
                                        meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/proposals/{proposalId}",
                                        validator: validate_GetProposal_606418,
                                        base: "/", url: url_GetProposal_606419,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_606432 = ref object of OpenApiRestCall_605589
proc url_ListInvitations_606434(protocol: Scheme; host: string; base: string;
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

proc validate_ListInvitations_606433(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns a listing of all invitations made on the specified network.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The pagination token that indicates the next set of results to retrieve.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of invitations to return.
  section = newJObject()
  var valid_606435 = query.getOrDefault("nextToken")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "nextToken", valid_606435
  var valid_606436 = query.getOrDefault("MaxResults")
  valid_606436 = validateParameter(valid_606436, JString, required = false,
                                 default = nil)
  if valid_606436 != nil:
    section.add "MaxResults", valid_606436
  var valid_606437 = query.getOrDefault("NextToken")
  valid_606437 = validateParameter(valid_606437, JString, required = false,
                                 default = nil)
  if valid_606437 != nil:
    section.add "NextToken", valid_606437
  var valid_606438 = query.getOrDefault("maxResults")
  valid_606438 = validateParameter(valid_606438, JInt, required = false, default = nil)
  if valid_606438 != nil:
    section.add "maxResults", valid_606438
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606439 = header.getOrDefault("X-Amz-Signature")
  valid_606439 = validateParameter(valid_606439, JString, required = false,
                                 default = nil)
  if valid_606439 != nil:
    section.add "X-Amz-Signature", valid_606439
  var valid_606440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-Content-Sha256", valid_606440
  var valid_606441 = header.getOrDefault("X-Amz-Date")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "X-Amz-Date", valid_606441
  var valid_606442 = header.getOrDefault("X-Amz-Credential")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "X-Amz-Credential", valid_606442
  var valid_606443 = header.getOrDefault("X-Amz-Security-Token")
  valid_606443 = validateParameter(valid_606443, JString, required = false,
                                 default = nil)
  if valid_606443 != nil:
    section.add "X-Amz-Security-Token", valid_606443
  var valid_606444 = header.getOrDefault("X-Amz-Algorithm")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-Algorithm", valid_606444
  var valid_606445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-SignedHeaders", valid_606445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606446: Call_ListInvitations_606432; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a listing of all invitations made on the specified network.
  ## 
  let valid = call_606446.validator(path, query, header, formData, body)
  let scheme = call_606446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606446.url(scheme.get, call_606446.host, call_606446.base,
                         call_606446.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606446, url, valid)

proc call*(call_606447: Call_ListInvitations_606432; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listInvitations
  ## Returns a listing of all invitations made on the specified network.
  ##   nextToken: string
  ##            : The pagination token that indicates the next set of results to retrieve.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of invitations to return.
  var query_606448 = newJObject()
  add(query_606448, "nextToken", newJString(nextToken))
  add(query_606448, "MaxResults", newJString(MaxResults))
  add(query_606448, "NextToken", newJString(NextToken))
  add(query_606448, "maxResults", newJInt(maxResults))
  result = call_606447.call(nil, query_606448, nil, nil, nil)

var listInvitations* = Call_ListInvitations_606432(name: "listInvitations",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/invitations", validator: validate_ListInvitations_606433, base: "/",
    url: url_ListInvitations_606434, schemes: {Scheme.Https, Scheme.Http})
type
  Call_VoteOnProposal_606469 = ref object of OpenApiRestCall_605589
proc url_VoteOnProposal_606471(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "networkId" in path, "`networkId` is a required path parameter"
  assert "proposalId" in path, "`proposalId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/networks/"),
               (kind: VariableSegment, value: "networkId"),
               (kind: ConstantSegment, value: "/proposals/"),
               (kind: VariableSegment, value: "proposalId"),
               (kind: ConstantSegment, value: "/votes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_VoteOnProposal_606470(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Casts a vote for a specified <code>ProposalId</code> on behalf of a member. The member to vote as, specified by <code>VoterMemberId</code>, must be in the same AWS account as the principal that calls the action.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   proposalId: JString (required)
  ##             :  The unique identifier of the proposal. 
  ##   networkId: JString (required)
  ##            :  The unique identifier of the network. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `proposalId` field"
  var valid_606472 = path.getOrDefault("proposalId")
  valid_606472 = validateParameter(valid_606472, JString, required = true,
                                 default = nil)
  if valid_606472 != nil:
    section.add "proposalId", valid_606472
  var valid_606473 = path.getOrDefault("networkId")
  valid_606473 = validateParameter(valid_606473, JString, required = true,
                                 default = nil)
  if valid_606473 != nil:
    section.add "networkId", valid_606473
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606474 = header.getOrDefault("X-Amz-Signature")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "X-Amz-Signature", valid_606474
  var valid_606475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606475 = validateParameter(valid_606475, JString, required = false,
                                 default = nil)
  if valid_606475 != nil:
    section.add "X-Amz-Content-Sha256", valid_606475
  var valid_606476 = header.getOrDefault("X-Amz-Date")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "X-Amz-Date", valid_606476
  var valid_606477 = header.getOrDefault("X-Amz-Credential")
  valid_606477 = validateParameter(valid_606477, JString, required = false,
                                 default = nil)
  if valid_606477 != nil:
    section.add "X-Amz-Credential", valid_606477
  var valid_606478 = header.getOrDefault("X-Amz-Security-Token")
  valid_606478 = validateParameter(valid_606478, JString, required = false,
                                 default = nil)
  if valid_606478 != nil:
    section.add "X-Amz-Security-Token", valid_606478
  var valid_606479 = header.getOrDefault("X-Amz-Algorithm")
  valid_606479 = validateParameter(valid_606479, JString, required = false,
                                 default = nil)
  if valid_606479 != nil:
    section.add "X-Amz-Algorithm", valid_606479
  var valid_606480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606480 = validateParameter(valid_606480, JString, required = false,
                                 default = nil)
  if valid_606480 != nil:
    section.add "X-Amz-SignedHeaders", valid_606480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606482: Call_VoteOnProposal_606469; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Casts a vote for a specified <code>ProposalId</code> on behalf of a member. The member to vote as, specified by <code>VoterMemberId</code>, must be in the same AWS account as the principal that calls the action.
  ## 
  let valid = call_606482.validator(path, query, header, formData, body)
  let scheme = call_606482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606482.url(scheme.get, call_606482.host, call_606482.base,
                         call_606482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606482, url, valid)

proc call*(call_606483: Call_VoteOnProposal_606469; proposalId: string;
          networkId: string; body: JsonNode): Recallable =
  ## voteOnProposal
  ## Casts a vote for a specified <code>ProposalId</code> on behalf of a member. The member to vote as, specified by <code>VoterMemberId</code>, must be in the same AWS account as the principal that calls the action.
  ##   proposalId: string (required)
  ##             :  The unique identifier of the proposal. 
  ##   networkId: string (required)
  ##            :  The unique identifier of the network. 
  ##   body: JObject (required)
  var path_606484 = newJObject()
  var body_606485 = newJObject()
  add(path_606484, "proposalId", newJString(proposalId))
  add(path_606484, "networkId", newJString(networkId))
  if body != nil:
    body_606485 = body
  result = call_606483.call(path_606484, nil, nil, nil, body_606485)

var voteOnProposal* = Call_VoteOnProposal_606469(name: "voteOnProposal",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals/{proposalId}/votes",
    validator: validate_VoteOnProposal_606470, base: "/", url: url_VoteOnProposal_606471,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProposalVotes_606449 = ref object of OpenApiRestCall_605589
proc url_ListProposalVotes_606451(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "networkId" in path, "`networkId` is a required path parameter"
  assert "proposalId" in path, "`proposalId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/networks/"),
               (kind: VariableSegment, value: "networkId"),
               (kind: ConstantSegment, value: "/proposals/"),
               (kind: VariableSegment, value: "proposalId"),
               (kind: ConstantSegment, value: "/votes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListProposalVotes_606450(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns the listing of votes for a specified proposal, including the value of each vote and the unique identifier of the member that cast the vote.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   proposalId: JString (required)
  ##             :  The unique identifier of the proposal. 
  ##   networkId: JString (required)
  ##            :  The unique identifier of the network. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `proposalId` field"
  var valid_606452 = path.getOrDefault("proposalId")
  valid_606452 = validateParameter(valid_606452, JString, required = true,
                                 default = nil)
  if valid_606452 != nil:
    section.add "proposalId", valid_606452
  var valid_606453 = path.getOrDefault("networkId")
  valid_606453 = validateParameter(valid_606453, JString, required = true,
                                 default = nil)
  if valid_606453 != nil:
    section.add "networkId", valid_606453
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  The pagination token that indicates the next set of results to retrieve. 
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             :  The maximum number of votes to return. 
  section = newJObject()
  var valid_606454 = query.getOrDefault("nextToken")
  valid_606454 = validateParameter(valid_606454, JString, required = false,
                                 default = nil)
  if valid_606454 != nil:
    section.add "nextToken", valid_606454
  var valid_606455 = query.getOrDefault("MaxResults")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "MaxResults", valid_606455
  var valid_606456 = query.getOrDefault("NextToken")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "NextToken", valid_606456
  var valid_606457 = query.getOrDefault("maxResults")
  valid_606457 = validateParameter(valid_606457, JInt, required = false, default = nil)
  if valid_606457 != nil:
    section.add "maxResults", valid_606457
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606458 = header.getOrDefault("X-Amz-Signature")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-Signature", valid_606458
  var valid_606459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-Content-Sha256", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-Date")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-Date", valid_606460
  var valid_606461 = header.getOrDefault("X-Amz-Credential")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-Credential", valid_606461
  var valid_606462 = header.getOrDefault("X-Amz-Security-Token")
  valid_606462 = validateParameter(valid_606462, JString, required = false,
                                 default = nil)
  if valid_606462 != nil:
    section.add "X-Amz-Security-Token", valid_606462
  var valid_606463 = header.getOrDefault("X-Amz-Algorithm")
  valid_606463 = validateParameter(valid_606463, JString, required = false,
                                 default = nil)
  if valid_606463 != nil:
    section.add "X-Amz-Algorithm", valid_606463
  var valid_606464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606464 = validateParameter(valid_606464, JString, required = false,
                                 default = nil)
  if valid_606464 != nil:
    section.add "X-Amz-SignedHeaders", valid_606464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606465: Call_ListProposalVotes_606449; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the listing of votes for a specified proposal, including the value of each vote and the unique identifier of the member that cast the vote.
  ## 
  let valid = call_606465.validator(path, query, header, formData, body)
  let scheme = call_606465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606465.url(scheme.get, call_606465.host, call_606465.base,
                         call_606465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606465, url, valid)

proc call*(call_606466: Call_ListProposalVotes_606449; proposalId: string;
          networkId: string; nextToken: string = ""; MaxResults: string = "";
          NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listProposalVotes
  ## Returns the listing of votes for a specified proposal, including the value of each vote and the unique identifier of the member that cast the vote.
  ##   nextToken: string
  ##            :  The pagination token that indicates the next set of results to retrieve. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   proposalId: string (required)
  ##             :  The unique identifier of the proposal. 
  ##   NextToken: string
  ##            : Pagination token
  ##   networkId: string (required)
  ##            :  The unique identifier of the network. 
  ##   maxResults: int
  ##             :  The maximum number of votes to return. 
  var path_606467 = newJObject()
  var query_606468 = newJObject()
  add(query_606468, "nextToken", newJString(nextToken))
  add(query_606468, "MaxResults", newJString(MaxResults))
  add(path_606467, "proposalId", newJString(proposalId))
  add(query_606468, "NextToken", newJString(NextToken))
  add(path_606467, "networkId", newJString(networkId))
  add(query_606468, "maxResults", newJInt(maxResults))
  result = call_606466.call(path_606467, query_606468, nil, nil, nil)

var listProposalVotes* = Call_ListProposalVotes_606449(name: "listProposalVotes",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals/{proposalId}/votes",
    validator: validate_ListProposalVotes_606450, base: "/",
    url: url_ListProposalVotes_606451, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectInvitation_606486 = ref object of OpenApiRestCall_605589
proc url_RejectInvitation_606488(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "invitationId" in path, "`invitationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/invitations/"),
               (kind: VariableSegment, value: "invitationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RejectInvitation_606487(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Rejects an invitation to join a network. This action can be called by a principal in an AWS account that has received an invitation to create a member and join a network.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   invitationId: JString (required)
  ##               : The unique identifier of the invitation to reject.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `invitationId` field"
  var valid_606489 = path.getOrDefault("invitationId")
  valid_606489 = validateParameter(valid_606489, JString, required = true,
                                 default = nil)
  if valid_606489 != nil:
    section.add "invitationId", valid_606489
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606490 = header.getOrDefault("X-Amz-Signature")
  valid_606490 = validateParameter(valid_606490, JString, required = false,
                                 default = nil)
  if valid_606490 != nil:
    section.add "X-Amz-Signature", valid_606490
  var valid_606491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606491 = validateParameter(valid_606491, JString, required = false,
                                 default = nil)
  if valid_606491 != nil:
    section.add "X-Amz-Content-Sha256", valid_606491
  var valid_606492 = header.getOrDefault("X-Amz-Date")
  valid_606492 = validateParameter(valid_606492, JString, required = false,
                                 default = nil)
  if valid_606492 != nil:
    section.add "X-Amz-Date", valid_606492
  var valid_606493 = header.getOrDefault("X-Amz-Credential")
  valid_606493 = validateParameter(valid_606493, JString, required = false,
                                 default = nil)
  if valid_606493 != nil:
    section.add "X-Amz-Credential", valid_606493
  var valid_606494 = header.getOrDefault("X-Amz-Security-Token")
  valid_606494 = validateParameter(valid_606494, JString, required = false,
                                 default = nil)
  if valid_606494 != nil:
    section.add "X-Amz-Security-Token", valid_606494
  var valid_606495 = header.getOrDefault("X-Amz-Algorithm")
  valid_606495 = validateParameter(valid_606495, JString, required = false,
                                 default = nil)
  if valid_606495 != nil:
    section.add "X-Amz-Algorithm", valid_606495
  var valid_606496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606496 = validateParameter(valid_606496, JString, required = false,
                                 default = nil)
  if valid_606496 != nil:
    section.add "X-Amz-SignedHeaders", valid_606496
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606497: Call_RejectInvitation_606486; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Rejects an invitation to join a network. This action can be called by a principal in an AWS account that has received an invitation to create a member and join a network.
  ## 
  let valid = call_606497.validator(path, query, header, formData, body)
  let scheme = call_606497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606497.url(scheme.get, call_606497.host, call_606497.base,
                         call_606497.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606497, url, valid)

proc call*(call_606498: Call_RejectInvitation_606486; invitationId: string): Recallable =
  ## rejectInvitation
  ## Rejects an invitation to join a network. This action can be called by a principal in an AWS account that has received an invitation to create a member and join a network.
  ##   invitationId: string (required)
  ##               : The unique identifier of the invitation to reject.
  var path_606499 = newJObject()
  add(path_606499, "invitationId", newJString(invitationId))
  result = call_606498.call(path_606499, nil, nil, nil, nil)

var rejectInvitation* = Call_RejectInvitation_606486(name: "rejectInvitation",
    meth: HttpMethod.HttpDelete, host: "managedblockchain.amazonaws.com",
    route: "/invitations/{invitationId}", validator: validate_RejectInvitation_606487,
    base: "/", url: url_RejectInvitation_606488,
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
