
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  Scheme* {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                             header: JsonNode = nil; formData: JsonNode = nil;
                             body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
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
    if required:
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "managedblockchain.ap-northeast-1.amazonaws.com", "ap-southeast-1": "managedblockchain.ap-southeast-1.amazonaws.com", "us-west-2": "managedblockchain.us-west-2.amazonaws.com", "eu-west-2": "managedblockchain.eu-west-2.amazonaws.com", "ap-northeast-3": "managedblockchain.ap-northeast-3.amazonaws.com", "eu-central-1": "managedblockchain.eu-central-1.amazonaws.com", "us-east-2": "managedblockchain.us-east-2.amazonaws.com", "us-east-1": "managedblockchain.us-east-1.amazonaws.com", "cn-northwest-1": "managedblockchain.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "managedblockchain.ap-south-1.amazonaws.com", "eu-north-1": "managedblockchain.eu-north-1.amazonaws.com", "ap-northeast-2": "managedblockchain.ap-northeast-2.amazonaws.com", "us-west-1": "managedblockchain.us-west-1.amazonaws.com", "us-gov-east-1": "managedblockchain.us-gov-east-1.amazonaws.com", "eu-west-3": "managedblockchain.eu-west-3.amazonaws.com", "cn-north-1": "managedblockchain.cn-north-1.amazonaws.com.cn", "sa-east-1": "managedblockchain.sa-east-1.amazonaws.com", "eu-west-1": "managedblockchain.eu-west-1.amazonaws.com", "us-gov-west-1": "managedblockchain.us-gov-west-1.amazonaws.com", "ap-southeast-2": "managedblockchain.ap-southeast-2.amazonaws.com", "ca-central-1": "managedblockchain.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateMember_402656507 = ref object of OpenApiRestCall_402656044
proc url_CreateMember_402656509(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMember_402656508(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a member within a Managed Blockchain network.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   networkId: JString (required)
                                 ##            : The unique identifier of the network in which the member is created.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `networkId` field"
  var valid_402656510 = path.getOrDefault("networkId")
  valid_402656510 = validateParameter(valid_402656510, JString, required = true,
                                      default = nil)
  if valid_402656510 != nil:
    section.add "networkId", valid_402656510
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656511 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Security-Token", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Signature")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Signature", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-Algorithm", valid_402656514
  var valid_402656515 = header.getOrDefault("X-Amz-Date")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "X-Amz-Date", valid_402656515
  var valid_402656516 = header.getOrDefault("X-Amz-Credential")
  valid_402656516 = validateParameter(valid_402656516, JString,
                                      required = false, default = nil)
  if valid_402656516 != nil:
    section.add "X-Amz-Credential", valid_402656516
  var valid_402656517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656517 = validateParameter(valid_402656517, JString,
                                      required = false, default = nil)
  if valid_402656517 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656519: Call_CreateMember_402656507; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a member within a Managed Blockchain network.
                                                                                         ## 
  let valid = call_402656519.validator(path, query, header, formData, body, _)
  let scheme = call_402656519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656519.makeUrl(scheme.get, call_402656519.host, call_402656519.base,
                                   call_402656519.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656519, uri, valid, _)

proc call*(call_402656520: Call_CreateMember_402656507; networkId: string;
           body: JsonNode): Recallable =
  ## createMember
  ## Creates a member within a Managed Blockchain network.
  ##   networkId: string (required)
                                                          ##            : The unique identifier of the network in which the member is created.
  ##   
                                                                                                                                              ## body: JObject (required)
  var path_402656521 = newJObject()
  var body_402656522 = newJObject()
  add(path_402656521, "networkId", newJString(networkId))
  if body != nil:
    body_402656522 = body
  result = call_402656520.call(path_402656521, nil, nil, nil, body_402656522)

var createMember* = Call_CreateMember_402656507(name: "createMember",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/members", validator: validate_CreateMember_402656508,
    base: "/", makeUrl: url_CreateMember_402656509,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_402656294 = ref object of OpenApiRestCall_402656044
proc url_ListMembers_402656296(protocol: Scheme; host: string; base: string;
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

proc validate_ListMembers_402656295(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a listing of the members in a network and properties of their configurations.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   networkId: JString (required)
                                 ##            : The unique identifier of the network for which to list members.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `networkId` field"
  var valid_402656389 = path.getOrDefault("networkId")
  valid_402656389 = validateParameter(valid_402656389, JString, required = true,
                                      default = nil)
  if valid_402656389 != nil:
    section.add "networkId", valid_402656389
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of members to return in the request.
  ##   
                                                                                                          ## status: JString
                                                                                                          ##         
                                                                                                          ## : 
                                                                                                          ## An 
                                                                                                          ## optional 
                                                                                                          ## status 
                                                                                                          ## specifier. 
                                                                                                          ## If 
                                                                                                          ## provided, 
                                                                                                          ## only 
                                                                                                          ## members 
                                                                                                          ## currently 
                                                                                                          ## in 
                                                                                                          ## this 
                                                                                                          ## status 
                                                                                                          ## are 
                                                                                                          ## listed.
  ##   
                                                                                                                    ## isOwned: JBool
                                                                                                                    ##          
                                                                                                                    ## : 
                                                                                                                    ## An 
                                                                                                                    ## optional 
                                                                                                                    ## Boolean 
                                                                                                                    ## value. 
                                                                                                                    ## If 
                                                                                                                    ## provided, 
                                                                                                                    ## the 
                                                                                                                    ## request 
                                                                                                                    ## is 
                                                                                                                    ## limited 
                                                                                                                    ## either 
                                                                                                                    ## to 
                                                                                                                    ## members 
                                                                                                                    ## that 
                                                                                                                    ## the 
                                                                                                                    ## current 
                                                                                                                    ## AWS 
                                                                                                                    ## account 
                                                                                                                    ## owns 
                                                                                                                    ## (<code>true</code>) 
                                                                                                                    ## or 
                                                                                                                    ## that 
                                                                                                                    ## other 
                                                                                                                    ## AWS 
                                                                                                                    ## accounts 
                                                                                                                    ## own 
                                                                                                                    ## (<code>false</code>). 
                                                                                                                    ## If 
                                                                                                                    ## omitted, 
                                                                                                                    ## all 
                                                                                                                    ## members 
                                                                                                                    ## are 
                                                                                                                    ## listed.
  ##   
                                                                                                                              ## nextToken: JString
                                                                                                                              ##            
                                                                                                                              ## : 
                                                                                                                              ## The 
                                                                                                                              ## pagination 
                                                                                                                              ## token 
                                                                                                                              ## that 
                                                                                                                              ## indicates 
                                                                                                                              ## the 
                                                                                                                              ## next 
                                                                                                                              ## set 
                                                                                                                              ## of 
                                                                                                                              ## results 
                                                                                                                              ## to 
                                                                                                                              ## retrieve.
  ##   
                                                                                                                                          ## MaxResults: JString
                                                                                                                                          ##             
                                                                                                                                          ## : 
                                                                                                                                          ## Pagination 
                                                                                                                                          ## limit
  ##   
                                                                                                                                                  ## name: JString
                                                                                                                                                  ##       
                                                                                                                                                  ## : 
                                                                                                                                                  ## The 
                                                                                                                                                  ## optional 
                                                                                                                                                  ## name 
                                                                                                                                                  ## of 
                                                                                                                                                  ## the 
                                                                                                                                                  ## member 
                                                                                                                                                  ## to 
                                                                                                                                                  ## list.
  ##   
                                                                                                                                                          ## NextToken: JString
                                                                                                                                                          ##            
                                                                                                                                                          ## : 
                                                                                                                                                          ## Pagination 
                                                                                                                                                          ## token
  section = newJObject()
  var valid_402656390 = query.getOrDefault("maxResults")
  valid_402656390 = validateParameter(valid_402656390, JInt, required = false,
                                      default = nil)
  if valid_402656390 != nil:
    section.add "maxResults", valid_402656390
  var valid_402656403 = query.getOrDefault("status")
  valid_402656403 = validateParameter(valid_402656403, JString,
                                      required = false,
                                      default = newJString("CREATING"))
  if valid_402656403 != nil:
    section.add "status", valid_402656403
  var valid_402656404 = query.getOrDefault("isOwned")
  valid_402656404 = validateParameter(valid_402656404, JBool, required = false,
                                      default = nil)
  if valid_402656404 != nil:
    section.add "isOwned", valid_402656404
  var valid_402656405 = query.getOrDefault("nextToken")
  valid_402656405 = validateParameter(valid_402656405, JString,
                                      required = false, default = nil)
  if valid_402656405 != nil:
    section.add "nextToken", valid_402656405
  var valid_402656406 = query.getOrDefault("MaxResults")
  valid_402656406 = validateParameter(valid_402656406, JString,
                                      required = false, default = nil)
  if valid_402656406 != nil:
    section.add "MaxResults", valid_402656406
  var valid_402656407 = query.getOrDefault("name")
  valid_402656407 = validateParameter(valid_402656407, JString,
                                      required = false, default = nil)
  if valid_402656407 != nil:
    section.add "name", valid_402656407
  var valid_402656408 = query.getOrDefault("NextToken")
  valid_402656408 = validateParameter(valid_402656408, JString,
                                      required = false, default = nil)
  if valid_402656408 != nil:
    section.add "NextToken", valid_402656408
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656409 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656409 = validateParameter(valid_402656409, JString,
                                      required = false, default = nil)
  if valid_402656409 != nil:
    section.add "X-Amz-Security-Token", valid_402656409
  var valid_402656410 = header.getOrDefault("X-Amz-Signature")
  valid_402656410 = validateParameter(valid_402656410, JString,
                                      required = false, default = nil)
  if valid_402656410 != nil:
    section.add "X-Amz-Signature", valid_402656410
  var valid_402656411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656411 = validateParameter(valid_402656411, JString,
                                      required = false, default = nil)
  if valid_402656411 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656411
  var valid_402656412 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656412 = validateParameter(valid_402656412, JString,
                                      required = false, default = nil)
  if valid_402656412 != nil:
    section.add "X-Amz-Algorithm", valid_402656412
  var valid_402656413 = header.getOrDefault("X-Amz-Date")
  valid_402656413 = validateParameter(valid_402656413, JString,
                                      required = false, default = nil)
  if valid_402656413 != nil:
    section.add "X-Amz-Date", valid_402656413
  var valid_402656414 = header.getOrDefault("X-Amz-Credential")
  valid_402656414 = validateParameter(valid_402656414, JString,
                                      required = false, default = nil)
  if valid_402656414 != nil:
    section.add "X-Amz-Credential", valid_402656414
  var valid_402656415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656415 = validateParameter(valid_402656415, JString,
                                      required = false, default = nil)
  if valid_402656415 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656415
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656429: Call_ListMembers_402656294; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a listing of the members in a network and properties of their configurations.
                                                                                         ## 
  let valid = call_402656429.validator(path, query, header, formData, body, _)
  let scheme = call_402656429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656429.makeUrl(scheme.get, call_402656429.host, call_402656429.base,
                                   call_402656429.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656429, uri, valid, _)

proc call*(call_402656478: Call_ListMembers_402656294; networkId: string;
           maxResults: int = 0; status: string = "CREATING";
           isOwned: bool = false; nextToken: string = "";
           MaxResults: string = ""; name: string = ""; NextToken: string = ""): Recallable =
  ## listMembers
  ## Returns a listing of the members in a network and properties of their configurations.
  ##   
                                                                                          ## maxResults: int
                                                                                          ##             
                                                                                          ## : 
                                                                                          ## The 
                                                                                          ## maximum 
                                                                                          ## number 
                                                                                          ## of 
                                                                                          ## members 
                                                                                          ## to 
                                                                                          ## return 
                                                                                          ## in 
                                                                                          ## the 
                                                                                          ## request.
  ##   
                                                                                                     ## networkId: string (required)
                                                                                                     ##            
                                                                                                     ## : 
                                                                                                     ## The 
                                                                                                     ## unique 
                                                                                                     ## identifier 
                                                                                                     ## of 
                                                                                                     ## the 
                                                                                                     ## network 
                                                                                                     ## for 
                                                                                                     ## which 
                                                                                                     ## to 
                                                                                                     ## list 
                                                                                                     ## members.
  ##   
                                                                                                                ## status: string
                                                                                                                ##         
                                                                                                                ## : 
                                                                                                                ## An 
                                                                                                                ## optional 
                                                                                                                ## status 
                                                                                                                ## specifier. 
                                                                                                                ## If 
                                                                                                                ## provided, 
                                                                                                                ## only 
                                                                                                                ## members 
                                                                                                                ## currently 
                                                                                                                ## in 
                                                                                                                ## this 
                                                                                                                ## status 
                                                                                                                ## are 
                                                                                                                ## listed.
  ##   
                                                                                                                          ## isOwned: bool
                                                                                                                          ##          
                                                                                                                          ## : 
                                                                                                                          ## An 
                                                                                                                          ## optional 
                                                                                                                          ## Boolean 
                                                                                                                          ## value. 
                                                                                                                          ## If 
                                                                                                                          ## provided, 
                                                                                                                          ## the 
                                                                                                                          ## request 
                                                                                                                          ## is 
                                                                                                                          ## limited 
                                                                                                                          ## either 
                                                                                                                          ## to 
                                                                                                                          ## members 
                                                                                                                          ## that 
                                                                                                                          ## the 
                                                                                                                          ## current 
                                                                                                                          ## AWS 
                                                                                                                          ## account 
                                                                                                                          ## owns 
                                                                                                                          ## (<code>true</code>) 
                                                                                                                          ## or 
                                                                                                                          ## that 
                                                                                                                          ## other 
                                                                                                                          ## AWS 
                                                                                                                          ## accounts 
                                                                                                                          ## own 
                                                                                                                          ## (<code>false</code>). 
                                                                                                                          ## If 
                                                                                                                          ## omitted, 
                                                                                                                          ## all 
                                                                                                                          ## members 
                                                                                                                          ## are 
                                                                                                                          ## listed.
  ##   
                                                                                                                                    ## nextToken: string
                                                                                                                                    ##            
                                                                                                                                    ## : 
                                                                                                                                    ## The 
                                                                                                                                    ## pagination 
                                                                                                                                    ## token 
                                                                                                                                    ## that 
                                                                                                                                    ## indicates 
                                                                                                                                    ## the 
                                                                                                                                    ## next 
                                                                                                                                    ## set 
                                                                                                                                    ## of 
                                                                                                                                    ## results 
                                                                                                                                    ## to 
                                                                                                                                    ## retrieve.
  ##   
                                                                                                                                                ## MaxResults: string
                                                                                                                                                ##             
                                                                                                                                                ## : 
                                                                                                                                                ## Pagination 
                                                                                                                                                ## limit
  ##   
                                                                                                                                                        ## name: string
                                                                                                                                                        ##       
                                                                                                                                                        ## : 
                                                                                                                                                        ## The 
                                                                                                                                                        ## optional 
                                                                                                                                                        ## name 
                                                                                                                                                        ## of 
                                                                                                                                                        ## the 
                                                                                                                                                        ## member 
                                                                                                                                                        ## to 
                                                                                                                                                        ## list.
  ##   
                                                                                                                                                                ## NextToken: string
                                                                                                                                                                ##            
                                                                                                                                                                ## : 
                                                                                                                                                                ## Pagination 
                                                                                                                                                                ## token
  var path_402656479 = newJObject()
  var query_402656481 = newJObject()
  add(query_402656481, "maxResults", newJInt(maxResults))
  add(path_402656479, "networkId", newJString(networkId))
  add(query_402656481, "status", newJString(status))
  add(query_402656481, "isOwned", newJBool(isOwned))
  add(query_402656481, "nextToken", newJString(nextToken))
  add(query_402656481, "MaxResults", newJString(MaxResults))
  add(query_402656481, "name", newJString(name))
  add(query_402656481, "NextToken", newJString(NextToken))
  result = call_402656478.call(path_402656479, query_402656481, nil, nil, nil)

var listMembers* = Call_ListMembers_402656294(name: "listMembers",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/members", validator: validate_ListMembers_402656295,
    base: "/", makeUrl: url_ListMembers_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNetwork_402656543 = ref object of OpenApiRestCall_402656044
proc url_CreateNetwork_402656545(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateNetwork_402656544(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new blockchain network using Amazon Managed Blockchain.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656546 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-Security-Token", valid_402656546
  var valid_402656547 = header.getOrDefault("X-Amz-Signature")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-Signature", valid_402656547
  var valid_402656548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656548 = validateParameter(valid_402656548, JString,
                                      required = false, default = nil)
  if valid_402656548 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656548
  var valid_402656549 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-Algorithm", valid_402656549
  var valid_402656550 = header.getOrDefault("X-Amz-Date")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "X-Amz-Date", valid_402656550
  var valid_402656551 = header.getOrDefault("X-Amz-Credential")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "X-Amz-Credential", valid_402656551
  var valid_402656552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656554: Call_CreateNetwork_402656543; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new blockchain network using Amazon Managed Blockchain.
                                                                                         ## 
  let valid = call_402656554.validator(path, query, header, formData, body, _)
  let scheme = call_402656554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656554.makeUrl(scheme.get, call_402656554.host, call_402656554.base,
                                   call_402656554.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656554, uri, valid, _)

proc call*(call_402656555: Call_CreateNetwork_402656543; body: JsonNode): Recallable =
  ## createNetwork
  ## Creates a new blockchain network using Amazon Managed Blockchain.
  ##   body: JObject (required)
  var body_402656556 = newJObject()
  if body != nil:
    body_402656556 = body
  result = call_402656555.call(nil, nil, nil, nil, body_402656556)

var createNetwork* = Call_CreateNetwork_402656543(name: "createNetwork",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks", validator: validate_CreateNetwork_402656544, base: "/",
    makeUrl: url_CreateNetwork_402656545, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNetworks_402656523 = ref object of OpenApiRestCall_402656044
proc url_ListNetworks_402656525(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListNetworks_402656524(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about the networks in which the current AWS account has members.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   framework: JString
                                  ##            : An optional framework specifier. If provided, only networks of this framework type are listed.
  ##   
                                                                                                                                                ## maxResults: JInt
                                                                                                                                                ##             
                                                                                                                                                ## : 
                                                                                                                                                ## The 
                                                                                                                                                ## maximum 
                                                                                                                                                ## number 
                                                                                                                                                ## of 
                                                                                                                                                ## networks 
                                                                                                                                                ## to 
                                                                                                                                                ## list.
  ##   
                                                                                                                                                        ## status: JString
                                                                                                                                                        ##         
                                                                                                                                                        ## : 
                                                                                                                                                        ## An 
                                                                                                                                                        ## optional 
                                                                                                                                                        ## status 
                                                                                                                                                        ## specifier. 
                                                                                                                                                        ## If 
                                                                                                                                                        ## provided, 
                                                                                                                                                        ## only 
                                                                                                                                                        ## networks 
                                                                                                                                                        ## currently 
                                                                                                                                                        ## in 
                                                                                                                                                        ## this 
                                                                                                                                                        ## status 
                                                                                                                                                        ## are 
                                                                                                                                                        ## listed.
  ##   
                                                                                                                                                                  ## nextToken: JString
                                                                                                                                                                  ##            
                                                                                                                                                                  ## : 
                                                                                                                                                                  ## The 
                                                                                                                                                                  ## pagination 
                                                                                                                                                                  ## token 
                                                                                                                                                                  ## that 
                                                                                                                                                                  ## indicates 
                                                                                                                                                                  ## the 
                                                                                                                                                                  ## next 
                                                                                                                                                                  ## set 
                                                                                                                                                                  ## of 
                                                                                                                                                                  ## results 
                                                                                                                                                                  ## to 
                                                                                                                                                                  ## retrieve.
  ##   
                                                                                                                                                                              ## MaxResults: JString
                                                                                                                                                                              ##             
                                                                                                                                                                              ## : 
                                                                                                                                                                              ## Pagination 
                                                                                                                                                                              ## limit
  ##   
                                                                                                                                                                                      ## name: JString
                                                                                                                                                                                      ##       
                                                                                                                                                                                      ## : 
                                                                                                                                                                                      ## The 
                                                                                                                                                                                      ## name 
                                                                                                                                                                                      ## of 
                                                                                                                                                                                      ## the 
                                                                                                                                                                                      ## network.
  ##   
                                                                                                                                                                                                 ## NextToken: JString
                                                                                                                                                                                                 ##            
                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                 ## Pagination 
                                                                                                                                                                                                 ## token
  section = newJObject()
  var valid_402656526 = query.getOrDefault("framework")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = newJString(
      "HYPERLEDGER_FABRIC"))
  if valid_402656526 != nil:
    section.add "framework", valid_402656526
  var valid_402656527 = query.getOrDefault("maxResults")
  valid_402656527 = validateParameter(valid_402656527, JInt, required = false,
                                      default = nil)
  if valid_402656527 != nil:
    section.add "maxResults", valid_402656527
  var valid_402656528 = query.getOrDefault("status")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false,
                                      default = newJString("CREATING"))
  if valid_402656528 != nil:
    section.add "status", valid_402656528
  var valid_402656529 = query.getOrDefault("nextToken")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "nextToken", valid_402656529
  var valid_402656530 = query.getOrDefault("MaxResults")
  valid_402656530 = validateParameter(valid_402656530, JString,
                                      required = false, default = nil)
  if valid_402656530 != nil:
    section.add "MaxResults", valid_402656530
  var valid_402656531 = query.getOrDefault("name")
  valid_402656531 = validateParameter(valid_402656531, JString,
                                      required = false, default = nil)
  if valid_402656531 != nil:
    section.add "name", valid_402656531
  var valid_402656532 = query.getOrDefault("NextToken")
  valid_402656532 = validateParameter(valid_402656532, JString,
                                      required = false, default = nil)
  if valid_402656532 != nil:
    section.add "NextToken", valid_402656532
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656533 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656533 = validateParameter(valid_402656533, JString,
                                      required = false, default = nil)
  if valid_402656533 != nil:
    section.add "X-Amz-Security-Token", valid_402656533
  var valid_402656534 = header.getOrDefault("X-Amz-Signature")
  valid_402656534 = validateParameter(valid_402656534, JString,
                                      required = false, default = nil)
  if valid_402656534 != nil:
    section.add "X-Amz-Signature", valid_402656534
  var valid_402656535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656535
  var valid_402656536 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false, default = nil)
  if valid_402656536 != nil:
    section.add "X-Amz-Algorithm", valid_402656536
  var valid_402656537 = header.getOrDefault("X-Amz-Date")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "X-Amz-Date", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Credential")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Credential", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656540: Call_ListNetworks_402656523; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the networks in which the current AWS account has members.
                                                                                         ## 
  let valid = call_402656540.validator(path, query, header, formData, body, _)
  let scheme = call_402656540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656540.makeUrl(scheme.get, call_402656540.host, call_402656540.base,
                                   call_402656540.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656540, uri, valid, _)

proc call*(call_402656541: Call_ListNetworks_402656523;
           framework: string = "HYPERLEDGER_FABRIC"; maxResults: int = 0;
           status: string = "CREATING"; nextToken: string = "";
           MaxResults: string = ""; name: string = ""; NextToken: string = ""): Recallable =
  ## listNetworks
  ## Returns information about the networks in which the current AWS account has members.
  ##   
                                                                                         ## framework: string
                                                                                         ##            
                                                                                         ## : 
                                                                                         ## An 
                                                                                         ## optional 
                                                                                         ## framework 
                                                                                         ## specifier. 
                                                                                         ## If 
                                                                                         ## provided, 
                                                                                         ## only 
                                                                                         ## networks 
                                                                                         ## of 
                                                                                         ## this 
                                                                                         ## framework 
                                                                                         ## type 
                                                                                         ## are 
                                                                                         ## listed.
  ##   
                                                                                                   ## maxResults: int
                                                                                                   ##             
                                                                                                   ## : 
                                                                                                   ## The 
                                                                                                   ## maximum 
                                                                                                   ## number 
                                                                                                   ## of 
                                                                                                   ## networks 
                                                                                                   ## to 
                                                                                                   ## list.
  ##   
                                                                                                           ## status: string
                                                                                                           ##         
                                                                                                           ## : 
                                                                                                           ## An 
                                                                                                           ## optional 
                                                                                                           ## status 
                                                                                                           ## specifier. 
                                                                                                           ## If 
                                                                                                           ## provided, 
                                                                                                           ## only 
                                                                                                           ## networks 
                                                                                                           ## currently 
                                                                                                           ## in 
                                                                                                           ## this 
                                                                                                           ## status 
                                                                                                           ## are 
                                                                                                           ## listed.
  ##   
                                                                                                                     ## nextToken: string
                                                                                                                     ##            
                                                                                                                     ## : 
                                                                                                                     ## The 
                                                                                                                     ## pagination 
                                                                                                                     ## token 
                                                                                                                     ## that 
                                                                                                                     ## indicates 
                                                                                                                     ## the 
                                                                                                                     ## next 
                                                                                                                     ## set 
                                                                                                                     ## of 
                                                                                                                     ## results 
                                                                                                                     ## to 
                                                                                                                     ## retrieve.
  ##   
                                                                                                                                 ## MaxResults: string
                                                                                                                                 ##             
                                                                                                                                 ## : 
                                                                                                                                 ## Pagination 
                                                                                                                                 ## limit
  ##   
                                                                                                                                         ## name: string
                                                                                                                                         ##       
                                                                                                                                         ## : 
                                                                                                                                         ## The 
                                                                                                                                         ## name 
                                                                                                                                         ## of 
                                                                                                                                         ## the 
                                                                                                                                         ## network.
  ##   
                                                                                                                                                    ## NextToken: string
                                                                                                                                                    ##            
                                                                                                                                                    ## : 
                                                                                                                                                    ## Pagination 
                                                                                                                                                    ## token
  var query_402656542 = newJObject()
  add(query_402656542, "framework", newJString(framework))
  add(query_402656542, "maxResults", newJInt(maxResults))
  add(query_402656542, "status", newJString(status))
  add(query_402656542, "nextToken", newJString(nextToken))
  add(query_402656542, "MaxResults", newJString(MaxResults))
  add(query_402656542, "name", newJString(name))
  add(query_402656542, "NextToken", newJString(NextToken))
  result = call_402656541.call(nil, query_402656542, nil, nil, nil)

var listNetworks* = Call_ListNetworks_402656523(name: "listNetworks",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks", validator: validate_ListNetworks_402656524, base: "/",
    makeUrl: url_ListNetworks_402656525, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNode_402656578 = ref object of OpenApiRestCall_402656044
proc url_CreateNode_402656580(protocol: Scheme; host: string; base: string;
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
                 (kind: VariableSegment, value: "memberId"),
                 (kind: ConstantSegment, value: "/nodes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateNode_402656579(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a peer node in a member.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   memberId: JString (required)
                                 ##           : The unique identifier of the member that owns this node.
  ##   
                                                                                                        ## networkId: JString (required)
                                                                                                        ##            
                                                                                                        ## : 
                                                                                                        ## The 
                                                                                                        ## unique 
                                                                                                        ## identifier 
                                                                                                        ## of 
                                                                                                        ## the 
                                                                                                        ## network 
                                                                                                        ## in 
                                                                                                        ## which 
                                                                                                        ## this 
                                                                                                        ## node 
                                                                                                        ## runs.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `memberId` field"
  var valid_402656581 = path.getOrDefault("memberId")
  valid_402656581 = validateParameter(valid_402656581, JString, required = true,
                                      default = nil)
  if valid_402656581 != nil:
    section.add "memberId", valid_402656581
  var valid_402656582 = path.getOrDefault("networkId")
  valid_402656582 = validateParameter(valid_402656582, JString, required = true,
                                      default = nil)
  if valid_402656582 != nil:
    section.add "networkId", valid_402656582
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656583 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Security-Token", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Signature")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Signature", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Algorithm", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-Date")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Date", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Credential")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Credential", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656591: Call_CreateNode_402656578; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a peer node in a member.
                                                                                         ## 
  let valid = call_402656591.validator(path, query, header, formData, body, _)
  let scheme = call_402656591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656591.makeUrl(scheme.get, call_402656591.host, call_402656591.base,
                                   call_402656591.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656591, uri, valid, _)

proc call*(call_402656592: Call_CreateNode_402656578; memberId: string;
           networkId: string; body: JsonNode): Recallable =
  ## createNode
  ## Creates a peer node in a member.
  ##   memberId: string (required)
                                     ##           : The unique identifier of the member that owns this node.
  ##   
                                                                                                            ## networkId: string (required)
                                                                                                            ##            
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## unique 
                                                                                                            ## identifier 
                                                                                                            ## of 
                                                                                                            ## the 
                                                                                                            ## network 
                                                                                                            ## in 
                                                                                                            ## which 
                                                                                                            ## this 
                                                                                                            ## node 
                                                                                                            ## runs.
  ##   
                                                                                                                    ## body: JObject (required)
  var path_402656593 = newJObject()
  var body_402656594 = newJObject()
  add(path_402656593, "memberId", newJString(memberId))
  add(path_402656593, "networkId", newJString(networkId))
  if body != nil:
    body_402656594 = body
  result = call_402656592.call(path_402656593, nil, nil, nil, body_402656594)

var createNode* = Call_CreateNode_402656578(name: "createNode",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/members/{memberId}/nodes",
    validator: validate_CreateNode_402656579, base: "/",
    makeUrl: url_CreateNode_402656580, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNodes_402656557 = ref object of OpenApiRestCall_402656044
proc url_ListNodes_402656559(protocol: Scheme; host: string; base: string;
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
                 (kind: VariableSegment, value: "memberId"),
                 (kind: ConstantSegment, value: "/nodes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListNodes_402656558(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about the nodes within a network.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   memberId: JString (required)
                                 ##           : The unique identifier of the member who owns the nodes to list.
  ##   
                                                                                                               ## networkId: JString (required)
                                                                                                               ##            
                                                                                                               ## : 
                                                                                                               ## The 
                                                                                                               ## unique 
                                                                                                               ## identifier 
                                                                                                               ## of 
                                                                                                               ## the 
                                                                                                               ## network 
                                                                                                               ## for 
                                                                                                               ## which 
                                                                                                               ## to 
                                                                                                               ## list 
                                                                                                               ## nodes.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `memberId` field"
  var valid_402656560 = path.getOrDefault("memberId")
  valid_402656560 = validateParameter(valid_402656560, JString, required = true,
                                      default = nil)
  if valid_402656560 != nil:
    section.add "memberId", valid_402656560
  var valid_402656561 = path.getOrDefault("networkId")
  valid_402656561 = validateParameter(valid_402656561, JString, required = true,
                                      default = nil)
  if valid_402656561 != nil:
    section.add "networkId", valid_402656561
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of nodes to list.
  ##   
                                                                                       ## status: JString
                                                                                       ##         
                                                                                       ## : 
                                                                                       ## An 
                                                                                       ## optional 
                                                                                       ## status 
                                                                                       ## specifier. 
                                                                                       ## If 
                                                                                       ## provided, 
                                                                                       ## only 
                                                                                       ## nodes 
                                                                                       ## currently 
                                                                                       ## in 
                                                                                       ## this 
                                                                                       ## status 
                                                                                       ## are 
                                                                                       ## listed.
  ##   
                                                                                                 ## nextToken: JString
                                                                                                 ##            
                                                                                                 ## : 
                                                                                                 ## The 
                                                                                                 ## pagination 
                                                                                                 ## token 
                                                                                                 ## that 
                                                                                                 ## indicates 
                                                                                                 ## the 
                                                                                                 ## next 
                                                                                                 ## set 
                                                                                                 ## of 
                                                                                                 ## results 
                                                                                                 ## to 
                                                                                                 ## retrieve.
  ##   
                                                                                                             ## MaxResults: JString
                                                                                                             ##             
                                                                                                             ## : 
                                                                                                             ## Pagination 
                                                                                                             ## limit
  ##   
                                                                                                                     ## NextToken: JString
                                                                                                                     ##            
                                                                                                                     ## : 
                                                                                                                     ## Pagination 
                                                                                                                     ## token
  section = newJObject()
  var valid_402656562 = query.getOrDefault("maxResults")
  valid_402656562 = validateParameter(valid_402656562, JInt, required = false,
                                      default = nil)
  if valid_402656562 != nil:
    section.add "maxResults", valid_402656562
  var valid_402656563 = query.getOrDefault("status")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false,
                                      default = newJString("CREATING"))
  if valid_402656563 != nil:
    section.add "status", valid_402656563
  var valid_402656564 = query.getOrDefault("nextToken")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "nextToken", valid_402656564
  var valid_402656565 = query.getOrDefault("MaxResults")
  valid_402656565 = validateParameter(valid_402656565, JString,
                                      required = false, default = nil)
  if valid_402656565 != nil:
    section.add "MaxResults", valid_402656565
  var valid_402656566 = query.getOrDefault("NextToken")
  valid_402656566 = validateParameter(valid_402656566, JString,
                                      required = false, default = nil)
  if valid_402656566 != nil:
    section.add "NextToken", valid_402656566
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656567 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656567 = validateParameter(valid_402656567, JString,
                                      required = false, default = nil)
  if valid_402656567 != nil:
    section.add "X-Amz-Security-Token", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Signature")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Signature", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Algorithm", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-Date")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Date", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-Credential")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Credential", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656573
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656574: Call_ListNodes_402656557; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the nodes within a network.
                                                                                         ## 
  let valid = call_402656574.validator(path, query, header, formData, body, _)
  let scheme = call_402656574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656574.makeUrl(scheme.get, call_402656574.host, call_402656574.base,
                                   call_402656574.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656574, uri, valid, _)

proc call*(call_402656575: Call_ListNodes_402656557; memberId: string;
           networkId: string; maxResults: int = 0; status: string = "CREATING";
           nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listNodes
  ## Returns information about the nodes within a network.
  ##   memberId: string (required)
                                                          ##           : The unique identifier of the member who owns the nodes to list.
  ##   
                                                                                                                                        ## maxResults: int
                                                                                                                                        ##             
                                                                                                                                        ## : 
                                                                                                                                        ## The 
                                                                                                                                        ## maximum 
                                                                                                                                        ## number 
                                                                                                                                        ## of 
                                                                                                                                        ## nodes 
                                                                                                                                        ## to 
                                                                                                                                        ## list.
  ##   
                                                                                                                                                ## networkId: string (required)
                                                                                                                                                ##            
                                                                                                                                                ## : 
                                                                                                                                                ## The 
                                                                                                                                                ## unique 
                                                                                                                                                ## identifier 
                                                                                                                                                ## of 
                                                                                                                                                ## the 
                                                                                                                                                ## network 
                                                                                                                                                ## for 
                                                                                                                                                ## which 
                                                                                                                                                ## to 
                                                                                                                                                ## list 
                                                                                                                                                ## nodes.
  ##   
                                                                                                                                                         ## status: string
                                                                                                                                                         ##         
                                                                                                                                                         ## : 
                                                                                                                                                         ## An 
                                                                                                                                                         ## optional 
                                                                                                                                                         ## status 
                                                                                                                                                         ## specifier. 
                                                                                                                                                         ## If 
                                                                                                                                                         ## provided, 
                                                                                                                                                         ## only 
                                                                                                                                                         ## nodes 
                                                                                                                                                         ## currently 
                                                                                                                                                         ## in 
                                                                                                                                                         ## this 
                                                                                                                                                         ## status 
                                                                                                                                                         ## are 
                                                                                                                                                         ## listed.
  ##   
                                                                                                                                                                   ## nextToken: string
                                                                                                                                                                   ##            
                                                                                                                                                                   ## : 
                                                                                                                                                                   ## The 
                                                                                                                                                                   ## pagination 
                                                                                                                                                                   ## token 
                                                                                                                                                                   ## that 
                                                                                                                                                                   ## indicates 
                                                                                                                                                                   ## the 
                                                                                                                                                                   ## next 
                                                                                                                                                                   ## set 
                                                                                                                                                                   ## of 
                                                                                                                                                                   ## results 
                                                                                                                                                                   ## to 
                                                                                                                                                                   ## retrieve.
  ##   
                                                                                                                                                                               ## MaxResults: string
                                                                                                                                                                               ##             
                                                                                                                                                                               ## : 
                                                                                                                                                                               ## Pagination 
                                                                                                                                                                               ## limit
  ##   
                                                                                                                                                                                       ## NextToken: string
                                                                                                                                                                                       ##            
                                                                                                                                                                                       ## : 
                                                                                                                                                                                       ## Pagination 
                                                                                                                                                                                       ## token
  var path_402656576 = newJObject()
  var query_402656577 = newJObject()
  add(path_402656576, "memberId", newJString(memberId))
  add(query_402656577, "maxResults", newJInt(maxResults))
  add(path_402656576, "networkId", newJString(networkId))
  add(query_402656577, "status", newJString(status))
  add(query_402656577, "nextToken", newJString(nextToken))
  add(query_402656577, "MaxResults", newJString(MaxResults))
  add(query_402656577, "NextToken", newJString(NextToken))
  result = call_402656575.call(path_402656576, query_402656577, nil, nil, nil)

var listNodes* = Call_ListNodes_402656557(name: "listNodes",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/members/{memberId}/nodes",
    validator: validate_ListNodes_402656558, base: "/", makeUrl: url_ListNodes_402656559,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProposal_402656614 = ref object of OpenApiRestCall_402656044
proc url_CreateProposal_402656616(protocol: Scheme; host: string; base: string;
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

proc validate_CreateProposal_402656615(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a proposal for a change to the network that other members of the network can vote on, for example, a proposal to add a new member to the network. Any member can create a proposal.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   networkId: JString (required)
                                 ##            :  The unique identifier of the network for which the proposal is made.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `networkId` field"
  var valid_402656617 = path.getOrDefault("networkId")
  valid_402656617 = validateParameter(valid_402656617, JString, required = true,
                                      default = nil)
  if valid_402656617 != nil:
    section.add "networkId", valid_402656617
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656618 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Security-Token", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-Signature")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-Signature", valid_402656619
  var valid_402656620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656620 = validateParameter(valid_402656620, JString,
                                      required = false, default = nil)
  if valid_402656620 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656620
  var valid_402656621 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "X-Amz-Algorithm", valid_402656621
  var valid_402656622 = header.getOrDefault("X-Amz-Date")
  valid_402656622 = validateParameter(valid_402656622, JString,
                                      required = false, default = nil)
  if valid_402656622 != nil:
    section.add "X-Amz-Date", valid_402656622
  var valid_402656623 = header.getOrDefault("X-Amz-Credential")
  valid_402656623 = validateParameter(valid_402656623, JString,
                                      required = false, default = nil)
  if valid_402656623 != nil:
    section.add "X-Amz-Credential", valid_402656623
  var valid_402656624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656624 = validateParameter(valid_402656624, JString,
                                      required = false, default = nil)
  if valid_402656624 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656626: Call_CreateProposal_402656614; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a proposal for a change to the network that other members of the network can vote on, for example, a proposal to add a new member to the network. Any member can create a proposal.
                                                                                         ## 
  let valid = call_402656626.validator(path, query, header, formData, body, _)
  let scheme = call_402656626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656626.makeUrl(scheme.get, call_402656626.host, call_402656626.base,
                                   call_402656626.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656626, uri, valid, _)

proc call*(call_402656627: Call_CreateProposal_402656614; networkId: string;
           body: JsonNode): Recallable =
  ## createProposal
  ## Creates a proposal for a change to the network that other members of the network can vote on, for example, a proposal to add a new member to the network. Any member can create a proposal.
  ##   
                                                                                                                                                                                                ## networkId: string (required)
                                                                                                                                                                                                ##            
                                                                                                                                                                                                ## :  
                                                                                                                                                                                                ## The 
                                                                                                                                                                                                ## unique 
                                                                                                                                                                                                ## identifier 
                                                                                                                                                                                                ## of 
                                                                                                                                                                                                ## the 
                                                                                                                                                                                                ## network 
                                                                                                                                                                                                ## for 
                                                                                                                                                                                                ## which 
                                                                                                                                                                                                ## the 
                                                                                                                                                                                                ## proposal 
                                                                                                                                                                                                ## is 
                                                                                                                                                                                                ## made.
  ##   
                                                                                                                                                                                                        ## body: JObject (required)
  var path_402656628 = newJObject()
  var body_402656629 = newJObject()
  add(path_402656628, "networkId", newJString(networkId))
  if body != nil:
    body_402656629 = body
  result = call_402656627.call(path_402656628, nil, nil, nil, body_402656629)

var createProposal* = Call_CreateProposal_402656614(name: "createProposal",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals",
    validator: validate_CreateProposal_402656615, base: "/",
    makeUrl: url_CreateProposal_402656616, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProposals_402656595 = ref object of OpenApiRestCall_402656044
proc url_ListProposals_402656597(protocol: Scheme; host: string; base: string;
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

proc validate_ListProposals_402656596(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a listing of proposals for the network.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   networkId: JString (required)
                                 ##            :  The unique identifier of the network. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `networkId` field"
  var valid_402656598 = path.getOrDefault("networkId")
  valid_402656598 = validateParameter(valid_402656598, JString, required = true,
                                      default = nil)
  if valid_402656598 != nil:
    section.add "networkId", valid_402656598
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             :  The maximum number of proposals to return. 
  ##   
                                                                                               ## nextToken: JString
                                                                                               ##            
                                                                                               ## :  
                                                                                               ## The 
                                                                                               ## pagination 
                                                                                               ## token 
                                                                                               ## that 
                                                                                               ## indicates 
                                                                                               ## the 
                                                                                               ## next 
                                                                                               ## set 
                                                                                               ## of 
                                                                                               ## results 
                                                                                               ## to 
                                                                                               ## retrieve. 
  ##   
                                                                                                            ## MaxResults: JString
                                                                                                            ##             
                                                                                                            ## : 
                                                                                                            ## Pagination 
                                                                                                            ## limit
  ##   
                                                                                                                    ## NextToken: JString
                                                                                                                    ##            
                                                                                                                    ## : 
                                                                                                                    ## Pagination 
                                                                                                                    ## token
  section = newJObject()
  var valid_402656599 = query.getOrDefault("maxResults")
  valid_402656599 = validateParameter(valid_402656599, JInt, required = false,
                                      default = nil)
  if valid_402656599 != nil:
    section.add "maxResults", valid_402656599
  var valid_402656600 = query.getOrDefault("nextToken")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "nextToken", valid_402656600
  var valid_402656601 = query.getOrDefault("MaxResults")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "MaxResults", valid_402656601
  var valid_402656602 = query.getOrDefault("NextToken")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "NextToken", valid_402656602
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656603 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Security-Token", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-Signature")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-Signature", valid_402656604
  var valid_402656605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656605 = validateParameter(valid_402656605, JString,
                                      required = false, default = nil)
  if valid_402656605 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656605
  var valid_402656606 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656606 = validateParameter(valid_402656606, JString,
                                      required = false, default = nil)
  if valid_402656606 != nil:
    section.add "X-Amz-Algorithm", valid_402656606
  var valid_402656607 = header.getOrDefault("X-Amz-Date")
  valid_402656607 = validateParameter(valid_402656607, JString,
                                      required = false, default = nil)
  if valid_402656607 != nil:
    section.add "X-Amz-Date", valid_402656607
  var valid_402656608 = header.getOrDefault("X-Amz-Credential")
  valid_402656608 = validateParameter(valid_402656608, JString,
                                      required = false, default = nil)
  if valid_402656608 != nil:
    section.add "X-Amz-Credential", valid_402656608
  var valid_402656609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656610: Call_ListProposals_402656595; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a listing of proposals for the network.
                                                                                         ## 
  let valid = call_402656610.validator(path, query, header, formData, body, _)
  let scheme = call_402656610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656610.makeUrl(scheme.get, call_402656610.host, call_402656610.base,
                                   call_402656610.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656610, uri, valid, _)

proc call*(call_402656611: Call_ListProposals_402656595; networkId: string;
           maxResults: int = 0; nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listProposals
  ## Returns a listing of proposals for the network.
  ##   maxResults: int
                                                    ##             :  The maximum number of proposals to return. 
  ##   
                                                                                                                 ## networkId: string (required)
                                                                                                                 ##            
                                                                                                                 ## :  
                                                                                                                 ## The 
                                                                                                                 ## unique 
                                                                                                                 ## identifier 
                                                                                                                 ## of 
                                                                                                                 ## the 
                                                                                                                 ## network. 
  ##   
                                                                                                                             ## nextToken: string
                                                                                                                             ##            
                                                                                                                             ## :  
                                                                                                                             ## The 
                                                                                                                             ## pagination 
                                                                                                                             ## token 
                                                                                                                             ## that 
                                                                                                                             ## indicates 
                                                                                                                             ## the 
                                                                                                                             ## next 
                                                                                                                             ## set 
                                                                                                                             ## of 
                                                                                                                             ## results 
                                                                                                                             ## to 
                                                                                                                             ## retrieve. 
  ##   
                                                                                                                                          ## MaxResults: string
                                                                                                                                          ##             
                                                                                                                                          ## : 
                                                                                                                                          ## Pagination 
                                                                                                                                          ## limit
  ##   
                                                                                                                                                  ## NextToken: string
                                                                                                                                                  ##            
                                                                                                                                                  ## : 
                                                                                                                                                  ## Pagination 
                                                                                                                                                  ## token
  var path_402656612 = newJObject()
  var query_402656613 = newJObject()
  add(query_402656613, "maxResults", newJInt(maxResults))
  add(path_402656612, "networkId", newJString(networkId))
  add(query_402656613, "nextToken", newJString(nextToken))
  add(query_402656613, "MaxResults", newJString(MaxResults))
  add(query_402656613, "NextToken", newJString(NextToken))
  result = call_402656611.call(path_402656612, query_402656613, nil, nil, nil)

var listProposals* = Call_ListProposals_402656595(name: "listProposals",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals", validator: validate_ListProposals_402656596,
    base: "/", makeUrl: url_ListProposals_402656597,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMember_402656630 = ref object of OpenApiRestCall_402656044
proc url_GetMember_402656632(protocol: Scheme; host: string; base: string;
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

proc validate_GetMember_402656631(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns detailed information about a member.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   memberId: JString (required)
                                 ##           : The unique identifier of the member.
  ##   
                                                                                    ## networkId: JString (required)
                                                                                    ##            
                                                                                    ## : 
                                                                                    ## The 
                                                                                    ## unique 
                                                                                    ## identifier 
                                                                                    ## of 
                                                                                    ## the 
                                                                                    ## network 
                                                                                    ## to 
                                                                                    ## which 
                                                                                    ## the 
                                                                                    ## member 
                                                                                    ## belongs.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `memberId` field"
  var valid_402656633 = path.getOrDefault("memberId")
  valid_402656633 = validateParameter(valid_402656633, JString, required = true,
                                      default = nil)
  if valid_402656633 != nil:
    section.add "memberId", valid_402656633
  var valid_402656634 = path.getOrDefault("networkId")
  valid_402656634 = validateParameter(valid_402656634, JString, required = true,
                                      default = nil)
  if valid_402656634 != nil:
    section.add "networkId", valid_402656634
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656635 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656635 = validateParameter(valid_402656635, JString,
                                      required = false, default = nil)
  if valid_402656635 != nil:
    section.add "X-Amz-Security-Token", valid_402656635
  var valid_402656636 = header.getOrDefault("X-Amz-Signature")
  valid_402656636 = validateParameter(valid_402656636, JString,
                                      required = false, default = nil)
  if valid_402656636 != nil:
    section.add "X-Amz-Signature", valid_402656636
  var valid_402656637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656637 = validateParameter(valid_402656637, JString,
                                      required = false, default = nil)
  if valid_402656637 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656637
  var valid_402656638 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656638 = validateParameter(valid_402656638, JString,
                                      required = false, default = nil)
  if valid_402656638 != nil:
    section.add "X-Amz-Algorithm", valid_402656638
  var valid_402656639 = header.getOrDefault("X-Amz-Date")
  valid_402656639 = validateParameter(valid_402656639, JString,
                                      required = false, default = nil)
  if valid_402656639 != nil:
    section.add "X-Amz-Date", valid_402656639
  var valid_402656640 = header.getOrDefault("X-Amz-Credential")
  valid_402656640 = validateParameter(valid_402656640, JString,
                                      required = false, default = nil)
  if valid_402656640 != nil:
    section.add "X-Amz-Credential", valid_402656640
  var valid_402656641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656641 = validateParameter(valid_402656641, JString,
                                      required = false, default = nil)
  if valid_402656641 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656642: Call_GetMember_402656630; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns detailed information about a member.
                                                                                         ## 
  let valid = call_402656642.validator(path, query, header, formData, body, _)
  let scheme = call_402656642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656642.makeUrl(scheme.get, call_402656642.host, call_402656642.base,
                                   call_402656642.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656642, uri, valid, _)

proc call*(call_402656643: Call_GetMember_402656630; memberId: string;
           networkId: string): Recallable =
  ## getMember
  ## Returns detailed information about a member.
  ##   memberId: string (required)
                                                 ##           : The unique identifier of the member.
  ##   
                                                                                                    ## networkId: string (required)
                                                                                                    ##            
                                                                                                    ## : 
                                                                                                    ## The 
                                                                                                    ## unique 
                                                                                                    ## identifier 
                                                                                                    ## of 
                                                                                                    ## the 
                                                                                                    ## network 
                                                                                                    ## to 
                                                                                                    ## which 
                                                                                                    ## the 
                                                                                                    ## member 
                                                                                                    ## belongs.
  var path_402656644 = newJObject()
  add(path_402656644, "memberId", newJString(memberId))
  add(path_402656644, "networkId", newJString(networkId))
  result = call_402656643.call(path_402656644, nil, nil, nil, nil)

var getMember* = Call_GetMember_402656630(name: "getMember",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/members/{memberId}",
    validator: validate_GetMember_402656631, base: "/", makeUrl: url_GetMember_402656632,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMember_402656645 = ref object of OpenApiRestCall_402656044
proc url_DeleteMember_402656647(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMember_402656646(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a member. Deleting a member removes the member and all associated resources from the network. <code>DeleteMember</code> can only be called for a specified <code>MemberId</code> if the principal performing the action is associated with the AWS account that owns the member. In all other cases, the <code>DeleteMember</code> action is carried out as the result of an approved proposal to remove a member. If <code>MemberId</code> is the last member in a network specified by the last AWS account, the network is deleted also.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   memberId: JString (required)
                                 ##           : The unique identifier of the member to remove.
  ##   
                                                                                              ## networkId: JString (required)
                                                                                              ##            
                                                                                              ## : 
                                                                                              ## The 
                                                                                              ## unique 
                                                                                              ## identifier 
                                                                                              ## of 
                                                                                              ## the 
                                                                                              ## network 
                                                                                              ## from 
                                                                                              ## which 
                                                                                              ## the 
                                                                                              ## member 
                                                                                              ## is 
                                                                                              ## removed.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `memberId` field"
  var valid_402656648 = path.getOrDefault("memberId")
  valid_402656648 = validateParameter(valid_402656648, JString, required = true,
                                      default = nil)
  if valid_402656648 != nil:
    section.add "memberId", valid_402656648
  var valid_402656649 = path.getOrDefault("networkId")
  valid_402656649 = validateParameter(valid_402656649, JString, required = true,
                                      default = nil)
  if valid_402656649 != nil:
    section.add "networkId", valid_402656649
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656650 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656650 = validateParameter(valid_402656650, JString,
                                      required = false, default = nil)
  if valid_402656650 != nil:
    section.add "X-Amz-Security-Token", valid_402656650
  var valid_402656651 = header.getOrDefault("X-Amz-Signature")
  valid_402656651 = validateParameter(valid_402656651, JString,
                                      required = false, default = nil)
  if valid_402656651 != nil:
    section.add "X-Amz-Signature", valid_402656651
  var valid_402656652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656652 = validateParameter(valid_402656652, JString,
                                      required = false, default = nil)
  if valid_402656652 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656652
  var valid_402656653 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656653 = validateParameter(valid_402656653, JString,
                                      required = false, default = nil)
  if valid_402656653 != nil:
    section.add "X-Amz-Algorithm", valid_402656653
  var valid_402656654 = header.getOrDefault("X-Amz-Date")
  valid_402656654 = validateParameter(valid_402656654, JString,
                                      required = false, default = nil)
  if valid_402656654 != nil:
    section.add "X-Amz-Date", valid_402656654
  var valid_402656655 = header.getOrDefault("X-Amz-Credential")
  valid_402656655 = validateParameter(valid_402656655, JString,
                                      required = false, default = nil)
  if valid_402656655 != nil:
    section.add "X-Amz-Credential", valid_402656655
  var valid_402656656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656656 = validateParameter(valid_402656656, JString,
                                      required = false, default = nil)
  if valid_402656656 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656657: Call_DeleteMember_402656645; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a member. Deleting a member removes the member and all associated resources from the network. <code>DeleteMember</code> can only be called for a specified <code>MemberId</code> if the principal performing the action is associated with the AWS account that owns the member. In all other cases, the <code>DeleteMember</code> action is carried out as the result of an approved proposal to remove a member. If <code>MemberId</code> is the last member in a network specified by the last AWS account, the network is deleted also.
                                                                                         ## 
  let valid = call_402656657.validator(path, query, header, formData, body, _)
  let scheme = call_402656657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656657.makeUrl(scheme.get, call_402656657.host, call_402656657.base,
                                   call_402656657.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656657, uri, valid, _)

proc call*(call_402656658: Call_DeleteMember_402656645; memberId: string;
           networkId: string): Recallable =
  ## deleteMember
  ## Deletes a member. Deleting a member removes the member and all associated resources from the network. <code>DeleteMember</code> can only be called for a specified <code>MemberId</code> if the principal performing the action is associated with the AWS account that owns the member. In all other cases, the <code>DeleteMember</code> action is carried out as the result of an approved proposal to remove a member. If <code>MemberId</code> is the last member in a network specified by the last AWS account, the network is deleted also.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## memberId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ##           
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## unique 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## identifier 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## member 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## remove.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## networkId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## unique 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## identifier 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## network 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## from 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## which 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## member 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## removed.
  var path_402656659 = newJObject()
  add(path_402656659, "memberId", newJString(memberId))
  add(path_402656659, "networkId", newJString(networkId))
  result = call_402656658.call(path_402656659, nil, nil, nil, nil)

var deleteMember* = Call_DeleteMember_402656645(name: "deleteMember",
    meth: HttpMethod.HttpDelete, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/members/{memberId}",
    validator: validate_DeleteMember_402656646, base: "/",
    makeUrl: url_DeleteMember_402656647, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNode_402656660 = ref object of OpenApiRestCall_402656044
proc url_GetNode_402656662(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetNode_402656661(path: JsonNode; query: JsonNode;
                                header: JsonNode; formData: JsonNode;
                                body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns detailed information about a peer node.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   nodeId: JString (required)
                                 ##         : The unique identifier of the node.
  ##   
                                                                                ## memberId: JString (required)
                                                                                ##           
                                                                                ## : 
                                                                                ## The 
                                                                                ## unique 
                                                                                ## identifier 
                                                                                ## of 
                                                                                ## the 
                                                                                ## member 
                                                                                ## that 
                                                                                ## owns 
                                                                                ## the 
                                                                                ## node.
  ##   
                                                                                        ## networkId: JString (required)
                                                                                        ##            
                                                                                        ## : 
                                                                                        ## The 
                                                                                        ## unique 
                                                                                        ## identifier 
                                                                                        ## of 
                                                                                        ## the 
                                                                                        ## network 
                                                                                        ## to 
                                                                                        ## which 
                                                                                        ## the 
                                                                                        ## node 
                                                                                        ## belongs.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `nodeId` field"
  var valid_402656663 = path.getOrDefault("nodeId")
  valid_402656663 = validateParameter(valid_402656663, JString, required = true,
                                      default = nil)
  if valid_402656663 != nil:
    section.add "nodeId", valid_402656663
  var valid_402656664 = path.getOrDefault("memberId")
  valid_402656664 = validateParameter(valid_402656664, JString, required = true,
                                      default = nil)
  if valid_402656664 != nil:
    section.add "memberId", valid_402656664
  var valid_402656665 = path.getOrDefault("networkId")
  valid_402656665 = validateParameter(valid_402656665, JString, required = true,
                                      default = nil)
  if valid_402656665 != nil:
    section.add "networkId", valid_402656665
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656666 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656666 = validateParameter(valid_402656666, JString,
                                      required = false, default = nil)
  if valid_402656666 != nil:
    section.add "X-Amz-Security-Token", valid_402656666
  var valid_402656667 = header.getOrDefault("X-Amz-Signature")
  valid_402656667 = validateParameter(valid_402656667, JString,
                                      required = false, default = nil)
  if valid_402656667 != nil:
    section.add "X-Amz-Signature", valid_402656667
  var valid_402656668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656668 = validateParameter(valid_402656668, JString,
                                      required = false, default = nil)
  if valid_402656668 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656668
  var valid_402656669 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656669 = validateParameter(valid_402656669, JString,
                                      required = false, default = nil)
  if valid_402656669 != nil:
    section.add "X-Amz-Algorithm", valid_402656669
  var valid_402656670 = header.getOrDefault("X-Amz-Date")
  valid_402656670 = validateParameter(valid_402656670, JString,
                                      required = false, default = nil)
  if valid_402656670 != nil:
    section.add "X-Amz-Date", valid_402656670
  var valid_402656671 = header.getOrDefault("X-Amz-Credential")
  valid_402656671 = validateParameter(valid_402656671, JString,
                                      required = false, default = nil)
  if valid_402656671 != nil:
    section.add "X-Amz-Credential", valid_402656671
  var valid_402656672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656672 = validateParameter(valid_402656672, JString,
                                      required = false, default = nil)
  if valid_402656672 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656673: Call_GetNode_402656660; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns detailed information about a peer node.
                                                                                         ## 
  let valid = call_402656673.validator(path, query, header, formData, body, _)
  let scheme = call_402656673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656673.makeUrl(scheme.get, call_402656673.host, call_402656673.base,
                                   call_402656673.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656673, uri, valid, _)

proc call*(call_402656674: Call_GetNode_402656660; nodeId: string;
           memberId: string; networkId: string): Recallable =
  ## getNode
  ## Returns detailed information about a peer node.
  ##   nodeId: string (required)
                                                    ##         : The unique identifier of the node.
  ##   
                                                                                                   ## memberId: string (required)
                                                                                                   ##           
                                                                                                   ## : 
                                                                                                   ## The 
                                                                                                   ## unique 
                                                                                                   ## identifier 
                                                                                                   ## of 
                                                                                                   ## the 
                                                                                                   ## member 
                                                                                                   ## that 
                                                                                                   ## owns 
                                                                                                   ## the 
                                                                                                   ## node.
  ##   
                                                                                                           ## networkId: string (required)
                                                                                                           ##            
                                                                                                           ## : 
                                                                                                           ## The 
                                                                                                           ## unique 
                                                                                                           ## identifier 
                                                                                                           ## of 
                                                                                                           ## the 
                                                                                                           ## network 
                                                                                                           ## to 
                                                                                                           ## which 
                                                                                                           ## the 
                                                                                                           ## node 
                                                                                                           ## belongs.
  var path_402656675 = newJObject()
  add(path_402656675, "nodeId", newJString(nodeId))
  add(path_402656675, "memberId", newJString(memberId))
  add(path_402656675, "networkId", newJString(networkId))
  result = call_402656674.call(path_402656675, nil, nil, nil, nil)

var getNode* = Call_GetNode_402656660(name: "getNode", meth: HttpMethod.HttpGet,
                                      host: "managedblockchain.amazonaws.com", route: "/networks/{networkId}/members/{memberId}/nodes/{nodeId}",
                                      validator: validate_GetNode_402656661,
                                      base: "/", makeUrl: url_GetNode_402656662,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNode_402656676 = ref object of OpenApiRestCall_402656044
proc url_DeleteNode_402656678(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_DeleteNode_402656677(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a peer node from a member that your AWS account owns. All data on the node is lost and cannot be recovered.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   nodeId: JString (required)
                                 ##         : The unique identifier of the node.
  ##   
                                                                                ## memberId: JString (required)
                                                                                ##           
                                                                                ## : 
                                                                                ## The 
                                                                                ## unique 
                                                                                ## identifier 
                                                                                ## of 
                                                                                ## the 
                                                                                ## member 
                                                                                ## that 
                                                                                ## owns 
                                                                                ## this 
                                                                                ## node.
  ##   
                                                                                        ## networkId: JString (required)
                                                                                        ##            
                                                                                        ## : 
                                                                                        ## The 
                                                                                        ## unique 
                                                                                        ## identifier 
                                                                                        ## of 
                                                                                        ## the 
                                                                                        ## network 
                                                                                        ## that 
                                                                                        ## the 
                                                                                        ## node 
                                                                                        ## belongs 
                                                                                        ## to.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `nodeId` field"
  var valid_402656679 = path.getOrDefault("nodeId")
  valid_402656679 = validateParameter(valid_402656679, JString, required = true,
                                      default = nil)
  if valid_402656679 != nil:
    section.add "nodeId", valid_402656679
  var valid_402656680 = path.getOrDefault("memberId")
  valid_402656680 = validateParameter(valid_402656680, JString, required = true,
                                      default = nil)
  if valid_402656680 != nil:
    section.add "memberId", valid_402656680
  var valid_402656681 = path.getOrDefault("networkId")
  valid_402656681 = validateParameter(valid_402656681, JString, required = true,
                                      default = nil)
  if valid_402656681 != nil:
    section.add "networkId", valid_402656681
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656682 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656682 = validateParameter(valid_402656682, JString,
                                      required = false, default = nil)
  if valid_402656682 != nil:
    section.add "X-Amz-Security-Token", valid_402656682
  var valid_402656683 = header.getOrDefault("X-Amz-Signature")
  valid_402656683 = validateParameter(valid_402656683, JString,
                                      required = false, default = nil)
  if valid_402656683 != nil:
    section.add "X-Amz-Signature", valid_402656683
  var valid_402656684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656684 = validateParameter(valid_402656684, JString,
                                      required = false, default = nil)
  if valid_402656684 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656684
  var valid_402656685 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656685 = validateParameter(valid_402656685, JString,
                                      required = false, default = nil)
  if valid_402656685 != nil:
    section.add "X-Amz-Algorithm", valid_402656685
  var valid_402656686 = header.getOrDefault("X-Amz-Date")
  valid_402656686 = validateParameter(valid_402656686, JString,
                                      required = false, default = nil)
  if valid_402656686 != nil:
    section.add "X-Amz-Date", valid_402656686
  var valid_402656687 = header.getOrDefault("X-Amz-Credential")
  valid_402656687 = validateParameter(valid_402656687, JString,
                                      required = false, default = nil)
  if valid_402656687 != nil:
    section.add "X-Amz-Credential", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656689: Call_DeleteNode_402656676; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a peer node from a member that your AWS account owns. All data on the node is lost and cannot be recovered.
                                                                                         ## 
  let valid = call_402656689.validator(path, query, header, formData, body, _)
  let scheme = call_402656689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656689.makeUrl(scheme.get, call_402656689.host, call_402656689.base,
                                   call_402656689.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656689, uri, valid, _)

proc call*(call_402656690: Call_DeleteNode_402656676; nodeId: string;
           memberId: string; networkId: string): Recallable =
  ## deleteNode
  ## Deletes a peer node from a member that your AWS account owns. All data on the node is lost and cannot be recovered.
  ##   
                                                                                                                        ## nodeId: string (required)
                                                                                                                        ##         
                                                                                                                        ## : 
                                                                                                                        ## The 
                                                                                                                        ## unique 
                                                                                                                        ## identifier 
                                                                                                                        ## of 
                                                                                                                        ## the 
                                                                                                                        ## node.
  ##   
                                                                                                                                ## memberId: string (required)
                                                                                                                                ##           
                                                                                                                                ## : 
                                                                                                                                ## The 
                                                                                                                                ## unique 
                                                                                                                                ## identifier 
                                                                                                                                ## of 
                                                                                                                                ## the 
                                                                                                                                ## member 
                                                                                                                                ## that 
                                                                                                                                ## owns 
                                                                                                                                ## this 
                                                                                                                                ## node.
  ##   
                                                                                                                                        ## networkId: string (required)
                                                                                                                                        ##            
                                                                                                                                        ## : 
                                                                                                                                        ## The 
                                                                                                                                        ## unique 
                                                                                                                                        ## identifier 
                                                                                                                                        ## of 
                                                                                                                                        ## the 
                                                                                                                                        ## network 
                                                                                                                                        ## that 
                                                                                                                                        ## the 
                                                                                                                                        ## node 
                                                                                                                                        ## belongs 
                                                                                                                                        ## to.
  var path_402656691 = newJObject()
  add(path_402656691, "nodeId", newJString(nodeId))
  add(path_402656691, "memberId", newJString(memberId))
  add(path_402656691, "networkId", newJString(networkId))
  result = call_402656690.call(path_402656691, nil, nil, nil, nil)

var deleteNode* = Call_DeleteNode_402656676(name: "deleteNode",
    meth: HttpMethod.HttpDelete, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/members/{memberId}/nodes/{nodeId}",
    validator: validate_DeleteNode_402656677, base: "/",
    makeUrl: url_DeleteNode_402656678, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNetwork_402656692 = ref object of OpenApiRestCall_402656044
proc url_GetNetwork_402656694(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetNetwork_402656693(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns detailed information about a network.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   networkId: JString (required)
                                 ##            : The unique identifier of the network to get information about.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `networkId` field"
  var valid_402656695 = path.getOrDefault("networkId")
  valid_402656695 = validateParameter(valid_402656695, JString, required = true,
                                      default = nil)
  if valid_402656695 != nil:
    section.add "networkId", valid_402656695
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656696 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656696 = validateParameter(valid_402656696, JString,
                                      required = false, default = nil)
  if valid_402656696 != nil:
    section.add "X-Amz-Security-Token", valid_402656696
  var valid_402656697 = header.getOrDefault("X-Amz-Signature")
  valid_402656697 = validateParameter(valid_402656697, JString,
                                      required = false, default = nil)
  if valid_402656697 != nil:
    section.add "X-Amz-Signature", valid_402656697
  var valid_402656698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656698 = validateParameter(valid_402656698, JString,
                                      required = false, default = nil)
  if valid_402656698 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656698
  var valid_402656699 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656699 = validateParameter(valid_402656699, JString,
                                      required = false, default = nil)
  if valid_402656699 != nil:
    section.add "X-Amz-Algorithm", valid_402656699
  var valid_402656700 = header.getOrDefault("X-Amz-Date")
  valid_402656700 = validateParameter(valid_402656700, JString,
                                      required = false, default = nil)
  if valid_402656700 != nil:
    section.add "X-Amz-Date", valid_402656700
  var valid_402656701 = header.getOrDefault("X-Amz-Credential")
  valid_402656701 = validateParameter(valid_402656701, JString,
                                      required = false, default = nil)
  if valid_402656701 != nil:
    section.add "X-Amz-Credential", valid_402656701
  var valid_402656702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656702 = validateParameter(valid_402656702, JString,
                                      required = false, default = nil)
  if valid_402656702 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656703: Call_GetNetwork_402656692; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns detailed information about a network.
                                                                                         ## 
  let valid = call_402656703.validator(path, query, header, formData, body, _)
  let scheme = call_402656703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656703.makeUrl(scheme.get, call_402656703.host, call_402656703.base,
                                   call_402656703.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656703, uri, valid, _)

proc call*(call_402656704: Call_GetNetwork_402656692; networkId: string): Recallable =
  ## getNetwork
  ## Returns detailed information about a network.
  ##   networkId: string (required)
                                                  ##            : The unique identifier of the network to get information about.
  var path_402656705 = newJObject()
  add(path_402656705, "networkId", newJString(networkId))
  result = call_402656704.call(path_402656705, nil, nil, nil, nil)

var getNetwork* = Call_GetNetwork_402656692(name: "getNetwork",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}", validator: validate_GetNetwork_402656693,
    base: "/", makeUrl: url_GetNetwork_402656694,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProposal_402656706 = ref object of OpenApiRestCall_402656044
proc url_GetProposal_402656708(protocol: Scheme; host: string; base: string;
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

proc validate_GetProposal_402656707(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns detailed information about a proposal.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   networkId: JString (required)
                                 ##            : The unique identifier of the network for which the proposal is made.
  ##   
                                                                                                                     ## proposalId: JString (required)
                                                                                                                     ##             
                                                                                                                     ## : 
                                                                                                                     ## The 
                                                                                                                     ## unique 
                                                                                                                     ## identifier 
                                                                                                                     ## of 
                                                                                                                     ## the 
                                                                                                                     ## proposal.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `networkId` field"
  var valid_402656709 = path.getOrDefault("networkId")
  valid_402656709 = validateParameter(valid_402656709, JString, required = true,
                                      default = nil)
  if valid_402656709 != nil:
    section.add "networkId", valid_402656709
  var valid_402656710 = path.getOrDefault("proposalId")
  valid_402656710 = validateParameter(valid_402656710, JString, required = true,
                                      default = nil)
  if valid_402656710 != nil:
    section.add "proposalId", valid_402656710
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656711 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656711 = validateParameter(valid_402656711, JString,
                                      required = false, default = nil)
  if valid_402656711 != nil:
    section.add "X-Amz-Security-Token", valid_402656711
  var valid_402656712 = header.getOrDefault("X-Amz-Signature")
  valid_402656712 = validateParameter(valid_402656712, JString,
                                      required = false, default = nil)
  if valid_402656712 != nil:
    section.add "X-Amz-Signature", valid_402656712
  var valid_402656713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656713 = validateParameter(valid_402656713, JString,
                                      required = false, default = nil)
  if valid_402656713 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656713
  var valid_402656714 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656714 = validateParameter(valid_402656714, JString,
                                      required = false, default = nil)
  if valid_402656714 != nil:
    section.add "X-Amz-Algorithm", valid_402656714
  var valid_402656715 = header.getOrDefault("X-Amz-Date")
  valid_402656715 = validateParameter(valid_402656715, JString,
                                      required = false, default = nil)
  if valid_402656715 != nil:
    section.add "X-Amz-Date", valid_402656715
  var valid_402656716 = header.getOrDefault("X-Amz-Credential")
  valid_402656716 = validateParameter(valid_402656716, JString,
                                      required = false, default = nil)
  if valid_402656716 != nil:
    section.add "X-Amz-Credential", valid_402656716
  var valid_402656717 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656717 = validateParameter(valid_402656717, JString,
                                      required = false, default = nil)
  if valid_402656717 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656717
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656718: Call_GetProposal_402656706; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns detailed information about a proposal.
                                                                                         ## 
  let valid = call_402656718.validator(path, query, header, formData, body, _)
  let scheme = call_402656718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656718.makeUrl(scheme.get, call_402656718.host, call_402656718.base,
                                   call_402656718.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656718, uri, valid, _)

proc call*(call_402656719: Call_GetProposal_402656706; networkId: string;
           proposalId: string): Recallable =
  ## getProposal
  ## Returns detailed information about a proposal.
  ##   networkId: string (required)
                                                   ##            : The unique identifier of the network for which the proposal is made.
  ##   
                                                                                                                                       ## proposalId: string (required)
                                                                                                                                       ##             
                                                                                                                                       ## : 
                                                                                                                                       ## The 
                                                                                                                                       ## unique 
                                                                                                                                       ## identifier 
                                                                                                                                       ## of 
                                                                                                                                       ## the 
                                                                                                                                       ## proposal.
  var path_402656720 = newJObject()
  add(path_402656720, "networkId", newJString(networkId))
  add(path_402656720, "proposalId", newJString(proposalId))
  result = call_402656719.call(path_402656720, nil, nil, nil, nil)

var getProposal* = Call_GetProposal_402656706(name: "getProposal",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals/{proposalId}",
    validator: validate_GetProposal_402656707, base: "/",
    makeUrl: url_GetProposal_402656708, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_402656721 = ref object of OpenApiRestCall_402656044
proc url_ListInvitations_402656723(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInvitations_402656722(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a listing of all invitations made on the specified network.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of invitations to return.
  ##   
                                                                                               ## nextToken: JString
                                                                                               ##            
                                                                                               ## : 
                                                                                               ## The 
                                                                                               ## pagination 
                                                                                               ## token 
                                                                                               ## that 
                                                                                               ## indicates 
                                                                                               ## the 
                                                                                               ## next 
                                                                                               ## set 
                                                                                               ## of 
                                                                                               ## results 
                                                                                               ## to 
                                                                                               ## retrieve.
  ##   
                                                                                                           ## MaxResults: JString
                                                                                                           ##             
                                                                                                           ## : 
                                                                                                           ## Pagination 
                                                                                                           ## limit
  ##   
                                                                                                                   ## NextToken: JString
                                                                                                                   ##            
                                                                                                                   ## : 
                                                                                                                   ## Pagination 
                                                                                                                   ## token
  section = newJObject()
  var valid_402656724 = query.getOrDefault("maxResults")
  valid_402656724 = validateParameter(valid_402656724, JInt, required = false,
                                      default = nil)
  if valid_402656724 != nil:
    section.add "maxResults", valid_402656724
  var valid_402656725 = query.getOrDefault("nextToken")
  valid_402656725 = validateParameter(valid_402656725, JString,
                                      required = false, default = nil)
  if valid_402656725 != nil:
    section.add "nextToken", valid_402656725
  var valid_402656726 = query.getOrDefault("MaxResults")
  valid_402656726 = validateParameter(valid_402656726, JString,
                                      required = false, default = nil)
  if valid_402656726 != nil:
    section.add "MaxResults", valid_402656726
  var valid_402656727 = query.getOrDefault("NextToken")
  valid_402656727 = validateParameter(valid_402656727, JString,
                                      required = false, default = nil)
  if valid_402656727 != nil:
    section.add "NextToken", valid_402656727
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656728 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656728 = validateParameter(valid_402656728, JString,
                                      required = false, default = nil)
  if valid_402656728 != nil:
    section.add "X-Amz-Security-Token", valid_402656728
  var valid_402656729 = header.getOrDefault("X-Amz-Signature")
  valid_402656729 = validateParameter(valid_402656729, JString,
                                      required = false, default = nil)
  if valid_402656729 != nil:
    section.add "X-Amz-Signature", valid_402656729
  var valid_402656730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656730 = validateParameter(valid_402656730, JString,
                                      required = false, default = nil)
  if valid_402656730 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656730
  var valid_402656731 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656731 = validateParameter(valid_402656731, JString,
                                      required = false, default = nil)
  if valid_402656731 != nil:
    section.add "X-Amz-Algorithm", valid_402656731
  var valid_402656732 = header.getOrDefault("X-Amz-Date")
  valid_402656732 = validateParameter(valid_402656732, JString,
                                      required = false, default = nil)
  if valid_402656732 != nil:
    section.add "X-Amz-Date", valid_402656732
  var valid_402656733 = header.getOrDefault("X-Amz-Credential")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-Credential", valid_402656733
  var valid_402656734 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656735: Call_ListInvitations_402656721; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a listing of all invitations made on the specified network.
                                                                                         ## 
  let valid = call_402656735.validator(path, query, header, formData, body, _)
  let scheme = call_402656735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656735.makeUrl(scheme.get, call_402656735.host, call_402656735.base,
                                   call_402656735.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656735, uri, valid, _)

proc call*(call_402656736: Call_ListInvitations_402656721; maxResults: int = 0;
           nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listInvitations
  ## Returns a listing of all invitations made on the specified network.
  ##   
                                                                        ## maxResults: int
                                                                        ##             
                                                                        ## : 
                                                                        ## The 
                                                                        ## maximum 
                                                                        ## number 
                                                                        ## of 
                                                                        ## invitations to 
                                                                        ## return.
  ##   
                                                                                  ## nextToken: string
                                                                                  ##            
                                                                                  ## : 
                                                                                  ## The 
                                                                                  ## pagination 
                                                                                  ## token 
                                                                                  ## that 
                                                                                  ## indicates 
                                                                                  ## the 
                                                                                  ## next 
                                                                                  ## set 
                                                                                  ## of 
                                                                                  ## results 
                                                                                  ## to 
                                                                                  ## retrieve.
  ##   
                                                                                              ## MaxResults: string
                                                                                              ##             
                                                                                              ## : 
                                                                                              ## Pagination 
                                                                                              ## limit
  ##   
                                                                                                      ## NextToken: string
                                                                                                      ##            
                                                                                                      ## : 
                                                                                                      ## Pagination 
                                                                                                      ## token
  var query_402656737 = newJObject()
  add(query_402656737, "maxResults", newJInt(maxResults))
  add(query_402656737, "nextToken", newJString(nextToken))
  add(query_402656737, "MaxResults", newJString(MaxResults))
  add(query_402656737, "NextToken", newJString(NextToken))
  result = call_402656736.call(nil, query_402656737, nil, nil, nil)

var listInvitations* = Call_ListInvitations_402656721(name: "listInvitations",
    meth: HttpMethod.HttpGet, host: "managedblockchain.amazonaws.com",
    route: "/invitations", validator: validate_ListInvitations_402656722,
    base: "/", makeUrl: url_ListInvitations_402656723,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_VoteOnProposal_402656758 = ref object of OpenApiRestCall_402656044
proc url_VoteOnProposal_402656760(protocol: Scheme; host: string; base: string;
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

proc validate_VoteOnProposal_402656759(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Casts a vote for a specified <code>ProposalId</code> on behalf of a member. The member to vote as, specified by <code>VoterMemberId</code>, must be in the same AWS account as the principal that calls the action.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   networkId: JString (required)
                                 ##            :  The unique identifier of the network. 
  ##   
                                                                                        ## proposalId: JString (required)
                                                                                        ##             
                                                                                        ## :  
                                                                                        ## The 
                                                                                        ## unique 
                                                                                        ## identifier 
                                                                                        ## of 
                                                                                        ## the 
                                                                                        ## proposal. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `networkId` field"
  var valid_402656761 = path.getOrDefault("networkId")
  valid_402656761 = validateParameter(valid_402656761, JString, required = true,
                                      default = nil)
  if valid_402656761 != nil:
    section.add "networkId", valid_402656761
  var valid_402656762 = path.getOrDefault("proposalId")
  valid_402656762 = validateParameter(valid_402656762, JString, required = true,
                                      default = nil)
  if valid_402656762 != nil:
    section.add "proposalId", valid_402656762
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656763 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656763 = validateParameter(valid_402656763, JString,
                                      required = false, default = nil)
  if valid_402656763 != nil:
    section.add "X-Amz-Security-Token", valid_402656763
  var valid_402656764 = header.getOrDefault("X-Amz-Signature")
  valid_402656764 = validateParameter(valid_402656764, JString,
                                      required = false, default = nil)
  if valid_402656764 != nil:
    section.add "X-Amz-Signature", valid_402656764
  var valid_402656765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656765
  var valid_402656766 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "X-Amz-Algorithm", valid_402656766
  var valid_402656767 = header.getOrDefault("X-Amz-Date")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "X-Amz-Date", valid_402656767
  var valid_402656768 = header.getOrDefault("X-Amz-Credential")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false, default = nil)
  if valid_402656768 != nil:
    section.add "X-Amz-Credential", valid_402656768
  var valid_402656769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656769
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656771: Call_VoteOnProposal_402656758; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Casts a vote for a specified <code>ProposalId</code> on behalf of a member. The member to vote as, specified by <code>VoterMemberId</code>, must be in the same AWS account as the principal that calls the action.
                                                                                         ## 
  let valid = call_402656771.validator(path, query, header, formData, body, _)
  let scheme = call_402656771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656771.makeUrl(scheme.get, call_402656771.host, call_402656771.base,
                                   call_402656771.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656771, uri, valid, _)

proc call*(call_402656772: Call_VoteOnProposal_402656758; networkId: string;
           body: JsonNode; proposalId: string): Recallable =
  ## voteOnProposal
  ## Casts a vote for a specified <code>ProposalId</code> on behalf of a member. The member to vote as, specified by <code>VoterMemberId</code>, must be in the same AWS account as the principal that calls the action.
  ##   
                                                                                                                                                                                                                        ## networkId: string (required)
                                                                                                                                                                                                                        ##            
                                                                                                                                                                                                                        ## :  
                                                                                                                                                                                                                        ## The 
                                                                                                                                                                                                                        ## unique 
                                                                                                                                                                                                                        ## identifier 
                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                        ## network. 
  ##   
                                                                                                                                                                                                                                    ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                               ## proposalId: string (required)
                                                                                                                                                                                                                                                               ##             
                                                                                                                                                                                                                                                               ## :  
                                                                                                                                                                                                                                                               ## The 
                                                                                                                                                                                                                                                               ## unique 
                                                                                                                                                                                                                                                               ## identifier 
                                                                                                                                                                                                                                                               ## of 
                                                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                                                               ## proposal. 
  var path_402656773 = newJObject()
  var body_402656774 = newJObject()
  add(path_402656773, "networkId", newJString(networkId))
  if body != nil:
    body_402656774 = body
  add(path_402656773, "proposalId", newJString(proposalId))
  result = call_402656772.call(path_402656773, nil, nil, nil, body_402656774)

var voteOnProposal* = Call_VoteOnProposal_402656758(name: "voteOnProposal",
    meth: HttpMethod.HttpPost, host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals/{proposalId}/votes",
    validator: validate_VoteOnProposal_402656759, base: "/",
    makeUrl: url_VoteOnProposal_402656760, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProposalVotes_402656738 = ref object of OpenApiRestCall_402656044
proc url_ListProposalVotes_402656740(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
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

proc validate_ListProposalVotes_402656739(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the listing of votes for a specified proposal, including the value of each vote and the unique identifier of the member that cast the vote.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   networkId: JString (required)
                                 ##            :  The unique identifier of the network. 
  ##   
                                                                                        ## proposalId: JString (required)
                                                                                        ##             
                                                                                        ## :  
                                                                                        ## The 
                                                                                        ## unique 
                                                                                        ## identifier 
                                                                                        ## of 
                                                                                        ## the 
                                                                                        ## proposal. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `networkId` field"
  var valid_402656741 = path.getOrDefault("networkId")
  valid_402656741 = validateParameter(valid_402656741, JString, required = true,
                                      default = nil)
  if valid_402656741 != nil:
    section.add "networkId", valid_402656741
  var valid_402656742 = path.getOrDefault("proposalId")
  valid_402656742 = validateParameter(valid_402656742, JString, required = true,
                                      default = nil)
  if valid_402656742 != nil:
    section.add "proposalId", valid_402656742
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             :  The maximum number of votes to return. 
  ##   
                                                                                           ## nextToken: JString
                                                                                           ##            
                                                                                           ## :  
                                                                                           ## The 
                                                                                           ## pagination 
                                                                                           ## token 
                                                                                           ## that 
                                                                                           ## indicates 
                                                                                           ## the 
                                                                                           ## next 
                                                                                           ## set 
                                                                                           ## of 
                                                                                           ## results 
                                                                                           ## to 
                                                                                           ## retrieve. 
  ##   
                                                                                                        ## MaxResults: JString
                                                                                                        ##             
                                                                                                        ## : 
                                                                                                        ## Pagination 
                                                                                                        ## limit
  ##   
                                                                                                                ## NextToken: JString
                                                                                                                ##            
                                                                                                                ## : 
                                                                                                                ## Pagination 
                                                                                                                ## token
  section = newJObject()
  var valid_402656743 = query.getOrDefault("maxResults")
  valid_402656743 = validateParameter(valid_402656743, JInt, required = false,
                                      default = nil)
  if valid_402656743 != nil:
    section.add "maxResults", valid_402656743
  var valid_402656744 = query.getOrDefault("nextToken")
  valid_402656744 = validateParameter(valid_402656744, JString,
                                      required = false, default = nil)
  if valid_402656744 != nil:
    section.add "nextToken", valid_402656744
  var valid_402656745 = query.getOrDefault("MaxResults")
  valid_402656745 = validateParameter(valid_402656745, JString,
                                      required = false, default = nil)
  if valid_402656745 != nil:
    section.add "MaxResults", valid_402656745
  var valid_402656746 = query.getOrDefault("NextToken")
  valid_402656746 = validateParameter(valid_402656746, JString,
                                      required = false, default = nil)
  if valid_402656746 != nil:
    section.add "NextToken", valid_402656746
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656747 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656747 = validateParameter(valid_402656747, JString,
                                      required = false, default = nil)
  if valid_402656747 != nil:
    section.add "X-Amz-Security-Token", valid_402656747
  var valid_402656748 = header.getOrDefault("X-Amz-Signature")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-Signature", valid_402656748
  var valid_402656749 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Algorithm", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-Date")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-Date", valid_402656751
  var valid_402656752 = header.getOrDefault("X-Amz-Credential")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Credential", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656753
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656754: Call_ListProposalVotes_402656738;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the listing of votes for a specified proposal, including the value of each vote and the unique identifier of the member that cast the vote.
                                                                                         ## 
  let valid = call_402656754.validator(path, query, header, formData, body, _)
  let scheme = call_402656754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656754.makeUrl(scheme.get, call_402656754.host, call_402656754.base,
                                   call_402656754.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656754, uri, valid, _)

proc call*(call_402656755: Call_ListProposalVotes_402656738; networkId: string;
           proposalId: string; maxResults: int = 0; nextToken: string = "";
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listProposalVotes
  ## Returns the listing of votes for a specified proposal, including the value of each vote and the unique identifier of the member that cast the vote.
  ##   
                                                                                                                                                        ## maxResults: int
                                                                                                                                                        ##             
                                                                                                                                                        ## :  
                                                                                                                                                        ## The 
                                                                                                                                                        ## maximum 
                                                                                                                                                        ## number 
                                                                                                                                                        ## of 
                                                                                                                                                        ## votes 
                                                                                                                                                        ## to 
                                                                                                                                                        ## return. 
  ##   
                                                                                                                                                                   ## networkId: string (required)
                                                                                                                                                                   ##            
                                                                                                                                                                   ## :  
                                                                                                                                                                   ## The 
                                                                                                                                                                   ## unique 
                                                                                                                                                                   ## identifier 
                                                                                                                                                                   ## of 
                                                                                                                                                                   ## the 
                                                                                                                                                                   ## network. 
  ##   
                                                                                                                                                                               ## nextToken: string
                                                                                                                                                                               ##            
                                                                                                                                                                               ## :  
                                                                                                                                                                               ## The 
                                                                                                                                                                               ## pagination 
                                                                                                                                                                               ## token 
                                                                                                                                                                               ## that 
                                                                                                                                                                               ## indicates 
                                                                                                                                                                               ## the 
                                                                                                                                                                               ## next 
                                                                                                                                                                               ## set 
                                                                                                                                                                               ## of 
                                                                                                                                                                               ## results 
                                                                                                                                                                               ## to 
                                                                                                                                                                               ## retrieve. 
  ##   
                                                                                                                                                                                            ## MaxResults: string
                                                                                                                                                                                            ##             
                                                                                                                                                                                            ## : 
                                                                                                                                                                                            ## Pagination 
                                                                                                                                                                                            ## limit
  ##   
                                                                                                                                                                                                    ## NextToken: string
                                                                                                                                                                                                    ##            
                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                    ## Pagination 
                                                                                                                                                                                                    ## token
  ##   
                                                                                                                                                                                                            ## proposalId: string (required)
                                                                                                                                                                                                            ##             
                                                                                                                                                                                                            ## :  
                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                            ## unique 
                                                                                                                                                                                                            ## identifier 
                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                            ## proposal. 
  var path_402656756 = newJObject()
  var query_402656757 = newJObject()
  add(query_402656757, "maxResults", newJInt(maxResults))
  add(path_402656756, "networkId", newJString(networkId))
  add(query_402656757, "nextToken", newJString(nextToken))
  add(query_402656757, "MaxResults", newJString(MaxResults))
  add(query_402656757, "NextToken", newJString(NextToken))
  add(path_402656756, "proposalId", newJString(proposalId))
  result = call_402656755.call(path_402656756, query_402656757, nil, nil, nil)

var listProposalVotes* = Call_ListProposalVotes_402656738(
    name: "listProposalVotes", meth: HttpMethod.HttpGet,
    host: "managedblockchain.amazonaws.com",
    route: "/networks/{networkId}/proposals/{proposalId}/votes",
    validator: validate_ListProposalVotes_402656739, base: "/",
    makeUrl: url_ListProposalVotes_402656740,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectInvitation_402656775 = ref object of OpenApiRestCall_402656044
proc url_RejectInvitation_402656777(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
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

proc validate_RejectInvitation_402656776(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656778 = path.getOrDefault("invitationId")
  valid_402656778 = validateParameter(valid_402656778, JString, required = true,
                                      default = nil)
  if valid_402656778 != nil:
    section.add "invitationId", valid_402656778
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656779 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656779 = validateParameter(valid_402656779, JString,
                                      required = false, default = nil)
  if valid_402656779 != nil:
    section.add "X-Amz-Security-Token", valid_402656779
  var valid_402656780 = header.getOrDefault("X-Amz-Signature")
  valid_402656780 = validateParameter(valid_402656780, JString,
                                      required = false, default = nil)
  if valid_402656780 != nil:
    section.add "X-Amz-Signature", valid_402656780
  var valid_402656781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656781 = validateParameter(valid_402656781, JString,
                                      required = false, default = nil)
  if valid_402656781 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656781
  var valid_402656782 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656782 = validateParameter(valid_402656782, JString,
                                      required = false, default = nil)
  if valid_402656782 != nil:
    section.add "X-Amz-Algorithm", valid_402656782
  var valid_402656783 = header.getOrDefault("X-Amz-Date")
  valid_402656783 = validateParameter(valid_402656783, JString,
                                      required = false, default = nil)
  if valid_402656783 != nil:
    section.add "X-Amz-Date", valid_402656783
  var valid_402656784 = header.getOrDefault("X-Amz-Credential")
  valid_402656784 = validateParameter(valid_402656784, JString,
                                      required = false, default = nil)
  if valid_402656784 != nil:
    section.add "X-Amz-Credential", valid_402656784
  var valid_402656785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656785 = validateParameter(valid_402656785, JString,
                                      required = false, default = nil)
  if valid_402656785 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656785
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656786: Call_RejectInvitation_402656775;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Rejects an invitation to join a network. This action can be called by a principal in an AWS account that has received an invitation to create a member and join a network.
                                                                                         ## 
  let valid = call_402656786.validator(path, query, header, formData, body, _)
  let scheme = call_402656786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656786.makeUrl(scheme.get, call_402656786.host, call_402656786.base,
                                   call_402656786.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656786, uri, valid, _)

proc call*(call_402656787: Call_RejectInvitation_402656775; invitationId: string): Recallable =
  ## rejectInvitation
  ## Rejects an invitation to join a network. This action can be called by a principal in an AWS account that has received an invitation to create a member and join a network.
  ##   
                                                                                                                                                                               ## invitationId: string (required)
                                                                                                                                                                               ##               
                                                                                                                                                                               ## : 
                                                                                                                                                                               ## The 
                                                                                                                                                                               ## unique 
                                                                                                                                                                               ## identifier 
                                                                                                                                                                               ## of 
                                                                                                                                                                               ## the 
                                                                                                                                                                               ## invitation 
                                                                                                                                                                               ## to 
                                                                                                                                                                               ## reject.
  var path_402656788 = newJObject()
  add(path_402656788, "invitationId", newJString(invitationId))
  result = call_402656787.call(path_402656788, nil, nil, nil, nil)

var rejectInvitation* = Call_RejectInvitation_402656775(
    name: "rejectInvitation", meth: HttpMethod.HttpDelete,
    host: "managedblockchain.amazonaws.com",
    route: "/invitations/{invitationId}", validator: validate_RejectInvitation_402656776,
    base: "/", makeUrl: url_RejectInvitation_402656777,
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}