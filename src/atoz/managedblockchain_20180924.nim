
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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  Call_CreateMember_613287 = ref object of OpenApiRestCall_612658
proc url_CreateMember_613289(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMember_613288(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613290 = path.getOrDefault("networkId")
  valid_613290 = validateParameter(valid_613290, JString, required = true,
                                 default = nil)
  if valid_613290 != nil:
    section.add "networkId", valid_613290
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
  var valid_613291 = header.getOrDefault("X-Amz-Signature")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-Signature", valid_613291
  var valid_613292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-Content-Sha256", valid_613292
  var valid_613293 = header.getOrDefault("X-Amz-Date")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-Date", valid_613293
  var valid_613294 = header.getOrDefault("X-Amz-Credential")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "X-Amz-Credential", valid_613294
  var valid_613295 = header.getOrDefault("X-Amz-Security-Token")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-Security-Token", valid_613295
  var valid_613296 = header.getOrDefault("X-Amz-Algorithm")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "X-Amz-Algorithm", valid_613296
  var valid_613297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613297 = validateParameter(valid_613297, JString, required = false,
                                 default = nil)
  if valid_613297 != nil:
    section.add "X-Amz-SignedHeaders", valid_613297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613299: Call_CreateMember_613287; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a member within a Managed Blockchain network.
  ## 
  let valid = call_613299.validator(path, query, header, formData, body)
  let scheme = call_613299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613299.url(scheme.get, call_613299.host, call_613299.base,
                         call_613299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613299, url, valid)

proc call*(call_613300: Call_CreateMember_613287; networkId: string; body: JsonNode): Recallable =
  ## createMember
  ## Creates a member within a Managed Blockchain network.
  ##   networkId: string (required)
  ##            : The unique identifier of the network in which the member is created.
  ##   body: JObject (required)
  var path_613301 = newJObject()
  var body_613302 = newJObject()
  add(path_613301, "networkId", newJString(networkId))
  if body != nil:
    body_613302 = body
  result = call_613300.call(path_613301, nil, nil, nil, body_613302)

var createMember* = Call_CreateMember_613287(name: "createMember",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/members", validator: validate_CreateMember_613288,
    base: "/", url: url_CreateMember_613289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_612996 = ref object of OpenApiRestCall_612658
proc url_ListMembers_612998(protocol: Scheme; host: string; base: string;
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

proc validate_ListMembers_612997(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613124 = path.getOrDefault("networkId")
  valid_613124 = validateParameter(valid_613124, JString, required = true,
                                 default = nil)
  if valid_613124 != nil:
    section.add "networkId", valid_613124
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
  var valid_613125 = query.getOrDefault("name")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "name", valid_613125
  var valid_613126 = query.getOrDefault("nextToken")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "nextToken", valid_613126
  var valid_613127 = query.getOrDefault("MaxResults")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "MaxResults", valid_613127
  var valid_613128 = query.getOrDefault("NextToken")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "NextToken", valid_613128
  var valid_613129 = query.getOrDefault("isOwned")
  valid_613129 = validateParameter(valid_613129, JBool, required = false, default = nil)
  if valid_613129 != nil:
    section.add "isOwned", valid_613129
  var valid_613143 = query.getOrDefault("status")
  valid_613143 = validateParameter(valid_613143, JString, required = false,
                                 default = newJString("CREATING"))
  if valid_613143 != nil:
    section.add "status", valid_613143
  var valid_613144 = query.getOrDefault("maxResults")
  valid_613144 = validateParameter(valid_613144, JInt, required = false, default = nil)
  if valid_613144 != nil:
    section.add "maxResults", valid_613144
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
  var valid_613145 = header.getOrDefault("X-Amz-Signature")
  valid_613145 = validateParameter(valid_613145, JString, required = false,
                                 default = nil)
  if valid_613145 != nil:
    section.add "X-Amz-Signature", valid_613145
  var valid_613146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613146 = validateParameter(valid_613146, JString, required = false,
                                 default = nil)
  if valid_613146 != nil:
    section.add "X-Amz-Content-Sha256", valid_613146
  var valid_613147 = header.getOrDefault("X-Amz-Date")
  valid_613147 = validateParameter(valid_613147, JString, required = false,
                                 default = nil)
  if valid_613147 != nil:
    section.add "X-Amz-Date", valid_613147
  var valid_613148 = header.getOrDefault("X-Amz-Credential")
  valid_613148 = validateParameter(valid_613148, JString, required = false,
                                 default = nil)
  if valid_613148 != nil:
    section.add "X-Amz-Credential", valid_613148
  var valid_613149 = header.getOrDefault("X-Amz-Security-Token")
  valid_613149 = validateParameter(valid_613149, JString, required = false,
                                 default = nil)
  if valid_613149 != nil:
    section.add "X-Amz-Security-Token", valid_613149
  var valid_613150 = header.getOrDefault("X-Amz-Algorithm")
  valid_613150 = validateParameter(valid_613150, JString, required = false,
                                 default = nil)
  if valid_613150 != nil:
    section.add "X-Amz-Algorithm", valid_613150
  var valid_613151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613151 = validateParameter(valid_613151, JString, required = false,
                                 default = nil)
  if valid_613151 != nil:
    section.add "X-Amz-SignedHeaders", valid_613151
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613174: Call_ListMembers_612996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a listing of the members in a network and properties of their configurations.
  ## 
  let valid = call_613174.validator(path, query, header, formData, body)
  let scheme = call_613174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613174.url(scheme.get, call_613174.host, call_613174.base,
                         call_613174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613174, url, valid)

proc call*(call_613245: Call_ListMembers_612996; networkId: string;
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
  var path_613246 = newJObject()
  var query_613248 = newJObject()
  add(query_613248, "name", newJString(name))
  add(query_613248, "nextToken", newJString(nextToken))
  add(query_613248, "MaxResults", newJString(MaxResults))
  add(query_613248, "NextToken", newJString(NextToken))
  add(path_613246, "networkId", newJString(networkId))
  add(query_613248, "isOwned", newJBool(isOwned))
  add(query_613248, "status", newJString(status))
  add(query_613248, "maxResults", newJInt(maxResults))
  result = call_613245.call(path_613246, query_613248, nil, nil, nil)

var listMembers* = Call_ListMembers_612996(name: "listMembers",
                                        meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
                                        route: "/networks/{networkId}/members",
                                        validator: validate_ListMembers_612997,
                                        base: "/", url: url_ListMembers_612998,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNetwork_613323 = ref object of OpenApiRestCall_612658
proc url_CreateNetwork_613325(protocol: Scheme; host: string; base: string;
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

proc validate_CreateNetwork_613324(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613326 = header.getOrDefault("X-Amz-Signature")
  valid_613326 = validateParameter(valid_613326, JString, required = false,
                                 default = nil)
  if valid_613326 != nil:
    section.add "X-Amz-Signature", valid_613326
  var valid_613327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613327 = validateParameter(valid_613327, JString, required = false,
                                 default = nil)
  if valid_613327 != nil:
    section.add "X-Amz-Content-Sha256", valid_613327
  var valid_613328 = header.getOrDefault("X-Amz-Date")
  valid_613328 = validateParameter(valid_613328, JString, required = false,
                                 default = nil)
  if valid_613328 != nil:
    section.add "X-Amz-Date", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Credential")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Credential", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Security-Token")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Security-Token", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Algorithm")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Algorithm", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-SignedHeaders", valid_613332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613334: Call_CreateNetwork_613323; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new blockchain network using Amazon Managed Blockchain.
  ## 
  let valid = call_613334.validator(path, query, header, formData, body)
  let scheme = call_613334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613334.url(scheme.get, call_613334.host, call_613334.base,
                         call_613334.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613334, url, valid)

proc call*(call_613335: Call_CreateNetwork_613323; body: JsonNode): Recallable =
  ## createNetwork
  ## Creates a new blockchain network using Amazon Managed Blockchain.
  ##   body: JObject (required)
  var body_613336 = newJObject()
  if body != nil:
    body_613336 = body
  result = call_613335.call(nil, nil, nil, nil, body_613336)

var createNetwork* = Call_CreateNetwork_613323(name: "createNetwork",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks", validator: validate_CreateNetwork_613324, base: "/",
    url: url_CreateNetwork_613325, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNetworks_613303 = ref object of OpenApiRestCall_612658
proc url_ListNetworks_613305(protocol: Scheme; host: string; base: string;
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

proc validate_ListNetworks_613304(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613306 = query.getOrDefault("framework")
  valid_613306 = validateParameter(valid_613306, JString, required = false,
                                 default = newJString("HYPERLEDGER_FABRIC"))
  if valid_613306 != nil:
    section.add "framework", valid_613306
  var valid_613307 = query.getOrDefault("name")
  valid_613307 = validateParameter(valid_613307, JString, required = false,
                                 default = nil)
  if valid_613307 != nil:
    section.add "name", valid_613307
  var valid_613308 = query.getOrDefault("nextToken")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "nextToken", valid_613308
  var valid_613309 = query.getOrDefault("MaxResults")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "MaxResults", valid_613309
  var valid_613310 = query.getOrDefault("NextToken")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "NextToken", valid_613310
  var valid_613311 = query.getOrDefault("status")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = newJString("CREATING"))
  if valid_613311 != nil:
    section.add "status", valid_613311
  var valid_613312 = query.getOrDefault("maxResults")
  valid_613312 = validateParameter(valid_613312, JInt, required = false, default = nil)
  if valid_613312 != nil:
    section.add "maxResults", valid_613312
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
  var valid_613313 = header.getOrDefault("X-Amz-Signature")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "X-Amz-Signature", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Content-Sha256", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Date")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Date", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Credential")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Credential", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Security-Token")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Security-Token", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Algorithm")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Algorithm", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-SignedHeaders", valid_613319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613320: Call_ListNetworks_613303; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the networks in which the current AWS account has members.
  ## 
  let valid = call_613320.validator(path, query, header, formData, body)
  let scheme = call_613320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613320.url(scheme.get, call_613320.host, call_613320.base,
                         call_613320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613320, url, valid)

proc call*(call_613321: Call_ListNetworks_613303;
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
  var query_613322 = newJObject()
  add(query_613322, "framework", newJString(framework))
  add(query_613322, "name", newJString(name))
  add(query_613322, "nextToken", newJString(nextToken))
  add(query_613322, "MaxResults", newJString(MaxResults))
  add(query_613322, "NextToken", newJString(NextToken))
  add(query_613322, "status", newJString(status))
  add(query_613322, "maxResults", newJInt(maxResults))
  result = call_613321.call(nil, query_613322, nil, nil, nil)

var listNetworks* = Call_ListNetworks_613303(name: "listNetworks",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks", validator: validate_ListNetworks_613304, base: "/",
    url: url_ListNetworks_613305, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNode_613358 = ref object of OpenApiRestCall_612658
proc url_CreateNode_613360(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateNode_613359(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613361 = path.getOrDefault("memberId")
  valid_613361 = validateParameter(valid_613361, JString, required = true,
                                 default = nil)
  if valid_613361 != nil:
    section.add "memberId", valid_613361
  var valid_613362 = path.getOrDefault("networkId")
  valid_613362 = validateParameter(valid_613362, JString, required = true,
                                 default = nil)
  if valid_613362 != nil:
    section.add "networkId", valid_613362
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
  var valid_613363 = header.getOrDefault("X-Amz-Signature")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Signature", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Content-Sha256", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-Date")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-Date", valid_613365
  var valid_613366 = header.getOrDefault("X-Amz-Credential")
  valid_613366 = validateParameter(valid_613366, JString, required = false,
                                 default = nil)
  if valid_613366 != nil:
    section.add "X-Amz-Credential", valid_613366
  var valid_613367 = header.getOrDefault("X-Amz-Security-Token")
  valid_613367 = validateParameter(valid_613367, JString, required = false,
                                 default = nil)
  if valid_613367 != nil:
    section.add "X-Amz-Security-Token", valid_613367
  var valid_613368 = header.getOrDefault("X-Amz-Algorithm")
  valid_613368 = validateParameter(valid_613368, JString, required = false,
                                 default = nil)
  if valid_613368 != nil:
    section.add "X-Amz-Algorithm", valid_613368
  var valid_613369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613369 = validateParameter(valid_613369, JString, required = false,
                                 default = nil)
  if valid_613369 != nil:
    section.add "X-Amz-SignedHeaders", valid_613369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613371: Call_CreateNode_613358; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a peer node in a member.
  ## 
  let valid = call_613371.validator(path, query, header, formData, body)
  let scheme = call_613371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613371.url(scheme.get, call_613371.host, call_613371.base,
                         call_613371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613371, url, valid)

proc call*(call_613372: Call_CreateNode_613358; memberId: string; networkId: string;
          body: JsonNode): Recallable =
  ## createNode
  ## Creates a peer node in a member.
  ##   memberId: string (required)
  ##           : The unique identifier of the member that owns this node.
  ##   networkId: string (required)
  ##            : The unique identifier of the network in which this node runs.
  ##   body: JObject (required)
  var path_613373 = newJObject()
  var body_613374 = newJObject()
  add(path_613373, "memberId", newJString(memberId))
  add(path_613373, "networkId", newJString(networkId))
  if body != nil:
    body_613374 = body
  result = call_613372.call(path_613373, nil, nil, nil, body_613374)

var createNode* = Call_CreateNode_613358(name: "createNode",
                                      meth: HttpMethod.HttpPost,
                                      host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes",
                                      validator: validate_CreateNode_613359,
                                      base: "/", url: url_CreateNode_613360,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNodes_613337 = ref object of OpenApiRestCall_612658
proc url_ListNodes_613339(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListNodes_613338(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613340 = path.getOrDefault("memberId")
  valid_613340 = validateParameter(valid_613340, JString, required = true,
                                 default = nil)
  if valid_613340 != nil:
    section.add "memberId", valid_613340
  var valid_613341 = path.getOrDefault("networkId")
  valid_613341 = validateParameter(valid_613341, JString, required = true,
                                 default = nil)
  if valid_613341 != nil:
    section.add "networkId", valid_613341
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
  var valid_613342 = query.getOrDefault("nextToken")
  valid_613342 = validateParameter(valid_613342, JString, required = false,
                                 default = nil)
  if valid_613342 != nil:
    section.add "nextToken", valid_613342
  var valid_613343 = query.getOrDefault("MaxResults")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "MaxResults", valid_613343
  var valid_613344 = query.getOrDefault("NextToken")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "NextToken", valid_613344
  var valid_613345 = query.getOrDefault("status")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = newJString("CREATING"))
  if valid_613345 != nil:
    section.add "status", valid_613345
  var valid_613346 = query.getOrDefault("maxResults")
  valid_613346 = validateParameter(valid_613346, JInt, required = false, default = nil)
  if valid_613346 != nil:
    section.add "maxResults", valid_613346
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
  var valid_613347 = header.getOrDefault("X-Amz-Signature")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Signature", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Content-Sha256", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-Date")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-Date", valid_613349
  var valid_613350 = header.getOrDefault("X-Amz-Credential")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-Credential", valid_613350
  var valid_613351 = header.getOrDefault("X-Amz-Security-Token")
  valid_613351 = validateParameter(valid_613351, JString, required = false,
                                 default = nil)
  if valid_613351 != nil:
    section.add "X-Amz-Security-Token", valid_613351
  var valid_613352 = header.getOrDefault("X-Amz-Algorithm")
  valid_613352 = validateParameter(valid_613352, JString, required = false,
                                 default = nil)
  if valid_613352 != nil:
    section.add "X-Amz-Algorithm", valid_613352
  var valid_613353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "X-Amz-SignedHeaders", valid_613353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613354: Call_ListNodes_613337; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the nodes within a network.
  ## 
  let valid = call_613354.validator(path, query, header, formData, body)
  let scheme = call_613354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613354.url(scheme.get, call_613354.host, call_613354.base,
                         call_613354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613354, url, valid)

proc call*(call_613355: Call_ListNodes_613337; memberId: string; networkId: string;
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
  var path_613356 = newJObject()
  var query_613357 = newJObject()
  add(query_613357, "nextToken", newJString(nextToken))
  add(path_613356, "memberId", newJString(memberId))
  add(query_613357, "MaxResults", newJString(MaxResults))
  add(query_613357, "NextToken", newJString(NextToken))
  add(path_613356, "networkId", newJString(networkId))
  add(query_613357, "status", newJString(status))
  add(query_613357, "maxResults", newJInt(maxResults))
  result = call_613355.call(path_613356, query_613357, nil, nil, nil)

var listNodes* = Call_ListNodes_613337(name: "listNodes", meth: HttpMethod.HttpGet,
                                    host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes",
                                    validator: validate_ListNodes_613338,
                                    base: "/", url: url_ListNodes_613339,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProposal_613394 = ref object of OpenApiRestCall_612658
proc url_CreateProposal_613396(protocol: Scheme; host: string; base: string;
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

proc validate_CreateProposal_613395(path: JsonNode; query: JsonNode;
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
  var valid_613397 = path.getOrDefault("networkId")
  valid_613397 = validateParameter(valid_613397, JString, required = true,
                                 default = nil)
  if valid_613397 != nil:
    section.add "networkId", valid_613397
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
  var valid_613398 = header.getOrDefault("X-Amz-Signature")
  valid_613398 = validateParameter(valid_613398, JString, required = false,
                                 default = nil)
  if valid_613398 != nil:
    section.add "X-Amz-Signature", valid_613398
  var valid_613399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613399 = validateParameter(valid_613399, JString, required = false,
                                 default = nil)
  if valid_613399 != nil:
    section.add "X-Amz-Content-Sha256", valid_613399
  var valid_613400 = header.getOrDefault("X-Amz-Date")
  valid_613400 = validateParameter(valid_613400, JString, required = false,
                                 default = nil)
  if valid_613400 != nil:
    section.add "X-Amz-Date", valid_613400
  var valid_613401 = header.getOrDefault("X-Amz-Credential")
  valid_613401 = validateParameter(valid_613401, JString, required = false,
                                 default = nil)
  if valid_613401 != nil:
    section.add "X-Amz-Credential", valid_613401
  var valid_613402 = header.getOrDefault("X-Amz-Security-Token")
  valid_613402 = validateParameter(valid_613402, JString, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "X-Amz-Security-Token", valid_613402
  var valid_613403 = header.getOrDefault("X-Amz-Algorithm")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "X-Amz-Algorithm", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-SignedHeaders", valid_613404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613406: Call_CreateProposal_613394; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a proposal for a change to the network that other members of the network can vote on, for example, a proposal to add a new member to the network. Any member can create a proposal.
  ## 
  let valid = call_613406.validator(path, query, header, formData, body)
  let scheme = call_613406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613406.url(scheme.get, call_613406.host, call_613406.base,
                         call_613406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613406, url, valid)

proc call*(call_613407: Call_CreateProposal_613394; networkId: string; body: JsonNode): Recallable =
  ## createProposal
  ## Creates a proposal for a change to the network that other members of the network can vote on, for example, a proposal to add a new member to the network. Any member can create a proposal.
  ##   networkId: string (required)
  ##            :  The unique identifier of the network for which the proposal is made.
  ##   body: JObject (required)
  var path_613408 = newJObject()
  var body_613409 = newJObject()
  add(path_613408, "networkId", newJString(networkId))
  if body != nil:
    body_613409 = body
  result = call_613407.call(path_613408, nil, nil, nil, body_613409)

var createProposal* = Call_CreateProposal_613394(name: "createProposal",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals", validator: validate_CreateProposal_613395,
    base: "/", url: url_CreateProposal_613396, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProposals_613375 = ref object of OpenApiRestCall_612658
proc url_ListProposals_613377(protocol: Scheme; host: string; base: string;
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

proc validate_ListProposals_613376(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613378 = path.getOrDefault("networkId")
  valid_613378 = validateParameter(valid_613378, JString, required = true,
                                 default = nil)
  if valid_613378 != nil:
    section.add "networkId", valid_613378
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
  var valid_613379 = query.getOrDefault("nextToken")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "nextToken", valid_613379
  var valid_613380 = query.getOrDefault("MaxResults")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "MaxResults", valid_613380
  var valid_613381 = query.getOrDefault("NextToken")
  valid_613381 = validateParameter(valid_613381, JString, required = false,
                                 default = nil)
  if valid_613381 != nil:
    section.add "NextToken", valid_613381
  var valid_613382 = query.getOrDefault("maxResults")
  valid_613382 = validateParameter(valid_613382, JInt, required = false, default = nil)
  if valid_613382 != nil:
    section.add "maxResults", valid_613382
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
  var valid_613383 = header.getOrDefault("X-Amz-Signature")
  valid_613383 = validateParameter(valid_613383, JString, required = false,
                                 default = nil)
  if valid_613383 != nil:
    section.add "X-Amz-Signature", valid_613383
  var valid_613384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613384 = validateParameter(valid_613384, JString, required = false,
                                 default = nil)
  if valid_613384 != nil:
    section.add "X-Amz-Content-Sha256", valid_613384
  var valid_613385 = header.getOrDefault("X-Amz-Date")
  valid_613385 = validateParameter(valid_613385, JString, required = false,
                                 default = nil)
  if valid_613385 != nil:
    section.add "X-Amz-Date", valid_613385
  var valid_613386 = header.getOrDefault("X-Amz-Credential")
  valid_613386 = validateParameter(valid_613386, JString, required = false,
                                 default = nil)
  if valid_613386 != nil:
    section.add "X-Amz-Credential", valid_613386
  var valid_613387 = header.getOrDefault("X-Amz-Security-Token")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "X-Amz-Security-Token", valid_613387
  var valid_613388 = header.getOrDefault("X-Amz-Algorithm")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "X-Amz-Algorithm", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-SignedHeaders", valid_613389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613390: Call_ListProposals_613375; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a listing of proposals for the network.
  ## 
  let valid = call_613390.validator(path, query, header, formData, body)
  let scheme = call_613390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613390.url(scheme.get, call_613390.host, call_613390.base,
                         call_613390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613390, url, valid)

proc call*(call_613391: Call_ListProposals_613375; networkId: string;
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
  var path_613392 = newJObject()
  var query_613393 = newJObject()
  add(query_613393, "nextToken", newJString(nextToken))
  add(query_613393, "MaxResults", newJString(MaxResults))
  add(query_613393, "NextToken", newJString(NextToken))
  add(path_613392, "networkId", newJString(networkId))
  add(query_613393, "maxResults", newJInt(maxResults))
  result = call_613391.call(path_613392, query_613393, nil, nil, nil)

var listProposals* = Call_ListProposals_613375(name: "listProposals",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals", validator: validate_ListProposals_613376,
    base: "/", url: url_ListProposals_613377, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMember_613410 = ref object of OpenApiRestCall_612658
proc url_GetMember_613412(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetMember_613411(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613413 = path.getOrDefault("memberId")
  valid_613413 = validateParameter(valid_613413, JString, required = true,
                                 default = nil)
  if valid_613413 != nil:
    section.add "memberId", valid_613413
  var valid_613414 = path.getOrDefault("networkId")
  valid_613414 = validateParameter(valid_613414, JString, required = true,
                                 default = nil)
  if valid_613414 != nil:
    section.add "networkId", valid_613414
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
  var valid_613415 = header.getOrDefault("X-Amz-Signature")
  valid_613415 = validateParameter(valid_613415, JString, required = false,
                                 default = nil)
  if valid_613415 != nil:
    section.add "X-Amz-Signature", valid_613415
  var valid_613416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613416 = validateParameter(valid_613416, JString, required = false,
                                 default = nil)
  if valid_613416 != nil:
    section.add "X-Amz-Content-Sha256", valid_613416
  var valid_613417 = header.getOrDefault("X-Amz-Date")
  valid_613417 = validateParameter(valid_613417, JString, required = false,
                                 default = nil)
  if valid_613417 != nil:
    section.add "X-Amz-Date", valid_613417
  var valid_613418 = header.getOrDefault("X-Amz-Credential")
  valid_613418 = validateParameter(valid_613418, JString, required = false,
                                 default = nil)
  if valid_613418 != nil:
    section.add "X-Amz-Credential", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-Security-Token")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Security-Token", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-Algorithm")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Algorithm", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-SignedHeaders", valid_613421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613422: Call_GetMember_613410; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a member.
  ## 
  let valid = call_613422.validator(path, query, header, formData, body)
  let scheme = call_613422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613422.url(scheme.get, call_613422.host, call_613422.base,
                         call_613422.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613422, url, valid)

proc call*(call_613423: Call_GetMember_613410; memberId: string; networkId: string): Recallable =
  ## getMember
  ## Returns detailed information about a member.
  ##   memberId: string (required)
  ##           : The unique identifier of the member.
  ##   networkId: string (required)
  ##            : The unique identifier of the network to which the member belongs.
  var path_613424 = newJObject()
  add(path_613424, "memberId", newJString(memberId))
  add(path_613424, "networkId", newJString(networkId))
  result = call_613423.call(path_613424, nil, nil, nil, nil)

var getMember* = Call_GetMember_613410(name: "getMember", meth: HttpMethod.HttpGet,
                                    host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}",
                                    validator: validate_GetMember_613411,
                                    base: "/", url: url_GetMember_613412,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMember_613425 = ref object of OpenApiRestCall_612658
proc url_DeleteMember_613427(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMember_613426(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613428 = path.getOrDefault("memberId")
  valid_613428 = validateParameter(valid_613428, JString, required = true,
                                 default = nil)
  if valid_613428 != nil:
    section.add "memberId", valid_613428
  var valid_613429 = path.getOrDefault("networkId")
  valid_613429 = validateParameter(valid_613429, JString, required = true,
                                 default = nil)
  if valid_613429 != nil:
    section.add "networkId", valid_613429
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
  var valid_613430 = header.getOrDefault("X-Amz-Signature")
  valid_613430 = validateParameter(valid_613430, JString, required = false,
                                 default = nil)
  if valid_613430 != nil:
    section.add "X-Amz-Signature", valid_613430
  var valid_613431 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613431 = validateParameter(valid_613431, JString, required = false,
                                 default = nil)
  if valid_613431 != nil:
    section.add "X-Amz-Content-Sha256", valid_613431
  var valid_613432 = header.getOrDefault("X-Amz-Date")
  valid_613432 = validateParameter(valid_613432, JString, required = false,
                                 default = nil)
  if valid_613432 != nil:
    section.add "X-Amz-Date", valid_613432
  var valid_613433 = header.getOrDefault("X-Amz-Credential")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-Credential", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-Security-Token")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-Security-Token", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-Algorithm")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-Algorithm", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-SignedHeaders", valid_613436
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613437: Call_DeleteMember_613425; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a member. Deleting a member removes the member and all associated resources from the network. <code>DeleteMember</code> can only be called for a specified <code>MemberId</code> if the principal performing the action is associated with the AWS account that owns the member. In all other cases, the <code>DeleteMember</code> action is carried out as the result of an approved proposal to remove a member. If <code>MemberId</code> is the last member in a network specified by the last AWS account, the network is deleted also.
  ## 
  let valid = call_613437.validator(path, query, header, formData, body)
  let scheme = call_613437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613437.url(scheme.get, call_613437.host, call_613437.base,
                         call_613437.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613437, url, valid)

proc call*(call_613438: Call_DeleteMember_613425; memberId: string; networkId: string): Recallable =
  ## deleteMember
  ## Deletes a member. Deleting a member removes the member and all associated resources from the network. <code>DeleteMember</code> can only be called for a specified <code>MemberId</code> if the principal performing the action is associated with the AWS account that owns the member. In all other cases, the <code>DeleteMember</code> action is carried out as the result of an approved proposal to remove a member. If <code>MemberId</code> is the last member in a network specified by the last AWS account, the network is deleted also.
  ##   memberId: string (required)
  ##           : The unique identifier of the member to remove.
  ##   networkId: string (required)
  ##            : The unique identifier of the network from which the member is removed.
  var path_613439 = newJObject()
  add(path_613439, "memberId", newJString(memberId))
  add(path_613439, "networkId", newJString(networkId))
  result = call_613438.call(path_613439, nil, nil, nil, nil)

var deleteMember* = Call_DeleteMember_613425(name: "deleteMember",
    meth: HttpMethod.HttpDelete, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/members/{memberId}",
    validator: validate_DeleteMember_613426, base: "/", url: url_DeleteMember_613427,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNode_613440 = ref object of OpenApiRestCall_612658
proc url_GetNode_613442(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetNode_613441(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613443 = path.getOrDefault("memberId")
  valid_613443 = validateParameter(valid_613443, JString, required = true,
                                 default = nil)
  if valid_613443 != nil:
    section.add "memberId", valid_613443
  var valid_613444 = path.getOrDefault("networkId")
  valid_613444 = validateParameter(valid_613444, JString, required = true,
                                 default = nil)
  if valid_613444 != nil:
    section.add "networkId", valid_613444
  var valid_613445 = path.getOrDefault("nodeId")
  valid_613445 = validateParameter(valid_613445, JString, required = true,
                                 default = nil)
  if valid_613445 != nil:
    section.add "nodeId", valid_613445
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
  var valid_613446 = header.getOrDefault("X-Amz-Signature")
  valid_613446 = validateParameter(valid_613446, JString, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "X-Amz-Signature", valid_613446
  var valid_613447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "X-Amz-Content-Sha256", valid_613447
  var valid_613448 = header.getOrDefault("X-Amz-Date")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-Date", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Credential")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Credential", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-Security-Token")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Security-Token", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-Algorithm")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Algorithm", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-SignedHeaders", valid_613452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613453: Call_GetNode_613440; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a peer node.
  ## 
  let valid = call_613453.validator(path, query, header, formData, body)
  let scheme = call_613453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613453.url(scheme.get, call_613453.host, call_613453.base,
                         call_613453.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613453, url, valid)

proc call*(call_613454: Call_GetNode_613440; memberId: string; networkId: string;
          nodeId: string): Recallable =
  ## getNode
  ## Returns detailed information about a peer node.
  ##   memberId: string (required)
  ##           : The unique identifier of the member that owns the node.
  ##   networkId: string (required)
  ##            : The unique identifier of the network to which the node belongs.
  ##   nodeId: string (required)
  ##         : The unique identifier of the node.
  var path_613455 = newJObject()
  add(path_613455, "memberId", newJString(memberId))
  add(path_613455, "networkId", newJString(networkId))
  add(path_613455, "nodeId", newJString(nodeId))
  result = call_613454.call(path_613455, nil, nil, nil, nil)

var getNode* = Call_GetNode_613440(name: "getNode", meth: HttpMethod.HttpGet,
                                host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes/{nodeId}",
                                validator: validate_GetNode_613441, base: "/",
                                url: url_GetNode_613442,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNode_613456 = ref object of OpenApiRestCall_612658
proc url_DeleteNode_613458(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteNode_613457(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613459 = path.getOrDefault("memberId")
  valid_613459 = validateParameter(valid_613459, JString, required = true,
                                 default = nil)
  if valid_613459 != nil:
    section.add "memberId", valid_613459
  var valid_613460 = path.getOrDefault("networkId")
  valid_613460 = validateParameter(valid_613460, JString, required = true,
                                 default = nil)
  if valid_613460 != nil:
    section.add "networkId", valid_613460
  var valid_613461 = path.getOrDefault("nodeId")
  valid_613461 = validateParameter(valid_613461, JString, required = true,
                                 default = nil)
  if valid_613461 != nil:
    section.add "nodeId", valid_613461
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
  var valid_613462 = header.getOrDefault("X-Amz-Signature")
  valid_613462 = validateParameter(valid_613462, JString, required = false,
                                 default = nil)
  if valid_613462 != nil:
    section.add "X-Amz-Signature", valid_613462
  var valid_613463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-Content-Sha256", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Date")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Date", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-Credential")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Credential", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Security-Token")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Security-Token", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Algorithm")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Algorithm", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-SignedHeaders", valid_613468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613469: Call_DeleteNode_613456; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a peer node from a member that your AWS account owns. All data on the node is lost and cannot be recovered.
  ## 
  let valid = call_613469.validator(path, query, header, formData, body)
  let scheme = call_613469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613469.url(scheme.get, call_613469.host, call_613469.base,
                         call_613469.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613469, url, valid)

proc call*(call_613470: Call_DeleteNode_613456; memberId: string; networkId: string;
          nodeId: string): Recallable =
  ## deleteNode
  ## Deletes a peer node from a member that your AWS account owns. All data on the node is lost and cannot be recovered.
  ##   memberId: string (required)
  ##           : The unique identifier of the member that owns this node.
  ##   networkId: string (required)
  ##            : The unique identifier of the network that the node belongs to.
  ##   nodeId: string (required)
  ##         : The unique identifier of the node.
  var path_613471 = newJObject()
  add(path_613471, "memberId", newJString(memberId))
  add(path_613471, "networkId", newJString(networkId))
  add(path_613471, "nodeId", newJString(nodeId))
  result = call_613470.call(path_613471, nil, nil, nil, nil)

var deleteNode* = Call_DeleteNode_613456(name: "deleteNode",
                                      meth: HttpMethod.HttpDelete,
                                      host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes/{nodeId}",
                                      validator: validate_DeleteNode_613457,
                                      base: "/", url: url_DeleteNode_613458,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNetwork_613472 = ref object of OpenApiRestCall_612658
proc url_GetNetwork_613474(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetNetwork_613473(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613475 = path.getOrDefault("networkId")
  valid_613475 = validateParameter(valid_613475, JString, required = true,
                                 default = nil)
  if valid_613475 != nil:
    section.add "networkId", valid_613475
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
  var valid_613476 = header.getOrDefault("X-Amz-Signature")
  valid_613476 = validateParameter(valid_613476, JString, required = false,
                                 default = nil)
  if valid_613476 != nil:
    section.add "X-Amz-Signature", valid_613476
  var valid_613477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613477 = validateParameter(valid_613477, JString, required = false,
                                 default = nil)
  if valid_613477 != nil:
    section.add "X-Amz-Content-Sha256", valid_613477
  var valid_613478 = header.getOrDefault("X-Amz-Date")
  valid_613478 = validateParameter(valid_613478, JString, required = false,
                                 default = nil)
  if valid_613478 != nil:
    section.add "X-Amz-Date", valid_613478
  var valid_613479 = header.getOrDefault("X-Amz-Credential")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "X-Amz-Credential", valid_613479
  var valid_613480 = header.getOrDefault("X-Amz-Security-Token")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Security-Token", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-Algorithm")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Algorithm", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-SignedHeaders", valid_613482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613483: Call_GetNetwork_613472; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a network.
  ## 
  let valid = call_613483.validator(path, query, header, formData, body)
  let scheme = call_613483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613483.url(scheme.get, call_613483.host, call_613483.base,
                         call_613483.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613483, url, valid)

proc call*(call_613484: Call_GetNetwork_613472; networkId: string): Recallable =
  ## getNetwork
  ## Returns detailed information about a network.
  ##   networkId: string (required)
  ##            : The unique identifier of the network to get information about.
  var path_613485 = newJObject()
  add(path_613485, "networkId", newJString(networkId))
  result = call_613484.call(path_613485, nil, nil, nil, nil)

var getNetwork* = Call_GetNetwork_613472(name: "getNetwork",
                                      meth: HttpMethod.HttpGet,
                                      host: "managedblockchain.amazonaws.com",
                                      route: "/networks/{networkId}",
                                      validator: validate_GetNetwork_613473,
                                      base: "/", url: url_GetNetwork_613474,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProposal_613486 = ref object of OpenApiRestCall_612658
proc url_GetProposal_613488(protocol: Scheme; host: string; base: string;
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

proc validate_GetProposal_613487(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613489 = path.getOrDefault("proposalId")
  valid_613489 = validateParameter(valid_613489, JString, required = true,
                                 default = nil)
  if valid_613489 != nil:
    section.add "proposalId", valid_613489
  var valid_613490 = path.getOrDefault("networkId")
  valid_613490 = validateParameter(valid_613490, JString, required = true,
                                 default = nil)
  if valid_613490 != nil:
    section.add "networkId", valid_613490
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
  var valid_613491 = header.getOrDefault("X-Amz-Signature")
  valid_613491 = validateParameter(valid_613491, JString, required = false,
                                 default = nil)
  if valid_613491 != nil:
    section.add "X-Amz-Signature", valid_613491
  var valid_613492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613492 = validateParameter(valid_613492, JString, required = false,
                                 default = nil)
  if valid_613492 != nil:
    section.add "X-Amz-Content-Sha256", valid_613492
  var valid_613493 = header.getOrDefault("X-Amz-Date")
  valid_613493 = validateParameter(valid_613493, JString, required = false,
                                 default = nil)
  if valid_613493 != nil:
    section.add "X-Amz-Date", valid_613493
  var valid_613494 = header.getOrDefault("X-Amz-Credential")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "X-Amz-Credential", valid_613494
  var valid_613495 = header.getOrDefault("X-Amz-Security-Token")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-Security-Token", valid_613495
  var valid_613496 = header.getOrDefault("X-Amz-Algorithm")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "X-Amz-Algorithm", valid_613496
  var valid_613497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "X-Amz-SignedHeaders", valid_613497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613498: Call_GetProposal_613486; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a proposal.
  ## 
  let valid = call_613498.validator(path, query, header, formData, body)
  let scheme = call_613498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613498.url(scheme.get, call_613498.host, call_613498.base,
                         call_613498.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613498, url, valid)

proc call*(call_613499: Call_GetProposal_613486; proposalId: string;
          networkId: string): Recallable =
  ## getProposal
  ## Returns detailed information about a proposal.
  ##   proposalId: string (required)
  ##             : The unique identifier of the proposal.
  ##   networkId: string (required)
  ##            : The unique identifier of the network for which the proposal is made.
  var path_613500 = newJObject()
  add(path_613500, "proposalId", newJString(proposalId))
  add(path_613500, "networkId", newJString(networkId))
  result = call_613499.call(path_613500, nil, nil, nil, nil)

var getProposal* = Call_GetProposal_613486(name: "getProposal",
                                        meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/proposals/{proposalId}",
                                        validator: validate_GetProposal_613487,
                                        base: "/", url: url_GetProposal_613488,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_613501 = ref object of OpenApiRestCall_612658
proc url_ListInvitations_613503(protocol: Scheme; host: string; base: string;
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

proc validate_ListInvitations_613502(path: JsonNode; query: JsonNode;
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
  var valid_613504 = query.getOrDefault("nextToken")
  valid_613504 = validateParameter(valid_613504, JString, required = false,
                                 default = nil)
  if valid_613504 != nil:
    section.add "nextToken", valid_613504
  var valid_613505 = query.getOrDefault("MaxResults")
  valid_613505 = validateParameter(valid_613505, JString, required = false,
                                 default = nil)
  if valid_613505 != nil:
    section.add "MaxResults", valid_613505
  var valid_613506 = query.getOrDefault("NextToken")
  valid_613506 = validateParameter(valid_613506, JString, required = false,
                                 default = nil)
  if valid_613506 != nil:
    section.add "NextToken", valid_613506
  var valid_613507 = query.getOrDefault("maxResults")
  valid_613507 = validateParameter(valid_613507, JInt, required = false, default = nil)
  if valid_613507 != nil:
    section.add "maxResults", valid_613507
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
  var valid_613508 = header.getOrDefault("X-Amz-Signature")
  valid_613508 = validateParameter(valid_613508, JString, required = false,
                                 default = nil)
  if valid_613508 != nil:
    section.add "X-Amz-Signature", valid_613508
  var valid_613509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613509 = validateParameter(valid_613509, JString, required = false,
                                 default = nil)
  if valid_613509 != nil:
    section.add "X-Amz-Content-Sha256", valid_613509
  var valid_613510 = header.getOrDefault("X-Amz-Date")
  valid_613510 = validateParameter(valid_613510, JString, required = false,
                                 default = nil)
  if valid_613510 != nil:
    section.add "X-Amz-Date", valid_613510
  var valid_613511 = header.getOrDefault("X-Amz-Credential")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = nil)
  if valid_613511 != nil:
    section.add "X-Amz-Credential", valid_613511
  var valid_613512 = header.getOrDefault("X-Amz-Security-Token")
  valid_613512 = validateParameter(valid_613512, JString, required = false,
                                 default = nil)
  if valid_613512 != nil:
    section.add "X-Amz-Security-Token", valid_613512
  var valid_613513 = header.getOrDefault("X-Amz-Algorithm")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "X-Amz-Algorithm", valid_613513
  var valid_613514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "X-Amz-SignedHeaders", valid_613514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613515: Call_ListInvitations_613501; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a listing of all invitations made on the specified network.
  ## 
  let valid = call_613515.validator(path, query, header, formData, body)
  let scheme = call_613515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613515.url(scheme.get, call_613515.host, call_613515.base,
                         call_613515.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613515, url, valid)

proc call*(call_613516: Call_ListInvitations_613501; nextToken: string = "";
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
  var query_613517 = newJObject()
  add(query_613517, "nextToken", newJString(nextToken))
  add(query_613517, "MaxResults", newJString(MaxResults))
  add(query_613517, "NextToken", newJString(NextToken))
  add(query_613517, "maxResults", newJInt(maxResults))
  result = call_613516.call(nil, query_613517, nil, nil, nil)

var listInvitations* = Call_ListInvitations_613501(name: "listInvitations",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/invitations", validator: validate_ListInvitations_613502, base: "/",
    url: url_ListInvitations_613503, schemes: {Scheme.Https, Scheme.Http})
type
  Call_VoteOnProposal_613538 = ref object of OpenApiRestCall_612658
proc url_VoteOnProposal_613540(protocol: Scheme; host: string; base: string;
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

proc validate_VoteOnProposal_613539(path: JsonNode; query: JsonNode;
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
  var valid_613541 = path.getOrDefault("proposalId")
  valid_613541 = validateParameter(valid_613541, JString, required = true,
                                 default = nil)
  if valid_613541 != nil:
    section.add "proposalId", valid_613541
  var valid_613542 = path.getOrDefault("networkId")
  valid_613542 = validateParameter(valid_613542, JString, required = true,
                                 default = nil)
  if valid_613542 != nil:
    section.add "networkId", valid_613542
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
  var valid_613543 = header.getOrDefault("X-Amz-Signature")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "X-Amz-Signature", valid_613543
  var valid_613544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "X-Amz-Content-Sha256", valid_613544
  var valid_613545 = header.getOrDefault("X-Amz-Date")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "X-Amz-Date", valid_613545
  var valid_613546 = header.getOrDefault("X-Amz-Credential")
  valid_613546 = validateParameter(valid_613546, JString, required = false,
                                 default = nil)
  if valid_613546 != nil:
    section.add "X-Amz-Credential", valid_613546
  var valid_613547 = header.getOrDefault("X-Amz-Security-Token")
  valid_613547 = validateParameter(valid_613547, JString, required = false,
                                 default = nil)
  if valid_613547 != nil:
    section.add "X-Amz-Security-Token", valid_613547
  var valid_613548 = header.getOrDefault("X-Amz-Algorithm")
  valid_613548 = validateParameter(valid_613548, JString, required = false,
                                 default = nil)
  if valid_613548 != nil:
    section.add "X-Amz-Algorithm", valid_613548
  var valid_613549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613549 = validateParameter(valid_613549, JString, required = false,
                                 default = nil)
  if valid_613549 != nil:
    section.add "X-Amz-SignedHeaders", valid_613549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613551: Call_VoteOnProposal_613538; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Casts a vote for a specified <code>ProposalId</code> on behalf of a member. The member to vote as, specified by <code>VoterMemberId</code>, must be in the same AWS account as the principal that calls the action.
  ## 
  let valid = call_613551.validator(path, query, header, formData, body)
  let scheme = call_613551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613551.url(scheme.get, call_613551.host, call_613551.base,
                         call_613551.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613551, url, valid)

proc call*(call_613552: Call_VoteOnProposal_613538; proposalId: string;
          networkId: string; body: JsonNode): Recallable =
  ## voteOnProposal
  ## Casts a vote for a specified <code>ProposalId</code> on behalf of a member. The member to vote as, specified by <code>VoterMemberId</code>, must be in the same AWS account as the principal that calls the action.
  ##   proposalId: string (required)
  ##             :  The unique identifier of the proposal. 
  ##   networkId: string (required)
  ##            :  The unique identifier of the network. 
  ##   body: JObject (required)
  var path_613553 = newJObject()
  var body_613554 = newJObject()
  add(path_613553, "proposalId", newJString(proposalId))
  add(path_613553, "networkId", newJString(networkId))
  if body != nil:
    body_613554 = body
  result = call_613552.call(path_613553, nil, nil, nil, body_613554)

var voteOnProposal* = Call_VoteOnProposal_613538(name: "voteOnProposal",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals/{proposalId}/votes",
    validator: validate_VoteOnProposal_613539, base: "/", url: url_VoteOnProposal_613540,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProposalVotes_613518 = ref object of OpenApiRestCall_612658
proc url_ListProposalVotes_613520(protocol: Scheme; host: string; base: string;
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

proc validate_ListProposalVotes_613519(path: JsonNode; query: JsonNode;
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
  var valid_613521 = path.getOrDefault("proposalId")
  valid_613521 = validateParameter(valid_613521, JString, required = true,
                                 default = nil)
  if valid_613521 != nil:
    section.add "proposalId", valid_613521
  var valid_613522 = path.getOrDefault("networkId")
  valid_613522 = validateParameter(valid_613522, JString, required = true,
                                 default = nil)
  if valid_613522 != nil:
    section.add "networkId", valid_613522
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
  var valid_613523 = query.getOrDefault("nextToken")
  valid_613523 = validateParameter(valid_613523, JString, required = false,
                                 default = nil)
  if valid_613523 != nil:
    section.add "nextToken", valid_613523
  var valid_613524 = query.getOrDefault("MaxResults")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "MaxResults", valid_613524
  var valid_613525 = query.getOrDefault("NextToken")
  valid_613525 = validateParameter(valid_613525, JString, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "NextToken", valid_613525
  var valid_613526 = query.getOrDefault("maxResults")
  valid_613526 = validateParameter(valid_613526, JInt, required = false, default = nil)
  if valid_613526 != nil:
    section.add "maxResults", valid_613526
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
  var valid_613527 = header.getOrDefault("X-Amz-Signature")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-Signature", valid_613527
  var valid_613528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-Content-Sha256", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-Date")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-Date", valid_613529
  var valid_613530 = header.getOrDefault("X-Amz-Credential")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-Credential", valid_613530
  var valid_613531 = header.getOrDefault("X-Amz-Security-Token")
  valid_613531 = validateParameter(valid_613531, JString, required = false,
                                 default = nil)
  if valid_613531 != nil:
    section.add "X-Amz-Security-Token", valid_613531
  var valid_613532 = header.getOrDefault("X-Amz-Algorithm")
  valid_613532 = validateParameter(valid_613532, JString, required = false,
                                 default = nil)
  if valid_613532 != nil:
    section.add "X-Amz-Algorithm", valid_613532
  var valid_613533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613533 = validateParameter(valid_613533, JString, required = false,
                                 default = nil)
  if valid_613533 != nil:
    section.add "X-Amz-SignedHeaders", valid_613533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613534: Call_ListProposalVotes_613518; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the listing of votes for a specified proposal, including the value of each vote and the unique identifier of the member that cast the vote.
  ## 
  let valid = call_613534.validator(path, query, header, formData, body)
  let scheme = call_613534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613534.url(scheme.get, call_613534.host, call_613534.base,
                         call_613534.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613534, url, valid)

proc call*(call_613535: Call_ListProposalVotes_613518; proposalId: string;
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
  var path_613536 = newJObject()
  var query_613537 = newJObject()
  add(query_613537, "nextToken", newJString(nextToken))
  add(query_613537, "MaxResults", newJString(MaxResults))
  add(path_613536, "proposalId", newJString(proposalId))
  add(query_613537, "NextToken", newJString(NextToken))
  add(path_613536, "networkId", newJString(networkId))
  add(query_613537, "maxResults", newJInt(maxResults))
  result = call_613535.call(path_613536, query_613537, nil, nil, nil)

var listProposalVotes* = Call_ListProposalVotes_613518(name: "listProposalVotes",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals/{proposalId}/votes",
    validator: validate_ListProposalVotes_613519, base: "/",
    url: url_ListProposalVotes_613520, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectInvitation_613555 = ref object of OpenApiRestCall_612658
proc url_RejectInvitation_613557(protocol: Scheme; host: string; base: string;
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

proc validate_RejectInvitation_613556(path: JsonNode; query: JsonNode;
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
  var valid_613558 = path.getOrDefault("invitationId")
  valid_613558 = validateParameter(valid_613558, JString, required = true,
                                 default = nil)
  if valid_613558 != nil:
    section.add "invitationId", valid_613558
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
  var valid_613559 = header.getOrDefault("X-Amz-Signature")
  valid_613559 = validateParameter(valid_613559, JString, required = false,
                                 default = nil)
  if valid_613559 != nil:
    section.add "X-Amz-Signature", valid_613559
  var valid_613560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613560 = validateParameter(valid_613560, JString, required = false,
                                 default = nil)
  if valid_613560 != nil:
    section.add "X-Amz-Content-Sha256", valid_613560
  var valid_613561 = header.getOrDefault("X-Amz-Date")
  valid_613561 = validateParameter(valid_613561, JString, required = false,
                                 default = nil)
  if valid_613561 != nil:
    section.add "X-Amz-Date", valid_613561
  var valid_613562 = header.getOrDefault("X-Amz-Credential")
  valid_613562 = validateParameter(valid_613562, JString, required = false,
                                 default = nil)
  if valid_613562 != nil:
    section.add "X-Amz-Credential", valid_613562
  var valid_613563 = header.getOrDefault("X-Amz-Security-Token")
  valid_613563 = validateParameter(valid_613563, JString, required = false,
                                 default = nil)
  if valid_613563 != nil:
    section.add "X-Amz-Security-Token", valid_613563
  var valid_613564 = header.getOrDefault("X-Amz-Algorithm")
  valid_613564 = validateParameter(valid_613564, JString, required = false,
                                 default = nil)
  if valid_613564 != nil:
    section.add "X-Amz-Algorithm", valid_613564
  var valid_613565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613565 = validateParameter(valid_613565, JString, required = false,
                                 default = nil)
  if valid_613565 != nil:
    section.add "X-Amz-SignedHeaders", valid_613565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613566: Call_RejectInvitation_613555; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Rejects an invitation to join a network. This action can be called by a principal in an AWS account that has received an invitation to create a member and join a network.
  ## 
  let valid = call_613566.validator(path, query, header, formData, body)
  let scheme = call_613566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613566.url(scheme.get, call_613566.host, call_613566.base,
                         call_613566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613566, url, valid)

proc call*(call_613567: Call_RejectInvitation_613555; invitationId: string): Recallable =
  ## rejectInvitation
  ## Rejects an invitation to join a network. This action can be called by a principal in an AWS account that has received an invitation to create a member and join a network.
  ##   invitationId: string (required)
  ##               : The unique identifier of the invitation to reject.
  var path_613568 = newJObject()
  add(path_613568, "invitationId", newJString(invitationId))
  result = call_613567.call(path_613568, nil, nil, nil, nil)

var rejectInvitation* = Call_RejectInvitation_613555(name: "rejectInvitation",
    meth: HttpMethod.HttpDelete, host: "managedblockchain.amazonaws.com",
    route: "/invitations/{invitationId}", validator: validate_RejectInvitation_613556,
    base: "/", url: url_RejectInvitation_613557,
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
