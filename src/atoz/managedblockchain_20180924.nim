
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateMember_603094 = ref object of OpenApiRestCall_602466
proc url_CreateMember_603096(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_CreateMember_603095(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603097 = path.getOrDefault("networkId")
  valid_603097 = validateParameter(valid_603097, JString, required = true,
                                 default = nil)
  if valid_603097 != nil:
    section.add "networkId", valid_603097
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603098 = header.getOrDefault("X-Amz-Date")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-Date", valid_603098
  var valid_603099 = header.getOrDefault("X-Amz-Security-Token")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-Security-Token", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Content-Sha256", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-Algorithm")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-Algorithm", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-Signature")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Signature", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-SignedHeaders", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-Credential")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-Credential", valid_603104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603106: Call_CreateMember_603094; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a member within a Managed Blockchain network.
  ## 
  let valid = call_603106.validator(path, query, header, formData, body)
  let scheme = call_603106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603106.url(scheme.get, call_603106.host, call_603106.base,
                         call_603106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603106, url, valid)

proc call*(call_603107: Call_CreateMember_603094; networkId: string; body: JsonNode): Recallable =
  ## createMember
  ## Creates a member within a Managed Blockchain network.
  ##   networkId: string (required)
  ##            : The unique identifier of the network in which the member is created.
  ##   body: JObject (required)
  var path_603108 = newJObject()
  var body_603109 = newJObject()
  add(path_603108, "networkId", newJString(networkId))
  if body != nil:
    body_603109 = body
  result = call_603107.call(path_603108, nil, nil, nil, body_603109)

var createMember* = Call_CreateMember_603094(name: "createMember",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/members", validator: validate_CreateMember_603095,
    base: "/", url: url_CreateMember_603096, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_602803 = ref object of OpenApiRestCall_602466
proc url_ListMembers_602805(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListMembers_602804(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602931 = path.getOrDefault("networkId")
  valid_602931 = validateParameter(valid_602931, JString, required = true,
                                 default = nil)
  if valid_602931 != nil:
    section.add "networkId", valid_602931
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of members to return in the request.
  ##   nextToken: JString
  ##            : The pagination token that indicates the next set of results to retrieve.
  ##   name: JString
  ##       : The optional name of the member to list.
  ##   isOwned: JBool
  ##          : An optional Boolean value. If provided, the request is limited either to members that the current AWS account owns (<code>true</code>) or that other AWS accounts own (<code>false</code>). If omitted, all members are listed.
  ##   status: JString
  ##         : An optional status specifier. If provided, only members currently in this status are listed.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_602932 = query.getOrDefault("NextToken")
  valid_602932 = validateParameter(valid_602932, JString, required = false,
                                 default = nil)
  if valid_602932 != nil:
    section.add "NextToken", valid_602932
  var valid_602933 = query.getOrDefault("maxResults")
  valid_602933 = validateParameter(valid_602933, JInt, required = false, default = nil)
  if valid_602933 != nil:
    section.add "maxResults", valid_602933
  var valid_602934 = query.getOrDefault("nextToken")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "nextToken", valid_602934
  var valid_602935 = query.getOrDefault("name")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "name", valid_602935
  var valid_602936 = query.getOrDefault("isOwned")
  valid_602936 = validateParameter(valid_602936, JBool, required = false, default = nil)
  if valid_602936 != nil:
    section.add "isOwned", valid_602936
  var valid_602950 = query.getOrDefault("status")
  valid_602950 = validateParameter(valid_602950, JString, required = false,
                                 default = newJString("CREATING"))
  if valid_602950 != nil:
    section.add "status", valid_602950
  var valid_602951 = query.getOrDefault("MaxResults")
  valid_602951 = validateParameter(valid_602951, JString, required = false,
                                 default = nil)
  if valid_602951 != nil:
    section.add "MaxResults", valid_602951
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602952 = header.getOrDefault("X-Amz-Date")
  valid_602952 = validateParameter(valid_602952, JString, required = false,
                                 default = nil)
  if valid_602952 != nil:
    section.add "X-Amz-Date", valid_602952
  var valid_602953 = header.getOrDefault("X-Amz-Security-Token")
  valid_602953 = validateParameter(valid_602953, JString, required = false,
                                 default = nil)
  if valid_602953 != nil:
    section.add "X-Amz-Security-Token", valid_602953
  var valid_602954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602954 = validateParameter(valid_602954, JString, required = false,
                                 default = nil)
  if valid_602954 != nil:
    section.add "X-Amz-Content-Sha256", valid_602954
  var valid_602955 = header.getOrDefault("X-Amz-Algorithm")
  valid_602955 = validateParameter(valid_602955, JString, required = false,
                                 default = nil)
  if valid_602955 != nil:
    section.add "X-Amz-Algorithm", valid_602955
  var valid_602956 = header.getOrDefault("X-Amz-Signature")
  valid_602956 = validateParameter(valid_602956, JString, required = false,
                                 default = nil)
  if valid_602956 != nil:
    section.add "X-Amz-Signature", valid_602956
  var valid_602957 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602957 = validateParameter(valid_602957, JString, required = false,
                                 default = nil)
  if valid_602957 != nil:
    section.add "X-Amz-SignedHeaders", valid_602957
  var valid_602958 = header.getOrDefault("X-Amz-Credential")
  valid_602958 = validateParameter(valid_602958, JString, required = false,
                                 default = nil)
  if valid_602958 != nil:
    section.add "X-Amz-Credential", valid_602958
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602981: Call_ListMembers_602803; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a listing of the members in a network and properties of their configurations.
  ## 
  let valid = call_602981.validator(path, query, header, formData, body)
  let scheme = call_602981.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602981.url(scheme.get, call_602981.host, call_602981.base,
                         call_602981.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602981, url, valid)

proc call*(call_603052: Call_ListMembers_602803; networkId: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          name: string = ""; isOwned: bool = false; status: string = "CREATING";
          MaxResults: string = ""): Recallable =
  ## listMembers
  ## Returns a listing of the members in a network and properties of their configurations.
  ##   networkId: string (required)
  ##            : The unique identifier of the network for which to list members.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of members to return in the request.
  ##   nextToken: string
  ##            : The pagination token that indicates the next set of results to retrieve.
  ##   name: string
  ##       : The optional name of the member to list.
  ##   isOwned: bool
  ##          : An optional Boolean value. If provided, the request is limited either to members that the current AWS account owns (<code>true</code>) or that other AWS accounts own (<code>false</code>). If omitted, all members are listed.
  ##   status: string
  ##         : An optional status specifier. If provided, only members currently in this status are listed.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_603053 = newJObject()
  var query_603055 = newJObject()
  add(path_603053, "networkId", newJString(networkId))
  add(query_603055, "NextToken", newJString(NextToken))
  add(query_603055, "maxResults", newJInt(maxResults))
  add(query_603055, "nextToken", newJString(nextToken))
  add(query_603055, "name", newJString(name))
  add(query_603055, "isOwned", newJBool(isOwned))
  add(query_603055, "status", newJString(status))
  add(query_603055, "MaxResults", newJString(MaxResults))
  result = call_603052.call(path_603053, query_603055, nil, nil, nil)

var listMembers* = Call_ListMembers_602803(name: "listMembers",
                                        meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
                                        route: "/networks/{networkId}/members",
                                        validator: validate_ListMembers_602804,
                                        base: "/", url: url_ListMembers_602805,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNetwork_603130 = ref object of OpenApiRestCall_602466
proc url_CreateNetwork_603132(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateNetwork_603131(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603133 = header.getOrDefault("X-Amz-Date")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Date", valid_603133
  var valid_603134 = header.getOrDefault("X-Amz-Security-Token")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "X-Amz-Security-Token", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Content-Sha256", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Algorithm")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Algorithm", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Signature")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Signature", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-SignedHeaders", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Credential")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Credential", valid_603139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603141: Call_CreateNetwork_603130; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new blockchain network using Amazon Managed Blockchain.
  ## 
  let valid = call_603141.validator(path, query, header, formData, body)
  let scheme = call_603141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603141.url(scheme.get, call_603141.host, call_603141.base,
                         call_603141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603141, url, valid)

proc call*(call_603142: Call_CreateNetwork_603130; body: JsonNode): Recallable =
  ## createNetwork
  ## Creates a new blockchain network using Amazon Managed Blockchain.
  ##   body: JObject (required)
  var body_603143 = newJObject()
  if body != nil:
    body_603143 = body
  result = call_603142.call(nil, nil, nil, nil, body_603143)

var createNetwork* = Call_CreateNetwork_603130(name: "createNetwork",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks", validator: validate_CreateNetwork_603131, base: "/",
    url: url_CreateNetwork_603132, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNetworks_603110 = ref object of OpenApiRestCall_602466
proc url_ListNetworks_603112(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListNetworks_603111(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of networks to list.
  ##   nextToken: JString
  ##            : The pagination token that indicates the next set of results to retrieve.
  ##   name: JString
  ##       : The name of the network.
  ##   status: JString
  ##         : An optional status specifier. If provided, only networks currently in this status are listed.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603113 = query.getOrDefault("framework")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = newJString("HYPERLEDGER_FABRIC"))
  if valid_603113 != nil:
    section.add "framework", valid_603113
  var valid_603114 = query.getOrDefault("NextToken")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "NextToken", valid_603114
  var valid_603115 = query.getOrDefault("maxResults")
  valid_603115 = validateParameter(valid_603115, JInt, required = false, default = nil)
  if valid_603115 != nil:
    section.add "maxResults", valid_603115
  var valid_603116 = query.getOrDefault("nextToken")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "nextToken", valid_603116
  var valid_603117 = query.getOrDefault("name")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "name", valid_603117
  var valid_603118 = query.getOrDefault("status")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = newJString("CREATING"))
  if valid_603118 != nil:
    section.add "status", valid_603118
  var valid_603119 = query.getOrDefault("MaxResults")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "MaxResults", valid_603119
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603120 = header.getOrDefault("X-Amz-Date")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Date", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Security-Token")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Security-Token", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Content-Sha256", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Algorithm")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Algorithm", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Signature")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Signature", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-SignedHeaders", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-Credential")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-Credential", valid_603126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603127: Call_ListNetworks_603110; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the networks in which the current AWS account has members.
  ## 
  let valid = call_603127.validator(path, query, header, formData, body)
  let scheme = call_603127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603127.url(scheme.get, call_603127.host, call_603127.base,
                         call_603127.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603127, url, valid)

proc call*(call_603128: Call_ListNetworks_603110;
          framework: string = "HYPERLEDGER_FABRIC"; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""; name: string = "";
          status: string = "CREATING"; MaxResults: string = ""): Recallable =
  ## listNetworks
  ## Returns information about the networks in which the current AWS account has members.
  ##   framework: string
  ##            : An optional framework specifier. If provided, only networks of this framework type are listed.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of networks to list.
  ##   nextToken: string
  ##            : The pagination token that indicates the next set of results to retrieve.
  ##   name: string
  ##       : The name of the network.
  ##   status: string
  ##         : An optional status specifier. If provided, only networks currently in this status are listed.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603129 = newJObject()
  add(query_603129, "framework", newJString(framework))
  add(query_603129, "NextToken", newJString(NextToken))
  add(query_603129, "maxResults", newJInt(maxResults))
  add(query_603129, "nextToken", newJString(nextToken))
  add(query_603129, "name", newJString(name))
  add(query_603129, "status", newJString(status))
  add(query_603129, "MaxResults", newJString(MaxResults))
  result = call_603128.call(nil, query_603129, nil, nil, nil)

var listNetworks* = Call_ListNetworks_603110(name: "listNetworks",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks", validator: validate_ListNetworks_603111, base: "/",
    url: url_ListNetworks_603112, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNode_603165 = ref object of OpenApiRestCall_602466
proc url_CreateNode_603167(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_CreateNode_603166(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a peer node in a member.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   networkId: JString (required)
  ##            : The unique identifier of the network in which this node runs.
  ##   memberId: JString (required)
  ##           : The unique identifier of the member that owns this node.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `networkId` field"
  var valid_603168 = path.getOrDefault("networkId")
  valid_603168 = validateParameter(valid_603168, JString, required = true,
                                 default = nil)
  if valid_603168 != nil:
    section.add "networkId", valid_603168
  var valid_603169 = path.getOrDefault("memberId")
  valid_603169 = validateParameter(valid_603169, JString, required = true,
                                 default = nil)
  if valid_603169 != nil:
    section.add "memberId", valid_603169
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603170 = header.getOrDefault("X-Amz-Date")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Date", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-Security-Token")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-Security-Token", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Content-Sha256", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-Algorithm")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-Algorithm", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-Signature")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-Signature", valid_603174
  var valid_603175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-SignedHeaders", valid_603175
  var valid_603176 = header.getOrDefault("X-Amz-Credential")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-Credential", valid_603176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603178: Call_CreateNode_603165; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a peer node in a member.
  ## 
  let valid = call_603178.validator(path, query, header, formData, body)
  let scheme = call_603178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603178.url(scheme.get, call_603178.host, call_603178.base,
                         call_603178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603178, url, valid)

proc call*(call_603179: Call_CreateNode_603165; networkId: string; memberId: string;
          body: JsonNode): Recallable =
  ## createNode
  ## Creates a peer node in a member.
  ##   networkId: string (required)
  ##            : The unique identifier of the network in which this node runs.
  ##   memberId: string (required)
  ##           : The unique identifier of the member that owns this node.
  ##   body: JObject (required)
  var path_603180 = newJObject()
  var body_603181 = newJObject()
  add(path_603180, "networkId", newJString(networkId))
  add(path_603180, "memberId", newJString(memberId))
  if body != nil:
    body_603181 = body
  result = call_603179.call(path_603180, nil, nil, nil, body_603181)

var createNode* = Call_CreateNode_603165(name: "createNode",
                                      meth: HttpMethod.HttpPost,
                                      host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes",
                                      validator: validate_CreateNode_603166,
                                      base: "/", url: url_CreateNode_603167,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNodes_603144 = ref object of OpenApiRestCall_602466
proc url_ListNodes_603146(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_ListNodes_603145(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about the nodes within a network.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   networkId: JString (required)
  ##            : The unique identifier of the network for which to list nodes.
  ##   memberId: JString (required)
  ##           : The unique identifier of the member who owns the nodes to list.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `networkId` field"
  var valid_603147 = path.getOrDefault("networkId")
  valid_603147 = validateParameter(valid_603147, JString, required = true,
                                 default = nil)
  if valid_603147 != nil:
    section.add "networkId", valid_603147
  var valid_603148 = path.getOrDefault("memberId")
  valid_603148 = validateParameter(valid_603148, JString, required = true,
                                 default = nil)
  if valid_603148 != nil:
    section.add "memberId", valid_603148
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of nodes to list.
  ##   nextToken: JString
  ##            : The pagination token that indicates the next set of results to retrieve.
  ##   status: JString
  ##         : An optional status specifier. If provided, only nodes currently in this status are listed.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603149 = query.getOrDefault("NextToken")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "NextToken", valid_603149
  var valid_603150 = query.getOrDefault("maxResults")
  valid_603150 = validateParameter(valid_603150, JInt, required = false, default = nil)
  if valid_603150 != nil:
    section.add "maxResults", valid_603150
  var valid_603151 = query.getOrDefault("nextToken")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "nextToken", valid_603151
  var valid_603152 = query.getOrDefault("status")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = newJString("CREATING"))
  if valid_603152 != nil:
    section.add "status", valid_603152
  var valid_603153 = query.getOrDefault("MaxResults")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "MaxResults", valid_603153
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603154 = header.getOrDefault("X-Amz-Date")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Date", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Security-Token")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Security-Token", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Content-Sha256", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Algorithm")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Algorithm", valid_603157
  var valid_603158 = header.getOrDefault("X-Amz-Signature")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "X-Amz-Signature", valid_603158
  var valid_603159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "X-Amz-SignedHeaders", valid_603159
  var valid_603160 = header.getOrDefault("X-Amz-Credential")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "X-Amz-Credential", valid_603160
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603161: Call_ListNodes_603144; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the nodes within a network.
  ## 
  let valid = call_603161.validator(path, query, header, formData, body)
  let scheme = call_603161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603161.url(scheme.get, call_603161.host, call_603161.base,
                         call_603161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603161, url, valid)

proc call*(call_603162: Call_ListNodes_603144; networkId: string; memberId: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          status: string = "CREATING"; MaxResults: string = ""): Recallable =
  ## listNodes
  ## Returns information about the nodes within a network.
  ##   networkId: string (required)
  ##            : The unique identifier of the network for which to list nodes.
  ##   memberId: string (required)
  ##           : The unique identifier of the member who owns the nodes to list.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of nodes to list.
  ##   nextToken: string
  ##            : The pagination token that indicates the next set of results to retrieve.
  ##   status: string
  ##         : An optional status specifier. If provided, only nodes currently in this status are listed.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_603163 = newJObject()
  var query_603164 = newJObject()
  add(path_603163, "networkId", newJString(networkId))
  add(path_603163, "memberId", newJString(memberId))
  add(query_603164, "NextToken", newJString(NextToken))
  add(query_603164, "maxResults", newJInt(maxResults))
  add(query_603164, "nextToken", newJString(nextToken))
  add(query_603164, "status", newJString(status))
  add(query_603164, "MaxResults", newJString(MaxResults))
  result = call_603162.call(path_603163, query_603164, nil, nil, nil)

var listNodes* = Call_ListNodes_603144(name: "listNodes", meth: HttpMethod.HttpGet,
                                    host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes",
                                    validator: validate_ListNodes_603145,
                                    base: "/", url: url_ListNodes_603146,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProposal_603201 = ref object of OpenApiRestCall_602466
proc url_CreateProposal_603203(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_CreateProposal_603202(path: JsonNode; query: JsonNode;
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
  var valid_603204 = path.getOrDefault("networkId")
  valid_603204 = validateParameter(valid_603204, JString, required = true,
                                 default = nil)
  if valid_603204 != nil:
    section.add "networkId", valid_603204
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603205 = header.getOrDefault("X-Amz-Date")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-Date", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-Security-Token")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Security-Token", valid_603206
  var valid_603207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-Content-Sha256", valid_603207
  var valid_603208 = header.getOrDefault("X-Amz-Algorithm")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-Algorithm", valid_603208
  var valid_603209 = header.getOrDefault("X-Amz-Signature")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "X-Amz-Signature", valid_603209
  var valid_603210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-SignedHeaders", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Credential")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Credential", valid_603211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603213: Call_CreateProposal_603201; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a proposal for a change to the network that other members of the network can vote on, for example, a proposal to add a new member to the network. Any member can create a proposal.
  ## 
  let valid = call_603213.validator(path, query, header, formData, body)
  let scheme = call_603213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603213.url(scheme.get, call_603213.host, call_603213.base,
                         call_603213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603213, url, valid)

proc call*(call_603214: Call_CreateProposal_603201; networkId: string; body: JsonNode): Recallable =
  ## createProposal
  ## Creates a proposal for a change to the network that other members of the network can vote on, for example, a proposal to add a new member to the network. Any member can create a proposal.
  ##   networkId: string (required)
  ##            :  The unique identifier of the network for which the proposal is made.
  ##   body: JObject (required)
  var path_603215 = newJObject()
  var body_603216 = newJObject()
  add(path_603215, "networkId", newJString(networkId))
  if body != nil:
    body_603216 = body
  result = call_603214.call(path_603215, nil, nil, nil, body_603216)

var createProposal* = Call_CreateProposal_603201(name: "createProposal",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals", validator: validate_CreateProposal_603202,
    base: "/", url: url_CreateProposal_603203, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProposals_603182 = ref object of OpenApiRestCall_602466
proc url_ListProposals_603184(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListProposals_603183(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603185 = path.getOrDefault("networkId")
  valid_603185 = validateParameter(valid_603185, JString, required = true,
                                 default = nil)
  if valid_603185 != nil:
    section.add "networkId", valid_603185
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             :  The maximum number of proposals to return. 
  ##   nextToken: JString
  ##            :  The pagination token that indicates the next set of results to retrieve. 
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603186 = query.getOrDefault("NextToken")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "NextToken", valid_603186
  var valid_603187 = query.getOrDefault("maxResults")
  valid_603187 = validateParameter(valid_603187, JInt, required = false, default = nil)
  if valid_603187 != nil:
    section.add "maxResults", valid_603187
  var valid_603188 = query.getOrDefault("nextToken")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "nextToken", valid_603188
  var valid_603189 = query.getOrDefault("MaxResults")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "MaxResults", valid_603189
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603190 = header.getOrDefault("X-Amz-Date")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Date", valid_603190
  var valid_603191 = header.getOrDefault("X-Amz-Security-Token")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-Security-Token", valid_603191
  var valid_603192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Content-Sha256", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-Algorithm")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-Algorithm", valid_603193
  var valid_603194 = header.getOrDefault("X-Amz-Signature")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "X-Amz-Signature", valid_603194
  var valid_603195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-SignedHeaders", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Credential")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Credential", valid_603196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603197: Call_ListProposals_603182; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a listing of proposals for the network.
  ## 
  let valid = call_603197.validator(path, query, header, formData, body)
  let scheme = call_603197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603197.url(scheme.get, call_603197.host, call_603197.base,
                         call_603197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603197, url, valid)

proc call*(call_603198: Call_ListProposals_603182; networkId: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listProposals
  ## Returns a listing of proposals for the network.
  ##   networkId: string (required)
  ##            :  The unique identifier of the network. 
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             :  The maximum number of proposals to return. 
  ##   nextToken: string
  ##            :  The pagination token that indicates the next set of results to retrieve. 
  ##   MaxResults: string
  ##             : Pagination limit
  var path_603199 = newJObject()
  var query_603200 = newJObject()
  add(path_603199, "networkId", newJString(networkId))
  add(query_603200, "NextToken", newJString(NextToken))
  add(query_603200, "maxResults", newJInt(maxResults))
  add(query_603200, "nextToken", newJString(nextToken))
  add(query_603200, "MaxResults", newJString(MaxResults))
  result = call_603198.call(path_603199, query_603200, nil, nil, nil)

var listProposals* = Call_ListProposals_603182(name: "listProposals",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals", validator: validate_ListProposals_603183,
    base: "/", url: url_ListProposals_603184, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMember_603217 = ref object of OpenApiRestCall_602466
proc url_GetMember_603219(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_GetMember_603218(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns detailed information about a member.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   networkId: JString (required)
  ##            : The unique identifier of the network to which the member belongs.
  ##   memberId: JString (required)
  ##           : The unique identifier of the member.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `networkId` field"
  var valid_603220 = path.getOrDefault("networkId")
  valid_603220 = validateParameter(valid_603220, JString, required = true,
                                 default = nil)
  if valid_603220 != nil:
    section.add "networkId", valid_603220
  var valid_603221 = path.getOrDefault("memberId")
  valid_603221 = validateParameter(valid_603221, JString, required = true,
                                 default = nil)
  if valid_603221 != nil:
    section.add "memberId", valid_603221
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603222 = header.getOrDefault("X-Amz-Date")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-Date", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-Security-Token")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-Security-Token", valid_603223
  var valid_603224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "X-Amz-Content-Sha256", valid_603224
  var valid_603225 = header.getOrDefault("X-Amz-Algorithm")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Algorithm", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Signature")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Signature", valid_603226
  var valid_603227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-SignedHeaders", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Credential")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Credential", valid_603228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603229: Call_GetMember_603217; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a member.
  ## 
  let valid = call_603229.validator(path, query, header, formData, body)
  let scheme = call_603229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603229.url(scheme.get, call_603229.host, call_603229.base,
                         call_603229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603229, url, valid)

proc call*(call_603230: Call_GetMember_603217; networkId: string; memberId: string): Recallable =
  ## getMember
  ## Returns detailed information about a member.
  ##   networkId: string (required)
  ##            : The unique identifier of the network to which the member belongs.
  ##   memberId: string (required)
  ##           : The unique identifier of the member.
  var path_603231 = newJObject()
  add(path_603231, "networkId", newJString(networkId))
  add(path_603231, "memberId", newJString(memberId))
  result = call_603230.call(path_603231, nil, nil, nil, nil)

var getMember* = Call_GetMember_603217(name: "getMember", meth: HttpMethod.HttpGet,
                                    host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}",
                                    validator: validate_GetMember_603218,
                                    base: "/", url: url_GetMember_603219,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMember_603232 = ref object of OpenApiRestCall_602466
proc url_DeleteMember_603234(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteMember_603233(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a member. Deleting a member removes the member and all associated resources from the network. <code>DeleteMember</code> can only be called for a specified <code>MemberId</code> if the principal performing the action is associated with the AWS account that owns the member. In all other cases, the <code>DeleteMember</code> action is carried out as the result of an approved proposal to remove a member. If <code>MemberId</code> is the last member in a network specified by the last AWS account, the network is deleted also.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   networkId: JString (required)
  ##            : The unique identifier of the network from which the member is removed.
  ##   memberId: JString (required)
  ##           : The unique identifier of the member to remove.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `networkId` field"
  var valid_603235 = path.getOrDefault("networkId")
  valid_603235 = validateParameter(valid_603235, JString, required = true,
                                 default = nil)
  if valid_603235 != nil:
    section.add "networkId", valid_603235
  var valid_603236 = path.getOrDefault("memberId")
  valid_603236 = validateParameter(valid_603236, JString, required = true,
                                 default = nil)
  if valid_603236 != nil:
    section.add "memberId", valid_603236
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603237 = header.getOrDefault("X-Amz-Date")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-Date", valid_603237
  var valid_603238 = header.getOrDefault("X-Amz-Security-Token")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "X-Amz-Security-Token", valid_603238
  var valid_603239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-Content-Sha256", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Algorithm")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Algorithm", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Signature")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Signature", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-SignedHeaders", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Credential")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Credential", valid_603243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603244: Call_DeleteMember_603232; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a member. Deleting a member removes the member and all associated resources from the network. <code>DeleteMember</code> can only be called for a specified <code>MemberId</code> if the principal performing the action is associated with the AWS account that owns the member. In all other cases, the <code>DeleteMember</code> action is carried out as the result of an approved proposal to remove a member. If <code>MemberId</code> is the last member in a network specified by the last AWS account, the network is deleted also.
  ## 
  let valid = call_603244.validator(path, query, header, formData, body)
  let scheme = call_603244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603244.url(scheme.get, call_603244.host, call_603244.base,
                         call_603244.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603244, url, valid)

proc call*(call_603245: Call_DeleteMember_603232; networkId: string; memberId: string): Recallable =
  ## deleteMember
  ## Deletes a member. Deleting a member removes the member and all associated resources from the network. <code>DeleteMember</code> can only be called for a specified <code>MemberId</code> if the principal performing the action is associated with the AWS account that owns the member. In all other cases, the <code>DeleteMember</code> action is carried out as the result of an approved proposal to remove a member. If <code>MemberId</code> is the last member in a network specified by the last AWS account, the network is deleted also.
  ##   networkId: string (required)
  ##            : The unique identifier of the network from which the member is removed.
  ##   memberId: string (required)
  ##           : The unique identifier of the member to remove.
  var path_603246 = newJObject()
  add(path_603246, "networkId", newJString(networkId))
  add(path_603246, "memberId", newJString(memberId))
  result = call_603245.call(path_603246, nil, nil, nil, nil)

var deleteMember* = Call_DeleteMember_603232(name: "deleteMember",
    meth: HttpMethod.HttpDelete, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/members/{memberId}",
    validator: validate_DeleteMember_603233, base: "/", url: url_DeleteMember_603234,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNode_603247 = ref object of OpenApiRestCall_602466
proc url_GetNode_603249(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_GetNode_603248(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns detailed information about a peer node.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   networkId: JString (required)
  ##            : The unique identifier of the network to which the node belongs.
  ##   memberId: JString (required)
  ##           : The unique identifier of the member that owns the node.
  ##   nodeId: JString (required)
  ##         : The unique identifier of the node.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `networkId` field"
  var valid_603250 = path.getOrDefault("networkId")
  valid_603250 = validateParameter(valid_603250, JString, required = true,
                                 default = nil)
  if valid_603250 != nil:
    section.add "networkId", valid_603250
  var valid_603251 = path.getOrDefault("memberId")
  valid_603251 = validateParameter(valid_603251, JString, required = true,
                                 default = nil)
  if valid_603251 != nil:
    section.add "memberId", valid_603251
  var valid_603252 = path.getOrDefault("nodeId")
  valid_603252 = validateParameter(valid_603252, JString, required = true,
                                 default = nil)
  if valid_603252 != nil:
    section.add "nodeId", valid_603252
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603253 = header.getOrDefault("X-Amz-Date")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "X-Amz-Date", valid_603253
  var valid_603254 = header.getOrDefault("X-Amz-Security-Token")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-Security-Token", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Content-Sha256", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Algorithm")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Algorithm", valid_603256
  var valid_603257 = header.getOrDefault("X-Amz-Signature")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-Signature", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-SignedHeaders", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Credential")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Credential", valid_603259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603260: Call_GetNode_603247; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a peer node.
  ## 
  let valid = call_603260.validator(path, query, header, formData, body)
  let scheme = call_603260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603260.url(scheme.get, call_603260.host, call_603260.base,
                         call_603260.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603260, url, valid)

proc call*(call_603261: Call_GetNode_603247; networkId: string; memberId: string;
          nodeId: string): Recallable =
  ## getNode
  ## Returns detailed information about a peer node.
  ##   networkId: string (required)
  ##            : The unique identifier of the network to which the node belongs.
  ##   memberId: string (required)
  ##           : The unique identifier of the member that owns the node.
  ##   nodeId: string (required)
  ##         : The unique identifier of the node.
  var path_603262 = newJObject()
  add(path_603262, "networkId", newJString(networkId))
  add(path_603262, "memberId", newJString(memberId))
  add(path_603262, "nodeId", newJString(nodeId))
  result = call_603261.call(path_603262, nil, nil, nil, nil)

var getNode* = Call_GetNode_603247(name: "getNode", meth: HttpMethod.HttpGet,
                                host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes/{nodeId}",
                                validator: validate_GetNode_603248, base: "/",
                                url: url_GetNode_603249,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNode_603263 = ref object of OpenApiRestCall_602466
proc url_DeleteNode_603265(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_DeleteNode_603264(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a peer node from a member that your AWS account owns. All data on the node is lost and cannot be recovered.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   networkId: JString (required)
  ##            : The unique identifier of the network that the node belongs to.
  ##   memberId: JString (required)
  ##           : The unique identifier of the member that owns this node.
  ##   nodeId: JString (required)
  ##         : The unique identifier of the node.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `networkId` field"
  var valid_603266 = path.getOrDefault("networkId")
  valid_603266 = validateParameter(valid_603266, JString, required = true,
                                 default = nil)
  if valid_603266 != nil:
    section.add "networkId", valid_603266
  var valid_603267 = path.getOrDefault("memberId")
  valid_603267 = validateParameter(valid_603267, JString, required = true,
                                 default = nil)
  if valid_603267 != nil:
    section.add "memberId", valid_603267
  var valid_603268 = path.getOrDefault("nodeId")
  valid_603268 = validateParameter(valid_603268, JString, required = true,
                                 default = nil)
  if valid_603268 != nil:
    section.add "nodeId", valid_603268
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603269 = header.getOrDefault("X-Amz-Date")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "X-Amz-Date", valid_603269
  var valid_603270 = header.getOrDefault("X-Amz-Security-Token")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Security-Token", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Content-Sha256", valid_603271
  var valid_603272 = header.getOrDefault("X-Amz-Algorithm")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "X-Amz-Algorithm", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-Signature")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Signature", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-SignedHeaders", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Credential")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Credential", valid_603275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603276: Call_DeleteNode_603263; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a peer node from a member that your AWS account owns. All data on the node is lost and cannot be recovered.
  ## 
  let valid = call_603276.validator(path, query, header, formData, body)
  let scheme = call_603276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603276.url(scheme.get, call_603276.host, call_603276.base,
                         call_603276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603276, url, valid)

proc call*(call_603277: Call_DeleteNode_603263; networkId: string; memberId: string;
          nodeId: string): Recallable =
  ## deleteNode
  ## Deletes a peer node from a member that your AWS account owns. All data on the node is lost and cannot be recovered.
  ##   networkId: string (required)
  ##            : The unique identifier of the network that the node belongs to.
  ##   memberId: string (required)
  ##           : The unique identifier of the member that owns this node.
  ##   nodeId: string (required)
  ##         : The unique identifier of the node.
  var path_603278 = newJObject()
  add(path_603278, "networkId", newJString(networkId))
  add(path_603278, "memberId", newJString(memberId))
  add(path_603278, "nodeId", newJString(nodeId))
  result = call_603277.call(path_603278, nil, nil, nil, nil)

var deleteNode* = Call_DeleteNode_603263(name: "deleteNode",
                                      meth: HttpMethod.HttpDelete,
                                      host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes/{nodeId}",
                                      validator: validate_DeleteNode_603264,
                                      base: "/", url: url_DeleteNode_603265,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNetwork_603279 = ref object of OpenApiRestCall_602466
proc url_GetNetwork_603281(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_GetNetwork_603280(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603282 = path.getOrDefault("networkId")
  valid_603282 = validateParameter(valid_603282, JString, required = true,
                                 default = nil)
  if valid_603282 != nil:
    section.add "networkId", valid_603282
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603283 = header.getOrDefault("X-Amz-Date")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-Date", valid_603283
  var valid_603284 = header.getOrDefault("X-Amz-Security-Token")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "X-Amz-Security-Token", valid_603284
  var valid_603285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Content-Sha256", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Algorithm")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Algorithm", valid_603286
  var valid_603287 = header.getOrDefault("X-Amz-Signature")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-Signature", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-SignedHeaders", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Credential")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Credential", valid_603289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603290: Call_GetNetwork_603279; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a network.
  ## 
  let valid = call_603290.validator(path, query, header, formData, body)
  let scheme = call_603290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603290.url(scheme.get, call_603290.host, call_603290.base,
                         call_603290.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603290, url, valid)

proc call*(call_603291: Call_GetNetwork_603279; networkId: string): Recallable =
  ## getNetwork
  ## Returns detailed information about a network.
  ##   networkId: string (required)
  ##            : The unique identifier of the network to get information about.
  var path_603292 = newJObject()
  add(path_603292, "networkId", newJString(networkId))
  result = call_603291.call(path_603292, nil, nil, nil, nil)

var getNetwork* = Call_GetNetwork_603279(name: "getNetwork",
                                      meth: HttpMethod.HttpGet,
                                      host: "managedblockchain.amazonaws.com",
                                      route: "/networks/{networkId}",
                                      validator: validate_GetNetwork_603280,
                                      base: "/", url: url_GetNetwork_603281,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProposal_603293 = ref object of OpenApiRestCall_602466
proc url_GetProposal_603295(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetProposal_603294(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns detailed information about a proposal.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   networkId: JString (required)
  ##            : The unique identifier of the network for which the proposal is made.
  ##   proposalId: JString (required)
  ##             : The unique identifier of the proposal.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `networkId` field"
  var valid_603296 = path.getOrDefault("networkId")
  valid_603296 = validateParameter(valid_603296, JString, required = true,
                                 default = nil)
  if valid_603296 != nil:
    section.add "networkId", valid_603296
  var valid_603297 = path.getOrDefault("proposalId")
  valid_603297 = validateParameter(valid_603297, JString, required = true,
                                 default = nil)
  if valid_603297 != nil:
    section.add "proposalId", valid_603297
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603298 = header.getOrDefault("X-Amz-Date")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "X-Amz-Date", valid_603298
  var valid_603299 = header.getOrDefault("X-Amz-Security-Token")
  valid_603299 = validateParameter(valid_603299, JString, required = false,
                                 default = nil)
  if valid_603299 != nil:
    section.add "X-Amz-Security-Token", valid_603299
  var valid_603300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Content-Sha256", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Algorithm")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Algorithm", valid_603301
  var valid_603302 = header.getOrDefault("X-Amz-Signature")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-Signature", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-SignedHeaders", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Credential")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Credential", valid_603304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603305: Call_GetProposal_603293; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a proposal.
  ## 
  let valid = call_603305.validator(path, query, header, formData, body)
  let scheme = call_603305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603305.url(scheme.get, call_603305.host, call_603305.base,
                         call_603305.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603305, url, valid)

proc call*(call_603306: Call_GetProposal_603293; networkId: string;
          proposalId: string): Recallable =
  ## getProposal
  ## Returns detailed information about a proposal.
  ##   networkId: string (required)
  ##            : The unique identifier of the network for which the proposal is made.
  ##   proposalId: string (required)
  ##             : The unique identifier of the proposal.
  var path_603307 = newJObject()
  add(path_603307, "networkId", newJString(networkId))
  add(path_603307, "proposalId", newJString(proposalId))
  result = call_603306.call(path_603307, nil, nil, nil, nil)

var getProposal* = Call_GetProposal_603293(name: "getProposal",
                                        meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/proposals/{proposalId}",
                                        validator: validate_GetProposal_603294,
                                        base: "/", url: url_GetProposal_603295,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_603308 = ref object of OpenApiRestCall_602466
proc url_ListInvitations_603310(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListInvitations_603309(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns a listing of all invitations made on the specified network.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of invitations to return.
  ##   nextToken: JString
  ##            : The pagination token that indicates the next set of results to retrieve.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603311 = query.getOrDefault("NextToken")
  valid_603311 = validateParameter(valid_603311, JString, required = false,
                                 default = nil)
  if valid_603311 != nil:
    section.add "NextToken", valid_603311
  var valid_603312 = query.getOrDefault("maxResults")
  valid_603312 = validateParameter(valid_603312, JInt, required = false, default = nil)
  if valid_603312 != nil:
    section.add "maxResults", valid_603312
  var valid_603313 = query.getOrDefault("nextToken")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "nextToken", valid_603313
  var valid_603314 = query.getOrDefault("MaxResults")
  valid_603314 = validateParameter(valid_603314, JString, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "MaxResults", valid_603314
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603315 = header.getOrDefault("X-Amz-Date")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Date", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-Security-Token")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Security-Token", valid_603316
  var valid_603317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "X-Amz-Content-Sha256", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-Algorithm")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Algorithm", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Signature")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Signature", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-SignedHeaders", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-Credential")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-Credential", valid_603321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603322: Call_ListInvitations_603308; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a listing of all invitations made on the specified network.
  ## 
  let valid = call_603322.validator(path, query, header, formData, body)
  let scheme = call_603322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603322.url(scheme.get, call_603322.host, call_603322.base,
                         call_603322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603322, url, valid)

proc call*(call_603323: Call_ListInvitations_603308; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listInvitations
  ## Returns a listing of all invitations made on the specified network.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of invitations to return.
  ##   nextToken: string
  ##            : The pagination token that indicates the next set of results to retrieve.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603324 = newJObject()
  add(query_603324, "NextToken", newJString(NextToken))
  add(query_603324, "maxResults", newJInt(maxResults))
  add(query_603324, "nextToken", newJString(nextToken))
  add(query_603324, "MaxResults", newJString(MaxResults))
  result = call_603323.call(nil, query_603324, nil, nil, nil)

var listInvitations* = Call_ListInvitations_603308(name: "listInvitations",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/invitations", validator: validate_ListInvitations_603309, base: "/",
    url: url_ListInvitations_603310, schemes: {Scheme.Https, Scheme.Http})
type
  Call_VoteOnProposal_603345 = ref object of OpenApiRestCall_602466
proc url_VoteOnProposal_603347(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_VoteOnProposal_603346(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Casts a vote for a specified <code>ProposalId</code> on behalf of a member. The member to vote as, specified by <code>VoterMemberId</code>, must be in the same AWS account as the principal that calls the action.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   networkId: JString (required)
  ##            :  The unique identifier of the network. 
  ##   proposalId: JString (required)
  ##             :  The unique identifier of the proposal. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `networkId` field"
  var valid_603348 = path.getOrDefault("networkId")
  valid_603348 = validateParameter(valid_603348, JString, required = true,
                                 default = nil)
  if valid_603348 != nil:
    section.add "networkId", valid_603348
  var valid_603349 = path.getOrDefault("proposalId")
  valid_603349 = validateParameter(valid_603349, JString, required = true,
                                 default = nil)
  if valid_603349 != nil:
    section.add "proposalId", valid_603349
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603350 = header.getOrDefault("X-Amz-Date")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Date", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-Security-Token")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-Security-Token", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Content-Sha256", valid_603352
  var valid_603353 = header.getOrDefault("X-Amz-Algorithm")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "X-Amz-Algorithm", valid_603353
  var valid_603354 = header.getOrDefault("X-Amz-Signature")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "X-Amz-Signature", valid_603354
  var valid_603355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "X-Amz-SignedHeaders", valid_603355
  var valid_603356 = header.getOrDefault("X-Amz-Credential")
  valid_603356 = validateParameter(valid_603356, JString, required = false,
                                 default = nil)
  if valid_603356 != nil:
    section.add "X-Amz-Credential", valid_603356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603358: Call_VoteOnProposal_603345; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Casts a vote for a specified <code>ProposalId</code> on behalf of a member. The member to vote as, specified by <code>VoterMemberId</code>, must be in the same AWS account as the principal that calls the action.
  ## 
  let valid = call_603358.validator(path, query, header, formData, body)
  let scheme = call_603358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603358.url(scheme.get, call_603358.host, call_603358.base,
                         call_603358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603358, url, valid)

proc call*(call_603359: Call_VoteOnProposal_603345; networkId: string;
          proposalId: string; body: JsonNode): Recallable =
  ## voteOnProposal
  ## Casts a vote for a specified <code>ProposalId</code> on behalf of a member. The member to vote as, specified by <code>VoterMemberId</code>, must be in the same AWS account as the principal that calls the action.
  ##   networkId: string (required)
  ##            :  The unique identifier of the network. 
  ##   proposalId: string (required)
  ##             :  The unique identifier of the proposal. 
  ##   body: JObject (required)
  var path_603360 = newJObject()
  var body_603361 = newJObject()
  add(path_603360, "networkId", newJString(networkId))
  add(path_603360, "proposalId", newJString(proposalId))
  if body != nil:
    body_603361 = body
  result = call_603359.call(path_603360, nil, nil, nil, body_603361)

var voteOnProposal* = Call_VoteOnProposal_603345(name: "voteOnProposal",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals/{proposalId}/votes",
    validator: validate_VoteOnProposal_603346, base: "/", url: url_VoteOnProposal_603347,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProposalVotes_603325 = ref object of OpenApiRestCall_602466
proc url_ListProposalVotes_603327(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListProposalVotes_603326(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns the listing of votes for a specified proposal, including the value of each vote and the unique identifier of the member that cast the vote.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   networkId: JString (required)
  ##            :  The unique identifier of the network. 
  ##   proposalId: JString (required)
  ##             :  The unique identifier of the proposal. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `networkId` field"
  var valid_603328 = path.getOrDefault("networkId")
  valid_603328 = validateParameter(valid_603328, JString, required = true,
                                 default = nil)
  if valid_603328 != nil:
    section.add "networkId", valid_603328
  var valid_603329 = path.getOrDefault("proposalId")
  valid_603329 = validateParameter(valid_603329, JString, required = true,
                                 default = nil)
  if valid_603329 != nil:
    section.add "proposalId", valid_603329
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             :  The maximum number of votes to return. 
  ##   nextToken: JString
  ##            :  The pagination token that indicates the next set of results to retrieve. 
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603330 = query.getOrDefault("NextToken")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "NextToken", valid_603330
  var valid_603331 = query.getOrDefault("maxResults")
  valid_603331 = validateParameter(valid_603331, JInt, required = false, default = nil)
  if valid_603331 != nil:
    section.add "maxResults", valid_603331
  var valid_603332 = query.getOrDefault("nextToken")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "nextToken", valid_603332
  var valid_603333 = query.getOrDefault("MaxResults")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "MaxResults", valid_603333
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603334 = header.getOrDefault("X-Amz-Date")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Date", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-Security-Token")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Security-Token", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-Content-Sha256", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Algorithm")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Algorithm", valid_603337
  var valid_603338 = header.getOrDefault("X-Amz-Signature")
  valid_603338 = validateParameter(valid_603338, JString, required = false,
                                 default = nil)
  if valid_603338 != nil:
    section.add "X-Amz-Signature", valid_603338
  var valid_603339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "X-Amz-SignedHeaders", valid_603339
  var valid_603340 = header.getOrDefault("X-Amz-Credential")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "X-Amz-Credential", valid_603340
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603341: Call_ListProposalVotes_603325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the listing of votes for a specified proposal, including the value of each vote and the unique identifier of the member that cast the vote.
  ## 
  let valid = call_603341.validator(path, query, header, formData, body)
  let scheme = call_603341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603341.url(scheme.get, call_603341.host, call_603341.base,
                         call_603341.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603341, url, valid)

proc call*(call_603342: Call_ListProposalVotes_603325; networkId: string;
          proposalId: string; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listProposalVotes
  ## Returns the listing of votes for a specified proposal, including the value of each vote and the unique identifier of the member that cast the vote.
  ##   networkId: string (required)
  ##            :  The unique identifier of the network. 
  ##   proposalId: string (required)
  ##             :  The unique identifier of the proposal. 
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             :  The maximum number of votes to return. 
  ##   nextToken: string
  ##            :  The pagination token that indicates the next set of results to retrieve. 
  ##   MaxResults: string
  ##             : Pagination limit
  var path_603343 = newJObject()
  var query_603344 = newJObject()
  add(path_603343, "networkId", newJString(networkId))
  add(path_603343, "proposalId", newJString(proposalId))
  add(query_603344, "NextToken", newJString(NextToken))
  add(query_603344, "maxResults", newJInt(maxResults))
  add(query_603344, "nextToken", newJString(nextToken))
  add(query_603344, "MaxResults", newJString(MaxResults))
  result = call_603342.call(path_603343, query_603344, nil, nil, nil)

var listProposalVotes* = Call_ListProposalVotes_603325(name: "listProposalVotes",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals/{proposalId}/votes",
    validator: validate_ListProposalVotes_603326, base: "/",
    url: url_ListProposalVotes_603327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectInvitation_603362 = ref object of OpenApiRestCall_602466
proc url_RejectInvitation_603364(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_RejectInvitation_603363(path: JsonNode; query: JsonNode;
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
  var valid_603365 = path.getOrDefault("invitationId")
  valid_603365 = validateParameter(valid_603365, JString, required = true,
                                 default = nil)
  if valid_603365 != nil:
    section.add "invitationId", valid_603365
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603366 = header.getOrDefault("X-Amz-Date")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-Date", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-Security-Token")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-Security-Token", valid_603367
  var valid_603368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603368 = validateParameter(valid_603368, JString, required = false,
                                 default = nil)
  if valid_603368 != nil:
    section.add "X-Amz-Content-Sha256", valid_603368
  var valid_603369 = header.getOrDefault("X-Amz-Algorithm")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "X-Amz-Algorithm", valid_603369
  var valid_603370 = header.getOrDefault("X-Amz-Signature")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "X-Amz-Signature", valid_603370
  var valid_603371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603371 = validateParameter(valid_603371, JString, required = false,
                                 default = nil)
  if valid_603371 != nil:
    section.add "X-Amz-SignedHeaders", valid_603371
  var valid_603372 = header.getOrDefault("X-Amz-Credential")
  valid_603372 = validateParameter(valid_603372, JString, required = false,
                                 default = nil)
  if valid_603372 != nil:
    section.add "X-Amz-Credential", valid_603372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603373: Call_RejectInvitation_603362; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Rejects an invitation to join a network. This action can be called by a principal in an AWS account that has received an invitation to create a member and join a network.
  ## 
  let valid = call_603373.validator(path, query, header, formData, body)
  let scheme = call_603373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603373.url(scheme.get, call_603373.host, call_603373.base,
                         call_603373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603373, url, valid)

proc call*(call_603374: Call_RejectInvitation_603362; invitationId: string): Recallable =
  ## rejectInvitation
  ## Rejects an invitation to join a network. This action can be called by a principal in an AWS account that has received an invitation to create a member and join a network.
  ##   invitationId: string (required)
  ##               : The unique identifier of the invitation to reject.
  var path_603375 = newJObject()
  add(path_603375, "invitationId", newJString(invitationId))
  result = call_603374.call(path_603375, nil, nil, nil, nil)

var rejectInvitation* = Call_RejectInvitation_603362(name: "rejectInvitation",
    meth: HttpMethod.HttpDelete, host: "managedblockchain.amazonaws.com",
    route: "/invitations/{invitationId}", validator: validate_RejectInvitation_603363,
    base: "/", url: url_RejectInvitation_603364,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
