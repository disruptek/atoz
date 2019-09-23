
import
  json, options, hashes, uri, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_600437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600437): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

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
  Call_CreateMember_601065 = ref object of OpenApiRestCall_600437
proc url_CreateMember_601067(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMember_601066(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601068 = path.getOrDefault("networkId")
  valid_601068 = validateParameter(valid_601068, JString, required = true,
                                 default = nil)
  if valid_601068 != nil:
    section.add "networkId", valid_601068
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
  var valid_601069 = header.getOrDefault("X-Amz-Date")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Date", valid_601069
  var valid_601070 = header.getOrDefault("X-Amz-Security-Token")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Security-Token", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Content-Sha256", valid_601071
  var valid_601072 = header.getOrDefault("X-Amz-Algorithm")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-Algorithm", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Signature")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Signature", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-SignedHeaders", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Credential")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Credential", valid_601075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601077: Call_CreateMember_601065; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a member within a Managed Blockchain network.
  ## 
  let valid = call_601077.validator(path, query, header, formData, body)
  let scheme = call_601077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601077.url(scheme.get, call_601077.host, call_601077.base,
                         call_601077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601077, url, valid)

proc call*(call_601078: Call_CreateMember_601065; networkId: string; body: JsonNode): Recallable =
  ## createMember
  ## Creates a member within a Managed Blockchain network.
  ##   networkId: string (required)
  ##            : The unique identifier of the network in which the member is created.
  ##   body: JObject (required)
  var path_601079 = newJObject()
  var body_601080 = newJObject()
  add(path_601079, "networkId", newJString(networkId))
  if body != nil:
    body_601080 = body
  result = call_601078.call(path_601079, nil, nil, nil, body_601080)

var createMember* = Call_CreateMember_601065(name: "createMember",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/members", validator: validate_CreateMember_601066,
    base: "/", url: url_CreateMember_601067, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_600774 = ref object of OpenApiRestCall_600437
proc url_ListMembers_600776(protocol: Scheme; host: string; base: string;
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

proc validate_ListMembers_600775(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600902 = path.getOrDefault("networkId")
  valid_600902 = validateParameter(valid_600902, JString, required = true,
                                 default = nil)
  if valid_600902 != nil:
    section.add "networkId", valid_600902
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
  var valid_600903 = query.getOrDefault("NextToken")
  valid_600903 = validateParameter(valid_600903, JString, required = false,
                                 default = nil)
  if valid_600903 != nil:
    section.add "NextToken", valid_600903
  var valid_600904 = query.getOrDefault("maxResults")
  valid_600904 = validateParameter(valid_600904, JInt, required = false, default = nil)
  if valid_600904 != nil:
    section.add "maxResults", valid_600904
  var valid_600905 = query.getOrDefault("nextToken")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "nextToken", valid_600905
  var valid_600906 = query.getOrDefault("name")
  valid_600906 = validateParameter(valid_600906, JString, required = false,
                                 default = nil)
  if valid_600906 != nil:
    section.add "name", valid_600906
  var valid_600907 = query.getOrDefault("isOwned")
  valid_600907 = validateParameter(valid_600907, JBool, required = false, default = nil)
  if valid_600907 != nil:
    section.add "isOwned", valid_600907
  var valid_600921 = query.getOrDefault("status")
  valid_600921 = validateParameter(valid_600921, JString, required = false,
                                 default = newJString("CREATING"))
  if valid_600921 != nil:
    section.add "status", valid_600921
  var valid_600922 = query.getOrDefault("MaxResults")
  valid_600922 = validateParameter(valid_600922, JString, required = false,
                                 default = nil)
  if valid_600922 != nil:
    section.add "MaxResults", valid_600922
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
  var valid_600923 = header.getOrDefault("X-Amz-Date")
  valid_600923 = validateParameter(valid_600923, JString, required = false,
                                 default = nil)
  if valid_600923 != nil:
    section.add "X-Amz-Date", valid_600923
  var valid_600924 = header.getOrDefault("X-Amz-Security-Token")
  valid_600924 = validateParameter(valid_600924, JString, required = false,
                                 default = nil)
  if valid_600924 != nil:
    section.add "X-Amz-Security-Token", valid_600924
  var valid_600925 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600925 = validateParameter(valid_600925, JString, required = false,
                                 default = nil)
  if valid_600925 != nil:
    section.add "X-Amz-Content-Sha256", valid_600925
  var valid_600926 = header.getOrDefault("X-Amz-Algorithm")
  valid_600926 = validateParameter(valid_600926, JString, required = false,
                                 default = nil)
  if valid_600926 != nil:
    section.add "X-Amz-Algorithm", valid_600926
  var valid_600927 = header.getOrDefault("X-Amz-Signature")
  valid_600927 = validateParameter(valid_600927, JString, required = false,
                                 default = nil)
  if valid_600927 != nil:
    section.add "X-Amz-Signature", valid_600927
  var valid_600928 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600928 = validateParameter(valid_600928, JString, required = false,
                                 default = nil)
  if valid_600928 != nil:
    section.add "X-Amz-SignedHeaders", valid_600928
  var valid_600929 = header.getOrDefault("X-Amz-Credential")
  valid_600929 = validateParameter(valid_600929, JString, required = false,
                                 default = nil)
  if valid_600929 != nil:
    section.add "X-Amz-Credential", valid_600929
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600952: Call_ListMembers_600774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a listing of the members in a network and properties of their configurations.
  ## 
  let valid = call_600952.validator(path, query, header, formData, body)
  let scheme = call_600952.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600952.url(scheme.get, call_600952.host, call_600952.base,
                         call_600952.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_600952, url, valid)

proc call*(call_601023: Call_ListMembers_600774; networkId: string;
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
  var path_601024 = newJObject()
  var query_601026 = newJObject()
  add(path_601024, "networkId", newJString(networkId))
  add(query_601026, "NextToken", newJString(NextToken))
  add(query_601026, "maxResults", newJInt(maxResults))
  add(query_601026, "nextToken", newJString(nextToken))
  add(query_601026, "name", newJString(name))
  add(query_601026, "isOwned", newJBool(isOwned))
  add(query_601026, "status", newJString(status))
  add(query_601026, "MaxResults", newJString(MaxResults))
  result = call_601023.call(path_601024, query_601026, nil, nil, nil)

var listMembers* = Call_ListMembers_600774(name: "listMembers",
                                        meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
                                        route: "/networks/{networkId}/members",
                                        validator: validate_ListMembers_600775,
                                        base: "/", url: url_ListMembers_600776,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNetwork_601101 = ref object of OpenApiRestCall_600437
proc url_CreateNetwork_601103(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateNetwork_601102(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601104 = header.getOrDefault("X-Amz-Date")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Date", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Security-Token")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Security-Token", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Content-Sha256", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Algorithm")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Algorithm", valid_601107
  var valid_601108 = header.getOrDefault("X-Amz-Signature")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-Signature", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-SignedHeaders", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-Credential")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Credential", valid_601110
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601112: Call_CreateNetwork_601101; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new blockchain network using Amazon Managed Blockchain.
  ## 
  let valid = call_601112.validator(path, query, header, formData, body)
  let scheme = call_601112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601112.url(scheme.get, call_601112.host, call_601112.base,
                         call_601112.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601112, url, valid)

proc call*(call_601113: Call_CreateNetwork_601101; body: JsonNode): Recallable =
  ## createNetwork
  ## Creates a new blockchain network using Amazon Managed Blockchain.
  ##   body: JObject (required)
  var body_601114 = newJObject()
  if body != nil:
    body_601114 = body
  result = call_601113.call(nil, nil, nil, nil, body_601114)

var createNetwork* = Call_CreateNetwork_601101(name: "createNetwork",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks", validator: validate_CreateNetwork_601102, base: "/",
    url: url_CreateNetwork_601103, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNetworks_601081 = ref object of OpenApiRestCall_600437
proc url_ListNetworks_601083(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListNetworks_601082(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601084 = query.getOrDefault("framework")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = newJString("HYPERLEDGER_FABRIC"))
  if valid_601084 != nil:
    section.add "framework", valid_601084
  var valid_601085 = query.getOrDefault("NextToken")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "NextToken", valid_601085
  var valid_601086 = query.getOrDefault("maxResults")
  valid_601086 = validateParameter(valid_601086, JInt, required = false, default = nil)
  if valid_601086 != nil:
    section.add "maxResults", valid_601086
  var valid_601087 = query.getOrDefault("nextToken")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "nextToken", valid_601087
  var valid_601088 = query.getOrDefault("name")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "name", valid_601088
  var valid_601089 = query.getOrDefault("status")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = newJString("CREATING"))
  if valid_601089 != nil:
    section.add "status", valid_601089
  var valid_601090 = query.getOrDefault("MaxResults")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "MaxResults", valid_601090
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
  var valid_601091 = header.getOrDefault("X-Amz-Date")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Date", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Security-Token")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Security-Token", valid_601092
  var valid_601093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-Content-Sha256", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-Algorithm")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Algorithm", valid_601094
  var valid_601095 = header.getOrDefault("X-Amz-Signature")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-Signature", valid_601095
  var valid_601096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-SignedHeaders", valid_601096
  var valid_601097 = header.getOrDefault("X-Amz-Credential")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "X-Amz-Credential", valid_601097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601098: Call_ListNetworks_601081; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the networks in which the current AWS account has members.
  ## 
  let valid = call_601098.validator(path, query, header, formData, body)
  let scheme = call_601098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601098.url(scheme.get, call_601098.host, call_601098.base,
                         call_601098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601098, url, valid)

proc call*(call_601099: Call_ListNetworks_601081;
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
  var query_601100 = newJObject()
  add(query_601100, "framework", newJString(framework))
  add(query_601100, "NextToken", newJString(NextToken))
  add(query_601100, "maxResults", newJInt(maxResults))
  add(query_601100, "nextToken", newJString(nextToken))
  add(query_601100, "name", newJString(name))
  add(query_601100, "status", newJString(status))
  add(query_601100, "MaxResults", newJString(MaxResults))
  result = call_601099.call(nil, query_601100, nil, nil, nil)

var listNetworks* = Call_ListNetworks_601081(name: "listNetworks",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks", validator: validate_ListNetworks_601082, base: "/",
    url: url_ListNetworks_601083, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNode_601136 = ref object of OpenApiRestCall_600437
proc url_CreateNode_601138(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateNode_601137(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601139 = path.getOrDefault("networkId")
  valid_601139 = validateParameter(valid_601139, JString, required = true,
                                 default = nil)
  if valid_601139 != nil:
    section.add "networkId", valid_601139
  var valid_601140 = path.getOrDefault("memberId")
  valid_601140 = validateParameter(valid_601140, JString, required = true,
                                 default = nil)
  if valid_601140 != nil:
    section.add "memberId", valid_601140
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
  var valid_601141 = header.getOrDefault("X-Amz-Date")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-Date", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-Security-Token")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-Security-Token", valid_601142
  var valid_601143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-Content-Sha256", valid_601143
  var valid_601144 = header.getOrDefault("X-Amz-Algorithm")
  valid_601144 = validateParameter(valid_601144, JString, required = false,
                                 default = nil)
  if valid_601144 != nil:
    section.add "X-Amz-Algorithm", valid_601144
  var valid_601145 = header.getOrDefault("X-Amz-Signature")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-Signature", valid_601145
  var valid_601146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-SignedHeaders", valid_601146
  var valid_601147 = header.getOrDefault("X-Amz-Credential")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "X-Amz-Credential", valid_601147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601149: Call_CreateNode_601136; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a peer node in a member.
  ## 
  let valid = call_601149.validator(path, query, header, formData, body)
  let scheme = call_601149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601149.url(scheme.get, call_601149.host, call_601149.base,
                         call_601149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601149, url, valid)

proc call*(call_601150: Call_CreateNode_601136; networkId: string; memberId: string;
          body: JsonNode): Recallable =
  ## createNode
  ## Creates a peer node in a member.
  ##   networkId: string (required)
  ##            : The unique identifier of the network in which this node runs.
  ##   memberId: string (required)
  ##           : The unique identifier of the member that owns this node.
  ##   body: JObject (required)
  var path_601151 = newJObject()
  var body_601152 = newJObject()
  add(path_601151, "networkId", newJString(networkId))
  add(path_601151, "memberId", newJString(memberId))
  if body != nil:
    body_601152 = body
  result = call_601150.call(path_601151, nil, nil, nil, body_601152)

var createNode* = Call_CreateNode_601136(name: "createNode",
                                      meth: HttpMethod.HttpPost,
                                      host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes",
                                      validator: validate_CreateNode_601137,
                                      base: "/", url: url_CreateNode_601138,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNodes_601115 = ref object of OpenApiRestCall_600437
proc url_ListNodes_601117(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListNodes_601116(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601118 = path.getOrDefault("networkId")
  valid_601118 = validateParameter(valid_601118, JString, required = true,
                                 default = nil)
  if valid_601118 != nil:
    section.add "networkId", valid_601118
  var valid_601119 = path.getOrDefault("memberId")
  valid_601119 = validateParameter(valid_601119, JString, required = true,
                                 default = nil)
  if valid_601119 != nil:
    section.add "memberId", valid_601119
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
  var valid_601120 = query.getOrDefault("NextToken")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "NextToken", valid_601120
  var valid_601121 = query.getOrDefault("maxResults")
  valid_601121 = validateParameter(valid_601121, JInt, required = false, default = nil)
  if valid_601121 != nil:
    section.add "maxResults", valid_601121
  var valid_601122 = query.getOrDefault("nextToken")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "nextToken", valid_601122
  var valid_601123 = query.getOrDefault("status")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = newJString("CREATING"))
  if valid_601123 != nil:
    section.add "status", valid_601123
  var valid_601124 = query.getOrDefault("MaxResults")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "MaxResults", valid_601124
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
  var valid_601125 = header.getOrDefault("X-Amz-Date")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Date", valid_601125
  var valid_601126 = header.getOrDefault("X-Amz-Security-Token")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Security-Token", valid_601126
  var valid_601127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-Content-Sha256", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-Algorithm")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-Algorithm", valid_601128
  var valid_601129 = header.getOrDefault("X-Amz-Signature")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-Signature", valid_601129
  var valid_601130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-SignedHeaders", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-Credential")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Credential", valid_601131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601132: Call_ListNodes_601115; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the nodes within a network.
  ## 
  let valid = call_601132.validator(path, query, header, formData, body)
  let scheme = call_601132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601132.url(scheme.get, call_601132.host, call_601132.base,
                         call_601132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601132, url, valid)

proc call*(call_601133: Call_ListNodes_601115; networkId: string; memberId: string;
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
  var path_601134 = newJObject()
  var query_601135 = newJObject()
  add(path_601134, "networkId", newJString(networkId))
  add(path_601134, "memberId", newJString(memberId))
  add(query_601135, "NextToken", newJString(NextToken))
  add(query_601135, "maxResults", newJInt(maxResults))
  add(query_601135, "nextToken", newJString(nextToken))
  add(query_601135, "status", newJString(status))
  add(query_601135, "MaxResults", newJString(MaxResults))
  result = call_601133.call(path_601134, query_601135, nil, nil, nil)

var listNodes* = Call_ListNodes_601115(name: "listNodes", meth: HttpMethod.HttpGet,
                                    host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes",
                                    validator: validate_ListNodes_601116,
                                    base: "/", url: url_ListNodes_601117,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProposal_601172 = ref object of OpenApiRestCall_600437
proc url_CreateProposal_601174(protocol: Scheme; host: string; base: string;
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

proc validate_CreateProposal_601173(path: JsonNode; query: JsonNode;
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
  var valid_601175 = path.getOrDefault("networkId")
  valid_601175 = validateParameter(valid_601175, JString, required = true,
                                 default = nil)
  if valid_601175 != nil:
    section.add "networkId", valid_601175
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
  var valid_601176 = header.getOrDefault("X-Amz-Date")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "X-Amz-Date", valid_601176
  var valid_601177 = header.getOrDefault("X-Amz-Security-Token")
  valid_601177 = validateParameter(valid_601177, JString, required = false,
                                 default = nil)
  if valid_601177 != nil:
    section.add "X-Amz-Security-Token", valid_601177
  var valid_601178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "X-Amz-Content-Sha256", valid_601178
  var valid_601179 = header.getOrDefault("X-Amz-Algorithm")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "X-Amz-Algorithm", valid_601179
  var valid_601180 = header.getOrDefault("X-Amz-Signature")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Signature", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-SignedHeaders", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Credential")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Credential", valid_601182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601184: Call_CreateProposal_601172; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a proposal for a change to the network that other members of the network can vote on, for example, a proposal to add a new member to the network. Any member can create a proposal.
  ## 
  let valid = call_601184.validator(path, query, header, formData, body)
  let scheme = call_601184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601184.url(scheme.get, call_601184.host, call_601184.base,
                         call_601184.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601184, url, valid)

proc call*(call_601185: Call_CreateProposal_601172; networkId: string; body: JsonNode): Recallable =
  ## createProposal
  ## Creates a proposal for a change to the network that other members of the network can vote on, for example, a proposal to add a new member to the network. Any member can create a proposal.
  ##   networkId: string (required)
  ##            :  The unique identifier of the network for which the proposal is made.
  ##   body: JObject (required)
  var path_601186 = newJObject()
  var body_601187 = newJObject()
  add(path_601186, "networkId", newJString(networkId))
  if body != nil:
    body_601187 = body
  result = call_601185.call(path_601186, nil, nil, nil, body_601187)

var createProposal* = Call_CreateProposal_601172(name: "createProposal",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals", validator: validate_CreateProposal_601173,
    base: "/", url: url_CreateProposal_601174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProposals_601153 = ref object of OpenApiRestCall_600437
proc url_ListProposals_601155(protocol: Scheme; host: string; base: string;
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

proc validate_ListProposals_601154(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601156 = path.getOrDefault("networkId")
  valid_601156 = validateParameter(valid_601156, JString, required = true,
                                 default = nil)
  if valid_601156 != nil:
    section.add "networkId", valid_601156
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
  var valid_601157 = query.getOrDefault("NextToken")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "NextToken", valid_601157
  var valid_601158 = query.getOrDefault("maxResults")
  valid_601158 = validateParameter(valid_601158, JInt, required = false, default = nil)
  if valid_601158 != nil:
    section.add "maxResults", valid_601158
  var valid_601159 = query.getOrDefault("nextToken")
  valid_601159 = validateParameter(valid_601159, JString, required = false,
                                 default = nil)
  if valid_601159 != nil:
    section.add "nextToken", valid_601159
  var valid_601160 = query.getOrDefault("MaxResults")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "MaxResults", valid_601160
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
  var valid_601161 = header.getOrDefault("X-Amz-Date")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "X-Amz-Date", valid_601161
  var valid_601162 = header.getOrDefault("X-Amz-Security-Token")
  valid_601162 = validateParameter(valid_601162, JString, required = false,
                                 default = nil)
  if valid_601162 != nil:
    section.add "X-Amz-Security-Token", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-Content-Sha256", valid_601163
  var valid_601164 = header.getOrDefault("X-Amz-Algorithm")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Algorithm", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-Signature")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Signature", valid_601165
  var valid_601166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-SignedHeaders", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Credential")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Credential", valid_601167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601168: Call_ListProposals_601153; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a listing of proposals for the network.
  ## 
  let valid = call_601168.validator(path, query, header, formData, body)
  let scheme = call_601168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601168.url(scheme.get, call_601168.host, call_601168.base,
                         call_601168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601168, url, valid)

proc call*(call_601169: Call_ListProposals_601153; networkId: string;
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
  var path_601170 = newJObject()
  var query_601171 = newJObject()
  add(path_601170, "networkId", newJString(networkId))
  add(query_601171, "NextToken", newJString(NextToken))
  add(query_601171, "maxResults", newJInt(maxResults))
  add(query_601171, "nextToken", newJString(nextToken))
  add(query_601171, "MaxResults", newJString(MaxResults))
  result = call_601169.call(path_601170, query_601171, nil, nil, nil)

var listProposals* = Call_ListProposals_601153(name: "listProposals",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals", validator: validate_ListProposals_601154,
    base: "/", url: url_ListProposals_601155, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMember_601188 = ref object of OpenApiRestCall_600437
proc url_GetMember_601190(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetMember_601189(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601191 = path.getOrDefault("networkId")
  valid_601191 = validateParameter(valid_601191, JString, required = true,
                                 default = nil)
  if valid_601191 != nil:
    section.add "networkId", valid_601191
  var valid_601192 = path.getOrDefault("memberId")
  valid_601192 = validateParameter(valid_601192, JString, required = true,
                                 default = nil)
  if valid_601192 != nil:
    section.add "memberId", valid_601192
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
  var valid_601193 = header.getOrDefault("X-Amz-Date")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-Date", valid_601193
  var valid_601194 = header.getOrDefault("X-Amz-Security-Token")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Security-Token", valid_601194
  var valid_601195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-Content-Sha256", valid_601195
  var valid_601196 = header.getOrDefault("X-Amz-Algorithm")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-Algorithm", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Signature")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Signature", valid_601197
  var valid_601198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "X-Amz-SignedHeaders", valid_601198
  var valid_601199 = header.getOrDefault("X-Amz-Credential")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-Credential", valid_601199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601200: Call_GetMember_601188; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a member.
  ## 
  let valid = call_601200.validator(path, query, header, formData, body)
  let scheme = call_601200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601200.url(scheme.get, call_601200.host, call_601200.base,
                         call_601200.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601200, url, valid)

proc call*(call_601201: Call_GetMember_601188; networkId: string; memberId: string): Recallable =
  ## getMember
  ## Returns detailed information about a member.
  ##   networkId: string (required)
  ##            : The unique identifier of the network to which the member belongs.
  ##   memberId: string (required)
  ##           : The unique identifier of the member.
  var path_601202 = newJObject()
  add(path_601202, "networkId", newJString(networkId))
  add(path_601202, "memberId", newJString(memberId))
  result = call_601201.call(path_601202, nil, nil, nil, nil)

var getMember* = Call_GetMember_601188(name: "getMember", meth: HttpMethod.HttpGet,
                                    host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}",
                                    validator: validate_GetMember_601189,
                                    base: "/", url: url_GetMember_601190,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMember_601203 = ref object of OpenApiRestCall_600437
proc url_DeleteMember_601205(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMember_601204(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601206 = path.getOrDefault("networkId")
  valid_601206 = validateParameter(valid_601206, JString, required = true,
                                 default = nil)
  if valid_601206 != nil:
    section.add "networkId", valid_601206
  var valid_601207 = path.getOrDefault("memberId")
  valid_601207 = validateParameter(valid_601207, JString, required = true,
                                 default = nil)
  if valid_601207 != nil:
    section.add "memberId", valid_601207
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
  var valid_601208 = header.getOrDefault("X-Amz-Date")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-Date", valid_601208
  var valid_601209 = header.getOrDefault("X-Amz-Security-Token")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Security-Token", valid_601209
  var valid_601210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Content-Sha256", valid_601210
  var valid_601211 = header.getOrDefault("X-Amz-Algorithm")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-Algorithm", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-Signature")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Signature", valid_601212
  var valid_601213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "X-Amz-SignedHeaders", valid_601213
  var valid_601214 = header.getOrDefault("X-Amz-Credential")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "X-Amz-Credential", valid_601214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601215: Call_DeleteMember_601203; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a member. Deleting a member removes the member and all associated resources from the network. <code>DeleteMember</code> can only be called for a specified <code>MemberId</code> if the principal performing the action is associated with the AWS account that owns the member. In all other cases, the <code>DeleteMember</code> action is carried out as the result of an approved proposal to remove a member. If <code>MemberId</code> is the last member in a network specified by the last AWS account, the network is deleted also.
  ## 
  let valid = call_601215.validator(path, query, header, formData, body)
  let scheme = call_601215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601215.url(scheme.get, call_601215.host, call_601215.base,
                         call_601215.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601215, url, valid)

proc call*(call_601216: Call_DeleteMember_601203; networkId: string; memberId: string): Recallable =
  ## deleteMember
  ## Deletes a member. Deleting a member removes the member and all associated resources from the network. <code>DeleteMember</code> can only be called for a specified <code>MemberId</code> if the principal performing the action is associated with the AWS account that owns the member. In all other cases, the <code>DeleteMember</code> action is carried out as the result of an approved proposal to remove a member. If <code>MemberId</code> is the last member in a network specified by the last AWS account, the network is deleted also.
  ##   networkId: string (required)
  ##            : The unique identifier of the network from which the member is removed.
  ##   memberId: string (required)
  ##           : The unique identifier of the member to remove.
  var path_601217 = newJObject()
  add(path_601217, "networkId", newJString(networkId))
  add(path_601217, "memberId", newJString(memberId))
  result = call_601216.call(path_601217, nil, nil, nil, nil)

var deleteMember* = Call_DeleteMember_601203(name: "deleteMember",
    meth: HttpMethod.HttpDelete, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/members/{memberId}",
    validator: validate_DeleteMember_601204, base: "/", url: url_DeleteMember_601205,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNode_601218 = ref object of OpenApiRestCall_600437
proc url_GetNode_601220(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetNode_601219(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601221 = path.getOrDefault("networkId")
  valid_601221 = validateParameter(valid_601221, JString, required = true,
                                 default = nil)
  if valid_601221 != nil:
    section.add "networkId", valid_601221
  var valid_601222 = path.getOrDefault("memberId")
  valid_601222 = validateParameter(valid_601222, JString, required = true,
                                 default = nil)
  if valid_601222 != nil:
    section.add "memberId", valid_601222
  var valid_601223 = path.getOrDefault("nodeId")
  valid_601223 = validateParameter(valid_601223, JString, required = true,
                                 default = nil)
  if valid_601223 != nil:
    section.add "nodeId", valid_601223
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
  var valid_601224 = header.getOrDefault("X-Amz-Date")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "X-Amz-Date", valid_601224
  var valid_601225 = header.getOrDefault("X-Amz-Security-Token")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "X-Amz-Security-Token", valid_601225
  var valid_601226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "X-Amz-Content-Sha256", valid_601226
  var valid_601227 = header.getOrDefault("X-Amz-Algorithm")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Algorithm", valid_601227
  var valid_601228 = header.getOrDefault("X-Amz-Signature")
  valid_601228 = validateParameter(valid_601228, JString, required = false,
                                 default = nil)
  if valid_601228 != nil:
    section.add "X-Amz-Signature", valid_601228
  var valid_601229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = nil)
  if valid_601229 != nil:
    section.add "X-Amz-SignedHeaders", valid_601229
  var valid_601230 = header.getOrDefault("X-Amz-Credential")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-Credential", valid_601230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601231: Call_GetNode_601218; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a peer node.
  ## 
  let valid = call_601231.validator(path, query, header, formData, body)
  let scheme = call_601231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601231.url(scheme.get, call_601231.host, call_601231.base,
                         call_601231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601231, url, valid)

proc call*(call_601232: Call_GetNode_601218; networkId: string; memberId: string;
          nodeId: string): Recallable =
  ## getNode
  ## Returns detailed information about a peer node.
  ##   networkId: string (required)
  ##            : The unique identifier of the network to which the node belongs.
  ##   memberId: string (required)
  ##           : The unique identifier of the member that owns the node.
  ##   nodeId: string (required)
  ##         : The unique identifier of the node.
  var path_601233 = newJObject()
  add(path_601233, "networkId", newJString(networkId))
  add(path_601233, "memberId", newJString(memberId))
  add(path_601233, "nodeId", newJString(nodeId))
  result = call_601232.call(path_601233, nil, nil, nil, nil)

var getNode* = Call_GetNode_601218(name: "getNode", meth: HttpMethod.HttpGet,
                                host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes/{nodeId}",
                                validator: validate_GetNode_601219, base: "/",
                                url: url_GetNode_601220,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNode_601234 = ref object of OpenApiRestCall_600437
proc url_DeleteNode_601236(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteNode_601235(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601237 = path.getOrDefault("networkId")
  valid_601237 = validateParameter(valid_601237, JString, required = true,
                                 default = nil)
  if valid_601237 != nil:
    section.add "networkId", valid_601237
  var valid_601238 = path.getOrDefault("memberId")
  valid_601238 = validateParameter(valid_601238, JString, required = true,
                                 default = nil)
  if valid_601238 != nil:
    section.add "memberId", valid_601238
  var valid_601239 = path.getOrDefault("nodeId")
  valid_601239 = validateParameter(valid_601239, JString, required = true,
                                 default = nil)
  if valid_601239 != nil:
    section.add "nodeId", valid_601239
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
  var valid_601240 = header.getOrDefault("X-Amz-Date")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "X-Amz-Date", valid_601240
  var valid_601241 = header.getOrDefault("X-Amz-Security-Token")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "X-Amz-Security-Token", valid_601241
  var valid_601242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Content-Sha256", valid_601242
  var valid_601243 = header.getOrDefault("X-Amz-Algorithm")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "X-Amz-Algorithm", valid_601243
  var valid_601244 = header.getOrDefault("X-Amz-Signature")
  valid_601244 = validateParameter(valid_601244, JString, required = false,
                                 default = nil)
  if valid_601244 != nil:
    section.add "X-Amz-Signature", valid_601244
  var valid_601245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-SignedHeaders", valid_601245
  var valid_601246 = header.getOrDefault("X-Amz-Credential")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-Credential", valid_601246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601247: Call_DeleteNode_601234; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a peer node from a member that your AWS account owns. All data on the node is lost and cannot be recovered.
  ## 
  let valid = call_601247.validator(path, query, header, formData, body)
  let scheme = call_601247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601247.url(scheme.get, call_601247.host, call_601247.base,
                         call_601247.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601247, url, valid)

proc call*(call_601248: Call_DeleteNode_601234; networkId: string; memberId: string;
          nodeId: string): Recallable =
  ## deleteNode
  ## Deletes a peer node from a member that your AWS account owns. All data on the node is lost and cannot be recovered.
  ##   networkId: string (required)
  ##            : The unique identifier of the network that the node belongs to.
  ##   memberId: string (required)
  ##           : The unique identifier of the member that owns this node.
  ##   nodeId: string (required)
  ##         : The unique identifier of the node.
  var path_601249 = newJObject()
  add(path_601249, "networkId", newJString(networkId))
  add(path_601249, "memberId", newJString(memberId))
  add(path_601249, "nodeId", newJString(nodeId))
  result = call_601248.call(path_601249, nil, nil, nil, nil)

var deleteNode* = Call_DeleteNode_601234(name: "deleteNode",
                                      meth: HttpMethod.HttpDelete,
                                      host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes/{nodeId}",
                                      validator: validate_DeleteNode_601235,
                                      base: "/", url: url_DeleteNode_601236,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNetwork_601250 = ref object of OpenApiRestCall_600437
proc url_GetNetwork_601252(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetNetwork_601251(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601253 = path.getOrDefault("networkId")
  valid_601253 = validateParameter(valid_601253, JString, required = true,
                                 default = nil)
  if valid_601253 != nil:
    section.add "networkId", valid_601253
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
  var valid_601254 = header.getOrDefault("X-Amz-Date")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-Date", valid_601254
  var valid_601255 = header.getOrDefault("X-Amz-Security-Token")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "X-Amz-Security-Token", valid_601255
  var valid_601256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-Content-Sha256", valid_601256
  var valid_601257 = header.getOrDefault("X-Amz-Algorithm")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Algorithm", valid_601257
  var valid_601258 = header.getOrDefault("X-Amz-Signature")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "X-Amz-Signature", valid_601258
  var valid_601259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601259 = validateParameter(valid_601259, JString, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "X-Amz-SignedHeaders", valid_601259
  var valid_601260 = header.getOrDefault("X-Amz-Credential")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "X-Amz-Credential", valid_601260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601261: Call_GetNetwork_601250; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a network.
  ## 
  let valid = call_601261.validator(path, query, header, formData, body)
  let scheme = call_601261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601261.url(scheme.get, call_601261.host, call_601261.base,
                         call_601261.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601261, url, valid)

proc call*(call_601262: Call_GetNetwork_601250; networkId: string): Recallable =
  ## getNetwork
  ## Returns detailed information about a network.
  ##   networkId: string (required)
  ##            : The unique identifier of the network to get information about.
  var path_601263 = newJObject()
  add(path_601263, "networkId", newJString(networkId))
  result = call_601262.call(path_601263, nil, nil, nil, nil)

var getNetwork* = Call_GetNetwork_601250(name: "getNetwork",
                                      meth: HttpMethod.HttpGet,
                                      host: "managedblockchain.amazonaws.com",
                                      route: "/networks/{networkId}",
                                      validator: validate_GetNetwork_601251,
                                      base: "/", url: url_GetNetwork_601252,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProposal_601264 = ref object of OpenApiRestCall_600437
proc url_GetProposal_601266(protocol: Scheme; host: string; base: string;
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

proc validate_GetProposal_601265(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601267 = path.getOrDefault("networkId")
  valid_601267 = validateParameter(valid_601267, JString, required = true,
                                 default = nil)
  if valid_601267 != nil:
    section.add "networkId", valid_601267
  var valid_601268 = path.getOrDefault("proposalId")
  valid_601268 = validateParameter(valid_601268, JString, required = true,
                                 default = nil)
  if valid_601268 != nil:
    section.add "proposalId", valid_601268
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
  var valid_601269 = header.getOrDefault("X-Amz-Date")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "X-Amz-Date", valid_601269
  var valid_601270 = header.getOrDefault("X-Amz-Security-Token")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "X-Amz-Security-Token", valid_601270
  var valid_601271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "X-Amz-Content-Sha256", valid_601271
  var valid_601272 = header.getOrDefault("X-Amz-Algorithm")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-Algorithm", valid_601272
  var valid_601273 = header.getOrDefault("X-Amz-Signature")
  valid_601273 = validateParameter(valid_601273, JString, required = false,
                                 default = nil)
  if valid_601273 != nil:
    section.add "X-Amz-Signature", valid_601273
  var valid_601274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601274 = validateParameter(valid_601274, JString, required = false,
                                 default = nil)
  if valid_601274 != nil:
    section.add "X-Amz-SignedHeaders", valid_601274
  var valid_601275 = header.getOrDefault("X-Amz-Credential")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = nil)
  if valid_601275 != nil:
    section.add "X-Amz-Credential", valid_601275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601276: Call_GetProposal_601264; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a proposal.
  ## 
  let valid = call_601276.validator(path, query, header, formData, body)
  let scheme = call_601276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601276.url(scheme.get, call_601276.host, call_601276.base,
                         call_601276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601276, url, valid)

proc call*(call_601277: Call_GetProposal_601264; networkId: string;
          proposalId: string): Recallable =
  ## getProposal
  ## Returns detailed information about a proposal.
  ##   networkId: string (required)
  ##            : The unique identifier of the network for which the proposal is made.
  ##   proposalId: string (required)
  ##             : The unique identifier of the proposal.
  var path_601278 = newJObject()
  add(path_601278, "networkId", newJString(networkId))
  add(path_601278, "proposalId", newJString(proposalId))
  result = call_601277.call(path_601278, nil, nil, nil, nil)

var getProposal* = Call_GetProposal_601264(name: "getProposal",
                                        meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/proposals/{proposalId}",
                                        validator: validate_GetProposal_601265,
                                        base: "/", url: url_GetProposal_601266,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_601279 = ref object of OpenApiRestCall_600437
proc url_ListInvitations_601281(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListInvitations_601280(path: JsonNode; query: JsonNode;
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
  var valid_601282 = query.getOrDefault("NextToken")
  valid_601282 = validateParameter(valid_601282, JString, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "NextToken", valid_601282
  var valid_601283 = query.getOrDefault("maxResults")
  valid_601283 = validateParameter(valid_601283, JInt, required = false, default = nil)
  if valid_601283 != nil:
    section.add "maxResults", valid_601283
  var valid_601284 = query.getOrDefault("nextToken")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "nextToken", valid_601284
  var valid_601285 = query.getOrDefault("MaxResults")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "MaxResults", valid_601285
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
  var valid_601286 = header.getOrDefault("X-Amz-Date")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "X-Amz-Date", valid_601286
  var valid_601287 = header.getOrDefault("X-Amz-Security-Token")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-Security-Token", valid_601287
  var valid_601288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "X-Amz-Content-Sha256", valid_601288
  var valid_601289 = header.getOrDefault("X-Amz-Algorithm")
  valid_601289 = validateParameter(valid_601289, JString, required = false,
                                 default = nil)
  if valid_601289 != nil:
    section.add "X-Amz-Algorithm", valid_601289
  var valid_601290 = header.getOrDefault("X-Amz-Signature")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-Signature", valid_601290
  var valid_601291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-SignedHeaders", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-Credential")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-Credential", valid_601292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601293: Call_ListInvitations_601279; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a listing of all invitations made on the specified network.
  ## 
  let valid = call_601293.validator(path, query, header, formData, body)
  let scheme = call_601293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601293.url(scheme.get, call_601293.host, call_601293.base,
                         call_601293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601293, url, valid)

proc call*(call_601294: Call_ListInvitations_601279; NextToken: string = "";
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
  var query_601295 = newJObject()
  add(query_601295, "NextToken", newJString(NextToken))
  add(query_601295, "maxResults", newJInt(maxResults))
  add(query_601295, "nextToken", newJString(nextToken))
  add(query_601295, "MaxResults", newJString(MaxResults))
  result = call_601294.call(nil, query_601295, nil, nil, nil)

var listInvitations* = Call_ListInvitations_601279(name: "listInvitations",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/invitations", validator: validate_ListInvitations_601280, base: "/",
    url: url_ListInvitations_601281, schemes: {Scheme.Https, Scheme.Http})
type
  Call_VoteOnProposal_601316 = ref object of OpenApiRestCall_600437
proc url_VoteOnProposal_601318(protocol: Scheme; host: string; base: string;
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

proc validate_VoteOnProposal_601317(path: JsonNode; query: JsonNode;
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
  var valid_601319 = path.getOrDefault("networkId")
  valid_601319 = validateParameter(valid_601319, JString, required = true,
                                 default = nil)
  if valid_601319 != nil:
    section.add "networkId", valid_601319
  var valid_601320 = path.getOrDefault("proposalId")
  valid_601320 = validateParameter(valid_601320, JString, required = true,
                                 default = nil)
  if valid_601320 != nil:
    section.add "proposalId", valid_601320
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
  var valid_601321 = header.getOrDefault("X-Amz-Date")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "X-Amz-Date", valid_601321
  var valid_601322 = header.getOrDefault("X-Amz-Security-Token")
  valid_601322 = validateParameter(valid_601322, JString, required = false,
                                 default = nil)
  if valid_601322 != nil:
    section.add "X-Amz-Security-Token", valid_601322
  var valid_601323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601323 = validateParameter(valid_601323, JString, required = false,
                                 default = nil)
  if valid_601323 != nil:
    section.add "X-Amz-Content-Sha256", valid_601323
  var valid_601324 = header.getOrDefault("X-Amz-Algorithm")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "X-Amz-Algorithm", valid_601324
  var valid_601325 = header.getOrDefault("X-Amz-Signature")
  valid_601325 = validateParameter(valid_601325, JString, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "X-Amz-Signature", valid_601325
  var valid_601326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "X-Amz-SignedHeaders", valid_601326
  var valid_601327 = header.getOrDefault("X-Amz-Credential")
  valid_601327 = validateParameter(valid_601327, JString, required = false,
                                 default = nil)
  if valid_601327 != nil:
    section.add "X-Amz-Credential", valid_601327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601329: Call_VoteOnProposal_601316; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Casts a vote for a specified <code>ProposalId</code> on behalf of a member. The member to vote as, specified by <code>VoterMemberId</code>, must be in the same AWS account as the principal that calls the action.
  ## 
  let valid = call_601329.validator(path, query, header, formData, body)
  let scheme = call_601329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601329.url(scheme.get, call_601329.host, call_601329.base,
                         call_601329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601329, url, valid)

proc call*(call_601330: Call_VoteOnProposal_601316; networkId: string;
          proposalId: string; body: JsonNode): Recallable =
  ## voteOnProposal
  ## Casts a vote for a specified <code>ProposalId</code> on behalf of a member. The member to vote as, specified by <code>VoterMemberId</code>, must be in the same AWS account as the principal that calls the action.
  ##   networkId: string (required)
  ##            :  The unique identifier of the network. 
  ##   proposalId: string (required)
  ##             :  The unique identifier of the proposal. 
  ##   body: JObject (required)
  var path_601331 = newJObject()
  var body_601332 = newJObject()
  add(path_601331, "networkId", newJString(networkId))
  add(path_601331, "proposalId", newJString(proposalId))
  if body != nil:
    body_601332 = body
  result = call_601330.call(path_601331, nil, nil, nil, body_601332)

var voteOnProposal* = Call_VoteOnProposal_601316(name: "voteOnProposal",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals/{proposalId}/votes",
    validator: validate_VoteOnProposal_601317, base: "/", url: url_VoteOnProposal_601318,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProposalVotes_601296 = ref object of OpenApiRestCall_600437
proc url_ListProposalVotes_601298(protocol: Scheme; host: string; base: string;
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

proc validate_ListProposalVotes_601297(path: JsonNode; query: JsonNode;
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
  var valid_601299 = path.getOrDefault("networkId")
  valid_601299 = validateParameter(valid_601299, JString, required = true,
                                 default = nil)
  if valid_601299 != nil:
    section.add "networkId", valid_601299
  var valid_601300 = path.getOrDefault("proposalId")
  valid_601300 = validateParameter(valid_601300, JString, required = true,
                                 default = nil)
  if valid_601300 != nil:
    section.add "proposalId", valid_601300
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
  var valid_601301 = query.getOrDefault("NextToken")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "NextToken", valid_601301
  var valid_601302 = query.getOrDefault("maxResults")
  valid_601302 = validateParameter(valid_601302, JInt, required = false, default = nil)
  if valid_601302 != nil:
    section.add "maxResults", valid_601302
  var valid_601303 = query.getOrDefault("nextToken")
  valid_601303 = validateParameter(valid_601303, JString, required = false,
                                 default = nil)
  if valid_601303 != nil:
    section.add "nextToken", valid_601303
  var valid_601304 = query.getOrDefault("MaxResults")
  valid_601304 = validateParameter(valid_601304, JString, required = false,
                                 default = nil)
  if valid_601304 != nil:
    section.add "MaxResults", valid_601304
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
  var valid_601305 = header.getOrDefault("X-Amz-Date")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "X-Amz-Date", valid_601305
  var valid_601306 = header.getOrDefault("X-Amz-Security-Token")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-Security-Token", valid_601306
  var valid_601307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "X-Amz-Content-Sha256", valid_601307
  var valid_601308 = header.getOrDefault("X-Amz-Algorithm")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-Algorithm", valid_601308
  var valid_601309 = header.getOrDefault("X-Amz-Signature")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "X-Amz-Signature", valid_601309
  var valid_601310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "X-Amz-SignedHeaders", valid_601310
  var valid_601311 = header.getOrDefault("X-Amz-Credential")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "X-Amz-Credential", valid_601311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601312: Call_ListProposalVotes_601296; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the listing of votes for a specified proposal, including the value of each vote and the unique identifier of the member that cast the vote.
  ## 
  let valid = call_601312.validator(path, query, header, formData, body)
  let scheme = call_601312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601312.url(scheme.get, call_601312.host, call_601312.base,
                         call_601312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601312, url, valid)

proc call*(call_601313: Call_ListProposalVotes_601296; networkId: string;
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
  var path_601314 = newJObject()
  var query_601315 = newJObject()
  add(path_601314, "networkId", newJString(networkId))
  add(path_601314, "proposalId", newJString(proposalId))
  add(query_601315, "NextToken", newJString(NextToken))
  add(query_601315, "maxResults", newJInt(maxResults))
  add(query_601315, "nextToken", newJString(nextToken))
  add(query_601315, "MaxResults", newJString(MaxResults))
  result = call_601313.call(path_601314, query_601315, nil, nil, nil)

var listProposalVotes* = Call_ListProposalVotes_601296(name: "listProposalVotes",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals/{proposalId}/votes",
    validator: validate_ListProposalVotes_601297, base: "/",
    url: url_ListProposalVotes_601298, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectInvitation_601333 = ref object of OpenApiRestCall_600437
proc url_RejectInvitation_601335(protocol: Scheme; host: string; base: string;
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

proc validate_RejectInvitation_601334(path: JsonNode; query: JsonNode;
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
  var valid_601336 = path.getOrDefault("invitationId")
  valid_601336 = validateParameter(valid_601336, JString, required = true,
                                 default = nil)
  if valid_601336 != nil:
    section.add "invitationId", valid_601336
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
  var valid_601337 = header.getOrDefault("X-Amz-Date")
  valid_601337 = validateParameter(valid_601337, JString, required = false,
                                 default = nil)
  if valid_601337 != nil:
    section.add "X-Amz-Date", valid_601337
  var valid_601338 = header.getOrDefault("X-Amz-Security-Token")
  valid_601338 = validateParameter(valid_601338, JString, required = false,
                                 default = nil)
  if valid_601338 != nil:
    section.add "X-Amz-Security-Token", valid_601338
  var valid_601339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601339 = validateParameter(valid_601339, JString, required = false,
                                 default = nil)
  if valid_601339 != nil:
    section.add "X-Amz-Content-Sha256", valid_601339
  var valid_601340 = header.getOrDefault("X-Amz-Algorithm")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "X-Amz-Algorithm", valid_601340
  var valid_601341 = header.getOrDefault("X-Amz-Signature")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "X-Amz-Signature", valid_601341
  var valid_601342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601342 = validateParameter(valid_601342, JString, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "X-Amz-SignedHeaders", valid_601342
  var valid_601343 = header.getOrDefault("X-Amz-Credential")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "X-Amz-Credential", valid_601343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601344: Call_RejectInvitation_601333; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Rejects an invitation to join a network. This action can be called by a principal in an AWS account that has received an invitation to create a member and join a network.
  ## 
  let valid = call_601344.validator(path, query, header, formData, body)
  let scheme = call_601344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601344.url(scheme.get, call_601344.host, call_601344.base,
                         call_601344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601344, url, valid)

proc call*(call_601345: Call_RejectInvitation_601333; invitationId: string): Recallable =
  ## rejectInvitation
  ## Rejects an invitation to join a network. This action can be called by a principal in an AWS account that has received an invitation to create a member and join a network.
  ##   invitationId: string (required)
  ##               : The unique identifier of the invitation to reject.
  var path_601346 = newJObject()
  add(path_601346, "invitationId", newJString(invitationId))
  result = call_601345.call(path_601346, nil, nil, nil, nil)

var rejectInvitation* = Call_RejectInvitation_601333(name: "rejectInvitation",
    meth: HttpMethod.HttpDelete, host: "managedblockchain.amazonaws.com",
    route: "/invitations/{invitationId}", validator: validate_RejectInvitation_601334,
    base: "/", url: url_RejectInvitation_601335,
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
