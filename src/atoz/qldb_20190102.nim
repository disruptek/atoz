
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon QLDB
## version: 2019-01-02
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## The control plane for Amazon QLDB
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/qldb/
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

  OpenApiRestCall_402656038 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656038](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656038): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "qldb.ap-northeast-1.amazonaws.com", "ap-southeast-1": "qldb.ap-southeast-1.amazonaws.com",
                               "us-west-2": "qldb.us-west-2.amazonaws.com",
                               "eu-west-2": "qldb.eu-west-2.amazonaws.com", "ap-northeast-3": "qldb.ap-northeast-3.amazonaws.com", "eu-central-1": "qldb.eu-central-1.amazonaws.com",
                               "us-east-2": "qldb.us-east-2.amazonaws.com",
                               "us-east-1": "qldb.us-east-1.amazonaws.com", "cn-northwest-1": "qldb.cn-northwest-1.amazonaws.com.cn",
                               "ap-south-1": "qldb.ap-south-1.amazonaws.com",
                               "eu-north-1": "qldb.eu-north-1.amazonaws.com", "ap-northeast-2": "qldb.ap-northeast-2.amazonaws.com",
                               "us-west-1": "qldb.us-west-1.amazonaws.com", "us-gov-east-1": "qldb.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "qldb.eu-west-3.amazonaws.com", "cn-north-1": "qldb.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "qldb.sa-east-1.amazonaws.com",
                               "eu-west-1": "qldb.eu-west-1.amazonaws.com", "us-gov-west-1": "qldb.us-gov-west-1.amazonaws.com", "ap-southeast-2": "qldb.ap-southeast-2.amazonaws.com", "ca-central-1": "qldb.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "qldb.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "qldb.ap-southeast-1.amazonaws.com",
      "us-west-2": "qldb.us-west-2.amazonaws.com",
      "eu-west-2": "qldb.eu-west-2.amazonaws.com",
      "ap-northeast-3": "qldb.ap-northeast-3.amazonaws.com",
      "eu-central-1": "qldb.eu-central-1.amazonaws.com",
      "us-east-2": "qldb.us-east-2.amazonaws.com",
      "us-east-1": "qldb.us-east-1.amazonaws.com",
      "cn-northwest-1": "qldb.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "qldb.ap-south-1.amazonaws.com",
      "eu-north-1": "qldb.eu-north-1.amazonaws.com",
      "ap-northeast-2": "qldb.ap-northeast-2.amazonaws.com",
      "us-west-1": "qldb.us-west-1.amazonaws.com",
      "us-gov-east-1": "qldb.us-gov-east-1.amazonaws.com",
      "eu-west-3": "qldb.eu-west-3.amazonaws.com",
      "cn-north-1": "qldb.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "qldb.sa-east-1.amazonaws.com",
      "eu-west-1": "qldb.eu-west-1.amazonaws.com",
      "us-gov-west-1": "qldb.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "qldb.ap-southeast-2.amazonaws.com",
      "ca-central-1": "qldb.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "qldb"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateLedger_402656473 = ref object of OpenApiRestCall_402656038
