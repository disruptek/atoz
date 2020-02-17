
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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
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
  Call_CreateMember_611287 = ref object of OpenApiRestCall_610658
proc url_CreateMember_611289(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateMember_611288(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611290 = path.getOrDefault("networkId")
  valid_611290 = validateParameter(valid_611290, JString, required = true,
                                 default = nil)
  if valid_611290 != nil:
    section.add "networkId", valid_611290
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
  var valid_611291 = header.getOrDefault("X-Amz-Signature")
  valid_611291 = validateParameter(valid_611291, JString, required = false,
                                 default = nil)
  if valid_611291 != nil:
    section.add "X-Amz-Signature", valid_611291
  var valid_611292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611292 = validateParameter(valid_611292, JString, required = false,
                                 default = nil)
  if valid_611292 != nil:
    section.add "X-Amz-Content-Sha256", valid_611292
  var valid_611293 = header.getOrDefault("X-Amz-Date")
  valid_611293 = validateParameter(valid_611293, JString, required = false,
                                 default = nil)
  if valid_611293 != nil:
    section.add "X-Amz-Date", valid_611293
  var valid_611294 = header.getOrDefault("X-Amz-Credential")
  valid_611294 = validateParameter(valid_611294, JString, required = false,
                                 default = nil)
  if valid_611294 != nil:
    section.add "X-Amz-Credential", valid_611294
  var valid_611295 = header.getOrDefault("X-Amz-Security-Token")
  valid_611295 = validateParameter(valid_611295, JString, required = false,
                                 default = nil)
  if valid_611295 != nil:
    section.add "X-Amz-Security-Token", valid_611295
  var valid_611296 = header.getOrDefault("X-Amz-Algorithm")
  valid_611296 = validateParameter(valid_611296, JString, required = false,
                                 default = nil)
  if valid_611296 != nil:
    section.add "X-Amz-Algorithm", valid_611296
  var valid_611297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611297 = validateParameter(valid_611297, JString, required = false,
                                 default = nil)
  if valid_611297 != nil:
    section.add "X-Amz-SignedHeaders", valid_611297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611299: Call_CreateMember_611287; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a member within a Managed Blockchain network.
  ## 
  let valid = call_611299.validator(path, query, header, formData, body)
  let scheme = call_611299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611299.url(scheme.get, call_611299.host, call_611299.base,
                         call_611299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611299, url, valid)

proc call*(call_611300: Call_CreateMember_611287; networkId: string; body: JsonNode): Recallable =
  ## createMember
  ## Creates a member within a Managed Blockchain network.
  ##   networkId: string (required)
  ##            : The unique identifier of the network in which the member is created.
  ##   body: JObject (required)
  var path_611301 = newJObject()
  var body_611302 = newJObject()
  add(path_611301, "networkId", newJString(networkId))
  if body != nil:
    body_611302 = body
  result = call_611300.call(path_611301, nil, nil, nil, body_611302)

var createMember* = Call_CreateMember_611287(name: "createMember",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/members", validator: validate_CreateMember_611288,
    base: "/", url: url_CreateMember_611289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_610996 = ref object of OpenApiRestCall_610658
proc url_ListMembers_610998(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListMembers_610997(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611124 = path.getOrDefault("networkId")
  valid_611124 = validateParameter(valid_611124, JString, required = true,
                                 default = nil)
  if valid_611124 != nil:
    section.add "networkId", valid_611124
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
  var valid_611125 = query.getOrDefault("name")
  valid_611125 = validateParameter(valid_611125, JString, required = false,
                                 default = nil)
  if valid_611125 != nil:
    section.add "name", valid_611125
  var valid_611126 = query.getOrDefault("nextToken")
  valid_611126 = validateParameter(valid_611126, JString, required = false,
                                 default = nil)
  if valid_611126 != nil:
    section.add "nextToken", valid_611126
  var valid_611127 = query.getOrDefault("MaxResults")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "MaxResults", valid_611127
  var valid_611128 = query.getOrDefault("NextToken")
  valid_611128 = validateParameter(valid_611128, JString, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "NextToken", valid_611128
  var valid_611129 = query.getOrDefault("isOwned")
  valid_611129 = validateParameter(valid_611129, JBool, required = false, default = nil)
  if valid_611129 != nil:
    section.add "isOwned", valid_611129
  var valid_611143 = query.getOrDefault("status")
  valid_611143 = validateParameter(valid_611143, JString, required = false,
                                 default = newJString("CREATING"))
  if valid_611143 != nil:
    section.add "status", valid_611143
  var valid_611144 = query.getOrDefault("maxResults")
  valid_611144 = validateParameter(valid_611144, JInt, required = false, default = nil)
  if valid_611144 != nil:
    section.add "maxResults", valid_611144
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
  var valid_611145 = header.getOrDefault("X-Amz-Signature")
  valid_611145 = validateParameter(valid_611145, JString, required = false,
                                 default = nil)
  if valid_611145 != nil:
    section.add "X-Amz-Signature", valid_611145
  var valid_611146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611146 = validateParameter(valid_611146, JString, required = false,
                                 default = nil)
  if valid_611146 != nil:
    section.add "X-Amz-Content-Sha256", valid_611146
  var valid_611147 = header.getOrDefault("X-Amz-Date")
  valid_611147 = validateParameter(valid_611147, JString, required = false,
                                 default = nil)
  if valid_611147 != nil:
    section.add "X-Amz-Date", valid_611147
  var valid_611148 = header.getOrDefault("X-Amz-Credential")
  valid_611148 = validateParameter(valid_611148, JString, required = false,
                                 default = nil)
  if valid_611148 != nil:
    section.add "X-Amz-Credential", valid_611148
  var valid_611149 = header.getOrDefault("X-Amz-Security-Token")
  valid_611149 = validateParameter(valid_611149, JString, required = false,
                                 default = nil)
  if valid_611149 != nil:
    section.add "X-Amz-Security-Token", valid_611149
  var valid_611150 = header.getOrDefault("X-Amz-Algorithm")
  valid_611150 = validateParameter(valid_611150, JString, required = false,
                                 default = nil)
  if valid_611150 != nil:
    section.add "X-Amz-Algorithm", valid_611150
  var valid_611151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611151 = validateParameter(valid_611151, JString, required = false,
                                 default = nil)
  if valid_611151 != nil:
    section.add "X-Amz-SignedHeaders", valid_611151
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611174: Call_ListMembers_610996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a listing of the members in a network and properties of their configurations.
  ## 
  let valid = call_611174.validator(path, query, header, formData, body)
  let scheme = call_611174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611174.url(scheme.get, call_611174.host, call_611174.base,
                         call_611174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611174, url, valid)

proc call*(call_611245: Call_ListMembers_610996; networkId: string;
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
  var path_611246 = newJObject()
  var query_611248 = newJObject()
  add(query_611248, "name", newJString(name))
  add(query_611248, "nextToken", newJString(nextToken))
  add(query_611248, "MaxResults", newJString(MaxResults))
  add(query_611248, "NextToken", newJString(NextToken))
  add(path_611246, "networkId", newJString(networkId))
  add(query_611248, "isOwned", newJBool(isOwned))
  add(query_611248, "status", newJString(status))
  add(query_611248, "maxResults", newJInt(maxResults))
  result = call_611245.call(path_611246, query_611248, nil, nil, nil)

var listMembers* = Call_ListMembers_610996(name: "listMembers",
                                        meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
                                        route: "/networks/{networkId}/members",
                                        validator: validate_ListMembers_610997,
                                        base: "/", url: url_ListMembers_610998,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNetwork_611323 = ref object of OpenApiRestCall_610658
proc url_CreateNetwork_611325(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateNetwork_611324(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611326 = header.getOrDefault("X-Amz-Signature")
  valid_611326 = validateParameter(valid_611326, JString, required = false,
                                 default = nil)
  if valid_611326 != nil:
    section.add "X-Amz-Signature", valid_611326
  var valid_611327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611327 = validateParameter(valid_611327, JString, required = false,
                                 default = nil)
  if valid_611327 != nil:
    section.add "X-Amz-Content-Sha256", valid_611327
  var valid_611328 = header.getOrDefault("X-Amz-Date")
  valid_611328 = validateParameter(valid_611328, JString, required = false,
                                 default = nil)
  if valid_611328 != nil:
    section.add "X-Amz-Date", valid_611328
  var valid_611329 = header.getOrDefault("X-Amz-Credential")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "X-Amz-Credential", valid_611329
  var valid_611330 = header.getOrDefault("X-Amz-Security-Token")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "X-Amz-Security-Token", valid_611330
  var valid_611331 = header.getOrDefault("X-Amz-Algorithm")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "X-Amz-Algorithm", valid_611331
  var valid_611332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "X-Amz-SignedHeaders", valid_611332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611334: Call_CreateNetwork_611323; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new blockchain network using Amazon Managed Blockchain.
  ## 
  let valid = call_611334.validator(path, query, header, formData, body)
  let scheme = call_611334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611334.url(scheme.get, call_611334.host, call_611334.base,
                         call_611334.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611334, url, valid)

proc call*(call_611335: Call_CreateNetwork_611323; body: JsonNode): Recallable =
  ## createNetwork
  ## Creates a new blockchain network using Amazon Managed Blockchain.
  ##   body: JObject (required)
  var body_611336 = newJObject()
  if body != nil:
    body_611336 = body
  result = call_611335.call(nil, nil, nil, nil, body_611336)

var createNetwork* = Call_CreateNetwork_611323(name: "createNetwork",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks", validator: validate_CreateNetwork_611324, base: "/",
    url: url_CreateNetwork_611325, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNetworks_611303 = ref object of OpenApiRestCall_610658
proc url_ListNetworks_611305(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListNetworks_611304(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611306 = query.getOrDefault("framework")
  valid_611306 = validateParameter(valid_611306, JString, required = false,
                                 default = newJString("HYPERLEDGER_FABRIC"))
  if valid_611306 != nil:
    section.add "framework", valid_611306
  var valid_611307 = query.getOrDefault("name")
  valid_611307 = validateParameter(valid_611307, JString, required = false,
                                 default = nil)
  if valid_611307 != nil:
    section.add "name", valid_611307
  var valid_611308 = query.getOrDefault("nextToken")
  valid_611308 = validateParameter(valid_611308, JString, required = false,
                                 default = nil)
  if valid_611308 != nil:
    section.add "nextToken", valid_611308
  var valid_611309 = query.getOrDefault("MaxResults")
  valid_611309 = validateParameter(valid_611309, JString, required = false,
                                 default = nil)
  if valid_611309 != nil:
    section.add "MaxResults", valid_611309
  var valid_611310 = query.getOrDefault("NextToken")
  valid_611310 = validateParameter(valid_611310, JString, required = false,
                                 default = nil)
  if valid_611310 != nil:
    section.add "NextToken", valid_611310
  var valid_611311 = query.getOrDefault("status")
  valid_611311 = validateParameter(valid_611311, JString, required = false,
                                 default = newJString("CREATING"))
  if valid_611311 != nil:
    section.add "status", valid_611311
  var valid_611312 = query.getOrDefault("maxResults")
  valid_611312 = validateParameter(valid_611312, JInt, required = false, default = nil)
  if valid_611312 != nil:
    section.add "maxResults", valid_611312
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
  var valid_611313 = header.getOrDefault("X-Amz-Signature")
  valid_611313 = validateParameter(valid_611313, JString, required = false,
                                 default = nil)
  if valid_611313 != nil:
    section.add "X-Amz-Signature", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-Content-Sha256", valid_611314
  var valid_611315 = header.getOrDefault("X-Amz-Date")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-Date", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-Credential")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-Credential", valid_611316
  var valid_611317 = header.getOrDefault("X-Amz-Security-Token")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Security-Token", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Algorithm")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Algorithm", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-SignedHeaders", valid_611319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611320: Call_ListNetworks_611303; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the networks in which the current AWS account has members.
  ## 
  let valid = call_611320.validator(path, query, header, formData, body)
  let scheme = call_611320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611320.url(scheme.get, call_611320.host, call_611320.base,
                         call_611320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611320, url, valid)

proc call*(call_611321: Call_ListNetworks_611303;
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
  var query_611322 = newJObject()
  add(query_611322, "framework", newJString(framework))
  add(query_611322, "name", newJString(name))
  add(query_611322, "nextToken", newJString(nextToken))
  add(query_611322, "MaxResults", newJString(MaxResults))
  add(query_611322, "NextToken", newJString(NextToken))
  add(query_611322, "status", newJString(status))
  add(query_611322, "maxResults", newJInt(maxResults))
  result = call_611321.call(nil, query_611322, nil, nil, nil)

var listNetworks* = Call_ListNetworks_611303(name: "listNetworks",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks", validator: validate_ListNetworks_611304, base: "/",
    url: url_ListNetworks_611305, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNode_611358 = ref object of OpenApiRestCall_610658
proc url_CreateNode_611360(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateNode_611359(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611361 = path.getOrDefault("memberId")
  valid_611361 = validateParameter(valid_611361, JString, required = true,
                                 default = nil)
  if valid_611361 != nil:
    section.add "memberId", valid_611361
  var valid_611362 = path.getOrDefault("networkId")
  valid_611362 = validateParameter(valid_611362, JString, required = true,
                                 default = nil)
  if valid_611362 != nil:
    section.add "networkId", valid_611362
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
  var valid_611363 = header.getOrDefault("X-Amz-Signature")
  valid_611363 = validateParameter(valid_611363, JString, required = false,
                                 default = nil)
  if valid_611363 != nil:
    section.add "X-Amz-Signature", valid_611363
  var valid_611364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611364 = validateParameter(valid_611364, JString, required = false,
                                 default = nil)
  if valid_611364 != nil:
    section.add "X-Amz-Content-Sha256", valid_611364
  var valid_611365 = header.getOrDefault("X-Amz-Date")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "X-Amz-Date", valid_611365
  var valid_611366 = header.getOrDefault("X-Amz-Credential")
  valid_611366 = validateParameter(valid_611366, JString, required = false,
                                 default = nil)
  if valid_611366 != nil:
    section.add "X-Amz-Credential", valid_611366
  var valid_611367 = header.getOrDefault("X-Amz-Security-Token")
  valid_611367 = validateParameter(valid_611367, JString, required = false,
                                 default = nil)
  if valid_611367 != nil:
    section.add "X-Amz-Security-Token", valid_611367
  var valid_611368 = header.getOrDefault("X-Amz-Algorithm")
  valid_611368 = validateParameter(valid_611368, JString, required = false,
                                 default = nil)
  if valid_611368 != nil:
    section.add "X-Amz-Algorithm", valid_611368
  var valid_611369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611369 = validateParameter(valid_611369, JString, required = false,
                                 default = nil)
  if valid_611369 != nil:
    section.add "X-Amz-SignedHeaders", valid_611369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611371: Call_CreateNode_611358; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a peer node in a member.
  ## 
  let valid = call_611371.validator(path, query, header, formData, body)
  let scheme = call_611371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611371.url(scheme.get, call_611371.host, call_611371.base,
                         call_611371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611371, url, valid)

proc call*(call_611372: Call_CreateNode_611358; memberId: string; networkId: string;
          body: JsonNode): Recallable =
  ## createNode
  ## Creates a peer node in a member.
  ##   memberId: string (required)
  ##           : The unique identifier of the member that owns this node.
  ##   networkId: string (required)
  ##            : The unique identifier of the network in which this node runs.
  ##   body: JObject (required)
  var path_611373 = newJObject()
  var body_611374 = newJObject()
  add(path_611373, "memberId", newJString(memberId))
  add(path_611373, "networkId", newJString(networkId))
  if body != nil:
    body_611374 = body
  result = call_611372.call(path_611373, nil, nil, nil, body_611374)

var createNode* = Call_CreateNode_611358(name: "createNode",
                                      meth: HttpMethod.HttpPost,
                                      host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes",
                                      validator: validate_CreateNode_611359,
                                      base: "/", url: url_CreateNode_611360,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNodes_611337 = ref object of OpenApiRestCall_610658
proc url_ListNodes_611339(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListNodes_611338(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611340 = path.getOrDefault("memberId")
  valid_611340 = validateParameter(valid_611340, JString, required = true,
                                 default = nil)
  if valid_611340 != nil:
    section.add "memberId", valid_611340
  var valid_611341 = path.getOrDefault("networkId")
  valid_611341 = validateParameter(valid_611341, JString, required = true,
                                 default = nil)
  if valid_611341 != nil:
    section.add "networkId", valid_611341
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
  var valid_611342 = query.getOrDefault("nextToken")
  valid_611342 = validateParameter(valid_611342, JString, required = false,
                                 default = nil)
  if valid_611342 != nil:
    section.add "nextToken", valid_611342
  var valid_611343 = query.getOrDefault("MaxResults")
  valid_611343 = validateParameter(valid_611343, JString, required = false,
                                 default = nil)
  if valid_611343 != nil:
    section.add "MaxResults", valid_611343
  var valid_611344 = query.getOrDefault("NextToken")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "NextToken", valid_611344
  var valid_611345 = query.getOrDefault("status")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = newJString("CREATING"))
  if valid_611345 != nil:
    section.add "status", valid_611345
  var valid_611346 = query.getOrDefault("maxResults")
  valid_611346 = validateParameter(valid_611346, JInt, required = false, default = nil)
  if valid_611346 != nil:
    section.add "maxResults", valid_611346
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
  var valid_611347 = header.getOrDefault("X-Amz-Signature")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "X-Amz-Signature", valid_611347
  var valid_611348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "X-Amz-Content-Sha256", valid_611348
  var valid_611349 = header.getOrDefault("X-Amz-Date")
  valid_611349 = validateParameter(valid_611349, JString, required = false,
                                 default = nil)
  if valid_611349 != nil:
    section.add "X-Amz-Date", valid_611349
  var valid_611350 = header.getOrDefault("X-Amz-Credential")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "X-Amz-Credential", valid_611350
  var valid_611351 = header.getOrDefault("X-Amz-Security-Token")
  valid_611351 = validateParameter(valid_611351, JString, required = false,
                                 default = nil)
  if valid_611351 != nil:
    section.add "X-Amz-Security-Token", valid_611351
  var valid_611352 = header.getOrDefault("X-Amz-Algorithm")
  valid_611352 = validateParameter(valid_611352, JString, required = false,
                                 default = nil)
  if valid_611352 != nil:
    section.add "X-Amz-Algorithm", valid_611352
  var valid_611353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "X-Amz-SignedHeaders", valid_611353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611354: Call_ListNodes_611337; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the nodes within a network.
  ## 
  let valid = call_611354.validator(path, query, header, formData, body)
  let scheme = call_611354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611354.url(scheme.get, call_611354.host, call_611354.base,
                         call_611354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611354, url, valid)

proc call*(call_611355: Call_ListNodes_611337; memberId: string; networkId: string;
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
  var path_611356 = newJObject()
  var query_611357 = newJObject()
  add(query_611357, "nextToken", newJString(nextToken))
  add(path_611356, "memberId", newJString(memberId))
  add(query_611357, "MaxResults", newJString(MaxResults))
  add(query_611357, "NextToken", newJString(NextToken))
  add(path_611356, "networkId", newJString(networkId))
  add(query_611357, "status", newJString(status))
  add(query_611357, "maxResults", newJInt(maxResults))
  result = call_611355.call(path_611356, query_611357, nil, nil, nil)

var listNodes* = Call_ListNodes_611337(name: "listNodes", meth: HttpMethod.HttpGet,
                                    host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes",
                                    validator: validate_ListNodes_611338,
                                    base: "/", url: url_ListNodes_611339,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProposal_611394 = ref object of OpenApiRestCall_610658
proc url_CreateProposal_611396(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateProposal_611395(path: JsonNode; query: JsonNode;
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
  var valid_611397 = path.getOrDefault("networkId")
  valid_611397 = validateParameter(valid_611397, JString, required = true,
                                 default = nil)
  if valid_611397 != nil:
    section.add "networkId", valid_611397
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
  var valid_611398 = header.getOrDefault("X-Amz-Signature")
  valid_611398 = validateParameter(valid_611398, JString, required = false,
                                 default = nil)
  if valid_611398 != nil:
    section.add "X-Amz-Signature", valid_611398
  var valid_611399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611399 = validateParameter(valid_611399, JString, required = false,
                                 default = nil)
  if valid_611399 != nil:
    section.add "X-Amz-Content-Sha256", valid_611399
  var valid_611400 = header.getOrDefault("X-Amz-Date")
  valid_611400 = validateParameter(valid_611400, JString, required = false,
                                 default = nil)
  if valid_611400 != nil:
    section.add "X-Amz-Date", valid_611400
  var valid_611401 = header.getOrDefault("X-Amz-Credential")
  valid_611401 = validateParameter(valid_611401, JString, required = false,
                                 default = nil)
  if valid_611401 != nil:
    section.add "X-Amz-Credential", valid_611401
  var valid_611402 = header.getOrDefault("X-Amz-Security-Token")
  valid_611402 = validateParameter(valid_611402, JString, required = false,
                                 default = nil)
  if valid_611402 != nil:
    section.add "X-Amz-Security-Token", valid_611402
  var valid_611403 = header.getOrDefault("X-Amz-Algorithm")
  valid_611403 = validateParameter(valid_611403, JString, required = false,
                                 default = nil)
  if valid_611403 != nil:
    section.add "X-Amz-Algorithm", valid_611403
  var valid_611404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611404 = validateParameter(valid_611404, JString, required = false,
                                 default = nil)
  if valid_611404 != nil:
    section.add "X-Amz-SignedHeaders", valid_611404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611406: Call_CreateProposal_611394; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a proposal for a change to the network that other members of the network can vote on, for example, a proposal to add a new member to the network. Any member can create a proposal.
  ## 
  let valid = call_611406.validator(path, query, header, formData, body)
  let scheme = call_611406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611406.url(scheme.get, call_611406.host, call_611406.base,
                         call_611406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611406, url, valid)

proc call*(call_611407: Call_CreateProposal_611394; networkId: string; body: JsonNode): Recallable =
  ## createProposal
  ## Creates a proposal for a change to the network that other members of the network can vote on, for example, a proposal to add a new member to the network. Any member can create a proposal.
  ##   networkId: string (required)
  ##            :  The unique identifier of the network for which the proposal is made.
  ##   body: JObject (required)
  var path_611408 = newJObject()
  var body_611409 = newJObject()
  add(path_611408, "networkId", newJString(networkId))
  if body != nil:
    body_611409 = body
  result = call_611407.call(path_611408, nil, nil, nil, body_611409)

var createProposal* = Call_CreateProposal_611394(name: "createProposal",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals", validator: validate_CreateProposal_611395,
    base: "/", url: url_CreateProposal_611396, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProposals_611375 = ref object of OpenApiRestCall_610658
proc url_ListProposals_611377(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListProposals_611376(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611378 = path.getOrDefault("networkId")
  valid_611378 = validateParameter(valid_611378, JString, required = true,
                                 default = nil)
  if valid_611378 != nil:
    section.add "networkId", valid_611378
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
  var valid_611379 = query.getOrDefault("nextToken")
  valid_611379 = validateParameter(valid_611379, JString, required = false,
                                 default = nil)
  if valid_611379 != nil:
    section.add "nextToken", valid_611379
  var valid_611380 = query.getOrDefault("MaxResults")
  valid_611380 = validateParameter(valid_611380, JString, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "MaxResults", valid_611380
  var valid_611381 = query.getOrDefault("NextToken")
  valid_611381 = validateParameter(valid_611381, JString, required = false,
                                 default = nil)
  if valid_611381 != nil:
    section.add "NextToken", valid_611381
  var valid_611382 = query.getOrDefault("maxResults")
  valid_611382 = validateParameter(valid_611382, JInt, required = false, default = nil)
  if valid_611382 != nil:
    section.add "maxResults", valid_611382
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
  var valid_611383 = header.getOrDefault("X-Amz-Signature")
  valid_611383 = validateParameter(valid_611383, JString, required = false,
                                 default = nil)
  if valid_611383 != nil:
    section.add "X-Amz-Signature", valid_611383
  var valid_611384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611384 = validateParameter(valid_611384, JString, required = false,
                                 default = nil)
  if valid_611384 != nil:
    section.add "X-Amz-Content-Sha256", valid_611384
  var valid_611385 = header.getOrDefault("X-Amz-Date")
  valid_611385 = validateParameter(valid_611385, JString, required = false,
                                 default = nil)
  if valid_611385 != nil:
    section.add "X-Amz-Date", valid_611385
  var valid_611386 = header.getOrDefault("X-Amz-Credential")
  valid_611386 = validateParameter(valid_611386, JString, required = false,
                                 default = nil)
  if valid_611386 != nil:
    section.add "X-Amz-Credential", valid_611386
  var valid_611387 = header.getOrDefault("X-Amz-Security-Token")
  valid_611387 = validateParameter(valid_611387, JString, required = false,
                                 default = nil)
  if valid_611387 != nil:
    section.add "X-Amz-Security-Token", valid_611387
  var valid_611388 = header.getOrDefault("X-Amz-Algorithm")
  valid_611388 = validateParameter(valid_611388, JString, required = false,
                                 default = nil)
  if valid_611388 != nil:
    section.add "X-Amz-Algorithm", valid_611388
  var valid_611389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "X-Amz-SignedHeaders", valid_611389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611390: Call_ListProposals_611375; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a listing of proposals for the network.
  ## 
  let valid = call_611390.validator(path, query, header, formData, body)
  let scheme = call_611390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611390.url(scheme.get, call_611390.host, call_611390.base,
                         call_611390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611390, url, valid)

proc call*(call_611391: Call_ListProposals_611375; networkId: string;
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
  var path_611392 = newJObject()
  var query_611393 = newJObject()
  add(query_611393, "nextToken", newJString(nextToken))
  add(query_611393, "MaxResults", newJString(MaxResults))
  add(query_611393, "NextToken", newJString(NextToken))
  add(path_611392, "networkId", newJString(networkId))
  add(query_611393, "maxResults", newJInt(maxResults))
  result = call_611391.call(path_611392, query_611393, nil, nil, nil)

var listProposals* = Call_ListProposals_611375(name: "listProposals",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals", validator: validate_ListProposals_611376,
    base: "/", url: url_ListProposals_611377, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMember_611410 = ref object of OpenApiRestCall_610658
proc url_GetMember_611412(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetMember_611411(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611413 = path.getOrDefault("memberId")
  valid_611413 = validateParameter(valid_611413, JString, required = true,
                                 default = nil)
  if valid_611413 != nil:
    section.add "memberId", valid_611413
  var valid_611414 = path.getOrDefault("networkId")
  valid_611414 = validateParameter(valid_611414, JString, required = true,
                                 default = nil)
  if valid_611414 != nil:
    section.add "networkId", valid_611414
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
  var valid_611415 = header.getOrDefault("X-Amz-Signature")
  valid_611415 = validateParameter(valid_611415, JString, required = false,
                                 default = nil)
  if valid_611415 != nil:
    section.add "X-Amz-Signature", valid_611415
  var valid_611416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611416 = validateParameter(valid_611416, JString, required = false,
                                 default = nil)
  if valid_611416 != nil:
    section.add "X-Amz-Content-Sha256", valid_611416
  var valid_611417 = header.getOrDefault("X-Amz-Date")
  valid_611417 = validateParameter(valid_611417, JString, required = false,
                                 default = nil)
  if valid_611417 != nil:
    section.add "X-Amz-Date", valid_611417
  var valid_611418 = header.getOrDefault("X-Amz-Credential")
  valid_611418 = validateParameter(valid_611418, JString, required = false,
                                 default = nil)
  if valid_611418 != nil:
    section.add "X-Amz-Credential", valid_611418
  var valid_611419 = header.getOrDefault("X-Amz-Security-Token")
  valid_611419 = validateParameter(valid_611419, JString, required = false,
                                 default = nil)
  if valid_611419 != nil:
    section.add "X-Amz-Security-Token", valid_611419
  var valid_611420 = header.getOrDefault("X-Amz-Algorithm")
  valid_611420 = validateParameter(valid_611420, JString, required = false,
                                 default = nil)
  if valid_611420 != nil:
    section.add "X-Amz-Algorithm", valid_611420
  var valid_611421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611421 = validateParameter(valid_611421, JString, required = false,
                                 default = nil)
  if valid_611421 != nil:
    section.add "X-Amz-SignedHeaders", valid_611421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611422: Call_GetMember_611410; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a member.
  ## 
  let valid = call_611422.validator(path, query, header, formData, body)
  let scheme = call_611422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611422.url(scheme.get, call_611422.host, call_611422.base,
                         call_611422.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611422, url, valid)

proc call*(call_611423: Call_GetMember_611410; memberId: string; networkId: string): Recallable =
  ## getMember
  ## Returns detailed information about a member.
  ##   memberId: string (required)
  ##           : The unique identifier of the member.
  ##   networkId: string (required)
  ##            : The unique identifier of the network to which the member belongs.
  var path_611424 = newJObject()
  add(path_611424, "memberId", newJString(memberId))
  add(path_611424, "networkId", newJString(networkId))
  result = call_611423.call(path_611424, nil, nil, nil, nil)

var getMember* = Call_GetMember_611410(name: "getMember", meth: HttpMethod.HttpGet,
                                    host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}",
                                    validator: validate_GetMember_611411,
                                    base: "/", url: url_GetMember_611412,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMember_611425 = ref object of OpenApiRestCall_610658
proc url_DeleteMember_611427(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteMember_611426(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611428 = path.getOrDefault("memberId")
  valid_611428 = validateParameter(valid_611428, JString, required = true,
                                 default = nil)
  if valid_611428 != nil:
    section.add "memberId", valid_611428
  var valid_611429 = path.getOrDefault("networkId")
  valid_611429 = validateParameter(valid_611429, JString, required = true,
                                 default = nil)
  if valid_611429 != nil:
    section.add "networkId", valid_611429
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
  var valid_611430 = header.getOrDefault("X-Amz-Signature")
  valid_611430 = validateParameter(valid_611430, JString, required = false,
                                 default = nil)
  if valid_611430 != nil:
    section.add "X-Amz-Signature", valid_611430
  var valid_611431 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611431 = validateParameter(valid_611431, JString, required = false,
                                 default = nil)
  if valid_611431 != nil:
    section.add "X-Amz-Content-Sha256", valid_611431
  var valid_611432 = header.getOrDefault("X-Amz-Date")
  valid_611432 = validateParameter(valid_611432, JString, required = false,
                                 default = nil)
  if valid_611432 != nil:
    section.add "X-Amz-Date", valid_611432
  var valid_611433 = header.getOrDefault("X-Amz-Credential")
  valid_611433 = validateParameter(valid_611433, JString, required = false,
                                 default = nil)
  if valid_611433 != nil:
    section.add "X-Amz-Credential", valid_611433
  var valid_611434 = header.getOrDefault("X-Amz-Security-Token")
  valid_611434 = validateParameter(valid_611434, JString, required = false,
                                 default = nil)
  if valid_611434 != nil:
    section.add "X-Amz-Security-Token", valid_611434
  var valid_611435 = header.getOrDefault("X-Amz-Algorithm")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "X-Amz-Algorithm", valid_611435
  var valid_611436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-SignedHeaders", valid_611436
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611437: Call_DeleteMember_611425; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a member. Deleting a member removes the member and all associated resources from the network. <code>DeleteMember</code> can only be called for a specified <code>MemberId</code> if the principal performing the action is associated with the AWS account that owns the member. In all other cases, the <code>DeleteMember</code> action is carried out as the result of an approved proposal to remove a member. If <code>MemberId</code> is the last member in a network specified by the last AWS account, the network is deleted also.
  ## 
  let valid = call_611437.validator(path, query, header, formData, body)
  let scheme = call_611437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611437.url(scheme.get, call_611437.host, call_611437.base,
                         call_611437.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611437, url, valid)

proc call*(call_611438: Call_DeleteMember_611425; memberId: string; networkId: string): Recallable =
  ## deleteMember
  ## Deletes a member. Deleting a member removes the member and all associated resources from the network. <code>DeleteMember</code> can only be called for a specified <code>MemberId</code> if the principal performing the action is associated with the AWS account that owns the member. In all other cases, the <code>DeleteMember</code> action is carried out as the result of an approved proposal to remove a member. If <code>MemberId</code> is the last member in a network specified by the last AWS account, the network is deleted also.
  ##   memberId: string (required)
  ##           : The unique identifier of the member to remove.
  ##   networkId: string (required)
  ##            : The unique identifier of the network from which the member is removed.
  var path_611439 = newJObject()
  add(path_611439, "memberId", newJString(memberId))
  add(path_611439, "networkId", newJString(networkId))
  result = call_611438.call(path_611439, nil, nil, nil, nil)

var deleteMember* = Call_DeleteMember_611425(name: "deleteMember",
    meth: HttpMethod.HttpDelete, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/members/{memberId}",
    validator: validate_DeleteMember_611426, base: "/", url: url_DeleteMember_611427,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNode_611440 = ref object of OpenApiRestCall_610658
proc url_GetNode_611442(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetNode_611441(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611443 = path.getOrDefault("memberId")
  valid_611443 = validateParameter(valid_611443, JString, required = true,
                                 default = nil)
  if valid_611443 != nil:
    section.add "memberId", valid_611443
  var valid_611444 = path.getOrDefault("networkId")
  valid_611444 = validateParameter(valid_611444, JString, required = true,
                                 default = nil)
  if valid_611444 != nil:
    section.add "networkId", valid_611444
  var valid_611445 = path.getOrDefault("nodeId")
  valid_611445 = validateParameter(valid_611445, JString, required = true,
                                 default = nil)
  if valid_611445 != nil:
    section.add "nodeId", valid_611445
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
  var valid_611446 = header.getOrDefault("X-Amz-Signature")
  valid_611446 = validateParameter(valid_611446, JString, required = false,
                                 default = nil)
  if valid_611446 != nil:
    section.add "X-Amz-Signature", valid_611446
  var valid_611447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611447 = validateParameter(valid_611447, JString, required = false,
                                 default = nil)
  if valid_611447 != nil:
    section.add "X-Amz-Content-Sha256", valid_611447
  var valid_611448 = header.getOrDefault("X-Amz-Date")
  valid_611448 = validateParameter(valid_611448, JString, required = false,
                                 default = nil)
  if valid_611448 != nil:
    section.add "X-Amz-Date", valid_611448
  var valid_611449 = header.getOrDefault("X-Amz-Credential")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "X-Amz-Credential", valid_611449
  var valid_611450 = header.getOrDefault("X-Amz-Security-Token")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "X-Amz-Security-Token", valid_611450
  var valid_611451 = header.getOrDefault("X-Amz-Algorithm")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "X-Amz-Algorithm", valid_611451
  var valid_611452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "X-Amz-SignedHeaders", valid_611452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611453: Call_GetNode_611440; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a peer node.
  ## 
  let valid = call_611453.validator(path, query, header, formData, body)
  let scheme = call_611453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611453.url(scheme.get, call_611453.host, call_611453.base,
                         call_611453.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611453, url, valid)

proc call*(call_611454: Call_GetNode_611440; memberId: string; networkId: string;
          nodeId: string): Recallable =
  ## getNode
  ## Returns detailed information about a peer node.
  ##   memberId: string (required)
  ##           : The unique identifier of the member that owns the node.
  ##   networkId: string (required)
  ##            : The unique identifier of the network to which the node belongs.
  ##   nodeId: string (required)
  ##         : The unique identifier of the node.
  var path_611455 = newJObject()
  add(path_611455, "memberId", newJString(memberId))
  add(path_611455, "networkId", newJString(networkId))
  add(path_611455, "nodeId", newJString(nodeId))
  result = call_611454.call(path_611455, nil, nil, nil, nil)

var getNode* = Call_GetNode_611440(name: "getNode", meth: HttpMethod.HttpGet,
                                host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes/{nodeId}",
                                validator: validate_GetNode_611441, base: "/",
                                url: url_GetNode_611442,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNode_611456 = ref object of OpenApiRestCall_610658
proc url_DeleteNode_611458(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteNode_611457(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611459 = path.getOrDefault("memberId")
  valid_611459 = validateParameter(valid_611459, JString, required = true,
                                 default = nil)
  if valid_611459 != nil:
    section.add "memberId", valid_611459
  var valid_611460 = path.getOrDefault("networkId")
  valid_611460 = validateParameter(valid_611460, JString, required = true,
                                 default = nil)
  if valid_611460 != nil:
    section.add "networkId", valid_611460
  var valid_611461 = path.getOrDefault("nodeId")
  valid_611461 = validateParameter(valid_611461, JString, required = true,
                                 default = nil)
  if valid_611461 != nil:
    section.add "nodeId", valid_611461
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
  var valid_611462 = header.getOrDefault("X-Amz-Signature")
  valid_611462 = validateParameter(valid_611462, JString, required = false,
                                 default = nil)
  if valid_611462 != nil:
    section.add "X-Amz-Signature", valid_611462
  var valid_611463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611463 = validateParameter(valid_611463, JString, required = false,
                                 default = nil)
  if valid_611463 != nil:
    section.add "X-Amz-Content-Sha256", valid_611463
  var valid_611464 = header.getOrDefault("X-Amz-Date")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "X-Amz-Date", valid_611464
  var valid_611465 = header.getOrDefault("X-Amz-Credential")
  valid_611465 = validateParameter(valid_611465, JString, required = false,
                                 default = nil)
  if valid_611465 != nil:
    section.add "X-Amz-Credential", valid_611465
  var valid_611466 = header.getOrDefault("X-Amz-Security-Token")
  valid_611466 = validateParameter(valid_611466, JString, required = false,
                                 default = nil)
  if valid_611466 != nil:
    section.add "X-Amz-Security-Token", valid_611466
  var valid_611467 = header.getOrDefault("X-Amz-Algorithm")
  valid_611467 = validateParameter(valid_611467, JString, required = false,
                                 default = nil)
  if valid_611467 != nil:
    section.add "X-Amz-Algorithm", valid_611467
  var valid_611468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "X-Amz-SignedHeaders", valid_611468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611469: Call_DeleteNode_611456; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a peer node from a member that your AWS account owns. All data on the node is lost and cannot be recovered.
  ## 
  let valid = call_611469.validator(path, query, header, formData, body)
  let scheme = call_611469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611469.url(scheme.get, call_611469.host, call_611469.base,
                         call_611469.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611469, url, valid)

proc call*(call_611470: Call_DeleteNode_611456; memberId: string; networkId: string;
          nodeId: string): Recallable =
  ## deleteNode
  ## Deletes a peer node from a member that your AWS account owns. All data on the node is lost and cannot be recovered.
  ##   memberId: string (required)
  ##           : The unique identifier of the member that owns this node.
  ##   networkId: string (required)
  ##            : The unique identifier of the network that the node belongs to.
  ##   nodeId: string (required)
  ##         : The unique identifier of the node.
  var path_611471 = newJObject()
  add(path_611471, "memberId", newJString(memberId))
  add(path_611471, "networkId", newJString(networkId))
  add(path_611471, "nodeId", newJString(nodeId))
  result = call_611470.call(path_611471, nil, nil, nil, nil)

var deleteNode* = Call_DeleteNode_611456(name: "deleteNode",
                                      meth: HttpMethod.HttpDelete,
                                      host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes/{nodeId}",
                                      validator: validate_DeleteNode_611457,
                                      base: "/", url: url_DeleteNode_611458,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNetwork_611472 = ref object of OpenApiRestCall_610658
proc url_GetNetwork_611474(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetNetwork_611473(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611475 = path.getOrDefault("networkId")
  valid_611475 = validateParameter(valid_611475, JString, required = true,
                                 default = nil)
  if valid_611475 != nil:
    section.add "networkId", valid_611475
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
  var valid_611476 = header.getOrDefault("X-Amz-Signature")
  valid_611476 = validateParameter(valid_611476, JString, required = false,
                                 default = nil)
  if valid_611476 != nil:
    section.add "X-Amz-Signature", valid_611476
  var valid_611477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611477 = validateParameter(valid_611477, JString, required = false,
                                 default = nil)
  if valid_611477 != nil:
    section.add "X-Amz-Content-Sha256", valid_611477
  var valid_611478 = header.getOrDefault("X-Amz-Date")
  valid_611478 = validateParameter(valid_611478, JString, required = false,
                                 default = nil)
  if valid_611478 != nil:
    section.add "X-Amz-Date", valid_611478
  var valid_611479 = header.getOrDefault("X-Amz-Credential")
  valid_611479 = validateParameter(valid_611479, JString, required = false,
                                 default = nil)
  if valid_611479 != nil:
    section.add "X-Amz-Credential", valid_611479
  var valid_611480 = header.getOrDefault("X-Amz-Security-Token")
  valid_611480 = validateParameter(valid_611480, JString, required = false,
                                 default = nil)
  if valid_611480 != nil:
    section.add "X-Amz-Security-Token", valid_611480
  var valid_611481 = header.getOrDefault("X-Amz-Algorithm")
  valid_611481 = validateParameter(valid_611481, JString, required = false,
                                 default = nil)
  if valid_611481 != nil:
    section.add "X-Amz-Algorithm", valid_611481
  var valid_611482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611482 = validateParameter(valid_611482, JString, required = false,
                                 default = nil)
  if valid_611482 != nil:
    section.add "X-Amz-SignedHeaders", valid_611482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611483: Call_GetNetwork_611472; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a network.
  ## 
  let valid = call_611483.validator(path, query, header, formData, body)
  let scheme = call_611483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611483.url(scheme.get, call_611483.host, call_611483.base,
                         call_611483.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611483, url, valid)

proc call*(call_611484: Call_GetNetwork_611472; networkId: string): Recallable =
  ## getNetwork
  ## Returns detailed information about a network.
  ##   networkId: string (required)
  ##            : The unique identifier of the network to get information about.
  var path_611485 = newJObject()
  add(path_611485, "networkId", newJString(networkId))
  result = call_611484.call(path_611485, nil, nil, nil, nil)

var getNetwork* = Call_GetNetwork_611472(name: "getNetwork",
                                      meth: HttpMethod.HttpGet,
                                      host: "managedblockchain.amazonaws.com",
                                      route: "/networks/{networkId}",
                                      validator: validate_GetNetwork_611473,
                                      base: "/", url: url_GetNetwork_611474,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProposal_611486 = ref object of OpenApiRestCall_610658
proc url_GetProposal_611488(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetProposal_611487(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611489 = path.getOrDefault("proposalId")
  valid_611489 = validateParameter(valid_611489, JString, required = true,
                                 default = nil)
  if valid_611489 != nil:
    section.add "proposalId", valid_611489
  var valid_611490 = path.getOrDefault("networkId")
  valid_611490 = validateParameter(valid_611490, JString, required = true,
                                 default = nil)
  if valid_611490 != nil:
    section.add "networkId", valid_611490
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
  var valid_611491 = header.getOrDefault("X-Amz-Signature")
  valid_611491 = validateParameter(valid_611491, JString, required = false,
                                 default = nil)
  if valid_611491 != nil:
    section.add "X-Amz-Signature", valid_611491
  var valid_611492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611492 = validateParameter(valid_611492, JString, required = false,
                                 default = nil)
  if valid_611492 != nil:
    section.add "X-Amz-Content-Sha256", valid_611492
  var valid_611493 = header.getOrDefault("X-Amz-Date")
  valid_611493 = validateParameter(valid_611493, JString, required = false,
                                 default = nil)
  if valid_611493 != nil:
    section.add "X-Amz-Date", valid_611493
  var valid_611494 = header.getOrDefault("X-Amz-Credential")
  valid_611494 = validateParameter(valid_611494, JString, required = false,
                                 default = nil)
  if valid_611494 != nil:
    section.add "X-Amz-Credential", valid_611494
  var valid_611495 = header.getOrDefault("X-Amz-Security-Token")
  valid_611495 = validateParameter(valid_611495, JString, required = false,
                                 default = nil)
  if valid_611495 != nil:
    section.add "X-Amz-Security-Token", valid_611495
  var valid_611496 = header.getOrDefault("X-Amz-Algorithm")
  valid_611496 = validateParameter(valid_611496, JString, required = false,
                                 default = nil)
  if valid_611496 != nil:
    section.add "X-Amz-Algorithm", valid_611496
  var valid_611497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611497 = validateParameter(valid_611497, JString, required = false,
                                 default = nil)
  if valid_611497 != nil:
    section.add "X-Amz-SignedHeaders", valid_611497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611498: Call_GetProposal_611486; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a proposal.
  ## 
  let valid = call_611498.validator(path, query, header, formData, body)
  let scheme = call_611498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611498.url(scheme.get, call_611498.host, call_611498.base,
                         call_611498.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611498, url, valid)

proc call*(call_611499: Call_GetProposal_611486; proposalId: string;
          networkId: string): Recallable =
  ## getProposal
  ## Returns detailed information about a proposal.
  ##   proposalId: string (required)
  ##             : The unique identifier of the proposal.
  ##   networkId: string (required)
  ##            : The unique identifier of the network for which the proposal is made.
  var path_611500 = newJObject()
  add(path_611500, "proposalId", newJString(proposalId))
  add(path_611500, "networkId", newJString(networkId))
  result = call_611499.call(path_611500, nil, nil, nil, nil)

var getProposal* = Call_GetProposal_611486(name: "getProposal",
                                        meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/proposals/{proposalId}",
                                        validator: validate_GetProposal_611487,
                                        base: "/", url: url_GetProposal_611488,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_611501 = ref object of OpenApiRestCall_610658
proc url_ListInvitations_611503(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInvitations_611502(path: JsonNode; query: JsonNode;
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
  var valid_611504 = query.getOrDefault("nextToken")
  valid_611504 = validateParameter(valid_611504, JString, required = false,
                                 default = nil)
  if valid_611504 != nil:
    section.add "nextToken", valid_611504
  var valid_611505 = query.getOrDefault("MaxResults")
  valid_611505 = validateParameter(valid_611505, JString, required = false,
                                 default = nil)
  if valid_611505 != nil:
    section.add "MaxResults", valid_611505
  var valid_611506 = query.getOrDefault("NextToken")
  valid_611506 = validateParameter(valid_611506, JString, required = false,
                                 default = nil)
  if valid_611506 != nil:
    section.add "NextToken", valid_611506
  var valid_611507 = query.getOrDefault("maxResults")
  valid_611507 = validateParameter(valid_611507, JInt, required = false, default = nil)
  if valid_611507 != nil:
    section.add "maxResults", valid_611507
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
  var valid_611508 = header.getOrDefault("X-Amz-Signature")
  valid_611508 = validateParameter(valid_611508, JString, required = false,
                                 default = nil)
  if valid_611508 != nil:
    section.add "X-Amz-Signature", valid_611508
  var valid_611509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611509 = validateParameter(valid_611509, JString, required = false,
                                 default = nil)
  if valid_611509 != nil:
    section.add "X-Amz-Content-Sha256", valid_611509
  var valid_611510 = header.getOrDefault("X-Amz-Date")
  valid_611510 = validateParameter(valid_611510, JString, required = false,
                                 default = nil)
  if valid_611510 != nil:
    section.add "X-Amz-Date", valid_611510
  var valid_611511 = header.getOrDefault("X-Amz-Credential")
  valid_611511 = validateParameter(valid_611511, JString, required = false,
                                 default = nil)
  if valid_611511 != nil:
    section.add "X-Amz-Credential", valid_611511
  var valid_611512 = header.getOrDefault("X-Amz-Security-Token")
  valid_611512 = validateParameter(valid_611512, JString, required = false,
                                 default = nil)
  if valid_611512 != nil:
    section.add "X-Amz-Security-Token", valid_611512
  var valid_611513 = header.getOrDefault("X-Amz-Algorithm")
  valid_611513 = validateParameter(valid_611513, JString, required = false,
                                 default = nil)
  if valid_611513 != nil:
    section.add "X-Amz-Algorithm", valid_611513
  var valid_611514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611514 = validateParameter(valid_611514, JString, required = false,
                                 default = nil)
  if valid_611514 != nil:
    section.add "X-Amz-SignedHeaders", valid_611514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611515: Call_ListInvitations_611501; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a listing of all invitations made on the specified network.
  ## 
  let valid = call_611515.validator(path, query, header, formData, body)
  let scheme = call_611515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611515.url(scheme.get, call_611515.host, call_611515.base,
                         call_611515.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611515, url, valid)

proc call*(call_611516: Call_ListInvitations_611501; nextToken: string = "";
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
  var query_611517 = newJObject()
  add(query_611517, "nextToken", newJString(nextToken))
  add(query_611517, "MaxResults", newJString(MaxResults))
  add(query_611517, "NextToken", newJString(NextToken))
  add(query_611517, "maxResults", newJInt(maxResults))
  result = call_611516.call(nil, query_611517, nil, nil, nil)

var listInvitations* = Call_ListInvitations_611501(name: "listInvitations",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/invitations", validator: validate_ListInvitations_611502, base: "/",
    url: url_ListInvitations_611503, schemes: {Scheme.Https, Scheme.Http})
type
  Call_VoteOnProposal_611538 = ref object of OpenApiRestCall_610658
proc url_VoteOnProposal_611540(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_VoteOnProposal_611539(path: JsonNode; query: JsonNode;
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
  var valid_611541 = path.getOrDefault("proposalId")
  valid_611541 = validateParameter(valid_611541, JString, required = true,
                                 default = nil)
  if valid_611541 != nil:
    section.add "proposalId", valid_611541
  var valid_611542 = path.getOrDefault("networkId")
  valid_611542 = validateParameter(valid_611542, JString, required = true,
                                 default = nil)
  if valid_611542 != nil:
    section.add "networkId", valid_611542
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
  var valid_611543 = header.getOrDefault("X-Amz-Signature")
  valid_611543 = validateParameter(valid_611543, JString, required = false,
                                 default = nil)
  if valid_611543 != nil:
    section.add "X-Amz-Signature", valid_611543
  var valid_611544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611544 = validateParameter(valid_611544, JString, required = false,
                                 default = nil)
  if valid_611544 != nil:
    section.add "X-Amz-Content-Sha256", valid_611544
  var valid_611545 = header.getOrDefault("X-Amz-Date")
  valid_611545 = validateParameter(valid_611545, JString, required = false,
                                 default = nil)
  if valid_611545 != nil:
    section.add "X-Amz-Date", valid_611545
  var valid_611546 = header.getOrDefault("X-Amz-Credential")
  valid_611546 = validateParameter(valid_611546, JString, required = false,
                                 default = nil)
  if valid_611546 != nil:
    section.add "X-Amz-Credential", valid_611546
  var valid_611547 = header.getOrDefault("X-Amz-Security-Token")
  valid_611547 = validateParameter(valid_611547, JString, required = false,
                                 default = nil)
  if valid_611547 != nil:
    section.add "X-Amz-Security-Token", valid_611547
  var valid_611548 = header.getOrDefault("X-Amz-Algorithm")
  valid_611548 = validateParameter(valid_611548, JString, required = false,
                                 default = nil)
  if valid_611548 != nil:
    section.add "X-Amz-Algorithm", valid_611548
  var valid_611549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611549 = validateParameter(valid_611549, JString, required = false,
                                 default = nil)
  if valid_611549 != nil:
    section.add "X-Amz-SignedHeaders", valid_611549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611551: Call_VoteOnProposal_611538; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Casts a vote for a specified <code>ProposalId</code> on behalf of a member. The member to vote as, specified by <code>VoterMemberId</code>, must be in the same AWS account as the principal that calls the action.
  ## 
  let valid = call_611551.validator(path, query, header, formData, body)
  let scheme = call_611551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611551.url(scheme.get, call_611551.host, call_611551.base,
                         call_611551.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611551, url, valid)

proc call*(call_611552: Call_VoteOnProposal_611538; proposalId: string;
          networkId: string; body: JsonNode): Recallable =
  ## voteOnProposal
  ## Casts a vote for a specified <code>ProposalId</code> on behalf of a member. The member to vote as, specified by <code>VoterMemberId</code>, must be in the same AWS account as the principal that calls the action.
  ##   proposalId: string (required)
  ##             :  The unique identifier of the proposal. 
  ##   networkId: string (required)
  ##            :  The unique identifier of the network. 
  ##   body: JObject (required)
  var path_611553 = newJObject()
  var body_611554 = newJObject()
  add(path_611553, "proposalId", newJString(proposalId))
  add(path_611553, "networkId", newJString(networkId))
  if body != nil:
    body_611554 = body
  result = call_611552.call(path_611553, nil, nil, nil, body_611554)

var voteOnProposal* = Call_VoteOnProposal_611538(name: "voteOnProposal",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals/{proposalId}/votes",
    validator: validate_VoteOnProposal_611539, base: "/", url: url_VoteOnProposal_611540,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProposalVotes_611518 = ref object of OpenApiRestCall_610658
proc url_ListProposalVotes_611520(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListProposalVotes_611519(path: JsonNode; query: JsonNode;
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
  var valid_611521 = path.getOrDefault("proposalId")
  valid_611521 = validateParameter(valid_611521, JString, required = true,
                                 default = nil)
  if valid_611521 != nil:
    section.add "proposalId", valid_611521
  var valid_611522 = path.getOrDefault("networkId")
  valid_611522 = validateParameter(valid_611522, JString, required = true,
                                 default = nil)
  if valid_611522 != nil:
    section.add "networkId", valid_611522
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
  var valid_611523 = query.getOrDefault("nextToken")
  valid_611523 = validateParameter(valid_611523, JString, required = false,
                                 default = nil)
  if valid_611523 != nil:
    section.add "nextToken", valid_611523
  var valid_611524 = query.getOrDefault("MaxResults")
  valid_611524 = validateParameter(valid_611524, JString, required = false,
                                 default = nil)
  if valid_611524 != nil:
    section.add "MaxResults", valid_611524
  var valid_611525 = query.getOrDefault("NextToken")
  valid_611525 = validateParameter(valid_611525, JString, required = false,
                                 default = nil)
  if valid_611525 != nil:
    section.add "NextToken", valid_611525
  var valid_611526 = query.getOrDefault("maxResults")
  valid_611526 = validateParameter(valid_611526, JInt, required = false, default = nil)
  if valid_611526 != nil:
    section.add "maxResults", valid_611526
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
  var valid_611527 = header.getOrDefault("X-Amz-Signature")
  valid_611527 = validateParameter(valid_611527, JString, required = false,
                                 default = nil)
  if valid_611527 != nil:
    section.add "X-Amz-Signature", valid_611527
  var valid_611528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611528 = validateParameter(valid_611528, JString, required = false,
                                 default = nil)
  if valid_611528 != nil:
    section.add "X-Amz-Content-Sha256", valid_611528
  var valid_611529 = header.getOrDefault("X-Amz-Date")
  valid_611529 = validateParameter(valid_611529, JString, required = false,
                                 default = nil)
  if valid_611529 != nil:
    section.add "X-Amz-Date", valid_611529
  var valid_611530 = header.getOrDefault("X-Amz-Credential")
  valid_611530 = validateParameter(valid_611530, JString, required = false,
                                 default = nil)
  if valid_611530 != nil:
    section.add "X-Amz-Credential", valid_611530
  var valid_611531 = header.getOrDefault("X-Amz-Security-Token")
  valid_611531 = validateParameter(valid_611531, JString, required = false,
                                 default = nil)
  if valid_611531 != nil:
    section.add "X-Amz-Security-Token", valid_611531
  var valid_611532 = header.getOrDefault("X-Amz-Algorithm")
  valid_611532 = validateParameter(valid_611532, JString, required = false,
                                 default = nil)
  if valid_611532 != nil:
    section.add "X-Amz-Algorithm", valid_611532
  var valid_611533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611533 = validateParameter(valid_611533, JString, required = false,
                                 default = nil)
  if valid_611533 != nil:
    section.add "X-Amz-SignedHeaders", valid_611533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611534: Call_ListProposalVotes_611518; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the listing of votes for a specified proposal, including the value of each vote and the unique identifier of the member that cast the vote.
  ## 
  let valid = call_611534.validator(path, query, header, formData, body)
  let scheme = call_611534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611534.url(scheme.get, call_611534.host, call_611534.base,
                         call_611534.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611534, url, valid)

proc call*(call_611535: Call_ListProposalVotes_611518; proposalId: string;
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
  var path_611536 = newJObject()
  var query_611537 = newJObject()
  add(query_611537, "nextToken", newJString(nextToken))
  add(query_611537, "MaxResults", newJString(MaxResults))
  add(path_611536, "proposalId", newJString(proposalId))
  add(query_611537, "NextToken", newJString(NextToken))
  add(path_611536, "networkId", newJString(networkId))
  add(query_611537, "maxResults", newJInt(maxResults))
  result = call_611535.call(path_611536, query_611537, nil, nil, nil)

var listProposalVotes* = Call_ListProposalVotes_611518(name: "listProposalVotes",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals/{proposalId}/votes",
    validator: validate_ListProposalVotes_611519, base: "/",
    url: url_ListProposalVotes_611520, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectInvitation_611555 = ref object of OpenApiRestCall_610658
proc url_RejectInvitation_611557(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RejectInvitation_611556(path: JsonNode; query: JsonNode;
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
  var valid_611558 = path.getOrDefault("invitationId")
  valid_611558 = validateParameter(valid_611558, JString, required = true,
                                 default = nil)
  if valid_611558 != nil:
    section.add "invitationId", valid_611558
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
  var valid_611559 = header.getOrDefault("X-Amz-Signature")
  valid_611559 = validateParameter(valid_611559, JString, required = false,
                                 default = nil)
  if valid_611559 != nil:
    section.add "X-Amz-Signature", valid_611559
  var valid_611560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611560 = validateParameter(valid_611560, JString, required = false,
                                 default = nil)
  if valid_611560 != nil:
    section.add "X-Amz-Content-Sha256", valid_611560
  var valid_611561 = header.getOrDefault("X-Amz-Date")
  valid_611561 = validateParameter(valid_611561, JString, required = false,
                                 default = nil)
  if valid_611561 != nil:
    section.add "X-Amz-Date", valid_611561
  var valid_611562 = header.getOrDefault("X-Amz-Credential")
  valid_611562 = validateParameter(valid_611562, JString, required = false,
                                 default = nil)
  if valid_611562 != nil:
    section.add "X-Amz-Credential", valid_611562
  var valid_611563 = header.getOrDefault("X-Amz-Security-Token")
  valid_611563 = validateParameter(valid_611563, JString, required = false,
                                 default = nil)
  if valid_611563 != nil:
    section.add "X-Amz-Security-Token", valid_611563
  var valid_611564 = header.getOrDefault("X-Amz-Algorithm")
  valid_611564 = validateParameter(valid_611564, JString, required = false,
                                 default = nil)
  if valid_611564 != nil:
    section.add "X-Amz-Algorithm", valid_611564
  var valid_611565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611565 = validateParameter(valid_611565, JString, required = false,
                                 default = nil)
  if valid_611565 != nil:
    section.add "X-Amz-SignedHeaders", valid_611565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611566: Call_RejectInvitation_611555; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Rejects an invitation to join a network. This action can be called by a principal in an AWS account that has received an invitation to create a member and join a network.
  ## 
  let valid = call_611566.validator(path, query, header, formData, body)
  let scheme = call_611566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611566.url(scheme.get, call_611566.host, call_611566.base,
                         call_611566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611566, url, valid)

proc call*(call_611567: Call_RejectInvitation_611555; invitationId: string): Recallable =
  ## rejectInvitation
  ## Rejects an invitation to join a network. This action can be called by a principal in an AWS account that has received an invitation to create a member and join a network.
  ##   invitationId: string (required)
  ##               : The unique identifier of the invitation to reject.
  var path_611568 = newJObject()
  add(path_611568, "invitationId", newJString(invitationId))
  result = call_611567.call(path_611568, nil, nil, nil, nil)

var rejectInvitation* = Call_RejectInvitation_611555(name: "rejectInvitation",
    meth: HttpMethod.HttpDelete, host: "managedblockchain.amazonaws.com",
    route: "/invitations/{invitationId}", validator: validate_RejectInvitation_611556,
    base: "/", url: url_RejectInvitation_611557,
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
