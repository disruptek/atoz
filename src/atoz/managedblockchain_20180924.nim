
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

  OpenApiRestCall_593437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593437): Option[Scheme] {.used.} =
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
  Call_CreateMember_594065 = ref object of OpenApiRestCall_593437
proc url_CreateMember_594067(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMember_594066(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594068 = path.getOrDefault("networkId")
  valid_594068 = validateParameter(valid_594068, JString, required = true,
                                 default = nil)
  if valid_594068 != nil:
    section.add "networkId", valid_594068
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
  var valid_594069 = header.getOrDefault("X-Amz-Date")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "X-Amz-Date", valid_594069
  var valid_594070 = header.getOrDefault("X-Amz-Security-Token")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "X-Amz-Security-Token", valid_594070
  var valid_594071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "X-Amz-Content-Sha256", valid_594071
  var valid_594072 = header.getOrDefault("X-Amz-Algorithm")
  valid_594072 = validateParameter(valid_594072, JString, required = false,
                                 default = nil)
  if valid_594072 != nil:
    section.add "X-Amz-Algorithm", valid_594072
  var valid_594073 = header.getOrDefault("X-Amz-Signature")
  valid_594073 = validateParameter(valid_594073, JString, required = false,
                                 default = nil)
  if valid_594073 != nil:
    section.add "X-Amz-Signature", valid_594073
  var valid_594074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594074 = validateParameter(valid_594074, JString, required = false,
                                 default = nil)
  if valid_594074 != nil:
    section.add "X-Amz-SignedHeaders", valid_594074
  var valid_594075 = header.getOrDefault("X-Amz-Credential")
  valid_594075 = validateParameter(valid_594075, JString, required = false,
                                 default = nil)
  if valid_594075 != nil:
    section.add "X-Amz-Credential", valid_594075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594077: Call_CreateMember_594065; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a member within a Managed Blockchain network.
  ## 
  let valid = call_594077.validator(path, query, header, formData, body)
  let scheme = call_594077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594077.url(scheme.get, call_594077.host, call_594077.base,
                         call_594077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594077, url, valid)

proc call*(call_594078: Call_CreateMember_594065; networkId: string; body: JsonNode): Recallable =
  ## createMember
  ## Creates a member within a Managed Blockchain network.
  ##   networkId: string (required)
  ##            : The unique identifier of the network in which the member is created.
  ##   body: JObject (required)
  var path_594079 = newJObject()
  var body_594080 = newJObject()
  add(path_594079, "networkId", newJString(networkId))
  if body != nil:
    body_594080 = body
  result = call_594078.call(path_594079, nil, nil, nil, body_594080)

var createMember* = Call_CreateMember_594065(name: "createMember",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/members", validator: validate_CreateMember_594066,
    base: "/", url: url_CreateMember_594067, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_593774 = ref object of OpenApiRestCall_593437
proc url_ListMembers_593776(protocol: Scheme; host: string; base: string;
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

proc validate_ListMembers_593775(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593902 = path.getOrDefault("networkId")
  valid_593902 = validateParameter(valid_593902, JString, required = true,
                                 default = nil)
  if valid_593902 != nil:
    section.add "networkId", valid_593902
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
  var valid_593903 = query.getOrDefault("NextToken")
  valid_593903 = validateParameter(valid_593903, JString, required = false,
                                 default = nil)
  if valid_593903 != nil:
    section.add "NextToken", valid_593903
  var valid_593904 = query.getOrDefault("maxResults")
  valid_593904 = validateParameter(valid_593904, JInt, required = false, default = nil)
  if valid_593904 != nil:
    section.add "maxResults", valid_593904
  var valid_593905 = query.getOrDefault("nextToken")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "nextToken", valid_593905
  var valid_593906 = query.getOrDefault("name")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "name", valid_593906
  var valid_593907 = query.getOrDefault("isOwned")
  valid_593907 = validateParameter(valid_593907, JBool, required = false, default = nil)
  if valid_593907 != nil:
    section.add "isOwned", valid_593907
  var valid_593921 = query.getOrDefault("status")
  valid_593921 = validateParameter(valid_593921, JString, required = false,
                                 default = newJString("CREATING"))
  if valid_593921 != nil:
    section.add "status", valid_593921
  var valid_593922 = query.getOrDefault("MaxResults")
  valid_593922 = validateParameter(valid_593922, JString, required = false,
                                 default = nil)
  if valid_593922 != nil:
    section.add "MaxResults", valid_593922
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
  var valid_593923 = header.getOrDefault("X-Amz-Date")
  valid_593923 = validateParameter(valid_593923, JString, required = false,
                                 default = nil)
  if valid_593923 != nil:
    section.add "X-Amz-Date", valid_593923
  var valid_593924 = header.getOrDefault("X-Amz-Security-Token")
  valid_593924 = validateParameter(valid_593924, JString, required = false,
                                 default = nil)
  if valid_593924 != nil:
    section.add "X-Amz-Security-Token", valid_593924
  var valid_593925 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593925 = validateParameter(valid_593925, JString, required = false,
                                 default = nil)
  if valid_593925 != nil:
    section.add "X-Amz-Content-Sha256", valid_593925
  var valid_593926 = header.getOrDefault("X-Amz-Algorithm")
  valid_593926 = validateParameter(valid_593926, JString, required = false,
                                 default = nil)
  if valid_593926 != nil:
    section.add "X-Amz-Algorithm", valid_593926
  var valid_593927 = header.getOrDefault("X-Amz-Signature")
  valid_593927 = validateParameter(valid_593927, JString, required = false,
                                 default = nil)
  if valid_593927 != nil:
    section.add "X-Amz-Signature", valid_593927
  var valid_593928 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593928 = validateParameter(valid_593928, JString, required = false,
                                 default = nil)
  if valid_593928 != nil:
    section.add "X-Amz-SignedHeaders", valid_593928
  var valid_593929 = header.getOrDefault("X-Amz-Credential")
  valid_593929 = validateParameter(valid_593929, JString, required = false,
                                 default = nil)
  if valid_593929 != nil:
    section.add "X-Amz-Credential", valid_593929
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593952: Call_ListMembers_593774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a listing of the members in a network and properties of their configurations.
  ## 
  let valid = call_593952.validator(path, query, header, formData, body)
  let scheme = call_593952.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593952.url(scheme.get, call_593952.host, call_593952.base,
                         call_593952.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593952, url, valid)

proc call*(call_594023: Call_ListMembers_593774; networkId: string;
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
  var path_594024 = newJObject()
  var query_594026 = newJObject()
  add(path_594024, "networkId", newJString(networkId))
  add(query_594026, "NextToken", newJString(NextToken))
  add(query_594026, "maxResults", newJInt(maxResults))
  add(query_594026, "nextToken", newJString(nextToken))
  add(query_594026, "name", newJString(name))
  add(query_594026, "isOwned", newJBool(isOwned))
  add(query_594026, "status", newJString(status))
  add(query_594026, "MaxResults", newJString(MaxResults))
  result = call_594023.call(path_594024, query_594026, nil, nil, nil)

var listMembers* = Call_ListMembers_593774(name: "listMembers",
                                        meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
                                        route: "/networks/{networkId}/members",
                                        validator: validate_ListMembers_593775,
                                        base: "/", url: url_ListMembers_593776,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNetwork_594101 = ref object of OpenApiRestCall_593437
proc url_CreateNetwork_594103(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateNetwork_594102(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594104 = header.getOrDefault("X-Amz-Date")
  valid_594104 = validateParameter(valid_594104, JString, required = false,
                                 default = nil)
  if valid_594104 != nil:
    section.add "X-Amz-Date", valid_594104
  var valid_594105 = header.getOrDefault("X-Amz-Security-Token")
  valid_594105 = validateParameter(valid_594105, JString, required = false,
                                 default = nil)
  if valid_594105 != nil:
    section.add "X-Amz-Security-Token", valid_594105
  var valid_594106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "X-Amz-Content-Sha256", valid_594106
  var valid_594107 = header.getOrDefault("X-Amz-Algorithm")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "X-Amz-Algorithm", valid_594107
  var valid_594108 = header.getOrDefault("X-Amz-Signature")
  valid_594108 = validateParameter(valid_594108, JString, required = false,
                                 default = nil)
  if valid_594108 != nil:
    section.add "X-Amz-Signature", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-SignedHeaders", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Credential")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Credential", valid_594110
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594112: Call_CreateNetwork_594101; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new blockchain network using Amazon Managed Blockchain.
  ## 
  let valid = call_594112.validator(path, query, header, formData, body)
  let scheme = call_594112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594112.url(scheme.get, call_594112.host, call_594112.base,
                         call_594112.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594112, url, valid)

proc call*(call_594113: Call_CreateNetwork_594101; body: JsonNode): Recallable =
  ## createNetwork
  ## Creates a new blockchain network using Amazon Managed Blockchain.
  ##   body: JObject (required)
  var body_594114 = newJObject()
  if body != nil:
    body_594114 = body
  result = call_594113.call(nil, nil, nil, nil, body_594114)

var createNetwork* = Call_CreateNetwork_594101(name: "createNetwork",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks", validator: validate_CreateNetwork_594102, base: "/",
    url: url_CreateNetwork_594103, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNetworks_594081 = ref object of OpenApiRestCall_593437
proc url_ListNetworks_594083(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListNetworks_594082(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594084 = query.getOrDefault("framework")
  valid_594084 = validateParameter(valid_594084, JString, required = false,
                                 default = newJString("HYPERLEDGER_FABRIC"))
  if valid_594084 != nil:
    section.add "framework", valid_594084
  var valid_594085 = query.getOrDefault("NextToken")
  valid_594085 = validateParameter(valid_594085, JString, required = false,
                                 default = nil)
  if valid_594085 != nil:
    section.add "NextToken", valid_594085
  var valid_594086 = query.getOrDefault("maxResults")
  valid_594086 = validateParameter(valid_594086, JInt, required = false, default = nil)
  if valid_594086 != nil:
    section.add "maxResults", valid_594086
  var valid_594087 = query.getOrDefault("nextToken")
  valid_594087 = validateParameter(valid_594087, JString, required = false,
                                 default = nil)
  if valid_594087 != nil:
    section.add "nextToken", valid_594087
  var valid_594088 = query.getOrDefault("name")
  valid_594088 = validateParameter(valid_594088, JString, required = false,
                                 default = nil)
  if valid_594088 != nil:
    section.add "name", valid_594088
  var valid_594089 = query.getOrDefault("status")
  valid_594089 = validateParameter(valid_594089, JString, required = false,
                                 default = newJString("CREATING"))
  if valid_594089 != nil:
    section.add "status", valid_594089
  var valid_594090 = query.getOrDefault("MaxResults")
  valid_594090 = validateParameter(valid_594090, JString, required = false,
                                 default = nil)
  if valid_594090 != nil:
    section.add "MaxResults", valid_594090
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
  var valid_594091 = header.getOrDefault("X-Amz-Date")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Date", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Security-Token")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Security-Token", valid_594092
  var valid_594093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "X-Amz-Content-Sha256", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Algorithm")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Algorithm", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Signature")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Signature", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-SignedHeaders", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-Credential")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-Credential", valid_594097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594098: Call_ListNetworks_594081; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the networks in which the current AWS account has members.
  ## 
  let valid = call_594098.validator(path, query, header, formData, body)
  let scheme = call_594098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594098.url(scheme.get, call_594098.host, call_594098.base,
                         call_594098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594098, url, valid)

proc call*(call_594099: Call_ListNetworks_594081;
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
  var query_594100 = newJObject()
  add(query_594100, "framework", newJString(framework))
  add(query_594100, "NextToken", newJString(NextToken))
  add(query_594100, "maxResults", newJInt(maxResults))
  add(query_594100, "nextToken", newJString(nextToken))
  add(query_594100, "name", newJString(name))
  add(query_594100, "status", newJString(status))
  add(query_594100, "MaxResults", newJString(MaxResults))
  result = call_594099.call(nil, query_594100, nil, nil, nil)

var listNetworks* = Call_ListNetworks_594081(name: "listNetworks",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks", validator: validate_ListNetworks_594082, base: "/",
    url: url_ListNetworks_594083, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNode_594136 = ref object of OpenApiRestCall_593437
proc url_CreateNode_594138(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateNode_594137(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594139 = path.getOrDefault("networkId")
  valid_594139 = validateParameter(valid_594139, JString, required = true,
                                 default = nil)
  if valid_594139 != nil:
    section.add "networkId", valid_594139
  var valid_594140 = path.getOrDefault("memberId")
  valid_594140 = validateParameter(valid_594140, JString, required = true,
                                 default = nil)
  if valid_594140 != nil:
    section.add "memberId", valid_594140
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
  var valid_594141 = header.getOrDefault("X-Amz-Date")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "X-Amz-Date", valid_594141
  var valid_594142 = header.getOrDefault("X-Amz-Security-Token")
  valid_594142 = validateParameter(valid_594142, JString, required = false,
                                 default = nil)
  if valid_594142 != nil:
    section.add "X-Amz-Security-Token", valid_594142
  var valid_594143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "X-Amz-Content-Sha256", valid_594143
  var valid_594144 = header.getOrDefault("X-Amz-Algorithm")
  valid_594144 = validateParameter(valid_594144, JString, required = false,
                                 default = nil)
  if valid_594144 != nil:
    section.add "X-Amz-Algorithm", valid_594144
  var valid_594145 = header.getOrDefault("X-Amz-Signature")
  valid_594145 = validateParameter(valid_594145, JString, required = false,
                                 default = nil)
  if valid_594145 != nil:
    section.add "X-Amz-Signature", valid_594145
  var valid_594146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594146 = validateParameter(valid_594146, JString, required = false,
                                 default = nil)
  if valid_594146 != nil:
    section.add "X-Amz-SignedHeaders", valid_594146
  var valid_594147 = header.getOrDefault("X-Amz-Credential")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "X-Amz-Credential", valid_594147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594149: Call_CreateNode_594136; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a peer node in a member.
  ## 
  let valid = call_594149.validator(path, query, header, formData, body)
  let scheme = call_594149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594149.url(scheme.get, call_594149.host, call_594149.base,
                         call_594149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594149, url, valid)

proc call*(call_594150: Call_CreateNode_594136; networkId: string; memberId: string;
          body: JsonNode): Recallable =
  ## createNode
  ## Creates a peer node in a member.
  ##   networkId: string (required)
  ##            : The unique identifier of the network in which this node runs.
  ##   memberId: string (required)
  ##           : The unique identifier of the member that owns this node.
  ##   body: JObject (required)
  var path_594151 = newJObject()
  var body_594152 = newJObject()
  add(path_594151, "networkId", newJString(networkId))
  add(path_594151, "memberId", newJString(memberId))
  if body != nil:
    body_594152 = body
  result = call_594150.call(path_594151, nil, nil, nil, body_594152)

var createNode* = Call_CreateNode_594136(name: "createNode",
                                      meth: HttpMethod.HttpPost,
                                      host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes",
                                      validator: validate_CreateNode_594137,
                                      base: "/", url: url_CreateNode_594138,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNodes_594115 = ref object of OpenApiRestCall_593437
proc url_ListNodes_594117(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListNodes_594116(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594118 = path.getOrDefault("networkId")
  valid_594118 = validateParameter(valid_594118, JString, required = true,
                                 default = nil)
  if valid_594118 != nil:
    section.add "networkId", valid_594118
  var valid_594119 = path.getOrDefault("memberId")
  valid_594119 = validateParameter(valid_594119, JString, required = true,
                                 default = nil)
  if valid_594119 != nil:
    section.add "memberId", valid_594119
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
  var valid_594120 = query.getOrDefault("NextToken")
  valid_594120 = validateParameter(valid_594120, JString, required = false,
                                 default = nil)
  if valid_594120 != nil:
    section.add "NextToken", valid_594120
  var valid_594121 = query.getOrDefault("maxResults")
  valid_594121 = validateParameter(valid_594121, JInt, required = false, default = nil)
  if valid_594121 != nil:
    section.add "maxResults", valid_594121
  var valid_594122 = query.getOrDefault("nextToken")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "nextToken", valid_594122
  var valid_594123 = query.getOrDefault("status")
  valid_594123 = validateParameter(valid_594123, JString, required = false,
                                 default = newJString("CREATING"))
  if valid_594123 != nil:
    section.add "status", valid_594123
  var valid_594124 = query.getOrDefault("MaxResults")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "MaxResults", valid_594124
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
  var valid_594125 = header.getOrDefault("X-Amz-Date")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Date", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-Security-Token")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-Security-Token", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-Content-Sha256", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Algorithm")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Algorithm", valid_594128
  var valid_594129 = header.getOrDefault("X-Amz-Signature")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "X-Amz-Signature", valid_594129
  var valid_594130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = nil)
  if valid_594130 != nil:
    section.add "X-Amz-SignedHeaders", valid_594130
  var valid_594131 = header.getOrDefault("X-Amz-Credential")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "X-Amz-Credential", valid_594131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594132: Call_ListNodes_594115; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the nodes within a network.
  ## 
  let valid = call_594132.validator(path, query, header, formData, body)
  let scheme = call_594132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594132.url(scheme.get, call_594132.host, call_594132.base,
                         call_594132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594132, url, valid)

proc call*(call_594133: Call_ListNodes_594115; networkId: string; memberId: string;
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
  var path_594134 = newJObject()
  var query_594135 = newJObject()
  add(path_594134, "networkId", newJString(networkId))
  add(path_594134, "memberId", newJString(memberId))
  add(query_594135, "NextToken", newJString(NextToken))
  add(query_594135, "maxResults", newJInt(maxResults))
  add(query_594135, "nextToken", newJString(nextToken))
  add(query_594135, "status", newJString(status))
  add(query_594135, "MaxResults", newJString(MaxResults))
  result = call_594133.call(path_594134, query_594135, nil, nil, nil)

var listNodes* = Call_ListNodes_594115(name: "listNodes", meth: HttpMethod.HttpGet,
                                    host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes",
                                    validator: validate_ListNodes_594116,
                                    base: "/", url: url_ListNodes_594117,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProposal_594172 = ref object of OpenApiRestCall_593437
proc url_CreateProposal_594174(protocol: Scheme; host: string; base: string;
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

proc validate_CreateProposal_594173(path: JsonNode; query: JsonNode;
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
  var valid_594175 = path.getOrDefault("networkId")
  valid_594175 = validateParameter(valid_594175, JString, required = true,
                                 default = nil)
  if valid_594175 != nil:
    section.add "networkId", valid_594175
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
  var valid_594176 = header.getOrDefault("X-Amz-Date")
  valid_594176 = validateParameter(valid_594176, JString, required = false,
                                 default = nil)
  if valid_594176 != nil:
    section.add "X-Amz-Date", valid_594176
  var valid_594177 = header.getOrDefault("X-Amz-Security-Token")
  valid_594177 = validateParameter(valid_594177, JString, required = false,
                                 default = nil)
  if valid_594177 != nil:
    section.add "X-Amz-Security-Token", valid_594177
  var valid_594178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594178 = validateParameter(valid_594178, JString, required = false,
                                 default = nil)
  if valid_594178 != nil:
    section.add "X-Amz-Content-Sha256", valid_594178
  var valid_594179 = header.getOrDefault("X-Amz-Algorithm")
  valid_594179 = validateParameter(valid_594179, JString, required = false,
                                 default = nil)
  if valid_594179 != nil:
    section.add "X-Amz-Algorithm", valid_594179
  var valid_594180 = header.getOrDefault("X-Amz-Signature")
  valid_594180 = validateParameter(valid_594180, JString, required = false,
                                 default = nil)
  if valid_594180 != nil:
    section.add "X-Amz-Signature", valid_594180
  var valid_594181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-SignedHeaders", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-Credential")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Credential", valid_594182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594184: Call_CreateProposal_594172; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a proposal for a change to the network that other members of the network can vote on, for example, a proposal to add a new member to the network. Any member can create a proposal.
  ## 
  let valid = call_594184.validator(path, query, header, formData, body)
  let scheme = call_594184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594184.url(scheme.get, call_594184.host, call_594184.base,
                         call_594184.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594184, url, valid)

proc call*(call_594185: Call_CreateProposal_594172; networkId: string; body: JsonNode): Recallable =
  ## createProposal
  ## Creates a proposal for a change to the network that other members of the network can vote on, for example, a proposal to add a new member to the network. Any member can create a proposal.
  ##   networkId: string (required)
  ##            :  The unique identifier of the network for which the proposal is made.
  ##   body: JObject (required)
  var path_594186 = newJObject()
  var body_594187 = newJObject()
  add(path_594186, "networkId", newJString(networkId))
  if body != nil:
    body_594187 = body
  result = call_594185.call(path_594186, nil, nil, nil, body_594187)

var createProposal* = Call_CreateProposal_594172(name: "createProposal",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals", validator: validate_CreateProposal_594173,
    base: "/", url: url_CreateProposal_594174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProposals_594153 = ref object of OpenApiRestCall_593437
proc url_ListProposals_594155(protocol: Scheme; host: string; base: string;
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

proc validate_ListProposals_594154(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594156 = path.getOrDefault("networkId")
  valid_594156 = validateParameter(valid_594156, JString, required = true,
                                 default = nil)
  if valid_594156 != nil:
    section.add "networkId", valid_594156
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
  var valid_594157 = query.getOrDefault("NextToken")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "NextToken", valid_594157
  var valid_594158 = query.getOrDefault("maxResults")
  valid_594158 = validateParameter(valid_594158, JInt, required = false, default = nil)
  if valid_594158 != nil:
    section.add "maxResults", valid_594158
  var valid_594159 = query.getOrDefault("nextToken")
  valid_594159 = validateParameter(valid_594159, JString, required = false,
                                 default = nil)
  if valid_594159 != nil:
    section.add "nextToken", valid_594159
  var valid_594160 = query.getOrDefault("MaxResults")
  valid_594160 = validateParameter(valid_594160, JString, required = false,
                                 default = nil)
  if valid_594160 != nil:
    section.add "MaxResults", valid_594160
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
  var valid_594161 = header.getOrDefault("X-Amz-Date")
  valid_594161 = validateParameter(valid_594161, JString, required = false,
                                 default = nil)
  if valid_594161 != nil:
    section.add "X-Amz-Date", valid_594161
  var valid_594162 = header.getOrDefault("X-Amz-Security-Token")
  valid_594162 = validateParameter(valid_594162, JString, required = false,
                                 default = nil)
  if valid_594162 != nil:
    section.add "X-Amz-Security-Token", valid_594162
  var valid_594163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594163 = validateParameter(valid_594163, JString, required = false,
                                 default = nil)
  if valid_594163 != nil:
    section.add "X-Amz-Content-Sha256", valid_594163
  var valid_594164 = header.getOrDefault("X-Amz-Algorithm")
  valid_594164 = validateParameter(valid_594164, JString, required = false,
                                 default = nil)
  if valid_594164 != nil:
    section.add "X-Amz-Algorithm", valid_594164
  var valid_594165 = header.getOrDefault("X-Amz-Signature")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "X-Amz-Signature", valid_594165
  var valid_594166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-SignedHeaders", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Credential")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Credential", valid_594167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594168: Call_ListProposals_594153; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a listing of proposals for the network.
  ## 
  let valid = call_594168.validator(path, query, header, formData, body)
  let scheme = call_594168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594168.url(scheme.get, call_594168.host, call_594168.base,
                         call_594168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594168, url, valid)

proc call*(call_594169: Call_ListProposals_594153; networkId: string;
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
  var path_594170 = newJObject()
  var query_594171 = newJObject()
  add(path_594170, "networkId", newJString(networkId))
  add(query_594171, "NextToken", newJString(NextToken))
  add(query_594171, "maxResults", newJInt(maxResults))
  add(query_594171, "nextToken", newJString(nextToken))
  add(query_594171, "MaxResults", newJString(MaxResults))
  result = call_594169.call(path_594170, query_594171, nil, nil, nil)

var listProposals* = Call_ListProposals_594153(name: "listProposals",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals", validator: validate_ListProposals_594154,
    base: "/", url: url_ListProposals_594155, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMember_594188 = ref object of OpenApiRestCall_593437
proc url_GetMember_594190(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetMember_594189(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594191 = path.getOrDefault("networkId")
  valid_594191 = validateParameter(valid_594191, JString, required = true,
                                 default = nil)
  if valid_594191 != nil:
    section.add "networkId", valid_594191
  var valid_594192 = path.getOrDefault("memberId")
  valid_594192 = validateParameter(valid_594192, JString, required = true,
                                 default = nil)
  if valid_594192 != nil:
    section.add "memberId", valid_594192
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
  var valid_594193 = header.getOrDefault("X-Amz-Date")
  valid_594193 = validateParameter(valid_594193, JString, required = false,
                                 default = nil)
  if valid_594193 != nil:
    section.add "X-Amz-Date", valid_594193
  var valid_594194 = header.getOrDefault("X-Amz-Security-Token")
  valid_594194 = validateParameter(valid_594194, JString, required = false,
                                 default = nil)
  if valid_594194 != nil:
    section.add "X-Amz-Security-Token", valid_594194
  var valid_594195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "X-Amz-Content-Sha256", valid_594195
  var valid_594196 = header.getOrDefault("X-Amz-Algorithm")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Algorithm", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-Signature")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Signature", valid_594197
  var valid_594198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594198 = validateParameter(valid_594198, JString, required = false,
                                 default = nil)
  if valid_594198 != nil:
    section.add "X-Amz-SignedHeaders", valid_594198
  var valid_594199 = header.getOrDefault("X-Amz-Credential")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Credential", valid_594199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594200: Call_GetMember_594188; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a member.
  ## 
  let valid = call_594200.validator(path, query, header, formData, body)
  let scheme = call_594200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594200.url(scheme.get, call_594200.host, call_594200.base,
                         call_594200.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594200, url, valid)

proc call*(call_594201: Call_GetMember_594188; networkId: string; memberId: string): Recallable =
  ## getMember
  ## Returns detailed information about a member.
  ##   networkId: string (required)
  ##            : The unique identifier of the network to which the member belongs.
  ##   memberId: string (required)
  ##           : The unique identifier of the member.
  var path_594202 = newJObject()
  add(path_594202, "networkId", newJString(networkId))
  add(path_594202, "memberId", newJString(memberId))
  result = call_594201.call(path_594202, nil, nil, nil, nil)

var getMember* = Call_GetMember_594188(name: "getMember", meth: HttpMethod.HttpGet,
                                    host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}",
                                    validator: validate_GetMember_594189,
                                    base: "/", url: url_GetMember_594190,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMember_594203 = ref object of OpenApiRestCall_593437
proc url_DeleteMember_594205(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMember_594204(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594206 = path.getOrDefault("networkId")
  valid_594206 = validateParameter(valid_594206, JString, required = true,
                                 default = nil)
  if valid_594206 != nil:
    section.add "networkId", valid_594206
  var valid_594207 = path.getOrDefault("memberId")
  valid_594207 = validateParameter(valid_594207, JString, required = true,
                                 default = nil)
  if valid_594207 != nil:
    section.add "memberId", valid_594207
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
  var valid_594208 = header.getOrDefault("X-Amz-Date")
  valid_594208 = validateParameter(valid_594208, JString, required = false,
                                 default = nil)
  if valid_594208 != nil:
    section.add "X-Amz-Date", valid_594208
  var valid_594209 = header.getOrDefault("X-Amz-Security-Token")
  valid_594209 = validateParameter(valid_594209, JString, required = false,
                                 default = nil)
  if valid_594209 != nil:
    section.add "X-Amz-Security-Token", valid_594209
  var valid_594210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "X-Amz-Content-Sha256", valid_594210
  var valid_594211 = header.getOrDefault("X-Amz-Algorithm")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Algorithm", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-Signature")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Signature", valid_594212
  var valid_594213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594213 = validateParameter(valid_594213, JString, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "X-Amz-SignedHeaders", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-Credential")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Credential", valid_594214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594215: Call_DeleteMember_594203; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a member. Deleting a member removes the member and all associated resources from the network. <code>DeleteMember</code> can only be called for a specified <code>MemberId</code> if the principal performing the action is associated with the AWS account that owns the member. In all other cases, the <code>DeleteMember</code> action is carried out as the result of an approved proposal to remove a member. If <code>MemberId</code> is the last member in a network specified by the last AWS account, the network is deleted also.
  ## 
  let valid = call_594215.validator(path, query, header, formData, body)
  let scheme = call_594215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594215.url(scheme.get, call_594215.host, call_594215.base,
                         call_594215.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594215, url, valid)

proc call*(call_594216: Call_DeleteMember_594203; networkId: string; memberId: string): Recallable =
  ## deleteMember
  ## Deletes a member. Deleting a member removes the member and all associated resources from the network. <code>DeleteMember</code> can only be called for a specified <code>MemberId</code> if the principal performing the action is associated with the AWS account that owns the member. In all other cases, the <code>DeleteMember</code> action is carried out as the result of an approved proposal to remove a member. If <code>MemberId</code> is the last member in a network specified by the last AWS account, the network is deleted also.
  ##   networkId: string (required)
  ##            : The unique identifier of the network from which the member is removed.
  ##   memberId: string (required)
  ##           : The unique identifier of the member to remove.
  var path_594217 = newJObject()
  add(path_594217, "networkId", newJString(networkId))
  add(path_594217, "memberId", newJString(memberId))
  result = call_594216.call(path_594217, nil, nil, nil, nil)

var deleteMember* = Call_DeleteMember_594203(name: "deleteMember",
    meth: HttpMethod.HttpDelete, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/members/{memberId}",
    validator: validate_DeleteMember_594204, base: "/", url: url_DeleteMember_594205,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNode_594218 = ref object of OpenApiRestCall_593437
proc url_GetNode_594220(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetNode_594219(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594221 = path.getOrDefault("networkId")
  valid_594221 = validateParameter(valid_594221, JString, required = true,
                                 default = nil)
  if valid_594221 != nil:
    section.add "networkId", valid_594221
  var valid_594222 = path.getOrDefault("memberId")
  valid_594222 = validateParameter(valid_594222, JString, required = true,
                                 default = nil)
  if valid_594222 != nil:
    section.add "memberId", valid_594222
  var valid_594223 = path.getOrDefault("nodeId")
  valid_594223 = validateParameter(valid_594223, JString, required = true,
                                 default = nil)
  if valid_594223 != nil:
    section.add "nodeId", valid_594223
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
  var valid_594224 = header.getOrDefault("X-Amz-Date")
  valid_594224 = validateParameter(valid_594224, JString, required = false,
                                 default = nil)
  if valid_594224 != nil:
    section.add "X-Amz-Date", valid_594224
  var valid_594225 = header.getOrDefault("X-Amz-Security-Token")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "X-Amz-Security-Token", valid_594225
  var valid_594226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Content-Sha256", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-Algorithm")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-Algorithm", valid_594227
  var valid_594228 = header.getOrDefault("X-Amz-Signature")
  valid_594228 = validateParameter(valid_594228, JString, required = false,
                                 default = nil)
  if valid_594228 != nil:
    section.add "X-Amz-Signature", valid_594228
  var valid_594229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "X-Amz-SignedHeaders", valid_594229
  var valid_594230 = header.getOrDefault("X-Amz-Credential")
  valid_594230 = validateParameter(valid_594230, JString, required = false,
                                 default = nil)
  if valid_594230 != nil:
    section.add "X-Amz-Credential", valid_594230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594231: Call_GetNode_594218; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a peer node.
  ## 
  let valid = call_594231.validator(path, query, header, formData, body)
  let scheme = call_594231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594231.url(scheme.get, call_594231.host, call_594231.base,
                         call_594231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594231, url, valid)

proc call*(call_594232: Call_GetNode_594218; networkId: string; memberId: string;
          nodeId: string): Recallable =
  ## getNode
  ## Returns detailed information about a peer node.
  ##   networkId: string (required)
  ##            : The unique identifier of the network to which the node belongs.
  ##   memberId: string (required)
  ##           : The unique identifier of the member that owns the node.
  ##   nodeId: string (required)
  ##         : The unique identifier of the node.
  var path_594233 = newJObject()
  add(path_594233, "networkId", newJString(networkId))
  add(path_594233, "memberId", newJString(memberId))
  add(path_594233, "nodeId", newJString(nodeId))
  result = call_594232.call(path_594233, nil, nil, nil, nil)

var getNode* = Call_GetNode_594218(name: "getNode", meth: HttpMethod.HttpGet,
                                host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes/{nodeId}",
                                validator: validate_GetNode_594219, base: "/",
                                url: url_GetNode_594220,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNode_594234 = ref object of OpenApiRestCall_593437
proc url_DeleteNode_594236(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteNode_594235(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594237 = path.getOrDefault("networkId")
  valid_594237 = validateParameter(valid_594237, JString, required = true,
                                 default = nil)
  if valid_594237 != nil:
    section.add "networkId", valid_594237
  var valid_594238 = path.getOrDefault("memberId")
  valid_594238 = validateParameter(valid_594238, JString, required = true,
                                 default = nil)
  if valid_594238 != nil:
    section.add "memberId", valid_594238
  var valid_594239 = path.getOrDefault("nodeId")
  valid_594239 = validateParameter(valid_594239, JString, required = true,
                                 default = nil)
  if valid_594239 != nil:
    section.add "nodeId", valid_594239
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
  var valid_594240 = header.getOrDefault("X-Amz-Date")
  valid_594240 = validateParameter(valid_594240, JString, required = false,
                                 default = nil)
  if valid_594240 != nil:
    section.add "X-Amz-Date", valid_594240
  var valid_594241 = header.getOrDefault("X-Amz-Security-Token")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-Security-Token", valid_594241
  var valid_594242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-Content-Sha256", valid_594242
  var valid_594243 = header.getOrDefault("X-Amz-Algorithm")
  valid_594243 = validateParameter(valid_594243, JString, required = false,
                                 default = nil)
  if valid_594243 != nil:
    section.add "X-Amz-Algorithm", valid_594243
  var valid_594244 = header.getOrDefault("X-Amz-Signature")
  valid_594244 = validateParameter(valid_594244, JString, required = false,
                                 default = nil)
  if valid_594244 != nil:
    section.add "X-Amz-Signature", valid_594244
  var valid_594245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594245 = validateParameter(valid_594245, JString, required = false,
                                 default = nil)
  if valid_594245 != nil:
    section.add "X-Amz-SignedHeaders", valid_594245
  var valid_594246 = header.getOrDefault("X-Amz-Credential")
  valid_594246 = validateParameter(valid_594246, JString, required = false,
                                 default = nil)
  if valid_594246 != nil:
    section.add "X-Amz-Credential", valid_594246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594247: Call_DeleteNode_594234; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a peer node from a member that your AWS account owns. All data on the node is lost and cannot be recovered.
  ## 
  let valid = call_594247.validator(path, query, header, formData, body)
  let scheme = call_594247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594247.url(scheme.get, call_594247.host, call_594247.base,
                         call_594247.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594247, url, valid)

proc call*(call_594248: Call_DeleteNode_594234; networkId: string; memberId: string;
          nodeId: string): Recallable =
  ## deleteNode
  ## Deletes a peer node from a member that your AWS account owns. All data on the node is lost and cannot be recovered.
  ##   networkId: string (required)
  ##            : The unique identifier of the network that the node belongs to.
  ##   memberId: string (required)
  ##           : The unique identifier of the member that owns this node.
  ##   nodeId: string (required)
  ##         : The unique identifier of the node.
  var path_594249 = newJObject()
  add(path_594249, "networkId", newJString(networkId))
  add(path_594249, "memberId", newJString(memberId))
  add(path_594249, "nodeId", newJString(nodeId))
  result = call_594248.call(path_594249, nil, nil, nil, nil)

var deleteNode* = Call_DeleteNode_594234(name: "deleteNode",
                                      meth: HttpMethod.HttpDelete,
                                      host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes/{nodeId}",
                                      validator: validate_DeleteNode_594235,
                                      base: "/", url: url_DeleteNode_594236,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNetwork_594250 = ref object of OpenApiRestCall_593437
proc url_GetNetwork_594252(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetNetwork_594251(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594253 = path.getOrDefault("networkId")
  valid_594253 = validateParameter(valid_594253, JString, required = true,
                                 default = nil)
  if valid_594253 != nil:
    section.add "networkId", valid_594253
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
  var valid_594254 = header.getOrDefault("X-Amz-Date")
  valid_594254 = validateParameter(valid_594254, JString, required = false,
                                 default = nil)
  if valid_594254 != nil:
    section.add "X-Amz-Date", valid_594254
  var valid_594255 = header.getOrDefault("X-Amz-Security-Token")
  valid_594255 = validateParameter(valid_594255, JString, required = false,
                                 default = nil)
  if valid_594255 != nil:
    section.add "X-Amz-Security-Token", valid_594255
  var valid_594256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Content-Sha256", valid_594256
  var valid_594257 = header.getOrDefault("X-Amz-Algorithm")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-Algorithm", valid_594257
  var valid_594258 = header.getOrDefault("X-Amz-Signature")
  valid_594258 = validateParameter(valid_594258, JString, required = false,
                                 default = nil)
  if valid_594258 != nil:
    section.add "X-Amz-Signature", valid_594258
  var valid_594259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "X-Amz-SignedHeaders", valid_594259
  var valid_594260 = header.getOrDefault("X-Amz-Credential")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "X-Amz-Credential", valid_594260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594261: Call_GetNetwork_594250; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a network.
  ## 
  let valid = call_594261.validator(path, query, header, formData, body)
  let scheme = call_594261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594261.url(scheme.get, call_594261.host, call_594261.base,
                         call_594261.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594261, url, valid)

proc call*(call_594262: Call_GetNetwork_594250; networkId: string): Recallable =
  ## getNetwork
  ## Returns detailed information about a network.
  ##   networkId: string (required)
  ##            : The unique identifier of the network to get information about.
  var path_594263 = newJObject()
  add(path_594263, "networkId", newJString(networkId))
  result = call_594262.call(path_594263, nil, nil, nil, nil)

var getNetwork* = Call_GetNetwork_594250(name: "getNetwork",
                                      meth: HttpMethod.HttpGet,
                                      host: "managedblockchain.amazonaws.com",
                                      route: "/networks/{networkId}",
                                      validator: validate_GetNetwork_594251,
                                      base: "/", url: url_GetNetwork_594252,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProposal_594264 = ref object of OpenApiRestCall_593437
proc url_GetProposal_594266(protocol: Scheme; host: string; base: string;
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

proc validate_GetProposal_594265(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594267 = path.getOrDefault("networkId")
  valid_594267 = validateParameter(valid_594267, JString, required = true,
                                 default = nil)
  if valid_594267 != nil:
    section.add "networkId", valid_594267
  var valid_594268 = path.getOrDefault("proposalId")
  valid_594268 = validateParameter(valid_594268, JString, required = true,
                                 default = nil)
  if valid_594268 != nil:
    section.add "proposalId", valid_594268
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
  var valid_594269 = header.getOrDefault("X-Amz-Date")
  valid_594269 = validateParameter(valid_594269, JString, required = false,
                                 default = nil)
  if valid_594269 != nil:
    section.add "X-Amz-Date", valid_594269
  var valid_594270 = header.getOrDefault("X-Amz-Security-Token")
  valid_594270 = validateParameter(valid_594270, JString, required = false,
                                 default = nil)
  if valid_594270 != nil:
    section.add "X-Amz-Security-Token", valid_594270
  var valid_594271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594271 = validateParameter(valid_594271, JString, required = false,
                                 default = nil)
  if valid_594271 != nil:
    section.add "X-Amz-Content-Sha256", valid_594271
  var valid_594272 = header.getOrDefault("X-Amz-Algorithm")
  valid_594272 = validateParameter(valid_594272, JString, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "X-Amz-Algorithm", valid_594272
  var valid_594273 = header.getOrDefault("X-Amz-Signature")
  valid_594273 = validateParameter(valid_594273, JString, required = false,
                                 default = nil)
  if valid_594273 != nil:
    section.add "X-Amz-Signature", valid_594273
  var valid_594274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594274 = validateParameter(valid_594274, JString, required = false,
                                 default = nil)
  if valid_594274 != nil:
    section.add "X-Amz-SignedHeaders", valid_594274
  var valid_594275 = header.getOrDefault("X-Amz-Credential")
  valid_594275 = validateParameter(valid_594275, JString, required = false,
                                 default = nil)
  if valid_594275 != nil:
    section.add "X-Amz-Credential", valid_594275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594276: Call_GetProposal_594264; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a proposal.
  ## 
  let valid = call_594276.validator(path, query, header, formData, body)
  let scheme = call_594276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594276.url(scheme.get, call_594276.host, call_594276.base,
                         call_594276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594276, url, valid)

proc call*(call_594277: Call_GetProposal_594264; networkId: string;
          proposalId: string): Recallable =
  ## getProposal
  ## Returns detailed information about a proposal.
  ##   networkId: string (required)
  ##            : The unique identifier of the network for which the proposal is made.
  ##   proposalId: string (required)
  ##             : The unique identifier of the proposal.
  var path_594278 = newJObject()
  add(path_594278, "networkId", newJString(networkId))
  add(path_594278, "proposalId", newJString(proposalId))
  result = call_594277.call(path_594278, nil, nil, nil, nil)

var getProposal* = Call_GetProposal_594264(name: "getProposal",
                                        meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/proposals/{proposalId}",
                                        validator: validate_GetProposal_594265,
                                        base: "/", url: url_GetProposal_594266,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_594279 = ref object of OpenApiRestCall_593437
proc url_ListInvitations_594281(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListInvitations_594280(path: JsonNode; query: JsonNode;
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
  var valid_594282 = query.getOrDefault("NextToken")
  valid_594282 = validateParameter(valid_594282, JString, required = false,
                                 default = nil)
  if valid_594282 != nil:
    section.add "NextToken", valid_594282
  var valid_594283 = query.getOrDefault("maxResults")
  valid_594283 = validateParameter(valid_594283, JInt, required = false, default = nil)
  if valid_594283 != nil:
    section.add "maxResults", valid_594283
  var valid_594284 = query.getOrDefault("nextToken")
  valid_594284 = validateParameter(valid_594284, JString, required = false,
                                 default = nil)
  if valid_594284 != nil:
    section.add "nextToken", valid_594284
  var valid_594285 = query.getOrDefault("MaxResults")
  valid_594285 = validateParameter(valid_594285, JString, required = false,
                                 default = nil)
  if valid_594285 != nil:
    section.add "MaxResults", valid_594285
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
  var valid_594286 = header.getOrDefault("X-Amz-Date")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "X-Amz-Date", valid_594286
  var valid_594287 = header.getOrDefault("X-Amz-Security-Token")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-Security-Token", valid_594287
  var valid_594288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594288 = validateParameter(valid_594288, JString, required = false,
                                 default = nil)
  if valid_594288 != nil:
    section.add "X-Amz-Content-Sha256", valid_594288
  var valid_594289 = header.getOrDefault("X-Amz-Algorithm")
  valid_594289 = validateParameter(valid_594289, JString, required = false,
                                 default = nil)
  if valid_594289 != nil:
    section.add "X-Amz-Algorithm", valid_594289
  var valid_594290 = header.getOrDefault("X-Amz-Signature")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "X-Amz-Signature", valid_594290
  var valid_594291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-SignedHeaders", valid_594291
  var valid_594292 = header.getOrDefault("X-Amz-Credential")
  valid_594292 = validateParameter(valid_594292, JString, required = false,
                                 default = nil)
  if valid_594292 != nil:
    section.add "X-Amz-Credential", valid_594292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594293: Call_ListInvitations_594279; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a listing of all invitations made on the specified network.
  ## 
  let valid = call_594293.validator(path, query, header, formData, body)
  let scheme = call_594293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594293.url(scheme.get, call_594293.host, call_594293.base,
                         call_594293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594293, url, valid)

proc call*(call_594294: Call_ListInvitations_594279; NextToken: string = "";
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
  var query_594295 = newJObject()
  add(query_594295, "NextToken", newJString(NextToken))
  add(query_594295, "maxResults", newJInt(maxResults))
  add(query_594295, "nextToken", newJString(nextToken))
  add(query_594295, "MaxResults", newJString(MaxResults))
  result = call_594294.call(nil, query_594295, nil, nil, nil)

var listInvitations* = Call_ListInvitations_594279(name: "listInvitations",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/invitations", validator: validate_ListInvitations_594280, base: "/",
    url: url_ListInvitations_594281, schemes: {Scheme.Https, Scheme.Http})
type
  Call_VoteOnProposal_594316 = ref object of OpenApiRestCall_593437
proc url_VoteOnProposal_594318(protocol: Scheme; host: string; base: string;
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

proc validate_VoteOnProposal_594317(path: JsonNode; query: JsonNode;
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
  var valid_594319 = path.getOrDefault("networkId")
  valid_594319 = validateParameter(valid_594319, JString, required = true,
                                 default = nil)
  if valid_594319 != nil:
    section.add "networkId", valid_594319
  var valid_594320 = path.getOrDefault("proposalId")
  valid_594320 = validateParameter(valid_594320, JString, required = true,
                                 default = nil)
  if valid_594320 != nil:
    section.add "proposalId", valid_594320
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
  var valid_594321 = header.getOrDefault("X-Amz-Date")
  valid_594321 = validateParameter(valid_594321, JString, required = false,
                                 default = nil)
  if valid_594321 != nil:
    section.add "X-Amz-Date", valid_594321
  var valid_594322 = header.getOrDefault("X-Amz-Security-Token")
  valid_594322 = validateParameter(valid_594322, JString, required = false,
                                 default = nil)
  if valid_594322 != nil:
    section.add "X-Amz-Security-Token", valid_594322
  var valid_594323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594323 = validateParameter(valid_594323, JString, required = false,
                                 default = nil)
  if valid_594323 != nil:
    section.add "X-Amz-Content-Sha256", valid_594323
  var valid_594324 = header.getOrDefault("X-Amz-Algorithm")
  valid_594324 = validateParameter(valid_594324, JString, required = false,
                                 default = nil)
  if valid_594324 != nil:
    section.add "X-Amz-Algorithm", valid_594324
  var valid_594325 = header.getOrDefault("X-Amz-Signature")
  valid_594325 = validateParameter(valid_594325, JString, required = false,
                                 default = nil)
  if valid_594325 != nil:
    section.add "X-Amz-Signature", valid_594325
  var valid_594326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594326 = validateParameter(valid_594326, JString, required = false,
                                 default = nil)
  if valid_594326 != nil:
    section.add "X-Amz-SignedHeaders", valid_594326
  var valid_594327 = header.getOrDefault("X-Amz-Credential")
  valid_594327 = validateParameter(valid_594327, JString, required = false,
                                 default = nil)
  if valid_594327 != nil:
    section.add "X-Amz-Credential", valid_594327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594329: Call_VoteOnProposal_594316; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Casts a vote for a specified <code>ProposalId</code> on behalf of a member. The member to vote as, specified by <code>VoterMemberId</code>, must be in the same AWS account as the principal that calls the action.
  ## 
  let valid = call_594329.validator(path, query, header, formData, body)
  let scheme = call_594329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594329.url(scheme.get, call_594329.host, call_594329.base,
                         call_594329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594329, url, valid)

proc call*(call_594330: Call_VoteOnProposal_594316; networkId: string;
          proposalId: string; body: JsonNode): Recallable =
  ## voteOnProposal
  ## Casts a vote for a specified <code>ProposalId</code> on behalf of a member. The member to vote as, specified by <code>VoterMemberId</code>, must be in the same AWS account as the principal that calls the action.
  ##   networkId: string (required)
  ##            :  The unique identifier of the network. 
  ##   proposalId: string (required)
  ##             :  The unique identifier of the proposal. 
  ##   body: JObject (required)
  var path_594331 = newJObject()
  var body_594332 = newJObject()
  add(path_594331, "networkId", newJString(networkId))
  add(path_594331, "proposalId", newJString(proposalId))
  if body != nil:
    body_594332 = body
  result = call_594330.call(path_594331, nil, nil, nil, body_594332)

var voteOnProposal* = Call_VoteOnProposal_594316(name: "voteOnProposal",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals/{proposalId}/votes",
    validator: validate_VoteOnProposal_594317, base: "/", url: url_VoteOnProposal_594318,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProposalVotes_594296 = ref object of OpenApiRestCall_593437
proc url_ListProposalVotes_594298(protocol: Scheme; host: string; base: string;
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

proc validate_ListProposalVotes_594297(path: JsonNode; query: JsonNode;
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
  var valid_594299 = path.getOrDefault("networkId")
  valid_594299 = validateParameter(valid_594299, JString, required = true,
                                 default = nil)
  if valid_594299 != nil:
    section.add "networkId", valid_594299
  var valid_594300 = path.getOrDefault("proposalId")
  valid_594300 = validateParameter(valid_594300, JString, required = true,
                                 default = nil)
  if valid_594300 != nil:
    section.add "proposalId", valid_594300
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
  var valid_594301 = query.getOrDefault("NextToken")
  valid_594301 = validateParameter(valid_594301, JString, required = false,
                                 default = nil)
  if valid_594301 != nil:
    section.add "NextToken", valid_594301
  var valid_594302 = query.getOrDefault("maxResults")
  valid_594302 = validateParameter(valid_594302, JInt, required = false, default = nil)
  if valid_594302 != nil:
    section.add "maxResults", valid_594302
  var valid_594303 = query.getOrDefault("nextToken")
  valid_594303 = validateParameter(valid_594303, JString, required = false,
                                 default = nil)
  if valid_594303 != nil:
    section.add "nextToken", valid_594303
  var valid_594304 = query.getOrDefault("MaxResults")
  valid_594304 = validateParameter(valid_594304, JString, required = false,
                                 default = nil)
  if valid_594304 != nil:
    section.add "MaxResults", valid_594304
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
  var valid_594305 = header.getOrDefault("X-Amz-Date")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "X-Amz-Date", valid_594305
  var valid_594306 = header.getOrDefault("X-Amz-Security-Token")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "X-Amz-Security-Token", valid_594306
  var valid_594307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594307 = validateParameter(valid_594307, JString, required = false,
                                 default = nil)
  if valid_594307 != nil:
    section.add "X-Amz-Content-Sha256", valid_594307
  var valid_594308 = header.getOrDefault("X-Amz-Algorithm")
  valid_594308 = validateParameter(valid_594308, JString, required = false,
                                 default = nil)
  if valid_594308 != nil:
    section.add "X-Amz-Algorithm", valid_594308
  var valid_594309 = header.getOrDefault("X-Amz-Signature")
  valid_594309 = validateParameter(valid_594309, JString, required = false,
                                 default = nil)
  if valid_594309 != nil:
    section.add "X-Amz-Signature", valid_594309
  var valid_594310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594310 = validateParameter(valid_594310, JString, required = false,
                                 default = nil)
  if valid_594310 != nil:
    section.add "X-Amz-SignedHeaders", valid_594310
  var valid_594311 = header.getOrDefault("X-Amz-Credential")
  valid_594311 = validateParameter(valid_594311, JString, required = false,
                                 default = nil)
  if valid_594311 != nil:
    section.add "X-Amz-Credential", valid_594311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594312: Call_ListProposalVotes_594296; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the listing of votes for a specified proposal, including the value of each vote and the unique identifier of the member that cast the vote.
  ## 
  let valid = call_594312.validator(path, query, header, formData, body)
  let scheme = call_594312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594312.url(scheme.get, call_594312.host, call_594312.base,
                         call_594312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594312, url, valid)

proc call*(call_594313: Call_ListProposalVotes_594296; networkId: string;
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
  var path_594314 = newJObject()
  var query_594315 = newJObject()
  add(path_594314, "networkId", newJString(networkId))
  add(path_594314, "proposalId", newJString(proposalId))
  add(query_594315, "NextToken", newJString(NextToken))
  add(query_594315, "maxResults", newJInt(maxResults))
  add(query_594315, "nextToken", newJString(nextToken))
  add(query_594315, "MaxResults", newJString(MaxResults))
  result = call_594313.call(path_594314, query_594315, nil, nil, nil)

var listProposalVotes* = Call_ListProposalVotes_594296(name: "listProposalVotes",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals/{proposalId}/votes",
    validator: validate_ListProposalVotes_594297, base: "/",
    url: url_ListProposalVotes_594298, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectInvitation_594333 = ref object of OpenApiRestCall_593437
proc url_RejectInvitation_594335(protocol: Scheme; host: string; base: string;
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

proc validate_RejectInvitation_594334(path: JsonNode; query: JsonNode;
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
  var valid_594336 = path.getOrDefault("invitationId")
  valid_594336 = validateParameter(valid_594336, JString, required = true,
                                 default = nil)
  if valid_594336 != nil:
    section.add "invitationId", valid_594336
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
  var valid_594337 = header.getOrDefault("X-Amz-Date")
  valid_594337 = validateParameter(valid_594337, JString, required = false,
                                 default = nil)
  if valid_594337 != nil:
    section.add "X-Amz-Date", valid_594337
  var valid_594338 = header.getOrDefault("X-Amz-Security-Token")
  valid_594338 = validateParameter(valid_594338, JString, required = false,
                                 default = nil)
  if valid_594338 != nil:
    section.add "X-Amz-Security-Token", valid_594338
  var valid_594339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594339 = validateParameter(valid_594339, JString, required = false,
                                 default = nil)
  if valid_594339 != nil:
    section.add "X-Amz-Content-Sha256", valid_594339
  var valid_594340 = header.getOrDefault("X-Amz-Algorithm")
  valid_594340 = validateParameter(valid_594340, JString, required = false,
                                 default = nil)
  if valid_594340 != nil:
    section.add "X-Amz-Algorithm", valid_594340
  var valid_594341 = header.getOrDefault("X-Amz-Signature")
  valid_594341 = validateParameter(valid_594341, JString, required = false,
                                 default = nil)
  if valid_594341 != nil:
    section.add "X-Amz-Signature", valid_594341
  var valid_594342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594342 = validateParameter(valid_594342, JString, required = false,
                                 default = nil)
  if valid_594342 != nil:
    section.add "X-Amz-SignedHeaders", valid_594342
  var valid_594343 = header.getOrDefault("X-Amz-Credential")
  valid_594343 = validateParameter(valid_594343, JString, required = false,
                                 default = nil)
  if valid_594343 != nil:
    section.add "X-Amz-Credential", valid_594343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594344: Call_RejectInvitation_594333; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Rejects an invitation to join a network. This action can be called by a principal in an AWS account that has received an invitation to create a member and join a network.
  ## 
  let valid = call_594344.validator(path, query, header, formData, body)
  let scheme = call_594344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594344.url(scheme.get, call_594344.host, call_594344.base,
                         call_594344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594344, url, valid)

proc call*(call_594345: Call_RejectInvitation_594333; invitationId: string): Recallable =
  ## rejectInvitation
  ## Rejects an invitation to join a network. This action can be called by a principal in an AWS account that has received an invitation to create a member and join a network.
  ##   invitationId: string (required)
  ##               : The unique identifier of the invitation to reject.
  var path_594346 = newJObject()
  add(path_594346, "invitationId", newJString(invitationId))
  result = call_594345.call(path_594346, nil, nil, nil, nil)

var rejectInvitation* = Call_RejectInvitation_594333(name: "rejectInvitation",
    meth: HttpMethod.HttpDelete, host: "managedblockchain.amazonaws.com",
    route: "/invitations/{invitationId}", validator: validate_RejectInvitation_594334,
    base: "/", url: url_RejectInvitation_594335,
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
