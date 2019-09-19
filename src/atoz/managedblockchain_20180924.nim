
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

  OpenApiRestCall_772597 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772597](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772597): Option[Scheme] {.used.} =
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
  Call_CreateMember_773224 = ref object of OpenApiRestCall_772597
proc url_CreateMember_773226(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMember_773225(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773227 = path.getOrDefault("networkId")
  valid_773227 = validateParameter(valid_773227, JString, required = true,
                                 default = nil)
  if valid_773227 != nil:
    section.add "networkId", valid_773227
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
  var valid_773228 = header.getOrDefault("X-Amz-Date")
  valid_773228 = validateParameter(valid_773228, JString, required = false,
                                 default = nil)
  if valid_773228 != nil:
    section.add "X-Amz-Date", valid_773228
  var valid_773229 = header.getOrDefault("X-Amz-Security-Token")
  valid_773229 = validateParameter(valid_773229, JString, required = false,
                                 default = nil)
  if valid_773229 != nil:
    section.add "X-Amz-Security-Token", valid_773229
  var valid_773230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773230 = validateParameter(valid_773230, JString, required = false,
                                 default = nil)
  if valid_773230 != nil:
    section.add "X-Amz-Content-Sha256", valid_773230
  var valid_773231 = header.getOrDefault("X-Amz-Algorithm")
  valid_773231 = validateParameter(valid_773231, JString, required = false,
                                 default = nil)
  if valid_773231 != nil:
    section.add "X-Amz-Algorithm", valid_773231
  var valid_773232 = header.getOrDefault("X-Amz-Signature")
  valid_773232 = validateParameter(valid_773232, JString, required = false,
                                 default = nil)
  if valid_773232 != nil:
    section.add "X-Amz-Signature", valid_773232
  var valid_773233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773233 = validateParameter(valid_773233, JString, required = false,
                                 default = nil)
  if valid_773233 != nil:
    section.add "X-Amz-SignedHeaders", valid_773233
  var valid_773234 = header.getOrDefault("X-Amz-Credential")
  valid_773234 = validateParameter(valid_773234, JString, required = false,
                                 default = nil)
  if valid_773234 != nil:
    section.add "X-Amz-Credential", valid_773234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773236: Call_CreateMember_773224; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a member within a Managed Blockchain network.
  ## 
  let valid = call_773236.validator(path, query, header, formData, body)
  let scheme = call_773236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773236.url(scheme.get, call_773236.host, call_773236.base,
                         call_773236.route, valid.getOrDefault("path"))
  result = hook(call_773236, url, valid)

proc call*(call_773237: Call_CreateMember_773224; networkId: string; body: JsonNode): Recallable =
  ## createMember
  ## Creates a member within a Managed Blockchain network.
  ##   networkId: string (required)
  ##            : The unique identifier of the network in which the member is created.
  ##   body: JObject (required)
  var path_773238 = newJObject()
  var body_773239 = newJObject()
  add(path_773238, "networkId", newJString(networkId))
  if body != nil:
    body_773239 = body
  result = call_773237.call(path_773238, nil, nil, nil, body_773239)

var createMember* = Call_CreateMember_773224(name: "createMember",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/members", validator: validate_CreateMember_773225,
    base: "/", url: url_CreateMember_773226, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_772933 = ref object of OpenApiRestCall_772597
proc url_ListMembers_772935(protocol: Scheme; host: string; base: string;
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

proc validate_ListMembers_772934(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773061 = path.getOrDefault("networkId")
  valid_773061 = validateParameter(valid_773061, JString, required = true,
                                 default = nil)
  if valid_773061 != nil:
    section.add "networkId", valid_773061
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
  var valid_773062 = query.getOrDefault("NextToken")
  valid_773062 = validateParameter(valid_773062, JString, required = false,
                                 default = nil)
  if valid_773062 != nil:
    section.add "NextToken", valid_773062
  var valid_773063 = query.getOrDefault("maxResults")
  valid_773063 = validateParameter(valid_773063, JInt, required = false, default = nil)
  if valid_773063 != nil:
    section.add "maxResults", valid_773063
  var valid_773064 = query.getOrDefault("nextToken")
  valid_773064 = validateParameter(valid_773064, JString, required = false,
                                 default = nil)
  if valid_773064 != nil:
    section.add "nextToken", valid_773064
  var valid_773065 = query.getOrDefault("name")
  valid_773065 = validateParameter(valid_773065, JString, required = false,
                                 default = nil)
  if valid_773065 != nil:
    section.add "name", valid_773065
  var valid_773066 = query.getOrDefault("isOwned")
  valid_773066 = validateParameter(valid_773066, JBool, required = false, default = nil)
  if valid_773066 != nil:
    section.add "isOwned", valid_773066
  var valid_773080 = query.getOrDefault("status")
  valid_773080 = validateParameter(valid_773080, JString, required = false,
                                 default = newJString("CREATING"))
  if valid_773080 != nil:
    section.add "status", valid_773080
  var valid_773081 = query.getOrDefault("MaxResults")
  valid_773081 = validateParameter(valid_773081, JString, required = false,
                                 default = nil)
  if valid_773081 != nil:
    section.add "MaxResults", valid_773081
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
  var valid_773082 = header.getOrDefault("X-Amz-Date")
  valid_773082 = validateParameter(valid_773082, JString, required = false,
                                 default = nil)
  if valid_773082 != nil:
    section.add "X-Amz-Date", valid_773082
  var valid_773083 = header.getOrDefault("X-Amz-Security-Token")
  valid_773083 = validateParameter(valid_773083, JString, required = false,
                                 default = nil)
  if valid_773083 != nil:
    section.add "X-Amz-Security-Token", valid_773083
  var valid_773084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773084 = validateParameter(valid_773084, JString, required = false,
                                 default = nil)
  if valid_773084 != nil:
    section.add "X-Amz-Content-Sha256", valid_773084
  var valid_773085 = header.getOrDefault("X-Amz-Algorithm")
  valid_773085 = validateParameter(valid_773085, JString, required = false,
                                 default = nil)
  if valid_773085 != nil:
    section.add "X-Amz-Algorithm", valid_773085
  var valid_773086 = header.getOrDefault("X-Amz-Signature")
  valid_773086 = validateParameter(valid_773086, JString, required = false,
                                 default = nil)
  if valid_773086 != nil:
    section.add "X-Amz-Signature", valid_773086
  var valid_773087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773087 = validateParameter(valid_773087, JString, required = false,
                                 default = nil)
  if valid_773087 != nil:
    section.add "X-Amz-SignedHeaders", valid_773087
  var valid_773088 = header.getOrDefault("X-Amz-Credential")
  valid_773088 = validateParameter(valid_773088, JString, required = false,
                                 default = nil)
  if valid_773088 != nil:
    section.add "X-Amz-Credential", valid_773088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773111: Call_ListMembers_772933; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a listing of the members in a network and properties of their configurations.
  ## 
  let valid = call_773111.validator(path, query, header, formData, body)
  let scheme = call_773111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773111.url(scheme.get, call_773111.host, call_773111.base,
                         call_773111.route, valid.getOrDefault("path"))
  result = hook(call_773111, url, valid)

proc call*(call_773182: Call_ListMembers_772933; networkId: string;
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
  var path_773183 = newJObject()
  var query_773185 = newJObject()
  add(path_773183, "networkId", newJString(networkId))
  add(query_773185, "NextToken", newJString(NextToken))
  add(query_773185, "maxResults", newJInt(maxResults))
  add(query_773185, "nextToken", newJString(nextToken))
  add(query_773185, "name", newJString(name))
  add(query_773185, "isOwned", newJBool(isOwned))
  add(query_773185, "status", newJString(status))
  add(query_773185, "MaxResults", newJString(MaxResults))
  result = call_773182.call(path_773183, query_773185, nil, nil, nil)

var listMembers* = Call_ListMembers_772933(name: "listMembers",
                                        meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
                                        route: "/networks/{networkId}/members",
                                        validator: validate_ListMembers_772934,
                                        base: "/", url: url_ListMembers_772935,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNetwork_773260 = ref object of OpenApiRestCall_772597
proc url_CreateNetwork_773262(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateNetwork_773261(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773263 = header.getOrDefault("X-Amz-Date")
  valid_773263 = validateParameter(valid_773263, JString, required = false,
                                 default = nil)
  if valid_773263 != nil:
    section.add "X-Amz-Date", valid_773263
  var valid_773264 = header.getOrDefault("X-Amz-Security-Token")
  valid_773264 = validateParameter(valid_773264, JString, required = false,
                                 default = nil)
  if valid_773264 != nil:
    section.add "X-Amz-Security-Token", valid_773264
  var valid_773265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "X-Amz-Content-Sha256", valid_773265
  var valid_773266 = header.getOrDefault("X-Amz-Algorithm")
  valid_773266 = validateParameter(valid_773266, JString, required = false,
                                 default = nil)
  if valid_773266 != nil:
    section.add "X-Amz-Algorithm", valid_773266
  var valid_773267 = header.getOrDefault("X-Amz-Signature")
  valid_773267 = validateParameter(valid_773267, JString, required = false,
                                 default = nil)
  if valid_773267 != nil:
    section.add "X-Amz-Signature", valid_773267
  var valid_773268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-SignedHeaders", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-Credential")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Credential", valid_773269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773271: Call_CreateNetwork_773260; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new blockchain network using Amazon Managed Blockchain.
  ## 
  let valid = call_773271.validator(path, query, header, formData, body)
  let scheme = call_773271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773271.url(scheme.get, call_773271.host, call_773271.base,
                         call_773271.route, valid.getOrDefault("path"))
  result = hook(call_773271, url, valid)

proc call*(call_773272: Call_CreateNetwork_773260; body: JsonNode): Recallable =
  ## createNetwork
  ## Creates a new blockchain network using Amazon Managed Blockchain.
  ##   body: JObject (required)
  var body_773273 = newJObject()
  if body != nil:
    body_773273 = body
  result = call_773272.call(nil, nil, nil, nil, body_773273)

var createNetwork* = Call_CreateNetwork_773260(name: "createNetwork",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks", validator: validate_CreateNetwork_773261, base: "/",
    url: url_CreateNetwork_773262, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNetworks_773240 = ref object of OpenApiRestCall_772597
proc url_ListNetworks_773242(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListNetworks_773241(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773243 = query.getOrDefault("framework")
  valid_773243 = validateParameter(valid_773243, JString, required = false,
                                 default = newJString("HYPERLEDGER_FABRIC"))
  if valid_773243 != nil:
    section.add "framework", valid_773243
  var valid_773244 = query.getOrDefault("NextToken")
  valid_773244 = validateParameter(valid_773244, JString, required = false,
                                 default = nil)
  if valid_773244 != nil:
    section.add "NextToken", valid_773244
  var valid_773245 = query.getOrDefault("maxResults")
  valid_773245 = validateParameter(valid_773245, JInt, required = false, default = nil)
  if valid_773245 != nil:
    section.add "maxResults", valid_773245
  var valid_773246 = query.getOrDefault("nextToken")
  valid_773246 = validateParameter(valid_773246, JString, required = false,
                                 default = nil)
  if valid_773246 != nil:
    section.add "nextToken", valid_773246
  var valid_773247 = query.getOrDefault("name")
  valid_773247 = validateParameter(valid_773247, JString, required = false,
                                 default = nil)
  if valid_773247 != nil:
    section.add "name", valid_773247
  var valid_773248 = query.getOrDefault("status")
  valid_773248 = validateParameter(valid_773248, JString, required = false,
                                 default = newJString("CREATING"))
  if valid_773248 != nil:
    section.add "status", valid_773248
  var valid_773249 = query.getOrDefault("MaxResults")
  valid_773249 = validateParameter(valid_773249, JString, required = false,
                                 default = nil)
  if valid_773249 != nil:
    section.add "MaxResults", valid_773249
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
  var valid_773250 = header.getOrDefault("X-Amz-Date")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "X-Amz-Date", valid_773250
  var valid_773251 = header.getOrDefault("X-Amz-Security-Token")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "X-Amz-Security-Token", valid_773251
  var valid_773252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773252 = validateParameter(valid_773252, JString, required = false,
                                 default = nil)
  if valid_773252 != nil:
    section.add "X-Amz-Content-Sha256", valid_773252
  var valid_773253 = header.getOrDefault("X-Amz-Algorithm")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-Algorithm", valid_773253
  var valid_773254 = header.getOrDefault("X-Amz-Signature")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-Signature", valid_773254
  var valid_773255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "X-Amz-SignedHeaders", valid_773255
  var valid_773256 = header.getOrDefault("X-Amz-Credential")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-Credential", valid_773256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773257: Call_ListNetworks_773240; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the networks in which the current AWS account has members.
  ## 
  let valid = call_773257.validator(path, query, header, formData, body)
  let scheme = call_773257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773257.url(scheme.get, call_773257.host, call_773257.base,
                         call_773257.route, valid.getOrDefault("path"))
  result = hook(call_773257, url, valid)

proc call*(call_773258: Call_ListNetworks_773240;
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
  var query_773259 = newJObject()
  add(query_773259, "framework", newJString(framework))
  add(query_773259, "NextToken", newJString(NextToken))
  add(query_773259, "maxResults", newJInt(maxResults))
  add(query_773259, "nextToken", newJString(nextToken))
  add(query_773259, "name", newJString(name))
  add(query_773259, "status", newJString(status))
  add(query_773259, "MaxResults", newJString(MaxResults))
  result = call_773258.call(nil, query_773259, nil, nil, nil)

var listNetworks* = Call_ListNetworks_773240(name: "listNetworks",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks", validator: validate_ListNetworks_773241, base: "/",
    url: url_ListNetworks_773242, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNode_773295 = ref object of OpenApiRestCall_772597
proc url_CreateNode_773297(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateNode_773296(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773298 = path.getOrDefault("networkId")
  valid_773298 = validateParameter(valid_773298, JString, required = true,
                                 default = nil)
  if valid_773298 != nil:
    section.add "networkId", valid_773298
  var valid_773299 = path.getOrDefault("memberId")
  valid_773299 = validateParameter(valid_773299, JString, required = true,
                                 default = nil)
  if valid_773299 != nil:
    section.add "memberId", valid_773299
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
  var valid_773300 = header.getOrDefault("X-Amz-Date")
  valid_773300 = validateParameter(valid_773300, JString, required = false,
                                 default = nil)
  if valid_773300 != nil:
    section.add "X-Amz-Date", valid_773300
  var valid_773301 = header.getOrDefault("X-Amz-Security-Token")
  valid_773301 = validateParameter(valid_773301, JString, required = false,
                                 default = nil)
  if valid_773301 != nil:
    section.add "X-Amz-Security-Token", valid_773301
  var valid_773302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773302 = validateParameter(valid_773302, JString, required = false,
                                 default = nil)
  if valid_773302 != nil:
    section.add "X-Amz-Content-Sha256", valid_773302
  var valid_773303 = header.getOrDefault("X-Amz-Algorithm")
  valid_773303 = validateParameter(valid_773303, JString, required = false,
                                 default = nil)
  if valid_773303 != nil:
    section.add "X-Amz-Algorithm", valid_773303
  var valid_773304 = header.getOrDefault("X-Amz-Signature")
  valid_773304 = validateParameter(valid_773304, JString, required = false,
                                 default = nil)
  if valid_773304 != nil:
    section.add "X-Amz-Signature", valid_773304
  var valid_773305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773305 = validateParameter(valid_773305, JString, required = false,
                                 default = nil)
  if valid_773305 != nil:
    section.add "X-Amz-SignedHeaders", valid_773305
  var valid_773306 = header.getOrDefault("X-Amz-Credential")
  valid_773306 = validateParameter(valid_773306, JString, required = false,
                                 default = nil)
  if valid_773306 != nil:
    section.add "X-Amz-Credential", valid_773306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773308: Call_CreateNode_773295; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a peer node in a member.
  ## 
  let valid = call_773308.validator(path, query, header, formData, body)
  let scheme = call_773308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773308.url(scheme.get, call_773308.host, call_773308.base,
                         call_773308.route, valid.getOrDefault("path"))
  result = hook(call_773308, url, valid)

proc call*(call_773309: Call_CreateNode_773295; networkId: string; memberId: string;
          body: JsonNode): Recallable =
  ## createNode
  ## Creates a peer node in a member.
  ##   networkId: string (required)
  ##            : The unique identifier of the network in which this node runs.
  ##   memberId: string (required)
  ##           : The unique identifier of the member that owns this node.
  ##   body: JObject (required)
  var path_773310 = newJObject()
  var body_773311 = newJObject()
  add(path_773310, "networkId", newJString(networkId))
  add(path_773310, "memberId", newJString(memberId))
  if body != nil:
    body_773311 = body
  result = call_773309.call(path_773310, nil, nil, nil, body_773311)

var createNode* = Call_CreateNode_773295(name: "createNode",
                                      meth: HttpMethod.HttpPost,
                                      host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes",
                                      validator: validate_CreateNode_773296,
                                      base: "/", url: url_CreateNode_773297,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNodes_773274 = ref object of OpenApiRestCall_772597
proc url_ListNodes_773276(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListNodes_773275(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773277 = path.getOrDefault("networkId")
  valid_773277 = validateParameter(valid_773277, JString, required = true,
                                 default = nil)
  if valid_773277 != nil:
    section.add "networkId", valid_773277
  var valid_773278 = path.getOrDefault("memberId")
  valid_773278 = validateParameter(valid_773278, JString, required = true,
                                 default = nil)
  if valid_773278 != nil:
    section.add "memberId", valid_773278
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
  var valid_773279 = query.getOrDefault("NextToken")
  valid_773279 = validateParameter(valid_773279, JString, required = false,
                                 default = nil)
  if valid_773279 != nil:
    section.add "NextToken", valid_773279
  var valid_773280 = query.getOrDefault("maxResults")
  valid_773280 = validateParameter(valid_773280, JInt, required = false, default = nil)
  if valid_773280 != nil:
    section.add "maxResults", valid_773280
  var valid_773281 = query.getOrDefault("nextToken")
  valid_773281 = validateParameter(valid_773281, JString, required = false,
                                 default = nil)
  if valid_773281 != nil:
    section.add "nextToken", valid_773281
  var valid_773282 = query.getOrDefault("status")
  valid_773282 = validateParameter(valid_773282, JString, required = false,
                                 default = newJString("CREATING"))
  if valid_773282 != nil:
    section.add "status", valid_773282
  var valid_773283 = query.getOrDefault("MaxResults")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "MaxResults", valid_773283
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
  var valid_773284 = header.getOrDefault("X-Amz-Date")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "X-Amz-Date", valid_773284
  var valid_773285 = header.getOrDefault("X-Amz-Security-Token")
  valid_773285 = validateParameter(valid_773285, JString, required = false,
                                 default = nil)
  if valid_773285 != nil:
    section.add "X-Amz-Security-Token", valid_773285
  var valid_773286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "X-Amz-Content-Sha256", valid_773286
  var valid_773287 = header.getOrDefault("X-Amz-Algorithm")
  valid_773287 = validateParameter(valid_773287, JString, required = false,
                                 default = nil)
  if valid_773287 != nil:
    section.add "X-Amz-Algorithm", valid_773287
  var valid_773288 = header.getOrDefault("X-Amz-Signature")
  valid_773288 = validateParameter(valid_773288, JString, required = false,
                                 default = nil)
  if valid_773288 != nil:
    section.add "X-Amz-Signature", valid_773288
  var valid_773289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773289 = validateParameter(valid_773289, JString, required = false,
                                 default = nil)
  if valid_773289 != nil:
    section.add "X-Amz-SignedHeaders", valid_773289
  var valid_773290 = header.getOrDefault("X-Amz-Credential")
  valid_773290 = validateParameter(valid_773290, JString, required = false,
                                 default = nil)
  if valid_773290 != nil:
    section.add "X-Amz-Credential", valid_773290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773291: Call_ListNodes_773274; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the nodes within a network.
  ## 
  let valid = call_773291.validator(path, query, header, formData, body)
  let scheme = call_773291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773291.url(scheme.get, call_773291.host, call_773291.base,
                         call_773291.route, valid.getOrDefault("path"))
  result = hook(call_773291, url, valid)

proc call*(call_773292: Call_ListNodes_773274; networkId: string; memberId: string;
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
  var path_773293 = newJObject()
  var query_773294 = newJObject()
  add(path_773293, "networkId", newJString(networkId))
  add(path_773293, "memberId", newJString(memberId))
  add(query_773294, "NextToken", newJString(NextToken))
  add(query_773294, "maxResults", newJInt(maxResults))
  add(query_773294, "nextToken", newJString(nextToken))
  add(query_773294, "status", newJString(status))
  add(query_773294, "MaxResults", newJString(MaxResults))
  result = call_773292.call(path_773293, query_773294, nil, nil, nil)

var listNodes* = Call_ListNodes_773274(name: "listNodes", meth: HttpMethod.HttpGet,
                                    host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes",
                                    validator: validate_ListNodes_773275,
                                    base: "/", url: url_ListNodes_773276,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProposal_773331 = ref object of OpenApiRestCall_772597
proc url_CreateProposal_773333(protocol: Scheme; host: string; base: string;
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

proc validate_CreateProposal_773332(path: JsonNode; query: JsonNode;
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
  var valid_773334 = path.getOrDefault("networkId")
  valid_773334 = validateParameter(valid_773334, JString, required = true,
                                 default = nil)
  if valid_773334 != nil:
    section.add "networkId", valid_773334
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
  var valid_773335 = header.getOrDefault("X-Amz-Date")
  valid_773335 = validateParameter(valid_773335, JString, required = false,
                                 default = nil)
  if valid_773335 != nil:
    section.add "X-Amz-Date", valid_773335
  var valid_773336 = header.getOrDefault("X-Amz-Security-Token")
  valid_773336 = validateParameter(valid_773336, JString, required = false,
                                 default = nil)
  if valid_773336 != nil:
    section.add "X-Amz-Security-Token", valid_773336
  var valid_773337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773337 = validateParameter(valid_773337, JString, required = false,
                                 default = nil)
  if valid_773337 != nil:
    section.add "X-Amz-Content-Sha256", valid_773337
  var valid_773338 = header.getOrDefault("X-Amz-Algorithm")
  valid_773338 = validateParameter(valid_773338, JString, required = false,
                                 default = nil)
  if valid_773338 != nil:
    section.add "X-Amz-Algorithm", valid_773338
  var valid_773339 = header.getOrDefault("X-Amz-Signature")
  valid_773339 = validateParameter(valid_773339, JString, required = false,
                                 default = nil)
  if valid_773339 != nil:
    section.add "X-Amz-Signature", valid_773339
  var valid_773340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773340 = validateParameter(valid_773340, JString, required = false,
                                 default = nil)
  if valid_773340 != nil:
    section.add "X-Amz-SignedHeaders", valid_773340
  var valid_773341 = header.getOrDefault("X-Amz-Credential")
  valid_773341 = validateParameter(valid_773341, JString, required = false,
                                 default = nil)
  if valid_773341 != nil:
    section.add "X-Amz-Credential", valid_773341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773343: Call_CreateProposal_773331; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a proposal for a change to the network that other members of the network can vote on, for example, a proposal to add a new member to the network. Any member can create a proposal.
  ## 
  let valid = call_773343.validator(path, query, header, formData, body)
  let scheme = call_773343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773343.url(scheme.get, call_773343.host, call_773343.base,
                         call_773343.route, valid.getOrDefault("path"))
  result = hook(call_773343, url, valid)

proc call*(call_773344: Call_CreateProposal_773331; networkId: string; body: JsonNode): Recallable =
  ## createProposal
  ## Creates a proposal for a change to the network that other members of the network can vote on, for example, a proposal to add a new member to the network. Any member can create a proposal.
  ##   networkId: string (required)
  ##            :  The unique identifier of the network for which the proposal is made.
  ##   body: JObject (required)
  var path_773345 = newJObject()
  var body_773346 = newJObject()
  add(path_773345, "networkId", newJString(networkId))
  if body != nil:
    body_773346 = body
  result = call_773344.call(path_773345, nil, nil, nil, body_773346)

var createProposal* = Call_CreateProposal_773331(name: "createProposal",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals", validator: validate_CreateProposal_773332,
    base: "/", url: url_CreateProposal_773333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProposals_773312 = ref object of OpenApiRestCall_772597
proc url_ListProposals_773314(protocol: Scheme; host: string; base: string;
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

proc validate_ListProposals_773313(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773315 = path.getOrDefault("networkId")
  valid_773315 = validateParameter(valid_773315, JString, required = true,
                                 default = nil)
  if valid_773315 != nil:
    section.add "networkId", valid_773315
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
  var valid_773316 = query.getOrDefault("NextToken")
  valid_773316 = validateParameter(valid_773316, JString, required = false,
                                 default = nil)
  if valid_773316 != nil:
    section.add "NextToken", valid_773316
  var valid_773317 = query.getOrDefault("maxResults")
  valid_773317 = validateParameter(valid_773317, JInt, required = false, default = nil)
  if valid_773317 != nil:
    section.add "maxResults", valid_773317
  var valid_773318 = query.getOrDefault("nextToken")
  valid_773318 = validateParameter(valid_773318, JString, required = false,
                                 default = nil)
  if valid_773318 != nil:
    section.add "nextToken", valid_773318
  var valid_773319 = query.getOrDefault("MaxResults")
  valid_773319 = validateParameter(valid_773319, JString, required = false,
                                 default = nil)
  if valid_773319 != nil:
    section.add "MaxResults", valid_773319
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
  var valid_773320 = header.getOrDefault("X-Amz-Date")
  valid_773320 = validateParameter(valid_773320, JString, required = false,
                                 default = nil)
  if valid_773320 != nil:
    section.add "X-Amz-Date", valid_773320
  var valid_773321 = header.getOrDefault("X-Amz-Security-Token")
  valid_773321 = validateParameter(valid_773321, JString, required = false,
                                 default = nil)
  if valid_773321 != nil:
    section.add "X-Amz-Security-Token", valid_773321
  var valid_773322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773322 = validateParameter(valid_773322, JString, required = false,
                                 default = nil)
  if valid_773322 != nil:
    section.add "X-Amz-Content-Sha256", valid_773322
  var valid_773323 = header.getOrDefault("X-Amz-Algorithm")
  valid_773323 = validateParameter(valid_773323, JString, required = false,
                                 default = nil)
  if valid_773323 != nil:
    section.add "X-Amz-Algorithm", valid_773323
  var valid_773324 = header.getOrDefault("X-Amz-Signature")
  valid_773324 = validateParameter(valid_773324, JString, required = false,
                                 default = nil)
  if valid_773324 != nil:
    section.add "X-Amz-Signature", valid_773324
  var valid_773325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773325 = validateParameter(valid_773325, JString, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "X-Amz-SignedHeaders", valid_773325
  var valid_773326 = header.getOrDefault("X-Amz-Credential")
  valid_773326 = validateParameter(valid_773326, JString, required = false,
                                 default = nil)
  if valid_773326 != nil:
    section.add "X-Amz-Credential", valid_773326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773327: Call_ListProposals_773312; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a listing of proposals for the network.
  ## 
  let valid = call_773327.validator(path, query, header, formData, body)
  let scheme = call_773327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773327.url(scheme.get, call_773327.host, call_773327.base,
                         call_773327.route, valid.getOrDefault("path"))
  result = hook(call_773327, url, valid)

proc call*(call_773328: Call_ListProposals_773312; networkId: string;
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
  var path_773329 = newJObject()
  var query_773330 = newJObject()
  add(path_773329, "networkId", newJString(networkId))
  add(query_773330, "NextToken", newJString(NextToken))
  add(query_773330, "maxResults", newJInt(maxResults))
  add(query_773330, "nextToken", newJString(nextToken))
  add(query_773330, "MaxResults", newJString(MaxResults))
  result = call_773328.call(path_773329, query_773330, nil, nil, nil)

var listProposals* = Call_ListProposals_773312(name: "listProposals",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals", validator: validate_ListProposals_773313,
    base: "/", url: url_ListProposals_773314, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMember_773347 = ref object of OpenApiRestCall_772597
proc url_GetMember_773349(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetMember_773348(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773350 = path.getOrDefault("networkId")
  valid_773350 = validateParameter(valid_773350, JString, required = true,
                                 default = nil)
  if valid_773350 != nil:
    section.add "networkId", valid_773350
  var valid_773351 = path.getOrDefault("memberId")
  valid_773351 = validateParameter(valid_773351, JString, required = true,
                                 default = nil)
  if valid_773351 != nil:
    section.add "memberId", valid_773351
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
  var valid_773352 = header.getOrDefault("X-Amz-Date")
  valid_773352 = validateParameter(valid_773352, JString, required = false,
                                 default = nil)
  if valid_773352 != nil:
    section.add "X-Amz-Date", valid_773352
  var valid_773353 = header.getOrDefault("X-Amz-Security-Token")
  valid_773353 = validateParameter(valid_773353, JString, required = false,
                                 default = nil)
  if valid_773353 != nil:
    section.add "X-Amz-Security-Token", valid_773353
  var valid_773354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773354 = validateParameter(valid_773354, JString, required = false,
                                 default = nil)
  if valid_773354 != nil:
    section.add "X-Amz-Content-Sha256", valid_773354
  var valid_773355 = header.getOrDefault("X-Amz-Algorithm")
  valid_773355 = validateParameter(valid_773355, JString, required = false,
                                 default = nil)
  if valid_773355 != nil:
    section.add "X-Amz-Algorithm", valid_773355
  var valid_773356 = header.getOrDefault("X-Amz-Signature")
  valid_773356 = validateParameter(valid_773356, JString, required = false,
                                 default = nil)
  if valid_773356 != nil:
    section.add "X-Amz-Signature", valid_773356
  var valid_773357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773357 = validateParameter(valid_773357, JString, required = false,
                                 default = nil)
  if valid_773357 != nil:
    section.add "X-Amz-SignedHeaders", valid_773357
  var valid_773358 = header.getOrDefault("X-Amz-Credential")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "X-Amz-Credential", valid_773358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773359: Call_GetMember_773347; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a member.
  ## 
  let valid = call_773359.validator(path, query, header, formData, body)
  let scheme = call_773359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773359.url(scheme.get, call_773359.host, call_773359.base,
                         call_773359.route, valid.getOrDefault("path"))
  result = hook(call_773359, url, valid)

proc call*(call_773360: Call_GetMember_773347; networkId: string; memberId: string): Recallable =
  ## getMember
  ## Returns detailed information about a member.
  ##   networkId: string (required)
  ##            : The unique identifier of the network to which the member belongs.
  ##   memberId: string (required)
  ##           : The unique identifier of the member.
  var path_773361 = newJObject()
  add(path_773361, "networkId", newJString(networkId))
  add(path_773361, "memberId", newJString(memberId))
  result = call_773360.call(path_773361, nil, nil, nil, nil)

var getMember* = Call_GetMember_773347(name: "getMember", meth: HttpMethod.HttpGet,
                                    host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}",
                                    validator: validate_GetMember_773348,
                                    base: "/", url: url_GetMember_773349,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMember_773362 = ref object of OpenApiRestCall_772597
proc url_DeleteMember_773364(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMember_773363(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773365 = path.getOrDefault("networkId")
  valid_773365 = validateParameter(valid_773365, JString, required = true,
                                 default = nil)
  if valid_773365 != nil:
    section.add "networkId", valid_773365
  var valid_773366 = path.getOrDefault("memberId")
  valid_773366 = validateParameter(valid_773366, JString, required = true,
                                 default = nil)
  if valid_773366 != nil:
    section.add "memberId", valid_773366
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
  var valid_773367 = header.getOrDefault("X-Amz-Date")
  valid_773367 = validateParameter(valid_773367, JString, required = false,
                                 default = nil)
  if valid_773367 != nil:
    section.add "X-Amz-Date", valid_773367
  var valid_773368 = header.getOrDefault("X-Amz-Security-Token")
  valid_773368 = validateParameter(valid_773368, JString, required = false,
                                 default = nil)
  if valid_773368 != nil:
    section.add "X-Amz-Security-Token", valid_773368
  var valid_773369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773369 = validateParameter(valid_773369, JString, required = false,
                                 default = nil)
  if valid_773369 != nil:
    section.add "X-Amz-Content-Sha256", valid_773369
  var valid_773370 = header.getOrDefault("X-Amz-Algorithm")
  valid_773370 = validateParameter(valid_773370, JString, required = false,
                                 default = nil)
  if valid_773370 != nil:
    section.add "X-Amz-Algorithm", valid_773370
  var valid_773371 = header.getOrDefault("X-Amz-Signature")
  valid_773371 = validateParameter(valid_773371, JString, required = false,
                                 default = nil)
  if valid_773371 != nil:
    section.add "X-Amz-Signature", valid_773371
  var valid_773372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773372 = validateParameter(valid_773372, JString, required = false,
                                 default = nil)
  if valid_773372 != nil:
    section.add "X-Amz-SignedHeaders", valid_773372
  var valid_773373 = header.getOrDefault("X-Amz-Credential")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "X-Amz-Credential", valid_773373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773374: Call_DeleteMember_773362; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a member. Deleting a member removes the member and all associated resources from the network. <code>DeleteMember</code> can only be called for a specified <code>MemberId</code> if the principal performing the action is associated with the AWS account that owns the member. In all other cases, the <code>DeleteMember</code> action is carried out as the result of an approved proposal to remove a member. If <code>MemberId</code> is the last member in a network specified by the last AWS account, the network is deleted also.
  ## 
  let valid = call_773374.validator(path, query, header, formData, body)
  let scheme = call_773374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773374.url(scheme.get, call_773374.host, call_773374.base,
                         call_773374.route, valid.getOrDefault("path"))
  result = hook(call_773374, url, valid)

proc call*(call_773375: Call_DeleteMember_773362; networkId: string; memberId: string): Recallable =
  ## deleteMember
  ## Deletes a member. Deleting a member removes the member and all associated resources from the network. <code>DeleteMember</code> can only be called for a specified <code>MemberId</code> if the principal performing the action is associated with the AWS account that owns the member. In all other cases, the <code>DeleteMember</code> action is carried out as the result of an approved proposal to remove a member. If <code>MemberId</code> is the last member in a network specified by the last AWS account, the network is deleted also.
  ##   networkId: string (required)
  ##            : The unique identifier of the network from which the member is removed.
  ##   memberId: string (required)
  ##           : The unique identifier of the member to remove.
  var path_773376 = newJObject()
  add(path_773376, "networkId", newJString(networkId))
  add(path_773376, "memberId", newJString(memberId))
  result = call_773375.call(path_773376, nil, nil, nil, nil)

var deleteMember* = Call_DeleteMember_773362(name: "deleteMember",
    meth: HttpMethod.HttpDelete, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/members/{memberId}",
    validator: validate_DeleteMember_773363, base: "/", url: url_DeleteMember_773364,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNode_773377 = ref object of OpenApiRestCall_772597
proc url_GetNode_773379(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetNode_773378(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773380 = path.getOrDefault("networkId")
  valid_773380 = validateParameter(valid_773380, JString, required = true,
                                 default = nil)
  if valid_773380 != nil:
    section.add "networkId", valid_773380
  var valid_773381 = path.getOrDefault("memberId")
  valid_773381 = validateParameter(valid_773381, JString, required = true,
                                 default = nil)
  if valid_773381 != nil:
    section.add "memberId", valid_773381
  var valid_773382 = path.getOrDefault("nodeId")
  valid_773382 = validateParameter(valid_773382, JString, required = true,
                                 default = nil)
  if valid_773382 != nil:
    section.add "nodeId", valid_773382
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
  var valid_773383 = header.getOrDefault("X-Amz-Date")
  valid_773383 = validateParameter(valid_773383, JString, required = false,
                                 default = nil)
  if valid_773383 != nil:
    section.add "X-Amz-Date", valid_773383
  var valid_773384 = header.getOrDefault("X-Amz-Security-Token")
  valid_773384 = validateParameter(valid_773384, JString, required = false,
                                 default = nil)
  if valid_773384 != nil:
    section.add "X-Amz-Security-Token", valid_773384
  var valid_773385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773385 = validateParameter(valid_773385, JString, required = false,
                                 default = nil)
  if valid_773385 != nil:
    section.add "X-Amz-Content-Sha256", valid_773385
  var valid_773386 = header.getOrDefault("X-Amz-Algorithm")
  valid_773386 = validateParameter(valid_773386, JString, required = false,
                                 default = nil)
  if valid_773386 != nil:
    section.add "X-Amz-Algorithm", valid_773386
  var valid_773387 = header.getOrDefault("X-Amz-Signature")
  valid_773387 = validateParameter(valid_773387, JString, required = false,
                                 default = nil)
  if valid_773387 != nil:
    section.add "X-Amz-Signature", valid_773387
  var valid_773388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773388 = validateParameter(valid_773388, JString, required = false,
                                 default = nil)
  if valid_773388 != nil:
    section.add "X-Amz-SignedHeaders", valid_773388
  var valid_773389 = header.getOrDefault("X-Amz-Credential")
  valid_773389 = validateParameter(valid_773389, JString, required = false,
                                 default = nil)
  if valid_773389 != nil:
    section.add "X-Amz-Credential", valid_773389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773390: Call_GetNode_773377; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a peer node.
  ## 
  let valid = call_773390.validator(path, query, header, formData, body)
  let scheme = call_773390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773390.url(scheme.get, call_773390.host, call_773390.base,
                         call_773390.route, valid.getOrDefault("path"))
  result = hook(call_773390, url, valid)

proc call*(call_773391: Call_GetNode_773377; networkId: string; memberId: string;
          nodeId: string): Recallable =
  ## getNode
  ## Returns detailed information about a peer node.
  ##   networkId: string (required)
  ##            : The unique identifier of the network to which the node belongs.
  ##   memberId: string (required)
  ##           : The unique identifier of the member that owns the node.
  ##   nodeId: string (required)
  ##         : The unique identifier of the node.
  var path_773392 = newJObject()
  add(path_773392, "networkId", newJString(networkId))
  add(path_773392, "memberId", newJString(memberId))
  add(path_773392, "nodeId", newJString(nodeId))
  result = call_773391.call(path_773392, nil, nil, nil, nil)

var getNode* = Call_GetNode_773377(name: "getNode", meth: HttpMethod.HttpGet,
                                host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes/{nodeId}",
                                validator: validate_GetNode_773378, base: "/",
                                url: url_GetNode_773379,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNode_773393 = ref object of OpenApiRestCall_772597
proc url_DeleteNode_773395(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteNode_773394(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773396 = path.getOrDefault("networkId")
  valid_773396 = validateParameter(valid_773396, JString, required = true,
                                 default = nil)
  if valid_773396 != nil:
    section.add "networkId", valid_773396
  var valid_773397 = path.getOrDefault("memberId")
  valid_773397 = validateParameter(valid_773397, JString, required = true,
                                 default = nil)
  if valid_773397 != nil:
    section.add "memberId", valid_773397
  var valid_773398 = path.getOrDefault("nodeId")
  valid_773398 = validateParameter(valid_773398, JString, required = true,
                                 default = nil)
  if valid_773398 != nil:
    section.add "nodeId", valid_773398
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
  var valid_773399 = header.getOrDefault("X-Amz-Date")
  valid_773399 = validateParameter(valid_773399, JString, required = false,
                                 default = nil)
  if valid_773399 != nil:
    section.add "X-Amz-Date", valid_773399
  var valid_773400 = header.getOrDefault("X-Amz-Security-Token")
  valid_773400 = validateParameter(valid_773400, JString, required = false,
                                 default = nil)
  if valid_773400 != nil:
    section.add "X-Amz-Security-Token", valid_773400
  var valid_773401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773401 = validateParameter(valid_773401, JString, required = false,
                                 default = nil)
  if valid_773401 != nil:
    section.add "X-Amz-Content-Sha256", valid_773401
  var valid_773402 = header.getOrDefault("X-Amz-Algorithm")
  valid_773402 = validateParameter(valid_773402, JString, required = false,
                                 default = nil)
  if valid_773402 != nil:
    section.add "X-Amz-Algorithm", valid_773402
  var valid_773403 = header.getOrDefault("X-Amz-Signature")
  valid_773403 = validateParameter(valid_773403, JString, required = false,
                                 default = nil)
  if valid_773403 != nil:
    section.add "X-Amz-Signature", valid_773403
  var valid_773404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773404 = validateParameter(valid_773404, JString, required = false,
                                 default = nil)
  if valid_773404 != nil:
    section.add "X-Amz-SignedHeaders", valid_773404
  var valid_773405 = header.getOrDefault("X-Amz-Credential")
  valid_773405 = validateParameter(valid_773405, JString, required = false,
                                 default = nil)
  if valid_773405 != nil:
    section.add "X-Amz-Credential", valid_773405
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773406: Call_DeleteNode_773393; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a peer node from a member that your AWS account owns. All data on the node is lost and cannot be recovered.
  ## 
  let valid = call_773406.validator(path, query, header, formData, body)
  let scheme = call_773406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773406.url(scheme.get, call_773406.host, call_773406.base,
                         call_773406.route, valid.getOrDefault("path"))
  result = hook(call_773406, url, valid)

proc call*(call_773407: Call_DeleteNode_773393; networkId: string; memberId: string;
          nodeId: string): Recallable =
  ## deleteNode
  ## Deletes a peer node from a member that your AWS account owns. All data on the node is lost and cannot be recovered.
  ##   networkId: string (required)
  ##            : The unique identifier of the network that the node belongs to.
  ##   memberId: string (required)
  ##           : The unique identifier of the member that owns this node.
  ##   nodeId: string (required)
  ##         : The unique identifier of the node.
  var path_773408 = newJObject()
  add(path_773408, "networkId", newJString(networkId))
  add(path_773408, "memberId", newJString(memberId))
  add(path_773408, "nodeId", newJString(nodeId))
  result = call_773407.call(path_773408, nil, nil, nil, nil)

var deleteNode* = Call_DeleteNode_773393(name: "deleteNode",
                                      meth: HttpMethod.HttpDelete,
                                      host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes/{nodeId}",
                                      validator: validate_DeleteNode_773394,
                                      base: "/", url: url_DeleteNode_773395,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNetwork_773409 = ref object of OpenApiRestCall_772597
proc url_GetNetwork_773411(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetNetwork_773410(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773412 = path.getOrDefault("networkId")
  valid_773412 = validateParameter(valid_773412, JString, required = true,
                                 default = nil)
  if valid_773412 != nil:
    section.add "networkId", valid_773412
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
  var valid_773413 = header.getOrDefault("X-Amz-Date")
  valid_773413 = validateParameter(valid_773413, JString, required = false,
                                 default = nil)
  if valid_773413 != nil:
    section.add "X-Amz-Date", valid_773413
  var valid_773414 = header.getOrDefault("X-Amz-Security-Token")
  valid_773414 = validateParameter(valid_773414, JString, required = false,
                                 default = nil)
  if valid_773414 != nil:
    section.add "X-Amz-Security-Token", valid_773414
  var valid_773415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773415 = validateParameter(valid_773415, JString, required = false,
                                 default = nil)
  if valid_773415 != nil:
    section.add "X-Amz-Content-Sha256", valid_773415
  var valid_773416 = header.getOrDefault("X-Amz-Algorithm")
  valid_773416 = validateParameter(valid_773416, JString, required = false,
                                 default = nil)
  if valid_773416 != nil:
    section.add "X-Amz-Algorithm", valid_773416
  var valid_773417 = header.getOrDefault("X-Amz-Signature")
  valid_773417 = validateParameter(valid_773417, JString, required = false,
                                 default = nil)
  if valid_773417 != nil:
    section.add "X-Amz-Signature", valid_773417
  var valid_773418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773418 = validateParameter(valid_773418, JString, required = false,
                                 default = nil)
  if valid_773418 != nil:
    section.add "X-Amz-SignedHeaders", valid_773418
  var valid_773419 = header.getOrDefault("X-Amz-Credential")
  valid_773419 = validateParameter(valid_773419, JString, required = false,
                                 default = nil)
  if valid_773419 != nil:
    section.add "X-Amz-Credential", valid_773419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773420: Call_GetNetwork_773409; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a network.
  ## 
  let valid = call_773420.validator(path, query, header, formData, body)
  let scheme = call_773420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773420.url(scheme.get, call_773420.host, call_773420.base,
                         call_773420.route, valid.getOrDefault("path"))
  result = hook(call_773420, url, valid)

proc call*(call_773421: Call_GetNetwork_773409; networkId: string): Recallable =
  ## getNetwork
  ## Returns detailed information about a network.
  ##   networkId: string (required)
  ##            : The unique identifier of the network to get information about.
  var path_773422 = newJObject()
  add(path_773422, "networkId", newJString(networkId))
  result = call_773421.call(path_773422, nil, nil, nil, nil)

var getNetwork* = Call_GetNetwork_773409(name: "getNetwork",
                                      meth: HttpMethod.HttpGet,
                                      host: "managedblockchain.amazonaws.com",
                                      route: "/networks/{networkId}",
                                      validator: validate_GetNetwork_773410,
                                      base: "/", url: url_GetNetwork_773411,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProposal_773423 = ref object of OpenApiRestCall_772597
proc url_GetProposal_773425(protocol: Scheme; host: string; base: string;
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

proc validate_GetProposal_773424(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773426 = path.getOrDefault("networkId")
  valid_773426 = validateParameter(valid_773426, JString, required = true,
                                 default = nil)
  if valid_773426 != nil:
    section.add "networkId", valid_773426
  var valid_773427 = path.getOrDefault("proposalId")
  valid_773427 = validateParameter(valid_773427, JString, required = true,
                                 default = nil)
  if valid_773427 != nil:
    section.add "proposalId", valid_773427
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
  var valid_773428 = header.getOrDefault("X-Amz-Date")
  valid_773428 = validateParameter(valid_773428, JString, required = false,
                                 default = nil)
  if valid_773428 != nil:
    section.add "X-Amz-Date", valid_773428
  var valid_773429 = header.getOrDefault("X-Amz-Security-Token")
  valid_773429 = validateParameter(valid_773429, JString, required = false,
                                 default = nil)
  if valid_773429 != nil:
    section.add "X-Amz-Security-Token", valid_773429
  var valid_773430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773430 = validateParameter(valid_773430, JString, required = false,
                                 default = nil)
  if valid_773430 != nil:
    section.add "X-Amz-Content-Sha256", valid_773430
  var valid_773431 = header.getOrDefault("X-Amz-Algorithm")
  valid_773431 = validateParameter(valid_773431, JString, required = false,
                                 default = nil)
  if valid_773431 != nil:
    section.add "X-Amz-Algorithm", valid_773431
  var valid_773432 = header.getOrDefault("X-Amz-Signature")
  valid_773432 = validateParameter(valid_773432, JString, required = false,
                                 default = nil)
  if valid_773432 != nil:
    section.add "X-Amz-Signature", valid_773432
  var valid_773433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773433 = validateParameter(valid_773433, JString, required = false,
                                 default = nil)
  if valid_773433 != nil:
    section.add "X-Amz-SignedHeaders", valid_773433
  var valid_773434 = header.getOrDefault("X-Amz-Credential")
  valid_773434 = validateParameter(valid_773434, JString, required = false,
                                 default = nil)
  if valid_773434 != nil:
    section.add "X-Amz-Credential", valid_773434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773435: Call_GetProposal_773423; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about a proposal.
  ## 
  let valid = call_773435.validator(path, query, header, formData, body)
  let scheme = call_773435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773435.url(scheme.get, call_773435.host, call_773435.base,
                         call_773435.route, valid.getOrDefault("path"))
  result = hook(call_773435, url, valid)

proc call*(call_773436: Call_GetProposal_773423; networkId: string;
          proposalId: string): Recallable =
  ## getProposal
  ## Returns detailed information about a proposal.
  ##   networkId: string (required)
  ##            : The unique identifier of the network for which the proposal is made.
  ##   proposalId: string (required)
  ##             : The unique identifier of the proposal.
  var path_773437 = newJObject()
  add(path_773437, "networkId", newJString(networkId))
  add(path_773437, "proposalId", newJString(proposalId))
  result = call_773436.call(path_773437, nil, nil, nil, nil)

var getProposal* = Call_GetProposal_773423(name: "getProposal",
                                        meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/proposals/{proposalId}",
                                        validator: validate_GetProposal_773424,
                                        base: "/", url: url_GetProposal_773425,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_773438 = ref object of OpenApiRestCall_772597
proc url_ListInvitations_773440(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListInvitations_773439(path: JsonNode; query: JsonNode;
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
  var valid_773441 = query.getOrDefault("NextToken")
  valid_773441 = validateParameter(valid_773441, JString, required = false,
                                 default = nil)
  if valid_773441 != nil:
    section.add "NextToken", valid_773441
  var valid_773442 = query.getOrDefault("maxResults")
  valid_773442 = validateParameter(valid_773442, JInt, required = false, default = nil)
  if valid_773442 != nil:
    section.add "maxResults", valid_773442
  var valid_773443 = query.getOrDefault("nextToken")
  valid_773443 = validateParameter(valid_773443, JString, required = false,
                                 default = nil)
  if valid_773443 != nil:
    section.add "nextToken", valid_773443
  var valid_773444 = query.getOrDefault("MaxResults")
  valid_773444 = validateParameter(valid_773444, JString, required = false,
                                 default = nil)
  if valid_773444 != nil:
    section.add "MaxResults", valid_773444
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
  var valid_773445 = header.getOrDefault("X-Amz-Date")
  valid_773445 = validateParameter(valid_773445, JString, required = false,
                                 default = nil)
  if valid_773445 != nil:
    section.add "X-Amz-Date", valid_773445
  var valid_773446 = header.getOrDefault("X-Amz-Security-Token")
  valid_773446 = validateParameter(valid_773446, JString, required = false,
                                 default = nil)
  if valid_773446 != nil:
    section.add "X-Amz-Security-Token", valid_773446
  var valid_773447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773447 = validateParameter(valid_773447, JString, required = false,
                                 default = nil)
  if valid_773447 != nil:
    section.add "X-Amz-Content-Sha256", valid_773447
  var valid_773448 = header.getOrDefault("X-Amz-Algorithm")
  valid_773448 = validateParameter(valid_773448, JString, required = false,
                                 default = nil)
  if valid_773448 != nil:
    section.add "X-Amz-Algorithm", valid_773448
  var valid_773449 = header.getOrDefault("X-Amz-Signature")
  valid_773449 = validateParameter(valid_773449, JString, required = false,
                                 default = nil)
  if valid_773449 != nil:
    section.add "X-Amz-Signature", valid_773449
  var valid_773450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773450 = validateParameter(valid_773450, JString, required = false,
                                 default = nil)
  if valid_773450 != nil:
    section.add "X-Amz-SignedHeaders", valid_773450
  var valid_773451 = header.getOrDefault("X-Amz-Credential")
  valid_773451 = validateParameter(valid_773451, JString, required = false,
                                 default = nil)
  if valid_773451 != nil:
    section.add "X-Amz-Credential", valid_773451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773452: Call_ListInvitations_773438; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a listing of all invitations made on the specified network.
  ## 
  let valid = call_773452.validator(path, query, header, formData, body)
  let scheme = call_773452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773452.url(scheme.get, call_773452.host, call_773452.base,
                         call_773452.route, valid.getOrDefault("path"))
  result = hook(call_773452, url, valid)

proc call*(call_773453: Call_ListInvitations_773438; NextToken: string = "";
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
  var query_773454 = newJObject()
  add(query_773454, "NextToken", newJString(NextToken))
  add(query_773454, "maxResults", newJInt(maxResults))
  add(query_773454, "nextToken", newJString(nextToken))
  add(query_773454, "MaxResults", newJString(MaxResults))
  result = call_773453.call(nil, query_773454, nil, nil, nil)

var listInvitations* = Call_ListInvitations_773438(name: "listInvitations",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/invitations", validator: validate_ListInvitations_773439, base: "/",
    url: url_ListInvitations_773440, schemes: {Scheme.Https, Scheme.Http})
type
  Call_VoteOnProposal_773475 = ref object of OpenApiRestCall_772597
proc url_VoteOnProposal_773477(protocol: Scheme; host: string; base: string;
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

proc validate_VoteOnProposal_773476(path: JsonNode; query: JsonNode;
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
  var valid_773478 = path.getOrDefault("networkId")
  valid_773478 = validateParameter(valid_773478, JString, required = true,
                                 default = nil)
  if valid_773478 != nil:
    section.add "networkId", valid_773478
  var valid_773479 = path.getOrDefault("proposalId")
  valid_773479 = validateParameter(valid_773479, JString, required = true,
                                 default = nil)
  if valid_773479 != nil:
    section.add "proposalId", valid_773479
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
  var valid_773480 = header.getOrDefault("X-Amz-Date")
  valid_773480 = validateParameter(valid_773480, JString, required = false,
                                 default = nil)
  if valid_773480 != nil:
    section.add "X-Amz-Date", valid_773480
  var valid_773481 = header.getOrDefault("X-Amz-Security-Token")
  valid_773481 = validateParameter(valid_773481, JString, required = false,
                                 default = nil)
  if valid_773481 != nil:
    section.add "X-Amz-Security-Token", valid_773481
  var valid_773482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773482 = validateParameter(valid_773482, JString, required = false,
                                 default = nil)
  if valid_773482 != nil:
    section.add "X-Amz-Content-Sha256", valid_773482
  var valid_773483 = header.getOrDefault("X-Amz-Algorithm")
  valid_773483 = validateParameter(valid_773483, JString, required = false,
                                 default = nil)
  if valid_773483 != nil:
    section.add "X-Amz-Algorithm", valid_773483
  var valid_773484 = header.getOrDefault("X-Amz-Signature")
  valid_773484 = validateParameter(valid_773484, JString, required = false,
                                 default = nil)
  if valid_773484 != nil:
    section.add "X-Amz-Signature", valid_773484
  var valid_773485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773485 = validateParameter(valid_773485, JString, required = false,
                                 default = nil)
  if valid_773485 != nil:
    section.add "X-Amz-SignedHeaders", valid_773485
  var valid_773486 = header.getOrDefault("X-Amz-Credential")
  valid_773486 = validateParameter(valid_773486, JString, required = false,
                                 default = nil)
  if valid_773486 != nil:
    section.add "X-Amz-Credential", valid_773486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773488: Call_VoteOnProposal_773475; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Casts a vote for a specified <code>ProposalId</code> on behalf of a member. The member to vote as, specified by <code>VoterMemberId</code>, must be in the same AWS account as the principal that calls the action.
  ## 
  let valid = call_773488.validator(path, query, header, formData, body)
  let scheme = call_773488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773488.url(scheme.get, call_773488.host, call_773488.base,
                         call_773488.route, valid.getOrDefault("path"))
  result = hook(call_773488, url, valid)

proc call*(call_773489: Call_VoteOnProposal_773475; networkId: string;
          proposalId: string; body: JsonNode): Recallable =
  ## voteOnProposal
  ## Casts a vote for a specified <code>ProposalId</code> on behalf of a member. The member to vote as, specified by <code>VoterMemberId</code>, must be in the same AWS account as the principal that calls the action.
  ##   networkId: string (required)
  ##            :  The unique identifier of the network. 
  ##   proposalId: string (required)
  ##             :  The unique identifier of the proposal. 
  ##   body: JObject (required)
  var path_773490 = newJObject()
  var body_773491 = newJObject()
  add(path_773490, "networkId", newJString(networkId))
  add(path_773490, "proposalId", newJString(proposalId))
  if body != nil:
    body_773491 = body
  result = call_773489.call(path_773490, nil, nil, nil, body_773491)

var voteOnProposal* = Call_VoteOnProposal_773475(name: "voteOnProposal",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals/{proposalId}/votes",
    validator: validate_VoteOnProposal_773476, base: "/", url: url_VoteOnProposal_773477,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProposalVotes_773455 = ref object of OpenApiRestCall_772597
proc url_ListProposalVotes_773457(protocol: Scheme; host: string; base: string;
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

proc validate_ListProposalVotes_773456(path: JsonNode; query: JsonNode;
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
  var valid_773458 = path.getOrDefault("networkId")
  valid_773458 = validateParameter(valid_773458, JString, required = true,
                                 default = nil)
  if valid_773458 != nil:
    section.add "networkId", valid_773458
  var valid_773459 = path.getOrDefault("proposalId")
  valid_773459 = validateParameter(valid_773459, JString, required = true,
                                 default = nil)
  if valid_773459 != nil:
    section.add "proposalId", valid_773459
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
  var valid_773460 = query.getOrDefault("NextToken")
  valid_773460 = validateParameter(valid_773460, JString, required = false,
                                 default = nil)
  if valid_773460 != nil:
    section.add "NextToken", valid_773460
  var valid_773461 = query.getOrDefault("maxResults")
  valid_773461 = validateParameter(valid_773461, JInt, required = false, default = nil)
  if valid_773461 != nil:
    section.add "maxResults", valid_773461
  var valid_773462 = query.getOrDefault("nextToken")
  valid_773462 = validateParameter(valid_773462, JString, required = false,
                                 default = nil)
  if valid_773462 != nil:
    section.add "nextToken", valid_773462
  var valid_773463 = query.getOrDefault("MaxResults")
  valid_773463 = validateParameter(valid_773463, JString, required = false,
                                 default = nil)
  if valid_773463 != nil:
    section.add "MaxResults", valid_773463
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
  var valid_773464 = header.getOrDefault("X-Amz-Date")
  valid_773464 = validateParameter(valid_773464, JString, required = false,
                                 default = nil)
  if valid_773464 != nil:
    section.add "X-Amz-Date", valid_773464
  var valid_773465 = header.getOrDefault("X-Amz-Security-Token")
  valid_773465 = validateParameter(valid_773465, JString, required = false,
                                 default = nil)
  if valid_773465 != nil:
    section.add "X-Amz-Security-Token", valid_773465
  var valid_773466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773466 = validateParameter(valid_773466, JString, required = false,
                                 default = nil)
  if valid_773466 != nil:
    section.add "X-Amz-Content-Sha256", valid_773466
  var valid_773467 = header.getOrDefault("X-Amz-Algorithm")
  valid_773467 = validateParameter(valid_773467, JString, required = false,
                                 default = nil)
  if valid_773467 != nil:
    section.add "X-Amz-Algorithm", valid_773467
  var valid_773468 = header.getOrDefault("X-Amz-Signature")
  valid_773468 = validateParameter(valid_773468, JString, required = false,
                                 default = nil)
  if valid_773468 != nil:
    section.add "X-Amz-Signature", valid_773468
  var valid_773469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773469 = validateParameter(valid_773469, JString, required = false,
                                 default = nil)
  if valid_773469 != nil:
    section.add "X-Amz-SignedHeaders", valid_773469
  var valid_773470 = header.getOrDefault("X-Amz-Credential")
  valid_773470 = validateParameter(valid_773470, JString, required = false,
                                 default = nil)
  if valid_773470 != nil:
    section.add "X-Amz-Credential", valid_773470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773471: Call_ListProposalVotes_773455; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the listing of votes for a specified proposal, including the value of each vote and the unique identifier of the member that cast the vote.
  ## 
  let valid = call_773471.validator(path, query, header, formData, body)
  let scheme = call_773471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773471.url(scheme.get, call_773471.host, call_773471.base,
                         call_773471.route, valid.getOrDefault("path"))
  result = hook(call_773471, url, valid)

proc call*(call_773472: Call_ListProposalVotes_773455; networkId: string;
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
  var path_773473 = newJObject()
  var query_773474 = newJObject()
  add(path_773473, "networkId", newJString(networkId))
  add(path_773473, "proposalId", newJString(proposalId))
  add(query_773474, "NextToken", newJString(NextToken))
  add(query_773474, "maxResults", newJInt(maxResults))
  add(query_773474, "nextToken", newJString(nextToken))
  add(query_773474, "MaxResults", newJString(MaxResults))
  result = call_773472.call(path_773473, query_773474, nil, nil, nil)

var listProposalVotes* = Call_ListProposalVotes_773455(name: "listProposalVotes",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals/{proposalId}/votes",
    validator: validate_ListProposalVotes_773456, base: "/",
    url: url_ListProposalVotes_773457, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectInvitation_773492 = ref object of OpenApiRestCall_772597
proc url_RejectInvitation_773494(protocol: Scheme; host: string; base: string;
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

proc validate_RejectInvitation_773493(path: JsonNode; query: JsonNode;
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
  var valid_773495 = path.getOrDefault("invitationId")
  valid_773495 = validateParameter(valid_773495, JString, required = true,
                                 default = nil)
  if valid_773495 != nil:
    section.add "invitationId", valid_773495
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
  var valid_773496 = header.getOrDefault("X-Amz-Date")
  valid_773496 = validateParameter(valid_773496, JString, required = false,
                                 default = nil)
  if valid_773496 != nil:
    section.add "X-Amz-Date", valid_773496
  var valid_773497 = header.getOrDefault("X-Amz-Security-Token")
  valid_773497 = validateParameter(valid_773497, JString, required = false,
                                 default = nil)
  if valid_773497 != nil:
    section.add "X-Amz-Security-Token", valid_773497
  var valid_773498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773498 = validateParameter(valid_773498, JString, required = false,
                                 default = nil)
  if valid_773498 != nil:
    section.add "X-Amz-Content-Sha256", valid_773498
  var valid_773499 = header.getOrDefault("X-Amz-Algorithm")
  valid_773499 = validateParameter(valid_773499, JString, required = false,
                                 default = nil)
  if valid_773499 != nil:
    section.add "X-Amz-Algorithm", valid_773499
  var valid_773500 = header.getOrDefault("X-Amz-Signature")
  valid_773500 = validateParameter(valid_773500, JString, required = false,
                                 default = nil)
  if valid_773500 != nil:
    section.add "X-Amz-Signature", valid_773500
  var valid_773501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773501 = validateParameter(valid_773501, JString, required = false,
                                 default = nil)
  if valid_773501 != nil:
    section.add "X-Amz-SignedHeaders", valid_773501
  var valid_773502 = header.getOrDefault("X-Amz-Credential")
  valid_773502 = validateParameter(valid_773502, JString, required = false,
                                 default = nil)
  if valid_773502 != nil:
    section.add "X-Amz-Credential", valid_773502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773503: Call_RejectInvitation_773492; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Rejects an invitation to join a network. This action can be called by a principal in an AWS account that has received an invitation to create a member and join a network.
  ## 
  let valid = call_773503.validator(path, query, header, formData, body)
  let scheme = call_773503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773503.url(scheme.get, call_773503.host, call_773503.base,
                         call_773503.route, valid.getOrDefault("path"))
  result = hook(call_773503, url, valid)

proc call*(call_773504: Call_RejectInvitation_773492; invitationId: string): Recallable =
  ## rejectInvitation
  ## Rejects an invitation to join a network. This action can be called by a principal in an AWS account that has received an invitation to create a member and join a network.
  ##   invitationId: string (required)
  ##               : The unique identifier of the invitation to reject.
  var path_773505 = newJObject()
  add(path_773505, "invitationId", newJString(invitationId))
  result = call_773504.call(path_773505, nil, nil, nil, nil)

var rejectInvitation* = Call_RejectInvitation_773492(name: "rejectInvitation",
    meth: HttpMethod.HttpDelete, host: "managedblockchain.amazonaws.com",
    route: "/invitations/{invitationId}", validator: validate_RejectInvitation_773493,
    base: "/", url: url_RejectInvitation_773494,
    schemes: {Scheme.Https, Scheme.Http})
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
