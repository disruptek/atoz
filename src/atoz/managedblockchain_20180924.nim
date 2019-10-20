
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

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateMember_592994 = ref object of OpenApiRestCall_592364
proc url_CreateMember_592996(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMember_592995(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592997 = path.getOrDefault("networkId")
  valid_592997 = validateParameter(valid_592997, JString, required = true,
                                 default = nil)
  if valid_592997 != nil:
    section.add "networkId", valid_592997
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
  var valid_592998 = header.getOrDefault("X-Amz-Signature")
  valid_592998 = validateParameter(valid_592998, JString, required = false,
                                 default = nil)
  if valid_592998 != nil:
    section.add "X-Amz-Signature", valid_592998
  var valid_592999 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592999 = validateParameter(valid_592999, JString, required = false,
                                 default = nil)
  if valid_592999 != nil:
    section.add "X-Amz-Content-Sha256", valid_592999
  var valid_593000 = header.getOrDefault("X-Amz-Date")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-Date", valid_593000
  var valid_593001 = header.getOrDefault("X-Amz-Credential")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "X-Amz-Credential", valid_593001
  var valid_593002 = header.getOrDefault("X-Amz-Security-Token")
  valid_593002 = validateParameter(valid_593002, JString, required = false,
                                 default = nil)
  if valid_593002 != nil:
    section.add "X-Amz-Security-Token", valid_593002
  var valid_593003 = header.getOrDefault("X-Amz-Algorithm")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "X-Amz-Algorithm", valid_593003
  var valid_593004 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = nil)
  if valid_593004 != nil:
    section.add "X-Amz-SignedHeaders", valid_593004
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593006: Call_CreateMember_592994; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a member within a Managed Blockchain network.
  ## 
  let valid = call_593006.validator(path, query, header, formData, body)
  let scheme = call_593006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593006.url(scheme.get, call_593006.host, call_593006.base,
                         call_593006.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593006, url, valid)

proc call*(call_593007: Call_CreateMember_592994; networkId: string; body: JsonNode): Recallable =
  ## createMember
  ## Creates a member within a Managed Blockchain network.
  ##   networkId: string (required)
  ##            : The unique identifier of the network in which the member is created.
  ##   body: JObject (required)
  var path_593008 = newJObject()
  var body_593009 = newJObject()
  add(path_593008, "networkId", newJString(networkId))
  if body != nil:
    body_593009 = body
  result = call_593007.call(path_593008, nil, nil, nil, body_593009)

var createMember* = Call_CreateMember_592994(name: "createMember",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/members", validator: validate_CreateMember_592995,
    base: "/", url: url_CreateMember_592996, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_592703 = ref object of OpenApiRestCall_592364
proc url_ListMembers_592705(protocol: Scheme; host: string; base: string;
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

proc validate_ListMembers_592704(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592831 = path.getOrDefault("networkId")
  valid_592831 = validateParameter(valid_592831, JString, required = true,
                                 default = nil)
  if valid_592831 != nil:
    section.add "networkId", valid_592831
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
  var valid_592832 = query.getOrDefault("name")
  valid_592832 = validateParameter(valid_592832, JString, required = false,
                                 default = nil)
  if valid_592832 != nil:
    section.add "name", valid_592832
  var valid_592833 = query.getOrDefault("nextToken")
  valid_592833 = validateParameter(valid_592833, JString, required = false,
                                 default = nil)
  if valid_592833 != nil:
    section.add "nextToken", valid_592833
  var valid_592834 = query.getOrDefault("MaxResults")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "MaxResults", valid_592834
  var valid_592835 = query.getOrDefault("NextToken")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "NextToken", valid_592835
  var valid_592836 = query.getOrDefault("isOwned")
  valid_592836 = validateParameter(valid_592836, JBool, required = false, default = nil)
  if valid_592836 != nil:
    section.add "isOwned", valid_592836
  var valid_592850 = query.getOrDefault("status")
  valid_592850 = validateParameter(valid_592850, JString, required = false,
                                 default = newJString("CREATING"))
  if valid_592850 != nil:
    section.add "status", valid_592850
  var valid_592851 = query.getOrDefault("maxResults")
  valid_592851 = validateParameter(valid_592851, JInt, required = false, default = nil)
  if valid_592851 != nil:
    section.add "maxResults", valid_592851
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
  var valid_592852 = header.getOrDefault("X-Amz-Signature")
  valid_592852 = validateParameter(valid_592852, JString, required = false,
                                 default = nil)
  if valid_592852 != nil:
    section.add "X-Amz-Signature", valid_592852
  var valid_592853 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592853 = validateParameter(valid_592853, JString, required = false,
                                 default = nil)
  if valid_592853 != nil:
    section.add "X-Amz-Content-Sha256", valid_592853
  var valid_592854 = header.getOrDefault("X-Amz-Date")
  valid_592854 = validateParameter(valid_592854, JString, required = false,
                                 default = nil)
  if valid_592854 != nil:
    section.add "X-Amz-Date", valid_592854
  var valid_592855 = header.getOrDefault("X-Amz-Credential")
  valid_592855 = validateParameter(valid_592855, JString, required = false,
                                 default = nil)
  if valid_592855 != nil:
    section.add "X-Amz-Credential", valid_592855
  var valid_592856 = header.getOrDefault("X-Amz-Security-Token")
  valid_592856 = validateParameter(valid_592856, JString, required = false,
                                 default = nil)
  if valid_592856 != nil:
    section.add "X-Amz-Security-Token", valid_592856
  var valid_592857 = header.getOrDefault("X-Amz-Algorithm")
  valid_592857 = validateParameter(valid_592857, JString, required = false,
                                 default = nil)
  if valid_592857 != nil:
    section.add "X-Amz-Algorithm", valid_592857
  var valid_592858 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592858 = validateParameter(valid_592858, JString, required = false,
                                 default = nil)
  if valid_592858 != nil:
    section.add "X-Amz-SignedHeaders", valid_592858
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592881: Call_ListMembers_592703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a listing of the members in a network and properties of their configurations.
  ## 
  let valid = call_592881.validator(path, query, header, formData, body)
  let scheme = call_592881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592881.url(scheme.get, call_592881.host, call_592881.base,
                         call_592881.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592881, url, valid)

proc call*(call_592952: Call_ListMembers_592703; networkId: string;
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
  var path_592953 = newJObject()
  var query_592955 = newJObject()
  add(query_592955, "name", newJString(name))
  add(query_592955, "nextToken", newJString(nextToken))
  add(query_592955, "MaxResults", newJString(MaxResults))
  add(query_592955, "NextToken", newJString(NextToken))
  add(path_592953, "networkId", newJString(networkId))
  add(query_592955, "isOwned", newJBool(isOwned))
  add(query_592955, "status", newJString(status))
  add(query_592955, "maxResults", newJInt(maxResults))
  result = call_592952.call(path_592953, query_592955, nil, nil, nil)

var listMembers* = Call_ListMembers_592703(name: "listMembers",
                                        meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
                                        route: "/networks/{networkId}/members",
                                        validator: validate_ListMembers_592704,
                                        base: "/", url: url_ListMembers_592705,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNetwork_593030 = ref object of OpenApiRestCall_592364
proc url_CreateNetwork_593032(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateNetwork_593031(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593033 = header.getOrDefault("X-Amz-Signature")
  valid_593033 = validateParameter(valid_593033, JString, required = false,
                                 default = nil)
  if valid_593033 != nil:
    section.add "X-Amz-Signature", valid_593033
  var valid_593034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593034 = validateParameter(valid_593034, JString, required = false,
                                 default = nil)
  if valid_593034 != nil:
    section.add "X-Amz-Content-Sha256", valid_593034
  var valid_593035 = header.getOrDefault("X-Amz-Date")
  valid_593035 = validateParameter(valid_593035, JString, required = false,
                                 default = nil)
  if valid_593035 != nil:
    section.add "X-Amz-Date", valid_593035
  var valid_593036 = header.getOrDefault("X-Amz-Credential")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "X-Amz-Credential", valid_593036
  var valid_593037 = header.getOrDefault("X-Amz-Security-Token")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-Security-Token", valid_593037
  var valid_593038 = header.getOrDefault("X-Amz-Algorithm")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Algorithm", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-SignedHeaders", valid_593039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593041: Call_CreateNetwork_593030; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new blockchain network using Amazon Managed Blockchain.
  ## 
  let valid = call_593041.validator(path, query, header, formData, body)
  let scheme = call_593041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593041.url(scheme.get, call_593041.host, call_593041.base,
                         call_593041.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593041, url, valid)

proc call*(call_593042: Call_CreateNetwork_593030; body: JsonNode): Recallable =
  ## createNetwork
  ## Creates a new blockchain network using Amazon Managed Blockchain.
  ##   body: JObject (required)
  var body_593043 = newJObject()
  if body != nil:
    body_593043 = body
  result = call_593042.call(nil, nil, nil, nil, body_593043)

var createNetwork* = Call_CreateNetwork_593030(name: "createNetwork",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks", validator: validate_CreateNetwork_593031, base: "/",
    url: url_CreateNetwork_593032, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNetworks_593010 = ref object of OpenApiRestCall_592364
proc url_ListNetworks_593012(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListNetworks_593011(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593013 = query.getOrDefault("framework")
  valid_593013 = validateParameter(valid_593013, JString, required = false,
                                 default = newJString("HYPERLEDGER_FABRIC"))
  if valid_593013 != nil:
    section.add "framework", valid_593013
  var valid_593014 = query.getOrDefault("name")
  valid_593014 = validateParameter(valid_593014, JString, required = false,
                                 default = nil)
  if valid_593014 != nil:
    section.add "name", valid_593014
  var valid_593015 = query.getOrDefault("nextToken")
  valid_593015 = validateParameter(valid_593015, JString, required = false,
                                 default = nil)
  if valid_593015 != nil:
    section.add "nextToken", valid_593015
  var valid_593016 = query.getOrDefault("MaxResults")
  valid_593016 = validateParameter(valid_593016, JString, required = false,
                                 default = nil)
  if valid_593016 != nil:
    section.add "MaxResults", valid_593016
  var valid_593017 = query.getOrDefault("NextToken")
  valid_593017 = validateParameter(valid_593017, JString, required = false,
                                 default = nil)
  if valid_593017 != nil:
    section.add "NextToken", valid_593017
  var valid_593018 = query.getOrDefault("status")
  valid_593018 = validateParameter(valid_593018, JString, required = false,
                                 default = newJString("CREATING"))
  if valid_593018 != nil:
    section.add "status", valid_593018
  var valid_593019 = query.getOrDefault("maxResults")
  valid_593019 = validateParameter(valid_593019, JInt, required = false, default = nil)
  if valid_593019 != nil:
    section.add "maxResults", valid_593019
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
  var valid_593020 = header.getOrDefault("X-Amz-Signature")
  valid_593020 = validateParameter(valid_593020, JString, required = false,
                                 default = nil)
  if valid_593020 != nil:
    section.add "X-Amz-Signature", valid_593020
  var valid_593021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-Content-Sha256", valid_593021
  var valid_593022 = header.getOrDefault("X-Amz-Date")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Date", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-Credential")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-Credential", valid_593023
  var valid_593024 = header.getOrDefault("X-Amz-Security-Token")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Security-Token", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-Algorithm")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-Algorithm", valid_593025
  var valid_593026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-SignedHeaders", valid_593026
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593027: Call_ListNetworks_593010; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the networks in which the current AWS account has members.
  ## 
  let valid = call_593027.validator(path, query, header, formData, body)
  let scheme = call_593027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593027.url(scheme.get, call_593027.host, call_593027.base,
                         call_593027.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593027, url, valid)

proc call*(call_593028: Call_ListNetworks_593010;
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
  var query_593029 = newJObject()
  add(query_593029, "framework", newJString(framework))
  add(query_593029, "name", newJString(name))
  add(query_593029, "nextToken", newJString(nextToken))
  add(query_593029, "MaxResults", newJString(MaxResults))
  add(query_593029, "NextToken", newJString(NextToken))
  add(query_593029, "status", newJString(status))
  add(query_593029, "maxResults", newJInt(maxResults))
  result = call_593028.call(nil, query_593029, nil, nil, nil)

var listNetworks* = Call_ListNetworks_593010(name: "listNetworks",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks", validator: validate_ListNetworks_593011, base: "/",
    url: url_ListNetworks_593012, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNode_593065 = ref object of OpenApiRestCall_592364
proc url_CreateNode_593067(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateNode_593066(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593068 = path.getOrDefault("memberId")
  valid_593068 = validateParameter(valid_593068, JString, required = true,
                                 default = nil)
  if valid_593068 != nil:
    section.add "memberId", valid_593068
  var valid_593069 = path.getOrDefault("networkId")
  valid_593069 = validateParameter(valid_593069, JString, required = true,
                                 default = nil)
  if valid_593069 != nil:
    section.add "networkId", valid_593069
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
  var valid_593070 = header.getOrDefault("X-Amz-Signature")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "X-Amz-Signature", valid_593070
  var valid_593071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "X-Amz-Content-Sha256", valid_593071
  var valid_593072 = header.getOrDefault("X-Amz-Date")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "X-Amz-Date", valid_593072
  var valid_593073 = header.getOrDefault("X-Amz-Credential")
  valid_593073 = validateParameter(valid_593073, JString, required = false,
                                 default = nil)
  if valid_593073 != nil:
    section.add "X-Amz-Credential", valid_593073
  var valid_593074 = header.getOrDefault("X-Amz-Security-Token")
  valid_593074 = validateParameter(valid_593074, JString, required = false,
                                 default = nil)
  if valid_593074 != nil:
    section.add "X-Amz-Security-Token", valid_593074
  var valid_593075 = header.getOrDefault("X-Amz-Algorithm")
  valid_593075 = validateParameter(valid_593075, JString, required = false,
                                 default = nil)
  if valid_593075 != nil:
    section.add "X-Amz-Algorithm", valid_593075
  var valid_593076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593076 = validateParameter(valid_593076, JString, required = false,
                                 default = nil)
  if valid_593076 != nil:
    section.add "X-Amz-SignedHeaders", valid_593076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593078: Call_CreateNode_593065; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a peer node in a member.
  ## 
  let valid = call_593078.validator(path, query, header, formData, body)
  let scheme = call_593078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593078.url(scheme.get, call_593078.host, call_593078.base,
                         call_593078.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593078, url, valid)

proc call*(call_593079: Call_CreateNode_593065; memberId: string; networkId: string;
          body: JsonNode): Recallable =
  ## createNode
  ## Creates a peer node in a member.
  ##   memberId: string (required)
  ##           : The unique identifier of the member that owns this node.
  ##   networkId: string (required)
  ##            : The unique identifier of the network in which this node runs.
  ##   body: JObject (required)
  var path_593080 = newJObject()
  var body_593081 = newJObject()
  add(path_593080, "memberId", newJString(memberId))
  add(path_593080, "networkId", newJString(networkId))
  if body != nil:
    body_593081 = body
  result = call_593079.call(path_593080, nil, nil, nil, body_593081)

var createNode* = Call_CreateNode_593065(name: "createNode",
                                      meth: HttpMethod.HttpPost,
                                      host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes",
                                      validator: validate_CreateNode_593066,
                                      base: "/", url: url_CreateNode_593067,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNodes_593044 = ref object of OpenApiRestCall_592364
proc url_ListNodes_593046(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListNodes_593045(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593047 = path.getOrDefault("memberId")
  valid_593047 = validateParameter(valid_593047, JString, required = true,
                                 default = nil)
  if valid_593047 != nil:
    section.add "memberId", valid_593047
  var valid_593048 = path.getOrDefault("networkId")
  valid_593048 = validateParameter(valid_593048, JString, required = true,
                                 default = nil)
  if valid_593048 != nil:
    section.add "networkId", valid_593048
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
  var valid_593049 = query.getOrDefault("nextToken")
  valid_593049 = validateParameter(valid_593049, JString, required = false,
                                 default = nil)
  if valid_593049 != nil:
    section.add "nextToken", valid_593049
  var valid_593050 = query.getOrDefault("MaxResults")
  valid_593050 = validateParameter(valid_593050, JString, required = false,
                                 default = nil)
  if valid_593050 != nil:
    section.add "MaxResults", valid_593050
  var valid_593051 = query.getOrDefault("NextToken")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "NextToken", valid_593051
  var valid_593052 = query.getOrDefault("status")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = newJString("CREATING"))
  if valid_593052 != nil:
    section.add "status", valid_593052
  var valid_593053 = query.getOrDefault("maxResults")
  valid_593053 = validateParameter(valid_593053, JInt, required = false, default = nil)
  if valid_593053 != nil:
    section.add "maxResults", valid_593053
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
  var valid_593054 = header.getOrDefault("X-Amz-Signature")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-Signature", valid_593054
  var valid_593055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Content-Sha256", valid_593055
  var valid_593056 = header.getOrDefault("X-Amz-Date")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "X-Amz-Date", valid_593056
  var valid_593057 = header.getOrDefault("X-Amz-Credential")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "X-Amz-Credential", valid_593057
  var valid_593058 = header.getOrDefault("X-Amz-Security-Token")
  valid_593058 = validateParameter(valid_593058, JString, required = false,
                                 default = nil)
  if valid_593058 != nil:
    section.add "X-Amz-Security-Token", valid_593058
  var valid_593059 = header.getOrDefault("X-Amz-Algorithm")
  valid_593059 = validateParameter(valid_593059, JString, required = false,
                                 default = nil)
  if valid_593059 != nil:
    section.add "X-Amz-Algorithm", valid_593059
  var valid_593060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593060 = validateParameter(valid_593060, JString, required = false,
                                 default = nil)
  if valid_593060 != nil:
    section.add "X-Amz-SignedHeaders", valid_593060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593061: Call_ListNodes_593044; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the nodes within a network.
  ## 
  let valid = call_593061.validator(path, query, header, formData, body)
  let scheme = call_593061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593061.url(scheme.get, call_593061.host, call_593061.base,
                         call_593061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593061, url, valid)

proc call*(call_593062: Call_ListNodes_593044; memberId: string; networkId: string;
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
  var path_593063 = newJObject()
  var query_593064 = newJObject()
  add(query_593064, "nextToken", newJString(nextToken))
  add(path_593063, "memberId", newJString(memberId))
  add(query_593064, "MaxResults", newJString(MaxResults))
  add(query_593064, "NextToken", newJString(NextToken))
  add(path_593063, "networkId", newJString(networkId))
  add(query_593064, "status", newJString(status))
  add(query_593064, "maxResults", newJInt(maxResults))
  result = call_593062.call(path_593063, query_593064, nil, nil, nil)

var listNodes* = Call_ListNodes_593044(name: "listNodes", meth: HttpMethod.HttpGet,
                                    host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes",
                                    validator: validate_ListNodes_593045,
                                    base: "/", url: url_ListNodes_593046,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProposal_593101 = ref object of OpenApiRestCall_592364
proc url_CreateProposal_593103(protocol: Scheme; host: string; base: string;
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

proc validate_CreateProposal_593102(path: JsonNode; query: JsonNode;
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
  var valid_593104 = path.getOrDefault("networkId")
  valid_593104 = validateParameter(valid_593104, JString, required = true,
                                 default = nil)
  if valid_593104 != nil:
    section.add "networkId", valid_593104
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
  var valid_593105 = header.getOrDefault("X-Amz-Signature")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "X-Amz-Signature", valid_593105
  var valid_593106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593106 = validateParameter(valid_593106, JString, required = false,
                                 default = nil)
  if valid_593106 != nil:
    section.add "X-Amz-Content-Sha256", valid_593106
  var valid_593107 = header.getOrDefault("X-Amz-Date")
  valid_593107 = validateParameter(valid_593107, JString, required = false,
                                 default = nil)
  if valid_593107 != nil:
    section.add "X-Amz-Date", valid_593107
  var valid_593108 = header.getOrDefault("X-Amz-Credential")
  valid_593108 = validateParameter(valid_593108, JString, required = false,
                                 default = nil)
  if valid_593108 != nil:
    section.add "X-Amz-Credential", valid_593108
  var valid_593109 = header.getOrDefault("X-Amz-Security-Token")
  valid_593109 = validateParameter(valid_593109, JString, required = false,
                                 default = nil)
  if valid_593109 != nil:
    section.add "X-Amz-Security-Token", valid_593109
  var valid_593110 = header.getOrDefault("X-Amz-Algorithm")
  valid_593110 = validateParameter(valid_593110, JString, required = false,
                                 default = nil)
  if valid_593110 != nil:
    section.add "X-Amz-Algorithm", valid_593110
  var valid_593111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593111 = validateParameter(valid_593111, JString, required = false,
                                 default = nil)
  if valid_593111 != nil:
    section.add "X-Amz-SignedHeaders", valid_593111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593113: Call_CreateProposal_593101; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a proposal for a change to the network that other members of the network can vote on, for example, a proposal to add a new member to the network. Any member can create a proposal.
  ## 
  let valid = call_593113.validator(path, query, header, formData, body)
  let scheme = call_593113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593113.url(scheme.get, call_593113.host, call_593113.base,
                         call_593113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593113, url, valid)

proc call*(call_593114: Call_CreateProposal_593101; networkId: string; body: JsonNode): Recallable =
  ## createProposal
  ## Creates a proposal for a change to the network that other members of the network can vote on, for example, a proposal to add a new member to the network. Any member can create a proposal.
  ##   networkId: string (required)
  ##            :  The unique identifier of the network for which the proposal is made.
  ##   body: JObject (required)
  var path_593115 = newJObject()
  var body_593116 = newJObject()
  add(path_593115, "networkId", newJString(networkId))
  if body != nil:
    body_593116 = body
  result = call_593114.call(path_593115, nil, nil, nil, body_593116)

var createProposal* = Call_CreateProposal_593101(name: "createProposal",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals", validator: validate_CreateProposal_593102,
    base: "/", url: url_CreateProposal_593103, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProposals_593082 = ref object of OpenApiRestCall_592364
proc url_ListProposals_593084(protocol: Scheme; host: string; base: string;
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

proc validate_ListProposals_593083(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593085 = path.getOrDefault("networkId")
  valid_593085 = validateParameter(valid_593085, JString, required = true,
                                 default = nil)
  if valid_593085 != nil:
    section.add "networkId", valid_593085
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
  var valid_593086 = query.getOrDefault("nextToken")
  valid_593086 = validateParameter(valid_593086, JString, required = false,
                                 default = nil)
  if valid_593086 != nil:
    section.add "nextToken", valid_593086
  var valid_593087 = query.getOrDefault("MaxResults")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "MaxResults", valid_593087
  var valid_593088 = query.getOrDefault("NextToken")
  valid_593088 = validateParameter(valid_593088, JString, required = false,
                                 default = nil)
  if valid_593088 != nil:
    section.add "NextToken", valid_593088
  var valid_593089 = query.getOrDefault("maxResults")
  valid_593089 = validateParameter(valid_593089, JInt, required = false, default = nil)
  if valid_593089 != nil:
    section.add "maxResults", valid_593089
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
  var valid_593090 = header.getOrDefault("X-Amz-Signature")
  valid_593090 = validateParameter(valid_593090, JString, required = false,
                                 default = nil)
  if valid_593090 != nil:
    section.add "X-Amz-Signature", valid_593090
  var valid_593091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593091 = validateParameter(valid_593091, JString, required = false,
                                 default = nil)
  if valid_593091 != nil:
    section.add "X-Amz-Content-Sha256", valid_593091
  var valid_593092 = header.getOrDefault("X-Amz-Date")
  valid_593092 = validateParameter(valid_593092, JString, required = false,
                                 default = nil)
  if valid_593092 != nil:
    section.add "X-Amz-Date", valid_593092
  var valid_593093 = header.getOrDefault("X-Amz-Credential")
  valid_593093 = validateParameter(valid_593093, JString, required = false,
                                 default = nil)
  if valid_593093 != nil:
    section.add "X-Amz-Credential", valid_593093
  var valid_593094 = header.getOrDefault("X-Amz-Security-Token")
  valid_593094 = validateParameter(valid_593094, JString, required = false,
                                 default = nil)
  if valid_593094 != nil:
    section.add "X-Amz-Security-Token", valid_593094
  var valid_593095 = header.getOrDefault("X-Amz-Algorithm")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "X-Amz-Algorithm", valid_593095
  var valid_593096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "X-Amz-SignedHeaders", valid_593096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593097: Call_ListProposals_593082; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a listing of proposals for the network.
  ## 
  let valid = call_593097.validator(path, query, header, formData, body)
  let scheme = call_593097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593097.url(scheme.get, call_593097.host, call_593097.base,
                         call_593097.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593097, url, valid)

proc call*(call_593098: Call_ListProposals_593082; networkId: string;
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
  var path_593099 = newJObject()
  var query_593100 = newJObject()
  add(query_593100, "nextToken", newJString(nextToken))
  add(query_593100, "MaxResults", newJString(MaxResults))
  add(query_593100, "NextToken", newJString(NextToken))
  add(path_593099, "networkId", newJString(networkId))
  add(query_593100, "maxResults", newJInt(maxResults))
  result = call_593098.call(path_593099, query_593100, nil, nil, nil)

var listProposals* = Call_ListProposals_593082(name: "listProposals",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals", validator: validate_ListProposals_593083,
    base: "/", url: url_ListProposals_593084, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMember_593117 = ref object of OpenApiRestCall_592364
proc url_GetMember_593119(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetMember_593118(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593120 = path.getOrDefault("memberId")
  valid_593120 = validateParameter(valid_593120, JString, required = true,
                                 default = nil)
  if valid_593120 != nil:
    section.add "memberId", valid_593120
  var valid_593121 = path.getOrDefault("networkId")
  valid_593121 = validateParameter(valid_593121, JString, required = true,
                                 default = nil)
  if valid_593121 != nil:
    section.add "networkId", valid_593121
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
  var valid_593122 = header.getOrDefault("X-Amz-Signature")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "X-Amz-Signature", valid_593122
  var valid_593123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "X-Amz-Content-Sha256", valid_593123
  var valid_593124 = header.getOrDefault("X-Amz-Date")
  valid_593124 = validateParameter(valid_593124, JString, required = false,
                                 default = nil)
  if valid_593124 != nil:
    section.add "X-Amz-Date", valid_593124
  var valid_593125 = header.getOrDefault("X-Amz-Credential")
  valid_593125 = validateParameter(valid_593125, JString, required = false,
                                 default = nil)
  if valid_593125 != nil:
    section.add "X-Amz-Credential", valid_593125
  var valid_593126 = header.getOrDefault("X-Amz-Security-Token")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "X-Amz-Security-Token", valid_593126
  var valid_593127 = header.getOrDefault("X-Amz-Algorithm")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "X-Amz-Algorithm", valid_593127
  var valid_593128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "X-Amz-SignedHeaders", valid_593128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593129: Call_GetMember_593117; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a member.
  ## 
  let valid = call_593129.validator(path, query, header, formData, body)
  let scheme = call_593129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593129.url(scheme.get, call_593129.host, call_593129.base,
                         call_593129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593129, url, valid)

proc call*(call_593130: Call_GetMember_593117; memberId: string; networkId: string): Recallable =
  ## getMember
  ## Returns detailed information about a member.
  ##   memberId: string (required)
  ##           : The unique identifier of the member.
  ##   networkId: string (required)
  ##            : The unique identifier of the network to which the member belongs.
  var path_593131 = newJObject()
  add(path_593131, "memberId", newJString(memberId))
  add(path_593131, "networkId", newJString(networkId))
  result = call_593130.call(path_593131, nil, nil, nil, nil)

var getMember* = Call_GetMember_593117(name: "getMember", meth: HttpMethod.HttpGet,
                                    host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}",
                                    validator: validate_GetMember_593118,
                                    base: "/", url: url_GetMember_593119,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMember_593132 = ref object of OpenApiRestCall_592364
proc url_DeleteMember_593134(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMember_593133(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593135 = path.getOrDefault("memberId")
  valid_593135 = validateParameter(valid_593135, JString, required = true,
                                 default = nil)
  if valid_593135 != nil:
    section.add "memberId", valid_593135
  var valid_593136 = path.getOrDefault("networkId")
  valid_593136 = validateParameter(valid_593136, JString, required = true,
                                 default = nil)
  if valid_593136 != nil:
    section.add "networkId", valid_593136
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
  var valid_593137 = header.getOrDefault("X-Amz-Signature")
  valid_593137 = validateParameter(valid_593137, JString, required = false,
                                 default = nil)
  if valid_593137 != nil:
    section.add "X-Amz-Signature", valid_593137
  var valid_593138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "X-Amz-Content-Sha256", valid_593138
  var valid_593139 = header.getOrDefault("X-Amz-Date")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "X-Amz-Date", valid_593139
  var valid_593140 = header.getOrDefault("X-Amz-Credential")
  valid_593140 = validateParameter(valid_593140, JString, required = false,
                                 default = nil)
  if valid_593140 != nil:
    section.add "X-Amz-Credential", valid_593140
  var valid_593141 = header.getOrDefault("X-Amz-Security-Token")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "X-Amz-Security-Token", valid_593141
  var valid_593142 = header.getOrDefault("X-Amz-Algorithm")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "X-Amz-Algorithm", valid_593142
  var valid_593143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "X-Amz-SignedHeaders", valid_593143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593144: Call_DeleteMember_593132; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a member. Deleting a member removes the member and all associated resources from the network. <code>DeleteMember</code> can only be called for a specified <code>MemberId</code> if the principal performing the action is associated with the AWS account that owns the member. In all other cases, the <code>DeleteMember</code> action is carried out as the result of an approved proposal to remove a member. If <code>MemberId</code> is the last member in a network specified by the last AWS account, the network is deleted also.
  ## 
  let valid = call_593144.validator(path, query, header, formData, body)
  let scheme = call_593144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593144.url(scheme.get, call_593144.host, call_593144.base,
                         call_593144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593144, url, valid)

proc call*(call_593145: Call_DeleteMember_593132; memberId: string; networkId: string): Recallable =
  ## deleteMember
  ## Deletes a member. Deleting a member removes the member and all associated resources from the network. <code>DeleteMember</code> can only be called for a specified <code>MemberId</code> if the principal performing the action is associated with the AWS account that owns the member. In all other cases, the <code>DeleteMember</code> action is carried out as the result of an approved proposal to remove a member. If <code>MemberId</code> is the last member in a network specified by the last AWS account, the network is deleted also.
  ##   memberId: string (required)
  ##           : The unique identifier of the member to remove.
  ##   networkId: string (required)
  ##            : The unique identifier of the network from which the member is removed.
  var path_593146 = newJObject()
  add(path_593146, "memberId", newJString(memberId))
  add(path_593146, "networkId", newJString(networkId))
  result = call_593145.call(path_593146, nil, nil, nil, nil)

var deleteMember* = Call_DeleteMember_593132(name: "deleteMember",
    meth: HttpMethod.HttpDelete, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/members/{memberId}",
    validator: validate_DeleteMember_593133, base: "/", url: url_DeleteMember_593134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNode_593147 = ref object of OpenApiRestCall_592364
proc url_GetNode_593149(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetNode_593148(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593150 = path.getOrDefault("memberId")
  valid_593150 = validateParameter(valid_593150, JString, required = true,
                                 default = nil)
  if valid_593150 != nil:
    section.add "memberId", valid_593150
  var valid_593151 = path.getOrDefault("networkId")
  valid_593151 = validateParameter(valid_593151, JString, required = true,
                                 default = nil)
  if valid_593151 != nil:
    section.add "networkId", valid_593151
  var valid_593152 = path.getOrDefault("nodeId")
  valid_593152 = validateParameter(valid_593152, JString, required = true,
                                 default = nil)
  if valid_593152 != nil:
    section.add "nodeId", valid_593152
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
  var valid_593153 = header.getOrDefault("X-Amz-Signature")
  valid_593153 = validateParameter(valid_593153, JString, required = false,
                                 default = nil)
  if valid_593153 != nil:
    section.add "X-Amz-Signature", valid_593153
  var valid_593154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593154 = validateParameter(valid_593154, JString, required = false,
                                 default = nil)
  if valid_593154 != nil:
    section.add "X-Amz-Content-Sha256", valid_593154
  var valid_593155 = header.getOrDefault("X-Amz-Date")
  valid_593155 = validateParameter(valid_593155, JString, required = false,
                                 default = nil)
  if valid_593155 != nil:
    section.add "X-Amz-Date", valid_593155
  var valid_593156 = header.getOrDefault("X-Amz-Credential")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "X-Amz-Credential", valid_593156
  var valid_593157 = header.getOrDefault("X-Amz-Security-Token")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "X-Amz-Security-Token", valid_593157
  var valid_593158 = header.getOrDefault("X-Amz-Algorithm")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "X-Amz-Algorithm", valid_593158
  var valid_593159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "X-Amz-SignedHeaders", valid_593159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593160: Call_GetNode_593147; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a peer node.
  ## 
  let valid = call_593160.validator(path, query, header, formData, body)
  let scheme = call_593160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593160.url(scheme.get, call_593160.host, call_593160.base,
                         call_593160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593160, url, valid)

proc call*(call_593161: Call_GetNode_593147; memberId: string; networkId: string;
          nodeId: string): Recallable =
  ## getNode
  ## Returns detailed information about a peer node.
  ##   memberId: string (required)
  ##           : The unique identifier of the member that owns the node.
  ##   networkId: string (required)
  ##            : The unique identifier of the network to which the node belongs.
  ##   nodeId: string (required)
  ##         : The unique identifier of the node.
  var path_593162 = newJObject()
  add(path_593162, "memberId", newJString(memberId))
  add(path_593162, "networkId", newJString(networkId))
  add(path_593162, "nodeId", newJString(nodeId))
  result = call_593161.call(path_593162, nil, nil, nil, nil)

var getNode* = Call_GetNode_593147(name: "getNode", meth: HttpMethod.HttpGet,
                                host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes/{nodeId}",
                                validator: validate_GetNode_593148, base: "/",
                                url: url_GetNode_593149,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNode_593163 = ref object of OpenApiRestCall_592364
proc url_DeleteNode_593165(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteNode_593164(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593166 = path.getOrDefault("memberId")
  valid_593166 = validateParameter(valid_593166, JString, required = true,
                                 default = nil)
  if valid_593166 != nil:
    section.add "memberId", valid_593166
  var valid_593167 = path.getOrDefault("networkId")
  valid_593167 = validateParameter(valid_593167, JString, required = true,
                                 default = nil)
  if valid_593167 != nil:
    section.add "networkId", valid_593167
  var valid_593168 = path.getOrDefault("nodeId")
  valid_593168 = validateParameter(valid_593168, JString, required = true,
                                 default = nil)
  if valid_593168 != nil:
    section.add "nodeId", valid_593168
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
  var valid_593169 = header.getOrDefault("X-Amz-Signature")
  valid_593169 = validateParameter(valid_593169, JString, required = false,
                                 default = nil)
  if valid_593169 != nil:
    section.add "X-Amz-Signature", valid_593169
  var valid_593170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593170 = validateParameter(valid_593170, JString, required = false,
                                 default = nil)
  if valid_593170 != nil:
    section.add "X-Amz-Content-Sha256", valid_593170
  var valid_593171 = header.getOrDefault("X-Amz-Date")
  valid_593171 = validateParameter(valid_593171, JString, required = false,
                                 default = nil)
  if valid_593171 != nil:
    section.add "X-Amz-Date", valid_593171
  var valid_593172 = header.getOrDefault("X-Amz-Credential")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = nil)
  if valid_593172 != nil:
    section.add "X-Amz-Credential", valid_593172
  var valid_593173 = header.getOrDefault("X-Amz-Security-Token")
  valid_593173 = validateParameter(valid_593173, JString, required = false,
                                 default = nil)
  if valid_593173 != nil:
    section.add "X-Amz-Security-Token", valid_593173
  var valid_593174 = header.getOrDefault("X-Amz-Algorithm")
  valid_593174 = validateParameter(valid_593174, JString, required = false,
                                 default = nil)
  if valid_593174 != nil:
    section.add "X-Amz-Algorithm", valid_593174
  var valid_593175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593175 = validateParameter(valid_593175, JString, required = false,
                                 default = nil)
  if valid_593175 != nil:
    section.add "X-Amz-SignedHeaders", valid_593175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593176: Call_DeleteNode_593163; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a peer node from a member that your AWS account owns. All data on the node is lost and cannot be recovered.
  ## 
  let valid = call_593176.validator(path, query, header, formData, body)
  let scheme = call_593176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593176.url(scheme.get, call_593176.host, call_593176.base,
                         call_593176.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593176, url, valid)

proc call*(call_593177: Call_DeleteNode_593163; memberId: string; networkId: string;
          nodeId: string): Recallable =
  ## deleteNode
  ## Deletes a peer node from a member that your AWS account owns. All data on the node is lost and cannot be recovered.
  ##   memberId: string (required)
  ##           : The unique identifier of the member that owns this node.
  ##   networkId: string (required)
  ##            : The unique identifier of the network that the node belongs to.
  ##   nodeId: string (required)
  ##         : The unique identifier of the node.
  var path_593178 = newJObject()
  add(path_593178, "memberId", newJString(memberId))
  add(path_593178, "networkId", newJString(networkId))
  add(path_593178, "nodeId", newJString(nodeId))
  result = call_593177.call(path_593178, nil, nil, nil, nil)

var deleteNode* = Call_DeleteNode_593163(name: "deleteNode",
                                      meth: HttpMethod.HttpDelete,
                                      host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes/{nodeId}",
                                      validator: validate_DeleteNode_593164,
                                      base: "/", url: url_DeleteNode_593165,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNetwork_593179 = ref object of OpenApiRestCall_592364
proc url_GetNetwork_593181(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetNetwork_593180(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593182 = path.getOrDefault("networkId")
  valid_593182 = validateParameter(valid_593182, JString, required = true,
                                 default = nil)
  if valid_593182 != nil:
    section.add "networkId", valid_593182
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
  var valid_593183 = header.getOrDefault("X-Amz-Signature")
  valid_593183 = validateParameter(valid_593183, JString, required = false,
                                 default = nil)
  if valid_593183 != nil:
    section.add "X-Amz-Signature", valid_593183
  var valid_593184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593184 = validateParameter(valid_593184, JString, required = false,
                                 default = nil)
  if valid_593184 != nil:
    section.add "X-Amz-Content-Sha256", valid_593184
  var valid_593185 = header.getOrDefault("X-Amz-Date")
  valid_593185 = validateParameter(valid_593185, JString, required = false,
                                 default = nil)
  if valid_593185 != nil:
    section.add "X-Amz-Date", valid_593185
  var valid_593186 = header.getOrDefault("X-Amz-Credential")
  valid_593186 = validateParameter(valid_593186, JString, required = false,
                                 default = nil)
  if valid_593186 != nil:
    section.add "X-Amz-Credential", valid_593186
  var valid_593187 = header.getOrDefault("X-Amz-Security-Token")
  valid_593187 = validateParameter(valid_593187, JString, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "X-Amz-Security-Token", valid_593187
  var valid_593188 = header.getOrDefault("X-Amz-Algorithm")
  valid_593188 = validateParameter(valid_593188, JString, required = false,
                                 default = nil)
  if valid_593188 != nil:
    section.add "X-Amz-Algorithm", valid_593188
  var valid_593189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "X-Amz-SignedHeaders", valid_593189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593190: Call_GetNetwork_593179; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a network.
  ## 
  let valid = call_593190.validator(path, query, header, formData, body)
  let scheme = call_593190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593190.url(scheme.get, call_593190.host, call_593190.base,
                         call_593190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593190, url, valid)

proc call*(call_593191: Call_GetNetwork_593179; networkId: string): Recallable =
  ## getNetwork
  ## Returns detailed information about a network.
  ##   networkId: string (required)
  ##            : The unique identifier of the network to get information about.
  var path_593192 = newJObject()
  add(path_593192, "networkId", newJString(networkId))
  result = call_593191.call(path_593192, nil, nil, nil, nil)

var getNetwork* = Call_GetNetwork_593179(name: "getNetwork",
                                      meth: HttpMethod.HttpGet,
                                      host: "managedblockchain.amazonaws.com",
                                      route: "/networks/{networkId}",
                                      validator: validate_GetNetwork_593180,
                                      base: "/", url: url_GetNetwork_593181,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProposal_593193 = ref object of OpenApiRestCall_592364
proc url_GetProposal_593195(protocol: Scheme; host: string; base: string;
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

proc validate_GetProposal_593194(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593196 = path.getOrDefault("proposalId")
  valid_593196 = validateParameter(valid_593196, JString, required = true,
                                 default = nil)
  if valid_593196 != nil:
    section.add "proposalId", valid_593196
  var valid_593197 = path.getOrDefault("networkId")
  valid_593197 = validateParameter(valid_593197, JString, required = true,
                                 default = nil)
  if valid_593197 != nil:
    section.add "networkId", valid_593197
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
  var valid_593198 = header.getOrDefault("X-Amz-Signature")
  valid_593198 = validateParameter(valid_593198, JString, required = false,
                                 default = nil)
  if valid_593198 != nil:
    section.add "X-Amz-Signature", valid_593198
  var valid_593199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593199 = validateParameter(valid_593199, JString, required = false,
                                 default = nil)
  if valid_593199 != nil:
    section.add "X-Amz-Content-Sha256", valid_593199
  var valid_593200 = header.getOrDefault("X-Amz-Date")
  valid_593200 = validateParameter(valid_593200, JString, required = false,
                                 default = nil)
  if valid_593200 != nil:
    section.add "X-Amz-Date", valid_593200
  var valid_593201 = header.getOrDefault("X-Amz-Credential")
  valid_593201 = validateParameter(valid_593201, JString, required = false,
                                 default = nil)
  if valid_593201 != nil:
    section.add "X-Amz-Credential", valid_593201
  var valid_593202 = header.getOrDefault("X-Amz-Security-Token")
  valid_593202 = validateParameter(valid_593202, JString, required = false,
                                 default = nil)
  if valid_593202 != nil:
    section.add "X-Amz-Security-Token", valid_593202
  var valid_593203 = header.getOrDefault("X-Amz-Algorithm")
  valid_593203 = validateParameter(valid_593203, JString, required = false,
                                 default = nil)
  if valid_593203 != nil:
    section.add "X-Amz-Algorithm", valid_593203
  var valid_593204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "X-Amz-SignedHeaders", valid_593204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593205: Call_GetProposal_593193; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a proposal.
  ## 
  let valid = call_593205.validator(path, query, header, formData, body)
  let scheme = call_593205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593205.url(scheme.get, call_593205.host, call_593205.base,
                         call_593205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593205, url, valid)

proc call*(call_593206: Call_GetProposal_593193; proposalId: string;
          networkId: string): Recallable =
  ## getProposal
  ## Returns detailed information about a proposal.
  ##   proposalId: string (required)
  ##             : The unique identifier of the proposal.
  ##   networkId: string (required)
  ##            : The unique identifier of the network for which the proposal is made.
  var path_593207 = newJObject()
  add(path_593207, "proposalId", newJString(proposalId))
  add(path_593207, "networkId", newJString(networkId))
  result = call_593206.call(path_593207, nil, nil, nil, nil)

var getProposal* = Call_GetProposal_593193(name: "getProposal",
                                        meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/proposals/{proposalId}",
                                        validator: validate_GetProposal_593194,
                                        base: "/", url: url_GetProposal_593195,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_593208 = ref object of OpenApiRestCall_592364
proc url_ListInvitations_593210(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListInvitations_593209(path: JsonNode; query: JsonNode;
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
  var valid_593211 = query.getOrDefault("nextToken")
  valid_593211 = validateParameter(valid_593211, JString, required = false,
                                 default = nil)
  if valid_593211 != nil:
    section.add "nextToken", valid_593211
  var valid_593212 = query.getOrDefault("MaxResults")
  valid_593212 = validateParameter(valid_593212, JString, required = false,
                                 default = nil)
  if valid_593212 != nil:
    section.add "MaxResults", valid_593212
  var valid_593213 = query.getOrDefault("NextToken")
  valid_593213 = validateParameter(valid_593213, JString, required = false,
                                 default = nil)
  if valid_593213 != nil:
    section.add "NextToken", valid_593213
  var valid_593214 = query.getOrDefault("maxResults")
  valid_593214 = validateParameter(valid_593214, JInt, required = false, default = nil)
  if valid_593214 != nil:
    section.add "maxResults", valid_593214
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
  var valid_593215 = header.getOrDefault("X-Amz-Signature")
  valid_593215 = validateParameter(valid_593215, JString, required = false,
                                 default = nil)
  if valid_593215 != nil:
    section.add "X-Amz-Signature", valid_593215
  var valid_593216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593216 = validateParameter(valid_593216, JString, required = false,
                                 default = nil)
  if valid_593216 != nil:
    section.add "X-Amz-Content-Sha256", valid_593216
  var valid_593217 = header.getOrDefault("X-Amz-Date")
  valid_593217 = validateParameter(valid_593217, JString, required = false,
                                 default = nil)
  if valid_593217 != nil:
    section.add "X-Amz-Date", valid_593217
  var valid_593218 = header.getOrDefault("X-Amz-Credential")
  valid_593218 = validateParameter(valid_593218, JString, required = false,
                                 default = nil)
  if valid_593218 != nil:
    section.add "X-Amz-Credential", valid_593218
  var valid_593219 = header.getOrDefault("X-Amz-Security-Token")
  valid_593219 = validateParameter(valid_593219, JString, required = false,
                                 default = nil)
  if valid_593219 != nil:
    section.add "X-Amz-Security-Token", valid_593219
  var valid_593220 = header.getOrDefault("X-Amz-Algorithm")
  valid_593220 = validateParameter(valid_593220, JString, required = false,
                                 default = nil)
  if valid_593220 != nil:
    section.add "X-Amz-Algorithm", valid_593220
  var valid_593221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593221 = validateParameter(valid_593221, JString, required = false,
                                 default = nil)
  if valid_593221 != nil:
    section.add "X-Amz-SignedHeaders", valid_593221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593222: Call_ListInvitations_593208; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a listing of all invitations made on the specified network.
  ## 
  let valid = call_593222.validator(path, query, header, formData, body)
  let scheme = call_593222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593222.url(scheme.get, call_593222.host, call_593222.base,
                         call_593222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593222, url, valid)

proc call*(call_593223: Call_ListInvitations_593208; nextToken: string = "";
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
  var query_593224 = newJObject()
  add(query_593224, "nextToken", newJString(nextToken))
  add(query_593224, "MaxResults", newJString(MaxResults))
  add(query_593224, "NextToken", newJString(NextToken))
  add(query_593224, "maxResults", newJInt(maxResults))
  result = call_593223.call(nil, query_593224, nil, nil, nil)

var listInvitations* = Call_ListInvitations_593208(name: "listInvitations",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/invitations", validator: validate_ListInvitations_593209, base: "/",
    url: url_ListInvitations_593210, schemes: {Scheme.Https, Scheme.Http})
type
  Call_VoteOnProposal_593245 = ref object of OpenApiRestCall_592364
proc url_VoteOnProposal_593247(protocol: Scheme; host: string; base: string;
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

proc validate_VoteOnProposal_593246(path: JsonNode; query: JsonNode;
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
  var valid_593248 = path.getOrDefault("proposalId")
  valid_593248 = validateParameter(valid_593248, JString, required = true,
                                 default = nil)
  if valid_593248 != nil:
    section.add "proposalId", valid_593248
  var valid_593249 = path.getOrDefault("networkId")
  valid_593249 = validateParameter(valid_593249, JString, required = true,
                                 default = nil)
  if valid_593249 != nil:
    section.add "networkId", valid_593249
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
  var valid_593250 = header.getOrDefault("X-Amz-Signature")
  valid_593250 = validateParameter(valid_593250, JString, required = false,
                                 default = nil)
  if valid_593250 != nil:
    section.add "X-Amz-Signature", valid_593250
  var valid_593251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593251 = validateParameter(valid_593251, JString, required = false,
                                 default = nil)
  if valid_593251 != nil:
    section.add "X-Amz-Content-Sha256", valid_593251
  var valid_593252 = header.getOrDefault("X-Amz-Date")
  valid_593252 = validateParameter(valid_593252, JString, required = false,
                                 default = nil)
  if valid_593252 != nil:
    section.add "X-Amz-Date", valid_593252
  var valid_593253 = header.getOrDefault("X-Amz-Credential")
  valid_593253 = validateParameter(valid_593253, JString, required = false,
                                 default = nil)
  if valid_593253 != nil:
    section.add "X-Amz-Credential", valid_593253
  var valid_593254 = header.getOrDefault("X-Amz-Security-Token")
  valid_593254 = validateParameter(valid_593254, JString, required = false,
                                 default = nil)
  if valid_593254 != nil:
    section.add "X-Amz-Security-Token", valid_593254
  var valid_593255 = header.getOrDefault("X-Amz-Algorithm")
  valid_593255 = validateParameter(valid_593255, JString, required = false,
                                 default = nil)
  if valid_593255 != nil:
    section.add "X-Amz-Algorithm", valid_593255
  var valid_593256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593256 = validateParameter(valid_593256, JString, required = false,
                                 default = nil)
  if valid_593256 != nil:
    section.add "X-Amz-SignedHeaders", valid_593256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593258: Call_VoteOnProposal_593245; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Casts a vote for a specified <code>ProposalId</code> on behalf of a member. The member to vote as, specified by <code>VoterMemberId</code>, must be in the same AWS account as the principal that calls the action.
  ## 
  let valid = call_593258.validator(path, query, header, formData, body)
  let scheme = call_593258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593258.url(scheme.get, call_593258.host, call_593258.base,
                         call_593258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593258, url, valid)

proc call*(call_593259: Call_VoteOnProposal_593245; proposalId: string;
          networkId: string; body: JsonNode): Recallable =
  ## voteOnProposal
  ## Casts a vote for a specified <code>ProposalId</code> on behalf of a member. The member to vote as, specified by <code>VoterMemberId</code>, must be in the same AWS account as the principal that calls the action.
  ##   proposalId: string (required)
  ##             :  The unique identifier of the proposal. 
  ##   networkId: string (required)
  ##            :  The unique identifier of the network. 
  ##   body: JObject (required)
  var path_593260 = newJObject()
  var body_593261 = newJObject()
  add(path_593260, "proposalId", newJString(proposalId))
  add(path_593260, "networkId", newJString(networkId))
  if body != nil:
    body_593261 = body
  result = call_593259.call(path_593260, nil, nil, nil, body_593261)

var voteOnProposal* = Call_VoteOnProposal_593245(name: "voteOnProposal",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals/{proposalId}/votes",
    validator: validate_VoteOnProposal_593246, base: "/", url: url_VoteOnProposal_593247,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProposalVotes_593225 = ref object of OpenApiRestCall_592364
proc url_ListProposalVotes_593227(protocol: Scheme; host: string; base: string;
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

proc validate_ListProposalVotes_593226(path: JsonNode; query: JsonNode;
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
  var valid_593228 = path.getOrDefault("proposalId")
  valid_593228 = validateParameter(valid_593228, JString, required = true,
                                 default = nil)
  if valid_593228 != nil:
    section.add "proposalId", valid_593228
  var valid_593229 = path.getOrDefault("networkId")
  valid_593229 = validateParameter(valid_593229, JString, required = true,
                                 default = nil)
  if valid_593229 != nil:
    section.add "networkId", valid_593229
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
  var valid_593230 = query.getOrDefault("nextToken")
  valid_593230 = validateParameter(valid_593230, JString, required = false,
                                 default = nil)
  if valid_593230 != nil:
    section.add "nextToken", valid_593230
  var valid_593231 = query.getOrDefault("MaxResults")
  valid_593231 = validateParameter(valid_593231, JString, required = false,
                                 default = nil)
  if valid_593231 != nil:
    section.add "MaxResults", valid_593231
  var valid_593232 = query.getOrDefault("NextToken")
  valid_593232 = validateParameter(valid_593232, JString, required = false,
                                 default = nil)
  if valid_593232 != nil:
    section.add "NextToken", valid_593232
  var valid_593233 = query.getOrDefault("maxResults")
  valid_593233 = validateParameter(valid_593233, JInt, required = false, default = nil)
  if valid_593233 != nil:
    section.add "maxResults", valid_593233
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
  var valid_593234 = header.getOrDefault("X-Amz-Signature")
  valid_593234 = validateParameter(valid_593234, JString, required = false,
                                 default = nil)
  if valid_593234 != nil:
    section.add "X-Amz-Signature", valid_593234
  var valid_593235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593235 = validateParameter(valid_593235, JString, required = false,
                                 default = nil)
  if valid_593235 != nil:
    section.add "X-Amz-Content-Sha256", valid_593235
  var valid_593236 = header.getOrDefault("X-Amz-Date")
  valid_593236 = validateParameter(valid_593236, JString, required = false,
                                 default = nil)
  if valid_593236 != nil:
    section.add "X-Amz-Date", valid_593236
  var valid_593237 = header.getOrDefault("X-Amz-Credential")
  valid_593237 = validateParameter(valid_593237, JString, required = false,
                                 default = nil)
  if valid_593237 != nil:
    section.add "X-Amz-Credential", valid_593237
  var valid_593238 = header.getOrDefault("X-Amz-Security-Token")
  valid_593238 = validateParameter(valid_593238, JString, required = false,
                                 default = nil)
  if valid_593238 != nil:
    section.add "X-Amz-Security-Token", valid_593238
  var valid_593239 = header.getOrDefault("X-Amz-Algorithm")
  valid_593239 = validateParameter(valid_593239, JString, required = false,
                                 default = nil)
  if valid_593239 != nil:
    section.add "X-Amz-Algorithm", valid_593239
  var valid_593240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593240 = validateParameter(valid_593240, JString, required = false,
                                 default = nil)
  if valid_593240 != nil:
    section.add "X-Amz-SignedHeaders", valid_593240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593241: Call_ListProposalVotes_593225; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the listing of votes for a specified proposal, including the value of each vote and the unique identifier of the member that cast the vote.
  ## 
  let valid = call_593241.validator(path, query, header, formData, body)
  let scheme = call_593241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593241.url(scheme.get, call_593241.host, call_593241.base,
                         call_593241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593241, url, valid)

proc call*(call_593242: Call_ListProposalVotes_593225; proposalId: string;
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
  var path_593243 = newJObject()
  var query_593244 = newJObject()
  add(query_593244, "nextToken", newJString(nextToken))
  add(query_593244, "MaxResults", newJString(MaxResults))
  add(path_593243, "proposalId", newJString(proposalId))
  add(query_593244, "NextToken", newJString(NextToken))
  add(path_593243, "networkId", newJString(networkId))
  add(query_593244, "maxResults", newJInt(maxResults))
  result = call_593242.call(path_593243, query_593244, nil, nil, nil)

var listProposalVotes* = Call_ListProposalVotes_593225(name: "listProposalVotes",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals/{proposalId}/votes",
    validator: validate_ListProposalVotes_593226, base: "/",
    url: url_ListProposalVotes_593227, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectInvitation_593262 = ref object of OpenApiRestCall_592364
proc url_RejectInvitation_593264(protocol: Scheme; host: string; base: string;
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

proc validate_RejectInvitation_593263(path: JsonNode; query: JsonNode;
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
  var valid_593265 = path.getOrDefault("invitationId")
  valid_593265 = validateParameter(valid_593265, JString, required = true,
                                 default = nil)
  if valid_593265 != nil:
    section.add "invitationId", valid_593265
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
  var valid_593266 = header.getOrDefault("X-Amz-Signature")
  valid_593266 = validateParameter(valid_593266, JString, required = false,
                                 default = nil)
  if valid_593266 != nil:
    section.add "X-Amz-Signature", valid_593266
  var valid_593267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593267 = validateParameter(valid_593267, JString, required = false,
                                 default = nil)
  if valid_593267 != nil:
    section.add "X-Amz-Content-Sha256", valid_593267
  var valid_593268 = header.getOrDefault("X-Amz-Date")
  valid_593268 = validateParameter(valid_593268, JString, required = false,
                                 default = nil)
  if valid_593268 != nil:
    section.add "X-Amz-Date", valid_593268
  var valid_593269 = header.getOrDefault("X-Amz-Credential")
  valid_593269 = validateParameter(valid_593269, JString, required = false,
                                 default = nil)
  if valid_593269 != nil:
    section.add "X-Amz-Credential", valid_593269
  var valid_593270 = header.getOrDefault("X-Amz-Security-Token")
  valid_593270 = validateParameter(valid_593270, JString, required = false,
                                 default = nil)
  if valid_593270 != nil:
    section.add "X-Amz-Security-Token", valid_593270
  var valid_593271 = header.getOrDefault("X-Amz-Algorithm")
  valid_593271 = validateParameter(valid_593271, JString, required = false,
                                 default = nil)
  if valid_593271 != nil:
    section.add "X-Amz-Algorithm", valid_593271
  var valid_593272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593272 = validateParameter(valid_593272, JString, required = false,
                                 default = nil)
  if valid_593272 != nil:
    section.add "X-Amz-SignedHeaders", valid_593272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593273: Call_RejectInvitation_593262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Rejects an invitation to join a network. This action can be called by a principal in an AWS account that has received an invitation to create a member and join a network.
  ## 
  let valid = call_593273.validator(path, query, header, formData, body)
  let scheme = call_593273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593273.url(scheme.get, call_593273.host, call_593273.base,
                         call_593273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593273, url, valid)

proc call*(call_593274: Call_RejectInvitation_593262; invitationId: string): Recallable =
  ## rejectInvitation
  ## Rejects an invitation to join a network. This action can be called by a principal in an AWS account that has received an invitation to create a member and join a network.
  ##   invitationId: string (required)
  ##               : The unique identifier of the invitation to reject.
  var path_593275 = newJObject()
  add(path_593275, "invitationId", newJString(invitationId))
  result = call_593274.call(path_593275, nil, nil, nil, nil)

var rejectInvitation* = Call_RejectInvitation_593262(name: "rejectInvitation",
    meth: HttpMethod.HttpDelete, host: "managedblockchain.amazonaws.com",
    route: "/invitations/{invitationId}", validator: validate_RejectInvitation_593263,
    base: "/", url: url_RejectInvitation_593264,
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
