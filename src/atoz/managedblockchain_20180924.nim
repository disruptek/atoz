
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateMember_601059 = ref object of OpenApiRestCall_600426
proc url_CreateMember_601061(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "networkId" in path, "`networkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/networks/"),
               (kind: VariableSegment, value: "networkId"),
               (kind: ConstantSegment, value: "/members")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateMember_601060(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601062 = path.getOrDefault("networkId")
  valid_601062 = validateParameter(valid_601062, JString, required = true,
                                 default = nil)
  if valid_601062 != nil:
    section.add "networkId", valid_601062
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
  var valid_601063 = header.getOrDefault("X-Amz-Date")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-Date", valid_601063
  var valid_601064 = header.getOrDefault("X-Amz-Security-Token")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-Security-Token", valid_601064
  var valid_601065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Content-Sha256", valid_601065
  var valid_601066 = header.getOrDefault("X-Amz-Algorithm")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-Algorithm", valid_601066
  var valid_601067 = header.getOrDefault("X-Amz-Signature")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "X-Amz-Signature", valid_601067
  var valid_601068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-SignedHeaders", valid_601068
  var valid_601069 = header.getOrDefault("X-Amz-Credential")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Credential", valid_601069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601071: Call_CreateMember_601059; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a member within a Managed Blockchain network.
  ## 
  let valid = call_601071.validator(path, query, header, formData, body)
  let scheme = call_601071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601071.url(scheme.get, call_601071.host, call_601071.base,
                         call_601071.route, valid.getOrDefault("path"))
  result = hook(call_601071, url, valid)

proc call*(call_601072: Call_CreateMember_601059; networkId: string; body: JsonNode): Recallable =
  ## createMember
  ## Creates a member within a Managed Blockchain network.
  ##   networkId: string (required)
  ##            : The unique identifier of the network in which the member is created.
  ##   body: JObject (required)
  var path_601073 = newJObject()
  var body_601074 = newJObject()
  add(path_601073, "networkId", newJString(networkId))
  if body != nil:
    body_601074 = body
  result = call_601072.call(path_601073, nil, nil, nil, body_601074)

var createMember* = Call_CreateMember_601059(name: "createMember",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/members", validator: validate_CreateMember_601060,
    base: "/", url: url_CreateMember_601061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_600768 = ref object of OpenApiRestCall_600426
proc url_ListMembers_600770(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "networkId" in path, "`networkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/networks/"),
               (kind: VariableSegment, value: "networkId"),
               (kind: ConstantSegment, value: "/members")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListMembers_600769(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600896 = path.getOrDefault("networkId")
  valid_600896 = validateParameter(valid_600896, JString, required = true,
                                 default = nil)
  if valid_600896 != nil:
    section.add "networkId", valid_600896
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
  var valid_600897 = query.getOrDefault("NextToken")
  valid_600897 = validateParameter(valid_600897, JString, required = false,
                                 default = nil)
  if valid_600897 != nil:
    section.add "NextToken", valid_600897
  var valid_600898 = query.getOrDefault("maxResults")
  valid_600898 = validateParameter(valid_600898, JInt, required = false, default = nil)
  if valid_600898 != nil:
    section.add "maxResults", valid_600898
  var valid_600899 = query.getOrDefault("nextToken")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "nextToken", valid_600899
  var valid_600900 = query.getOrDefault("name")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "name", valid_600900
  var valid_600901 = query.getOrDefault("isOwned")
  valid_600901 = validateParameter(valid_600901, JBool, required = false, default = nil)
  if valid_600901 != nil:
    section.add "isOwned", valid_600901
  var valid_600915 = query.getOrDefault("status")
  valid_600915 = validateParameter(valid_600915, JString, required = false,
                                 default = newJString("CREATING"))
  if valid_600915 != nil:
    section.add "status", valid_600915
  var valid_600916 = query.getOrDefault("MaxResults")
  valid_600916 = validateParameter(valid_600916, JString, required = false,
                                 default = nil)
  if valid_600916 != nil:
    section.add "MaxResults", valid_600916
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
  var valid_600917 = header.getOrDefault("X-Amz-Date")
  valid_600917 = validateParameter(valid_600917, JString, required = false,
                                 default = nil)
  if valid_600917 != nil:
    section.add "X-Amz-Date", valid_600917
  var valid_600918 = header.getOrDefault("X-Amz-Security-Token")
  valid_600918 = validateParameter(valid_600918, JString, required = false,
                                 default = nil)
  if valid_600918 != nil:
    section.add "X-Amz-Security-Token", valid_600918
  var valid_600919 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600919 = validateParameter(valid_600919, JString, required = false,
                                 default = nil)
  if valid_600919 != nil:
    section.add "X-Amz-Content-Sha256", valid_600919
  var valid_600920 = header.getOrDefault("X-Amz-Algorithm")
  valid_600920 = validateParameter(valid_600920, JString, required = false,
                                 default = nil)
  if valid_600920 != nil:
    section.add "X-Amz-Algorithm", valid_600920
  var valid_600921 = header.getOrDefault("X-Amz-Signature")
  valid_600921 = validateParameter(valid_600921, JString, required = false,
                                 default = nil)
  if valid_600921 != nil:
    section.add "X-Amz-Signature", valid_600921
  var valid_600922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600922 = validateParameter(valid_600922, JString, required = false,
                                 default = nil)
  if valid_600922 != nil:
    section.add "X-Amz-SignedHeaders", valid_600922
  var valid_600923 = header.getOrDefault("X-Amz-Credential")
  valid_600923 = validateParameter(valid_600923, JString, required = false,
                                 default = nil)
  if valid_600923 != nil:
    section.add "X-Amz-Credential", valid_600923
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600946: Call_ListMembers_600768; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a listing of the members in a network and properties of their configurations.
  ## 
  let valid = call_600946.validator(path, query, header, formData, body)
  let scheme = call_600946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600946.url(scheme.get, call_600946.host, call_600946.base,
                         call_600946.route, valid.getOrDefault("path"))
  result = hook(call_600946, url, valid)

proc call*(call_601017: Call_ListMembers_600768; networkId: string;
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
  var path_601018 = newJObject()
  var query_601020 = newJObject()
  add(path_601018, "networkId", newJString(networkId))
  add(query_601020, "NextToken", newJString(NextToken))
  add(query_601020, "maxResults", newJInt(maxResults))
  add(query_601020, "nextToken", newJString(nextToken))
  add(query_601020, "name", newJString(name))
  add(query_601020, "isOwned", newJBool(isOwned))
  add(query_601020, "status", newJString(status))
  add(query_601020, "MaxResults", newJString(MaxResults))
  result = call_601017.call(path_601018, query_601020, nil, nil, nil)

var listMembers* = Call_ListMembers_600768(name: "listMembers",
                                        meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
                                        route: "/networks/{networkId}/members",
                                        validator: validate_ListMembers_600769,
                                        base: "/", url: url_ListMembers_600770,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNetwork_601095 = ref object of OpenApiRestCall_600426
proc url_CreateNetwork_601097(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateNetwork_601096(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601098 = header.getOrDefault("X-Amz-Date")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "X-Amz-Date", valid_601098
  var valid_601099 = header.getOrDefault("X-Amz-Security-Token")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "X-Amz-Security-Token", valid_601099
  var valid_601100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Content-Sha256", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-Algorithm")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-Algorithm", valid_601101
  var valid_601102 = header.getOrDefault("X-Amz-Signature")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "X-Amz-Signature", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-SignedHeaders", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Credential")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Credential", valid_601104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601106: Call_CreateNetwork_601095; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new blockchain network using Amazon Managed Blockchain.
  ## 
  let valid = call_601106.validator(path, query, header, formData, body)
  let scheme = call_601106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601106.url(scheme.get, call_601106.host, call_601106.base,
                         call_601106.route, valid.getOrDefault("path"))
  result = hook(call_601106, url, valid)

proc call*(call_601107: Call_CreateNetwork_601095; body: JsonNode): Recallable =
  ## createNetwork
  ## Creates a new blockchain network using Amazon Managed Blockchain.
  ##   body: JObject (required)
  var body_601108 = newJObject()
  if body != nil:
    body_601108 = body
  result = call_601107.call(nil, nil, nil, nil, body_601108)

var createNetwork* = Call_CreateNetwork_601095(name: "createNetwork",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks", validator: validate_CreateNetwork_601096, base: "/",
    url: url_CreateNetwork_601097, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNetworks_601075 = ref object of OpenApiRestCall_600426
proc url_ListNetworks_601077(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListNetworks_601076(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601078 = query.getOrDefault("framework")
  valid_601078 = validateParameter(valid_601078, JString, required = false,
                                 default = newJString("HYPERLEDGER_FABRIC"))
  if valid_601078 != nil:
    section.add "framework", valid_601078
  var valid_601079 = query.getOrDefault("NextToken")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "NextToken", valid_601079
  var valid_601080 = query.getOrDefault("maxResults")
  valid_601080 = validateParameter(valid_601080, JInt, required = false, default = nil)
  if valid_601080 != nil:
    section.add "maxResults", valid_601080
  var valid_601081 = query.getOrDefault("nextToken")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "nextToken", valid_601081
  var valid_601082 = query.getOrDefault("name")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "name", valid_601082
  var valid_601083 = query.getOrDefault("status")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = newJString("CREATING"))
  if valid_601083 != nil:
    section.add "status", valid_601083
  var valid_601084 = query.getOrDefault("MaxResults")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "MaxResults", valid_601084
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
  var valid_601085 = header.getOrDefault("X-Amz-Date")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Date", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Security-Token")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Security-Token", valid_601086
  var valid_601087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-Content-Sha256", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Algorithm")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Algorithm", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Signature")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Signature", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-SignedHeaders", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-Credential")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Credential", valid_601091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601092: Call_ListNetworks_601075; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the networks in which the current AWS account has members.
  ## 
  let valid = call_601092.validator(path, query, header, formData, body)
  let scheme = call_601092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601092.url(scheme.get, call_601092.host, call_601092.base,
                         call_601092.route, valid.getOrDefault("path"))
  result = hook(call_601092, url, valid)

proc call*(call_601093: Call_ListNetworks_601075;
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
  var query_601094 = newJObject()
  add(query_601094, "framework", newJString(framework))
  add(query_601094, "NextToken", newJString(NextToken))
  add(query_601094, "maxResults", newJInt(maxResults))
  add(query_601094, "nextToken", newJString(nextToken))
  add(query_601094, "name", newJString(name))
  add(query_601094, "status", newJString(status))
  add(query_601094, "MaxResults", newJString(MaxResults))
  result = call_601093.call(nil, query_601094, nil, nil, nil)

var listNetworks* = Call_ListNetworks_601075(name: "listNetworks",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks", validator: validate_ListNetworks_601076, base: "/",
    url: url_ListNetworks_601077, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNode_601130 = ref object of OpenApiRestCall_600426
proc url_CreateNode_601132(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateNode_601131(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601133 = path.getOrDefault("networkId")
  valid_601133 = validateParameter(valid_601133, JString, required = true,
                                 default = nil)
  if valid_601133 != nil:
    section.add "networkId", valid_601133
  var valid_601134 = path.getOrDefault("memberId")
  valid_601134 = validateParameter(valid_601134, JString, required = true,
                                 default = nil)
  if valid_601134 != nil:
    section.add "memberId", valid_601134
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
  var valid_601135 = header.getOrDefault("X-Amz-Date")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Date", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-Security-Token")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-Security-Token", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Content-Sha256", valid_601137
  var valid_601138 = header.getOrDefault("X-Amz-Algorithm")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "X-Amz-Algorithm", valid_601138
  var valid_601139 = header.getOrDefault("X-Amz-Signature")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Signature", valid_601139
  var valid_601140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-SignedHeaders", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-Credential")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-Credential", valid_601141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601143: Call_CreateNode_601130; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a peer node in a member.
  ## 
  let valid = call_601143.validator(path, query, header, formData, body)
  let scheme = call_601143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601143.url(scheme.get, call_601143.host, call_601143.base,
                         call_601143.route, valid.getOrDefault("path"))
  result = hook(call_601143, url, valid)

proc call*(call_601144: Call_CreateNode_601130; networkId: string; memberId: string;
          body: JsonNode): Recallable =
  ## createNode
  ## Creates a peer node in a member.
  ##   networkId: string (required)
  ##            : The unique identifier of the network in which this node runs.
  ##   memberId: string (required)
  ##           : The unique identifier of the member that owns this node.
  ##   body: JObject (required)
  var path_601145 = newJObject()
  var body_601146 = newJObject()
  add(path_601145, "networkId", newJString(networkId))
  add(path_601145, "memberId", newJString(memberId))
  if body != nil:
    body_601146 = body
  result = call_601144.call(path_601145, nil, nil, nil, body_601146)

var createNode* = Call_CreateNode_601130(name: "createNode",
                                      meth: HttpMethod.HttpPost,
                                      host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes",
                                      validator: validate_CreateNode_601131,
                                      base: "/", url: url_CreateNode_601132,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNodes_601109 = ref object of OpenApiRestCall_600426
proc url_ListNodes_601111(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListNodes_601110(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601112 = path.getOrDefault("networkId")
  valid_601112 = validateParameter(valid_601112, JString, required = true,
                                 default = nil)
  if valid_601112 != nil:
    section.add "networkId", valid_601112
  var valid_601113 = path.getOrDefault("memberId")
  valid_601113 = validateParameter(valid_601113, JString, required = true,
                                 default = nil)
  if valid_601113 != nil:
    section.add "memberId", valid_601113
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
  var valid_601114 = query.getOrDefault("NextToken")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "NextToken", valid_601114
  var valid_601115 = query.getOrDefault("maxResults")
  valid_601115 = validateParameter(valid_601115, JInt, required = false, default = nil)
  if valid_601115 != nil:
    section.add "maxResults", valid_601115
  var valid_601116 = query.getOrDefault("nextToken")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "nextToken", valid_601116
  var valid_601117 = query.getOrDefault("status")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = newJString("CREATING"))
  if valid_601117 != nil:
    section.add "status", valid_601117
  var valid_601118 = query.getOrDefault("MaxResults")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "MaxResults", valid_601118
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
  var valid_601119 = header.getOrDefault("X-Amz-Date")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Date", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Security-Token")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Security-Token", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-Content-Sha256", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Algorithm")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Algorithm", valid_601122
  var valid_601123 = header.getOrDefault("X-Amz-Signature")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = nil)
  if valid_601123 != nil:
    section.add "X-Amz-Signature", valid_601123
  var valid_601124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-SignedHeaders", valid_601124
  var valid_601125 = header.getOrDefault("X-Amz-Credential")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Credential", valid_601125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601126: Call_ListNodes_601109; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the nodes within a network.
  ## 
  let valid = call_601126.validator(path, query, header, formData, body)
  let scheme = call_601126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601126.url(scheme.get, call_601126.host, call_601126.base,
                         call_601126.route, valid.getOrDefault("path"))
  result = hook(call_601126, url, valid)

proc call*(call_601127: Call_ListNodes_601109; networkId: string; memberId: string;
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
  var path_601128 = newJObject()
  var query_601129 = newJObject()
  add(path_601128, "networkId", newJString(networkId))
  add(path_601128, "memberId", newJString(memberId))
  add(query_601129, "NextToken", newJString(NextToken))
  add(query_601129, "maxResults", newJInt(maxResults))
  add(query_601129, "nextToken", newJString(nextToken))
  add(query_601129, "status", newJString(status))
  add(query_601129, "MaxResults", newJString(MaxResults))
  result = call_601127.call(path_601128, query_601129, nil, nil, nil)

var listNodes* = Call_ListNodes_601109(name: "listNodes", meth: HttpMethod.HttpGet,
                                    host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes",
                                    validator: validate_ListNodes_601110,
                                    base: "/", url: url_ListNodes_601111,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProposal_601166 = ref object of OpenApiRestCall_600426
proc url_CreateProposal_601168(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "networkId" in path, "`networkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/networks/"),
               (kind: VariableSegment, value: "networkId"),
               (kind: ConstantSegment, value: "/proposals")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateProposal_601167(path: JsonNode; query: JsonNode;
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
  var valid_601169 = path.getOrDefault("networkId")
  valid_601169 = validateParameter(valid_601169, JString, required = true,
                                 default = nil)
  if valid_601169 != nil:
    section.add "networkId", valid_601169
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
  var valid_601170 = header.getOrDefault("X-Amz-Date")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Date", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-Security-Token")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-Security-Token", valid_601171
  var valid_601172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-Content-Sha256", valid_601172
  var valid_601173 = header.getOrDefault("X-Amz-Algorithm")
  valid_601173 = validateParameter(valid_601173, JString, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "X-Amz-Algorithm", valid_601173
  var valid_601174 = header.getOrDefault("X-Amz-Signature")
  valid_601174 = validateParameter(valid_601174, JString, required = false,
                                 default = nil)
  if valid_601174 != nil:
    section.add "X-Amz-Signature", valid_601174
  var valid_601175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601175 = validateParameter(valid_601175, JString, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "X-Amz-SignedHeaders", valid_601175
  var valid_601176 = header.getOrDefault("X-Amz-Credential")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "X-Amz-Credential", valid_601176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601178: Call_CreateProposal_601166; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a proposal for a change to the network that other members of the network can vote on, for example, a proposal to add a new member to the network. Any member can create a proposal.
  ## 
  let valid = call_601178.validator(path, query, header, formData, body)
  let scheme = call_601178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601178.url(scheme.get, call_601178.host, call_601178.base,
                         call_601178.route, valid.getOrDefault("path"))
  result = hook(call_601178, url, valid)

proc call*(call_601179: Call_CreateProposal_601166; networkId: string; body: JsonNode): Recallable =
  ## createProposal
  ## Creates a proposal for a change to the network that other members of the network can vote on, for example, a proposal to add a new member to the network. Any member can create a proposal.
  ##   networkId: string (required)
  ##            :  The unique identifier of the network for which the proposal is made.
  ##   body: JObject (required)
  var path_601180 = newJObject()
  var body_601181 = newJObject()
  add(path_601180, "networkId", newJString(networkId))
  if body != nil:
    body_601181 = body
  result = call_601179.call(path_601180, nil, nil, nil, body_601181)

var createProposal* = Call_CreateProposal_601166(name: "createProposal",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals", validator: validate_CreateProposal_601167,
    base: "/", url: url_CreateProposal_601168, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProposals_601147 = ref object of OpenApiRestCall_600426
proc url_ListProposals_601149(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "networkId" in path, "`networkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/networks/"),
               (kind: VariableSegment, value: "networkId"),
               (kind: ConstantSegment, value: "/proposals")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListProposals_601148(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601150 = path.getOrDefault("networkId")
  valid_601150 = validateParameter(valid_601150, JString, required = true,
                                 default = nil)
  if valid_601150 != nil:
    section.add "networkId", valid_601150
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
  var valid_601151 = query.getOrDefault("NextToken")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "NextToken", valid_601151
  var valid_601152 = query.getOrDefault("maxResults")
  valid_601152 = validateParameter(valid_601152, JInt, required = false, default = nil)
  if valid_601152 != nil:
    section.add "maxResults", valid_601152
  var valid_601153 = query.getOrDefault("nextToken")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "nextToken", valid_601153
  var valid_601154 = query.getOrDefault("MaxResults")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "MaxResults", valid_601154
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
  var valid_601155 = header.getOrDefault("X-Amz-Date")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "X-Amz-Date", valid_601155
  var valid_601156 = header.getOrDefault("X-Amz-Security-Token")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "X-Amz-Security-Token", valid_601156
  var valid_601157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "X-Amz-Content-Sha256", valid_601157
  var valid_601158 = header.getOrDefault("X-Amz-Algorithm")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "X-Amz-Algorithm", valid_601158
  var valid_601159 = header.getOrDefault("X-Amz-Signature")
  valid_601159 = validateParameter(valid_601159, JString, required = false,
                                 default = nil)
  if valid_601159 != nil:
    section.add "X-Amz-Signature", valid_601159
  var valid_601160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "X-Amz-SignedHeaders", valid_601160
  var valid_601161 = header.getOrDefault("X-Amz-Credential")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "X-Amz-Credential", valid_601161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601162: Call_ListProposals_601147; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a listing of proposals for the network.
  ## 
  let valid = call_601162.validator(path, query, header, formData, body)
  let scheme = call_601162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601162.url(scheme.get, call_601162.host, call_601162.base,
                         call_601162.route, valid.getOrDefault("path"))
  result = hook(call_601162, url, valid)

proc call*(call_601163: Call_ListProposals_601147; networkId: string;
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
  var path_601164 = newJObject()
  var query_601165 = newJObject()
  add(path_601164, "networkId", newJString(networkId))
  add(query_601165, "NextToken", newJString(NextToken))
  add(query_601165, "maxResults", newJInt(maxResults))
  add(query_601165, "nextToken", newJString(nextToken))
  add(query_601165, "MaxResults", newJString(MaxResults))
  result = call_601163.call(path_601164, query_601165, nil, nil, nil)

var listProposals* = Call_ListProposals_601147(name: "listProposals",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals", validator: validate_ListProposals_601148,
    base: "/", url: url_ListProposals_601149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMember_601182 = ref object of OpenApiRestCall_600426
proc url_GetMember_601184(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetMember_601183(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601185 = path.getOrDefault("networkId")
  valid_601185 = validateParameter(valid_601185, JString, required = true,
                                 default = nil)
  if valid_601185 != nil:
    section.add "networkId", valid_601185
  var valid_601186 = path.getOrDefault("memberId")
  valid_601186 = validateParameter(valid_601186, JString, required = true,
                                 default = nil)
  if valid_601186 != nil:
    section.add "memberId", valid_601186
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
  var valid_601187 = header.getOrDefault("X-Amz-Date")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-Date", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-Security-Token")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-Security-Token", valid_601188
  var valid_601189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601189 = validateParameter(valid_601189, JString, required = false,
                                 default = nil)
  if valid_601189 != nil:
    section.add "X-Amz-Content-Sha256", valid_601189
  var valid_601190 = header.getOrDefault("X-Amz-Algorithm")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = nil)
  if valid_601190 != nil:
    section.add "X-Amz-Algorithm", valid_601190
  var valid_601191 = header.getOrDefault("X-Amz-Signature")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "X-Amz-Signature", valid_601191
  var valid_601192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601192 = validateParameter(valid_601192, JString, required = false,
                                 default = nil)
  if valid_601192 != nil:
    section.add "X-Amz-SignedHeaders", valid_601192
  var valid_601193 = header.getOrDefault("X-Amz-Credential")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-Credential", valid_601193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601194: Call_GetMember_601182; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a member.
  ## 
  let valid = call_601194.validator(path, query, header, formData, body)
  let scheme = call_601194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601194.url(scheme.get, call_601194.host, call_601194.base,
                         call_601194.route, valid.getOrDefault("path"))
  result = hook(call_601194, url, valid)

proc call*(call_601195: Call_GetMember_601182; networkId: string; memberId: string): Recallable =
  ## getMember
  ## Returns detailed information about a member.
  ##   networkId: string (required)
  ##            : The unique identifier of the network to which the member belongs.
  ##   memberId: string (required)
  ##           : The unique identifier of the member.
  var path_601196 = newJObject()
  add(path_601196, "networkId", newJString(networkId))
  add(path_601196, "memberId", newJString(memberId))
  result = call_601195.call(path_601196, nil, nil, nil, nil)

var getMember* = Call_GetMember_601182(name: "getMember", meth: HttpMethod.HttpGet,
                                    host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}",
                                    validator: validate_GetMember_601183,
                                    base: "/", url: url_GetMember_601184,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMember_601197 = ref object of OpenApiRestCall_600426
proc url_DeleteMember_601199(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteMember_601198(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601200 = path.getOrDefault("networkId")
  valid_601200 = validateParameter(valid_601200, JString, required = true,
                                 default = nil)
  if valid_601200 != nil:
    section.add "networkId", valid_601200
  var valid_601201 = path.getOrDefault("memberId")
  valid_601201 = validateParameter(valid_601201, JString, required = true,
                                 default = nil)
  if valid_601201 != nil:
    section.add "memberId", valid_601201
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
  var valid_601202 = header.getOrDefault("X-Amz-Date")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-Date", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-Security-Token")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Security-Token", valid_601203
  var valid_601204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601204 = validateParameter(valid_601204, JString, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "X-Amz-Content-Sha256", valid_601204
  var valid_601205 = header.getOrDefault("X-Amz-Algorithm")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "X-Amz-Algorithm", valid_601205
  var valid_601206 = header.getOrDefault("X-Amz-Signature")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Signature", valid_601206
  var valid_601207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601207 = validateParameter(valid_601207, JString, required = false,
                                 default = nil)
  if valid_601207 != nil:
    section.add "X-Amz-SignedHeaders", valid_601207
  var valid_601208 = header.getOrDefault("X-Amz-Credential")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-Credential", valid_601208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601209: Call_DeleteMember_601197; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a member. Deleting a member removes the member and all associated resources from the network. <code>DeleteMember</code> can only be called for a specified <code>MemberId</code> if the principal performing the action is associated with the AWS account that owns the member. In all other cases, the <code>DeleteMember</code> action is carried out as the result of an approved proposal to remove a member. If <code>MemberId</code> is the last member in a network specified by the last AWS account, the network is deleted also.
  ## 
  let valid = call_601209.validator(path, query, header, formData, body)
  let scheme = call_601209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601209.url(scheme.get, call_601209.host, call_601209.base,
                         call_601209.route, valid.getOrDefault("path"))
  result = hook(call_601209, url, valid)

proc call*(call_601210: Call_DeleteMember_601197; networkId: string; memberId: string): Recallable =
  ## deleteMember
  ## Deletes a member. Deleting a member removes the member and all associated resources from the network. <code>DeleteMember</code> can only be called for a specified <code>MemberId</code> if the principal performing the action is associated with the AWS account that owns the member. In all other cases, the <code>DeleteMember</code> action is carried out as the result of an approved proposal to remove a member. If <code>MemberId</code> is the last member in a network specified by the last AWS account, the network is deleted also.
  ##   networkId: string (required)
  ##            : The unique identifier of the network from which the member is removed.
  ##   memberId: string (required)
  ##           : The unique identifier of the member to remove.
  var path_601211 = newJObject()
  add(path_601211, "networkId", newJString(networkId))
  add(path_601211, "memberId", newJString(memberId))
  result = call_601210.call(path_601211, nil, nil, nil, nil)

var deleteMember* = Call_DeleteMember_601197(name: "deleteMember",
    meth: HttpMethod.HttpDelete, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/members/{memberId}",
    validator: validate_DeleteMember_601198, base: "/", url: url_DeleteMember_601199,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNode_601212 = ref object of OpenApiRestCall_600426
proc url_GetNode_601214(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetNode_601213(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601215 = path.getOrDefault("networkId")
  valid_601215 = validateParameter(valid_601215, JString, required = true,
                                 default = nil)
  if valid_601215 != nil:
    section.add "networkId", valid_601215
  var valid_601216 = path.getOrDefault("memberId")
  valid_601216 = validateParameter(valid_601216, JString, required = true,
                                 default = nil)
  if valid_601216 != nil:
    section.add "memberId", valid_601216
  var valid_601217 = path.getOrDefault("nodeId")
  valid_601217 = validateParameter(valid_601217, JString, required = true,
                                 default = nil)
  if valid_601217 != nil:
    section.add "nodeId", valid_601217
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
  var valid_601218 = header.getOrDefault("X-Amz-Date")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-Date", valid_601218
  var valid_601219 = header.getOrDefault("X-Amz-Security-Token")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "X-Amz-Security-Token", valid_601219
  var valid_601220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-Content-Sha256", valid_601220
  var valid_601221 = header.getOrDefault("X-Amz-Algorithm")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-Algorithm", valid_601221
  var valid_601222 = header.getOrDefault("X-Amz-Signature")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "X-Amz-Signature", valid_601222
  var valid_601223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "X-Amz-SignedHeaders", valid_601223
  var valid_601224 = header.getOrDefault("X-Amz-Credential")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "X-Amz-Credential", valid_601224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601225: Call_GetNode_601212; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a peer node.
  ## 
  let valid = call_601225.validator(path, query, header, formData, body)
  let scheme = call_601225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601225.url(scheme.get, call_601225.host, call_601225.base,
                         call_601225.route, valid.getOrDefault("path"))
  result = hook(call_601225, url, valid)

proc call*(call_601226: Call_GetNode_601212; networkId: string; memberId: string;
          nodeId: string): Recallable =
  ## getNode
  ## Returns detailed information about a peer node.
  ##   networkId: string (required)
  ##            : The unique identifier of the network to which the node belongs.
  ##   memberId: string (required)
  ##           : The unique identifier of the member that owns the node.
  ##   nodeId: string (required)
  ##         : The unique identifier of the node.
  var path_601227 = newJObject()
  add(path_601227, "networkId", newJString(networkId))
  add(path_601227, "memberId", newJString(memberId))
  add(path_601227, "nodeId", newJString(nodeId))
  result = call_601226.call(path_601227, nil, nil, nil, nil)

var getNode* = Call_GetNode_601212(name: "getNode", meth: HttpMethod.HttpGet,
                                host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes/{nodeId}",
                                validator: validate_GetNode_601213, base: "/",
                                url: url_GetNode_601214,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNode_601228 = ref object of OpenApiRestCall_600426
proc url_DeleteNode_601230(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteNode_601229(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601231 = path.getOrDefault("networkId")
  valid_601231 = validateParameter(valid_601231, JString, required = true,
                                 default = nil)
  if valid_601231 != nil:
    section.add "networkId", valid_601231
  var valid_601232 = path.getOrDefault("memberId")
  valid_601232 = validateParameter(valid_601232, JString, required = true,
                                 default = nil)
  if valid_601232 != nil:
    section.add "memberId", valid_601232
  var valid_601233 = path.getOrDefault("nodeId")
  valid_601233 = validateParameter(valid_601233, JString, required = true,
                                 default = nil)
  if valid_601233 != nil:
    section.add "nodeId", valid_601233
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
  var valid_601234 = header.getOrDefault("X-Amz-Date")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "X-Amz-Date", valid_601234
  var valid_601235 = header.getOrDefault("X-Amz-Security-Token")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "X-Amz-Security-Token", valid_601235
  var valid_601236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "X-Amz-Content-Sha256", valid_601236
  var valid_601237 = header.getOrDefault("X-Amz-Algorithm")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = nil)
  if valid_601237 != nil:
    section.add "X-Amz-Algorithm", valid_601237
  var valid_601238 = header.getOrDefault("X-Amz-Signature")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "X-Amz-Signature", valid_601238
  var valid_601239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "X-Amz-SignedHeaders", valid_601239
  var valid_601240 = header.getOrDefault("X-Amz-Credential")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "X-Amz-Credential", valid_601240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601241: Call_DeleteNode_601228; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a peer node from a member that your AWS account owns. All data on the node is lost and cannot be recovered.
  ## 
  let valid = call_601241.validator(path, query, header, formData, body)
  let scheme = call_601241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601241.url(scheme.get, call_601241.host, call_601241.base,
                         call_601241.route, valid.getOrDefault("path"))
  result = hook(call_601241, url, valid)

proc call*(call_601242: Call_DeleteNode_601228; networkId: string; memberId: string;
          nodeId: string): Recallable =
  ## deleteNode
  ## Deletes a peer node from a member that your AWS account owns. All data on the node is lost and cannot be recovered.
  ##   networkId: string (required)
  ##            : The unique identifier of the network that the node belongs to.
  ##   memberId: string (required)
  ##           : The unique identifier of the member that owns this node.
  ##   nodeId: string (required)
  ##         : The unique identifier of the node.
  var path_601243 = newJObject()
  add(path_601243, "networkId", newJString(networkId))
  add(path_601243, "memberId", newJString(memberId))
  add(path_601243, "nodeId", newJString(nodeId))
  result = call_601242.call(path_601243, nil, nil, nil, nil)

var deleteNode* = Call_DeleteNode_601228(name: "deleteNode",
                                      meth: HttpMethod.HttpDelete,
                                      host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes/{nodeId}",
                                      validator: validate_DeleteNode_601229,
                                      base: "/", url: url_DeleteNode_601230,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNetwork_601244 = ref object of OpenApiRestCall_600426
proc url_GetNetwork_601246(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "networkId" in path, "`networkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/networks/"),
               (kind: VariableSegment, value: "networkId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetNetwork_601245(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601247 = path.getOrDefault("networkId")
  valid_601247 = validateParameter(valid_601247, JString, required = true,
                                 default = nil)
  if valid_601247 != nil:
    section.add "networkId", valid_601247
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
  var valid_601248 = header.getOrDefault("X-Amz-Date")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-Date", valid_601248
  var valid_601249 = header.getOrDefault("X-Amz-Security-Token")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "X-Amz-Security-Token", valid_601249
  var valid_601250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "X-Amz-Content-Sha256", valid_601250
  var valid_601251 = header.getOrDefault("X-Amz-Algorithm")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "X-Amz-Algorithm", valid_601251
  var valid_601252 = header.getOrDefault("X-Amz-Signature")
  valid_601252 = validateParameter(valid_601252, JString, required = false,
                                 default = nil)
  if valid_601252 != nil:
    section.add "X-Amz-Signature", valid_601252
  var valid_601253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-SignedHeaders", valid_601253
  var valid_601254 = header.getOrDefault("X-Amz-Credential")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-Credential", valid_601254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601255: Call_GetNetwork_601244; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a network.
  ## 
  let valid = call_601255.validator(path, query, header, formData, body)
  let scheme = call_601255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601255.url(scheme.get, call_601255.host, call_601255.base,
                         call_601255.route, valid.getOrDefault("path"))
  result = hook(call_601255, url, valid)

proc call*(call_601256: Call_GetNetwork_601244; networkId: string): Recallable =
  ## getNetwork
  ## Returns detailed information about a network.
  ##   networkId: string (required)
  ##            : The unique identifier of the network to get information about.
  var path_601257 = newJObject()
  add(path_601257, "networkId", newJString(networkId))
  result = call_601256.call(path_601257, nil, nil, nil, nil)

var getNetwork* = Call_GetNetwork_601244(name: "getNetwork",
                                      meth: HttpMethod.HttpGet,
                                      host: "managedblockchain.amazonaws.com",
                                      route: "/networks/{networkId}",
                                      validator: validate_GetNetwork_601245,
                                      base: "/", url: url_GetNetwork_601246,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProposal_601258 = ref object of OpenApiRestCall_600426
proc url_GetProposal_601260(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetProposal_601259(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601261 = path.getOrDefault("networkId")
  valid_601261 = validateParameter(valid_601261, JString, required = true,
                                 default = nil)
  if valid_601261 != nil:
    section.add "networkId", valid_601261
  var valid_601262 = path.getOrDefault("proposalId")
  valid_601262 = validateParameter(valid_601262, JString, required = true,
                                 default = nil)
  if valid_601262 != nil:
    section.add "proposalId", valid_601262
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
  var valid_601263 = header.getOrDefault("X-Amz-Date")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-Date", valid_601263
  var valid_601264 = header.getOrDefault("X-Amz-Security-Token")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "X-Amz-Security-Token", valid_601264
  var valid_601265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-Content-Sha256", valid_601265
  var valid_601266 = header.getOrDefault("X-Amz-Algorithm")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-Algorithm", valid_601266
  var valid_601267 = header.getOrDefault("X-Amz-Signature")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "X-Amz-Signature", valid_601267
  var valid_601268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-SignedHeaders", valid_601268
  var valid_601269 = header.getOrDefault("X-Amz-Credential")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "X-Amz-Credential", valid_601269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601270: Call_GetProposal_601258; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a proposal.
  ## 
  let valid = call_601270.validator(path, query, header, formData, body)
  let scheme = call_601270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601270.url(scheme.get, call_601270.host, call_601270.base,
                         call_601270.route, valid.getOrDefault("path"))
  result = hook(call_601270, url, valid)

proc call*(call_601271: Call_GetProposal_601258; networkId: string;
          proposalId: string): Recallable =
  ## getProposal
  ## Returns detailed information about a proposal.
  ##   networkId: string (required)
  ##            : The unique identifier of the network for which the proposal is made.
  ##   proposalId: string (required)
  ##             : The unique identifier of the proposal.
  var path_601272 = newJObject()
  add(path_601272, "networkId", newJString(networkId))
  add(path_601272, "proposalId", newJString(proposalId))
  result = call_601271.call(path_601272, nil, nil, nil, nil)

var getProposal* = Call_GetProposal_601258(name: "getProposal",
                                        meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/proposals/{proposalId}",
                                        validator: validate_GetProposal_601259,
                                        base: "/", url: url_GetProposal_601260,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_601273 = ref object of OpenApiRestCall_600426
proc url_ListInvitations_601275(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListInvitations_601274(path: JsonNode; query: JsonNode;
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
  var valid_601276 = query.getOrDefault("NextToken")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "NextToken", valid_601276
  var valid_601277 = query.getOrDefault("maxResults")
  valid_601277 = validateParameter(valid_601277, JInt, required = false, default = nil)
  if valid_601277 != nil:
    section.add "maxResults", valid_601277
  var valid_601278 = query.getOrDefault("nextToken")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "nextToken", valid_601278
  var valid_601279 = query.getOrDefault("MaxResults")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "MaxResults", valid_601279
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
  var valid_601280 = header.getOrDefault("X-Amz-Date")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "X-Amz-Date", valid_601280
  var valid_601281 = header.getOrDefault("X-Amz-Security-Token")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-Security-Token", valid_601281
  var valid_601282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601282 = validateParameter(valid_601282, JString, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "X-Amz-Content-Sha256", valid_601282
  var valid_601283 = header.getOrDefault("X-Amz-Algorithm")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "X-Amz-Algorithm", valid_601283
  var valid_601284 = header.getOrDefault("X-Amz-Signature")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "X-Amz-Signature", valid_601284
  var valid_601285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "X-Amz-SignedHeaders", valid_601285
  var valid_601286 = header.getOrDefault("X-Amz-Credential")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "X-Amz-Credential", valid_601286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601287: Call_ListInvitations_601273; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a listing of all invitations made on the specified network.
  ## 
  let valid = call_601287.validator(path, query, header, formData, body)
  let scheme = call_601287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601287.url(scheme.get, call_601287.host, call_601287.base,
                         call_601287.route, valid.getOrDefault("path"))
  result = hook(call_601287, url, valid)

proc call*(call_601288: Call_ListInvitations_601273; NextToken: string = "";
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
  var query_601289 = newJObject()
  add(query_601289, "NextToken", newJString(NextToken))
  add(query_601289, "maxResults", newJInt(maxResults))
  add(query_601289, "nextToken", newJString(nextToken))
  add(query_601289, "MaxResults", newJString(MaxResults))
  result = call_601288.call(nil, query_601289, nil, nil, nil)

var listInvitations* = Call_ListInvitations_601273(name: "listInvitations",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/invitations", validator: validate_ListInvitations_601274, base: "/",
    url: url_ListInvitations_601275, schemes: {Scheme.Https, Scheme.Http})
type
  Call_VoteOnProposal_601310 = ref object of OpenApiRestCall_600426
proc url_VoteOnProposal_601312(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_VoteOnProposal_601311(path: JsonNode; query: JsonNode;
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
  var valid_601313 = path.getOrDefault("networkId")
  valid_601313 = validateParameter(valid_601313, JString, required = true,
                                 default = nil)
  if valid_601313 != nil:
    section.add "networkId", valid_601313
  var valid_601314 = path.getOrDefault("proposalId")
  valid_601314 = validateParameter(valid_601314, JString, required = true,
                                 default = nil)
  if valid_601314 != nil:
    section.add "proposalId", valid_601314
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
  var valid_601315 = header.getOrDefault("X-Amz-Date")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "X-Amz-Date", valid_601315
  var valid_601316 = header.getOrDefault("X-Amz-Security-Token")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "X-Amz-Security-Token", valid_601316
  var valid_601317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "X-Amz-Content-Sha256", valid_601317
  var valid_601318 = header.getOrDefault("X-Amz-Algorithm")
  valid_601318 = validateParameter(valid_601318, JString, required = false,
                                 default = nil)
  if valid_601318 != nil:
    section.add "X-Amz-Algorithm", valid_601318
  var valid_601319 = header.getOrDefault("X-Amz-Signature")
  valid_601319 = validateParameter(valid_601319, JString, required = false,
                                 default = nil)
  if valid_601319 != nil:
    section.add "X-Amz-Signature", valid_601319
  var valid_601320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601320 = validateParameter(valid_601320, JString, required = false,
                                 default = nil)
  if valid_601320 != nil:
    section.add "X-Amz-SignedHeaders", valid_601320
  var valid_601321 = header.getOrDefault("X-Amz-Credential")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "X-Amz-Credential", valid_601321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601323: Call_VoteOnProposal_601310; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Casts a vote for a specified <code>ProposalId</code> on behalf of a member. The member to vote as, specified by <code>VoterMemberId</code>, must be in the same AWS account as the principal that calls the action.
  ## 
  let valid = call_601323.validator(path, query, header, formData, body)
  let scheme = call_601323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601323.url(scheme.get, call_601323.host, call_601323.base,
                         call_601323.route, valid.getOrDefault("path"))
  result = hook(call_601323, url, valid)

proc call*(call_601324: Call_VoteOnProposal_601310; networkId: string;
          proposalId: string; body: JsonNode): Recallable =
  ## voteOnProposal
  ## Casts a vote for a specified <code>ProposalId</code> on behalf of a member. The member to vote as, specified by <code>VoterMemberId</code>, must be in the same AWS account as the principal that calls the action.
  ##   networkId: string (required)
  ##            :  The unique identifier of the network. 
  ##   proposalId: string (required)
  ##             :  The unique identifier of the proposal. 
  ##   body: JObject (required)
  var path_601325 = newJObject()
  var body_601326 = newJObject()
  add(path_601325, "networkId", newJString(networkId))
  add(path_601325, "proposalId", newJString(proposalId))
  if body != nil:
    body_601326 = body
  result = call_601324.call(path_601325, nil, nil, nil, body_601326)

var voteOnProposal* = Call_VoteOnProposal_601310(name: "voteOnProposal",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals/{proposalId}/votes",
    validator: validate_VoteOnProposal_601311, base: "/", url: url_VoteOnProposal_601312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProposalVotes_601290 = ref object of OpenApiRestCall_600426
proc url_ListProposalVotes_601292(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListProposalVotes_601291(path: JsonNode; query: JsonNode;
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
  var valid_601293 = path.getOrDefault("networkId")
  valid_601293 = validateParameter(valid_601293, JString, required = true,
                                 default = nil)
  if valid_601293 != nil:
    section.add "networkId", valid_601293
  var valid_601294 = path.getOrDefault("proposalId")
  valid_601294 = validateParameter(valid_601294, JString, required = true,
                                 default = nil)
  if valid_601294 != nil:
    section.add "proposalId", valid_601294
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
  var valid_601295 = query.getOrDefault("NextToken")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "NextToken", valid_601295
  var valid_601296 = query.getOrDefault("maxResults")
  valid_601296 = validateParameter(valid_601296, JInt, required = false, default = nil)
  if valid_601296 != nil:
    section.add "maxResults", valid_601296
  var valid_601297 = query.getOrDefault("nextToken")
  valid_601297 = validateParameter(valid_601297, JString, required = false,
                                 default = nil)
  if valid_601297 != nil:
    section.add "nextToken", valid_601297
  var valid_601298 = query.getOrDefault("MaxResults")
  valid_601298 = validateParameter(valid_601298, JString, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "MaxResults", valid_601298
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
  var valid_601299 = header.getOrDefault("X-Amz-Date")
  valid_601299 = validateParameter(valid_601299, JString, required = false,
                                 default = nil)
  if valid_601299 != nil:
    section.add "X-Amz-Date", valid_601299
  var valid_601300 = header.getOrDefault("X-Amz-Security-Token")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "X-Amz-Security-Token", valid_601300
  var valid_601301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "X-Amz-Content-Sha256", valid_601301
  var valid_601302 = header.getOrDefault("X-Amz-Algorithm")
  valid_601302 = validateParameter(valid_601302, JString, required = false,
                                 default = nil)
  if valid_601302 != nil:
    section.add "X-Amz-Algorithm", valid_601302
  var valid_601303 = header.getOrDefault("X-Amz-Signature")
  valid_601303 = validateParameter(valid_601303, JString, required = false,
                                 default = nil)
  if valid_601303 != nil:
    section.add "X-Amz-Signature", valid_601303
  var valid_601304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601304 = validateParameter(valid_601304, JString, required = false,
                                 default = nil)
  if valid_601304 != nil:
    section.add "X-Amz-SignedHeaders", valid_601304
  var valid_601305 = header.getOrDefault("X-Amz-Credential")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "X-Amz-Credential", valid_601305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601306: Call_ListProposalVotes_601290; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the listing of votes for a specified proposal, including the value of each vote and the unique identifier of the member that cast the vote.
  ## 
  let valid = call_601306.validator(path, query, header, formData, body)
  let scheme = call_601306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601306.url(scheme.get, call_601306.host, call_601306.base,
                         call_601306.route, valid.getOrDefault("path"))
  result = hook(call_601306, url, valid)

proc call*(call_601307: Call_ListProposalVotes_601290; networkId: string;
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
  var path_601308 = newJObject()
  var query_601309 = newJObject()
  add(path_601308, "networkId", newJString(networkId))
  add(path_601308, "proposalId", newJString(proposalId))
  add(query_601309, "NextToken", newJString(NextToken))
  add(query_601309, "maxResults", newJInt(maxResults))
  add(query_601309, "nextToken", newJString(nextToken))
  add(query_601309, "MaxResults", newJString(MaxResults))
  result = call_601307.call(path_601308, query_601309, nil, nil, nil)

var listProposalVotes* = Call_ListProposalVotes_601290(name: "listProposalVotes",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals/{proposalId}/votes",
    validator: validate_ListProposalVotes_601291, base: "/",
    url: url_ListProposalVotes_601292, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectInvitation_601327 = ref object of OpenApiRestCall_600426
proc url_RejectInvitation_601329(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "invitationId" in path, "`invitationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/invitations/"),
               (kind: VariableSegment, value: "invitationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_RejectInvitation_601328(path: JsonNode; query: JsonNode;
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
  var valid_601330 = path.getOrDefault("invitationId")
  valid_601330 = validateParameter(valid_601330, JString, required = true,
                                 default = nil)
  if valid_601330 != nil:
    section.add "invitationId", valid_601330
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
  var valid_601331 = header.getOrDefault("X-Amz-Date")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "X-Amz-Date", valid_601331
  var valid_601332 = header.getOrDefault("X-Amz-Security-Token")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "X-Amz-Security-Token", valid_601332
  var valid_601333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601333 = validateParameter(valid_601333, JString, required = false,
                                 default = nil)
  if valid_601333 != nil:
    section.add "X-Amz-Content-Sha256", valid_601333
  var valid_601334 = header.getOrDefault("X-Amz-Algorithm")
  valid_601334 = validateParameter(valid_601334, JString, required = false,
                                 default = nil)
  if valid_601334 != nil:
    section.add "X-Amz-Algorithm", valid_601334
  var valid_601335 = header.getOrDefault("X-Amz-Signature")
  valid_601335 = validateParameter(valid_601335, JString, required = false,
                                 default = nil)
  if valid_601335 != nil:
    section.add "X-Amz-Signature", valid_601335
  var valid_601336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601336 = validateParameter(valid_601336, JString, required = false,
                                 default = nil)
  if valid_601336 != nil:
    section.add "X-Amz-SignedHeaders", valid_601336
  var valid_601337 = header.getOrDefault("X-Amz-Credential")
  valid_601337 = validateParameter(valid_601337, JString, required = false,
                                 default = nil)
  if valid_601337 != nil:
    section.add "X-Amz-Credential", valid_601337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601338: Call_RejectInvitation_601327; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Rejects an invitation to join a network. This action can be called by a principal in an AWS account that has received an invitation to create a member and join a network.
  ## 
  let valid = call_601338.validator(path, query, header, formData, body)
  let scheme = call_601338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601338.url(scheme.get, call_601338.host, call_601338.base,
                         call_601338.route, valid.getOrDefault("path"))
  result = hook(call_601338, url, valid)

proc call*(call_601339: Call_RejectInvitation_601327; invitationId: string): Recallable =
  ## rejectInvitation
  ## Rejects an invitation to join a network. This action can be called by a principal in an AWS account that has received an invitation to create a member and join a network.
  ##   invitationId: string (required)
  ##               : The unique identifier of the invitation to reject.
  var path_601340 = newJObject()
  add(path_601340, "invitationId", newJString(invitationId))
  result = call_601339.call(path_601340, nil, nil, nil, nil)

var rejectInvitation* = Call_RejectInvitation_601327(name: "rejectInvitation",
    meth: HttpMethod.HttpDelete, host: "managedblockchain.amazonaws.com",
    route: "/invitations/{invitationId}", validator: validate_RejectInvitation_601328,
    base: "/", url: url_RejectInvitation_601329,
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