proc url_CreateLedger_402656475(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateLedger_402656474(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new ledger in your AWS account.
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
  var valid_402656476 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656476 = validateParameter(valid_402656476, JString,
                                      required = false, default = nil)
  if valid_402656476 != nil:
    section.add "X-Amz-Security-Token", valid_402656476
  var valid_402656477 = header.getOrDefault("X-Amz-Signature")
  valid_402656477 = validateParameter(valid_402656477, JString,
                                      required = false, default = nil)
  if valid_402656477 != nil:
    section.add "X-Amz-Signature", valid_402656477
  var valid_402656478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656478 = validateParameter(valid_402656478, JString,
                                      required = false, default = nil)
  if valid_402656478 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656478
  var valid_402656479 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656479 = validateParameter(valid_402656479, JString,
                                      required = false, default = nil)
  if valid_402656479 != nil:
    section.add "X-Amz-Algorithm", valid_402656479
  var valid_402656480 = header.getOrDefault("X-Amz-Date")
  valid_402656480 = validateParameter(valid_402656480, JString,
                                      required = false, default = nil)
  if valid_402656480 != nil:
    section.add "X-Amz-Date", valid_402656480
  var valid_402656481 = header.getOrDefault("X-Amz-Credential")
  valid_402656481 = validateParameter(valid_402656481, JString,
                                      required = false, default = nil)
  if valid_402656481 != nil:
    section.add "X-Amz-Credential", valid_402656481
  var valid_402656482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656482 = validateParameter(valid_402656482, JString,
                                      required = false, default = nil)
  if valid_402656482 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656482
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

proc call*(call_402656484: Call_CreateLedger_402656473; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new ledger in your AWS account.
                                                                                         ## 
  let valid = call_402656484.validator(path, query, header, formData, body, _)
  let scheme = call_402656484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656484.makeUrl(scheme.get, call_402656484.host, call_402656484.base,
                                   call_402656484.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656484, uri, valid, _)

proc call*(call_402656485: Call_CreateLedger_402656473; body: JsonNode): Recallable =
  ## createLedger
  ## Creates a new ledger in your AWS account.
  ##   body: JObject (required)
  var body_402656486 = newJObject()
  if body != nil:
    body_402656486 = body
  result = call_402656485.call(nil, nil, nil, nil, body_402656486)

var createLedger* = Call_CreateLedger_402656473(name: "createLedger",
    meth: HttpMethod.HttpPost, host: "qldb.amazonaws.com", route: "/ledgers",
    validator: validate_CreateLedger_402656474, base: "/",
    makeUrl: url_CreateLedger_402656475, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLedgers_402656288 = ref object of OpenApiRestCall_402656038
proc url_ListLedgers_402656290(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLedgers_402656289(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns an array of ledger summaries that are associated with the current AWS account and Region.</p> <p>This action returns a maximum of 100 items and is paginated so that you can retrieve all the items by calling <code>ListLedgers</code> multiple times.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   max_results: JInt
                                  ##              : The maximum number of results to return in a single <code>ListLedgers</code> request. (The actual number of results returned might be fewer.)
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
  ##   
                                                                                                                                                                                                                 ## next_token: JString
                                                                                                                                                                                                                 ##             
                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                 ## A 
                                                                                                                                                                                                                 ## pagination 
                                                                                                                                                                                                                 ## token, 
                                                                                                                                                                                                                 ## indicating 
                                                                                                                                                                                                                 ## that 
                                                                                                                                                                                                                 ## you 
                                                                                                                                                                                                                 ## want 
                                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                                 ## retrieve 
                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                 ## next 
                                                                                                                                                                                                                 ## page 
                                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                                 ## results. 
                                                                                                                                                                                                                 ## If 
                                                                                                                                                                                                                 ## you 
                                                                                                                                                                                                                 ## received 
                                                                                                                                                                                                                 ## a 
                                                                                                                                                                                                                 ## value 
                                                                                                                                                                                                                 ## for 
                                                                                                                                                                                                                 ## <code>NextToken</code> 
                                                                                                                                                                                                                 ## in 
                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                 ## response 
                                                                                                                                                                                                                 ## from 
                                                                                                                                                                                                                 ## a 
                                                                                                                                                                                                                 ## previous 
                                                                                                                                                                                                                 ## <code>ListLedgers</code> 
                                                                                                                                                                                                                 ## call, 
                                                                                                                                                                                                                 ## then 
                                                                                                                                                                                                                 ## you 
                                                                                                                                                                                                                 ## should 
                                                                                                                                                                                                                 ## use 
                                                                                                                                                                                                                 ## that 
                                                                                                                                                                                                                 ## value 
                                                                                                                                                                                                                 ## as 
                                                                                                                                                                                                                 ## input 
                                                                                                                                                                                                                 ## here.
  section = newJObject()
  var valid_402656372 = query.getOrDefault("max_results")
  valid_402656372 = validateParameter(valid_402656372, JInt, required = false,
                                      default = nil)
  if valid_402656372 != nil:
    section.add "max_results", valid_402656372
  var valid_402656373 = query.getOrDefault("MaxResults")
  valid_402656373 = validateParameter(valid_402656373, JString,
                                      required = false, default = nil)
  if valid_402656373 != nil:
    section.add "MaxResults", valid_402656373
  var valid_402656374 = query.getOrDefault("NextToken")
  valid_402656374 = validateParameter(valid_402656374, JString,
                                      required = false, default = nil)
  if valid_402656374 != nil:
    section.add "NextToken", valid_402656374
  var valid_402656375 = query.getOrDefault("next_token")
  valid_402656375 = validateParameter(valid_402656375, JString,
                                      required = false, default = nil)
  if valid_402656375 != nil:
    section.add "next_token", valid_402656375
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
  var valid_402656376 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656376 = validateParameter(valid_402656376, JString,
                                      required = false, default = nil)
  if valid_402656376 != nil:
    section.add "X-Amz-Security-Token", valid_402656376
  var valid_402656377 = header.getOrDefault("X-Amz-Signature")
  valid_402656377 = validateParameter(valid_402656377, JString,
                                      required = false, default = nil)
  if valid_402656377 != nil:
    section.add "X-Amz-Signature", valid_402656377
  var valid_402656378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656378 = validateParameter(valid_402656378, JString,
                                      required = false, default = nil)
  if valid_402656378 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656378
  var valid_402656379 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656379 = validateParameter(valid_402656379, JString,
                                      required = false, default = nil)
  if valid_402656379 != nil:
    section.add "X-Amz-Algorithm", valid_402656379
  var valid_402656380 = header.getOrDefault("X-Amz-Date")
  valid_402656380 = validateParameter(valid_402656380, JString,
                                      required = false, default = nil)
  if valid_402656380 != nil:
    section.add "X-Amz-Date", valid_402656380
  var valid_402656381 = header.getOrDefault("X-Amz-Credential")
  valid_402656381 = validateParameter(valid_402656381, JString,
                                      required = false, default = nil)
  if valid_402656381 != nil:
    section.add "X-Amz-Credential", valid_402656381
  var valid_402656382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656382 = validateParameter(valid_402656382, JString,
                                      required = false, default = nil)
  if valid_402656382 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656396: Call_ListLedgers_402656288; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns an array of ledger summaries that are associated with the current AWS account and Region.</p> <p>This action returns a maximum of 100 items and is paginated so that you can retrieve all the items by calling <code>ListLedgers</code> multiple times.</p>
                                                                                         ## 
  let valid = call_402656396.validator(path, query, header, formData, body, _)
  let scheme = call_402656396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656396.makeUrl(scheme.get, call_402656396.host, call_402656396.base,
                                   call_402656396.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656396, uri, valid, _)

proc call*(call_402656445: Call_ListLedgers_402656288; maxResults: int = 0;
           MaxResults: string = ""; NextToken: string = "";
           nextToken: string = ""): Recallable =
  ## listLedgers
  ## <p>Returns an array of ledger summaries that are associated with the current AWS account and Region.</p> <p>This action returns a maximum of 100 items and is paginated so that you can retrieve all the items by calling <code>ListLedgers</code> multiple times.</p>
  ##   
                                                                                                                                                                                                                                                                           ## maxResults: int
                                                                                                                                                                                                                                                                           ##             
                                                                                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                                                                                           ## The 
                                                                                                                                                                                                                                                                           ## maximum 
                                                                                                                                                                                                                                                                           ## number 
                                                                                                                                                                                                                                                                           ## of 
                                                                                                                                                                                                                                                                           ## results 
                                                                                                                                                                                                                                                                           ## to 
                                                                                                                                                                                                                                                                           ## return 
                                                                                                                                                                                                                                                                           ## in 
                                                                                                                                                                                                                                                                           ## a 
                                                                                                                                                                                                                                                                           ## single 
                                                                                                                                                                                                                                                                           ## <code>ListLedgers</code> 
                                                                                                                                                                                                                                                                           ## request. 
                                                                                                                                                                                                                                                                           ## (The 
                                                                                                                                                                                                                                                                           ## actual 
                                                                                                                                                                                                                                                                           ## number 
                                                                                                                                                                                                                                                                           ## of 
                                                                                                                                                                                                                                                                           ## results 
                                                                                                                                                                                                                                                                           ## returned 
                                                                                                                                                                                                                                                                           ## might 
                                                                                                                                                                                                                                                                           ## be 
                                                                                                                                                                                                                                                                           ## fewer.)
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
                                                                                                                                                                                                                                                                                                     ## nextToken: string
                                                                                                                                                                                                                                                                                                     ##            
                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                     ## A 
                                                                                                                                                                                                                                                                                                     ## pagination 
                                                                                                                                                                                                                                                                                                     ## token, 
                                                                                                                                                                                                                                                                                                     ## indicating 
                                                                                                                                                                                                                                                                                                     ## that 
                                                                                                                                                                                                                                                                                                     ## you 
                                                                                                                                                                                                                                                                                                     ## want 
                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                     ## retrieve 
                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                     ## next 
                                                                                                                                                                                                                                                                                                     ## page 
                                                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                                                     ## results. 
                                                                                                                                                                                                                                                                                                     ## If 
                                                                                                                                                                                                                                                                                                     ## you 
                                                                                                                                                                                                                                                                                                     ## received 
                                                                                                                                                                                                                                                                                                     ## a 
                                                                                                                                                                                                                                                                                                     ## value 
                                                                                                                                                                                                                                                                                                     ## for 
                                                                                                                                                                                                                                                                                                     ## <code>NextToken</code> 
                                                                                                                                                                                                                                                                                                     ## in 
                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                     ## response 
                                                                                                                                                                                                                                                                                                     ## from 
                                                                                                                                                                                                                                                                                                     ## a 
                                                                                                                                                                                                                                                                                                     ## previous 
                                                                                                                                                                                                                                                                                                     ## <code>ListLedgers</code> 
                                                                                                                                                                                                                                                                                                     ## call, 
                                                                                                                                                                                                                                                                                                     ## then 
                                                                                                                                                                                                                                                                                                     ## you 
                                                                                                                                                                                                                                                                                                     ## should 
                                                                                                                                                                                                                                                                                                     ## use 
                                                                                                                                                                                                                                                                                                     ## that 
                                                                                                                                                                                                                                                                                                     ## value 
                                                                                                                                                                                                                                                                                                     ## as 
                                                                                                                                                                                                                                                                                                     ## input 
                                                                                                                                                                                                                                                                                                     ## here.
  var query_402656446 = newJObject()
  add(query_402656446, "max_results", newJInt(maxResults))
  add(query_402656446, "MaxResults", newJString(MaxResults))
  add(query_402656446, "NextToken", newJString(NextToken))
  add(query_402656446, "next_token", newJString(nextToken))
  result = call_402656445.call(nil, query_402656446, nil, nil, nil)

var listLedgers* = Call_ListLedgers_402656288(name: "listLedgers",
    meth: HttpMethod.HttpGet, host: "qldb.amazonaws.com", route: "/ledgers",
    validator: validate_ListLedgers_402656289, base: "/",
    makeUrl: url_ListLedgers_402656290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLedger_402656487 = ref object of OpenApiRestCall_402656038
proc url_DescribeLedger_402656489(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/ledgers/"),
                 (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeLedger_402656488(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about a ledger, including its state and when it was created.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the ledger that you want to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656501 = path.getOrDefault("name")
  valid_402656501 = validateParameter(valid_402656501, JString, required = true,
                                      default = nil)
  if valid_402656501 != nil:
    section.add "name", valid_402656501
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
  var valid_402656502 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-Security-Token", valid_402656502
  var valid_402656503 = header.getOrDefault("X-Amz-Signature")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-Signature", valid_402656503
  var valid_402656504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656504
  var valid_402656505 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "X-Amz-Algorithm", valid_402656505
  var valid_402656506 = header.getOrDefault("X-Amz-Date")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-Date", valid_402656506
  var valid_402656507 = header.getOrDefault("X-Amz-Credential")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Credential", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656509: Call_DescribeLedger_402656487; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a ledger, including its state and when it was created.
                                                                                         ## 
  let valid = call_402656509.validator(path, query, header, formData, body, _)
  let scheme = call_402656509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656509.makeUrl(scheme.get, call_402656509.host, call_402656509.base,
                                   call_402656509.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656509, uri, valid, _)

proc call*(call_402656510: Call_DescribeLedger_402656487; name: string): Recallable =
  ## describeLedger
  ## Returns information about a ledger, including its state and when it was created.
  ##   
                                                                                     ## name: string (required)
                                                                                     ##       
                                                                                     ## : 
                                                                                     ## The 
                                                                                     ## name 
                                                                                     ## of 
                                                                                     ## the 
                                                                                     ## ledger 
                                                                                     ## that 
                                                                                     ## you 
                                                                                     ## want 
                                                                                     ## to 
                                                                                     ## describe.
  var path_402656511 = newJObject()
  add(path_402656511, "name", newJString(name))
  result = call_402656510.call(path_402656511, nil, nil, nil, nil)

var describeLedger* = Call_DescribeLedger_402656487(name: "describeLedger",
    meth: HttpMethod.HttpGet, host: "qldb.amazonaws.com",
    route: "/ledgers/{name}", validator: validate_DescribeLedger_402656488,
    base: "/", makeUrl: url_DescribeLedger_402656489,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLedger_402656526 = ref object of OpenApiRestCall_402656038
proc url_UpdateLedger_402656528(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/ledgers/"),
                 (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateLedger_402656527(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates properties on a ledger.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the ledger.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656529 = path.getOrDefault("name")
  valid_402656529 = validateParameter(valid_402656529, JString, required = true,
                                      default = nil)
  if valid_402656529 != nil:
    section.add "name", valid_402656529
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
  var valid_402656530 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656530 = validateParameter(valid_402656530, JString,
                                      required = false, default = nil)
  if valid_402656530 != nil:
    section.add "X-Amz-Security-Token", valid_402656530
  var valid_402656531 = header.getOrDefault("X-Amz-Signature")
  valid_402656531 = validateParameter(valid_402656531, JString,
                                      required = false, default = nil)
  if valid_402656531 != nil:
    section.add "X-Amz-Signature", valid_402656531
  var valid_402656532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656532 = validateParameter(valid_402656532, JString,
                                      required = false, default = nil)
  if valid_402656532 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656532
  var valid_402656533 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656533 = validateParameter(valid_402656533, JString,
                                      required = false, default = nil)
  if valid_402656533 != nil:
    section.add "X-Amz-Algorithm", valid_402656533
  var valid_402656534 = header.getOrDefault("X-Amz-Date")
  valid_402656534 = validateParameter(valid_402656534, JString,
                                      required = false, default = nil)
  if valid_402656534 != nil:
    section.add "X-Amz-Date", valid_402656534
  var valid_402656535 = header.getOrDefault("X-Amz-Credential")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "X-Amz-Credential", valid_402656535
  var valid_402656536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false, default = nil)
  if valid_402656536 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656536
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

proc call*(call_402656538: Call_UpdateLedger_402656526; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates properties on a ledger.
                                                                                         ## 
  let valid = call_402656538.validator(path, query, header, formData, body, _)
  let scheme = call_402656538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656538.makeUrl(scheme.get, call_402656538.host, call_402656538.base,
                                   call_402656538.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656538, uri, valid, _)

proc call*(call_402656539: Call_UpdateLedger_402656526; name: string;
           body: JsonNode): Recallable =
  ## updateLedger
  ## Updates properties on a ledger.
  ##   name: string (required)
                                    ##       : The name of the ledger.
  ##   body: JObject (required)
  var path_402656540 = newJObject()
  var body_402656541 = newJObject()
  add(path_402656540, "name", newJString(name))
  if body != nil:
    body_402656541 = body
  result = call_402656539.call(path_402656540, nil, nil, nil, body_402656541)

var updateLedger* = Call_UpdateLedger_402656526(name: "updateLedger",
    meth: HttpMethod.HttpPatch, host: "qldb.amazonaws.com",
    route: "/ledgers/{name}", validator: validate_UpdateLedger_402656527,
    base: "/", makeUrl: url_UpdateLedger_402656528,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLedger_402656512 = ref object of OpenApiRestCall_402656038
proc url_DeleteLedger_402656514(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/ledgers/"),
                 (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteLedger_402656513(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes a ledger and all of its contents. This action is irreversible.</p> <p>If deletion protection is enabled, you must first disable it before you can delete the ledger using the QLDB API or the AWS Command Line Interface (AWS CLI). You can disable it by calling the <code>UpdateLedger</code> operation to set the flag to <code>false</code>. The QLDB console disables deletion protection for you when you use it to delete a ledger.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the ledger that you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656515 = path.getOrDefault("name")
  valid_402656515 = validateParameter(valid_402656515, JString, required = true,
                                      default = nil)
  if valid_402656515 != nil:
    section.add "name", valid_402656515
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
  var valid_402656516 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656516 = validateParameter(valid_402656516, JString,
                                      required = false, default = nil)
  if valid_402656516 != nil:
    section.add "X-Amz-Security-Token", valid_402656516
  var valid_402656517 = header.getOrDefault("X-Amz-Signature")
  valid_402656517 = validateParameter(valid_402656517, JString,
                                      required = false, default = nil)
  if valid_402656517 != nil:
    section.add "X-Amz-Signature", valid_402656517
  var valid_402656518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656518 = validateParameter(valid_402656518, JString,
                                      required = false, default = nil)
  if valid_402656518 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656518
  var valid_402656519 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "X-Amz-Algorithm", valid_402656519
  var valid_402656520 = header.getOrDefault("X-Amz-Date")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-Date", valid_402656520
  var valid_402656521 = header.getOrDefault("X-Amz-Credential")
  valid_402656521 = validateParameter(valid_402656521, JString,
                                      required = false, default = nil)
  if valid_402656521 != nil:
    section.add "X-Amz-Credential", valid_402656521
  var valid_402656522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656522 = validateParameter(valid_402656522, JString,
                                      required = false, default = nil)
  if valid_402656522 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656523: Call_DeleteLedger_402656512; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a ledger and all of its contents. This action is irreversible.</p> <p>If deletion protection is enabled, you must first disable it before you can delete the ledger using the QLDB API or the AWS Command Line Interface (AWS CLI). You can disable it by calling the <code>UpdateLedger</code> operation to set the flag to <code>false</code>. The QLDB console disables deletion protection for you when you use it to delete a ledger.</p>
                                                                                         ## 
  let valid = call_402656523.validator(path, query, header, formData, body, _)
  let scheme = call_402656523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656523.makeUrl(scheme.get, call_402656523.host, call_402656523.base,
                                   call_402656523.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656523, uri, valid, _)

proc call*(call_402656524: Call_DeleteLedger_402656512; name: string): Recallable =
  ## deleteLedger
  ## <p>Deletes a ledger and all of its contents. This action is irreversible.</p> <p>If deletion protection is enabled, you must first disable it before you can delete the ledger using the QLDB API or the AWS Command Line Interface (AWS CLI). You can disable it by calling the <code>UpdateLedger</code> operation to set the flag to <code>false</code>. The QLDB console disables deletion protection for you when you use it to delete a ledger.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## name: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ##       
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## ledger 
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## delete.
  var path_402656525 = newJObject()
  add(path_402656525, "name", newJString(name))
  result = call_402656524.call(path_402656525, nil, nil, nil, nil)

var deleteLedger* = Call_DeleteLedger_402656512(name: "deleteLedger",
    meth: HttpMethod.HttpDelete, host: "qldb.amazonaws.com",
    route: "/ledgers/{name}", validator: validate_DeleteLedger_402656513,
    base: "/", makeUrl: url_DeleteLedger_402656514,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJournalS3Export_402656542 = ref object of OpenApiRestCall_402656038
proc url_DescribeJournalS3Export_402656544(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  assert "exportId" in path, "`exportId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/ledgers/"),
                 (kind: VariableSegment, value: "name"),
                 (kind: ConstantSegment, value: "/journal-s3-exports/"),
                 (kind: VariableSegment, value: "exportId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeJournalS3Export_402656543(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns information about a journal export job, including the ledger name, export ID, when it was created, current status, and its start and end time export parameters.</p> <p>If the export job with the given <code>ExportId</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p> <p>If the ledger with the given <code>Name</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the ledger.
  ##   exportId: JString (required)
                                                                   ##           : The unique ID of the journal export job that you want to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656545 = path.getOrDefault("name")
  valid_402656545 = validateParameter(valid_402656545, JString, required = true,
                                      default = nil)
  if valid_402656545 != nil:
    section.add "name", valid_402656545
  var valid_402656546 = path.getOrDefault("exportId")
  valid_402656546 = validateParameter(valid_402656546, JString, required = true,
                                      default = nil)
  if valid_402656546 != nil:
    section.add "exportId", valid_402656546
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
  var valid_402656547 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-Security-Token", valid_402656547
  var valid_402656548 = header.getOrDefault("X-Amz-Signature")
  valid_402656548 = validateParameter(valid_402656548, JString,
                                      required = false, default = nil)
  if valid_402656548 != nil:
    section.add "X-Amz-Signature", valid_402656548
  var valid_402656549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656549
  var valid_402656550 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "X-Amz-Algorithm", valid_402656550
  var valid_402656551 = header.getOrDefault("X-Amz-Date")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "X-Amz-Date", valid_402656551
  var valid_402656552 = header.getOrDefault("X-Amz-Credential")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "X-Amz-Credential", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656554: Call_DescribeJournalS3Export_402656542;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns information about a journal export job, including the ledger name, export ID, when it was created, current status, and its start and end time export parameters.</p> <p>If the export job with the given <code>ExportId</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p> <p>If the ledger with the given <code>Name</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p>
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

proc call*(call_402656555: Call_DescribeJournalS3Export_402656542; name: string;
           exportId: string): Recallable =
  ## describeJournalS3Export
  ## <p>Returns information about a journal export job, including the ledger name, export ID, when it was created, current status, and its start and end time export parameters.</p> <p>If the export job with the given <code>ExportId</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p> <p>If the ledger with the given <code>Name</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                              ## name: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                              ##       
                                                                                                                                                                                                                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                              ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                              ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                              ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                              ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                              ## ledger.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## exportId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ##           
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## unique 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## ID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## journal 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## export 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## job 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## describe.
  var path_402656556 = newJObject()
  add(path_402656556, "name", newJString(name))
  add(path_402656556, "exportId", newJString(exportId))
  result = call_402656555.call(path_402656556, nil, nil, nil, nil)

var describeJournalS3Export* = Call_DescribeJournalS3Export_402656542(
    name: "describeJournalS3Export", meth: HttpMethod.HttpGet,
    host: "qldb.amazonaws.com",
    route: "/ledgers/{name}/journal-s3-exports/{exportId}",
    validator: validate_DescribeJournalS3Export_402656543, base: "/",
    makeUrl: url_DescribeJournalS3Export_402656544,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportJournalToS3_402656576 = ref object of OpenApiRestCall_402656038
proc url_ExportJournalToS3_402656578(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/ledgers/"),
                 (kind: VariableSegment, value: "name"),
                 (kind: ConstantSegment, value: "/journal-s3-exports")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ExportJournalToS3_402656577(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Exports journal contents within a date and time range from a ledger into a specified Amazon Simple Storage Service (Amazon S3) bucket. The data is written as files in Amazon Ion format.</p> <p>If the ledger with the given <code>Name</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p> <p>If the ledger with the given <code>Name</code> is in <code>CREATING</code> status, then throws <code>ResourcePreconditionNotMetException</code>.</p> <p>You can initiate up to two concurrent journal export requests for each ledger. Beyond this limit, journal export requests throw <code>LimitExceededException</code>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the ledger.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656579 = path.getOrDefault("name")
  valid_402656579 = validateParameter(valid_402656579, JString, required = true,
                                      default = nil)
  if valid_402656579 != nil:
    section.add "name", valid_402656579
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
  var valid_402656580 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656580 = validateParameter(valid_402656580, JString,
                                      required = false, default = nil)
  if valid_402656580 != nil:
    section.add "X-Amz-Security-Token", valid_402656580
  var valid_402656581 = header.getOrDefault("X-Amz-Signature")
  valid_402656581 = validateParameter(valid_402656581, JString,
                                      required = false, default = nil)
  if valid_402656581 != nil:
    section.add "X-Amz-Signature", valid_402656581
  var valid_402656582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656582 = validateParameter(valid_402656582, JString,
                                      required = false, default = nil)
  if valid_402656582 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Algorithm", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Date")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Date", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Credential")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Credential", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656586
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

proc call*(call_402656588: Call_ExportJournalToS3_402656576;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Exports journal contents within a date and time range from a ledger into a specified Amazon Simple Storage Service (Amazon S3) bucket. The data is written as files in Amazon Ion format.</p> <p>If the ledger with the given <code>Name</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p> <p>If the ledger with the given <code>Name</code> is in <code>CREATING</code> status, then throws <code>ResourcePreconditionNotMetException</code>.</p> <p>You can initiate up to two concurrent journal export requests for each ledger. Beyond this limit, journal export requests throw <code>LimitExceededException</code>.</p>
                                                                                         ## 
  let valid = call_402656588.validator(path, query, header, formData, body, _)
  let scheme = call_402656588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656588.makeUrl(scheme.get, call_402656588.host, call_402656588.base,
                                   call_402656588.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656588, uri, valid, _)

proc call*(call_402656589: Call_ExportJournalToS3_402656576; name: string;
           body: JsonNode): Recallable =
  ## exportJournalToS3
  ## <p>Exports journal contents within a date and time range from a ledger into a specified Amazon Simple Storage Service (Amazon S3) bucket. The data is written as files in Amazon Ion format.</p> <p>If the ledger with the given <code>Name</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p> <p>If the ledger with the given <code>Name</code> is in <code>CREATING</code> status, then throws <code>ResourcePreconditionNotMetException</code>.</p> <p>You can initiate up to two concurrent journal export requests for each ledger. Beyond this limit, journal export requests throw <code>LimitExceededException</code>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## name: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ##       
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## ledger.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var path_402656590 = newJObject()
  var body_402656591 = newJObject()
  add(path_402656590, "name", newJString(name))
  if body != nil:
    body_402656591 = body
  result = call_402656589.call(path_402656590, nil, nil, nil, body_402656591)

var exportJournalToS3* = Call_ExportJournalToS3_402656576(
    name: "exportJournalToS3", meth: HttpMethod.HttpPost,
    host: "qldb.amazonaws.com", route: "/ledgers/{name}/journal-s3-exports",
    validator: validate_ExportJournalToS3_402656577, base: "/",
    makeUrl: url_ExportJournalToS3_402656578,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJournalS3ExportsForLedger_402656557 = ref object of OpenApiRestCall_402656038
proc url_ListJournalS3ExportsForLedger_402656559(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/ledgers/"),
                 (kind: VariableSegment, value: "name"),
                 (kind: ConstantSegment, value: "/journal-s3-exports")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListJournalS3ExportsForLedger_402656558(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Returns an array of journal export job descriptions for a specified ledger.</p> <p>This action returns a maximum of <code>MaxResults</code> items, and is paginated so that you can retrieve all the items by calling <code>ListJournalS3ExportsForLedger</code> multiple times.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the ledger.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656560 = path.getOrDefault("name")
  valid_402656560 = validateParameter(valid_402656560, JString, required = true,
                                      default = nil)
  if valid_402656560 != nil:
    section.add "name", valid_402656560
  result.add "path", section
  ## parameters in `query` object:
  ##   max_results: JInt
                                  ##              : The maximum number of results to return in a single <code>ListJournalS3ExportsForLedger</code> request. (The actual number of results returned might be fewer.)
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
  ##   
                                                                                                                                                                                                                                   ## next_token: JString
                                                                                                                                                                                                                                   ##             
                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                   ## A 
                                                                                                                                                                                                                                   ## pagination 
                                                                                                                                                                                                                                   ## token, 
                                                                                                                                                                                                                                   ## indicating 
                                                                                                                                                                                                                                   ## that 
                                                                                                                                                                                                                                   ## you 
                                                                                                                                                                                                                                   ## want 
                                                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                                                   ## retrieve 
                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                   ## next 
                                                                                                                                                                                                                                   ## page 
                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                   ## results. 
                                                                                                                                                                                                                                   ## If 
                                                                                                                                                                                                                                   ## you 
                                                                                                                                                                                                                                   ## received 
                                                                                                                                                                                                                                   ## a 
                                                                                                                                                                                                                                   ## value 
                                                                                                                                                                                                                                   ## for 
                                                                                                                                                                                                                                   ## <code>NextToken</code> 
                                                                                                                                                                                                                                   ## in 
                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                   ## response 
                                                                                                                                                                                                                                   ## from 
                                                                                                                                                                                                                                   ## a 
                                                                                                                                                                                                                                   ## previous 
                                                                                                                                                                                                                                   ## <code>ListJournalS3ExportsForLedger</code> 
                                                                                                                                                                                                                                   ## call, 
                                                                                                                                                                                                                                   ## then 
                                                                                                                                                                                                                                   ## you 
                                                                                                                                                                                                                                   ## should 
                                                                                                                                                                                                                                   ## use 
                                                                                                                                                                                                                                   ## that 
                                                                                                                                                                                                                                   ## value 
                                                                                                                                                                                                                                   ## as 
                                                                                                                                                                                                                                   ## input 
                                                                                                                                                                                                                                   ## here.
  section = newJObject()
  var valid_402656561 = query.getOrDefault("max_results")
  valid_402656561 = validateParameter(valid_402656561, JInt, required = false,
                                      default = nil)
  if valid_402656561 != nil:
    section.add "max_results", valid_402656561
  var valid_402656562 = query.getOrDefault("MaxResults")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "MaxResults", valid_402656562
  var valid_402656563 = query.getOrDefault("NextToken")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "NextToken", valid_402656563
  var valid_402656564 = query.getOrDefault("next_token")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "next_token", valid_402656564
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
  var valid_402656565 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656565 = validateParameter(valid_402656565, JString,
                                      required = false, default = nil)
  if valid_402656565 != nil:
    section.add "X-Amz-Security-Token", valid_402656565
  var valid_402656566 = header.getOrDefault("X-Amz-Signature")
  valid_402656566 = validateParameter(valid_402656566, JString,
                                      required = false, default = nil)
  if valid_402656566 != nil:
    section.add "X-Amz-Signature", valid_402656566
  var valid_402656567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656567 = validateParameter(valid_402656567, JString,
                                      required = false, default = nil)
  if valid_402656567 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Algorithm", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Date")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Date", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Credential")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Credential", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656572: Call_ListJournalS3ExportsForLedger_402656557;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns an array of journal export job descriptions for a specified ledger.</p> <p>This action returns a maximum of <code>MaxResults</code> items, and is paginated so that you can retrieve all the items by calling <code>ListJournalS3ExportsForLedger</code> multiple times.</p>
                                                                                         ## 
  let valid = call_402656572.validator(path, query, header, formData, body, _)
  let scheme = call_402656572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656572.makeUrl(scheme.get, call_402656572.host, call_402656572.base,
                                   call_402656572.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656572, uri, valid, _)

proc call*(call_402656573: Call_ListJournalS3ExportsForLedger_402656557;
           name: string; maxResults: int = 0; MaxResults: string = "";
           NextToken: string = ""; nextToken: string = ""): Recallable =
  ## listJournalS3ExportsForLedger
  ## <p>Returns an array of journal export job descriptions for a specified ledger.</p> <p>This action returns a maximum of <code>MaxResults</code> items, and is paginated so that you can retrieve all the items by calling <code>ListJournalS3ExportsForLedger</code> multiple times.</p>
  ##   
                                                                                                                                                                                                                                                                                            ## maxResults: int
                                                                                                                                                                                                                                                                                            ##             
                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                                                                                            ## maximum 
                                                                                                                                                                                                                                                                                            ## number 
                                                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                                                            ## results 
                                                                                                                                                                                                                                                                                            ## to 
                                                                                                                                                                                                                                                                                            ## return 
                                                                                                                                                                                                                                                                                            ## in 
                                                                                                                                                                                                                                                                                            ## a 
                                                                                                                                                                                                                                                                                            ## single 
                                                                                                                                                                                                                                                                                            ## <code>ListJournalS3ExportsForLedger</code> 
                                                                                                                                                                                                                                                                                            ## request. 
                                                                                                                                                                                                                                                                                            ## (The 
                                                                                                                                                                                                                                                                                            ## actual 
                                                                                                                                                                                                                                                                                            ## number 
                                                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                                                            ## results 
                                                                                                                                                                                                                                                                                            ## returned 
                                                                                                                                                                                                                                                                                            ## might 
                                                                                                                                                                                                                                                                                            ## be 
                                                                                                                                                                                                                                                                                            ## fewer.)
  ##   
                                                                                                                                                                                                                                                                                                      ## name: string (required)
                                                                                                                                                                                                                                                                                                      ##       
                                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                                      ## The 
                                                                                                                                                                                                                                                                                                      ## name 
                                                                                                                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                      ## ledger.
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
                                                                                                                                                                                                                                                                                                                                ## nextToken: string
                                                                                                                                                                                                                                                                                                                                ##            
                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                ## A 
                                                                                                                                                                                                                                                                                                                                ## pagination 
                                                                                                                                                                                                                                                                                                                                ## token, 
                                                                                                                                                                                                                                                                                                                                ## indicating 
                                                                                                                                                                                                                                                                                                                                ## that 
                                                                                                                                                                                                                                                                                                                                ## you 
                                                                                                                                                                                                                                                                                                                                ## want 
                                                                                                                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                                                                                                                ## retrieve 
                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                ## next 
                                                                                                                                                                                                                                                                                                                                ## page 
                                                                                                                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                                                                                                                ## results. 
                                                                                                                                                                                                                                                                                                                                ## If 
                                                                                                                                                                                                                                                                                                                                ## you 
                                                                                                                                                                                                                                                                                                                                ## received 
                                                                                                                                                                                                                                                                                                                                ## a 
                                                                                                                                                                                                                                                                                                                                ## value 
                                                                                                                                                                                                                                                                                                                                ## for 
                                                                                                                                                                                                                                                                                                                                ## <code>NextToken</code> 
                                                                                                                                                                                                                                                                                                                                ## in 
                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                ## response 
                                                                                                                                                                                                                                                                                                                                ## from 
                                                                                                                                                                                                                                                                                                                                ## a 
                                                                                                                                                                                                                                                                                                                                ## previous 
                                                                                                                                                                                                                                                                                                                                ## <code>ListJournalS3ExportsForLedger</code> 
                                                                                                                                                                                                                                                                                                                                ## call, 
                                                                                                                                                                                                                                                                                                                                ## then 
                                                                                                                                                                                                                                                                                                                                ## you 
                                                                                                                                                                                                                                                                                                                                ## should 
                                                                                                                                                                                                                                                                                                                                ## use 
                                                                                                                                                                                                                                                                                                                                ## that 
                                                                                                                                                                                                                                                                                                                                ## value 
                                                                                                                                                                                                                                                                                                                                ## as 
                                                                                                                                                                                                                                                                                                                                ## input 
                                                                                                                                                                                                                                                                                                                                ## here.
  var path_402656574 = newJObject()
  var query_402656575 = newJObject()
  add(query_402656575, "max_results", newJInt(maxResults))
  add(path_402656574, "name", newJString(name))
  add(query_402656575, "MaxResults", newJString(MaxResults))
  add(query_402656575, "NextToken", newJString(NextToken))
  add(query_402656575, "next_token", newJString(nextToken))
  result = call_402656573.call(path_402656574, query_402656575, nil, nil, nil)

var listJournalS3ExportsForLedger* = Call_ListJournalS3ExportsForLedger_402656557(
    name: "listJournalS3ExportsForLedger", meth: HttpMethod.HttpGet,
    host: "qldb.amazonaws.com", route: "/ledgers/{name}/journal-s3-exports",
    validator: validate_ListJournalS3ExportsForLedger_402656558, base: "/",
    makeUrl: url_ListJournalS3ExportsForLedger_402656559,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBlock_402656592 = ref object of OpenApiRestCall_402656038
proc url_GetBlock_402656594(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/ledgers/"),
                 (kind: VariableSegment, value: "name"),
                 (kind: ConstantSegment, value: "/block")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBlock_402656593(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns a journal block object at a specified address in a ledger. Also returns a proof of the specified block for verification if <code>DigestTipAddress</code> is provided.</p> <p>If the specified ledger doesn't exist or is in <code>DELETING</code> status, then throws <code>ResourceNotFoundException</code>.</p> <p>If the specified ledger is in <code>CREATING</code> status, then throws <code>ResourcePreconditionNotMetException</code>.</p> <p>If no block exists with the specified address, then throws <code>InvalidParameterException</code>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the ledger.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656595 = path.getOrDefault("name")
  valid_402656595 = validateParameter(valid_402656595, JString, required = true,
                                      default = nil)
  if valid_402656595 != nil:
    section.add "name", valid_402656595
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
  var valid_402656596 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656596 = validateParameter(valid_402656596, JString,
                                      required = false, default = nil)
  if valid_402656596 != nil:
    section.add "X-Amz-Security-Token", valid_402656596
  var valid_402656597 = header.getOrDefault("X-Amz-Signature")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-Signature", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Algorithm", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Date")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Date", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Credential")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Credential", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656602
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

proc call*(call_402656604: Call_GetBlock_402656592; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a journal block object at a specified address in a ledger. Also returns a proof of the specified block for verification if <code>DigestTipAddress</code> is provided.</p> <p>If the specified ledger doesn't exist or is in <code>DELETING</code> status, then throws <code>ResourceNotFoundException</code>.</p> <p>If the specified ledger is in <code>CREATING</code> status, then throws <code>ResourcePreconditionNotMetException</code>.</p> <p>If no block exists with the specified address, then throws <code>InvalidParameterException</code>.</p>
                                                                                         ## 
  let valid = call_402656604.validator(path, query, header, formData, body, _)
  let scheme = call_402656604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656604.makeUrl(scheme.get, call_402656604.host, call_402656604.base,
                                   call_402656604.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656604, uri, valid, _)

proc call*(call_402656605: Call_GetBlock_402656592; name: string; body: JsonNode): Recallable =
  ## getBlock
  ## <p>Returns a journal block object at a specified address in a ledger. Also returns a proof of the specified block for verification if <code>DigestTipAddress</code> is provided.</p> <p>If the specified ledger doesn't exist or is in <code>DELETING</code> status, then throws <code>ResourceNotFoundException</code>.</p> <p>If the specified ledger is in <code>CREATING</code> status, then throws <code>ResourcePreconditionNotMetException</code>.</p> <p>If no block exists with the specified address, then throws <code>InvalidParameterException</code>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## name: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ##       
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## ledger.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var path_402656606 = newJObject()
  var body_402656607 = newJObject()
  add(path_402656606, "name", newJString(name))
  if body != nil:
    body_402656607 = body
  result = call_402656605.call(path_402656606, nil, nil, nil, body_402656607)

var getBlock* = Call_GetBlock_402656592(name: "getBlock",
                                        meth: HttpMethod.HttpPost,
                                        host: "qldb.amazonaws.com",
                                        route: "/ledgers/{name}/block",
                                        validator: validate_GetBlock_402656593,
                                        base: "/", makeUrl: url_GetBlock_402656594,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDigest_402656608 = ref object of OpenApiRestCall_402656038
proc url_GetDigest_402656610(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/ledgers/"),
                 (kind: VariableSegment, value: "name"),
                 (kind: ConstantSegment, value: "/digest")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDigest_402656609(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the digest of a ledger at the latest committed block in the journal. The response includes a 256-bit hash value and a block address.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the ledger.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656611 = path.getOrDefault("name")
  valid_402656611 = validateParameter(valid_402656611, JString, required = true,
                                      default = nil)
  if valid_402656611 != nil:
    section.add "name", valid_402656611
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
  var valid_402656612 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656612 = validateParameter(valid_402656612, JString,
                                      required = false, default = nil)
  if valid_402656612 != nil:
    section.add "X-Amz-Security-Token", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Signature")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Signature", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Algorithm", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Date")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Date", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-Credential")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Credential", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656618
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656619: Call_GetDigest_402656608; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the digest of a ledger at the latest committed block in the journal. The response includes a 256-bit hash value and a block address.
                                                                                         ## 
  let valid = call_402656619.validator(path, query, header, formData, body, _)
  let scheme = call_402656619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656619.makeUrl(scheme.get, call_402656619.host, call_402656619.base,
                                   call_402656619.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656619, uri, valid, _)

proc call*(call_402656620: Call_GetDigest_402656608; name: string): Recallable =
  ## getDigest
  ## Returns the digest of a ledger at the latest committed block in the journal. The response includes a 256-bit hash value and a block address.
  ##   
                                                                                                                                                 ## name: string (required)
                                                                                                                                                 ##       
                                                                                                                                                 ## : 
                                                                                                                                                 ## The 
                                                                                                                                                 ## name 
                                                                                                                                                 ## of 
                                                                                                                                                 ## the 
                                                                                                                                                 ## ledger.
  var path_402656621 = newJObject()
  add(path_402656621, "name", newJString(name))
  result = call_402656620.call(path_402656621, nil, nil, nil, nil)

var getDigest* = Call_GetDigest_402656608(name: "getDigest",
    meth: HttpMethod.HttpPost, host: "qldb.amazonaws.com",
    route: "/ledgers/{name}/digest", validator: validate_GetDigest_402656609,
    base: "/", makeUrl: url_GetDigest_402656610,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevision_402656622 = ref object of OpenApiRestCall_402656038
proc url_GetRevision_402656624(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/ledgers/"),
                 (kind: VariableSegment, value: "name"),
                 (kind: ConstantSegment, value: "/revision")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRevision_402656623(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a revision data object for a specified document ID and block address. Also returns a proof of the specified revision for verification if <code>DigestTipAddress</code> is provided.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the ledger.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656625 = path.getOrDefault("name")
  valid_402656625 = validateParameter(valid_402656625, JString, required = true,
                                      default = nil)
  if valid_402656625 != nil:
    section.add "name", valid_402656625
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
  var valid_402656626 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656626 = validateParameter(valid_402656626, JString,
                                      required = false, default = nil)
  if valid_402656626 != nil:
    section.add "X-Amz-Security-Token", valid_402656626
  var valid_402656627 = header.getOrDefault("X-Amz-Signature")
  valid_402656627 = validateParameter(valid_402656627, JString,
                                      required = false, default = nil)
  if valid_402656627 != nil:
    section.add "X-Amz-Signature", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Algorithm", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Date")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Date", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Credential")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Credential", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656632
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

proc call*(call_402656634: Call_GetRevision_402656622; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a revision data object for a specified document ID and block address. Also returns a proof of the specified revision for verification if <code>DigestTipAddress</code> is provided.
                                                                                         ## 
  let valid = call_402656634.validator(path, query, header, formData, body, _)
  let scheme = call_402656634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656634.makeUrl(scheme.get, call_402656634.host, call_402656634.base,
                                   call_402656634.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656634, uri, valid, _)

proc call*(call_402656635: Call_GetRevision_402656622; name: string;
           body: JsonNode): Recallable =
  ## getRevision
  ## Returns a revision data object for a specified document ID and block address. Also returns a proof of the specified revision for verification if <code>DigestTipAddress</code> is provided.
  ##   
                                                                                                                                                                                                ## name: string (required)
                                                                                                                                                                                                ##       
                                                                                                                                                                                                ## : 
                                                                                                                                                                                                ## The 
                                                                                                                                                                                                ## name 
                                                                                                                                                                                                ## of 
                                                                                                                                                                                                ## the 
                                                                                                                                                                                                ## ledger.
  ##   
                                                                                                                                                                                                          ## body: JObject (required)
  var path_402656636 = newJObject()
  var body_402656637 = newJObject()
  add(path_402656636, "name", newJString(name))
  if body != nil:
    body_402656637 = body
  result = call_402656635.call(path_402656636, nil, nil, nil, body_402656637)

var getRevision* = Call_GetRevision_402656622(name: "getRevision",
    meth: HttpMethod.HttpPost, host: "qldb.amazonaws.com",
    route: "/ledgers/{name}/revision", validator: validate_GetRevision_402656623,
    base: "/", makeUrl: url_GetRevision_402656624,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJournalS3Exports_402656638 = ref object of OpenApiRestCall_402656038
proc url_ListJournalS3Exports_402656640(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListJournalS3Exports_402656639(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns an array of journal export job descriptions for all ledgers that are associated with the current AWS account and Region.</p> <p>This action returns a maximum of <code>MaxResults</code> items, and is paginated so that you can retrieve all the items by calling <code>ListJournalS3Exports</code> multiple times.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   max_results: JInt
                                  ##              : The maximum number of results to return in a single <code>ListJournalS3Exports</code> request. (The actual number of results returned might be fewer.)
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
  ##   
                                                                                                                                                                                                                          ## next_token: JString
                                                                                                                                                                                                                          ##             
                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                          ## A 
                                                                                                                                                                                                                          ## pagination 
                                                                                                                                                                                                                          ## token, 
                                                                                                                                                                                                                          ## indicating 
                                                                                                                                                                                                                          ## that 
                                                                                                                                                                                                                          ## you 
                                                                                                                                                                                                                          ## want 
                                                                                                                                                                                                                          ## to 
                                                                                                                                                                                                                          ## retrieve 
                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                          ## next 
                                                                                                                                                                                                                          ## page 
                                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                                          ## results. 
                                                                                                                                                                                                                          ## If 
                                                                                                                                                                                                                          ## you 
                                                                                                                                                                                                                          ## received 
                                                                                                                                                                                                                          ## a 
                                                                                                                                                                                                                          ## value 
                                                                                                                                                                                                                          ## for 
                                                                                                                                                                                                                          ## <code>NextToken</code> 
                                                                                                                                                                                                                          ## in 
                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                          ## response 
                                                                                                                                                                                                                          ## from 
                                                                                                                                                                                                                          ## a 
                                                                                                                                                                                                                          ## previous 
                                                                                                                                                                                                                          ## <code>ListJournalS3Exports</code> 
                                                                                                                                                                                                                          ## call, 
                                                                                                                                                                                                                          ## then 
                                                                                                                                                                                                                          ## you 
                                                                                                                                                                                                                          ## should 
                                                                                                                                                                                                                          ## use 
                                                                                                                                                                                                                          ## that 
                                                                                                                                                                                                                          ## value 
                                                                                                                                                                                                                          ## as 
                                                                                                                                                                                                                          ## input 
                                                                                                                                                                                                                          ## here.
  section = newJObject()
  var valid_402656641 = query.getOrDefault("max_results")
  valid_402656641 = validateParameter(valid_402656641, JInt, required = false,
                                      default = nil)
  if valid_402656641 != nil:
    section.add "max_results", valid_402656641
  var valid_402656642 = query.getOrDefault("MaxResults")
  valid_402656642 = validateParameter(valid_402656642, JString,
                                      required = false, default = nil)
  if valid_402656642 != nil:
    section.add "MaxResults", valid_402656642
  var valid_402656643 = query.getOrDefault("NextToken")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "NextToken", valid_402656643
  var valid_402656644 = query.getOrDefault("next_token")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "next_token", valid_402656644
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
  var valid_402656645 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Security-Token", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Signature")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Signature", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Algorithm", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-Date")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-Date", valid_402656649
  var valid_402656650 = header.getOrDefault("X-Amz-Credential")
  valid_402656650 = validateParameter(valid_402656650, JString,
                                      required = false, default = nil)
  if valid_402656650 != nil:
    section.add "X-Amz-Credential", valid_402656650
  var valid_402656651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656651 = validateParameter(valid_402656651, JString,
                                      required = false, default = nil)
  if valid_402656651 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656651
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656652: Call_ListJournalS3Exports_402656638;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns an array of journal export job descriptions for all ledgers that are associated with the current AWS account and Region.</p> <p>This action returns a maximum of <code>MaxResults</code> items, and is paginated so that you can retrieve all the items by calling <code>ListJournalS3Exports</code> multiple times.</p>
                                                                                         ## 
  let valid = call_402656652.validator(path, query, header, formData, body, _)
  let scheme = call_402656652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656652.makeUrl(scheme.get, call_402656652.host, call_402656652.base,
                                   call_402656652.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656652, uri, valid, _)

proc call*(call_402656653: Call_ListJournalS3Exports_402656638;
           maxResults: int = 0; MaxResults: string = ""; NextToken: string = "";
           nextToken: string = ""): Recallable =
  ## listJournalS3Exports
  ## <p>Returns an array of journal export job descriptions for all ledgers that are associated with the current AWS account and Region.</p> <p>This action returns a maximum of <code>MaxResults</code> items, and is paginated so that you can retrieve all the items by calling <code>ListJournalS3Exports</code> multiple times.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                        ## maxResults: int
                                                                                                                                                                                                                                                                                                                                        ##             
                                                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                                                        ## The 
                                                                                                                                                                                                                                                                                                                                        ## maximum 
                                                                                                                                                                                                                                                                                                                                        ## number 
                                                                                                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                                                                                                        ## results 
                                                                                                                                                                                                                                                                                                                                        ## to 
                                                                                                                                                                                                                                                                                                                                        ## return 
                                                                                                                                                                                                                                                                                                                                        ## in 
                                                                                                                                                                                                                                                                                                                                        ## a 
                                                                                                                                                                                                                                                                                                                                        ## single 
                                                                                                                                                                                                                                                                                                                                        ## <code>ListJournalS3Exports</code> 
                                                                                                                                                                                                                                                                                                                                        ## request. 
                                                                                                                                                                                                                                                                                                                                        ## (The 
                                                                                                                                                                                                                                                                                                                                        ## actual 
                                                                                                                                                                                                                                                                                                                                        ## number 
                                                                                                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                                                                                                        ## results 
                                                                                                                                                                                                                                                                                                                                        ## returned 
                                                                                                                                                                                                                                                                                                                                        ## might 
                                                                                                                                                                                                                                                                                                                                        ## be 
                                                                                                                                                                                                                                                                                                                                        ## fewer.)
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
                                                                                                                                                                                                                                                                                                                                                                  ## nextToken: string
                                                                                                                                                                                                                                                                                                                                                                  ##            
                                                                                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                                                                                  ## A 
                                                                                                                                                                                                                                                                                                                                                                  ## pagination 
                                                                                                                                                                                                                                                                                                                                                                  ## token, 
                                                                                                                                                                                                                                                                                                                                                                  ## indicating 
                                                                                                                                                                                                                                                                                                                                                                  ## that 
                                                                                                                                                                                                                                                                                                                                                                  ## you 
                                                                                                                                                                                                                                                                                                                                                                  ## want 
                                                                                                                                                                                                                                                                                                                                                                  ## to 
                                                                                                                                                                                                                                                                                                                                                                  ## retrieve 
                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                  ## next 
                                                                                                                                                                                                                                                                                                                                                                  ## page 
                                                                                                                                                                                                                                                                                                                                                                  ## of 
                                                                                                                                                                                                                                                                                                                                                                  ## results. 
                                                                                                                                                                                                                                                                                                                                                                  ## If 
                                                                                                                                                                                                                                                                                                                                                                  ## you 
                                                                                                                                                                                                                                                                                                                                                                  ## received 
                                                                                                                                                                                                                                                                                                                                                                  ## a 
                                                                                                                                                                                                                                                                                                                                                                  ## value 
                                                                                                                                                                                                                                                                                                                                                                  ## for 
                                                                                                                                                                                                                                                                                                                                                                  ## <code>NextToken</code> 
                                                                                                                                                                                                                                                                                                                                                                  ## in 
                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                  ## response 
                                                                                                                                                                                                                                                                                                                                                                  ## from 
                                                                                                                                                                                                                                                                                                                                                                  ## a 
                                                                                                                                                                                                                                                                                                                                                                  ## previous 
                                                                                                                                                                                                                                                                                                                                                                  ## <code>ListJournalS3Exports</code> 
                                                                                                                                                                                                                                                                                                                                                                  ## call, 
                                                                                                                                                                                                                                                                                                                                                                  ## then 
                                                                                                                                                                                                                                                                                                                                                                  ## you 
                                                                                                                                                                                                                                                                                                                                                                  ## should 
                                                                                                                                                                                                                                                                                                                                                                  ## use 
                                                                                                                                                                                                                                                                                                                                                                  ## that 
                                                                                                                                                                                                                                                                                                                                                                  ## value 
                                                                                                                                                                                                                                                                                                                                                                  ## as 
                                                                                                                                                                                                                                                                                                                                                                  ## input 
                                                                                                                                                                                                                                                                                                                                                                  ## here.
  var query_402656654 = newJObject()
  add(query_402656654, "max_results", newJInt(maxResults))
  add(query_402656654, "MaxResults", newJString(MaxResults))
  add(query_402656654, "NextToken", newJString(NextToken))
  add(query_402656654, "next_token", newJString(nextToken))
  result = call_402656653.call(nil, query_402656654, nil, nil, nil)

var listJournalS3Exports* = Call_ListJournalS3Exports_402656638(
    name: "listJournalS3Exports", meth: HttpMethod.HttpGet,
    host: "qldb.amazonaws.com", route: "/journal-s3-exports",
    validator: validate_ListJournalS3Exports_402656639, base: "/",
    makeUrl: url_ListJournalS3Exports_402656640,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656669 = ref object of OpenApiRestCall_402656038
proc url_TagResource_402656671(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_402656670(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Adds one or more tags to a specified Amazon QLDB resource.</p> <p>A resource can have up to 50 tags. If you try to create more than 50 tags for a resource, your request fails and returns an error.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              : <p>The Amazon Resource Name (ARN) to which you want to add the tags. For example:</p> <p> 
                                 ## <code>arn:aws:qldb:us-east-1:123456789012:ledger/exampleLedger</code> 
                                 ## </p>
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402656672 = path.getOrDefault("resourceArn")
  valid_402656672 = validateParameter(valid_402656672, JString, required = true,
                                      default = nil)
  if valid_402656672 != nil:
    section.add "resourceArn", valid_402656672
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
  var valid_402656673 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Security-Token", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-Signature")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-Signature", valid_402656674
  var valid_402656675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656675
  var valid_402656676 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Algorithm", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-Date")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Date", valid_402656677
  var valid_402656678 = header.getOrDefault("X-Amz-Credential")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Credential", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656679
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

proc call*(call_402656681: Call_TagResource_402656669; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds one or more tags to a specified Amazon QLDB resource.</p> <p>A resource can have up to 50 tags. If you try to create more than 50 tags for a resource, your request fails and returns an error.</p>
                                                                                         ## 
  let valid = call_402656681.validator(path, query, header, formData, body, _)
  let scheme = call_402656681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656681.makeUrl(scheme.get, call_402656681.host, call_402656681.base,
                                   call_402656681.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656681, uri, valid, _)

proc call*(call_402656682: Call_TagResource_402656669; body: JsonNode;
           resourceArn: string): Recallable =
  ## tagResource
  ## <p>Adds one or more tags to a specified Amazon QLDB resource.</p> <p>A resource can have up to 50 tags. If you try to create more than 50 tags for a resource, your request fails and returns an error.</p>
  ##   
                                                                                                                                                                                                                ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                           ## resourceArn: string (required)
                                                                                                                                                                                                                                           ##              
                                                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                                                           ## <p>The 
                                                                                                                                                                                                                                           ## Amazon 
                                                                                                                                                                                                                                           ## Resource 
                                                                                                                                                                                                                                           ## Name 
                                                                                                                                                                                                                                           ## (ARN) 
                                                                                                                                                                                                                                           ## to 
                                                                                                                                                                                                                                           ## which 
                                                                                                                                                                                                                                           ## you 
                                                                                                                                                                                                                                           ## want 
                                                                                                                                                                                                                                           ## to 
                                                                                                                                                                                                                                           ## add 
                                                                                                                                                                                                                                           ## the 
                                                                                                                                                                                                                                           ## tags. 
                                                                                                                                                                                                                                           ## For 
                                                                                                                                                                                                                                           ## example:</p> 
                                                                                                                                                                                                                                           ## <p> 
                                                                                                                                                                                                                                           ## <code>arn:aws:qldb:us-east-1:123456789012:ledger/exampleLedger</code> 
                                                                                                                                                                                                                                           ## </p>
  var path_402656683 = newJObject()
  var body_402656684 = newJObject()
  if body != nil:
    body_402656684 = body
  add(path_402656683, "resourceArn", newJString(resourceArn))
  result = call_402656682.call(path_402656683, nil, nil, nil, body_402656684)

var tagResource* = Call_TagResource_402656669(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "qldb.amazonaws.com",
    route: "/tags/{resourceArn}", validator: validate_TagResource_402656670,
    base: "/", makeUrl: url_TagResource_402656671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656655 = ref object of OpenApiRestCall_402656038
proc url_ListTagsForResource_402656657(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_402656656(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns all tags for a specified Amazon QLDB resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              : <p>The Amazon Resource Name (ARN) for which you want to list the tags. For example:</p> <p> 
                                 ## <code>arn:aws:qldb:us-east-1:123456789012:ledger/exampleLedger</code> 
                                 ## </p>
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402656658 = path.getOrDefault("resourceArn")
  valid_402656658 = validateParameter(valid_402656658, JString, required = true,
                                      default = nil)
  if valid_402656658 != nil:
    section.add "resourceArn", valid_402656658
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
  var valid_402656659 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Security-Token", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-Signature")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-Signature", valid_402656660
  var valid_402656661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Algorithm", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Date")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Date", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-Credential")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-Credential", valid_402656664
  var valid_402656665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656665 = validateParameter(valid_402656665, JString,
                                      required = false, default = nil)
  if valid_402656665 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656666: Call_ListTagsForResource_402656655;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns all tags for a specified Amazon QLDB resource.
                                                                                         ## 
  let valid = call_402656666.validator(path, query, header, formData, body, _)
  let scheme = call_402656666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656666.makeUrl(scheme.get, call_402656666.host, call_402656666.base,
                                   call_402656666.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656666, uri, valid, _)

proc call*(call_402656667: Call_ListTagsForResource_402656655;
           resourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns all tags for a specified Amazon QLDB resource.
  ##   resourceArn: string (required)
                                                           ##              : <p>The Amazon Resource Name (ARN) for which you want to list the tags. For example:</p> <p> 
                                                           ## <code>arn:aws:qldb:us-east-1:123456789012:ledger/exampleLedger</code> 
                                                           ## </p>
  var path_402656668 = newJObject()
  add(path_402656668, "resourceArn", newJString(resourceArn))
  result = call_402656667.call(path_402656668, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_402656655(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "qldb.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_402656656, base: "/",
    makeUrl: url_ListTagsForResource_402656657,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402656685 = ref object of OpenApiRestCall_402656038
proc url_UntagResource_402656687(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resourceArn"),
                 (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_402656686(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes one or more tags from a specified Amazon QLDB resource. You can specify up to 50 tag keys to remove.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              : <p>The Amazon Resource Name (ARN) from which you want to remove the tags. For example:</p> <p> 
                                 ## <code>arn:aws:qldb:us-east-1:123456789012:ledger/exampleLedger</code> 
                                 ## </p>
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402656688 = path.getOrDefault("resourceArn")
  valid_402656688 = validateParameter(valid_402656688, JString, required = true,
                                      default = nil)
  if valid_402656688 != nil:
    section.add "resourceArn", valid_402656688
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
                                  ##          : The list of tag keys that you want to remove.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `tagKeys` field"
  var valid_402656689 = query.getOrDefault("tagKeys")
  valid_402656689 = validateParameter(valid_402656689, JArray, required = true,
                                      default = nil)
  if valid_402656689 != nil:
    section.add "tagKeys", valid_402656689
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
  var valid_402656690 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Security-Token", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Signature")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Signature", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-Algorithm", valid_402656693
  var valid_402656694 = header.getOrDefault("X-Amz-Date")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-Date", valid_402656694
  var valid_402656695 = header.getOrDefault("X-Amz-Credential")
  valid_402656695 = validateParameter(valid_402656695, JString,
                                      required = false, default = nil)
  if valid_402656695 != nil:
    section.add "X-Amz-Credential", valid_402656695
  var valid_402656696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656696 = validateParameter(valid_402656696, JString,
                                      required = false, default = nil)
  if valid_402656696 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656697: Call_UntagResource_402656685; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes one or more tags from a specified Amazon QLDB resource. You can specify up to 50 tag keys to remove.
                                                                                         ## 
  let valid = call_402656697.validator(path, query, header, formData, body, _)
  let scheme = call_402656697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656697.makeUrl(scheme.get, call_402656697.host, call_402656697.base,
                                   call_402656697.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656697, uri, valid, _)

proc call*(call_402656698: Call_UntagResource_402656685; tagKeys: JsonNode;
           resourceArn: string): Recallable =
  ## untagResource
  ## Removes one or more tags from a specified Amazon QLDB resource. You can specify up to 50 tag keys to remove.
  ##   
                                                                                                                 ## tagKeys: JArray (required)
                                                                                                                 ##          
                                                                                                                 ## : 
                                                                                                                 ## The 
                                                                                                                 ## list 
                                                                                                                 ## of 
                                                                                                                 ## tag 
                                                                                                                 ## keys 
                                                                                                                 ## that 
                                                                                                                 ## you 
                                                                                                                 ## want 
                                                                                                                 ## to 
                                                                                                                 ## remove.
  ##   
                                                                                                                           ## resourceArn: string (required)
                                                                                                                           ##              
                                                                                                                           ## : 
                                                                                                                           ## <p>The 
                                                                                                                           ## Amazon 
                                                                                                                           ## Resource 
                                                                                                                           ## Name 
                                                                                                                           ## (ARN) 
                                                                                                                           ## from 
                                                                                                                           ## which 
                                                                                                                           ## you 
                                                                                                                           ## want 
                                                                                                                           ## to 
                                                                                                                           ## remove 
                                                                                                                           ## the 
                                                                                                                           ## tags. 
                                                                                                                           ## For 
                                                                                                                           ## example:</p> 
                                                                                                                           ## <p> 
                                                                                                                           ## <code>arn:aws:qldb:us-east-1:123456789012:ledger/exampleLedger</code> 
                                                                                                                           ## </p>
  var path_402656699 = newJObject()
  var query_402656700 = newJObject()
  if tagKeys != nil:
    query_402656700.add "tagKeys", tagKeys
  add(path_402656699, "resourceArn", newJString(resourceArn))
  result = call_402656698.call(path_402656699, query_402656700, nil, nil, nil)

var untagResource* = Call_UntagResource_402656685(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "qldb.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_402656686,
    base: "/", makeUrl: url_UntagResource_402656687,
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