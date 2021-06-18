
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Backup
## version: 2018-11-15
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Backup</fullname> <p>AWS Backup is a unified backup service designed to protect AWS services and their associated data. AWS Backup simplifies the creation, migration, restoration, and deletion of backups, while also providing reporting and auditing.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/backup/
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "backup.ap-northeast-1.amazonaws.com", "ap-southeast-1": "backup.ap-southeast-1.amazonaws.com",
                               "us-west-2": "backup.us-west-2.amazonaws.com",
                               "eu-west-2": "backup.eu-west-2.amazonaws.com", "ap-northeast-3": "backup.ap-northeast-3.amazonaws.com", "eu-central-1": "backup.eu-central-1.amazonaws.com",
                               "us-east-2": "backup.us-east-2.amazonaws.com",
                               "us-east-1": "backup.us-east-1.amazonaws.com", "cn-northwest-1": "backup.cn-northwest-1.amazonaws.com.cn",
                               "ap-south-1": "backup.ap-south-1.amazonaws.com",
                               "eu-north-1": "backup.eu-north-1.amazonaws.com", "ap-northeast-2": "backup.ap-northeast-2.amazonaws.com",
                               "us-west-1": "backup.us-west-1.amazonaws.com", "us-gov-east-1": "backup.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "backup.eu-west-3.amazonaws.com", "cn-north-1": "backup.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "backup.sa-east-1.amazonaws.com",
                               "eu-west-1": "backup.eu-west-1.amazonaws.com", "us-gov-west-1": "backup.us-gov-west-1.amazonaws.com", "ap-southeast-2": "backup.ap-southeast-2.amazonaws.com", "ca-central-1": "backup.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "backup.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "backup.ap-southeast-1.amazonaws.com",
      "us-west-2": "backup.us-west-2.amazonaws.com",
      "eu-west-2": "backup.eu-west-2.amazonaws.com",
      "ap-northeast-3": "backup.ap-northeast-3.amazonaws.com",
      "eu-central-1": "backup.eu-central-1.amazonaws.com",
      "us-east-2": "backup.us-east-2.amazonaws.com",
      "us-east-1": "backup.us-east-1.amazonaws.com",
      "cn-northwest-1": "backup.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "backup.ap-south-1.amazonaws.com",
      "eu-north-1": "backup.eu-north-1.amazonaws.com",
      "ap-northeast-2": "backup.ap-northeast-2.amazonaws.com",
      "us-west-1": "backup.us-west-1.amazonaws.com",
      "us-gov-east-1": "backup.us-gov-east-1.amazonaws.com",
      "eu-west-3": "backup.eu-west-3.amazonaws.com",
      "cn-north-1": "backup.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "backup.sa-east-1.amazonaws.com",
      "eu-west-1": "backup.eu-west-1.amazonaws.com",
      "us-gov-west-1": "backup.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "backup.ap-southeast-2.amazonaws.com",
      "ca-central-1": "backup.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "backup"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateBackupPlan_402656480 = ref object of OpenApiRestCall_402656044
proc url_CreateBackupPlan_402656482(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateBackupPlan_402656481(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Backup plans are documents that contain information that AWS Backup uses to schedule tasks that create recovery points of resources.</p> <p>If you call <code>CreateBackupPlan</code> with a plan that already exists, an <code>AlreadyExistsException</code> is returned.</p>
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
  var valid_402656483 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656483 = validateParameter(valid_402656483, JString,
                                      required = false, default = nil)
  if valid_402656483 != nil:
    section.add "X-Amz-Security-Token", valid_402656483
  var valid_402656484 = header.getOrDefault("X-Amz-Signature")
  valid_402656484 = validateParameter(valid_402656484, JString,
                                      required = false, default = nil)
  if valid_402656484 != nil:
    section.add "X-Amz-Signature", valid_402656484
  var valid_402656485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656485 = validateParameter(valid_402656485, JString,
                                      required = false, default = nil)
  if valid_402656485 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656485
  var valid_402656486 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656486 = validateParameter(valid_402656486, JString,
                                      required = false, default = nil)
  if valid_402656486 != nil:
    section.add "X-Amz-Algorithm", valid_402656486
  var valid_402656487 = header.getOrDefault("X-Amz-Date")
  valid_402656487 = validateParameter(valid_402656487, JString,
                                      required = false, default = nil)
  if valid_402656487 != nil:
    section.add "X-Amz-Date", valid_402656487
  var valid_402656488 = header.getOrDefault("X-Amz-Credential")
  valid_402656488 = validateParameter(valid_402656488, JString,
                                      required = false, default = nil)
  if valid_402656488 != nil:
    section.add "X-Amz-Credential", valid_402656488
  var valid_402656489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656489 = validateParameter(valid_402656489, JString,
                                      required = false, default = nil)
  if valid_402656489 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656489
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

proc call*(call_402656491: Call_CreateBackupPlan_402656480;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Backup plans are documents that contain information that AWS Backup uses to schedule tasks that create recovery points of resources.</p> <p>If you call <code>CreateBackupPlan</code> with a plan that already exists, an <code>AlreadyExistsException</code> is returned.</p>
                                                                                         ## 
  let valid = call_402656491.validator(path, query, header, formData, body, _)
  let scheme = call_402656491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656491.makeUrl(scheme.get, call_402656491.host, call_402656491.base,
                                   call_402656491.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656491, uri, valid, _)

proc call*(call_402656492: Call_CreateBackupPlan_402656480; body: JsonNode): Recallable =
  ## createBackupPlan
  ## <p>Backup plans are documents that contain information that AWS Backup uses to schedule tasks that create recovery points of resources.</p> <p>If you call <code>CreateBackupPlan</code> with a plan that already exists, an <code>AlreadyExistsException</code> is returned.</p>
  ##   
                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402656493 = newJObject()
  if body != nil:
    body_402656493 = body
  result = call_402656492.call(nil, nil, nil, nil, body_402656493)

var createBackupPlan* = Call_CreateBackupPlan_402656480(
    name: "createBackupPlan", meth: HttpMethod.HttpPut,
    host: "backup.amazonaws.com", route: "/backup/plans/",
    validator: validate_CreateBackupPlan_402656481, base: "/",
    makeUrl: url_CreateBackupPlan_402656482,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupPlans_402656294 = ref object of OpenApiRestCall_402656044
proc url_ListBackupPlans_402656296(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBackupPlans_402656295(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns metadata of your saved backup plans, including Amazon Resource Names (ARNs), plan IDs, creation and deletion dates, version IDs, plan names, and creator request IDs.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of items to be returned.
  ##   
                                                                                              ## nextToken: JString
                                                                                              ##            
                                                                                              ## : 
                                                                                              ## The 
                                                                                              ## next 
                                                                                              ## item 
                                                                                              ## following 
                                                                                              ## a 
                                                                                              ## partial 
                                                                                              ## list 
                                                                                              ## of 
                                                                                              ## returned 
                                                                                              ## items. 
                                                                                              ## For 
                                                                                              ## example, 
                                                                                              ## if 
                                                                                              ## a 
                                                                                              ## request 
                                                                                              ## is 
                                                                                              ## made 
                                                                                              ## to 
                                                                                              ## return 
                                                                                              ## <code>maxResults</code> 
                                                                                              ## number 
                                                                                              ## of 
                                                                                              ## items, 
                                                                                              ## <code>NextToken</code> 
                                                                                              ## allows 
                                                                                              ## you 
                                                                                              ## to 
                                                                                              ## return 
                                                                                              ## more 
                                                                                              ## items 
                                                                                              ## in 
                                                                                              ## your 
                                                                                              ## list 
                                                                                              ## starting 
                                                                                              ## at 
                                                                                              ## the 
                                                                                              ## location 
                                                                                              ## pointed 
                                                                                              ## to 
                                                                                              ## by 
                                                                                              ## the 
                                                                                              ## next 
                                                                                              ## token.
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
                                                                                                                       ## includeDeleted: JBool
                                                                                                                       ##                 
                                                                                                                       ## : 
                                                                                                                       ## A 
                                                                                                                       ## Boolean 
                                                                                                                       ## value 
                                                                                                                       ## with 
                                                                                                                       ## a 
                                                                                                                       ## default 
                                                                                                                       ## value 
                                                                                                                       ## of 
                                                                                                                       ## <code>FALSE</code> 
                                                                                                                       ## that 
                                                                                                                       ## returns 
                                                                                                                       ## deleted 
                                                                                                                       ## backup 
                                                                                                                       ## plans 
                                                                                                                       ## when 
                                                                                                                       ## set 
                                                                                                                       ## to 
                                                                                                                       ## <code>TRUE</code>.
  section = newJObject()
  var valid_402656378 = query.getOrDefault("maxResults")
  valid_402656378 = validateParameter(valid_402656378, JInt, required = false,
                                      default = nil)
  if valid_402656378 != nil:
    section.add "maxResults", valid_402656378
  var valid_402656379 = query.getOrDefault("nextToken")
  valid_402656379 = validateParameter(valid_402656379, JString,
                                      required = false, default = nil)
  if valid_402656379 != nil:
    section.add "nextToken", valid_402656379
  var valid_402656380 = query.getOrDefault("MaxResults")
  valid_402656380 = validateParameter(valid_402656380, JString,
                                      required = false, default = nil)
  if valid_402656380 != nil:
    section.add "MaxResults", valid_402656380
  var valid_402656381 = query.getOrDefault("NextToken")
  valid_402656381 = validateParameter(valid_402656381, JString,
                                      required = false, default = nil)
  if valid_402656381 != nil:
    section.add "NextToken", valid_402656381
  var valid_402656382 = query.getOrDefault("includeDeleted")
  valid_402656382 = validateParameter(valid_402656382, JBool, required = false,
                                      default = nil)
  if valid_402656382 != nil:
    section.add "includeDeleted", valid_402656382
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
  var valid_402656383 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656383 = validateParameter(valid_402656383, JString,
                                      required = false, default = nil)
  if valid_402656383 != nil:
    section.add "X-Amz-Security-Token", valid_402656383
  var valid_402656384 = header.getOrDefault("X-Amz-Signature")
  valid_402656384 = validateParameter(valid_402656384, JString,
                                      required = false, default = nil)
  if valid_402656384 != nil:
    section.add "X-Amz-Signature", valid_402656384
  var valid_402656385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656385 = validateParameter(valid_402656385, JString,
                                      required = false, default = nil)
  if valid_402656385 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656385
  var valid_402656386 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656386 = validateParameter(valid_402656386, JString,
                                      required = false, default = nil)
  if valid_402656386 != nil:
    section.add "X-Amz-Algorithm", valid_402656386
  var valid_402656387 = header.getOrDefault("X-Amz-Date")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-Date", valid_402656387
  var valid_402656388 = header.getOrDefault("X-Amz-Credential")
  valid_402656388 = validateParameter(valid_402656388, JString,
                                      required = false, default = nil)
  if valid_402656388 != nil:
    section.add "X-Amz-Credential", valid_402656388
  var valid_402656389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656389 = validateParameter(valid_402656389, JString,
                                      required = false, default = nil)
  if valid_402656389 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656403: Call_ListBackupPlans_402656294; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns metadata of your saved backup plans, including Amazon Resource Names (ARNs), plan IDs, creation and deletion dates, version IDs, plan names, and creator request IDs.
                                                                                         ## 
  let valid = call_402656403.validator(path, query, header, formData, body, _)
  let scheme = call_402656403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656403.makeUrl(scheme.get, call_402656403.host, call_402656403.base,
                                   call_402656403.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656403, uri, valid, _)

proc call*(call_402656452: Call_ListBackupPlans_402656294; maxResults: int = 0;
           nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""; includeDeleted: bool = false): Recallable =
  ## listBackupPlans
  ## Returns metadata of your saved backup plans, including Amazon Resource Names (ARNs), plan IDs, creation and deletion dates, version IDs, plan names, and creator request IDs.
  ##   
                                                                                                                                                                                  ## maxResults: int
                                                                                                                                                                                  ##             
                                                                                                                                                                                  ## : 
                                                                                                                                                                                  ## The 
                                                                                                                                                                                  ## maximum 
                                                                                                                                                                                  ## number 
                                                                                                                                                                                  ## of 
                                                                                                                                                                                  ## items 
                                                                                                                                                                                  ## to 
                                                                                                                                                                                  ## be 
                                                                                                                                                                                  ## returned.
  ##   
                                                                                                                                                                                              ## nextToken: string
                                                                                                                                                                                              ##            
                                                                                                                                                                                              ## : 
                                                                                                                                                                                              ## The 
                                                                                                                                                                                              ## next 
                                                                                                                                                                                              ## item 
                                                                                                                                                                                              ## following 
                                                                                                                                                                                              ## a 
                                                                                                                                                                                              ## partial 
                                                                                                                                                                                              ## list 
                                                                                                                                                                                              ## of 
                                                                                                                                                                                              ## returned 
                                                                                                                                                                                              ## items. 
                                                                                                                                                                                              ## For 
                                                                                                                                                                                              ## example, 
                                                                                                                                                                                              ## if 
                                                                                                                                                                                              ## a 
                                                                                                                                                                                              ## request 
                                                                                                                                                                                              ## is 
                                                                                                                                                                                              ## made 
                                                                                                                                                                                              ## to 
                                                                                                                                                                                              ## return 
                                                                                                                                                                                              ## <code>maxResults</code> 
                                                                                                                                                                                              ## number 
                                                                                                                                                                                              ## of 
                                                                                                                                                                                              ## items, 
                                                                                                                                                                                              ## <code>NextToken</code> 
                                                                                                                                                                                              ## allows 
                                                                                                                                                                                              ## you 
                                                                                                                                                                                              ## to 
                                                                                                                                                                                              ## return 
                                                                                                                                                                                              ## more 
                                                                                                                                                                                              ## items 
                                                                                                                                                                                              ## in 
                                                                                                                                                                                              ## your 
                                                                                                                                                                                              ## list 
                                                                                                                                                                                              ## starting 
                                                                                                                                                                                              ## at 
                                                                                                                                                                                              ## the 
                                                                                                                                                                                              ## location 
                                                                                                                                                                                              ## pointed 
                                                                                                                                                                                              ## to 
                                                                                                                                                                                              ## by 
                                                                                                                                                                                              ## the 
                                                                                                                                                                                              ## next 
                                                                                                                                                                                              ## token.
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
                                                                                                                                                                                                                       ## includeDeleted: bool
                                                                                                                                                                                                                       ##                 
                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                       ## A 
                                                                                                                                                                                                                       ## Boolean 
                                                                                                                                                                                                                       ## value 
                                                                                                                                                                                                                       ## with 
                                                                                                                                                                                                                       ## a 
                                                                                                                                                                                                                       ## default 
                                                                                                                                                                                                                       ## value 
                                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                                       ## <code>FALSE</code> 
                                                                                                                                                                                                                       ## that 
                                                                                                                                                                                                                       ## returns 
                                                                                                                                                                                                                       ## deleted 
                                                                                                                                                                                                                       ## backup 
                                                                                                                                                                                                                       ## plans 
                                                                                                                                                                                                                       ## when 
                                                                                                                                                                                                                       ## set 
                                                                                                                                                                                                                       ## to 
                                                                                                                                                                                                                       ## <code>TRUE</code>.
  var query_402656453 = newJObject()
  add(query_402656453, "maxResults", newJInt(maxResults))
  add(query_402656453, "nextToken", newJString(nextToken))
  add(query_402656453, "MaxResults", newJString(MaxResults))
  add(query_402656453, "NextToken", newJString(NextToken))
  add(query_402656453, "includeDeleted", newJBool(includeDeleted))
  result = call_402656452.call(nil, query_402656453, nil, nil, nil)

var listBackupPlans* = Call_ListBackupPlans_402656294(name: "listBackupPlans",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com",
    route: "/backup/plans/", validator: validate_ListBackupPlans_402656295,
    base: "/", makeUrl: url_ListBackupPlans_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBackupSelection_402656524 = ref object of OpenApiRestCall_402656044
proc url_CreateBackupSelection_402656526(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupPlanId" in path, "`backupPlanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/plans/"),
                 (kind: VariableSegment, value: "backupPlanId"),
                 (kind: ConstantSegment, value: "/selections/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateBackupSelection_402656525(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a JSON document that specifies a set of resources to assign to a backup plan. Resources can be included by specifying patterns for a <code>ListOfTags</code> and selected <code>Resources</code>. </p> <p>For example, consider the following patterns:</p> <ul> <li> <p> <code>Resources: "arn:aws:ec2:region:account-id:volume/volume-id"</code> </p> </li> <li> <p> <code>ConditionKey:"department"</code> </p> <p> <code>ConditionValue:"finance"</code> </p> <p> <code>ConditionType:"STRINGEQUALS"</code> </p> </li> <li> <p> <code>ConditionKey:"importance"</code> </p> <p> <code>ConditionValue:"critical"</code> </p> <p> <code>ConditionType:"STRINGEQUALS"</code> </p> </li> </ul> <p>Using these patterns would back up all Amazon Elastic Block Store (Amazon EBS) volumes that are tagged as <code>"department=finance"</code>, <code>"importance=critical"</code>, in addition to an EBS volume with the specified volume Id.</p> <p>Resources and conditions are additive in that all resources that match the pattern are selected. This shouldn't be confused with a logical AND, where all conditions must match. The matching patterns are logically 'put together using the OR operator. In other words, all patterns that match are selected for backup.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupPlanId: JString (required)
                                 ##               : Uniquely identifies the backup plan to be associated with the selection of resources.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `backupPlanId` field"
  var valid_402656527 = path.getOrDefault("backupPlanId")
  valid_402656527 = validateParameter(valid_402656527, JString, required = true,
                                      default = nil)
  if valid_402656527 != nil:
    section.add "backupPlanId", valid_402656527
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
  var valid_402656528 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Security-Token", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-Signature")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-Signature", valid_402656529
  var valid_402656530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656530 = validateParameter(valid_402656530, JString,
                                      required = false, default = nil)
  if valid_402656530 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656530
  var valid_402656531 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656531 = validateParameter(valid_402656531, JString,
                                      required = false, default = nil)
  if valid_402656531 != nil:
    section.add "X-Amz-Algorithm", valid_402656531
  var valid_402656532 = header.getOrDefault("X-Amz-Date")
  valid_402656532 = validateParameter(valid_402656532, JString,
                                      required = false, default = nil)
  if valid_402656532 != nil:
    section.add "X-Amz-Date", valid_402656532
  var valid_402656533 = header.getOrDefault("X-Amz-Credential")
  valid_402656533 = validateParameter(valid_402656533, JString,
                                      required = false, default = nil)
  if valid_402656533 != nil:
    section.add "X-Amz-Credential", valid_402656533
  var valid_402656534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656534 = validateParameter(valid_402656534, JString,
                                      required = false, default = nil)
  if valid_402656534 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656534
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

proc call*(call_402656536: Call_CreateBackupSelection_402656524;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a JSON document that specifies a set of resources to assign to a backup plan. Resources can be included by specifying patterns for a <code>ListOfTags</code> and selected <code>Resources</code>. </p> <p>For example, consider the following patterns:</p> <ul> <li> <p> <code>Resources: "arn:aws:ec2:region:account-id:volume/volume-id"</code> </p> </li> <li> <p> <code>ConditionKey:"department"</code> </p> <p> <code>ConditionValue:"finance"</code> </p> <p> <code>ConditionType:"STRINGEQUALS"</code> </p> </li> <li> <p> <code>ConditionKey:"importance"</code> </p> <p> <code>ConditionValue:"critical"</code> </p> <p> <code>ConditionType:"STRINGEQUALS"</code> </p> </li> </ul> <p>Using these patterns would back up all Amazon Elastic Block Store (Amazon EBS) volumes that are tagged as <code>"department=finance"</code>, <code>"importance=critical"</code>, in addition to an EBS volume with the specified volume Id.</p> <p>Resources and conditions are additive in that all resources that match the pattern are selected. This shouldn't be confused with a logical AND, where all conditions must match. The matching patterns are logically 'put together using the OR operator. In other words, all patterns that match are selected for backup.</p>
                                                                                         ## 
  let valid = call_402656536.validator(path, query, header, formData, body, _)
  let scheme = call_402656536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656536.makeUrl(scheme.get, call_402656536.host, call_402656536.base,
                                   call_402656536.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656536, uri, valid, _)

proc call*(call_402656537: Call_CreateBackupSelection_402656524;
           backupPlanId: string; body: JsonNode): Recallable =
  ## createBackupSelection
  ## <p>Creates a JSON document that specifies a set of resources to assign to a backup plan. Resources can be included by specifying patterns for a <code>ListOfTags</code> and selected <code>Resources</code>. </p> <p>For example, consider the following patterns:</p> <ul> <li> <p> <code>Resources: "arn:aws:ec2:region:account-id:volume/volume-id"</code> </p> </li> <li> <p> <code>ConditionKey:"department"</code> </p> <p> <code>ConditionValue:"finance"</code> </p> <p> <code>ConditionType:"STRINGEQUALS"</code> </p> </li> <li> <p> <code>ConditionKey:"importance"</code> </p> <p> <code>ConditionValue:"critical"</code> </p> <p> <code>ConditionType:"STRINGEQUALS"</code> </p> </li> </ul> <p>Using these patterns would back up all Amazon Elastic Block Store (Amazon EBS) volumes that are tagged as <code>"department=finance"</code>, <code>"importance=critical"</code>, in addition to an EBS volume with the specified volume Id.</p> <p>Resources and conditions are additive in that all resources that match the pattern are selected. This shouldn't be confused with a logical AND, where all conditions must match. The matching patterns are logically 'put together using the OR operator. In other words, all patterns that match are selected for backup.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## backupPlanId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ##               
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## Uniquely 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## identifies 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## backup 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## plan 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## be 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## associated 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## with 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## selection 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## resources.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## body: JObject (required)
  var path_402656538 = newJObject()
  var body_402656539 = newJObject()
  add(path_402656538, "backupPlanId", newJString(backupPlanId))
  if body != nil:
    body_402656539 = body
  result = call_402656537.call(path_402656538, nil, nil, nil, body_402656539)

var createBackupSelection* = Call_CreateBackupSelection_402656524(
    name: "createBackupSelection", meth: HttpMethod.HttpPut,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/selections/",
    validator: validate_CreateBackupSelection_402656525, base: "/",
    makeUrl: url_CreateBackupSelection_402656526,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupSelections_402656494 = ref object of OpenApiRestCall_402656044
proc url_ListBackupSelections_402656496(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupPlanId" in path, "`backupPlanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/plans/"),
                 (kind: VariableSegment, value: "backupPlanId"),
                 (kind: ConstantSegment, value: "/selections/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListBackupSelections_402656495(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns an array containing metadata of the resources associated with the target backup plan.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupPlanId: JString (required)
                                 ##               : Uniquely identifies a backup plan.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `backupPlanId` field"
  var valid_402656508 = path.getOrDefault("backupPlanId")
  valid_402656508 = validateParameter(valid_402656508, JString, required = true,
                                      default = nil)
  if valid_402656508 != nil:
    section.add "backupPlanId", valid_402656508
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of items to be returned.
  ##   
                                                                                              ## nextToken: JString
                                                                                              ##            
                                                                                              ## : 
                                                                                              ## The 
                                                                                              ## next 
                                                                                              ## item 
                                                                                              ## following 
                                                                                              ## a 
                                                                                              ## partial 
                                                                                              ## list 
                                                                                              ## of 
                                                                                              ## returned 
                                                                                              ## items. 
                                                                                              ## For 
                                                                                              ## example, 
                                                                                              ## if 
                                                                                              ## a 
                                                                                              ## request 
                                                                                              ## is 
                                                                                              ## made 
                                                                                              ## to 
                                                                                              ## return 
                                                                                              ## <code>maxResults</code> 
                                                                                              ## number 
                                                                                              ## of 
                                                                                              ## items, 
                                                                                              ## <code>NextToken</code> 
                                                                                              ## allows 
                                                                                              ## you 
                                                                                              ## to 
                                                                                              ## return 
                                                                                              ## more 
                                                                                              ## items 
                                                                                              ## in 
                                                                                              ## your 
                                                                                              ## list 
                                                                                              ## starting 
                                                                                              ## at 
                                                                                              ## the 
                                                                                              ## location 
                                                                                              ## pointed 
                                                                                              ## to 
                                                                                              ## by 
                                                                                              ## the 
                                                                                              ## next 
                                                                                              ## token.
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
  var valid_402656509 = query.getOrDefault("maxResults")
  valid_402656509 = validateParameter(valid_402656509, JInt, required = false,
                                      default = nil)
  if valid_402656509 != nil:
    section.add "maxResults", valid_402656509
  var valid_402656510 = query.getOrDefault("nextToken")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "nextToken", valid_402656510
  var valid_402656511 = query.getOrDefault("MaxResults")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "MaxResults", valid_402656511
  var valid_402656512 = query.getOrDefault("NextToken")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "NextToken", valid_402656512
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
  var valid_402656513 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Security-Token", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-Signature")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-Signature", valid_402656514
  var valid_402656515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656515
  var valid_402656516 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656516 = validateParameter(valid_402656516, JString,
                                      required = false, default = nil)
  if valid_402656516 != nil:
    section.add "X-Amz-Algorithm", valid_402656516
  var valid_402656517 = header.getOrDefault("X-Amz-Date")
  valid_402656517 = validateParameter(valid_402656517, JString,
                                      required = false, default = nil)
  if valid_402656517 != nil:
    section.add "X-Amz-Date", valid_402656517
  var valid_402656518 = header.getOrDefault("X-Amz-Credential")
  valid_402656518 = validateParameter(valid_402656518, JString,
                                      required = false, default = nil)
  if valid_402656518 != nil:
    section.add "X-Amz-Credential", valid_402656518
  var valid_402656519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656520: Call_ListBackupSelections_402656494;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns an array containing metadata of the resources associated with the target backup plan.
                                                                                         ## 
  let valid = call_402656520.validator(path, query, header, formData, body, _)
  let scheme = call_402656520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656520.makeUrl(scheme.get, call_402656520.host, call_402656520.base,
                                   call_402656520.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656520, uri, valid, _)

proc call*(call_402656521: Call_ListBackupSelections_402656494;
           backupPlanId: string; maxResults: int = 0; nextToken: string = "";
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listBackupSelections
  ## Returns an array containing metadata of the resources associated with the target backup plan.
  ##   
                                                                                                  ## maxResults: int
                                                                                                  ##             
                                                                                                  ## : 
                                                                                                  ## The 
                                                                                                  ## maximum 
                                                                                                  ## number 
                                                                                                  ## of 
                                                                                                  ## items 
                                                                                                  ## to 
                                                                                                  ## be 
                                                                                                  ## returned.
  ##   
                                                                                                              ## nextToken: string
                                                                                                              ##            
                                                                                                              ## : 
                                                                                                              ## The 
                                                                                                              ## next 
                                                                                                              ## item 
                                                                                                              ## following 
                                                                                                              ## a 
                                                                                                              ## partial 
                                                                                                              ## list 
                                                                                                              ## of 
                                                                                                              ## returned 
                                                                                                              ## items. 
                                                                                                              ## For 
                                                                                                              ## example, 
                                                                                                              ## if 
                                                                                                              ## a 
                                                                                                              ## request 
                                                                                                              ## is 
                                                                                                              ## made 
                                                                                                              ## to 
                                                                                                              ## return 
                                                                                                              ## <code>maxResults</code> 
                                                                                                              ## number 
                                                                                                              ## of 
                                                                                                              ## items, 
                                                                                                              ## <code>NextToken</code> 
                                                                                                              ## allows 
                                                                                                              ## you 
                                                                                                              ## to 
                                                                                                              ## return 
                                                                                                              ## more 
                                                                                                              ## items 
                                                                                                              ## in 
                                                                                                              ## your 
                                                                                                              ## list 
                                                                                                              ## starting 
                                                                                                              ## at 
                                                                                                              ## the 
                                                                                                              ## location 
                                                                                                              ## pointed 
                                                                                                              ## to 
                                                                                                              ## by 
                                                                                                              ## the 
                                                                                                              ## next 
                                                                                                              ## token.
  ##   
                                                                                                                       ## backupPlanId: string (required)
                                                                                                                       ##               
                                                                                                                       ## : 
                                                                                                                       ## Uniquely 
                                                                                                                       ## identifies 
                                                                                                                       ## a 
                                                                                                                       ## backup 
                                                                                                                       ## plan.
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
  var path_402656522 = newJObject()
  var query_402656523 = newJObject()
  add(query_402656523, "maxResults", newJInt(maxResults))
  add(query_402656523, "nextToken", newJString(nextToken))
  add(path_402656522, "backupPlanId", newJString(backupPlanId))
  add(query_402656523, "MaxResults", newJString(MaxResults))
  add(query_402656523, "NextToken", newJString(NextToken))
  result = call_402656521.call(path_402656522, query_402656523, nil, nil, nil)

var listBackupSelections* = Call_ListBackupSelections_402656494(
    name: "listBackupSelections", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/selections/",
    validator: validate_ListBackupSelections_402656495, base: "/",
    makeUrl: url_ListBackupSelections_402656496,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBackupVault_402656554 = ref object of OpenApiRestCall_402656044
proc url_CreateBackupVault_402656556(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path,
         "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
                 (kind: VariableSegment, value: "backupVaultName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateBackupVault_402656555(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a logical container where backups are stored. A <code>CreateBackupVault</code> request includes a name, optionally one or more resource tags, an encryption key, and a request ID.</p> <note> <p>Sensitive data, such as passport numbers, should not be included the name of a backup vault.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
                                 ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `backupVaultName` field"
  var valid_402656557 = path.getOrDefault("backupVaultName")
  valid_402656557 = validateParameter(valid_402656557, JString, required = true,
                                      default = nil)
  if valid_402656557 != nil:
    section.add "backupVaultName", valid_402656557
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
  var valid_402656558 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Security-Token", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-Signature")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-Signature", valid_402656559
  var valid_402656560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656560 = validateParameter(valid_402656560, JString,
                                      required = false, default = nil)
  if valid_402656560 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656560
  var valid_402656561 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656561 = validateParameter(valid_402656561, JString,
                                      required = false, default = nil)
  if valid_402656561 != nil:
    section.add "X-Amz-Algorithm", valid_402656561
  var valid_402656562 = header.getOrDefault("X-Amz-Date")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "X-Amz-Date", valid_402656562
  var valid_402656563 = header.getOrDefault("X-Amz-Credential")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "X-Amz-Credential", valid_402656563
  var valid_402656564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656564
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

proc call*(call_402656566: Call_CreateBackupVault_402656554;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a logical container where backups are stored. A <code>CreateBackupVault</code> request includes a name, optionally one or more resource tags, an encryption key, and a request ID.</p> <note> <p>Sensitive data, such as passport numbers, should not be included the name of a backup vault.</p> </note>
                                                                                         ## 
  let valid = call_402656566.validator(path, query, header, formData, body, _)
  let scheme = call_402656566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656566.makeUrl(scheme.get, call_402656566.host, call_402656566.base,
                                   call_402656566.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656566, uri, valid, _)

proc call*(call_402656567: Call_CreateBackupVault_402656554; body: JsonNode;
           backupVaultName: string): Recallable =
  ## createBackupVault
  ## <p>Creates a logical container where backups are stored. A <code>CreateBackupVault</code> request includes a name, optionally one or more resource tags, an encryption key, and a request ID.</p> <note> <p>Sensitive data, such as passport numbers, should not be included the name of a backup vault.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                    ## backupVaultName: string (required)
                                                                                                                                                                                                                                                                                                                                                    ##                  
                                                                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                                                                    ## The 
                                                                                                                                                                                                                                                                                                                                                    ## name 
                                                                                                                                                                                                                                                                                                                                                    ## of 
                                                                                                                                                                                                                                                                                                                                                    ## a 
                                                                                                                                                                                                                                                                                                                                                    ## logical 
                                                                                                                                                                                                                                                                                                                                                    ## container 
                                                                                                                                                                                                                                                                                                                                                    ## where 
                                                                                                                                                                                                                                                                                                                                                    ## backups 
                                                                                                                                                                                                                                                                                                                                                    ## are 
                                                                                                                                                                                                                                                                                                                                                    ## stored. 
                                                                                                                                                                                                                                                                                                                                                    ## Backup 
                                                                                                                                                                                                                                                                                                                                                    ## vaults 
                                                                                                                                                                                                                                                                                                                                                    ## are 
                                                                                                                                                                                                                                                                                                                                                    ## identified 
                                                                                                                                                                                                                                                                                                                                                    ## by 
                                                                                                                                                                                                                                                                                                                                                    ## names 
                                                                                                                                                                                                                                                                                                                                                    ## that 
                                                                                                                                                                                                                                                                                                                                                    ## are 
                                                                                                                                                                                                                                                                                                                                                    ## unique 
                                                                                                                                                                                                                                                                                                                                                    ## to 
                                                                                                                                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                                                                                                                                    ## account 
                                                                                                                                                                                                                                                                                                                                                    ## used 
                                                                                                                                                                                                                                                                                                                                                    ## to 
                                                                                                                                                                                                                                                                                                                                                    ## create 
                                                                                                                                                                                                                                                                                                                                                    ## them 
                                                                                                                                                                                                                                                                                                                                                    ## and 
                                                                                                                                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                                                                                                                                    ## AWS 
                                                                                                                                                                                                                                                                                                                                                    ## Region 
                                                                                                                                                                                                                                                                                                                                                    ## where 
                                                                                                                                                                                                                                                                                                                                                    ## they 
                                                                                                                                                                                                                                                                                                                                                    ## are 
                                                                                                                                                                                                                                                                                                                                                    ## created. 
                                                                                                                                                                                                                                                                                                                                                    ## They 
                                                                                                                                                                                                                                                                                                                                                    ## consist 
                                                                                                                                                                                                                                                                                                                                                    ## of 
                                                                                                                                                                                                                                                                                                                                                    ## lowercase 
                                                                                                                                                                                                                                                                                                                                                    ## letters, 
                                                                                                                                                                                                                                                                                                                                                    ## numbers, 
                                                                                                                                                                                                                                                                                                                                                    ## and 
                                                                                                                                                                                                                                                                                                                                                    ## hyphens.
  var path_402656568 = newJObject()
  var body_402656569 = newJObject()
  if body != nil:
    body_402656569 = body
  add(path_402656568, "backupVaultName", newJString(backupVaultName))
  result = call_402656567.call(path_402656568, nil, nil, nil, body_402656569)

var createBackupVault* = Call_CreateBackupVault_402656554(
    name: "createBackupVault", meth: HttpMethod.HttpPut,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}",
    validator: validate_CreateBackupVault_402656555, base: "/",
    makeUrl: url_CreateBackupVault_402656556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBackupVault_402656540 = ref object of OpenApiRestCall_402656044
proc url_DescribeBackupVault_402656542(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path,
         "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
                 (kind: VariableSegment, value: "backupVaultName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeBackupVault_402656541(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns metadata about a backup vault specified by its name.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
                                 ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `backupVaultName` field"
  var valid_402656543 = path.getOrDefault("backupVaultName")
  valid_402656543 = validateParameter(valid_402656543, JString, required = true,
                                      default = nil)
  if valid_402656543 != nil:
    section.add "backupVaultName", valid_402656543
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
  var valid_402656544 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-Security-Token", valid_402656544
  var valid_402656545 = header.getOrDefault("X-Amz-Signature")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "X-Amz-Signature", valid_402656545
  var valid_402656546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656546
  var valid_402656547 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-Algorithm", valid_402656547
  var valid_402656548 = header.getOrDefault("X-Amz-Date")
  valid_402656548 = validateParameter(valid_402656548, JString,
                                      required = false, default = nil)
  if valid_402656548 != nil:
    section.add "X-Amz-Date", valid_402656548
  var valid_402656549 = header.getOrDefault("X-Amz-Credential")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-Credential", valid_402656549
  var valid_402656550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656551: Call_DescribeBackupVault_402656540;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns metadata about a backup vault specified by its name.
                                                                                         ## 
  let valid = call_402656551.validator(path, query, header, formData, body, _)
  let scheme = call_402656551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656551.makeUrl(scheme.get, call_402656551.host, call_402656551.base,
                                   call_402656551.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656551, uri, valid, _)

proc call*(call_402656552: Call_DescribeBackupVault_402656540;
           backupVaultName: string): Recallable =
  ## describeBackupVault
  ## Returns metadata about a backup vault specified by its name.
  ##   
                                                                 ## backupVaultName: string (required)
                                                                 ##                  
                                                                 ## : 
                                                                 ## The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_402656553 = newJObject()
  add(path_402656553, "backupVaultName", newJString(backupVaultName))
  result = call_402656552.call(path_402656553, nil, nil, nil, nil)

var describeBackupVault* = Call_DescribeBackupVault_402656540(
    name: "describeBackupVault", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}",
    validator: validate_DescribeBackupVault_402656541, base: "/",
    makeUrl: url_DescribeBackupVault_402656542,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupVault_402656570 = ref object of OpenApiRestCall_402656044
proc url_DeleteBackupVault_402656572(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path,
         "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
                 (kind: VariableSegment, value: "backupVaultName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBackupVault_402656571(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the backup vault identified by its name. A vault can be deleted only if it is empty.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
                                 ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and theAWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `backupVaultName` field"
  var valid_402656573 = path.getOrDefault("backupVaultName")
  valid_402656573 = validateParameter(valid_402656573, JString, required = true,
                                      default = nil)
  if valid_402656573 != nil:
    section.add "backupVaultName", valid_402656573
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
  var valid_402656574 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-Security-Token", valid_402656574
  var valid_402656575 = header.getOrDefault("X-Amz-Signature")
  valid_402656575 = validateParameter(valid_402656575, JString,
                                      required = false, default = nil)
  if valid_402656575 != nil:
    section.add "X-Amz-Signature", valid_402656575
  var valid_402656576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656576 = validateParameter(valid_402656576, JString,
                                      required = false, default = nil)
  if valid_402656576 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656576
  var valid_402656577 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-Algorithm", valid_402656577
  var valid_402656578 = header.getOrDefault("X-Amz-Date")
  valid_402656578 = validateParameter(valid_402656578, JString,
                                      required = false, default = nil)
  if valid_402656578 != nil:
    section.add "X-Amz-Date", valid_402656578
  var valid_402656579 = header.getOrDefault("X-Amz-Credential")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "X-Amz-Credential", valid_402656579
  var valid_402656580 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656580 = validateParameter(valid_402656580, JString,
                                      required = false, default = nil)
  if valid_402656580 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656580
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656581: Call_DeleteBackupVault_402656570;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the backup vault identified by its name. A vault can be deleted only if it is empty.
                                                                                         ## 
  let valid = call_402656581.validator(path, query, header, formData, body, _)
  let scheme = call_402656581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656581.makeUrl(scheme.get, call_402656581.host, call_402656581.base,
                                   call_402656581.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656581, uri, valid, _)

proc call*(call_402656582: Call_DeleteBackupVault_402656570;
           backupVaultName: string): Recallable =
  ## deleteBackupVault
  ## Deletes the backup vault identified by its name. A vault can be deleted only if it is empty.
  ##   
                                                                                                 ## backupVaultName: string (required)
                                                                                                 ##                  
                                                                                                 ## : 
                                                                                                 ## The 
                                                                                                 ## name 
                                                                                                 ## of 
                                                                                                 ## a 
                                                                                                 ## logical 
                                                                                                 ## container 
                                                                                                 ## where 
                                                                                                 ## backups 
                                                                                                 ## are 
                                                                                                 ## stored. 
                                                                                                 ## Backup 
                                                                                                 ## vaults 
                                                                                                 ## are 
                                                                                                 ## identified 
                                                                                                 ## by 
                                                                                                 ## names 
                                                                                                 ## that 
                                                                                                 ## are 
                                                                                                 ## unique 
                                                                                                 ## to 
                                                                                                 ## the 
                                                                                                 ## account 
                                                                                                 ## used 
                                                                                                 ## to 
                                                                                                 ## create 
                                                                                                 ## them 
                                                                                                 ## and 
                                                                                                 ## theAWS 
                                                                                                 ## Region 
                                                                                                 ## where 
                                                                                                 ## they 
                                                                                                 ## are 
                                                                                                 ## created. 
                                                                                                 ## They 
                                                                                                 ## consist 
                                                                                                 ## of 
                                                                                                 ## lowercase 
                                                                                                 ## letters, 
                                                                                                 ## numbers, 
                                                                                                 ## and 
                                                                                                 ## hyphens.
  var path_402656583 = newJObject()
  add(path_402656583, "backupVaultName", newJString(backupVaultName))
  result = call_402656582.call(path_402656583, nil, nil, nil, nil)

var deleteBackupVault* = Call_DeleteBackupVault_402656570(
    name: "deleteBackupVault", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}",
    validator: validate_DeleteBackupVault_402656571, base: "/",
    makeUrl: url_DeleteBackupVault_402656572,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBackupPlan_402656584 = ref object of OpenApiRestCall_402656044
proc url_UpdateBackupPlan_402656586(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupPlanId" in path, "`backupPlanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/plans/"),
                 (kind: VariableSegment, value: "backupPlanId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateBackupPlan_402656585(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Replaces the body of a saved backup plan identified by its <code>backupPlanId</code> with the input document in JSON format. The new version is uniquely identified by a <code>VersionId</code>.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupPlanId: JString (required)
                                 ##               : Uniquely identifies a backup plan.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `backupPlanId` field"
  var valid_402656587 = path.getOrDefault("backupPlanId")
  valid_402656587 = validateParameter(valid_402656587, JString, required = true,
                                      default = nil)
  if valid_402656587 != nil:
    section.add "backupPlanId", valid_402656587
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
  var valid_402656588 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Security-Token", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-Signature")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-Signature", valid_402656589
  var valid_402656590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656590 = validateParameter(valid_402656590, JString,
                                      required = false, default = nil)
  if valid_402656590 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656590
  var valid_402656591 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "X-Amz-Algorithm", valid_402656591
  var valid_402656592 = header.getOrDefault("X-Amz-Date")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "X-Amz-Date", valid_402656592
  var valid_402656593 = header.getOrDefault("X-Amz-Credential")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-Credential", valid_402656593
  var valid_402656594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656594
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

proc call*(call_402656596: Call_UpdateBackupPlan_402656584;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Replaces the body of a saved backup plan identified by its <code>backupPlanId</code> with the input document in JSON format. The new version is uniquely identified by a <code>VersionId</code>.
                                                                                         ## 
  let valid = call_402656596.validator(path, query, header, formData, body, _)
  let scheme = call_402656596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656596.makeUrl(scheme.get, call_402656596.host, call_402656596.base,
                                   call_402656596.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656596, uri, valid, _)

proc call*(call_402656597: Call_UpdateBackupPlan_402656584;
           backupPlanId: string; body: JsonNode): Recallable =
  ## updateBackupPlan
  ## Replaces the body of a saved backup plan identified by its <code>backupPlanId</code> with the input document in JSON format. The new version is uniquely identified by a <code>VersionId</code>.
  ##   
                                                                                                                                                                                                     ## backupPlanId: string (required)
                                                                                                                                                                                                     ##               
                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                     ## Uniquely 
                                                                                                                                                                                                     ## identifies 
                                                                                                                                                                                                     ## a 
                                                                                                                                                                                                     ## backup 
                                                                                                                                                                                                     ## plan.
  ##   
                                                                                                                                                                                                             ## body: JObject (required)
  var path_402656598 = newJObject()
  var body_402656599 = newJObject()
  add(path_402656598, "backupPlanId", newJString(backupPlanId))
  if body != nil:
    body_402656599 = body
  result = call_402656597.call(path_402656598, nil, nil, nil, body_402656599)

var updateBackupPlan* = Call_UpdateBackupPlan_402656584(
    name: "updateBackupPlan", meth: HttpMethod.HttpPost,
    host: "backup.amazonaws.com", route: "/backup/plans/{backupPlanId}",
    validator: validate_UpdateBackupPlan_402656585, base: "/",
    makeUrl: url_UpdateBackupPlan_402656586,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupPlan_402656600 = ref object of OpenApiRestCall_402656044
proc url_DeleteBackupPlan_402656602(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupPlanId" in path, "`backupPlanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/plans/"),
                 (kind: VariableSegment, value: "backupPlanId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBackupPlan_402656601(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a backup plan. A backup plan can only be deleted after all associated selections of resources have been deleted. Deleting a backup plan deletes the current version of a backup plan. Previous versions, if any, will still exist.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupPlanId: JString (required)
                                 ##               : Uniquely identifies a backup plan.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `backupPlanId` field"
  var valid_402656603 = path.getOrDefault("backupPlanId")
  valid_402656603 = validateParameter(valid_402656603, JString, required = true,
                                      default = nil)
  if valid_402656603 != nil:
    section.add "backupPlanId", valid_402656603
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
  var valid_402656604 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-Security-Token", valid_402656604
  var valid_402656605 = header.getOrDefault("X-Amz-Signature")
  valid_402656605 = validateParameter(valid_402656605, JString,
                                      required = false, default = nil)
  if valid_402656605 != nil:
    section.add "X-Amz-Signature", valid_402656605
  var valid_402656606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656606 = validateParameter(valid_402656606, JString,
                                      required = false, default = nil)
  if valid_402656606 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656606
  var valid_402656607 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656607 = validateParameter(valid_402656607, JString,
                                      required = false, default = nil)
  if valid_402656607 != nil:
    section.add "X-Amz-Algorithm", valid_402656607
  var valid_402656608 = header.getOrDefault("X-Amz-Date")
  valid_402656608 = validateParameter(valid_402656608, JString,
                                      required = false, default = nil)
  if valid_402656608 != nil:
    section.add "X-Amz-Date", valid_402656608
  var valid_402656609 = header.getOrDefault("X-Amz-Credential")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-Credential", valid_402656609
  var valid_402656610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656610
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656611: Call_DeleteBackupPlan_402656600;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a backup plan. A backup plan can only be deleted after all associated selections of resources have been deleted. Deleting a backup plan deletes the current version of a backup plan. Previous versions, if any, will still exist.
                                                                                         ## 
  let valid = call_402656611.validator(path, query, header, formData, body, _)
  let scheme = call_402656611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656611.makeUrl(scheme.get, call_402656611.host, call_402656611.base,
                                   call_402656611.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656611, uri, valid, _)

proc call*(call_402656612: Call_DeleteBackupPlan_402656600; backupPlanId: string): Recallable =
  ## deleteBackupPlan
  ## Deletes a backup plan. A backup plan can only be deleted after all associated selections of resources have been deleted. Deleting a backup plan deletes the current version of a backup plan. Previous versions, if any, will still exist.
  ##   
                                                                                                                                                                                                                                               ## backupPlanId: string (required)
                                                                                                                                                                                                                                               ##               
                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                               ## Uniquely 
                                                                                                                                                                                                                                               ## identifies 
                                                                                                                                                                                                                                               ## a 
                                                                                                                                                                                                                                               ## backup 
                                                                                                                                                                                                                                               ## plan.
  var path_402656613 = newJObject()
  add(path_402656613, "backupPlanId", newJString(backupPlanId))
  result = call_402656612.call(path_402656613, nil, nil, nil, nil)

var deleteBackupPlan* = Call_DeleteBackupPlan_402656600(
    name: "deleteBackupPlan", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com", route: "/backup/plans/{backupPlanId}",
    validator: validate_DeleteBackupPlan_402656601, base: "/",
    makeUrl: url_DeleteBackupPlan_402656602,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupSelection_402656614 = ref object of OpenApiRestCall_402656044
proc url_GetBackupSelection_402656616(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupPlanId" in path, "`backupPlanId` is a required path parameter"
  assert "selectionId" in path, "`selectionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/plans/"),
                 (kind: VariableSegment, value: "backupPlanId"),
                 (kind: ConstantSegment, value: "/selections/"),
                 (kind: VariableSegment, value: "selectionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBackupSelection_402656615(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns selection metadata and a document in JSON format that specifies a list of resources that are associated with a backup plan.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupPlanId: JString (required)
                                 ##               : Uniquely identifies a backup plan.
  ##   
                                                                                      ## selectionId: JString (required)
                                                                                      ##              
                                                                                      ## : 
                                                                                      ## Uniquely 
                                                                                      ## identifies 
                                                                                      ## the 
                                                                                      ## body 
                                                                                      ## of 
                                                                                      ## a 
                                                                                      ## request 
                                                                                      ## to 
                                                                                      ## assign 
                                                                                      ## a 
                                                                                      ## set 
                                                                                      ## of 
                                                                                      ## resources 
                                                                                      ## to 
                                                                                      ## a 
                                                                                      ## backup 
                                                                                      ## plan.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `backupPlanId` field"
  var valid_402656617 = path.getOrDefault("backupPlanId")
  valid_402656617 = validateParameter(valid_402656617, JString, required = true,
                                      default = nil)
  if valid_402656617 != nil:
    section.add "backupPlanId", valid_402656617
  var valid_402656618 = path.getOrDefault("selectionId")
  valid_402656618 = validateParameter(valid_402656618, JString, required = true,
                                      default = nil)
  if valid_402656618 != nil:
    section.add "selectionId", valid_402656618
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
  var valid_402656619 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-Security-Token", valid_402656619
  var valid_402656620 = header.getOrDefault("X-Amz-Signature")
  valid_402656620 = validateParameter(valid_402656620, JString,
                                      required = false, default = nil)
  if valid_402656620 != nil:
    section.add "X-Amz-Signature", valid_402656620
  var valid_402656621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656621
  var valid_402656622 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656622 = validateParameter(valid_402656622, JString,
                                      required = false, default = nil)
  if valid_402656622 != nil:
    section.add "X-Amz-Algorithm", valid_402656622
  var valid_402656623 = header.getOrDefault("X-Amz-Date")
  valid_402656623 = validateParameter(valid_402656623, JString,
                                      required = false, default = nil)
  if valid_402656623 != nil:
    section.add "X-Amz-Date", valid_402656623
  var valid_402656624 = header.getOrDefault("X-Amz-Credential")
  valid_402656624 = validateParameter(valid_402656624, JString,
                                      required = false, default = nil)
  if valid_402656624 != nil:
    section.add "X-Amz-Credential", valid_402656624
  var valid_402656625 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656625 = validateParameter(valid_402656625, JString,
                                      required = false, default = nil)
  if valid_402656625 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656625
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656626: Call_GetBackupSelection_402656614;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns selection metadata and a document in JSON format that specifies a list of resources that are associated with a backup plan.
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

proc call*(call_402656627: Call_GetBackupSelection_402656614;
           backupPlanId: string; selectionId: string): Recallable =
  ## getBackupSelection
  ## Returns selection metadata and a document in JSON format that specifies a list of resources that are associated with a backup plan.
  ##   
                                                                                                                                        ## backupPlanId: string (required)
                                                                                                                                        ##               
                                                                                                                                        ## : 
                                                                                                                                        ## Uniquely 
                                                                                                                                        ## identifies 
                                                                                                                                        ## a 
                                                                                                                                        ## backup 
                                                                                                                                        ## plan.
  ##   
                                                                                                                                                ## selectionId: string (required)
                                                                                                                                                ##              
                                                                                                                                                ## : 
                                                                                                                                                ## Uniquely 
                                                                                                                                                ## identifies 
                                                                                                                                                ## the 
                                                                                                                                                ## body 
                                                                                                                                                ## of 
                                                                                                                                                ## a 
                                                                                                                                                ## request 
                                                                                                                                                ## to 
                                                                                                                                                ## assign 
                                                                                                                                                ## a 
                                                                                                                                                ## set 
                                                                                                                                                ## of 
                                                                                                                                                ## resources 
                                                                                                                                                ## to 
                                                                                                                                                ## a 
                                                                                                                                                ## backup 
                                                                                                                                                ## plan.
  var path_402656628 = newJObject()
  add(path_402656628, "backupPlanId", newJString(backupPlanId))
  add(path_402656628, "selectionId", newJString(selectionId))
  result = call_402656627.call(path_402656628, nil, nil, nil, nil)

var getBackupSelection* = Call_GetBackupSelection_402656614(
    name: "getBackupSelection", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/selections/{selectionId}",
    validator: validate_GetBackupSelection_402656615, base: "/",
    makeUrl: url_GetBackupSelection_402656616,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupSelection_402656629 = ref object of OpenApiRestCall_402656044
proc url_DeleteBackupSelection_402656631(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupPlanId" in path, "`backupPlanId` is a required path parameter"
  assert "selectionId" in path, "`selectionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/plans/"),
                 (kind: VariableSegment, value: "backupPlanId"),
                 (kind: ConstantSegment, value: "/selections/"),
                 (kind: VariableSegment, value: "selectionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBackupSelection_402656630(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the resource selection associated with a backup plan that is specified by the <code>SelectionId</code>.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupPlanId: JString (required)
                                 ##               : Uniquely identifies a backup plan.
  ##   
                                                                                      ## selectionId: JString (required)
                                                                                      ##              
                                                                                      ## : 
                                                                                      ## Uniquely 
                                                                                      ## identifies 
                                                                                      ## the 
                                                                                      ## body 
                                                                                      ## of 
                                                                                      ## a 
                                                                                      ## request 
                                                                                      ## to 
                                                                                      ## assign 
                                                                                      ## a 
                                                                                      ## set 
                                                                                      ## of 
                                                                                      ## resources 
                                                                                      ## to 
                                                                                      ## a 
                                                                                      ## backup 
                                                                                      ## plan.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `backupPlanId` field"
  var valid_402656632 = path.getOrDefault("backupPlanId")
  valid_402656632 = validateParameter(valid_402656632, JString, required = true,
                                      default = nil)
  if valid_402656632 != nil:
    section.add "backupPlanId", valid_402656632
  var valid_402656633 = path.getOrDefault("selectionId")
  valid_402656633 = validateParameter(valid_402656633, JString, required = true,
                                      default = nil)
  if valid_402656633 != nil:
    section.add "selectionId", valid_402656633
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
  var valid_402656634 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-Security-Token", valid_402656634
  var valid_402656635 = header.getOrDefault("X-Amz-Signature")
  valid_402656635 = validateParameter(valid_402656635, JString,
                                      required = false, default = nil)
  if valid_402656635 != nil:
    section.add "X-Amz-Signature", valid_402656635
  var valid_402656636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656636 = validateParameter(valid_402656636, JString,
                                      required = false, default = nil)
  if valid_402656636 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656636
  var valid_402656637 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656637 = validateParameter(valid_402656637, JString,
                                      required = false, default = nil)
  if valid_402656637 != nil:
    section.add "X-Amz-Algorithm", valid_402656637
  var valid_402656638 = header.getOrDefault("X-Amz-Date")
  valid_402656638 = validateParameter(valid_402656638, JString,
                                      required = false, default = nil)
  if valid_402656638 != nil:
    section.add "X-Amz-Date", valid_402656638
  var valid_402656639 = header.getOrDefault("X-Amz-Credential")
  valid_402656639 = validateParameter(valid_402656639, JString,
                                      required = false, default = nil)
  if valid_402656639 != nil:
    section.add "X-Amz-Credential", valid_402656639
  var valid_402656640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656640 = validateParameter(valid_402656640, JString,
                                      required = false, default = nil)
  if valid_402656640 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656640
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656641: Call_DeleteBackupSelection_402656629;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the resource selection associated with a backup plan that is specified by the <code>SelectionId</code>.
                                                                                         ## 
  let valid = call_402656641.validator(path, query, header, formData, body, _)
  let scheme = call_402656641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656641.makeUrl(scheme.get, call_402656641.host, call_402656641.base,
                                   call_402656641.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656641, uri, valid, _)

proc call*(call_402656642: Call_DeleteBackupSelection_402656629;
           backupPlanId: string; selectionId: string): Recallable =
  ## deleteBackupSelection
  ## Deletes the resource selection associated with a backup plan that is specified by the <code>SelectionId</code>.
  ##   
                                                                                                                    ## backupPlanId: string (required)
                                                                                                                    ##               
                                                                                                                    ## : 
                                                                                                                    ## Uniquely 
                                                                                                                    ## identifies 
                                                                                                                    ## a 
                                                                                                                    ## backup 
                                                                                                                    ## plan.
  ##   
                                                                                                                            ## selectionId: string (required)
                                                                                                                            ##              
                                                                                                                            ## : 
                                                                                                                            ## Uniquely 
                                                                                                                            ## identifies 
                                                                                                                            ## the 
                                                                                                                            ## body 
                                                                                                                            ## of 
                                                                                                                            ## a 
                                                                                                                            ## request 
                                                                                                                            ## to 
                                                                                                                            ## assign 
                                                                                                                            ## a 
                                                                                                                            ## set 
                                                                                                                            ## of 
                                                                                                                            ## resources 
                                                                                                                            ## to 
                                                                                                                            ## a 
                                                                                                                            ## backup 
                                                                                                                            ## plan.
  var path_402656643 = newJObject()
  add(path_402656643, "backupPlanId", newJString(backupPlanId))
  add(path_402656643, "selectionId", newJString(selectionId))
  result = call_402656642.call(path_402656643, nil, nil, nil, nil)

var deleteBackupSelection* = Call_DeleteBackupSelection_402656629(
    name: "deleteBackupSelection", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/selections/{selectionId}",
    validator: validate_DeleteBackupSelection_402656630, base: "/",
    makeUrl: url_DeleteBackupSelection_402656631,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBackupVaultAccessPolicy_402656658 = ref object of OpenApiRestCall_402656044
proc url_PutBackupVaultAccessPolicy_402656660(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path,
         "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
                 (kind: VariableSegment, value: "backupVaultName"),
                 (kind: ConstantSegment, value: "/access-policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutBackupVaultAccessPolicy_402656659(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Sets a resource-based policy that is used to manage access permissions on the target backup vault. Requires a backup vault name and an access policy document in JSON format.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
                                 ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `backupVaultName` field"
  var valid_402656661 = path.getOrDefault("backupVaultName")
  valid_402656661 = validateParameter(valid_402656661, JString, required = true,
                                      default = nil)
  if valid_402656661 != nil:
    section.add "backupVaultName", valid_402656661
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
  var valid_402656662 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Security-Token", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Signature")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Signature", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656664
  var valid_402656665 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656665 = validateParameter(valid_402656665, JString,
                                      required = false, default = nil)
  if valid_402656665 != nil:
    section.add "X-Amz-Algorithm", valid_402656665
  var valid_402656666 = header.getOrDefault("X-Amz-Date")
  valid_402656666 = validateParameter(valid_402656666, JString,
                                      required = false, default = nil)
  if valid_402656666 != nil:
    section.add "X-Amz-Date", valid_402656666
  var valid_402656667 = header.getOrDefault("X-Amz-Credential")
  valid_402656667 = validateParameter(valid_402656667, JString,
                                      required = false, default = nil)
  if valid_402656667 != nil:
    section.add "X-Amz-Credential", valid_402656667
  var valid_402656668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656668 = validateParameter(valid_402656668, JString,
                                      required = false, default = nil)
  if valid_402656668 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656668
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

proc call*(call_402656670: Call_PutBackupVaultAccessPolicy_402656658;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Sets a resource-based policy that is used to manage access permissions on the target backup vault. Requires a backup vault name and an access policy document in JSON format.
                                                                                         ## 
  let valid = call_402656670.validator(path, query, header, formData, body, _)
  let scheme = call_402656670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656670.makeUrl(scheme.get, call_402656670.host, call_402656670.base,
                                   call_402656670.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656670, uri, valid, _)

proc call*(call_402656671: Call_PutBackupVaultAccessPolicy_402656658;
           body: JsonNode; backupVaultName: string): Recallable =
  ## putBackupVaultAccessPolicy
  ## Sets a resource-based policy that is used to manage access permissions on the target backup vault. Requires a backup vault name and an access policy document in JSON format.
  ##   
                                                                                                                                                                                  ## body: JObject (required)
  ##   
                                                                                                                                                                                                             ## backupVaultName: string (required)
                                                                                                                                                                                                             ##                  
                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                             ## The 
                                                                                                                                                                                                             ## name 
                                                                                                                                                                                                             ## of 
                                                                                                                                                                                                             ## a 
                                                                                                                                                                                                             ## logical 
                                                                                                                                                                                                             ## container 
                                                                                                                                                                                                             ## where 
                                                                                                                                                                                                             ## backups 
                                                                                                                                                                                                             ## are 
                                                                                                                                                                                                             ## stored. 
                                                                                                                                                                                                             ## Backup 
                                                                                                                                                                                                             ## vaults 
                                                                                                                                                                                                             ## are 
                                                                                                                                                                                                             ## identified 
                                                                                                                                                                                                             ## by 
                                                                                                                                                                                                             ## names 
                                                                                                                                                                                                             ## that 
                                                                                                                                                                                                             ## are 
                                                                                                                                                                                                             ## unique 
                                                                                                                                                                                                             ## to 
                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                             ## account 
                                                                                                                                                                                                             ## used 
                                                                                                                                                                                                             ## to 
                                                                                                                                                                                                             ## create 
                                                                                                                                                                                                             ## them 
                                                                                                                                                                                                             ## and 
                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                             ## AWS 
                                                                                                                                                                                                             ## Region 
                                                                                                                                                                                                             ## where 
                                                                                                                                                                                                             ## they 
                                                                                                                                                                                                             ## are 
                                                                                                                                                                                                             ## created. 
                                                                                                                                                                                                             ## They 
                                                                                                                                                                                                             ## consist 
                                                                                                                                                                                                             ## of 
                                                                                                                                                                                                             ## lowercase 
                                                                                                                                                                                                             ## letters, 
                                                                                                                                                                                                             ## numbers, 
                                                                                                                                                                                                             ## and 
                                                                                                                                                                                                             ## hyphens.
  var path_402656672 = newJObject()
  var body_402656673 = newJObject()
  if body != nil:
    body_402656673 = body
  add(path_402656672, "backupVaultName", newJString(backupVaultName))
  result = call_402656671.call(path_402656672, nil, nil, nil, body_402656673)

var putBackupVaultAccessPolicy* = Call_PutBackupVaultAccessPolicy_402656658(
    name: "putBackupVaultAccessPolicy", meth: HttpMethod.HttpPut,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/access-policy",
    validator: validate_PutBackupVaultAccessPolicy_402656659, base: "/",
    makeUrl: url_PutBackupVaultAccessPolicy_402656660,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupVaultAccessPolicy_402656644 = ref object of OpenApiRestCall_402656044
proc url_GetBackupVaultAccessPolicy_402656646(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path,
         "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
                 (kind: VariableSegment, value: "backupVaultName"),
                 (kind: ConstantSegment, value: "/access-policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBackupVaultAccessPolicy_402656645(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns the access policy document that is associated with the named backup vault.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
                                 ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `backupVaultName` field"
  var valid_402656647 = path.getOrDefault("backupVaultName")
  valid_402656647 = validateParameter(valid_402656647, JString, required = true,
                                      default = nil)
  if valid_402656647 != nil:
    section.add "backupVaultName", valid_402656647
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
  var valid_402656648 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Security-Token", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-Signature")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-Signature", valid_402656649
  var valid_402656650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656650 = validateParameter(valid_402656650, JString,
                                      required = false, default = nil)
  if valid_402656650 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656650
  var valid_402656651 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656651 = validateParameter(valid_402656651, JString,
                                      required = false, default = nil)
  if valid_402656651 != nil:
    section.add "X-Amz-Algorithm", valid_402656651
  var valid_402656652 = header.getOrDefault("X-Amz-Date")
  valid_402656652 = validateParameter(valid_402656652, JString,
                                      required = false, default = nil)
  if valid_402656652 != nil:
    section.add "X-Amz-Date", valid_402656652
  var valid_402656653 = header.getOrDefault("X-Amz-Credential")
  valid_402656653 = validateParameter(valid_402656653, JString,
                                      required = false, default = nil)
  if valid_402656653 != nil:
    section.add "X-Amz-Credential", valid_402656653
  var valid_402656654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656654 = validateParameter(valid_402656654, JString,
                                      required = false, default = nil)
  if valid_402656654 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656655: Call_GetBackupVaultAccessPolicy_402656644;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the access policy document that is associated with the named backup vault.
                                                                                         ## 
  let valid = call_402656655.validator(path, query, header, formData, body, _)
  let scheme = call_402656655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656655.makeUrl(scheme.get, call_402656655.host, call_402656655.base,
                                   call_402656655.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656655, uri, valid, _)

proc call*(call_402656656: Call_GetBackupVaultAccessPolicy_402656644;
           backupVaultName: string): Recallable =
  ## getBackupVaultAccessPolicy
  ## Returns the access policy document that is associated with the named backup vault.
  ##   
                                                                                       ## backupVaultName: string (required)
                                                                                       ##                  
                                                                                       ## : 
                                                                                       ## The 
                                                                                       ## name 
                                                                                       ## of 
                                                                                       ## a 
                                                                                       ## logical 
                                                                                       ## container 
                                                                                       ## where 
                                                                                       ## backups 
                                                                                       ## are 
                                                                                       ## stored. 
                                                                                       ## Backup 
                                                                                       ## vaults 
                                                                                       ## are 
                                                                                       ## identified 
                                                                                       ## by 
                                                                                       ## names 
                                                                                       ## that 
                                                                                       ## are 
                                                                                       ## unique 
                                                                                       ## to 
                                                                                       ## the 
                                                                                       ## account 
                                                                                       ## used 
                                                                                       ## to 
                                                                                       ## create 
                                                                                       ## them 
                                                                                       ## and 
                                                                                       ## the 
                                                                                       ## AWS 
                                                                                       ## Region 
                                                                                       ## where 
                                                                                       ## they 
                                                                                       ## are 
                                                                                       ## created. 
                                                                                       ## They 
                                                                                       ## consist 
                                                                                       ## of 
                                                                                       ## lowercase 
                                                                                       ## letters, 
                                                                                       ## numbers, 
                                                                                       ## and 
                                                                                       ## hyphens.
  var path_402656657 = newJObject()
  add(path_402656657, "backupVaultName", newJString(backupVaultName))
  result = call_402656656.call(path_402656657, nil, nil, nil, nil)

var getBackupVaultAccessPolicy* = Call_GetBackupVaultAccessPolicy_402656644(
    name: "getBackupVaultAccessPolicy", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/access-policy",
    validator: validate_GetBackupVaultAccessPolicy_402656645, base: "/",
    makeUrl: url_GetBackupVaultAccessPolicy_402656646,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupVaultAccessPolicy_402656674 = ref object of OpenApiRestCall_402656044
proc url_DeleteBackupVaultAccessPolicy_402656676(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path,
         "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
                 (kind: VariableSegment, value: "backupVaultName"),
                 (kind: ConstantSegment, value: "/access-policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBackupVaultAccessPolicy_402656675(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes the policy document that manages permissions on a backup vault.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
                                 ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `backupVaultName` field"
  var valid_402656677 = path.getOrDefault("backupVaultName")
  valid_402656677 = validateParameter(valid_402656677, JString, required = true,
                                      default = nil)
  if valid_402656677 != nil:
    section.add "backupVaultName", valid_402656677
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
  var valid_402656678 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Security-Token", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-Signature")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-Signature", valid_402656679
  var valid_402656680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656680 = validateParameter(valid_402656680, JString,
                                      required = false, default = nil)
  if valid_402656680 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656680
  var valid_402656681 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656681 = validateParameter(valid_402656681, JString,
                                      required = false, default = nil)
  if valid_402656681 != nil:
    section.add "X-Amz-Algorithm", valid_402656681
  var valid_402656682 = header.getOrDefault("X-Amz-Date")
  valid_402656682 = validateParameter(valid_402656682, JString,
                                      required = false, default = nil)
  if valid_402656682 != nil:
    section.add "X-Amz-Date", valid_402656682
  var valid_402656683 = header.getOrDefault("X-Amz-Credential")
  valid_402656683 = validateParameter(valid_402656683, JString,
                                      required = false, default = nil)
  if valid_402656683 != nil:
    section.add "X-Amz-Credential", valid_402656683
  var valid_402656684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656684 = validateParameter(valid_402656684, JString,
                                      required = false, default = nil)
  if valid_402656684 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656685: Call_DeleteBackupVaultAccessPolicy_402656674;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the policy document that manages permissions on a backup vault.
                                                                                         ## 
  let valid = call_402656685.validator(path, query, header, formData, body, _)
  let scheme = call_402656685.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656685.makeUrl(scheme.get, call_402656685.host, call_402656685.base,
                                   call_402656685.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656685, uri, valid, _)

proc call*(call_402656686: Call_DeleteBackupVaultAccessPolicy_402656674;
           backupVaultName: string): Recallable =
  ## deleteBackupVaultAccessPolicy
  ## Deletes the policy document that manages permissions on a backup vault.
  ##   
                                                                            ## backupVaultName: string (required)
                                                                            ##                  
                                                                            ## : 
                                                                            ## The 
                                                                            ## name 
                                                                            ## of 
                                                                            ## a 
                                                                            ## logical 
                                                                            ## container 
                                                                            ## where 
                                                                            ## backups 
                                                                            ## are 
                                                                            ## stored. 
                                                                            ## Backup 
                                                                            ## vaults 
                                                                            ## are 
                                                                            ## identified 
                                                                            ## by 
                                                                            ## names 
                                                                            ## that 
                                                                            ## are 
                                                                            ## unique 
                                                                            ## to 
                                                                            ## the 
                                                                            ## account 
                                                                            ## used 
                                                                            ## to 
                                                                            ## create 
                                                                            ## them 
                                                                            ## and 
                                                                            ## the 
                                                                            ## AWS 
                                                                            ## Region 
                                                                            ## where 
                                                                            ## they 
                                                                            ## are 
                                                                            ## created. 
                                                                            ## They 
                                                                            ## consist 
                                                                            ## of 
                                                                            ## lowercase 
                                                                            ## letters, 
                                                                            ## numbers, 
                                                                            ## and 
                                                                            ## hyphens.
  var path_402656687 = newJObject()
  add(path_402656687, "backupVaultName", newJString(backupVaultName))
  result = call_402656686.call(path_402656687, nil, nil, nil, nil)

var deleteBackupVaultAccessPolicy* = Call_DeleteBackupVaultAccessPolicy_402656674(
    name: "deleteBackupVaultAccessPolicy", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/access-policy",
    validator: validate_DeleteBackupVaultAccessPolicy_402656675, base: "/",
    makeUrl: url_DeleteBackupVaultAccessPolicy_402656676,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBackupVaultNotifications_402656702 = ref object of OpenApiRestCall_402656044
proc url_PutBackupVaultNotifications_402656704(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path,
         "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
                 (kind: VariableSegment, value: "backupVaultName"),
                 (kind: ConstantSegment, value: "/notification-configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutBackupVaultNotifications_402656703(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Turns on notifications on a backup vault for the specified topic and events.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
                                 ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `backupVaultName` field"
  var valid_402656705 = path.getOrDefault("backupVaultName")
  valid_402656705 = validateParameter(valid_402656705, JString, required = true,
                                      default = nil)
  if valid_402656705 != nil:
    section.add "backupVaultName", valid_402656705
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
  var valid_402656706 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Security-Token", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-Signature")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-Signature", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656708
  var valid_402656709 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-Algorithm", valid_402656709
  var valid_402656710 = header.getOrDefault("X-Amz-Date")
  valid_402656710 = validateParameter(valid_402656710, JString,
                                      required = false, default = nil)
  if valid_402656710 != nil:
    section.add "X-Amz-Date", valid_402656710
  var valid_402656711 = header.getOrDefault("X-Amz-Credential")
  valid_402656711 = validateParameter(valid_402656711, JString,
                                      required = false, default = nil)
  if valid_402656711 != nil:
    section.add "X-Amz-Credential", valid_402656711
  var valid_402656712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656712 = validateParameter(valid_402656712, JString,
                                      required = false, default = nil)
  if valid_402656712 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656712
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

proc call*(call_402656714: Call_PutBackupVaultNotifications_402656702;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Turns on notifications on a backup vault for the specified topic and events.
                                                                                         ## 
  let valid = call_402656714.validator(path, query, header, formData, body, _)
  let scheme = call_402656714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656714.makeUrl(scheme.get, call_402656714.host, call_402656714.base,
                                   call_402656714.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656714, uri, valid, _)

proc call*(call_402656715: Call_PutBackupVaultNotifications_402656702;
           body: JsonNode; backupVaultName: string): Recallable =
  ## putBackupVaultNotifications
  ## Turns on notifications on a backup vault for the specified topic and events.
  ##   
                                                                                 ## body: JObject (required)
  ##   
                                                                                                            ## backupVaultName: string (required)
                                                                                                            ##                  
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## name 
                                                                                                            ## of 
                                                                                                            ## a 
                                                                                                            ## logical 
                                                                                                            ## container 
                                                                                                            ## where 
                                                                                                            ## backups 
                                                                                                            ## are 
                                                                                                            ## stored. 
                                                                                                            ## Backup 
                                                                                                            ## vaults 
                                                                                                            ## are 
                                                                                                            ## identified 
                                                                                                            ## by 
                                                                                                            ## names 
                                                                                                            ## that 
                                                                                                            ## are 
                                                                                                            ## unique 
                                                                                                            ## to 
                                                                                                            ## the 
                                                                                                            ## account 
                                                                                                            ## used 
                                                                                                            ## to 
                                                                                                            ## create 
                                                                                                            ## them 
                                                                                                            ## and 
                                                                                                            ## the 
                                                                                                            ## AWS 
                                                                                                            ## Region 
                                                                                                            ## where 
                                                                                                            ## they 
                                                                                                            ## are 
                                                                                                            ## created. 
                                                                                                            ## They 
                                                                                                            ## consist 
                                                                                                            ## of 
                                                                                                            ## lowercase 
                                                                                                            ## letters, 
                                                                                                            ## numbers, 
                                                                                                            ## and 
                                                                                                            ## hyphens.
  var path_402656716 = newJObject()
  var body_402656717 = newJObject()
  if body != nil:
    body_402656717 = body
  add(path_402656716, "backupVaultName", newJString(backupVaultName))
  result = call_402656715.call(path_402656716, nil, nil, nil, body_402656717)

var putBackupVaultNotifications* = Call_PutBackupVaultNotifications_402656702(
    name: "putBackupVaultNotifications", meth: HttpMethod.HttpPut,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/notification-configuration",
    validator: validate_PutBackupVaultNotifications_402656703, base: "/",
    makeUrl: url_PutBackupVaultNotifications_402656704,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupVaultNotifications_402656688 = ref object of OpenApiRestCall_402656044
proc url_GetBackupVaultNotifications_402656690(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path,
         "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
                 (kind: VariableSegment, value: "backupVaultName"),
                 (kind: ConstantSegment, value: "/notification-configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBackupVaultNotifications_402656689(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns event notifications for the specified backup vault.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
                                 ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `backupVaultName` field"
  var valid_402656691 = path.getOrDefault("backupVaultName")
  valid_402656691 = validateParameter(valid_402656691, JString, required = true,
                                      default = nil)
  if valid_402656691 != nil:
    section.add "backupVaultName", valid_402656691
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
  var valid_402656692 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Security-Token", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-Signature")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-Signature", valid_402656693
  var valid_402656694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656694
  var valid_402656695 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656695 = validateParameter(valid_402656695, JString,
                                      required = false, default = nil)
  if valid_402656695 != nil:
    section.add "X-Amz-Algorithm", valid_402656695
  var valid_402656696 = header.getOrDefault("X-Amz-Date")
  valid_402656696 = validateParameter(valid_402656696, JString,
                                      required = false, default = nil)
  if valid_402656696 != nil:
    section.add "X-Amz-Date", valid_402656696
  var valid_402656697 = header.getOrDefault("X-Amz-Credential")
  valid_402656697 = validateParameter(valid_402656697, JString,
                                      required = false, default = nil)
  if valid_402656697 != nil:
    section.add "X-Amz-Credential", valid_402656697
  var valid_402656698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656698 = validateParameter(valid_402656698, JString,
                                      required = false, default = nil)
  if valid_402656698 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656699: Call_GetBackupVaultNotifications_402656688;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns event notifications for the specified backup vault.
                                                                                         ## 
  let valid = call_402656699.validator(path, query, header, formData, body, _)
  let scheme = call_402656699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656699.makeUrl(scheme.get, call_402656699.host, call_402656699.base,
                                   call_402656699.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656699, uri, valid, _)

proc call*(call_402656700: Call_GetBackupVaultNotifications_402656688;
           backupVaultName: string): Recallable =
  ## getBackupVaultNotifications
  ## Returns event notifications for the specified backup vault.
  ##   backupVaultName: string (required)
                                                                ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_402656701 = newJObject()
  add(path_402656701, "backupVaultName", newJString(backupVaultName))
  result = call_402656700.call(path_402656701, nil, nil, nil, nil)

var getBackupVaultNotifications* = Call_GetBackupVaultNotifications_402656688(
    name: "getBackupVaultNotifications", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/notification-configuration",
    validator: validate_GetBackupVaultNotifications_402656689, base: "/",
    makeUrl: url_GetBackupVaultNotifications_402656690,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupVaultNotifications_402656718 = ref object of OpenApiRestCall_402656044
proc url_DeleteBackupVaultNotifications_402656720(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path,
         "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
                 (kind: VariableSegment, value: "backupVaultName"),
                 (kind: ConstantSegment, value: "/notification-configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBackupVaultNotifications_402656719(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes event notifications for the specified backup vault.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
                                 ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `backupVaultName` field"
  var valid_402656721 = path.getOrDefault("backupVaultName")
  valid_402656721 = validateParameter(valid_402656721, JString, required = true,
                                      default = nil)
  if valid_402656721 != nil:
    section.add "backupVaultName", valid_402656721
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
  var valid_402656722 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Security-Token", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-Signature")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Signature", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656724
  var valid_402656725 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656725 = validateParameter(valid_402656725, JString,
                                      required = false, default = nil)
  if valid_402656725 != nil:
    section.add "X-Amz-Algorithm", valid_402656725
  var valid_402656726 = header.getOrDefault("X-Amz-Date")
  valid_402656726 = validateParameter(valid_402656726, JString,
                                      required = false, default = nil)
  if valid_402656726 != nil:
    section.add "X-Amz-Date", valid_402656726
  var valid_402656727 = header.getOrDefault("X-Amz-Credential")
  valid_402656727 = validateParameter(valid_402656727, JString,
                                      required = false, default = nil)
  if valid_402656727 != nil:
    section.add "X-Amz-Credential", valid_402656727
  var valid_402656728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656728 = validateParameter(valid_402656728, JString,
                                      required = false, default = nil)
  if valid_402656728 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656729: Call_DeleteBackupVaultNotifications_402656718;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes event notifications for the specified backup vault.
                                                                                         ## 
  let valid = call_402656729.validator(path, query, header, formData, body, _)
  let scheme = call_402656729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656729.makeUrl(scheme.get, call_402656729.host, call_402656729.base,
                                   call_402656729.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656729, uri, valid, _)

proc call*(call_402656730: Call_DeleteBackupVaultNotifications_402656718;
           backupVaultName: string): Recallable =
  ## deleteBackupVaultNotifications
  ## Deletes event notifications for the specified backup vault.
  ##   backupVaultName: string (required)
                                                                ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_402656731 = newJObject()
  add(path_402656731, "backupVaultName", newJString(backupVaultName))
  result = call_402656730.call(path_402656731, nil, nil, nil, nil)

var deleteBackupVaultNotifications* = Call_DeleteBackupVaultNotifications_402656718(
    name: "deleteBackupVaultNotifications", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/notification-configuration",
    validator: validate_DeleteBackupVaultNotifications_402656719, base: "/",
    makeUrl: url_DeleteBackupVaultNotifications_402656720,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRecoveryPointLifecycle_402656747 = ref object of OpenApiRestCall_402656044
proc url_UpdateRecoveryPointLifecycle_402656749(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path,
         "`backupVaultName` is a required path parameter"
  assert "recoveryPointArn" in path,
         "`recoveryPointArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
                 (kind: VariableSegment, value: "backupVaultName"),
                 (kind: ConstantSegment, value: "/recovery-points/"),
                 (kind: VariableSegment, value: "recoveryPointArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRecoveryPointLifecycle_402656748(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Sets the transition lifecycle of a recovery point.</p> <p>The lifecycle defines when a protected resource is transitioned to cold storage and when it expires. AWS Backup transitions and expires backups automatically according to the lifecycle that you define. </p> <p>Backups transitioned to cold storage must be stored in cold storage for a minimum of 90 days. Therefore, the “expire after days” setting must be 90 days greater than the “transition to cold after days” setting. The “transition to cold after days” setting cannot be changed after a backup has been transitioned to cold. </p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   recoveryPointArn: JString (required)
                                 ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
                                 ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  ##   
                                                                                                                                           ## backupVaultName: JString (required)
                                                                                                                                           ##                  
                                                                                                                                           ## : 
                                                                                                                                           ## The 
                                                                                                                                           ## name 
                                                                                                                                           ## of 
                                                                                                                                           ## a 
                                                                                                                                           ## logical 
                                                                                                                                           ## container 
                                                                                                                                           ## where 
                                                                                                                                           ## backups 
                                                                                                                                           ## are 
                                                                                                                                           ## stored. 
                                                                                                                                           ## Backup 
                                                                                                                                           ## vaults 
                                                                                                                                           ## are 
                                                                                                                                           ## identified 
                                                                                                                                           ## by 
                                                                                                                                           ## names 
                                                                                                                                           ## that 
                                                                                                                                           ## are 
                                                                                                                                           ## unique 
                                                                                                                                           ## to 
                                                                                                                                           ## the 
                                                                                                                                           ## account 
                                                                                                                                           ## used 
                                                                                                                                           ## to 
                                                                                                                                           ## create 
                                                                                                                                           ## them 
                                                                                                                                           ## and 
                                                                                                                                           ## the 
                                                                                                                                           ## AWS 
                                                                                                                                           ## Region 
                                                                                                                                           ## where 
                                                                                                                                           ## they 
                                                                                                                                           ## are 
                                                                                                                                           ## created. 
                                                                                                                                           ## They 
                                                                                                                                           ## consist 
                                                                                                                                           ## of 
                                                                                                                                           ## lowercase 
                                                                                                                                           ## letters, 
                                                                                                                                           ## numbers, 
                                                                                                                                           ## and 
                                                                                                                                           ## hyphens.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `recoveryPointArn` field"
  var valid_402656750 = path.getOrDefault("recoveryPointArn")
  valid_402656750 = validateParameter(valid_402656750, JString, required = true,
                                      default = nil)
  if valid_402656750 != nil:
    section.add "recoveryPointArn", valid_402656750
  var valid_402656751 = path.getOrDefault("backupVaultName")
  valid_402656751 = validateParameter(valid_402656751, JString, required = true,
                                      default = nil)
  if valid_402656751 != nil:
    section.add "backupVaultName", valid_402656751
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
  var valid_402656752 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Security-Token", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-Signature")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-Signature", valid_402656753
  var valid_402656754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656754
  var valid_402656755 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656755 = validateParameter(valid_402656755, JString,
                                      required = false, default = nil)
  if valid_402656755 != nil:
    section.add "X-Amz-Algorithm", valid_402656755
  var valid_402656756 = header.getOrDefault("X-Amz-Date")
  valid_402656756 = validateParameter(valid_402656756, JString,
                                      required = false, default = nil)
  if valid_402656756 != nil:
    section.add "X-Amz-Date", valid_402656756
  var valid_402656757 = header.getOrDefault("X-Amz-Credential")
  valid_402656757 = validateParameter(valid_402656757, JString,
                                      required = false, default = nil)
  if valid_402656757 != nil:
    section.add "X-Amz-Credential", valid_402656757
  var valid_402656758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656758 = validateParameter(valid_402656758, JString,
                                      required = false, default = nil)
  if valid_402656758 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656758
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

proc call*(call_402656760: Call_UpdateRecoveryPointLifecycle_402656747;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sets the transition lifecycle of a recovery point.</p> <p>The lifecycle defines when a protected resource is transitioned to cold storage and when it expires. AWS Backup transitions and expires backups automatically according to the lifecycle that you define. </p> <p>Backups transitioned to cold storage must be stored in cold storage for a minimum of 90 days. Therefore, the “expire after days” setting must be 90 days greater than the “transition to cold after days” setting. The “transition to cold after days” setting cannot be changed after a backup has been transitioned to cold. </p>
                                                                                         ## 
  let valid = call_402656760.validator(path, query, header, formData, body, _)
  let scheme = call_402656760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656760.makeUrl(scheme.get, call_402656760.host, call_402656760.base,
                                   call_402656760.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656760, uri, valid, _)

proc call*(call_402656761: Call_UpdateRecoveryPointLifecycle_402656747;
           recoveryPointArn: string; body: JsonNode; backupVaultName: string): Recallable =
  ## updateRecoveryPointLifecycle
  ## <p>Sets the transition lifecycle of a recovery point.</p> <p>The lifecycle defines when a protected resource is transitioned to cold storage and when it expires. AWS Backup transitions and expires backups automatically according to the lifecycle that you define. </p> <p>Backups transitioned to cold storage must be stored in cold storage for a minimum of 90 days. Therefore, the “expire after days” setting must be 90 days greater than the “transition to cold after days” setting. The “transition to cold after days” setting cannot be changed after a backup has been transitioned to cold. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## recoveryPointArn: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ##                   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## An 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## Resource 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## Name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## (ARN) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## uniquely 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## identifies 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## recovery 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## point; 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## for 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## example, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## backupVaultName: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ##                  
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## logical 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## container 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## where 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## backups 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## stored. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## Backup 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## vaults 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## identified 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## by 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## names 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## unique 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## account 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## used 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## create 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## them 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## AWS 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## Region 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## where 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## they 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## created. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## They 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## consist 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## lowercase 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## letters, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## numbers, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## hyphens.
  var path_402656762 = newJObject()
  var body_402656763 = newJObject()
  add(path_402656762, "recoveryPointArn", newJString(recoveryPointArn))
  if body != nil:
    body_402656763 = body
  add(path_402656762, "backupVaultName", newJString(backupVaultName))
  result = call_402656761.call(path_402656762, nil, nil, nil, body_402656763)

var updateRecoveryPointLifecycle* = Call_UpdateRecoveryPointLifecycle_402656747(
    name: "updateRecoveryPointLifecycle", meth: HttpMethod.HttpPost,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}/recovery-points/{recoveryPointArn}",
    validator: validate_UpdateRecoveryPointLifecycle_402656748, base: "/",
    makeUrl: url_UpdateRecoveryPointLifecycle_402656749,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRecoveryPoint_402656732 = ref object of OpenApiRestCall_402656044
proc url_DescribeRecoveryPoint_402656734(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path,
         "`backupVaultName` is a required path parameter"
  assert "recoveryPointArn" in path,
         "`recoveryPointArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
                 (kind: VariableSegment, value: "backupVaultName"),
                 (kind: ConstantSegment, value: "/recovery-points/"),
                 (kind: VariableSegment, value: "recoveryPointArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeRecoveryPoint_402656733(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns metadata associated with a recovery point, including ID, status, encryption, and lifecycle.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   recoveryPointArn: JString (required)
                                 ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
                                 ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  ##   
                                                                                                                                           ## backupVaultName: JString (required)
                                                                                                                                           ##                  
                                                                                                                                           ## : 
                                                                                                                                           ## The 
                                                                                                                                           ## name 
                                                                                                                                           ## of 
                                                                                                                                           ## a 
                                                                                                                                           ## logical 
                                                                                                                                           ## container 
                                                                                                                                           ## where 
                                                                                                                                           ## backups 
                                                                                                                                           ## are 
                                                                                                                                           ## stored. 
                                                                                                                                           ## Backup 
                                                                                                                                           ## vaults 
                                                                                                                                           ## are 
                                                                                                                                           ## identified 
                                                                                                                                           ## by 
                                                                                                                                           ## names 
                                                                                                                                           ## that 
                                                                                                                                           ## are 
                                                                                                                                           ## unique 
                                                                                                                                           ## to 
                                                                                                                                           ## the 
                                                                                                                                           ## account 
                                                                                                                                           ## used 
                                                                                                                                           ## to 
                                                                                                                                           ## create 
                                                                                                                                           ## them 
                                                                                                                                           ## and 
                                                                                                                                           ## the 
                                                                                                                                           ## AWS 
                                                                                                                                           ## Region 
                                                                                                                                           ## where 
                                                                                                                                           ## they 
                                                                                                                                           ## are 
                                                                                                                                           ## created. 
                                                                                                                                           ## They 
                                                                                                                                           ## consist 
                                                                                                                                           ## of 
                                                                                                                                           ## lowercase 
                                                                                                                                           ## letters, 
                                                                                                                                           ## numbers, 
                                                                                                                                           ## and 
                                                                                                                                           ## hyphens.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `recoveryPointArn` field"
  var valid_402656735 = path.getOrDefault("recoveryPointArn")
  valid_402656735 = validateParameter(valid_402656735, JString, required = true,
                                      default = nil)
  if valid_402656735 != nil:
    section.add "recoveryPointArn", valid_402656735
  var valid_402656736 = path.getOrDefault("backupVaultName")
  valid_402656736 = validateParameter(valid_402656736, JString, required = true,
                                      default = nil)
  if valid_402656736 != nil:
    section.add "backupVaultName", valid_402656736
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
  var valid_402656737 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Security-Token", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-Signature")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-Signature", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656739
  var valid_402656740 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656740 = validateParameter(valid_402656740, JString,
                                      required = false, default = nil)
  if valid_402656740 != nil:
    section.add "X-Amz-Algorithm", valid_402656740
  var valid_402656741 = header.getOrDefault("X-Amz-Date")
  valid_402656741 = validateParameter(valid_402656741, JString,
                                      required = false, default = nil)
  if valid_402656741 != nil:
    section.add "X-Amz-Date", valid_402656741
  var valid_402656742 = header.getOrDefault("X-Amz-Credential")
  valid_402656742 = validateParameter(valid_402656742, JString,
                                      required = false, default = nil)
  if valid_402656742 != nil:
    section.add "X-Amz-Credential", valid_402656742
  var valid_402656743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656743 = validateParameter(valid_402656743, JString,
                                      required = false, default = nil)
  if valid_402656743 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656744: Call_DescribeRecoveryPoint_402656732;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns metadata associated with a recovery point, including ID, status, encryption, and lifecycle.
                                                                                         ## 
  let valid = call_402656744.validator(path, query, header, formData, body, _)
  let scheme = call_402656744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656744.makeUrl(scheme.get, call_402656744.host, call_402656744.base,
                                   call_402656744.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656744, uri, valid, _)

proc call*(call_402656745: Call_DescribeRecoveryPoint_402656732;
           recoveryPointArn: string; backupVaultName: string): Recallable =
  ## describeRecoveryPoint
  ## Returns metadata associated with a recovery point, including ID, status, encryption, and lifecycle.
  ##   
                                                                                                        ## recoveryPointArn: string (required)
                                                                                                        ##                   
                                                                                                        ## : 
                                                                                                        ## An 
                                                                                                        ## Amazon 
                                                                                                        ## Resource 
                                                                                                        ## Name 
                                                                                                        ## (ARN) 
                                                                                                        ## that 
                                                                                                        ## uniquely 
                                                                                                        ## identifies 
                                                                                                        ## a 
                                                                                                        ## recovery 
                                                                                                        ## point; 
                                                                                                        ## for 
                                                                                                        ## example, 
                                                                                                        ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  ##   
                                                                                                                                                                                                                  ## backupVaultName: string (required)
                                                                                                                                                                                                                  ##                  
                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                  ## The 
                                                                                                                                                                                                                  ## name 
                                                                                                                                                                                                                  ## of 
                                                                                                                                                                                                                  ## a 
                                                                                                                                                                                                                  ## logical 
                                                                                                                                                                                                                  ## container 
                                                                                                                                                                                                                  ## where 
                                                                                                                                                                                                                  ## backups 
                                                                                                                                                                                                                  ## are 
                                                                                                                                                                                                                  ## stored. 
                                                                                                                                                                                                                  ## Backup 
                                                                                                                                                                                                                  ## vaults 
                                                                                                                                                                                                                  ## are 
                                                                                                                                                                                                                  ## identified 
                                                                                                                                                                                                                  ## by 
                                                                                                                                                                                                                  ## names 
                                                                                                                                                                                                                  ## that 
                                                                                                                                                                                                                  ## are 
                                                                                                                                                                                                                  ## unique 
                                                                                                                                                                                                                  ## to 
                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                  ## account 
                                                                                                                                                                                                                  ## used 
                                                                                                                                                                                                                  ## to 
                                                                                                                                                                                                                  ## create 
                                                                                                                                                                                                                  ## them 
                                                                                                                                                                                                                  ## and 
                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                  ## AWS 
                                                                                                                                                                                                                  ## Region 
                                                                                                                                                                                                                  ## where 
                                                                                                                                                                                                                  ## they 
                                                                                                                                                                                                                  ## are 
                                                                                                                                                                                                                  ## created. 
                                                                                                                                                                                                                  ## They 
                                                                                                                                                                                                                  ## consist 
                                                                                                                                                                                                                  ## of 
                                                                                                                                                                                                                  ## lowercase 
                                                                                                                                                                                                                  ## letters, 
                                                                                                                                                                                                                  ## numbers, 
                                                                                                                                                                                                                  ## and 
                                                                                                                                                                                                                  ## hyphens.
  var path_402656746 = newJObject()
  add(path_402656746, "recoveryPointArn", newJString(recoveryPointArn))
  add(path_402656746, "backupVaultName", newJString(backupVaultName))
  result = call_402656745.call(path_402656746, nil, nil, nil, nil)

var describeRecoveryPoint* = Call_DescribeRecoveryPoint_402656732(
    name: "describeRecoveryPoint", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}/recovery-points/{recoveryPointArn}",
    validator: validate_DescribeRecoveryPoint_402656733, base: "/",
    makeUrl: url_DescribeRecoveryPoint_402656734,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRecoveryPoint_402656764 = ref object of OpenApiRestCall_402656044
proc url_DeleteRecoveryPoint_402656766(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path,
         "`backupVaultName` is a required path parameter"
  assert "recoveryPointArn" in path,
         "`recoveryPointArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
                 (kind: VariableSegment, value: "backupVaultName"),
                 (kind: ConstantSegment, value: "/recovery-points/"),
                 (kind: VariableSegment, value: "recoveryPointArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRecoveryPoint_402656765(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the recovery point specified by a recovery point ID.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   recoveryPointArn: JString (required)
                                 ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
                                 ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  ##   
                                                                                                                                           ## backupVaultName: JString (required)
                                                                                                                                           ##                  
                                                                                                                                           ## : 
                                                                                                                                           ## The 
                                                                                                                                           ## name 
                                                                                                                                           ## of 
                                                                                                                                           ## a 
                                                                                                                                           ## logical 
                                                                                                                                           ## container 
                                                                                                                                           ## where 
                                                                                                                                           ## backups 
                                                                                                                                           ## are 
                                                                                                                                           ## stored. 
                                                                                                                                           ## Backup 
                                                                                                                                           ## vaults 
                                                                                                                                           ## are 
                                                                                                                                           ## identified 
                                                                                                                                           ## by 
                                                                                                                                           ## names 
                                                                                                                                           ## that 
                                                                                                                                           ## are 
                                                                                                                                           ## unique 
                                                                                                                                           ## to 
                                                                                                                                           ## the 
                                                                                                                                           ## account 
                                                                                                                                           ## used 
                                                                                                                                           ## to 
                                                                                                                                           ## create 
                                                                                                                                           ## them 
                                                                                                                                           ## and 
                                                                                                                                           ## the 
                                                                                                                                           ## AWS 
                                                                                                                                           ## Region 
                                                                                                                                           ## where 
                                                                                                                                           ## they 
                                                                                                                                           ## are 
                                                                                                                                           ## created. 
                                                                                                                                           ## They 
                                                                                                                                           ## consist 
                                                                                                                                           ## of 
                                                                                                                                           ## lowercase 
                                                                                                                                           ## letters, 
                                                                                                                                           ## numbers, 
                                                                                                                                           ## and 
                                                                                                                                           ## hyphens.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `recoveryPointArn` field"
  var valid_402656767 = path.getOrDefault("recoveryPointArn")
  valid_402656767 = validateParameter(valid_402656767, JString, required = true,
                                      default = nil)
  if valid_402656767 != nil:
    section.add "recoveryPointArn", valid_402656767
  var valid_402656768 = path.getOrDefault("backupVaultName")
  valid_402656768 = validateParameter(valid_402656768, JString, required = true,
                                      default = nil)
  if valid_402656768 != nil:
    section.add "backupVaultName", valid_402656768
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
  var valid_402656769 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-Security-Token", valid_402656769
  var valid_402656770 = header.getOrDefault("X-Amz-Signature")
  valid_402656770 = validateParameter(valid_402656770, JString,
                                      required = false, default = nil)
  if valid_402656770 != nil:
    section.add "X-Amz-Signature", valid_402656770
  var valid_402656771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656771 = validateParameter(valid_402656771, JString,
                                      required = false, default = nil)
  if valid_402656771 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656771
  var valid_402656772 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656772 = validateParameter(valid_402656772, JString,
                                      required = false, default = nil)
  if valid_402656772 != nil:
    section.add "X-Amz-Algorithm", valid_402656772
  var valid_402656773 = header.getOrDefault("X-Amz-Date")
  valid_402656773 = validateParameter(valid_402656773, JString,
                                      required = false, default = nil)
  if valid_402656773 != nil:
    section.add "X-Amz-Date", valid_402656773
  var valid_402656774 = header.getOrDefault("X-Amz-Credential")
  valid_402656774 = validateParameter(valid_402656774, JString,
                                      required = false, default = nil)
  if valid_402656774 != nil:
    section.add "X-Amz-Credential", valid_402656774
  var valid_402656775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656775 = validateParameter(valid_402656775, JString,
                                      required = false, default = nil)
  if valid_402656775 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656775
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656776: Call_DeleteRecoveryPoint_402656764;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the recovery point specified by a recovery point ID.
                                                                                         ## 
  let valid = call_402656776.validator(path, query, header, formData, body, _)
  let scheme = call_402656776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656776.makeUrl(scheme.get, call_402656776.host, call_402656776.base,
                                   call_402656776.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656776, uri, valid, _)

proc call*(call_402656777: Call_DeleteRecoveryPoint_402656764;
           recoveryPointArn: string; backupVaultName: string): Recallable =
  ## deleteRecoveryPoint
  ## Deletes the recovery point specified by a recovery point ID.
  ##   
                                                                 ## recoveryPointArn: string (required)
                                                                 ##                   
                                                                 ## : 
                                                                 ## An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
                                                                 ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  ##   
                                                                                                                                                                           ## backupVaultName: string (required)
                                                                                                                                                                           ##                  
                                                                                                                                                                           ## : 
                                                                                                                                                                           ## The 
                                                                                                                                                                           ## name 
                                                                                                                                                                           ## of 
                                                                                                                                                                           ## a 
                                                                                                                                                                           ## logical 
                                                                                                                                                                           ## container 
                                                                                                                                                                           ## where 
                                                                                                                                                                           ## backups 
                                                                                                                                                                           ## are 
                                                                                                                                                                           ## stored. 
                                                                                                                                                                           ## Backup 
                                                                                                                                                                           ## vaults 
                                                                                                                                                                           ## are 
                                                                                                                                                                           ## identified 
                                                                                                                                                                           ## by 
                                                                                                                                                                           ## names 
                                                                                                                                                                           ## that 
                                                                                                                                                                           ## are 
                                                                                                                                                                           ## unique 
                                                                                                                                                                           ## to 
                                                                                                                                                                           ## the 
                                                                                                                                                                           ## account 
                                                                                                                                                                           ## used 
                                                                                                                                                                           ## to 
                                                                                                                                                                           ## create 
                                                                                                                                                                           ## them 
                                                                                                                                                                           ## and 
                                                                                                                                                                           ## the 
                                                                                                                                                                           ## AWS 
                                                                                                                                                                           ## Region 
                                                                                                                                                                           ## where 
                                                                                                                                                                           ## they 
                                                                                                                                                                           ## are 
                                                                                                                                                                           ## created. 
                                                                                                                                                                           ## They 
                                                                                                                                                                           ## consist 
                                                                                                                                                                           ## of 
                                                                                                                                                                           ## lowercase 
                                                                                                                                                                           ## letters, 
                                                                                                                                                                           ## numbers, 
                                                                                                                                                                           ## and 
                                                                                                                                                                           ## hyphens.
  var path_402656778 = newJObject()
  add(path_402656778, "recoveryPointArn", newJString(recoveryPointArn))
  add(path_402656778, "backupVaultName", newJString(backupVaultName))
  result = call_402656777.call(path_402656778, nil, nil, nil, nil)

var deleteRecoveryPoint* = Call_DeleteRecoveryPoint_402656764(
    name: "deleteRecoveryPoint", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}/recovery-points/{recoveryPointArn}",
    validator: validate_DeleteRecoveryPoint_402656765, base: "/",
    makeUrl: url_DeleteRecoveryPoint_402656766,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopBackupJob_402656793 = ref object of OpenApiRestCall_402656044
proc url_StopBackupJob_402656795(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupJobId" in path, "`backupJobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-jobs/"),
                 (kind: VariableSegment, value: "backupJobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StopBackupJob_402656794(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Attempts to cancel a job to create a one-time backup of a resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupJobId: JString (required)
                                 ##              : Uniquely identifies a request to AWS Backup to back up a resource.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `backupJobId` field"
  var valid_402656796 = path.getOrDefault("backupJobId")
  valid_402656796 = validateParameter(valid_402656796, JString, required = true,
                                      default = nil)
  if valid_402656796 != nil:
    section.add "backupJobId", valid_402656796
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
  var valid_402656797 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656797 = validateParameter(valid_402656797, JString,
                                      required = false, default = nil)
  if valid_402656797 != nil:
    section.add "X-Amz-Security-Token", valid_402656797
  var valid_402656798 = header.getOrDefault("X-Amz-Signature")
  valid_402656798 = validateParameter(valid_402656798, JString,
                                      required = false, default = nil)
  if valid_402656798 != nil:
    section.add "X-Amz-Signature", valid_402656798
  var valid_402656799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656799 = validateParameter(valid_402656799, JString,
                                      required = false, default = nil)
  if valid_402656799 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656799
  var valid_402656800 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656800 = validateParameter(valid_402656800, JString,
                                      required = false, default = nil)
  if valid_402656800 != nil:
    section.add "X-Amz-Algorithm", valid_402656800
  var valid_402656801 = header.getOrDefault("X-Amz-Date")
  valid_402656801 = validateParameter(valid_402656801, JString,
                                      required = false, default = nil)
  if valid_402656801 != nil:
    section.add "X-Amz-Date", valid_402656801
  var valid_402656802 = header.getOrDefault("X-Amz-Credential")
  valid_402656802 = validateParameter(valid_402656802, JString,
                                      required = false, default = nil)
  if valid_402656802 != nil:
    section.add "X-Amz-Credential", valid_402656802
  var valid_402656803 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656803 = validateParameter(valid_402656803, JString,
                                      required = false, default = nil)
  if valid_402656803 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656803
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656804: Call_StopBackupJob_402656793; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Attempts to cancel a job to create a one-time backup of a resource.
                                                                                         ## 
  let valid = call_402656804.validator(path, query, header, formData, body, _)
  let scheme = call_402656804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656804.makeUrl(scheme.get, call_402656804.host, call_402656804.base,
                                   call_402656804.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656804, uri, valid, _)

proc call*(call_402656805: Call_StopBackupJob_402656793; backupJobId: string): Recallable =
  ## stopBackupJob
  ## Attempts to cancel a job to create a one-time backup of a resource.
  ##   
                                                                        ## backupJobId: string (required)
                                                                        ##              
                                                                        ## : 
                                                                        ## Uniquely 
                                                                        ## identifies 
                                                                        ## a 
                                                                        ## request to AWS 
                                                                        ## Backup 
                                                                        ## to 
                                                                        ## back up a 
                                                                        ## resource.
  var path_402656806 = newJObject()
  add(path_402656806, "backupJobId", newJString(backupJobId))
  result = call_402656805.call(path_402656806, nil, nil, nil, nil)

var stopBackupJob* = Call_StopBackupJob_402656793(name: "stopBackupJob",
    meth: HttpMethod.HttpPost, host: "backup.amazonaws.com",
    route: "/backup-jobs/{backupJobId}", validator: validate_StopBackupJob_402656794,
    base: "/", makeUrl: url_StopBackupJob_402656795,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBackupJob_402656779 = ref object of OpenApiRestCall_402656044
proc url_DescribeBackupJob_402656781(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupJobId" in path, "`backupJobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-jobs/"),
                 (kind: VariableSegment, value: "backupJobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeBackupJob_402656780(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns metadata associated with creating a backup of a resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupJobId: JString (required)
                                 ##              : Uniquely identifies a request to AWS Backup to back up a resource.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `backupJobId` field"
  var valid_402656782 = path.getOrDefault("backupJobId")
  valid_402656782 = validateParameter(valid_402656782, JString, required = true,
                                      default = nil)
  if valid_402656782 != nil:
    section.add "backupJobId", valid_402656782
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
  var valid_402656783 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656783 = validateParameter(valid_402656783, JString,
                                      required = false, default = nil)
  if valid_402656783 != nil:
    section.add "X-Amz-Security-Token", valid_402656783
  var valid_402656784 = header.getOrDefault("X-Amz-Signature")
  valid_402656784 = validateParameter(valid_402656784, JString,
                                      required = false, default = nil)
  if valid_402656784 != nil:
    section.add "X-Amz-Signature", valid_402656784
  var valid_402656785 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656785 = validateParameter(valid_402656785, JString,
                                      required = false, default = nil)
  if valid_402656785 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656785
  var valid_402656786 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656786 = validateParameter(valid_402656786, JString,
                                      required = false, default = nil)
  if valid_402656786 != nil:
    section.add "X-Amz-Algorithm", valid_402656786
  var valid_402656787 = header.getOrDefault("X-Amz-Date")
  valid_402656787 = validateParameter(valid_402656787, JString,
                                      required = false, default = nil)
  if valid_402656787 != nil:
    section.add "X-Amz-Date", valid_402656787
  var valid_402656788 = header.getOrDefault("X-Amz-Credential")
  valid_402656788 = validateParameter(valid_402656788, JString,
                                      required = false, default = nil)
  if valid_402656788 != nil:
    section.add "X-Amz-Credential", valid_402656788
  var valid_402656789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656789 = validateParameter(valid_402656789, JString,
                                      required = false, default = nil)
  if valid_402656789 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656789
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656790: Call_DescribeBackupJob_402656779;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns metadata associated with creating a backup of a resource.
                                                                                         ## 
  let valid = call_402656790.validator(path, query, header, formData, body, _)
  let scheme = call_402656790.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656790.makeUrl(scheme.get, call_402656790.host, call_402656790.base,
                                   call_402656790.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656790, uri, valid, _)

proc call*(call_402656791: Call_DescribeBackupJob_402656779; backupJobId: string): Recallable =
  ## describeBackupJob
  ## Returns metadata associated with creating a backup of a resource.
  ##   
                                                                      ## backupJobId: string (required)
                                                                      ##              
                                                                      ## : 
                                                                      ## Uniquely 
                                                                      ## identifies 
                                                                      ## a 
                                                                      ## request to AWS 
                                                                      ## Backup 
                                                                      ## to 
                                                                      ## back up a 
                                                                      ## resource.
  var path_402656792 = newJObject()
  add(path_402656792, "backupJobId", newJString(backupJobId))
  result = call_402656791.call(path_402656792, nil, nil, nil, nil)

var describeBackupJob* = Call_DescribeBackupJob_402656779(
    name: "describeBackupJob", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup-jobs/{backupJobId}",
    validator: validate_DescribeBackupJob_402656780, base: "/",
    makeUrl: url_DescribeBackupJob_402656781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCopyJob_402656807 = ref object of OpenApiRestCall_402656044
proc url_DescribeCopyJob_402656809(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "copyJobId" in path, "`copyJobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/copy-jobs/"),
                 (kind: VariableSegment, value: "copyJobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeCopyJob_402656808(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns metadata associated with creating a copy of a resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   copyJobId: JString (required)
                                 ##            : Uniquely identifies a request to AWS Backup to copy a resource.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `copyJobId` field"
  var valid_402656810 = path.getOrDefault("copyJobId")
  valid_402656810 = validateParameter(valid_402656810, JString, required = true,
                                      default = nil)
  if valid_402656810 != nil:
    section.add "copyJobId", valid_402656810
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
  var valid_402656811 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656811 = validateParameter(valid_402656811, JString,
                                      required = false, default = nil)
  if valid_402656811 != nil:
    section.add "X-Amz-Security-Token", valid_402656811
  var valid_402656812 = header.getOrDefault("X-Amz-Signature")
  valid_402656812 = validateParameter(valid_402656812, JString,
                                      required = false, default = nil)
  if valid_402656812 != nil:
    section.add "X-Amz-Signature", valid_402656812
  var valid_402656813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656813 = validateParameter(valid_402656813, JString,
                                      required = false, default = nil)
  if valid_402656813 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656813
  var valid_402656814 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656814 = validateParameter(valid_402656814, JString,
                                      required = false, default = nil)
  if valid_402656814 != nil:
    section.add "X-Amz-Algorithm", valid_402656814
  var valid_402656815 = header.getOrDefault("X-Amz-Date")
  valid_402656815 = validateParameter(valid_402656815, JString,
                                      required = false, default = nil)
  if valid_402656815 != nil:
    section.add "X-Amz-Date", valid_402656815
  var valid_402656816 = header.getOrDefault("X-Amz-Credential")
  valid_402656816 = validateParameter(valid_402656816, JString,
                                      required = false, default = nil)
  if valid_402656816 != nil:
    section.add "X-Amz-Credential", valid_402656816
  var valid_402656817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656817 = validateParameter(valid_402656817, JString,
                                      required = false, default = nil)
  if valid_402656817 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656818: Call_DescribeCopyJob_402656807; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns metadata associated with creating a copy of a resource.
                                                                                         ## 
  let valid = call_402656818.validator(path, query, header, formData, body, _)
  let scheme = call_402656818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656818.makeUrl(scheme.get, call_402656818.host, call_402656818.base,
                                   call_402656818.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656818, uri, valid, _)

proc call*(call_402656819: Call_DescribeCopyJob_402656807; copyJobId: string): Recallable =
  ## describeCopyJob
  ## Returns metadata associated with creating a copy of a resource.
  ##   copyJobId: string (required)
                                                                    ##            : Uniquely identifies a request to AWS Backup to copy a resource.
  var path_402656820 = newJObject()
  add(path_402656820, "copyJobId", newJString(copyJobId))
  result = call_402656819.call(path_402656820, nil, nil, nil, nil)

var describeCopyJob* = Call_DescribeCopyJob_402656807(name: "describeCopyJob",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com",
    route: "/copy-jobs/{copyJobId}", validator: validate_DescribeCopyJob_402656808,
    base: "/", makeUrl: url_DescribeCopyJob_402656809,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProtectedResource_402656821 = ref object of OpenApiRestCall_402656044
proc url_DescribeProtectedResource_402656823(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/resources/"),
                 (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeProtectedResource_402656822(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns information about a saved resource, including the last time it was backed-up, its Amazon Resource Name (ARN), and the AWS service type of the saved resource.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              : An Amazon Resource Name (ARN) that uniquely identifies a resource. The format of the ARN depends on the resource type.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402656824 = path.getOrDefault("resourceArn")
  valid_402656824 = validateParameter(valid_402656824, JString, required = true,
                                      default = nil)
  if valid_402656824 != nil:
    section.add "resourceArn", valid_402656824
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
  var valid_402656825 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656825 = validateParameter(valid_402656825, JString,
                                      required = false, default = nil)
  if valid_402656825 != nil:
    section.add "X-Amz-Security-Token", valid_402656825
  var valid_402656826 = header.getOrDefault("X-Amz-Signature")
  valid_402656826 = validateParameter(valid_402656826, JString,
                                      required = false, default = nil)
  if valid_402656826 != nil:
    section.add "X-Amz-Signature", valid_402656826
  var valid_402656827 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656827 = validateParameter(valid_402656827, JString,
                                      required = false, default = nil)
  if valid_402656827 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656827
  var valid_402656828 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656828 = validateParameter(valid_402656828, JString,
                                      required = false, default = nil)
  if valid_402656828 != nil:
    section.add "X-Amz-Algorithm", valid_402656828
  var valid_402656829 = header.getOrDefault("X-Amz-Date")
  valid_402656829 = validateParameter(valid_402656829, JString,
                                      required = false, default = nil)
  if valid_402656829 != nil:
    section.add "X-Amz-Date", valid_402656829
  var valid_402656830 = header.getOrDefault("X-Amz-Credential")
  valid_402656830 = validateParameter(valid_402656830, JString,
                                      required = false, default = nil)
  if valid_402656830 != nil:
    section.add "X-Amz-Credential", valid_402656830
  var valid_402656831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656831 = validateParameter(valid_402656831, JString,
                                      required = false, default = nil)
  if valid_402656831 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656831
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656832: Call_DescribeProtectedResource_402656821;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a saved resource, including the last time it was backed-up, its Amazon Resource Name (ARN), and the AWS service type of the saved resource.
                                                                                         ## 
  let valid = call_402656832.validator(path, query, header, formData, body, _)
  let scheme = call_402656832.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656832.makeUrl(scheme.get, call_402656832.host, call_402656832.base,
                                   call_402656832.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656832, uri, valid, _)

proc call*(call_402656833: Call_DescribeProtectedResource_402656821;
           resourceArn: string): Recallable =
  ## describeProtectedResource
  ## Returns information about a saved resource, including the last time it was backed-up, its Amazon Resource Name (ARN), and the AWS service type of the saved resource.
  ##   
                                                                                                                                                                          ## resourceArn: string (required)
                                                                                                                                                                          ##              
                                                                                                                                                                          ## : 
                                                                                                                                                                          ## An 
                                                                                                                                                                          ## Amazon 
                                                                                                                                                                          ## Resource 
                                                                                                                                                                          ## Name 
                                                                                                                                                                          ## (ARN) 
                                                                                                                                                                          ## that 
                                                                                                                                                                          ## uniquely 
                                                                                                                                                                          ## identifies 
                                                                                                                                                                          ## a 
                                                                                                                                                                          ## resource. 
                                                                                                                                                                          ## The 
                                                                                                                                                                          ## format 
                                                                                                                                                                          ## of 
                                                                                                                                                                          ## the 
                                                                                                                                                                          ## ARN 
                                                                                                                                                                          ## depends 
                                                                                                                                                                          ## on 
                                                                                                                                                                          ## the 
                                                                                                                                                                          ## resource 
                                                                                                                                                                          ## type.
  var path_402656834 = newJObject()
  add(path_402656834, "resourceArn", newJString(resourceArn))
  result = call_402656833.call(path_402656834, nil, nil, nil, nil)

var describeProtectedResource* = Call_DescribeProtectedResource_402656821(
    name: "describeProtectedResource", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/resources/{resourceArn}",
    validator: validate_DescribeProtectedResource_402656822, base: "/",
    makeUrl: url_DescribeProtectedResource_402656823,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRestoreJob_402656835 = ref object of OpenApiRestCall_402656044
proc url_DescribeRestoreJob_402656837(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restoreJobId" in path, "`restoreJobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restore-jobs/"),
                 (kind: VariableSegment, value: "restoreJobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeRestoreJob_402656836(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns metadata associated with a restore job that is specified by a job ID.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restoreJobId: JString (required)
                                 ##               : Uniquely identifies the job that restores a recovery point.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `restoreJobId` field"
  var valid_402656838 = path.getOrDefault("restoreJobId")
  valid_402656838 = validateParameter(valid_402656838, JString, required = true,
                                      default = nil)
  if valid_402656838 != nil:
    section.add "restoreJobId", valid_402656838
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
  var valid_402656839 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656839 = validateParameter(valid_402656839, JString,
                                      required = false, default = nil)
  if valid_402656839 != nil:
    section.add "X-Amz-Security-Token", valid_402656839
  var valid_402656840 = header.getOrDefault("X-Amz-Signature")
  valid_402656840 = validateParameter(valid_402656840, JString,
                                      required = false, default = nil)
  if valid_402656840 != nil:
    section.add "X-Amz-Signature", valid_402656840
  var valid_402656841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656841 = validateParameter(valid_402656841, JString,
                                      required = false, default = nil)
  if valid_402656841 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656841
  var valid_402656842 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656842 = validateParameter(valid_402656842, JString,
                                      required = false, default = nil)
  if valid_402656842 != nil:
    section.add "X-Amz-Algorithm", valid_402656842
  var valid_402656843 = header.getOrDefault("X-Amz-Date")
  valid_402656843 = validateParameter(valid_402656843, JString,
                                      required = false, default = nil)
  if valid_402656843 != nil:
    section.add "X-Amz-Date", valid_402656843
  var valid_402656844 = header.getOrDefault("X-Amz-Credential")
  valid_402656844 = validateParameter(valid_402656844, JString,
                                      required = false, default = nil)
  if valid_402656844 != nil:
    section.add "X-Amz-Credential", valid_402656844
  var valid_402656845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656845 = validateParameter(valid_402656845, JString,
                                      required = false, default = nil)
  if valid_402656845 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656846: Call_DescribeRestoreJob_402656835;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns metadata associated with a restore job that is specified by a job ID.
                                                                                         ## 
  let valid = call_402656846.validator(path, query, header, formData, body, _)
  let scheme = call_402656846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656846.makeUrl(scheme.get, call_402656846.host, call_402656846.base,
                                   call_402656846.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656846, uri, valid, _)

proc call*(call_402656847: Call_DescribeRestoreJob_402656835;
           restoreJobId: string): Recallable =
  ## describeRestoreJob
  ## Returns metadata associated with a restore job that is specified by a job ID.
  ##   
                                                                                  ## restoreJobId: string (required)
                                                                                  ##               
                                                                                  ## : 
                                                                                  ## Uniquely 
                                                                                  ## identifies 
                                                                                  ## the 
                                                                                  ## job 
                                                                                  ## that 
                                                                                  ## restores 
                                                                                  ## a 
                                                                                  ## recovery 
                                                                                  ## point.
  var path_402656848 = newJObject()
  add(path_402656848, "restoreJobId", newJString(restoreJobId))
  result = call_402656847.call(path_402656848, nil, nil, nil, nil)

var describeRestoreJob* = Call_DescribeRestoreJob_402656835(
    name: "describeRestoreJob", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/restore-jobs/{restoreJobId}",
    validator: validate_DescribeRestoreJob_402656836, base: "/",
    makeUrl: url_DescribeRestoreJob_402656837,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportBackupPlanTemplate_402656849 = ref object of OpenApiRestCall_402656044
proc url_ExportBackupPlanTemplate_402656851(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupPlanId" in path, "`backupPlanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/plans/"),
                 (kind: VariableSegment, value: "backupPlanId"),
                 (kind: ConstantSegment, value: "/toTemplate/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ExportBackupPlanTemplate_402656850(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns the backup plan that is specified by the plan ID as a backup template.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupPlanId: JString (required)
                                 ##               : Uniquely identifies a backup plan.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `backupPlanId` field"
  var valid_402656852 = path.getOrDefault("backupPlanId")
  valid_402656852 = validateParameter(valid_402656852, JString, required = true,
                                      default = nil)
  if valid_402656852 != nil:
    section.add "backupPlanId", valid_402656852
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
  var valid_402656853 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656853 = validateParameter(valid_402656853, JString,
                                      required = false, default = nil)
  if valid_402656853 != nil:
    section.add "X-Amz-Security-Token", valid_402656853
  var valid_402656854 = header.getOrDefault("X-Amz-Signature")
  valid_402656854 = validateParameter(valid_402656854, JString,
                                      required = false, default = nil)
  if valid_402656854 != nil:
    section.add "X-Amz-Signature", valid_402656854
  var valid_402656855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656855 = validateParameter(valid_402656855, JString,
                                      required = false, default = nil)
  if valid_402656855 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656855
  var valid_402656856 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656856 = validateParameter(valid_402656856, JString,
                                      required = false, default = nil)
  if valid_402656856 != nil:
    section.add "X-Amz-Algorithm", valid_402656856
  var valid_402656857 = header.getOrDefault("X-Amz-Date")
  valid_402656857 = validateParameter(valid_402656857, JString,
                                      required = false, default = nil)
  if valid_402656857 != nil:
    section.add "X-Amz-Date", valid_402656857
  var valid_402656858 = header.getOrDefault("X-Amz-Credential")
  valid_402656858 = validateParameter(valid_402656858, JString,
                                      required = false, default = nil)
  if valid_402656858 != nil:
    section.add "X-Amz-Credential", valid_402656858
  var valid_402656859 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656859 = validateParameter(valid_402656859, JString,
                                      required = false, default = nil)
  if valid_402656859 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656859
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656860: Call_ExportBackupPlanTemplate_402656849;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the backup plan that is specified by the plan ID as a backup template.
                                                                                         ## 
  let valid = call_402656860.validator(path, query, header, formData, body, _)
  let scheme = call_402656860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656860.makeUrl(scheme.get, call_402656860.host, call_402656860.base,
                                   call_402656860.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656860, uri, valid, _)

proc call*(call_402656861: Call_ExportBackupPlanTemplate_402656849;
           backupPlanId: string): Recallable =
  ## exportBackupPlanTemplate
  ## Returns the backup plan that is specified by the plan ID as a backup template.
  ##   
                                                                                   ## backupPlanId: string (required)
                                                                                   ##               
                                                                                   ## : 
                                                                                   ## Uniquely 
                                                                                   ## identifies 
                                                                                   ## a 
                                                                                   ## backup 
                                                                                   ## plan.
  var path_402656862 = newJObject()
  add(path_402656862, "backupPlanId", newJString(backupPlanId))
  result = call_402656861.call(path_402656862, nil, nil, nil, nil)

var exportBackupPlanTemplate* = Call_ExportBackupPlanTemplate_402656849(
    name: "exportBackupPlanTemplate", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/toTemplate/",
    validator: validate_ExportBackupPlanTemplate_402656850, base: "/",
    makeUrl: url_ExportBackupPlanTemplate_402656851,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupPlan_402656863 = ref object of OpenApiRestCall_402656044
proc url_GetBackupPlan_402656865(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupPlanId" in path, "`backupPlanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/plans/"),
                 (kind: VariableSegment, value: "backupPlanId"),
                 (kind: ConstantSegment, value: "/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBackupPlan_402656864(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the body of a backup plan in JSON format, in addition to plan metadata.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupPlanId: JString (required)
                                 ##               : Uniquely identifies a backup plan.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `backupPlanId` field"
  var valid_402656866 = path.getOrDefault("backupPlanId")
  valid_402656866 = validateParameter(valid_402656866, JString, required = true,
                                      default = nil)
  if valid_402656866 != nil:
    section.add "backupPlanId", valid_402656866
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
                                  ##            : Unique, randomly generated, Unicode, UTF-8 encoded strings that are at most 1,024 bytes long. Version IDs cannot be edited.
  section = newJObject()
  var valid_402656867 = query.getOrDefault("versionId")
  valid_402656867 = validateParameter(valid_402656867, JString,
                                      required = false, default = nil)
  if valid_402656867 != nil:
    section.add "versionId", valid_402656867
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
  var valid_402656868 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656868 = validateParameter(valid_402656868, JString,
                                      required = false, default = nil)
  if valid_402656868 != nil:
    section.add "X-Amz-Security-Token", valid_402656868
  var valid_402656869 = header.getOrDefault("X-Amz-Signature")
  valid_402656869 = validateParameter(valid_402656869, JString,
                                      required = false, default = nil)
  if valid_402656869 != nil:
    section.add "X-Amz-Signature", valid_402656869
  var valid_402656870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656870 = validateParameter(valid_402656870, JString,
                                      required = false, default = nil)
  if valid_402656870 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656870
  var valid_402656871 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656871 = validateParameter(valid_402656871, JString,
                                      required = false, default = nil)
  if valid_402656871 != nil:
    section.add "X-Amz-Algorithm", valid_402656871
  var valid_402656872 = header.getOrDefault("X-Amz-Date")
  valid_402656872 = validateParameter(valid_402656872, JString,
                                      required = false, default = nil)
  if valid_402656872 != nil:
    section.add "X-Amz-Date", valid_402656872
  var valid_402656873 = header.getOrDefault("X-Amz-Credential")
  valid_402656873 = validateParameter(valid_402656873, JString,
                                      required = false, default = nil)
  if valid_402656873 != nil:
    section.add "X-Amz-Credential", valid_402656873
  var valid_402656874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656874 = validateParameter(valid_402656874, JString,
                                      required = false, default = nil)
  if valid_402656874 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656874
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656875: Call_GetBackupPlan_402656863; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the body of a backup plan in JSON format, in addition to plan metadata.
                                                                                         ## 
  let valid = call_402656875.validator(path, query, header, formData, body, _)
  let scheme = call_402656875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656875.makeUrl(scheme.get, call_402656875.host, call_402656875.base,
                                   call_402656875.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656875, uri, valid, _)

proc call*(call_402656876: Call_GetBackupPlan_402656863; backupPlanId: string;
           versionId: string = ""): Recallable =
  ## getBackupPlan
  ## Returns the body of a backup plan in JSON format, in addition to plan metadata.
  ##   
                                                                                    ## versionId: string
                                                                                    ##            
                                                                                    ## : 
                                                                                    ## Unique, 
                                                                                    ## randomly 
                                                                                    ## generated, 
                                                                                    ## Unicode, 
                                                                                    ## UTF-8 
                                                                                    ## encoded 
                                                                                    ## strings 
                                                                                    ## that 
                                                                                    ## are 
                                                                                    ## at 
                                                                                    ## most 
                                                                                    ## 1,024 
                                                                                    ## bytes 
                                                                                    ## long. 
                                                                                    ## Version 
                                                                                    ## IDs 
                                                                                    ## cannot 
                                                                                    ## be 
                                                                                    ## edited.
  ##   
                                                                                              ## backupPlanId: string (required)
                                                                                              ##               
                                                                                              ## : 
                                                                                              ## Uniquely 
                                                                                              ## identifies 
                                                                                              ## a 
                                                                                              ## backup 
                                                                                              ## plan.
  var path_402656877 = newJObject()
  var query_402656878 = newJObject()
  add(query_402656878, "versionId", newJString(versionId))
  add(path_402656877, "backupPlanId", newJString(backupPlanId))
  result = call_402656876.call(path_402656877, query_402656878, nil, nil, nil)

var getBackupPlan* = Call_GetBackupPlan_402656863(name: "getBackupPlan",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/", validator: validate_GetBackupPlan_402656864,
    base: "/", makeUrl: url_GetBackupPlan_402656865,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupPlanFromJSON_402656879 = ref object of OpenApiRestCall_402656044
proc url_GetBackupPlanFromJSON_402656881(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBackupPlanFromJSON_402656880(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a valid JSON document specifying a backup plan or an error.
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
  var valid_402656882 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656882 = validateParameter(valid_402656882, JString,
                                      required = false, default = nil)
  if valid_402656882 != nil:
    section.add "X-Amz-Security-Token", valid_402656882
  var valid_402656883 = header.getOrDefault("X-Amz-Signature")
  valid_402656883 = validateParameter(valid_402656883, JString,
                                      required = false, default = nil)
  if valid_402656883 != nil:
    section.add "X-Amz-Signature", valid_402656883
  var valid_402656884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656884 = validateParameter(valid_402656884, JString,
                                      required = false, default = nil)
  if valid_402656884 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656884
  var valid_402656885 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656885 = validateParameter(valid_402656885, JString,
                                      required = false, default = nil)
  if valid_402656885 != nil:
    section.add "X-Amz-Algorithm", valid_402656885
  var valid_402656886 = header.getOrDefault("X-Amz-Date")
  valid_402656886 = validateParameter(valid_402656886, JString,
                                      required = false, default = nil)
  if valid_402656886 != nil:
    section.add "X-Amz-Date", valid_402656886
  var valid_402656887 = header.getOrDefault("X-Amz-Credential")
  valid_402656887 = validateParameter(valid_402656887, JString,
                                      required = false, default = nil)
  if valid_402656887 != nil:
    section.add "X-Amz-Credential", valid_402656887
  var valid_402656888 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656888 = validateParameter(valid_402656888, JString,
                                      required = false, default = nil)
  if valid_402656888 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656888
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

proc call*(call_402656890: Call_GetBackupPlanFromJSON_402656879;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a valid JSON document specifying a backup plan or an error.
                                                                                         ## 
  let valid = call_402656890.validator(path, query, header, formData, body, _)
  let scheme = call_402656890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656890.makeUrl(scheme.get, call_402656890.host, call_402656890.base,
                                   call_402656890.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656890, uri, valid, _)

proc call*(call_402656891: Call_GetBackupPlanFromJSON_402656879; body: JsonNode): Recallable =
  ## getBackupPlanFromJSON
  ## Returns a valid JSON document specifying a backup plan or an error.
  ##   body: JObject 
                                                                        ## (required)
  var body_402656892 = newJObject()
  if body != nil:
    body_402656892 = body
  result = call_402656891.call(nil, nil, nil, nil, body_402656892)

var getBackupPlanFromJSON* = Call_GetBackupPlanFromJSON_402656879(
    name: "getBackupPlanFromJSON", meth: HttpMethod.HttpPost,
    host: "backup.amazonaws.com", route: "/backup/template/json/toPlan",
    validator: validate_GetBackupPlanFromJSON_402656880, base: "/",
    makeUrl: url_GetBackupPlanFromJSON_402656881,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupPlanFromTemplate_402656893 = ref object of OpenApiRestCall_402656044
proc url_GetBackupPlanFromTemplate_402656895(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "templateId" in path, "`templateId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/template/plans/"),
                 (kind: VariableSegment, value: "templateId"),
                 (kind: ConstantSegment, value: "/toPlan")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBackupPlanFromTemplate_402656894(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns the template specified by its <code>templateId</code> as a backup plan.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   templateId: JString (required)
                                 ##             : Uniquely identifies a stored backup plan template.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `templateId` field"
  var valid_402656896 = path.getOrDefault("templateId")
  valid_402656896 = validateParameter(valid_402656896, JString, required = true,
                                      default = nil)
  if valid_402656896 != nil:
    section.add "templateId", valid_402656896
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
  var valid_402656897 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656897 = validateParameter(valid_402656897, JString,
                                      required = false, default = nil)
  if valid_402656897 != nil:
    section.add "X-Amz-Security-Token", valid_402656897
  var valid_402656898 = header.getOrDefault("X-Amz-Signature")
  valid_402656898 = validateParameter(valid_402656898, JString,
                                      required = false, default = nil)
  if valid_402656898 != nil:
    section.add "X-Amz-Signature", valid_402656898
  var valid_402656899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656899 = validateParameter(valid_402656899, JString,
                                      required = false, default = nil)
  if valid_402656899 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656899
  var valid_402656900 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656900 = validateParameter(valid_402656900, JString,
                                      required = false, default = nil)
  if valid_402656900 != nil:
    section.add "X-Amz-Algorithm", valid_402656900
  var valid_402656901 = header.getOrDefault("X-Amz-Date")
  valid_402656901 = validateParameter(valid_402656901, JString,
                                      required = false, default = nil)
  if valid_402656901 != nil:
    section.add "X-Amz-Date", valid_402656901
  var valid_402656902 = header.getOrDefault("X-Amz-Credential")
  valid_402656902 = validateParameter(valid_402656902, JString,
                                      required = false, default = nil)
  if valid_402656902 != nil:
    section.add "X-Amz-Credential", valid_402656902
  var valid_402656903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656903 = validateParameter(valid_402656903, JString,
                                      required = false, default = nil)
  if valid_402656903 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656904: Call_GetBackupPlanFromTemplate_402656893;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the template specified by its <code>templateId</code> as a backup plan.
                                                                                         ## 
  let valid = call_402656904.validator(path, query, header, formData, body, _)
  let scheme = call_402656904.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656904.makeUrl(scheme.get, call_402656904.host, call_402656904.base,
                                   call_402656904.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656904, uri, valid, _)

proc call*(call_402656905: Call_GetBackupPlanFromTemplate_402656893;
           templateId: string): Recallable =
  ## getBackupPlanFromTemplate
  ## Returns the template specified by its <code>templateId</code> as a backup plan.
  ##   
                                                                                    ## templateId: string (required)
                                                                                    ##             
                                                                                    ## : 
                                                                                    ## Uniquely 
                                                                                    ## identifies 
                                                                                    ## a 
                                                                                    ## stored 
                                                                                    ## backup 
                                                                                    ## plan 
                                                                                    ## template.
  var path_402656906 = newJObject()
  add(path_402656906, "templateId", newJString(templateId))
  result = call_402656905.call(path_402656906, nil, nil, nil, nil)

var getBackupPlanFromTemplate* = Call_GetBackupPlanFromTemplate_402656893(
    name: "getBackupPlanFromTemplate", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup/template/plans/{templateId}/toPlan",
    validator: validate_GetBackupPlanFromTemplate_402656894, base: "/",
    makeUrl: url_GetBackupPlanFromTemplate_402656895,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRecoveryPointRestoreMetadata_402656907 = ref object of OpenApiRestCall_402656044
proc url_GetRecoveryPointRestoreMetadata_402656909(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path,
         "`backupVaultName` is a required path parameter"
  assert "recoveryPointArn" in path,
         "`recoveryPointArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
                 (kind: VariableSegment, value: "backupVaultName"),
                 (kind: ConstantSegment, value: "/recovery-points/"),
                 (kind: VariableSegment, value: "recoveryPointArn"),
                 (kind: ConstantSegment, value: "/restore-metadata")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRecoveryPointRestoreMetadata_402656908(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns a set of metadata key-value pairs that were used to create the backup.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   recoveryPointArn: JString (required)
                                 ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
                                 ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  ##   
                                                                                                                                           ## backupVaultName: JString (required)
                                                                                                                                           ##                  
                                                                                                                                           ## : 
                                                                                                                                           ## The 
                                                                                                                                           ## name 
                                                                                                                                           ## of 
                                                                                                                                           ## a 
                                                                                                                                           ## logical 
                                                                                                                                           ## container 
                                                                                                                                           ## where 
                                                                                                                                           ## backups 
                                                                                                                                           ## are 
                                                                                                                                           ## stored. 
                                                                                                                                           ## Backup 
                                                                                                                                           ## vaults 
                                                                                                                                           ## are 
                                                                                                                                           ## identified 
                                                                                                                                           ## by 
                                                                                                                                           ## names 
                                                                                                                                           ## that 
                                                                                                                                           ## are 
                                                                                                                                           ## unique 
                                                                                                                                           ## to 
                                                                                                                                           ## the 
                                                                                                                                           ## account 
                                                                                                                                           ## used 
                                                                                                                                           ## to 
                                                                                                                                           ## create 
                                                                                                                                           ## them 
                                                                                                                                           ## and 
                                                                                                                                           ## the 
                                                                                                                                           ## AWS 
                                                                                                                                           ## Region 
                                                                                                                                           ## where 
                                                                                                                                           ## they 
                                                                                                                                           ## are 
                                                                                                                                           ## created. 
                                                                                                                                           ## They 
                                                                                                                                           ## consist 
                                                                                                                                           ## of 
                                                                                                                                           ## lowercase 
                                                                                                                                           ## letters, 
                                                                                                                                           ## numbers, 
                                                                                                                                           ## and 
                                                                                                                                           ## hyphens.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `recoveryPointArn` field"
  var valid_402656910 = path.getOrDefault("recoveryPointArn")
  valid_402656910 = validateParameter(valid_402656910, JString, required = true,
                                      default = nil)
  if valid_402656910 != nil:
    section.add "recoveryPointArn", valid_402656910
  var valid_402656911 = path.getOrDefault("backupVaultName")
  valid_402656911 = validateParameter(valid_402656911, JString, required = true,
                                      default = nil)
  if valid_402656911 != nil:
    section.add "backupVaultName", valid_402656911
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
  var valid_402656912 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656912 = validateParameter(valid_402656912, JString,
                                      required = false, default = nil)
  if valid_402656912 != nil:
    section.add "X-Amz-Security-Token", valid_402656912
  var valid_402656913 = header.getOrDefault("X-Amz-Signature")
  valid_402656913 = validateParameter(valid_402656913, JString,
                                      required = false, default = nil)
  if valid_402656913 != nil:
    section.add "X-Amz-Signature", valid_402656913
  var valid_402656914 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656914 = validateParameter(valid_402656914, JString,
                                      required = false, default = nil)
  if valid_402656914 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656914
  var valid_402656915 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656915 = validateParameter(valid_402656915, JString,
                                      required = false, default = nil)
  if valid_402656915 != nil:
    section.add "X-Amz-Algorithm", valid_402656915
  var valid_402656916 = header.getOrDefault("X-Amz-Date")
  valid_402656916 = validateParameter(valid_402656916, JString,
                                      required = false, default = nil)
  if valid_402656916 != nil:
    section.add "X-Amz-Date", valid_402656916
  var valid_402656917 = header.getOrDefault("X-Amz-Credential")
  valid_402656917 = validateParameter(valid_402656917, JString,
                                      required = false, default = nil)
  if valid_402656917 != nil:
    section.add "X-Amz-Credential", valid_402656917
  var valid_402656918 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656918 = validateParameter(valid_402656918, JString,
                                      required = false, default = nil)
  if valid_402656918 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656918
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656919: Call_GetRecoveryPointRestoreMetadata_402656907;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a set of metadata key-value pairs that were used to create the backup.
                                                                                         ## 
  let valid = call_402656919.validator(path, query, header, formData, body, _)
  let scheme = call_402656919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656919.makeUrl(scheme.get, call_402656919.host, call_402656919.base,
                                   call_402656919.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656919, uri, valid, _)

proc call*(call_402656920: Call_GetRecoveryPointRestoreMetadata_402656907;
           recoveryPointArn: string; backupVaultName: string): Recallable =
  ## getRecoveryPointRestoreMetadata
  ## Returns a set of metadata key-value pairs that were used to create the backup.
  ##   
                                                                                   ## recoveryPointArn: string (required)
                                                                                   ##                   
                                                                                   ## : 
                                                                                   ## An 
                                                                                   ## Amazon 
                                                                                   ## Resource 
                                                                                   ## Name 
                                                                                   ## (ARN) 
                                                                                   ## that 
                                                                                   ## uniquely 
                                                                                   ## identifies 
                                                                                   ## a 
                                                                                   ## recovery 
                                                                                   ## point; 
                                                                                   ## for 
                                                                                   ## example, 
                                                                                   ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  ##   
                                                                                                                                                                                             ## backupVaultName: string (required)
                                                                                                                                                                                             ##                  
                                                                                                                                                                                             ## : 
                                                                                                                                                                                             ## The 
                                                                                                                                                                                             ## name 
                                                                                                                                                                                             ## of 
                                                                                                                                                                                             ## a 
                                                                                                                                                                                             ## logical 
                                                                                                                                                                                             ## container 
                                                                                                                                                                                             ## where 
                                                                                                                                                                                             ## backups 
                                                                                                                                                                                             ## are 
                                                                                                                                                                                             ## stored. 
                                                                                                                                                                                             ## Backup 
                                                                                                                                                                                             ## vaults 
                                                                                                                                                                                             ## are 
                                                                                                                                                                                             ## identified 
                                                                                                                                                                                             ## by 
                                                                                                                                                                                             ## names 
                                                                                                                                                                                             ## that 
                                                                                                                                                                                             ## are 
                                                                                                                                                                                             ## unique 
                                                                                                                                                                                             ## to 
                                                                                                                                                                                             ## the 
                                                                                                                                                                                             ## account 
                                                                                                                                                                                             ## used 
                                                                                                                                                                                             ## to 
                                                                                                                                                                                             ## create 
                                                                                                                                                                                             ## them 
                                                                                                                                                                                             ## and 
                                                                                                                                                                                             ## the 
                                                                                                                                                                                             ## AWS 
                                                                                                                                                                                             ## Region 
                                                                                                                                                                                             ## where 
                                                                                                                                                                                             ## they 
                                                                                                                                                                                             ## are 
                                                                                                                                                                                             ## created. 
                                                                                                                                                                                             ## They 
                                                                                                                                                                                             ## consist 
                                                                                                                                                                                             ## of 
                                                                                                                                                                                             ## lowercase 
                                                                                                                                                                                             ## letters, 
                                                                                                                                                                                             ## numbers, 
                                                                                                                                                                                             ## and 
                                                                                                                                                                                             ## hyphens.
  var path_402656921 = newJObject()
  add(path_402656921, "recoveryPointArn", newJString(recoveryPointArn))
  add(path_402656921, "backupVaultName", newJString(backupVaultName))
  result = call_402656920.call(path_402656921, nil, nil, nil, nil)

var getRecoveryPointRestoreMetadata* = Call_GetRecoveryPointRestoreMetadata_402656907(
    name: "getRecoveryPointRestoreMetadata", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}/recovery-points/{recoveryPointArn}/restore-metadata",
    validator: validate_GetRecoveryPointRestoreMetadata_402656908, base: "/",
    makeUrl: url_GetRecoveryPointRestoreMetadata_402656909,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSupportedResourceTypes_402656922 = ref object of OpenApiRestCall_402656044
proc url_GetSupportedResourceTypes_402656924(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSupportedResourceTypes_402656923(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns the AWS resource types supported by AWS Backup.
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
  var valid_402656925 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656925 = validateParameter(valid_402656925, JString,
                                      required = false, default = nil)
  if valid_402656925 != nil:
    section.add "X-Amz-Security-Token", valid_402656925
  var valid_402656926 = header.getOrDefault("X-Amz-Signature")
  valid_402656926 = validateParameter(valid_402656926, JString,
                                      required = false, default = nil)
  if valid_402656926 != nil:
    section.add "X-Amz-Signature", valid_402656926
  var valid_402656927 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656927 = validateParameter(valid_402656927, JString,
                                      required = false, default = nil)
  if valid_402656927 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656927
  var valid_402656928 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656928 = validateParameter(valid_402656928, JString,
                                      required = false, default = nil)
  if valid_402656928 != nil:
    section.add "X-Amz-Algorithm", valid_402656928
  var valid_402656929 = header.getOrDefault("X-Amz-Date")
  valid_402656929 = validateParameter(valid_402656929, JString,
                                      required = false, default = nil)
  if valid_402656929 != nil:
    section.add "X-Amz-Date", valid_402656929
  var valid_402656930 = header.getOrDefault("X-Amz-Credential")
  valid_402656930 = validateParameter(valid_402656930, JString,
                                      required = false, default = nil)
  if valid_402656930 != nil:
    section.add "X-Amz-Credential", valid_402656930
  var valid_402656931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656931 = validateParameter(valid_402656931, JString,
                                      required = false, default = nil)
  if valid_402656931 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656931
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656932: Call_GetSupportedResourceTypes_402656922;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the AWS resource types supported by AWS Backup.
                                                                                         ## 
  let valid = call_402656932.validator(path, query, header, formData, body, _)
  let scheme = call_402656932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656932.makeUrl(scheme.get, call_402656932.host, call_402656932.base,
                                   call_402656932.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656932, uri, valid, _)

proc call*(call_402656933: Call_GetSupportedResourceTypes_402656922): Recallable =
  ## getSupportedResourceTypes
  ## Returns the AWS resource types supported by AWS Backup.
  result = call_402656933.call(nil, nil, nil, nil, nil)

var getSupportedResourceTypes* = Call_GetSupportedResourceTypes_402656922(
    name: "getSupportedResourceTypes", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/supported-resource-types",
    validator: validate_GetSupportedResourceTypes_402656923, base: "/",
    makeUrl: url_GetSupportedResourceTypes_402656924,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupJobs_402656934 = ref object of OpenApiRestCall_402656044
proc url_ListBackupJobs_402656936(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBackupJobs_402656935(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns metadata about your backup jobs.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   state: JString
                                  ##        : Returns only backup jobs that are in the specified state.
  ##   
                                                                                                       ## createdBefore: JString
                                                                                                       ##                
                                                                                                       ## : 
                                                                                                       ## Returns 
                                                                                                       ## only 
                                                                                                       ## backup 
                                                                                                       ## jobs 
                                                                                                       ## that 
                                                                                                       ## were 
                                                                                                       ## created 
                                                                                                       ## before 
                                                                                                       ## the 
                                                                                                       ## specified 
                                                                                                       ## date.
  ##   
                                                                                                               ## maxResults: JInt
                                                                                                               ##             
                                                                                                               ## : 
                                                                                                               ## The 
                                                                                                               ## maximum 
                                                                                                               ## number 
                                                                                                               ## of 
                                                                                                               ## items 
                                                                                                               ## to 
                                                                                                               ## be 
                                                                                                               ## returned.
  ##   
                                                                                                                           ## createdAfter: JString
                                                                                                                           ##               
                                                                                                                           ## : 
                                                                                                                           ## Returns 
                                                                                                                           ## only 
                                                                                                                           ## backup 
                                                                                                                           ## jobs 
                                                                                                                           ## that 
                                                                                                                           ## were 
                                                                                                                           ## created 
                                                                                                                           ## after 
                                                                                                                           ## the 
                                                                                                                           ## specified 
                                                                                                                           ## date.
  ##   
                                                                                                                                   ## nextToken: JString
                                                                                                                                   ##            
                                                                                                                                   ## : 
                                                                                                                                   ## The 
                                                                                                                                   ## next 
                                                                                                                                   ## item 
                                                                                                                                   ## following 
                                                                                                                                   ## a 
                                                                                                                                   ## partial 
                                                                                                                                   ## list 
                                                                                                                                   ## of 
                                                                                                                                   ## returned 
                                                                                                                                   ## items. 
                                                                                                                                   ## For 
                                                                                                                                   ## example, 
                                                                                                                                   ## if 
                                                                                                                                   ## a 
                                                                                                                                   ## request 
                                                                                                                                   ## is 
                                                                                                                                   ## made 
                                                                                                                                   ## to 
                                                                                                                                   ## return 
                                                                                                                                   ## <code>maxResults</code> 
                                                                                                                                   ## number 
                                                                                                                                   ## of 
                                                                                                                                   ## items, 
                                                                                                                                   ## <code>NextToken</code> 
                                                                                                                                   ## allows 
                                                                                                                                   ## you 
                                                                                                                                   ## to 
                                                                                                                                   ## return 
                                                                                                                                   ## more 
                                                                                                                                   ## items 
                                                                                                                                   ## in 
                                                                                                                                   ## your 
                                                                                                                                   ## list 
                                                                                                                                   ## starting 
                                                                                                                                   ## at 
                                                                                                                                   ## the 
                                                                                                                                   ## location 
                                                                                                                                   ## pointed 
                                                                                                                                   ## to 
                                                                                                                                   ## by 
                                                                                                                                   ## the 
                                                                                                                                   ## next 
                                                                                                                                   ## token.
  ##   
                                                                                                                                            ## backupVaultName: JString
                                                                                                                                            ##                  
                                                                                                                                            ## : 
                                                                                                                                            ## Returns 
                                                                                                                                            ## only 
                                                                                                                                            ## backup 
                                                                                                                                            ## jobs 
                                                                                                                                            ## that 
                                                                                                                                            ## will 
                                                                                                                                            ## be 
                                                                                                                                            ## stored 
                                                                                                                                            ## in 
                                                                                                                                            ## the 
                                                                                                                                            ## specified 
                                                                                                                                            ## backup 
                                                                                                                                            ## vault. 
                                                                                                                                            ## Backup 
                                                                                                                                            ## vaults 
                                                                                                                                            ## are 
                                                                                                                                            ## identified 
                                                                                                                                            ## by 
                                                                                                                                            ## names 
                                                                                                                                            ## that 
                                                                                                                                            ## are 
                                                                                                                                            ## unique 
                                                                                                                                            ## to 
                                                                                                                                            ## the 
                                                                                                                                            ## account 
                                                                                                                                            ## used 
                                                                                                                                            ## to 
                                                                                                                                            ## create 
                                                                                                                                            ## them 
                                                                                                                                            ## and 
                                                                                                                                            ## the 
                                                                                                                                            ## AWS 
                                                                                                                                            ## Region 
                                                                                                                                            ## where 
                                                                                                                                            ## they 
                                                                                                                                            ## are 
                                                                                                                                            ## created. 
                                                                                                                                            ## They 
                                                                                                                                            ## consist 
                                                                                                                                            ## of 
                                                                                                                                            ## lowercase 
                                                                                                                                            ## letters, 
                                                                                                                                            ## numbers, 
                                                                                                                                            ## and 
                                                                                                                                            ## hyphens.
  ##   
                                                                                                                                                       ## MaxResults: JString
                                                                                                                                                       ##             
                                                                                                                                                       ## : 
                                                                                                                                                       ## Pagination 
                                                                                                                                                       ## limit
  ##   
                                                                                                                                                               ## resourceArn: JString
                                                                                                                                                               ##              
                                                                                                                                                               ## : 
                                                                                                                                                               ## Returns 
                                                                                                                                                               ## only 
                                                                                                                                                               ## backup 
                                                                                                                                                               ## jobs 
                                                                                                                                                               ## that 
                                                                                                                                                               ## match 
                                                                                                                                                               ## the 
                                                                                                                                                               ## specified 
                                                                                                                                                               ## resource 
                                                                                                                                                               ## Amazon 
                                                                                                                                                               ## Resource 
                                                                                                                                                               ## Name 
                                                                                                                                                               ## (ARN).
  ##   
                                                                                                                                                                        ## resourceType: JString
                                                                                                                                                                        ##               
                                                                                                                                                                        ## : 
                                                                                                                                                                        ## <p>Returns 
                                                                                                                                                                        ## only 
                                                                                                                                                                        ## backup 
                                                                                                                                                                        ## jobs 
                                                                                                                                                                        ## for 
                                                                                                                                                                        ## the 
                                                                                                                                                                        ## specified 
                                                                                                                                                                        ## resources:</p> 
                                                                                                                                                                        ## <ul> 
                                                                                                                                                                        ## <li> 
                                                                                                                                                                        ## <p> 
                                                                                                                                                                        ## <code>DynamoDB</code> 
                                                                                                                                                                        ## for 
                                                                                                                                                                        ## Amazon 
                                                                                                                                                                        ## DynamoDB</p> 
                                                                                                                                                                        ## </li> 
                                                                                                                                                                        ## <li> 
                                                                                                                                                                        ## <p> 
                                                                                                                                                                        ## <code>EBS</code> 
                                                                                                                                                                        ## for 
                                                                                                                                                                        ## Amazon 
                                                                                                                                                                        ## Elastic 
                                                                                                                                                                        ## Block 
                                                                                                                                                                        ## Store</p> 
                                                                                                                                                                        ## </li> 
                                                                                                                                                                        ## <li> 
                                                                                                                                                                        ## <p> 
                                                                                                                                                                        ## <code>EFS</code> 
                                                                                                                                                                        ## for 
                                                                                                                                                                        ## Amazon 
                                                                                                                                                                        ## Elastic 
                                                                                                                                                                        ## File 
                                                                                                                                                                        ## System</p> 
                                                                                                                                                                        ## </li> 
                                                                                                                                                                        ## <li> 
                                                                                                                                                                        ## <p> 
                                                                                                                                                                        ## <code>RDS</code> 
                                                                                                                                                                        ## for 
                                                                                                                                                                        ## Amazon 
                                                                                                                                                                        ## Relational 
                                                                                                                                                                        ## Database 
                                                                                                                                                                        ## Service</p> 
                                                                                                                                                                        ## </li> 
                                                                                                                                                                        ## <li> 
                                                                                                                                                                        ## <p> 
                                                                                                                                                                        ## <code>Storage 
                                                                                                                                                                        ## Gateway</code> 
                                                                                                                                                                        ## for 
                                                                                                                                                                        ## AWS 
                                                                                                                                                                        ## Storage 
                                                                                                                                                                        ## Gateway</p> 
                                                                                                                                                                        ## </li> 
                                                                                                                                                                        ## </ul>
  ##   
                                                                                                                                                                                ## NextToken: JString
                                                                                                                                                                                ##            
                                                                                                                                                                                ## : 
                                                                                                                                                                                ## Pagination 
                                                                                                                                                                                ## token
  section = newJObject()
  var valid_402656949 = query.getOrDefault("state")
  valid_402656949 = validateParameter(valid_402656949, JString,
                                      required = false,
                                      default = newJString("CREATED"))
  if valid_402656949 != nil:
    section.add "state", valid_402656949
  var valid_402656950 = query.getOrDefault("createdBefore")
  valid_402656950 = validateParameter(valid_402656950, JString,
                                      required = false, default = nil)
  if valid_402656950 != nil:
    section.add "createdBefore", valid_402656950
  var valid_402656951 = query.getOrDefault("maxResults")
  valid_402656951 = validateParameter(valid_402656951, JInt, required = false,
                                      default = nil)
  if valid_402656951 != nil:
    section.add "maxResults", valid_402656951
  var valid_402656952 = query.getOrDefault("createdAfter")
  valid_402656952 = validateParameter(valid_402656952, JString,
                                      required = false, default = nil)
  if valid_402656952 != nil:
    section.add "createdAfter", valid_402656952
  var valid_402656953 = query.getOrDefault("nextToken")
  valid_402656953 = validateParameter(valid_402656953, JString,
                                      required = false, default = nil)
  if valid_402656953 != nil:
    section.add "nextToken", valid_402656953
  var valid_402656954 = query.getOrDefault("backupVaultName")
  valid_402656954 = validateParameter(valid_402656954, JString,
                                      required = false, default = nil)
  if valid_402656954 != nil:
    section.add "backupVaultName", valid_402656954
  var valid_402656955 = query.getOrDefault("MaxResults")
  valid_402656955 = validateParameter(valid_402656955, JString,
                                      required = false, default = nil)
  if valid_402656955 != nil:
    section.add "MaxResults", valid_402656955
  var valid_402656956 = query.getOrDefault("resourceArn")
  valid_402656956 = validateParameter(valid_402656956, JString,
                                      required = false, default = nil)
  if valid_402656956 != nil:
    section.add "resourceArn", valid_402656956
  var valid_402656957 = query.getOrDefault("resourceType")
  valid_402656957 = validateParameter(valid_402656957, JString,
                                      required = false, default = nil)
  if valid_402656957 != nil:
    section.add "resourceType", valid_402656957
  var valid_402656958 = query.getOrDefault("NextToken")
  valid_402656958 = validateParameter(valid_402656958, JString,
                                      required = false, default = nil)
  if valid_402656958 != nil:
    section.add "NextToken", valid_402656958
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
  var valid_402656959 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656959 = validateParameter(valid_402656959, JString,
                                      required = false, default = nil)
  if valid_402656959 != nil:
    section.add "X-Amz-Security-Token", valid_402656959
  var valid_402656960 = header.getOrDefault("X-Amz-Signature")
  valid_402656960 = validateParameter(valid_402656960, JString,
                                      required = false, default = nil)
  if valid_402656960 != nil:
    section.add "X-Amz-Signature", valid_402656960
  var valid_402656961 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656961 = validateParameter(valid_402656961, JString,
                                      required = false, default = nil)
  if valid_402656961 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656961
  var valid_402656962 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656962 = validateParameter(valid_402656962, JString,
                                      required = false, default = nil)
  if valid_402656962 != nil:
    section.add "X-Amz-Algorithm", valid_402656962
  var valid_402656963 = header.getOrDefault("X-Amz-Date")
  valid_402656963 = validateParameter(valid_402656963, JString,
                                      required = false, default = nil)
  if valid_402656963 != nil:
    section.add "X-Amz-Date", valid_402656963
  var valid_402656964 = header.getOrDefault("X-Amz-Credential")
  valid_402656964 = validateParameter(valid_402656964, JString,
                                      required = false, default = nil)
  if valid_402656964 != nil:
    section.add "X-Amz-Credential", valid_402656964
  var valid_402656965 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656965 = validateParameter(valid_402656965, JString,
                                      required = false, default = nil)
  if valid_402656965 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656965
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656966: Call_ListBackupJobs_402656934; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns metadata about your backup jobs.
                                                                                         ## 
  let valid = call_402656966.validator(path, query, header, formData, body, _)
  let scheme = call_402656966.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656966.makeUrl(scheme.get, call_402656966.host, call_402656966.base,
                                   call_402656966.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656966, uri, valid, _)

proc call*(call_402656967: Call_ListBackupJobs_402656934;
           state: string = "CREATED"; createdBefore: string = "";
           maxResults: int = 0; createdAfter: string = "";
           nextToken: string = ""; backupVaultName: string = "";
           MaxResults: string = ""; resourceArn: string = "";
           resourceType: string = ""; NextToken: string = ""): Recallable =
  ## listBackupJobs
  ## Returns metadata about your backup jobs.
  ##   state: string
                                             ##        : Returns only backup jobs that are in the specified state.
  ##   
                                                                                                                  ## createdBefore: string
                                                                                                                  ##                
                                                                                                                  ## : 
                                                                                                                  ## Returns 
                                                                                                                  ## only 
                                                                                                                  ## backup 
                                                                                                                  ## jobs 
                                                                                                                  ## that 
                                                                                                                  ## were 
                                                                                                                  ## created 
                                                                                                                  ## before 
                                                                                                                  ## the 
                                                                                                                  ## specified 
                                                                                                                  ## date.
  ##   
                                                                                                                          ## maxResults: int
                                                                                                                          ##             
                                                                                                                          ## : 
                                                                                                                          ## The 
                                                                                                                          ## maximum 
                                                                                                                          ## number 
                                                                                                                          ## of 
                                                                                                                          ## items 
                                                                                                                          ## to 
                                                                                                                          ## be 
                                                                                                                          ## returned.
  ##   
                                                                                                                                      ## createdAfter: string
                                                                                                                                      ##               
                                                                                                                                      ## : 
                                                                                                                                      ## Returns 
                                                                                                                                      ## only 
                                                                                                                                      ## backup 
                                                                                                                                      ## jobs 
                                                                                                                                      ## that 
                                                                                                                                      ## were 
                                                                                                                                      ## created 
                                                                                                                                      ## after 
                                                                                                                                      ## the 
                                                                                                                                      ## specified 
                                                                                                                                      ## date.
  ##   
                                                                                                                                              ## nextToken: string
                                                                                                                                              ##            
                                                                                                                                              ## : 
                                                                                                                                              ## The 
                                                                                                                                              ## next 
                                                                                                                                              ## item 
                                                                                                                                              ## following 
                                                                                                                                              ## a 
                                                                                                                                              ## partial 
                                                                                                                                              ## list 
                                                                                                                                              ## of 
                                                                                                                                              ## returned 
                                                                                                                                              ## items. 
                                                                                                                                              ## For 
                                                                                                                                              ## example, 
                                                                                                                                              ## if 
                                                                                                                                              ## a 
                                                                                                                                              ## request 
                                                                                                                                              ## is 
                                                                                                                                              ## made 
                                                                                                                                              ## to 
                                                                                                                                              ## return 
                                                                                                                                              ## <code>maxResults</code> 
                                                                                                                                              ## number 
                                                                                                                                              ## of 
                                                                                                                                              ## items, 
                                                                                                                                              ## <code>NextToken</code> 
                                                                                                                                              ## allows 
                                                                                                                                              ## you 
                                                                                                                                              ## to 
                                                                                                                                              ## return 
                                                                                                                                              ## more 
                                                                                                                                              ## items 
                                                                                                                                              ## in 
                                                                                                                                              ## your 
                                                                                                                                              ## list 
                                                                                                                                              ## starting 
                                                                                                                                              ## at 
                                                                                                                                              ## the 
                                                                                                                                              ## location 
                                                                                                                                              ## pointed 
                                                                                                                                              ## to 
                                                                                                                                              ## by 
                                                                                                                                              ## the 
                                                                                                                                              ## next 
                                                                                                                                              ## token.
  ##   
                                                                                                                                                       ## backupVaultName: string
                                                                                                                                                       ##                  
                                                                                                                                                       ## : 
                                                                                                                                                       ## Returns 
                                                                                                                                                       ## only 
                                                                                                                                                       ## backup 
                                                                                                                                                       ## jobs 
                                                                                                                                                       ## that 
                                                                                                                                                       ## will 
                                                                                                                                                       ## be 
                                                                                                                                                       ## stored 
                                                                                                                                                       ## in 
                                                                                                                                                       ## the 
                                                                                                                                                       ## specified 
                                                                                                                                                       ## backup 
                                                                                                                                                       ## vault. 
                                                                                                                                                       ## Backup 
                                                                                                                                                       ## vaults 
                                                                                                                                                       ## are 
                                                                                                                                                       ## identified 
                                                                                                                                                       ## by 
                                                                                                                                                       ## names 
                                                                                                                                                       ## that 
                                                                                                                                                       ## are 
                                                                                                                                                       ## unique 
                                                                                                                                                       ## to 
                                                                                                                                                       ## the 
                                                                                                                                                       ## account 
                                                                                                                                                       ## used 
                                                                                                                                                       ## to 
                                                                                                                                                       ## create 
                                                                                                                                                       ## them 
                                                                                                                                                       ## and 
                                                                                                                                                       ## the 
                                                                                                                                                       ## AWS 
                                                                                                                                                       ## Region 
                                                                                                                                                       ## where 
                                                                                                                                                       ## they 
                                                                                                                                                       ## are 
                                                                                                                                                       ## created. 
                                                                                                                                                       ## They 
                                                                                                                                                       ## consist 
                                                                                                                                                       ## of 
                                                                                                                                                       ## lowercase 
                                                                                                                                                       ## letters, 
                                                                                                                                                       ## numbers, 
                                                                                                                                                       ## and 
                                                                                                                                                       ## hyphens.
  ##   
                                                                                                                                                                  ## MaxResults: string
                                                                                                                                                                  ##             
                                                                                                                                                                  ## : 
                                                                                                                                                                  ## Pagination 
                                                                                                                                                                  ## limit
  ##   
                                                                                                                                                                          ## resourceArn: string
                                                                                                                                                                          ##              
                                                                                                                                                                          ## : 
                                                                                                                                                                          ## Returns 
                                                                                                                                                                          ## only 
                                                                                                                                                                          ## backup 
                                                                                                                                                                          ## jobs 
                                                                                                                                                                          ## that 
                                                                                                                                                                          ## match 
                                                                                                                                                                          ## the 
                                                                                                                                                                          ## specified 
                                                                                                                                                                          ## resource 
                                                                                                                                                                          ## Amazon 
                                                                                                                                                                          ## Resource 
                                                                                                                                                                          ## Name 
                                                                                                                                                                          ## (ARN).
  ##   
                                                                                                                                                                                   ## resourceType: string
                                                                                                                                                                                   ##               
                                                                                                                                                                                   ## : 
                                                                                                                                                                                   ## <p>Returns 
                                                                                                                                                                                   ## only 
                                                                                                                                                                                   ## backup 
                                                                                                                                                                                   ## jobs 
                                                                                                                                                                                   ## for 
                                                                                                                                                                                   ## the 
                                                                                                                                                                                   ## specified 
                                                                                                                                                                                   ## resources:</p> 
                                                                                                                                                                                   ## <ul> 
                                                                                                                                                                                   ## <li> 
                                                                                                                                                                                   ## <p> 
                                                                                                                                                                                   ## <code>DynamoDB</code> 
                                                                                                                                                                                   ## for 
                                                                                                                                                                                   ## Amazon 
                                                                                                                                                                                   ## DynamoDB</p> 
                                                                                                                                                                                   ## </li> 
                                                                                                                                                                                   ## <li> 
                                                                                                                                                                                   ## <p> 
                                                                                                                                                                                   ## <code>EBS</code> 
                                                                                                                                                                                   ## for 
                                                                                                                                                                                   ## Amazon 
                                                                                                                                                                                   ## Elastic 
                                                                                                                                                                                   ## Block 
                                                                                                                                                                                   ## Store</p> 
                                                                                                                                                                                   ## </li> 
                                                                                                                                                                                   ## <li> 
                                                                                                                                                                                   ## <p> 
                                                                                                                                                                                   ## <code>EFS</code> 
                                                                                                                                                                                   ## for 
                                                                                                                                                                                   ## Amazon 
                                                                                                                                                                                   ## Elastic 
                                                                                                                                                                                   ## File 
                                                                                                                                                                                   ## System</p> 
                                                                                                                                                                                   ## </li> 
                                                                                                                                                                                   ## <li> 
                                                                                                                                                                                   ## <p> 
                                                                                                                                                                                   ## <code>RDS</code> 
                                                                                                                                                                                   ## for 
                                                                                                                                                                                   ## Amazon 
                                                                                                                                                                                   ## Relational 
                                                                                                                                                                                   ## Database 
                                                                                                                                                                                   ## Service</p> 
                                                                                                                                                                                   ## </li> 
                                                                                                                                                                                   ## <li> 
                                                                                                                                                                                   ## <p> 
                                                                                                                                                                                   ## <code>Storage 
                                                                                                                                                                                   ## Gateway</code> 
                                                                                                                                                                                   ## for 
                                                                                                                                                                                   ## AWS 
                                                                                                                                                                                   ## Storage 
                                                                                                                                                                                   ## Gateway</p> 
                                                                                                                                                                                   ## </li> 
                                                                                                                                                                                   ## </ul>
  ##   
                                                                                                                                                                                           ## NextToken: string
                                                                                                                                                                                           ##            
                                                                                                                                                                                           ## : 
                                                                                                                                                                                           ## Pagination 
                                                                                                                                                                                           ## token
  var query_402656968 = newJObject()
  add(query_402656968, "state", newJString(state))
  add(query_402656968, "createdBefore", newJString(createdBefore))
  add(query_402656968, "maxResults", newJInt(maxResults))
  add(query_402656968, "createdAfter", newJString(createdAfter))
  add(query_402656968, "nextToken", newJString(nextToken))
  add(query_402656968, "backupVaultName", newJString(backupVaultName))
  add(query_402656968, "MaxResults", newJString(MaxResults))
  add(query_402656968, "resourceArn", newJString(resourceArn))
  add(query_402656968, "resourceType", newJString(resourceType))
  add(query_402656968, "NextToken", newJString(NextToken))
  result = call_402656967.call(nil, query_402656968, nil, nil, nil)

var listBackupJobs* = Call_ListBackupJobs_402656934(name: "listBackupJobs",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com",
    route: "/backup-jobs/", validator: validate_ListBackupJobs_402656935,
    base: "/", makeUrl: url_ListBackupJobs_402656936,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupPlanTemplates_402656969 = ref object of OpenApiRestCall_402656044
proc url_ListBackupPlanTemplates_402656971(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBackupPlanTemplates_402656970(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns metadata of your saved backup plan templates, including the template ID, name, and the creation and deletion dates.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of items to be returned.
  ##   
                                                                                              ## nextToken: JString
                                                                                              ##            
                                                                                              ## : 
                                                                                              ## The 
                                                                                              ## next 
                                                                                              ## item 
                                                                                              ## following 
                                                                                              ## a 
                                                                                              ## partial 
                                                                                              ## list 
                                                                                              ## of 
                                                                                              ## returned 
                                                                                              ## items. 
                                                                                              ## For 
                                                                                              ## example, 
                                                                                              ## if 
                                                                                              ## a 
                                                                                              ## request 
                                                                                              ## is 
                                                                                              ## made 
                                                                                              ## to 
                                                                                              ## return 
                                                                                              ## <code>maxResults</code> 
                                                                                              ## number 
                                                                                              ## of 
                                                                                              ## items, 
                                                                                              ## <code>NextToken</code> 
                                                                                              ## allows 
                                                                                              ## you 
                                                                                              ## to 
                                                                                              ## return 
                                                                                              ## more 
                                                                                              ## items 
                                                                                              ## in 
                                                                                              ## your 
                                                                                              ## list 
                                                                                              ## starting 
                                                                                              ## at 
                                                                                              ## the 
                                                                                              ## location 
                                                                                              ## pointed 
                                                                                              ## to 
                                                                                              ## by 
                                                                                              ## the 
                                                                                              ## next 
                                                                                              ## token.
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
  var valid_402656972 = query.getOrDefault("maxResults")
  valid_402656972 = validateParameter(valid_402656972, JInt, required = false,
                                      default = nil)
  if valid_402656972 != nil:
    section.add "maxResults", valid_402656972
  var valid_402656973 = query.getOrDefault("nextToken")
  valid_402656973 = validateParameter(valid_402656973, JString,
                                      required = false, default = nil)
  if valid_402656973 != nil:
    section.add "nextToken", valid_402656973
  var valid_402656974 = query.getOrDefault("MaxResults")
  valid_402656974 = validateParameter(valid_402656974, JString,
                                      required = false, default = nil)
  if valid_402656974 != nil:
    section.add "MaxResults", valid_402656974
  var valid_402656975 = query.getOrDefault("NextToken")
  valid_402656975 = validateParameter(valid_402656975, JString,
                                      required = false, default = nil)
  if valid_402656975 != nil:
    section.add "NextToken", valid_402656975
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
  var valid_402656976 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656976 = validateParameter(valid_402656976, JString,
                                      required = false, default = nil)
  if valid_402656976 != nil:
    section.add "X-Amz-Security-Token", valid_402656976
  var valid_402656977 = header.getOrDefault("X-Amz-Signature")
  valid_402656977 = validateParameter(valid_402656977, JString,
                                      required = false, default = nil)
  if valid_402656977 != nil:
    section.add "X-Amz-Signature", valid_402656977
  var valid_402656978 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656978 = validateParameter(valid_402656978, JString,
                                      required = false, default = nil)
  if valid_402656978 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656978
  var valid_402656979 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656979 = validateParameter(valid_402656979, JString,
                                      required = false, default = nil)
  if valid_402656979 != nil:
    section.add "X-Amz-Algorithm", valid_402656979
  var valid_402656980 = header.getOrDefault("X-Amz-Date")
  valid_402656980 = validateParameter(valid_402656980, JString,
                                      required = false, default = nil)
  if valid_402656980 != nil:
    section.add "X-Amz-Date", valid_402656980
  var valid_402656981 = header.getOrDefault("X-Amz-Credential")
  valid_402656981 = validateParameter(valid_402656981, JString,
                                      required = false, default = nil)
  if valid_402656981 != nil:
    section.add "X-Amz-Credential", valid_402656981
  var valid_402656982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656982 = validateParameter(valid_402656982, JString,
                                      required = false, default = nil)
  if valid_402656982 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656983: Call_ListBackupPlanTemplates_402656969;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns metadata of your saved backup plan templates, including the template ID, name, and the creation and deletion dates.
                                                                                         ## 
  let valid = call_402656983.validator(path, query, header, formData, body, _)
  let scheme = call_402656983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656983.makeUrl(scheme.get, call_402656983.host, call_402656983.base,
                                   call_402656983.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656983, uri, valid, _)

proc call*(call_402656984: Call_ListBackupPlanTemplates_402656969;
           maxResults: int = 0; nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listBackupPlanTemplates
  ## Returns metadata of your saved backup plan templates, including the template ID, name, and the creation and deletion dates.
  ##   
                                                                                                                                ## maxResults: int
                                                                                                                                ##             
                                                                                                                                ## : 
                                                                                                                                ## The 
                                                                                                                                ## maximum 
                                                                                                                                ## number 
                                                                                                                                ## of 
                                                                                                                                ## items 
                                                                                                                                ## to 
                                                                                                                                ## be 
                                                                                                                                ## returned.
  ##   
                                                                                                                                            ## nextToken: string
                                                                                                                                            ##            
                                                                                                                                            ## : 
                                                                                                                                            ## The 
                                                                                                                                            ## next 
                                                                                                                                            ## item 
                                                                                                                                            ## following 
                                                                                                                                            ## a 
                                                                                                                                            ## partial 
                                                                                                                                            ## list 
                                                                                                                                            ## of 
                                                                                                                                            ## returned 
                                                                                                                                            ## items. 
                                                                                                                                            ## For 
                                                                                                                                            ## example, 
                                                                                                                                            ## if 
                                                                                                                                            ## a 
                                                                                                                                            ## request 
                                                                                                                                            ## is 
                                                                                                                                            ## made 
                                                                                                                                            ## to 
                                                                                                                                            ## return 
                                                                                                                                            ## <code>maxResults</code> 
                                                                                                                                            ## number 
                                                                                                                                            ## of 
                                                                                                                                            ## items, 
                                                                                                                                            ## <code>NextToken</code> 
                                                                                                                                            ## allows 
                                                                                                                                            ## you 
                                                                                                                                            ## to 
                                                                                                                                            ## return 
                                                                                                                                            ## more 
                                                                                                                                            ## items 
                                                                                                                                            ## in 
                                                                                                                                            ## your 
                                                                                                                                            ## list 
                                                                                                                                            ## starting 
                                                                                                                                            ## at 
                                                                                                                                            ## the 
                                                                                                                                            ## location 
                                                                                                                                            ## pointed 
                                                                                                                                            ## to 
                                                                                                                                            ## by 
                                                                                                                                            ## the 
                                                                                                                                            ## next 
                                                                                                                                            ## token.
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
  var query_402656985 = newJObject()
  add(query_402656985, "maxResults", newJInt(maxResults))
  add(query_402656985, "nextToken", newJString(nextToken))
  add(query_402656985, "MaxResults", newJString(MaxResults))
  add(query_402656985, "NextToken", newJString(NextToken))
  result = call_402656984.call(nil, query_402656985, nil, nil, nil)

var listBackupPlanTemplates* = Call_ListBackupPlanTemplates_402656969(
    name: "listBackupPlanTemplates", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup/template/plans",
    validator: validate_ListBackupPlanTemplates_402656970, base: "/",
    makeUrl: url_ListBackupPlanTemplates_402656971,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupPlanVersions_402656986 = ref object of OpenApiRestCall_402656044
proc url_ListBackupPlanVersions_402656988(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupPlanId" in path, "`backupPlanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/plans/"),
                 (kind: VariableSegment, value: "backupPlanId"),
                 (kind: ConstantSegment, value: "/versions/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListBackupPlanVersions_402656987(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns version metadata of your backup plans, including Amazon Resource Names (ARNs), backup plan IDs, creation and deletion dates, plan names, and version IDs.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupPlanId: JString (required)
                                 ##               : Uniquely identifies a backup plan.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `backupPlanId` field"
  var valid_402656989 = path.getOrDefault("backupPlanId")
  valid_402656989 = validateParameter(valid_402656989, JString, required = true,
                                      default = nil)
  if valid_402656989 != nil:
    section.add "backupPlanId", valid_402656989
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of items to be returned.
  ##   
                                                                                              ## nextToken: JString
                                                                                              ##            
                                                                                              ## : 
                                                                                              ## The 
                                                                                              ## next 
                                                                                              ## item 
                                                                                              ## following 
                                                                                              ## a 
                                                                                              ## partial 
                                                                                              ## list 
                                                                                              ## of 
                                                                                              ## returned 
                                                                                              ## items. 
                                                                                              ## For 
                                                                                              ## example, 
                                                                                              ## if 
                                                                                              ## a 
                                                                                              ## request 
                                                                                              ## is 
                                                                                              ## made 
                                                                                              ## to 
                                                                                              ## return 
                                                                                              ## <code>maxResults</code> 
                                                                                              ## number 
                                                                                              ## of 
                                                                                              ## items, 
                                                                                              ## <code>NextToken</code> 
                                                                                              ## allows 
                                                                                              ## you 
                                                                                              ## to 
                                                                                              ## return 
                                                                                              ## more 
                                                                                              ## items 
                                                                                              ## in 
                                                                                              ## your 
                                                                                              ## list 
                                                                                              ## starting 
                                                                                              ## at 
                                                                                              ## the 
                                                                                              ## location 
                                                                                              ## pointed 
                                                                                              ## to 
                                                                                              ## by 
                                                                                              ## the 
                                                                                              ## next 
                                                                                              ## token.
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
  var valid_402656990 = query.getOrDefault("maxResults")
  valid_402656990 = validateParameter(valid_402656990, JInt, required = false,
                                      default = nil)
  if valid_402656990 != nil:
    section.add "maxResults", valid_402656990
  var valid_402656991 = query.getOrDefault("nextToken")
  valid_402656991 = validateParameter(valid_402656991, JString,
                                      required = false, default = nil)
  if valid_402656991 != nil:
    section.add "nextToken", valid_402656991
  var valid_402656992 = query.getOrDefault("MaxResults")
  valid_402656992 = validateParameter(valid_402656992, JString,
                                      required = false, default = nil)
  if valid_402656992 != nil:
    section.add "MaxResults", valid_402656992
  var valid_402656993 = query.getOrDefault("NextToken")
  valid_402656993 = validateParameter(valid_402656993, JString,
                                      required = false, default = nil)
  if valid_402656993 != nil:
    section.add "NextToken", valid_402656993
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
  var valid_402656994 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656994 = validateParameter(valid_402656994, JString,
                                      required = false, default = nil)
  if valid_402656994 != nil:
    section.add "X-Amz-Security-Token", valid_402656994
  var valid_402656995 = header.getOrDefault("X-Amz-Signature")
  valid_402656995 = validateParameter(valid_402656995, JString,
                                      required = false, default = nil)
  if valid_402656995 != nil:
    section.add "X-Amz-Signature", valid_402656995
  var valid_402656996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656996 = validateParameter(valid_402656996, JString,
                                      required = false, default = nil)
  if valid_402656996 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656996
  var valid_402656997 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656997 = validateParameter(valid_402656997, JString,
                                      required = false, default = nil)
  if valid_402656997 != nil:
    section.add "X-Amz-Algorithm", valid_402656997
  var valid_402656998 = header.getOrDefault("X-Amz-Date")
  valid_402656998 = validateParameter(valid_402656998, JString,
                                      required = false, default = nil)
  if valid_402656998 != nil:
    section.add "X-Amz-Date", valid_402656998
  var valid_402656999 = header.getOrDefault("X-Amz-Credential")
  valid_402656999 = validateParameter(valid_402656999, JString,
                                      required = false, default = nil)
  if valid_402656999 != nil:
    section.add "X-Amz-Credential", valid_402656999
  var valid_402657000 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657000 = validateParameter(valid_402657000, JString,
                                      required = false, default = nil)
  if valid_402657000 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657000
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657001: Call_ListBackupPlanVersions_402656986;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns version metadata of your backup plans, including Amazon Resource Names (ARNs), backup plan IDs, creation and deletion dates, plan names, and version IDs.
                                                                                         ## 
  let valid = call_402657001.validator(path, query, header, formData, body, _)
  let scheme = call_402657001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657001.makeUrl(scheme.get, call_402657001.host, call_402657001.base,
                                   call_402657001.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657001, uri, valid, _)

proc call*(call_402657002: Call_ListBackupPlanVersions_402656986;
           backupPlanId: string; maxResults: int = 0; nextToken: string = "";
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listBackupPlanVersions
  ## Returns version metadata of your backup plans, including Amazon Resource Names (ARNs), backup plan IDs, creation and deletion dates, plan names, and version IDs.
  ##   
                                                                                                                                                                      ## maxResults: int
                                                                                                                                                                      ##             
                                                                                                                                                                      ## : 
                                                                                                                                                                      ## The 
                                                                                                                                                                      ## maximum 
                                                                                                                                                                      ## number 
                                                                                                                                                                      ## of 
                                                                                                                                                                      ## items 
                                                                                                                                                                      ## to 
                                                                                                                                                                      ## be 
                                                                                                                                                                      ## returned.
  ##   
                                                                                                                                                                                  ## nextToken: string
                                                                                                                                                                                  ##            
                                                                                                                                                                                  ## : 
                                                                                                                                                                                  ## The 
                                                                                                                                                                                  ## next 
                                                                                                                                                                                  ## item 
                                                                                                                                                                                  ## following 
                                                                                                                                                                                  ## a 
                                                                                                                                                                                  ## partial 
                                                                                                                                                                                  ## list 
                                                                                                                                                                                  ## of 
                                                                                                                                                                                  ## returned 
                                                                                                                                                                                  ## items. 
                                                                                                                                                                                  ## For 
                                                                                                                                                                                  ## example, 
                                                                                                                                                                                  ## if 
                                                                                                                                                                                  ## a 
                                                                                                                                                                                  ## request 
                                                                                                                                                                                  ## is 
                                                                                                                                                                                  ## made 
                                                                                                                                                                                  ## to 
                                                                                                                                                                                  ## return 
                                                                                                                                                                                  ## <code>maxResults</code> 
                                                                                                                                                                                  ## number 
                                                                                                                                                                                  ## of 
                                                                                                                                                                                  ## items, 
                                                                                                                                                                                  ## <code>NextToken</code> 
                                                                                                                                                                                  ## allows 
                                                                                                                                                                                  ## you 
                                                                                                                                                                                  ## to 
                                                                                                                                                                                  ## return 
                                                                                                                                                                                  ## more 
                                                                                                                                                                                  ## items 
                                                                                                                                                                                  ## in 
                                                                                                                                                                                  ## your 
                                                                                                                                                                                  ## list 
                                                                                                                                                                                  ## starting 
                                                                                                                                                                                  ## at 
                                                                                                                                                                                  ## the 
                                                                                                                                                                                  ## location 
                                                                                                                                                                                  ## pointed 
                                                                                                                                                                                  ## to 
                                                                                                                                                                                  ## by 
                                                                                                                                                                                  ## the 
                                                                                                                                                                                  ## next 
                                                                                                                                                                                  ## token.
  ##   
                                                                                                                                                                                           ## backupPlanId: string (required)
                                                                                                                                                                                           ##               
                                                                                                                                                                                           ## : 
                                                                                                                                                                                           ## Uniquely 
                                                                                                                                                                                           ## identifies 
                                                                                                                                                                                           ## a 
                                                                                                                                                                                           ## backup 
                                                                                                                                                                                           ## plan.
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
  var path_402657003 = newJObject()
  var query_402657004 = newJObject()
  add(query_402657004, "maxResults", newJInt(maxResults))
  add(query_402657004, "nextToken", newJString(nextToken))
  add(path_402657003, "backupPlanId", newJString(backupPlanId))
  add(query_402657004, "MaxResults", newJString(MaxResults))
  add(query_402657004, "NextToken", newJString(NextToken))
  result = call_402657002.call(path_402657003, query_402657004, nil, nil, nil)

var listBackupPlanVersions* = Call_ListBackupPlanVersions_402656986(
    name: "listBackupPlanVersions", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/versions/",
    validator: validate_ListBackupPlanVersions_402656987, base: "/",
    makeUrl: url_ListBackupPlanVersions_402656988,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupVaults_402657005 = ref object of OpenApiRestCall_402656044
proc url_ListBackupVaults_402657007(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBackupVaults_402657006(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of recovery point storage containers along with information about them.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of items to be returned.
  ##   
                                                                                              ## nextToken: JString
                                                                                              ##            
                                                                                              ## : 
                                                                                              ## The 
                                                                                              ## next 
                                                                                              ## item 
                                                                                              ## following 
                                                                                              ## a 
                                                                                              ## partial 
                                                                                              ## list 
                                                                                              ## of 
                                                                                              ## returned 
                                                                                              ## items. 
                                                                                              ## For 
                                                                                              ## example, 
                                                                                              ## if 
                                                                                              ## a 
                                                                                              ## request 
                                                                                              ## is 
                                                                                              ## made 
                                                                                              ## to 
                                                                                              ## return 
                                                                                              ## <code>maxResults</code> 
                                                                                              ## number 
                                                                                              ## of 
                                                                                              ## items, 
                                                                                              ## <code>NextToken</code> 
                                                                                              ## allows 
                                                                                              ## you 
                                                                                              ## to 
                                                                                              ## return 
                                                                                              ## more 
                                                                                              ## items 
                                                                                              ## in 
                                                                                              ## your 
                                                                                              ## list 
                                                                                              ## starting 
                                                                                              ## at 
                                                                                              ## the 
                                                                                              ## location 
                                                                                              ## pointed 
                                                                                              ## to 
                                                                                              ## by 
                                                                                              ## the 
                                                                                              ## next 
                                                                                              ## token.
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
  var valid_402657008 = query.getOrDefault("maxResults")
  valid_402657008 = validateParameter(valid_402657008, JInt, required = false,
                                      default = nil)
  if valid_402657008 != nil:
    section.add "maxResults", valid_402657008
  var valid_402657009 = query.getOrDefault("nextToken")
  valid_402657009 = validateParameter(valid_402657009, JString,
                                      required = false, default = nil)
  if valid_402657009 != nil:
    section.add "nextToken", valid_402657009
  var valid_402657010 = query.getOrDefault("MaxResults")
  valid_402657010 = validateParameter(valid_402657010, JString,
                                      required = false, default = nil)
  if valid_402657010 != nil:
    section.add "MaxResults", valid_402657010
  var valid_402657011 = query.getOrDefault("NextToken")
  valid_402657011 = validateParameter(valid_402657011, JString,
                                      required = false, default = nil)
  if valid_402657011 != nil:
    section.add "NextToken", valid_402657011
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
  var valid_402657012 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657012 = validateParameter(valid_402657012, JString,
                                      required = false, default = nil)
  if valid_402657012 != nil:
    section.add "X-Amz-Security-Token", valid_402657012
  var valid_402657013 = header.getOrDefault("X-Amz-Signature")
  valid_402657013 = validateParameter(valid_402657013, JString,
                                      required = false, default = nil)
  if valid_402657013 != nil:
    section.add "X-Amz-Signature", valid_402657013
  var valid_402657014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657014 = validateParameter(valid_402657014, JString,
                                      required = false, default = nil)
  if valid_402657014 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657014
  var valid_402657015 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657015 = validateParameter(valid_402657015, JString,
                                      required = false, default = nil)
  if valid_402657015 != nil:
    section.add "X-Amz-Algorithm", valid_402657015
  var valid_402657016 = header.getOrDefault("X-Amz-Date")
  valid_402657016 = validateParameter(valid_402657016, JString,
                                      required = false, default = nil)
  if valid_402657016 != nil:
    section.add "X-Amz-Date", valid_402657016
  var valid_402657017 = header.getOrDefault("X-Amz-Credential")
  valid_402657017 = validateParameter(valid_402657017, JString,
                                      required = false, default = nil)
  if valid_402657017 != nil:
    section.add "X-Amz-Credential", valid_402657017
  var valid_402657018 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657018 = validateParameter(valid_402657018, JString,
                                      required = false, default = nil)
  if valid_402657018 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657018
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657019: Call_ListBackupVaults_402657005;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of recovery point storage containers along with information about them.
                                                                                         ## 
  let valid = call_402657019.validator(path, query, header, formData, body, _)
  let scheme = call_402657019.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657019.makeUrl(scheme.get, call_402657019.host, call_402657019.base,
                                   call_402657019.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657019, uri, valid, _)

proc call*(call_402657020: Call_ListBackupVaults_402657005; maxResults: int = 0;
           nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listBackupVaults
  ## Returns a list of recovery point storage containers along with information about them.
  ##   
                                                                                           ## maxResults: int
                                                                                           ##             
                                                                                           ## : 
                                                                                           ## The 
                                                                                           ## maximum 
                                                                                           ## number 
                                                                                           ## of 
                                                                                           ## items 
                                                                                           ## to 
                                                                                           ## be 
                                                                                           ## returned.
  ##   
                                                                                                       ## nextToken: string
                                                                                                       ##            
                                                                                                       ## : 
                                                                                                       ## The 
                                                                                                       ## next 
                                                                                                       ## item 
                                                                                                       ## following 
                                                                                                       ## a 
                                                                                                       ## partial 
                                                                                                       ## list 
                                                                                                       ## of 
                                                                                                       ## returned 
                                                                                                       ## items. 
                                                                                                       ## For 
                                                                                                       ## example, 
                                                                                                       ## if 
                                                                                                       ## a 
                                                                                                       ## request 
                                                                                                       ## is 
                                                                                                       ## made 
                                                                                                       ## to 
                                                                                                       ## return 
                                                                                                       ## <code>maxResults</code> 
                                                                                                       ## number 
                                                                                                       ## of 
                                                                                                       ## items, 
                                                                                                       ## <code>NextToken</code> 
                                                                                                       ## allows 
                                                                                                       ## you 
                                                                                                       ## to 
                                                                                                       ## return 
                                                                                                       ## more 
                                                                                                       ## items 
                                                                                                       ## in 
                                                                                                       ## your 
                                                                                                       ## list 
                                                                                                       ## starting 
                                                                                                       ## at 
                                                                                                       ## the 
                                                                                                       ## location 
                                                                                                       ## pointed 
                                                                                                       ## to 
                                                                                                       ## by 
                                                                                                       ## the 
                                                                                                       ## next 
                                                                                                       ## token.
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
  var query_402657021 = newJObject()
  add(query_402657021, "maxResults", newJInt(maxResults))
  add(query_402657021, "nextToken", newJString(nextToken))
  add(query_402657021, "MaxResults", newJString(MaxResults))
  add(query_402657021, "NextToken", newJString(NextToken))
  result = call_402657020.call(nil, query_402657021, nil, nil, nil)

var listBackupVaults* = Call_ListBackupVaults_402657005(
    name: "listBackupVaults", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup-vaults/",
    validator: validate_ListBackupVaults_402657006, base: "/",
    makeUrl: url_ListBackupVaults_402657007,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCopyJobs_402657022 = ref object of OpenApiRestCall_402656044
proc url_ListCopyJobs_402657024(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCopyJobs_402657023(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns metadata about your copy jobs.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   state: JString
                                  ##        : Returns only copy jobs that are in the specified state.
  ##   
                                                                                                     ## createdBefore: JString
                                                                                                     ##                
                                                                                                     ## : 
                                                                                                     ## Returns 
                                                                                                     ## only 
                                                                                                     ## copy 
                                                                                                     ## jobs 
                                                                                                     ## that 
                                                                                                     ## were 
                                                                                                     ## created 
                                                                                                     ## before 
                                                                                                     ## the 
                                                                                                     ## specified 
                                                                                                     ## date.
  ##   
                                                                                                             ## destinationVaultArn: JString
                                                                                                             ##                      
                                                                                                             ## : 
                                                                                                             ## An 
                                                                                                             ## Amazon 
                                                                                                             ## Resource 
                                                                                                             ## Name 
                                                                                                             ## (ARN) 
                                                                                                             ## that 
                                                                                                             ## uniquely 
                                                                                                             ## identifies 
                                                                                                             ## a 
                                                                                                             ## source 
                                                                                                             ## backup 
                                                                                                             ## vault 
                                                                                                             ## to 
                                                                                                             ## copy 
                                                                                                             ## from; 
                                                                                                             ## for 
                                                                                                             ## example, 
                                                                                                             ## arn:aws:backup:us-east-1:123456789012:vault:aBackupVault. 
  ##   
                                                                                                                                                                          ## maxResults: JInt
                                                                                                                                                                          ##             
                                                                                                                                                                          ## : 
                                                                                                                                                                          ## The 
                                                                                                                                                                          ## maximum 
                                                                                                                                                                          ## number 
                                                                                                                                                                          ## of 
                                                                                                                                                                          ## items 
                                                                                                                                                                          ## to 
                                                                                                                                                                          ## be 
                                                                                                                                                                          ## returned.
  ##   
                                                                                                                                                                                      ## createdAfter: JString
                                                                                                                                                                                      ##               
                                                                                                                                                                                      ## : 
                                                                                                                                                                                      ## Returns 
                                                                                                                                                                                      ## only 
                                                                                                                                                                                      ## copy 
                                                                                                                                                                                      ## jobs 
                                                                                                                                                                                      ## that 
                                                                                                                                                                                      ## were 
                                                                                                                                                                                      ## created 
                                                                                                                                                                                      ## after 
                                                                                                                                                                                      ## the 
                                                                                                                                                                                      ## specified 
                                                                                                                                                                                      ## date.
  ##   
                                                                                                                                                                                              ## nextToken: JString
                                                                                                                                                                                              ##            
                                                                                                                                                                                              ## : 
                                                                                                                                                                                              ## The 
                                                                                                                                                                                              ## next 
                                                                                                                                                                                              ## item 
                                                                                                                                                                                              ## following 
                                                                                                                                                                                              ## a 
                                                                                                                                                                                              ## partial 
                                                                                                                                                                                              ## list 
                                                                                                                                                                                              ## of 
                                                                                                                                                                                              ## returned 
                                                                                                                                                                                              ## items. 
                                                                                                                                                                                              ## For 
                                                                                                                                                                                              ## example, 
                                                                                                                                                                                              ## if 
                                                                                                                                                                                              ## a 
                                                                                                                                                                                              ## request 
                                                                                                                                                                                              ## is 
                                                                                                                                                                                              ## made 
                                                                                                                                                                                              ## to 
                                                                                                                                                                                              ## return 
                                                                                                                                                                                              ## maxResults 
                                                                                                                                                                                              ## number 
                                                                                                                                                                                              ## of 
                                                                                                                                                                                              ## items, 
                                                                                                                                                                                              ## NextToken 
                                                                                                                                                                                              ## allows 
                                                                                                                                                                                              ## you 
                                                                                                                                                                                              ## to 
                                                                                                                                                                                              ## return 
                                                                                                                                                                                              ## more 
                                                                                                                                                                                              ## items 
                                                                                                                                                                                              ## in 
                                                                                                                                                                                              ## your 
                                                                                                                                                                                              ## list 
                                                                                                                                                                                              ## starting 
                                                                                                                                                                                              ## at 
                                                                                                                                                                                              ## the 
                                                                                                                                                                                              ## location 
                                                                                                                                                                                              ## pointed 
                                                                                                                                                                                              ## to 
                                                                                                                                                                                              ## by 
                                                                                                                                                                                              ## the 
                                                                                                                                                                                              ## next 
                                                                                                                                                                                              ## token. 
  ##   
                                                                                                                                                                                                        ## MaxResults: JString
                                                                                                                                                                                                        ##             
                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                        ## Pagination 
                                                                                                                                                                                                        ## limit
  ##   
                                                                                                                                                                                                                ## resourceArn: JString
                                                                                                                                                                                                                ##              
                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                ## Returns 
                                                                                                                                                                                                                ## only 
                                                                                                                                                                                                                ## copy 
                                                                                                                                                                                                                ## jobs 
                                                                                                                                                                                                                ## that 
                                                                                                                                                                                                                ## match 
                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                ## specified 
                                                                                                                                                                                                                ## resource 
                                                                                                                                                                                                                ## Amazon 
                                                                                                                                                                                                                ## Resource 
                                                                                                                                                                                                                ## Name 
                                                                                                                                                                                                                ## (ARN). 
  ##   
                                                                                                                                                                                                                          ## resourceType: JString
                                                                                                                                                                                                                          ##               
                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                          ## <p>Returns 
                                                                                                                                                                                                                          ## only 
                                                                                                                                                                                                                          ## backup 
                                                                                                                                                                                                                          ## jobs 
                                                                                                                                                                                                                          ## for 
                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                          ## specified 
                                                                                                                                                                                                                          ## resources:</p> 
                                                                                                                                                                                                                          ## <ul> 
                                                                                                                                                                                                                          ## <li> 
                                                                                                                                                                                                                          ## <p> 
                                                                                                                                                                                                                          ## <code>DynamoDB</code> 
                                                                                                                                                                                                                          ## for 
                                                                                                                                                                                                                          ## Amazon 
                                                                                                                                                                                                                          ## DynamoDB</p> 
                                                                                                                                                                                                                          ## </li> 
                                                                                                                                                                                                                          ## <li> 
                                                                                                                                                                                                                          ## <p> 
                                                                                                                                                                                                                          ## <code>EBS</code> 
                                                                                                                                                                                                                          ## for 
                                                                                                                                                                                                                          ## Amazon 
                                                                                                                                                                                                                          ## Elastic 
                                                                                                                                                                                                                          ## Block 
                                                                                                                                                                                                                          ## Store</p> 
                                                                                                                                                                                                                          ## </li> 
                                                                                                                                                                                                                          ## <li> 
                                                                                                                                                                                                                          ## <p> 
                                                                                                                                                                                                                          ## <code>EFS</code> 
                                                                                                                                                                                                                          ## for 
                                                                                                                                                                                                                          ## Amazon 
                                                                                                                                                                                                                          ## Elastic 
                                                                                                                                                                                                                          ## File 
                                                                                                                                                                                                                          ## System</p> 
                                                                                                                                                                                                                          ## </li> 
                                                                                                                                                                                                                          ## <li> 
                                                                                                                                                                                                                          ## <p> 
                                                                                                                                                                                                                          ## <code>RDS</code> 
                                                                                                                                                                                                                          ## for 
                                                                                                                                                                                                                          ## Amazon 
                                                                                                                                                                                                                          ## Relational 
                                                                                                                                                                                                                          ## Database 
                                                                                                                                                                                                                          ## Service</p> 
                                                                                                                                                                                                                          ## </li> 
                                                                                                                                                                                                                          ## <li> 
                                                                                                                                                                                                                          ## <p> 
                                                                                                                                                                                                                          ## <code>Storage 
                                                                                                                                                                                                                          ## Gateway</code> 
                                                                                                                                                                                                                          ## for 
                                                                                                                                                                                                                          ## AWS 
                                                                                                                                                                                                                          ## Storage 
                                                                                                                                                                                                                          ## Gateway</p> 
                                                                                                                                                                                                                          ## </li> 
                                                                                                                                                                                                                          ## </ul>
  ##   
                                                                                                                                                                                                                                  ## NextToken: JString
                                                                                                                                                                                                                                  ##            
                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                  ## Pagination 
                                                                                                                                                                                                                                  ## token
  section = newJObject()
  var valid_402657025 = query.getOrDefault("state")
  valid_402657025 = validateParameter(valid_402657025, JString,
                                      required = false,
                                      default = newJString("CREATED"))
  if valid_402657025 != nil:
    section.add "state", valid_402657025
  var valid_402657026 = query.getOrDefault("createdBefore")
  valid_402657026 = validateParameter(valid_402657026, JString,
                                      required = false, default = nil)
  if valid_402657026 != nil:
    section.add "createdBefore", valid_402657026
  var valid_402657027 = query.getOrDefault("destinationVaultArn")
  valid_402657027 = validateParameter(valid_402657027, JString,
                                      required = false, default = nil)
  if valid_402657027 != nil:
    section.add "destinationVaultArn", valid_402657027
  var valid_402657028 = query.getOrDefault("maxResults")
  valid_402657028 = validateParameter(valid_402657028, JInt, required = false,
                                      default = nil)
  if valid_402657028 != nil:
    section.add "maxResults", valid_402657028
  var valid_402657029 = query.getOrDefault("createdAfter")
  valid_402657029 = validateParameter(valid_402657029, JString,
                                      required = false, default = nil)
  if valid_402657029 != nil:
    section.add "createdAfter", valid_402657029
  var valid_402657030 = query.getOrDefault("nextToken")
  valid_402657030 = validateParameter(valid_402657030, JString,
                                      required = false, default = nil)
  if valid_402657030 != nil:
    section.add "nextToken", valid_402657030
  var valid_402657031 = query.getOrDefault("MaxResults")
  valid_402657031 = validateParameter(valid_402657031, JString,
                                      required = false, default = nil)
  if valid_402657031 != nil:
    section.add "MaxResults", valid_402657031
  var valid_402657032 = query.getOrDefault("resourceArn")
  valid_402657032 = validateParameter(valid_402657032, JString,
                                      required = false, default = nil)
  if valid_402657032 != nil:
    section.add "resourceArn", valid_402657032
  var valid_402657033 = query.getOrDefault("resourceType")
  valid_402657033 = validateParameter(valid_402657033, JString,
                                      required = false, default = nil)
  if valid_402657033 != nil:
    section.add "resourceType", valid_402657033
  var valid_402657034 = query.getOrDefault("NextToken")
  valid_402657034 = validateParameter(valid_402657034, JString,
                                      required = false, default = nil)
  if valid_402657034 != nil:
    section.add "NextToken", valid_402657034
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
  var valid_402657035 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657035 = validateParameter(valid_402657035, JString,
                                      required = false, default = nil)
  if valid_402657035 != nil:
    section.add "X-Amz-Security-Token", valid_402657035
  var valid_402657036 = header.getOrDefault("X-Amz-Signature")
  valid_402657036 = validateParameter(valid_402657036, JString,
                                      required = false, default = nil)
  if valid_402657036 != nil:
    section.add "X-Amz-Signature", valid_402657036
  var valid_402657037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657037 = validateParameter(valid_402657037, JString,
                                      required = false, default = nil)
  if valid_402657037 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657037
  var valid_402657038 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657038 = validateParameter(valid_402657038, JString,
                                      required = false, default = nil)
  if valid_402657038 != nil:
    section.add "X-Amz-Algorithm", valid_402657038
  var valid_402657039 = header.getOrDefault("X-Amz-Date")
  valid_402657039 = validateParameter(valid_402657039, JString,
                                      required = false, default = nil)
  if valid_402657039 != nil:
    section.add "X-Amz-Date", valid_402657039
  var valid_402657040 = header.getOrDefault("X-Amz-Credential")
  valid_402657040 = validateParameter(valid_402657040, JString,
                                      required = false, default = nil)
  if valid_402657040 != nil:
    section.add "X-Amz-Credential", valid_402657040
  var valid_402657041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657041 = validateParameter(valid_402657041, JString,
                                      required = false, default = nil)
  if valid_402657041 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657042: Call_ListCopyJobs_402657022; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns metadata about your copy jobs.
                                                                                         ## 
  let valid = call_402657042.validator(path, query, header, formData, body, _)
  let scheme = call_402657042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657042.makeUrl(scheme.get, call_402657042.host, call_402657042.base,
                                   call_402657042.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657042, uri, valid, _)

proc call*(call_402657043: Call_ListCopyJobs_402657022;
           state: string = "CREATED"; createdBefore: string = "";
           destinationVaultArn: string = ""; maxResults: int = 0;
           createdAfter: string = ""; nextToken: string = "";
           MaxResults: string = ""; resourceArn: string = "";
           resourceType: string = ""; NextToken: string = ""): Recallable =
  ## listCopyJobs
  ## Returns metadata about your copy jobs.
  ##   state: string
                                           ##        : Returns only copy jobs that are in the specified state.
  ##   
                                                                                                              ## createdBefore: string
                                                                                                              ##                
                                                                                                              ## : 
                                                                                                              ## Returns 
                                                                                                              ## only 
                                                                                                              ## copy 
                                                                                                              ## jobs 
                                                                                                              ## that 
                                                                                                              ## were 
                                                                                                              ## created 
                                                                                                              ## before 
                                                                                                              ## the 
                                                                                                              ## specified 
                                                                                                              ## date.
  ##   
                                                                                                                      ## destinationVaultArn: string
                                                                                                                      ##                      
                                                                                                                      ## : 
                                                                                                                      ## An 
                                                                                                                      ## Amazon 
                                                                                                                      ## Resource 
                                                                                                                      ## Name 
                                                                                                                      ## (ARN) 
                                                                                                                      ## that 
                                                                                                                      ## uniquely 
                                                                                                                      ## identifies 
                                                                                                                      ## a 
                                                                                                                      ## source 
                                                                                                                      ## backup 
                                                                                                                      ## vault 
                                                                                                                      ## to 
                                                                                                                      ## copy 
                                                                                                                      ## from; 
                                                                                                                      ## for 
                                                                                                                      ## example, 
                                                                                                                      ## arn:aws:backup:us-east-1:123456789012:vault:aBackupVault. 
  ##   
                                                                                                                                                                                   ## maxResults: int
                                                                                                                                                                                   ##             
                                                                                                                                                                                   ## : 
                                                                                                                                                                                   ## The 
                                                                                                                                                                                   ## maximum 
                                                                                                                                                                                   ## number 
                                                                                                                                                                                   ## of 
                                                                                                                                                                                   ## items 
                                                                                                                                                                                   ## to 
                                                                                                                                                                                   ## be 
                                                                                                                                                                                   ## returned.
  ##   
                                                                                                                                                                                               ## createdAfter: string
                                                                                                                                                                                               ##               
                                                                                                                                                                                               ## : 
                                                                                                                                                                                               ## Returns 
                                                                                                                                                                                               ## only 
                                                                                                                                                                                               ## copy 
                                                                                                                                                                                               ## jobs 
                                                                                                                                                                                               ## that 
                                                                                                                                                                                               ## were 
                                                                                                                                                                                               ## created 
                                                                                                                                                                                               ## after 
                                                                                                                                                                                               ## the 
                                                                                                                                                                                               ## specified 
                                                                                                                                                                                               ## date.
  ##   
                                                                                                                                                                                                       ## nextToken: string
                                                                                                                                                                                                       ##            
                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                       ## The 
                                                                                                                                                                                                       ## next 
                                                                                                                                                                                                       ## item 
                                                                                                                                                                                                       ## following 
                                                                                                                                                                                                       ## a 
                                                                                                                                                                                                       ## partial 
                                                                                                                                                                                                       ## list 
                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                       ## returned 
                                                                                                                                                                                                       ## items. 
                                                                                                                                                                                                       ## For 
                                                                                                                                                                                                       ## example, 
                                                                                                                                                                                                       ## if 
                                                                                                                                                                                                       ## a 
                                                                                                                                                                                                       ## request 
                                                                                                                                                                                                       ## is 
                                                                                                                                                                                                       ## made 
                                                                                                                                                                                                       ## to 
                                                                                                                                                                                                       ## return 
                                                                                                                                                                                                       ## maxResults 
                                                                                                                                                                                                       ## number 
                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                       ## items, 
                                                                                                                                                                                                       ## NextToken 
                                                                                                                                                                                                       ## allows 
                                                                                                                                                                                                       ## you 
                                                                                                                                                                                                       ## to 
                                                                                                                                                                                                       ## return 
                                                                                                                                                                                                       ## more 
                                                                                                                                                                                                       ## items 
                                                                                                                                                                                                       ## in 
                                                                                                                                                                                                       ## your 
                                                                                                                                                                                                       ## list 
                                                                                                                                                                                                       ## starting 
                                                                                                                                                                                                       ## at 
                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                       ## location 
                                                                                                                                                                                                       ## pointed 
                                                                                                                                                                                                       ## to 
                                                                                                                                                                                                       ## by 
                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                       ## next 
                                                                                                                                                                                                       ## token. 
  ##   
                                                                                                                                                                                                                 ## MaxResults: string
                                                                                                                                                                                                                 ##             
                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                 ## Pagination 
                                                                                                                                                                                                                 ## limit
  ##   
                                                                                                                                                                                                                         ## resourceArn: string
                                                                                                                                                                                                                         ##              
                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                         ## Returns 
                                                                                                                                                                                                                         ## only 
                                                                                                                                                                                                                         ## copy 
                                                                                                                                                                                                                         ## jobs 
                                                                                                                                                                                                                         ## that 
                                                                                                                                                                                                                         ## match 
                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                         ## specified 
                                                                                                                                                                                                                         ## resource 
                                                                                                                                                                                                                         ## Amazon 
                                                                                                                                                                                                                         ## Resource 
                                                                                                                                                                                                                         ## Name 
                                                                                                                                                                                                                         ## (ARN). 
  ##   
                                                                                                                                                                                                                                   ## resourceType: string
                                                                                                                                                                                                                                   ##               
                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                   ## <p>Returns 
                                                                                                                                                                                                                                   ## only 
                                                                                                                                                                                                                                   ## backup 
                                                                                                                                                                                                                                   ## jobs 
                                                                                                                                                                                                                                   ## for 
                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                   ## specified 
                                                                                                                                                                                                                                   ## resources:</p> 
                                                                                                                                                                                                                                   ## <ul> 
                                                                                                                                                                                                                                   ## <li> 
                                                                                                                                                                                                                                   ## <p> 
                                                                                                                                                                                                                                   ## <code>DynamoDB</code> 
                                                                                                                                                                                                                                   ## for 
                                                                                                                                                                                                                                   ## Amazon 
                                                                                                                                                                                                                                   ## DynamoDB</p> 
                                                                                                                                                                                                                                   ## </li> 
                                                                                                                                                                                                                                   ## <li> 
                                                                                                                                                                                                                                   ## <p> 
                                                                                                                                                                                                                                   ## <code>EBS</code> 
                                                                                                                                                                                                                                   ## for 
                                                                                                                                                                                                                                   ## Amazon 
                                                                                                                                                                                                                                   ## Elastic 
                                                                                                                                                                                                                                   ## Block 
                                                                                                                                                                                                                                   ## Store</p> 
                                                                                                                                                                                                                                   ## </li> 
                                                                                                                                                                                                                                   ## <li> 
                                                                                                                                                                                                                                   ## <p> 
                                                                                                                                                                                                                                   ## <code>EFS</code> 
                                                                                                                                                                                                                                   ## for 
                                                                                                                                                                                                                                   ## Amazon 
                                                                                                                                                                                                                                   ## Elastic 
                                                                                                                                                                                                                                   ## File 
                                                                                                                                                                                                                                   ## System</p> 
                                                                                                                                                                                                                                   ## </li> 
                                                                                                                                                                                                                                   ## <li> 
                                                                                                                                                                                                                                   ## <p> 
                                                                                                                                                                                                                                   ## <code>RDS</code> 
                                                                                                                                                                                                                                   ## for 
                                                                                                                                                                                                                                   ## Amazon 
                                                                                                                                                                                                                                   ## Relational 
                                                                                                                                                                                                                                   ## Database 
                                                                                                                                                                                                                                   ## Service</p> 
                                                                                                                                                                                                                                   ## </li> 
                                                                                                                                                                                                                                   ## <li> 
                                                                                                                                                                                                                                   ## <p> 
                                                                                                                                                                                                                                   ## <code>Storage 
                                                                                                                                                                                                                                   ## Gateway</code> 
                                                                                                                                                                                                                                   ## for 
                                                                                                                                                                                                                                   ## AWS 
                                                                                                                                                                                                                                   ## Storage 
                                                                                                                                                                                                                                   ## Gateway</p> 
                                                                                                                                                                                                                                   ## </li> 
                                                                                                                                                                                                                                   ## </ul>
  ##   
                                                                                                                                                                                                                                           ## NextToken: string
                                                                                                                                                                                                                                           ##            
                                                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                                                           ## Pagination 
                                                                                                                                                                                                                                           ## token
  var query_402657044 = newJObject()
  add(query_402657044, "state", newJString(state))
  add(query_402657044, "createdBefore", newJString(createdBefore))
  add(query_402657044, "destinationVaultArn", newJString(destinationVaultArn))
  add(query_402657044, "maxResults", newJInt(maxResults))
  add(query_402657044, "createdAfter", newJString(createdAfter))
  add(query_402657044, "nextToken", newJString(nextToken))
  add(query_402657044, "MaxResults", newJString(MaxResults))
  add(query_402657044, "resourceArn", newJString(resourceArn))
  add(query_402657044, "resourceType", newJString(resourceType))
  add(query_402657044, "NextToken", newJString(NextToken))
  result = call_402657043.call(nil, query_402657044, nil, nil, nil)

var listCopyJobs* = Call_ListCopyJobs_402657022(name: "listCopyJobs",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com",
    route: "/copy-jobs/", validator: validate_ListCopyJobs_402657023, base: "/",
    makeUrl: url_ListCopyJobs_402657024, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProtectedResources_402657045 = ref object of OpenApiRestCall_402656044
proc url_ListProtectedResources_402657047(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProtectedResources_402657046(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns an array of resources successfully backed up by AWS Backup, including the time the resource was saved, an Amazon Resource Name (ARN) of the resource, and a resource type.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of items to be returned.
  ##   
                                                                                              ## nextToken: JString
                                                                                              ##            
                                                                                              ## : 
                                                                                              ## The 
                                                                                              ## next 
                                                                                              ## item 
                                                                                              ## following 
                                                                                              ## a 
                                                                                              ## partial 
                                                                                              ## list 
                                                                                              ## of 
                                                                                              ## returned 
                                                                                              ## items. 
                                                                                              ## For 
                                                                                              ## example, 
                                                                                              ## if 
                                                                                              ## a 
                                                                                              ## request 
                                                                                              ## is 
                                                                                              ## made 
                                                                                              ## to 
                                                                                              ## return 
                                                                                              ## <code>maxResults</code> 
                                                                                              ## number 
                                                                                              ## of 
                                                                                              ## items, 
                                                                                              ## <code>NextToken</code> 
                                                                                              ## allows 
                                                                                              ## you 
                                                                                              ## to 
                                                                                              ## return 
                                                                                              ## more 
                                                                                              ## items 
                                                                                              ## in 
                                                                                              ## your 
                                                                                              ## list 
                                                                                              ## starting 
                                                                                              ## at 
                                                                                              ## the 
                                                                                              ## location 
                                                                                              ## pointed 
                                                                                              ## to 
                                                                                              ## by 
                                                                                              ## the 
                                                                                              ## next 
                                                                                              ## token.
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
  var valid_402657048 = query.getOrDefault("maxResults")
  valid_402657048 = validateParameter(valid_402657048, JInt, required = false,
                                      default = nil)
  if valid_402657048 != nil:
    section.add "maxResults", valid_402657048
  var valid_402657049 = query.getOrDefault("nextToken")
  valid_402657049 = validateParameter(valid_402657049, JString,
                                      required = false, default = nil)
  if valid_402657049 != nil:
    section.add "nextToken", valid_402657049
  var valid_402657050 = query.getOrDefault("MaxResults")
  valid_402657050 = validateParameter(valid_402657050, JString,
                                      required = false, default = nil)
  if valid_402657050 != nil:
    section.add "MaxResults", valid_402657050
  var valid_402657051 = query.getOrDefault("NextToken")
  valid_402657051 = validateParameter(valid_402657051, JString,
                                      required = false, default = nil)
  if valid_402657051 != nil:
    section.add "NextToken", valid_402657051
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
  var valid_402657052 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657052 = validateParameter(valid_402657052, JString,
                                      required = false, default = nil)
  if valid_402657052 != nil:
    section.add "X-Amz-Security-Token", valid_402657052
  var valid_402657053 = header.getOrDefault("X-Amz-Signature")
  valid_402657053 = validateParameter(valid_402657053, JString,
                                      required = false, default = nil)
  if valid_402657053 != nil:
    section.add "X-Amz-Signature", valid_402657053
  var valid_402657054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657054 = validateParameter(valid_402657054, JString,
                                      required = false, default = nil)
  if valid_402657054 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657054
  var valid_402657055 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657055 = validateParameter(valid_402657055, JString,
                                      required = false, default = nil)
  if valid_402657055 != nil:
    section.add "X-Amz-Algorithm", valid_402657055
  var valid_402657056 = header.getOrDefault("X-Amz-Date")
  valid_402657056 = validateParameter(valid_402657056, JString,
                                      required = false, default = nil)
  if valid_402657056 != nil:
    section.add "X-Amz-Date", valid_402657056
  var valid_402657057 = header.getOrDefault("X-Amz-Credential")
  valid_402657057 = validateParameter(valid_402657057, JString,
                                      required = false, default = nil)
  if valid_402657057 != nil:
    section.add "X-Amz-Credential", valid_402657057
  var valid_402657058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657058 = validateParameter(valid_402657058, JString,
                                      required = false, default = nil)
  if valid_402657058 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657059: Call_ListProtectedResources_402657045;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns an array of resources successfully backed up by AWS Backup, including the time the resource was saved, an Amazon Resource Name (ARN) of the resource, and a resource type.
                                                                                         ## 
  let valid = call_402657059.validator(path, query, header, formData, body, _)
  let scheme = call_402657059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657059.makeUrl(scheme.get, call_402657059.host, call_402657059.base,
                                   call_402657059.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657059, uri, valid, _)

proc call*(call_402657060: Call_ListProtectedResources_402657045;
           maxResults: int = 0; nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listProtectedResources
  ## Returns an array of resources successfully backed up by AWS Backup, including the time the resource was saved, an Amazon Resource Name (ARN) of the resource, and a resource type.
  ##   
                                                                                                                                                                                       ## maxResults: int
                                                                                                                                                                                       ##             
                                                                                                                                                                                       ## : 
                                                                                                                                                                                       ## The 
                                                                                                                                                                                       ## maximum 
                                                                                                                                                                                       ## number 
                                                                                                                                                                                       ## of 
                                                                                                                                                                                       ## items 
                                                                                                                                                                                       ## to 
                                                                                                                                                                                       ## be 
                                                                                                                                                                                       ## returned.
  ##   
                                                                                                                                                                                                   ## nextToken: string
                                                                                                                                                                                                   ##            
                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                   ## The 
                                                                                                                                                                                                   ## next 
                                                                                                                                                                                                   ## item 
                                                                                                                                                                                                   ## following 
                                                                                                                                                                                                   ## a 
                                                                                                                                                                                                   ## partial 
                                                                                                                                                                                                   ## list 
                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                   ## returned 
                                                                                                                                                                                                   ## items. 
                                                                                                                                                                                                   ## For 
                                                                                                                                                                                                   ## example, 
                                                                                                                                                                                                   ## if 
                                                                                                                                                                                                   ## a 
                                                                                                                                                                                                   ## request 
                                                                                                                                                                                                   ## is 
                                                                                                                                                                                                   ## made 
                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                   ## return 
                                                                                                                                                                                                   ## <code>maxResults</code> 
                                                                                                                                                                                                   ## number 
                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                   ## items, 
                                                                                                                                                                                                   ## <code>NextToken</code> 
                                                                                                                                                                                                   ## allows 
                                                                                                                                                                                                   ## you 
                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                   ## return 
                                                                                                                                                                                                   ## more 
                                                                                                                                                                                                   ## items 
                                                                                                                                                                                                   ## in 
                                                                                                                                                                                                   ## your 
                                                                                                                                                                                                   ## list 
                                                                                                                                                                                                   ## starting 
                                                                                                                                                                                                   ## at 
                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                   ## location 
                                                                                                                                                                                                   ## pointed 
                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                   ## by 
                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                   ## next 
                                                                                                                                                                                                   ## token.
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
  var query_402657061 = newJObject()
  add(query_402657061, "maxResults", newJInt(maxResults))
  add(query_402657061, "nextToken", newJString(nextToken))
  add(query_402657061, "MaxResults", newJString(MaxResults))
  add(query_402657061, "NextToken", newJString(NextToken))
  result = call_402657060.call(nil, query_402657061, nil, nil, nil)

var listProtectedResources* = Call_ListProtectedResources_402657045(
    name: "listProtectedResources", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/resources/",
    validator: validate_ListProtectedResources_402657046, base: "/",
    makeUrl: url_ListProtectedResources_402657047,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecoveryPointsByBackupVault_402657062 = ref object of OpenApiRestCall_402656044
proc url_ListRecoveryPointsByBackupVault_402657064(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path,
         "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
                 (kind: VariableSegment, value: "backupVaultName"),
                 (kind: ConstantSegment, value: "/recovery-points/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListRecoveryPointsByBackupVault_402657063(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns detailed information about the recovery points stored in a backup vault.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
                                 ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `backupVaultName` field"
  var valid_402657065 = path.getOrDefault("backupVaultName")
  valid_402657065 = validateParameter(valid_402657065, JString, required = true,
                                      default = nil)
  if valid_402657065 != nil:
    section.add "backupVaultName", valid_402657065
  result.add "path", section
  ## parameters in `query` object:
  ##   createdBefore: JString
                                  ##                : Returns only recovery points that were created before the specified timestamp.
  ##   
                                                                                                                                    ## maxResults: JInt
                                                                                                                                    ##             
                                                                                                                                    ## : 
                                                                                                                                    ## The 
                                                                                                                                    ## maximum 
                                                                                                                                    ## number 
                                                                                                                                    ## of 
                                                                                                                                    ## items 
                                                                                                                                    ## to 
                                                                                                                                    ## be 
                                                                                                                                    ## returned.
  ##   
                                                                                                                                                ## createdAfter: JString
                                                                                                                                                ##               
                                                                                                                                                ## : 
                                                                                                                                                ## Returns 
                                                                                                                                                ## only 
                                                                                                                                                ## recovery 
                                                                                                                                                ## points 
                                                                                                                                                ## that 
                                                                                                                                                ## were 
                                                                                                                                                ## created 
                                                                                                                                                ## after 
                                                                                                                                                ## the 
                                                                                                                                                ## specified 
                                                                                                                                                ## timestamp.
  ##   
                                                                                                                                                             ## nextToken: JString
                                                                                                                                                             ##            
                                                                                                                                                             ## : 
                                                                                                                                                             ## The 
                                                                                                                                                             ## next 
                                                                                                                                                             ## item 
                                                                                                                                                             ## following 
                                                                                                                                                             ## a 
                                                                                                                                                             ## partial 
                                                                                                                                                             ## list 
                                                                                                                                                             ## of 
                                                                                                                                                             ## returned 
                                                                                                                                                             ## items. 
                                                                                                                                                             ## For 
                                                                                                                                                             ## example, 
                                                                                                                                                             ## if 
                                                                                                                                                             ## a 
                                                                                                                                                             ## request 
                                                                                                                                                             ## is 
                                                                                                                                                             ## made 
                                                                                                                                                             ## to 
                                                                                                                                                             ## return 
                                                                                                                                                             ## <code>maxResults</code> 
                                                                                                                                                             ## number 
                                                                                                                                                             ## of 
                                                                                                                                                             ## items, 
                                                                                                                                                             ## <code>NextToken</code> 
                                                                                                                                                             ## allows 
                                                                                                                                                             ## you 
                                                                                                                                                             ## to 
                                                                                                                                                             ## return 
                                                                                                                                                             ## more 
                                                                                                                                                             ## items 
                                                                                                                                                             ## in 
                                                                                                                                                             ## your 
                                                                                                                                                             ## list 
                                                                                                                                                             ## starting 
                                                                                                                                                             ## at 
                                                                                                                                                             ## the 
                                                                                                                                                             ## location 
                                                                                                                                                             ## pointed 
                                                                                                                                                             ## to 
                                                                                                                                                             ## by 
                                                                                                                                                             ## the 
                                                                                                                                                             ## next 
                                                                                                                                                             ## token.
  ##   
                                                                                                                                                                      ## backupPlanId: JString
                                                                                                                                                                      ##               
                                                                                                                                                                      ## : 
                                                                                                                                                                      ## Returns 
                                                                                                                                                                      ## only 
                                                                                                                                                                      ## recovery 
                                                                                                                                                                      ## points 
                                                                                                                                                                      ## that 
                                                                                                                                                                      ## match 
                                                                                                                                                                      ## the 
                                                                                                                                                                      ## specified 
                                                                                                                                                                      ## backup 
                                                                                                                                                                      ## plan 
                                                                                                                                                                      ## ID.
  ##   
                                                                                                                                                                            ## MaxResults: JString
                                                                                                                                                                            ##             
                                                                                                                                                                            ## : 
                                                                                                                                                                            ## Pagination 
                                                                                                                                                                            ## limit
  ##   
                                                                                                                                                                                    ## resourceArn: JString
                                                                                                                                                                                    ##              
                                                                                                                                                                                    ## : 
                                                                                                                                                                                    ## Returns 
                                                                                                                                                                                    ## only 
                                                                                                                                                                                    ## recovery 
                                                                                                                                                                                    ## points 
                                                                                                                                                                                    ## that 
                                                                                                                                                                                    ## match 
                                                                                                                                                                                    ## the 
                                                                                                                                                                                    ## specified 
                                                                                                                                                                                    ## resource 
                                                                                                                                                                                    ## Amazon 
                                                                                                                                                                                    ## Resource 
                                                                                                                                                                                    ## Name 
                                                                                                                                                                                    ## (ARN).
  ##   
                                                                                                                                                                                             ## resourceType: JString
                                                                                                                                                                                             ##               
                                                                                                                                                                                             ## : 
                                                                                                                                                                                             ## Returns 
                                                                                                                                                                                             ## only 
                                                                                                                                                                                             ## recovery 
                                                                                                                                                                                             ## points 
                                                                                                                                                                                             ## that 
                                                                                                                                                                                             ## match 
                                                                                                                                                                                             ## the 
                                                                                                                                                                                             ## specified 
                                                                                                                                                                                             ## resource 
                                                                                                                                                                                             ## type.
  ##   
                                                                                                                                                                                                     ## NextToken: JString
                                                                                                                                                                                                     ##            
                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                     ## Pagination 
                                                                                                                                                                                                     ## token
  section = newJObject()
  var valid_402657066 = query.getOrDefault("createdBefore")
  valid_402657066 = validateParameter(valid_402657066, JString,
                                      required = false, default = nil)
  if valid_402657066 != nil:
    section.add "createdBefore", valid_402657066
  var valid_402657067 = query.getOrDefault("maxResults")
  valid_402657067 = validateParameter(valid_402657067, JInt, required = false,
                                      default = nil)
  if valid_402657067 != nil:
    section.add "maxResults", valid_402657067
  var valid_402657068 = query.getOrDefault("createdAfter")
  valid_402657068 = validateParameter(valid_402657068, JString,
                                      required = false, default = nil)
  if valid_402657068 != nil:
    section.add "createdAfter", valid_402657068
  var valid_402657069 = query.getOrDefault("nextToken")
  valid_402657069 = validateParameter(valid_402657069, JString,
                                      required = false, default = nil)
  if valid_402657069 != nil:
    section.add "nextToken", valid_402657069
  var valid_402657070 = query.getOrDefault("backupPlanId")
  valid_402657070 = validateParameter(valid_402657070, JString,
                                      required = false, default = nil)
  if valid_402657070 != nil:
    section.add "backupPlanId", valid_402657070
  var valid_402657071 = query.getOrDefault("MaxResults")
  valid_402657071 = validateParameter(valid_402657071, JString,
                                      required = false, default = nil)
  if valid_402657071 != nil:
    section.add "MaxResults", valid_402657071
  var valid_402657072 = query.getOrDefault("resourceArn")
  valid_402657072 = validateParameter(valid_402657072, JString,
                                      required = false, default = nil)
  if valid_402657072 != nil:
    section.add "resourceArn", valid_402657072
  var valid_402657073 = query.getOrDefault("resourceType")
  valid_402657073 = validateParameter(valid_402657073, JString,
                                      required = false, default = nil)
  if valid_402657073 != nil:
    section.add "resourceType", valid_402657073
  var valid_402657074 = query.getOrDefault("NextToken")
  valid_402657074 = validateParameter(valid_402657074, JString,
                                      required = false, default = nil)
  if valid_402657074 != nil:
    section.add "NextToken", valid_402657074
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
  var valid_402657075 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657075 = validateParameter(valid_402657075, JString,
                                      required = false, default = nil)
  if valid_402657075 != nil:
    section.add "X-Amz-Security-Token", valid_402657075
  var valid_402657076 = header.getOrDefault("X-Amz-Signature")
  valid_402657076 = validateParameter(valid_402657076, JString,
                                      required = false, default = nil)
  if valid_402657076 != nil:
    section.add "X-Amz-Signature", valid_402657076
  var valid_402657077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657077 = validateParameter(valid_402657077, JString,
                                      required = false, default = nil)
  if valid_402657077 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657077
  var valid_402657078 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657078 = validateParameter(valid_402657078, JString,
                                      required = false, default = nil)
  if valid_402657078 != nil:
    section.add "X-Amz-Algorithm", valid_402657078
  var valid_402657079 = header.getOrDefault("X-Amz-Date")
  valid_402657079 = validateParameter(valid_402657079, JString,
                                      required = false, default = nil)
  if valid_402657079 != nil:
    section.add "X-Amz-Date", valid_402657079
  var valid_402657080 = header.getOrDefault("X-Amz-Credential")
  valid_402657080 = validateParameter(valid_402657080, JString,
                                      required = false, default = nil)
  if valid_402657080 != nil:
    section.add "X-Amz-Credential", valid_402657080
  var valid_402657081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657081 = validateParameter(valid_402657081, JString,
                                      required = false, default = nil)
  if valid_402657081 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657082: Call_ListRecoveryPointsByBackupVault_402657062;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns detailed information about the recovery points stored in a backup vault.
                                                                                         ## 
  let valid = call_402657082.validator(path, query, header, formData, body, _)
  let scheme = call_402657082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657082.makeUrl(scheme.get, call_402657082.host, call_402657082.base,
                                   call_402657082.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657082, uri, valid, _)

proc call*(call_402657083: Call_ListRecoveryPointsByBackupVault_402657062;
           backupVaultName: string; createdBefore: string = "";
           maxResults: int = 0; createdAfter: string = "";
           nextToken: string = ""; backupPlanId: string = "";
           MaxResults: string = ""; resourceArn: string = "";
           resourceType: string = ""; NextToken: string = ""): Recallable =
  ## listRecoveryPointsByBackupVault
  ## Returns detailed information about the recovery points stored in a backup vault.
  ##   
                                                                                     ## createdBefore: string
                                                                                     ##                
                                                                                     ## : 
                                                                                     ## Returns 
                                                                                     ## only 
                                                                                     ## recovery 
                                                                                     ## points 
                                                                                     ## that 
                                                                                     ## were 
                                                                                     ## created 
                                                                                     ## before 
                                                                                     ## the 
                                                                                     ## specified 
                                                                                     ## timestamp.
  ##   
                                                                                                  ## maxResults: int
                                                                                                  ##             
                                                                                                  ## : 
                                                                                                  ## The 
                                                                                                  ## maximum 
                                                                                                  ## number 
                                                                                                  ## of 
                                                                                                  ## items 
                                                                                                  ## to 
                                                                                                  ## be 
                                                                                                  ## returned.
  ##   
                                                                                                              ## createdAfter: string
                                                                                                              ##               
                                                                                                              ## : 
                                                                                                              ## Returns 
                                                                                                              ## only 
                                                                                                              ## recovery 
                                                                                                              ## points 
                                                                                                              ## that 
                                                                                                              ## were 
                                                                                                              ## created 
                                                                                                              ## after 
                                                                                                              ## the 
                                                                                                              ## specified 
                                                                                                              ## timestamp.
  ##   
                                                                                                                           ## nextToken: string
                                                                                                                           ##            
                                                                                                                           ## : 
                                                                                                                           ## The 
                                                                                                                           ## next 
                                                                                                                           ## item 
                                                                                                                           ## following 
                                                                                                                           ## a 
                                                                                                                           ## partial 
                                                                                                                           ## list 
                                                                                                                           ## of 
                                                                                                                           ## returned 
                                                                                                                           ## items. 
                                                                                                                           ## For 
                                                                                                                           ## example, 
                                                                                                                           ## if 
                                                                                                                           ## a 
                                                                                                                           ## request 
                                                                                                                           ## is 
                                                                                                                           ## made 
                                                                                                                           ## to 
                                                                                                                           ## return 
                                                                                                                           ## <code>maxResults</code> 
                                                                                                                           ## number 
                                                                                                                           ## of 
                                                                                                                           ## items, 
                                                                                                                           ## <code>NextToken</code> 
                                                                                                                           ## allows 
                                                                                                                           ## you 
                                                                                                                           ## to 
                                                                                                                           ## return 
                                                                                                                           ## more 
                                                                                                                           ## items 
                                                                                                                           ## in 
                                                                                                                           ## your 
                                                                                                                           ## list 
                                                                                                                           ## starting 
                                                                                                                           ## at 
                                                                                                                           ## the 
                                                                                                                           ## location 
                                                                                                                           ## pointed 
                                                                                                                           ## to 
                                                                                                                           ## by 
                                                                                                                           ## the 
                                                                                                                           ## next 
                                                                                                                           ## token.
  ##   
                                                                                                                                    ## backupPlanId: string
                                                                                                                                    ##               
                                                                                                                                    ## : 
                                                                                                                                    ## Returns 
                                                                                                                                    ## only 
                                                                                                                                    ## recovery 
                                                                                                                                    ## points 
                                                                                                                                    ## that 
                                                                                                                                    ## match 
                                                                                                                                    ## the 
                                                                                                                                    ## specified 
                                                                                                                                    ## backup 
                                                                                                                                    ## plan 
                                                                                                                                    ## ID.
  ##   
                                                                                                                                          ## MaxResults: string
                                                                                                                                          ##             
                                                                                                                                          ## : 
                                                                                                                                          ## Pagination 
                                                                                                                                          ## limit
  ##   
                                                                                                                                                  ## resourceArn: string
                                                                                                                                                  ##              
                                                                                                                                                  ## : 
                                                                                                                                                  ## Returns 
                                                                                                                                                  ## only 
                                                                                                                                                  ## recovery 
                                                                                                                                                  ## points 
                                                                                                                                                  ## that 
                                                                                                                                                  ## match 
                                                                                                                                                  ## the 
                                                                                                                                                  ## specified 
                                                                                                                                                  ## resource 
                                                                                                                                                  ## Amazon 
                                                                                                                                                  ## Resource 
                                                                                                                                                  ## Name 
                                                                                                                                                  ## (ARN).
  ##   
                                                                                                                                                           ## resourceType: string
                                                                                                                                                           ##               
                                                                                                                                                           ## : 
                                                                                                                                                           ## Returns 
                                                                                                                                                           ## only 
                                                                                                                                                           ## recovery 
                                                                                                                                                           ## points 
                                                                                                                                                           ## that 
                                                                                                                                                           ## match 
                                                                                                                                                           ## the 
                                                                                                                                                           ## specified 
                                                                                                                                                           ## resource 
                                                                                                                                                           ## type.
  ##   
                                                                                                                                                                   ## NextToken: string
                                                                                                                                                                   ##            
                                                                                                                                                                   ## : 
                                                                                                                                                                   ## Pagination 
                                                                                                                                                                   ## token
  ##   
                                                                                                                                                                           ## backupVaultName: string (required)
                                                                                                                                                                           ##                  
                                                                                                                                                                           ## : 
                                                                                                                                                                           ## The 
                                                                                                                                                                           ## name 
                                                                                                                                                                           ## of 
                                                                                                                                                                           ## a 
                                                                                                                                                                           ## logical 
                                                                                                                                                                           ## container 
                                                                                                                                                                           ## where 
                                                                                                                                                                           ## backups 
                                                                                                                                                                           ## are 
                                                                                                                                                                           ## stored. 
                                                                                                                                                                           ## Backup 
                                                                                                                                                                           ## vaults 
                                                                                                                                                                           ## are 
                                                                                                                                                                           ## identified 
                                                                                                                                                                           ## by 
                                                                                                                                                                           ## names 
                                                                                                                                                                           ## that 
                                                                                                                                                                           ## are 
                                                                                                                                                                           ## unique 
                                                                                                                                                                           ## to 
                                                                                                                                                                           ## the 
                                                                                                                                                                           ## account 
                                                                                                                                                                           ## used 
                                                                                                                                                                           ## to 
                                                                                                                                                                           ## create 
                                                                                                                                                                           ## them 
                                                                                                                                                                           ## and 
                                                                                                                                                                           ## the 
                                                                                                                                                                           ## AWS 
                                                                                                                                                                           ## Region 
                                                                                                                                                                           ## where 
                                                                                                                                                                           ## they 
                                                                                                                                                                           ## are 
                                                                                                                                                                           ## created. 
                                                                                                                                                                           ## They 
                                                                                                                                                                           ## consist 
                                                                                                                                                                           ## of 
                                                                                                                                                                           ## lowercase 
                                                                                                                                                                           ## letters, 
                                                                                                                                                                           ## numbers, 
                                                                                                                                                                           ## and 
                                                                                                                                                                           ## hyphens.
  var path_402657084 = newJObject()
  var query_402657085 = newJObject()
  add(query_402657085, "createdBefore", newJString(createdBefore))
  add(query_402657085, "maxResults", newJInt(maxResults))
  add(query_402657085, "createdAfter", newJString(createdAfter))
  add(query_402657085, "nextToken", newJString(nextToken))
  add(query_402657085, "backupPlanId", newJString(backupPlanId))
  add(query_402657085, "MaxResults", newJString(MaxResults))
  add(query_402657085, "resourceArn", newJString(resourceArn))
  add(query_402657085, "resourceType", newJString(resourceType))
  add(query_402657085, "NextToken", newJString(NextToken))
  add(path_402657084, "backupVaultName", newJString(backupVaultName))
  result = call_402657083.call(path_402657084, query_402657085, nil, nil, nil)

var listRecoveryPointsByBackupVault* = Call_ListRecoveryPointsByBackupVault_402657062(
    name: "listRecoveryPointsByBackupVault", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/recovery-points/",
    validator: validate_ListRecoveryPointsByBackupVault_402657063, base: "/",
    makeUrl: url_ListRecoveryPointsByBackupVault_402657064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecoveryPointsByResource_402657086 = ref object of OpenApiRestCall_402656044
proc url_ListRecoveryPointsByResource_402657088(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/resources/"),
                 (kind: VariableSegment, value: "resourceArn"),
                 (kind: ConstantSegment, value: "/recovery-points/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListRecoveryPointsByResource_402657087(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns detailed information about recovery points of the type specified by a resource Amazon Resource Name (ARN).
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              : An ARN that uniquely identifies a resource. The format of the ARN depends on the resource type.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402657089 = path.getOrDefault("resourceArn")
  valid_402657089 = validateParameter(valid_402657089, JString, required = true,
                                      default = nil)
  if valid_402657089 != nil:
    section.add "resourceArn", valid_402657089
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of items to be returned.
  ##   
                                                                                              ## nextToken: JString
                                                                                              ##            
                                                                                              ## : 
                                                                                              ## The 
                                                                                              ## next 
                                                                                              ## item 
                                                                                              ## following 
                                                                                              ## a 
                                                                                              ## partial 
                                                                                              ## list 
                                                                                              ## of 
                                                                                              ## returned 
                                                                                              ## items. 
                                                                                              ## For 
                                                                                              ## example, 
                                                                                              ## if 
                                                                                              ## a 
                                                                                              ## request 
                                                                                              ## is 
                                                                                              ## made 
                                                                                              ## to 
                                                                                              ## return 
                                                                                              ## <code>maxResults</code> 
                                                                                              ## number 
                                                                                              ## of 
                                                                                              ## items, 
                                                                                              ## <code>NextToken</code> 
                                                                                              ## allows 
                                                                                              ## you 
                                                                                              ## to 
                                                                                              ## return 
                                                                                              ## more 
                                                                                              ## items 
                                                                                              ## in 
                                                                                              ## your 
                                                                                              ## list 
                                                                                              ## starting 
                                                                                              ## at 
                                                                                              ## the 
                                                                                              ## location 
                                                                                              ## pointed 
                                                                                              ## to 
                                                                                              ## by 
                                                                                              ## the 
                                                                                              ## next 
                                                                                              ## token.
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
  var valid_402657090 = query.getOrDefault("maxResults")
  valid_402657090 = validateParameter(valid_402657090, JInt, required = false,
                                      default = nil)
  if valid_402657090 != nil:
    section.add "maxResults", valid_402657090
  var valid_402657091 = query.getOrDefault("nextToken")
  valid_402657091 = validateParameter(valid_402657091, JString,
                                      required = false, default = nil)
  if valid_402657091 != nil:
    section.add "nextToken", valid_402657091
  var valid_402657092 = query.getOrDefault("MaxResults")
  valid_402657092 = validateParameter(valid_402657092, JString,
                                      required = false, default = nil)
  if valid_402657092 != nil:
    section.add "MaxResults", valid_402657092
  var valid_402657093 = query.getOrDefault("NextToken")
  valid_402657093 = validateParameter(valid_402657093, JString,
                                      required = false, default = nil)
  if valid_402657093 != nil:
    section.add "NextToken", valid_402657093
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
  var valid_402657094 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657094 = validateParameter(valid_402657094, JString,
                                      required = false, default = nil)
  if valid_402657094 != nil:
    section.add "X-Amz-Security-Token", valid_402657094
  var valid_402657095 = header.getOrDefault("X-Amz-Signature")
  valid_402657095 = validateParameter(valid_402657095, JString,
                                      required = false, default = nil)
  if valid_402657095 != nil:
    section.add "X-Amz-Signature", valid_402657095
  var valid_402657096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657096 = validateParameter(valid_402657096, JString,
                                      required = false, default = nil)
  if valid_402657096 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657096
  var valid_402657097 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657097 = validateParameter(valid_402657097, JString,
                                      required = false, default = nil)
  if valid_402657097 != nil:
    section.add "X-Amz-Algorithm", valid_402657097
  var valid_402657098 = header.getOrDefault("X-Amz-Date")
  valid_402657098 = validateParameter(valid_402657098, JString,
                                      required = false, default = nil)
  if valid_402657098 != nil:
    section.add "X-Amz-Date", valid_402657098
  var valid_402657099 = header.getOrDefault("X-Amz-Credential")
  valid_402657099 = validateParameter(valid_402657099, JString,
                                      required = false, default = nil)
  if valid_402657099 != nil:
    section.add "X-Amz-Credential", valid_402657099
  var valid_402657100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657100 = validateParameter(valid_402657100, JString,
                                      required = false, default = nil)
  if valid_402657100 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657101: Call_ListRecoveryPointsByResource_402657086;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns detailed information about recovery points of the type specified by a resource Amazon Resource Name (ARN).
                                                                                         ## 
  let valid = call_402657101.validator(path, query, header, formData, body, _)
  let scheme = call_402657101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657101.makeUrl(scheme.get, call_402657101.host, call_402657101.base,
                                   call_402657101.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657101, uri, valid, _)

proc call*(call_402657102: Call_ListRecoveryPointsByResource_402657086;
           resourceArn: string; maxResults: int = 0; nextToken: string = "";
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listRecoveryPointsByResource
  ## Returns detailed information about recovery points of the type specified by a resource Amazon Resource Name (ARN).
  ##   
                                                                                                                       ## maxResults: int
                                                                                                                       ##             
                                                                                                                       ## : 
                                                                                                                       ## The 
                                                                                                                       ## maximum 
                                                                                                                       ## number 
                                                                                                                       ## of 
                                                                                                                       ## items 
                                                                                                                       ## to 
                                                                                                                       ## be 
                                                                                                                       ## returned.
  ##   
                                                                                                                                   ## nextToken: string
                                                                                                                                   ##            
                                                                                                                                   ## : 
                                                                                                                                   ## The 
                                                                                                                                   ## next 
                                                                                                                                   ## item 
                                                                                                                                   ## following 
                                                                                                                                   ## a 
                                                                                                                                   ## partial 
                                                                                                                                   ## list 
                                                                                                                                   ## of 
                                                                                                                                   ## returned 
                                                                                                                                   ## items. 
                                                                                                                                   ## For 
                                                                                                                                   ## example, 
                                                                                                                                   ## if 
                                                                                                                                   ## a 
                                                                                                                                   ## request 
                                                                                                                                   ## is 
                                                                                                                                   ## made 
                                                                                                                                   ## to 
                                                                                                                                   ## return 
                                                                                                                                   ## <code>maxResults</code> 
                                                                                                                                   ## number 
                                                                                                                                   ## of 
                                                                                                                                   ## items, 
                                                                                                                                   ## <code>NextToken</code> 
                                                                                                                                   ## allows 
                                                                                                                                   ## you 
                                                                                                                                   ## to 
                                                                                                                                   ## return 
                                                                                                                                   ## more 
                                                                                                                                   ## items 
                                                                                                                                   ## in 
                                                                                                                                   ## your 
                                                                                                                                   ## list 
                                                                                                                                   ## starting 
                                                                                                                                   ## at 
                                                                                                                                   ## the 
                                                                                                                                   ## location 
                                                                                                                                   ## pointed 
                                                                                                                                   ## to 
                                                                                                                                   ## by 
                                                                                                                                   ## the 
                                                                                                                                   ## next 
                                                                                                                                   ## token.
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
                                                                                                                                                            ## resourceArn: string (required)
                                                                                                                                                            ##              
                                                                                                                                                            ## : 
                                                                                                                                                            ## An 
                                                                                                                                                            ## ARN 
                                                                                                                                                            ## that 
                                                                                                                                                            ## uniquely 
                                                                                                                                                            ## identifies 
                                                                                                                                                            ## a 
                                                                                                                                                            ## resource. 
                                                                                                                                                            ## The 
                                                                                                                                                            ## format 
                                                                                                                                                            ## of 
                                                                                                                                                            ## the 
                                                                                                                                                            ## ARN 
                                                                                                                                                            ## depends 
                                                                                                                                                            ## on 
                                                                                                                                                            ## the 
                                                                                                                                                            ## resource 
                                                                                                                                                            ## type.
  var path_402657103 = newJObject()
  var query_402657104 = newJObject()
  add(query_402657104, "maxResults", newJInt(maxResults))
  add(query_402657104, "nextToken", newJString(nextToken))
  add(query_402657104, "MaxResults", newJString(MaxResults))
  add(query_402657104, "NextToken", newJString(NextToken))
  add(path_402657103, "resourceArn", newJString(resourceArn))
  result = call_402657102.call(path_402657103, query_402657104, nil, nil, nil)

var listRecoveryPointsByResource* = Call_ListRecoveryPointsByResource_402657086(
    name: "listRecoveryPointsByResource", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/resources/{resourceArn}/recovery-points/",
    validator: validate_ListRecoveryPointsByResource_402657087, base: "/",
    makeUrl: url_ListRecoveryPointsByResource_402657088,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRestoreJobs_402657105 = ref object of OpenApiRestCall_402656044
proc url_ListRestoreJobs_402657107(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRestoreJobs_402657106(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of jobs that AWS Backup initiated to restore a saved resource, including metadata about the recovery process.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of items to be returned.
  ##   
                                                                                              ## nextToken: JString
                                                                                              ##            
                                                                                              ## : 
                                                                                              ## The 
                                                                                              ## next 
                                                                                              ## item 
                                                                                              ## following 
                                                                                              ## a 
                                                                                              ## partial 
                                                                                              ## list 
                                                                                              ## of 
                                                                                              ## returned 
                                                                                              ## items. 
                                                                                              ## For 
                                                                                              ## example, 
                                                                                              ## if 
                                                                                              ## a 
                                                                                              ## request 
                                                                                              ## is 
                                                                                              ## made 
                                                                                              ## to 
                                                                                              ## return 
                                                                                              ## <code>maxResults</code> 
                                                                                              ## number 
                                                                                              ## of 
                                                                                              ## items, 
                                                                                              ## <code>NextToken</code> 
                                                                                              ## allows 
                                                                                              ## you 
                                                                                              ## to 
                                                                                              ## return 
                                                                                              ## more 
                                                                                              ## items 
                                                                                              ## in 
                                                                                              ## your 
                                                                                              ## list 
                                                                                              ## starting 
                                                                                              ## at 
                                                                                              ## the 
                                                                                              ## location 
                                                                                              ## pointed 
                                                                                              ## to 
                                                                                              ## by 
                                                                                              ## the 
                                                                                              ## next 
                                                                                              ## token.
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
  var valid_402657108 = query.getOrDefault("maxResults")
  valid_402657108 = validateParameter(valid_402657108, JInt, required = false,
                                      default = nil)
  if valid_402657108 != nil:
    section.add "maxResults", valid_402657108
  var valid_402657109 = query.getOrDefault("nextToken")
  valid_402657109 = validateParameter(valid_402657109, JString,
                                      required = false, default = nil)
  if valid_402657109 != nil:
    section.add "nextToken", valid_402657109
  var valid_402657110 = query.getOrDefault("MaxResults")
  valid_402657110 = validateParameter(valid_402657110, JString,
                                      required = false, default = nil)
  if valid_402657110 != nil:
    section.add "MaxResults", valid_402657110
  var valid_402657111 = query.getOrDefault("NextToken")
  valid_402657111 = validateParameter(valid_402657111, JString,
                                      required = false, default = nil)
  if valid_402657111 != nil:
    section.add "NextToken", valid_402657111
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
  var valid_402657112 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657112 = validateParameter(valid_402657112, JString,
                                      required = false, default = nil)
  if valid_402657112 != nil:
    section.add "X-Amz-Security-Token", valid_402657112
  var valid_402657113 = header.getOrDefault("X-Amz-Signature")
  valid_402657113 = validateParameter(valid_402657113, JString,
                                      required = false, default = nil)
  if valid_402657113 != nil:
    section.add "X-Amz-Signature", valid_402657113
  var valid_402657114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657114 = validateParameter(valid_402657114, JString,
                                      required = false, default = nil)
  if valid_402657114 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657114
  var valid_402657115 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657115 = validateParameter(valid_402657115, JString,
                                      required = false, default = nil)
  if valid_402657115 != nil:
    section.add "X-Amz-Algorithm", valid_402657115
  var valid_402657116 = header.getOrDefault("X-Amz-Date")
  valid_402657116 = validateParameter(valid_402657116, JString,
                                      required = false, default = nil)
  if valid_402657116 != nil:
    section.add "X-Amz-Date", valid_402657116
  var valid_402657117 = header.getOrDefault("X-Amz-Credential")
  valid_402657117 = validateParameter(valid_402657117, JString,
                                      required = false, default = nil)
  if valid_402657117 != nil:
    section.add "X-Amz-Credential", valid_402657117
  var valid_402657118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657118 = validateParameter(valid_402657118, JString,
                                      required = false, default = nil)
  if valid_402657118 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657119: Call_ListRestoreJobs_402657105; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of jobs that AWS Backup initiated to restore a saved resource, including metadata about the recovery process.
                                                                                         ## 
  let valid = call_402657119.validator(path, query, header, formData, body, _)
  let scheme = call_402657119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657119.makeUrl(scheme.get, call_402657119.host, call_402657119.base,
                                   call_402657119.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657119, uri, valid, _)

proc call*(call_402657120: Call_ListRestoreJobs_402657105; maxResults: int = 0;
           nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listRestoreJobs
  ## Returns a list of jobs that AWS Backup initiated to restore a saved resource, including metadata about the recovery process.
  ##   
                                                                                                                                 ## maxResults: int
                                                                                                                                 ##             
                                                                                                                                 ## : 
                                                                                                                                 ## The 
                                                                                                                                 ## maximum 
                                                                                                                                 ## number 
                                                                                                                                 ## of 
                                                                                                                                 ## items 
                                                                                                                                 ## to 
                                                                                                                                 ## be 
                                                                                                                                 ## returned.
  ##   
                                                                                                                                             ## nextToken: string
                                                                                                                                             ##            
                                                                                                                                             ## : 
                                                                                                                                             ## The 
                                                                                                                                             ## next 
                                                                                                                                             ## item 
                                                                                                                                             ## following 
                                                                                                                                             ## a 
                                                                                                                                             ## partial 
                                                                                                                                             ## list 
                                                                                                                                             ## of 
                                                                                                                                             ## returned 
                                                                                                                                             ## items. 
                                                                                                                                             ## For 
                                                                                                                                             ## example, 
                                                                                                                                             ## if 
                                                                                                                                             ## a 
                                                                                                                                             ## request 
                                                                                                                                             ## is 
                                                                                                                                             ## made 
                                                                                                                                             ## to 
                                                                                                                                             ## return 
                                                                                                                                             ## <code>maxResults</code> 
                                                                                                                                             ## number 
                                                                                                                                             ## of 
                                                                                                                                             ## items, 
                                                                                                                                             ## <code>NextToken</code> 
                                                                                                                                             ## allows 
                                                                                                                                             ## you 
                                                                                                                                             ## to 
                                                                                                                                             ## return 
                                                                                                                                             ## more 
                                                                                                                                             ## items 
                                                                                                                                             ## in 
                                                                                                                                             ## your 
                                                                                                                                             ## list 
                                                                                                                                             ## starting 
                                                                                                                                             ## at 
                                                                                                                                             ## the 
                                                                                                                                             ## location 
                                                                                                                                             ## pointed 
                                                                                                                                             ## to 
                                                                                                                                             ## by 
                                                                                                                                             ## the 
                                                                                                                                             ## next 
                                                                                                                                             ## token.
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
  var query_402657121 = newJObject()
  add(query_402657121, "maxResults", newJInt(maxResults))
  add(query_402657121, "nextToken", newJString(nextToken))
  add(query_402657121, "MaxResults", newJString(MaxResults))
  add(query_402657121, "NextToken", newJString(NextToken))
  result = call_402657120.call(nil, query_402657121, nil, nil, nil)

var listRestoreJobs* = Call_ListRestoreJobs_402657105(name: "listRestoreJobs",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com",
    route: "/restore-jobs/", validator: validate_ListRestoreJobs_402657106,
    base: "/", makeUrl: url_ListRestoreJobs_402657107,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_402657122 = ref object of OpenApiRestCall_402656044
proc url_ListTags_402657124(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resourceArn"),
                 (kind: ConstantSegment, value: "/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTags_402657123(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of key-value pairs assigned to a target recovery point, backup plan, or backup vault.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              : An Amazon Resource Name (ARN) that uniquely identifies a resource. The format of the ARN depends on the type of resource. Valid targets for <code>ListTags</code> are recovery points, backup plans, and backup vaults.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402657125 = path.getOrDefault("resourceArn")
  valid_402657125 = validateParameter(valid_402657125, JString, required = true,
                                      default = nil)
  if valid_402657125 != nil:
    section.add "resourceArn", valid_402657125
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of items to be returned.
  ##   
                                                                                              ## nextToken: JString
                                                                                              ##            
                                                                                              ## : 
                                                                                              ## The 
                                                                                              ## next 
                                                                                              ## item 
                                                                                              ## following 
                                                                                              ## a 
                                                                                              ## partial 
                                                                                              ## list 
                                                                                              ## of 
                                                                                              ## returned 
                                                                                              ## items. 
                                                                                              ## For 
                                                                                              ## example, 
                                                                                              ## if 
                                                                                              ## a 
                                                                                              ## request 
                                                                                              ## is 
                                                                                              ## made 
                                                                                              ## to 
                                                                                              ## return 
                                                                                              ## <code>maxResults</code> 
                                                                                              ## number 
                                                                                              ## of 
                                                                                              ## items, 
                                                                                              ## <code>NextToken</code> 
                                                                                              ## allows 
                                                                                              ## you 
                                                                                              ## to 
                                                                                              ## return 
                                                                                              ## more 
                                                                                              ## items 
                                                                                              ## in 
                                                                                              ## your 
                                                                                              ## list 
                                                                                              ## starting 
                                                                                              ## at 
                                                                                              ## the 
                                                                                              ## location 
                                                                                              ## pointed 
                                                                                              ## to 
                                                                                              ## by 
                                                                                              ## the 
                                                                                              ## next 
                                                                                              ## token.
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
  var valid_402657126 = query.getOrDefault("maxResults")
  valid_402657126 = validateParameter(valid_402657126, JInt, required = false,
                                      default = nil)
  if valid_402657126 != nil:
    section.add "maxResults", valid_402657126
  var valid_402657127 = query.getOrDefault("nextToken")
  valid_402657127 = validateParameter(valid_402657127, JString,
                                      required = false, default = nil)
  if valid_402657127 != nil:
    section.add "nextToken", valid_402657127
  var valid_402657128 = query.getOrDefault("MaxResults")
  valid_402657128 = validateParameter(valid_402657128, JString,
                                      required = false, default = nil)
  if valid_402657128 != nil:
    section.add "MaxResults", valid_402657128
  var valid_402657129 = query.getOrDefault("NextToken")
  valid_402657129 = validateParameter(valid_402657129, JString,
                                      required = false, default = nil)
  if valid_402657129 != nil:
    section.add "NextToken", valid_402657129
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
  var valid_402657130 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657130 = validateParameter(valid_402657130, JString,
                                      required = false, default = nil)
  if valid_402657130 != nil:
    section.add "X-Amz-Security-Token", valid_402657130
  var valid_402657131 = header.getOrDefault("X-Amz-Signature")
  valid_402657131 = validateParameter(valid_402657131, JString,
                                      required = false, default = nil)
  if valid_402657131 != nil:
    section.add "X-Amz-Signature", valid_402657131
  var valid_402657132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657132 = validateParameter(valid_402657132, JString,
                                      required = false, default = nil)
  if valid_402657132 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657132
  var valid_402657133 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657133 = validateParameter(valid_402657133, JString,
                                      required = false, default = nil)
  if valid_402657133 != nil:
    section.add "X-Amz-Algorithm", valid_402657133
  var valid_402657134 = header.getOrDefault("X-Amz-Date")
  valid_402657134 = validateParameter(valid_402657134, JString,
                                      required = false, default = nil)
  if valid_402657134 != nil:
    section.add "X-Amz-Date", valid_402657134
  var valid_402657135 = header.getOrDefault("X-Amz-Credential")
  valid_402657135 = validateParameter(valid_402657135, JString,
                                      required = false, default = nil)
  if valid_402657135 != nil:
    section.add "X-Amz-Credential", valid_402657135
  var valid_402657136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657136 = validateParameter(valid_402657136, JString,
                                      required = false, default = nil)
  if valid_402657136 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657137: Call_ListTags_402657122; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of key-value pairs assigned to a target recovery point, backup plan, or backup vault.
                                                                                         ## 
  let valid = call_402657137.validator(path, query, header, formData, body, _)
  let scheme = call_402657137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657137.makeUrl(scheme.get, call_402657137.host, call_402657137.base,
                                   call_402657137.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657137, uri, valid, _)

proc call*(call_402657138: Call_ListTags_402657122; resourceArn: string;
           maxResults: int = 0; nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listTags
  ## Returns a list of key-value pairs assigned to a target recovery point, backup plan, or backup vault.
  ##   
                                                                                                         ## maxResults: int
                                                                                                         ##             
                                                                                                         ## : 
                                                                                                         ## The 
                                                                                                         ## maximum 
                                                                                                         ## number 
                                                                                                         ## of 
                                                                                                         ## items 
                                                                                                         ## to 
                                                                                                         ## be 
                                                                                                         ## returned.
  ##   
                                                                                                                     ## nextToken: string
                                                                                                                     ##            
                                                                                                                     ## : 
                                                                                                                     ## The 
                                                                                                                     ## next 
                                                                                                                     ## item 
                                                                                                                     ## following 
                                                                                                                     ## a 
                                                                                                                     ## partial 
                                                                                                                     ## list 
                                                                                                                     ## of 
                                                                                                                     ## returned 
                                                                                                                     ## items. 
                                                                                                                     ## For 
                                                                                                                     ## example, 
                                                                                                                     ## if 
                                                                                                                     ## a 
                                                                                                                     ## request 
                                                                                                                     ## is 
                                                                                                                     ## made 
                                                                                                                     ## to 
                                                                                                                     ## return 
                                                                                                                     ## <code>maxResults</code> 
                                                                                                                     ## number 
                                                                                                                     ## of 
                                                                                                                     ## items, 
                                                                                                                     ## <code>NextToken</code> 
                                                                                                                     ## allows 
                                                                                                                     ## you 
                                                                                                                     ## to 
                                                                                                                     ## return 
                                                                                                                     ## more 
                                                                                                                     ## items 
                                                                                                                     ## in 
                                                                                                                     ## your 
                                                                                                                     ## list 
                                                                                                                     ## starting 
                                                                                                                     ## at 
                                                                                                                     ## the 
                                                                                                                     ## location 
                                                                                                                     ## pointed 
                                                                                                                     ## to 
                                                                                                                     ## by 
                                                                                                                     ## the 
                                                                                                                     ## next 
                                                                                                                     ## token.
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
                                                                                                                                              ## resourceArn: string (required)
                                                                                                                                              ##              
                                                                                                                                              ## : 
                                                                                                                                              ## An 
                                                                                                                                              ## Amazon 
                                                                                                                                              ## Resource 
                                                                                                                                              ## Name 
                                                                                                                                              ## (ARN) 
                                                                                                                                              ## that 
                                                                                                                                              ## uniquely 
                                                                                                                                              ## identifies 
                                                                                                                                              ## a 
                                                                                                                                              ## resource. 
                                                                                                                                              ## The 
                                                                                                                                              ## format 
                                                                                                                                              ## of 
                                                                                                                                              ## the 
                                                                                                                                              ## ARN 
                                                                                                                                              ## depends 
                                                                                                                                              ## on 
                                                                                                                                              ## the 
                                                                                                                                              ## type 
                                                                                                                                              ## of 
                                                                                                                                              ## resource. 
                                                                                                                                              ## Valid 
                                                                                                                                              ## targets 
                                                                                                                                              ## for 
                                                                                                                                              ## <code>ListTags</code> 
                                                                                                                                              ## are 
                                                                                                                                              ## recovery 
                                                                                                                                              ## points, 
                                                                                                                                              ## backup 
                                                                                                                                              ## plans, 
                                                                                                                                              ## and 
                                                                                                                                              ## backup 
                                                                                                                                              ## vaults.
  var path_402657139 = newJObject()
  var query_402657140 = newJObject()
  add(query_402657140, "maxResults", newJInt(maxResults))
  add(query_402657140, "nextToken", newJString(nextToken))
  add(query_402657140, "MaxResults", newJString(MaxResults))
  add(query_402657140, "NextToken", newJString(NextToken))
  add(path_402657139, "resourceArn", newJString(resourceArn))
  result = call_402657138.call(path_402657139, query_402657140, nil, nil, nil)

var listTags* = Call_ListTags_402657122(name: "listTags",
                                        meth: HttpMethod.HttpGet,
                                        host: "backup.amazonaws.com",
                                        route: "/tags/{resourceArn}/",
                                        validator: validate_ListTags_402657123,
                                        base: "/", makeUrl: url_ListTags_402657124,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartBackupJob_402657141 = ref object of OpenApiRestCall_402656044
proc url_StartBackupJob_402657143(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartBackupJob_402657142(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Starts a job to create a one-time backup of the specified resource.
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
  var valid_402657144 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657144 = validateParameter(valid_402657144, JString,
                                      required = false, default = nil)
  if valid_402657144 != nil:
    section.add "X-Amz-Security-Token", valid_402657144
  var valid_402657145 = header.getOrDefault("X-Amz-Signature")
  valid_402657145 = validateParameter(valid_402657145, JString,
                                      required = false, default = nil)
  if valid_402657145 != nil:
    section.add "X-Amz-Signature", valid_402657145
  var valid_402657146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657146 = validateParameter(valid_402657146, JString,
                                      required = false, default = nil)
  if valid_402657146 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657146
  var valid_402657147 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657147 = validateParameter(valid_402657147, JString,
                                      required = false, default = nil)
  if valid_402657147 != nil:
    section.add "X-Amz-Algorithm", valid_402657147
  var valid_402657148 = header.getOrDefault("X-Amz-Date")
  valid_402657148 = validateParameter(valid_402657148, JString,
                                      required = false, default = nil)
  if valid_402657148 != nil:
    section.add "X-Amz-Date", valid_402657148
  var valid_402657149 = header.getOrDefault("X-Amz-Credential")
  valid_402657149 = validateParameter(valid_402657149, JString,
                                      required = false, default = nil)
  if valid_402657149 != nil:
    section.add "X-Amz-Credential", valid_402657149
  var valid_402657150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657150 = validateParameter(valid_402657150, JString,
                                      required = false, default = nil)
  if valid_402657150 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657150
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

proc call*(call_402657152: Call_StartBackupJob_402657141; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts a job to create a one-time backup of the specified resource.
                                                                                         ## 
  let valid = call_402657152.validator(path, query, header, formData, body, _)
  let scheme = call_402657152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657152.makeUrl(scheme.get, call_402657152.host, call_402657152.base,
                                   call_402657152.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657152, uri, valid, _)

proc call*(call_402657153: Call_StartBackupJob_402657141; body: JsonNode): Recallable =
  ## startBackupJob
  ## Starts a job to create a one-time backup of the specified resource.
  ##   body: JObject 
                                                                        ## (required)
  var body_402657154 = newJObject()
  if body != nil:
    body_402657154 = body
  result = call_402657153.call(nil, nil, nil, nil, body_402657154)

var startBackupJob* = Call_StartBackupJob_402657141(name: "startBackupJob",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com",
    route: "/backup-jobs", validator: validate_StartBackupJob_402657142,
    base: "/", makeUrl: url_StartBackupJob_402657143,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartCopyJob_402657155 = ref object of OpenApiRestCall_402656044
proc url_StartCopyJob_402657157(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartCopyJob_402657156(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Starts a job to create a one-time copy of the specified resource.
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
  var valid_402657158 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657158 = validateParameter(valid_402657158, JString,
                                      required = false, default = nil)
  if valid_402657158 != nil:
    section.add "X-Amz-Security-Token", valid_402657158
  var valid_402657159 = header.getOrDefault("X-Amz-Signature")
  valid_402657159 = validateParameter(valid_402657159, JString,
                                      required = false, default = nil)
  if valid_402657159 != nil:
    section.add "X-Amz-Signature", valid_402657159
  var valid_402657160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657160 = validateParameter(valid_402657160, JString,
                                      required = false, default = nil)
  if valid_402657160 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657160
  var valid_402657161 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657161 = validateParameter(valid_402657161, JString,
                                      required = false, default = nil)
  if valid_402657161 != nil:
    section.add "X-Amz-Algorithm", valid_402657161
  var valid_402657162 = header.getOrDefault("X-Amz-Date")
  valid_402657162 = validateParameter(valid_402657162, JString,
                                      required = false, default = nil)
  if valid_402657162 != nil:
    section.add "X-Amz-Date", valid_402657162
  var valid_402657163 = header.getOrDefault("X-Amz-Credential")
  valid_402657163 = validateParameter(valid_402657163, JString,
                                      required = false, default = nil)
  if valid_402657163 != nil:
    section.add "X-Amz-Credential", valid_402657163
  var valid_402657164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657164 = validateParameter(valid_402657164, JString,
                                      required = false, default = nil)
  if valid_402657164 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657164
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

proc call*(call_402657166: Call_StartCopyJob_402657155; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts a job to create a one-time copy of the specified resource.
                                                                                         ## 
  let valid = call_402657166.validator(path, query, header, formData, body, _)
  let scheme = call_402657166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657166.makeUrl(scheme.get, call_402657166.host, call_402657166.base,
                                   call_402657166.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657166, uri, valid, _)

proc call*(call_402657167: Call_StartCopyJob_402657155; body: JsonNode): Recallable =
  ## startCopyJob
  ## Starts a job to create a one-time copy of the specified resource.
  ##   body: JObject (required)
  var body_402657168 = newJObject()
  if body != nil:
    body_402657168 = body
  result = call_402657167.call(nil, nil, nil, nil, body_402657168)

var startCopyJob* = Call_StartCopyJob_402657155(name: "startCopyJob",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com", route: "/copy-jobs",
    validator: validate_StartCopyJob_402657156, base: "/",
    makeUrl: url_StartCopyJob_402657157, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartRestoreJob_402657169 = ref object of OpenApiRestCall_402656044
proc url_StartRestoreJob_402657171(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartRestoreJob_402657170(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Recovers the saved resource identified by an Amazon Resource Name (ARN). </p> <p>If the resource ARN is included in the request, then the last complete backup of that resource is recovered. If the ARN of a recovery point is supplied, then that recovery point is restored.</p>
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
  var valid_402657172 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657172 = validateParameter(valid_402657172, JString,
                                      required = false, default = nil)
  if valid_402657172 != nil:
    section.add "X-Amz-Security-Token", valid_402657172
  var valid_402657173 = header.getOrDefault("X-Amz-Signature")
  valid_402657173 = validateParameter(valid_402657173, JString,
                                      required = false, default = nil)
  if valid_402657173 != nil:
    section.add "X-Amz-Signature", valid_402657173
  var valid_402657174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657174 = validateParameter(valid_402657174, JString,
                                      required = false, default = nil)
  if valid_402657174 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657174
  var valid_402657175 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657175 = validateParameter(valid_402657175, JString,
                                      required = false, default = nil)
  if valid_402657175 != nil:
    section.add "X-Amz-Algorithm", valid_402657175
  var valid_402657176 = header.getOrDefault("X-Amz-Date")
  valid_402657176 = validateParameter(valid_402657176, JString,
                                      required = false, default = nil)
  if valid_402657176 != nil:
    section.add "X-Amz-Date", valid_402657176
  var valid_402657177 = header.getOrDefault("X-Amz-Credential")
  valid_402657177 = validateParameter(valid_402657177, JString,
                                      required = false, default = nil)
  if valid_402657177 != nil:
    section.add "X-Amz-Credential", valid_402657177
  var valid_402657178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657178 = validateParameter(valid_402657178, JString,
                                      required = false, default = nil)
  if valid_402657178 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657178
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

proc call*(call_402657180: Call_StartRestoreJob_402657169; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Recovers the saved resource identified by an Amazon Resource Name (ARN). </p> <p>If the resource ARN is included in the request, then the last complete backup of that resource is recovered. If the ARN of a recovery point is supplied, then that recovery point is restored.</p>
                                                                                         ## 
  let valid = call_402657180.validator(path, query, header, formData, body, _)
  let scheme = call_402657180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657180.makeUrl(scheme.get, call_402657180.host, call_402657180.base,
                                   call_402657180.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657180, uri, valid, _)

proc call*(call_402657181: Call_StartRestoreJob_402657169; body: JsonNode): Recallable =
  ## startRestoreJob
  ## <p>Recovers the saved resource identified by an Amazon Resource Name (ARN). </p> <p>If the resource ARN is included in the request, then the last complete backup of that resource is recovered. If the ARN of a recovery point is supplied, then that recovery point is restored.</p>
  ##   
                                                                                                                                                                                                                                                                                           ## body: JObject (required)
  var body_402657182 = newJObject()
  if body != nil:
    body_402657182 = body
  result = call_402657181.call(nil, nil, nil, nil, body_402657182)

var startRestoreJob* = Call_StartRestoreJob_402657169(name: "startRestoreJob",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com",
    route: "/restore-jobs", validator: validate_StartRestoreJob_402657170,
    base: "/", makeUrl: url_StartRestoreJob_402657171,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402657183 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402657185(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_402657184(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Assigns a set of key-value pairs to a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN).
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              : An ARN that uniquely identifies a resource. The format of the ARN depends on the type of the tagged resource.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402657186 = path.getOrDefault("resourceArn")
  valid_402657186 = validateParameter(valid_402657186, JString, required = true,
                                      default = nil)
  if valid_402657186 != nil:
    section.add "resourceArn", valid_402657186
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
  var valid_402657187 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657187 = validateParameter(valid_402657187, JString,
                                      required = false, default = nil)
  if valid_402657187 != nil:
    section.add "X-Amz-Security-Token", valid_402657187
  var valid_402657188 = header.getOrDefault("X-Amz-Signature")
  valid_402657188 = validateParameter(valid_402657188, JString,
                                      required = false, default = nil)
  if valid_402657188 != nil:
    section.add "X-Amz-Signature", valid_402657188
  var valid_402657189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657189 = validateParameter(valid_402657189, JString,
                                      required = false, default = nil)
  if valid_402657189 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657189
  var valid_402657190 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657190 = validateParameter(valid_402657190, JString,
                                      required = false, default = nil)
  if valid_402657190 != nil:
    section.add "X-Amz-Algorithm", valid_402657190
  var valid_402657191 = header.getOrDefault("X-Amz-Date")
  valid_402657191 = validateParameter(valid_402657191, JString,
                                      required = false, default = nil)
  if valid_402657191 != nil:
    section.add "X-Amz-Date", valid_402657191
  var valid_402657192 = header.getOrDefault("X-Amz-Credential")
  valid_402657192 = validateParameter(valid_402657192, JString,
                                      required = false, default = nil)
  if valid_402657192 != nil:
    section.add "X-Amz-Credential", valid_402657192
  var valid_402657193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657193 = validateParameter(valid_402657193, JString,
                                      required = false, default = nil)
  if valid_402657193 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657193
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

proc call*(call_402657195: Call_TagResource_402657183; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Assigns a set of key-value pairs to a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN).
                                                                                         ## 
  let valid = call_402657195.validator(path, query, header, formData, body, _)
  let scheme = call_402657195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657195.makeUrl(scheme.get, call_402657195.host, call_402657195.base,
                                   call_402657195.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657195, uri, valid, _)

proc call*(call_402657196: Call_TagResource_402657183; body: JsonNode;
           resourceArn: string): Recallable =
  ## tagResource
  ## Assigns a set of key-value pairs to a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN).
  ##   
                                                                                                                                    ## body: JObject (required)
  ##   
                                                                                                                                                               ## resourceArn: string (required)
                                                                                                                                                               ##              
                                                                                                                                                               ## : 
                                                                                                                                                               ## An 
                                                                                                                                                               ## ARN 
                                                                                                                                                               ## that 
                                                                                                                                                               ## uniquely 
                                                                                                                                                               ## identifies 
                                                                                                                                                               ## a 
                                                                                                                                                               ## resource. 
                                                                                                                                                               ## The 
                                                                                                                                                               ## format 
                                                                                                                                                               ## of 
                                                                                                                                                               ## the 
                                                                                                                                                               ## ARN 
                                                                                                                                                               ## depends 
                                                                                                                                                               ## on 
                                                                                                                                                               ## the 
                                                                                                                                                               ## type 
                                                                                                                                                               ## of 
                                                                                                                                                               ## the 
                                                                                                                                                               ## tagged 
                                                                                                                                                               ## resource.
  var path_402657197 = newJObject()
  var body_402657198 = newJObject()
  if body != nil:
    body_402657198 = body
  add(path_402657197, "resourceArn", newJString(resourceArn))
  result = call_402657196.call(path_402657197, nil, nil, nil, body_402657198)

var tagResource* = Call_TagResource_402657183(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "backup.amazonaws.com",
    route: "/tags/{resourceArn}", validator: validate_TagResource_402657184,
    base: "/", makeUrl: url_TagResource_402657185,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402657199 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402657201(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/untag/"),
                 (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_402657200(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes a set of key-value pairs from a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN)
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              : An ARN that uniquely identifies a resource. The format of the ARN depends on the type of the tagged resource.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402657202 = path.getOrDefault("resourceArn")
  valid_402657202 = validateParameter(valid_402657202, JString, required = true,
                                      default = nil)
  if valid_402657202 != nil:
    section.add "resourceArn", valid_402657202
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
  var valid_402657203 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657203 = validateParameter(valid_402657203, JString,
                                      required = false, default = nil)
  if valid_402657203 != nil:
    section.add "X-Amz-Security-Token", valid_402657203
  var valid_402657204 = header.getOrDefault("X-Amz-Signature")
  valid_402657204 = validateParameter(valid_402657204, JString,
                                      required = false, default = nil)
  if valid_402657204 != nil:
    section.add "X-Amz-Signature", valid_402657204
  var valid_402657205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657205 = validateParameter(valid_402657205, JString,
                                      required = false, default = nil)
  if valid_402657205 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657205
  var valid_402657206 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657206 = validateParameter(valid_402657206, JString,
                                      required = false, default = nil)
  if valid_402657206 != nil:
    section.add "X-Amz-Algorithm", valid_402657206
  var valid_402657207 = header.getOrDefault("X-Amz-Date")
  valid_402657207 = validateParameter(valid_402657207, JString,
                                      required = false, default = nil)
  if valid_402657207 != nil:
    section.add "X-Amz-Date", valid_402657207
  var valid_402657208 = header.getOrDefault("X-Amz-Credential")
  valid_402657208 = validateParameter(valid_402657208, JString,
                                      required = false, default = nil)
  if valid_402657208 != nil:
    section.add "X-Amz-Credential", valid_402657208
  var valid_402657209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657209 = validateParameter(valid_402657209, JString,
                                      required = false, default = nil)
  if valid_402657209 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657209
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

proc call*(call_402657211: Call_UntagResource_402657199; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a set of key-value pairs from a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN)
                                                                                         ## 
  let valid = call_402657211.validator(path, query, header, formData, body, _)
  let scheme = call_402657211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657211.makeUrl(scheme.get, call_402657211.host, call_402657211.base,
                                   call_402657211.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657211, uri, valid, _)

proc call*(call_402657212: Call_UntagResource_402657199; body: JsonNode;
           resourceArn: string): Recallable =
  ## untagResource
  ## Removes a set of key-value pairs from a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN)
  ##   
                                                                                                                                     ## body: JObject (required)
  ##   
                                                                                                                                                                ## resourceArn: string (required)
                                                                                                                                                                ##              
                                                                                                                                                                ## : 
                                                                                                                                                                ## An 
                                                                                                                                                                ## ARN 
                                                                                                                                                                ## that 
                                                                                                                                                                ## uniquely 
                                                                                                                                                                ## identifies 
                                                                                                                                                                ## a 
                                                                                                                                                                ## resource. 
                                                                                                                                                                ## The 
                                                                                                                                                                ## format 
                                                                                                                                                                ## of 
                                                                                                                                                                ## the 
                                                                                                                                                                ## ARN 
                                                                                                                                                                ## depends 
                                                                                                                                                                ## on 
                                                                                                                                                                ## the 
                                                                                                                                                                ## type 
                                                                                                                                                                ## of 
                                                                                                                                                                ## the 
                                                                                                                                                                ## tagged 
                                                                                                                                                                ## resource.
  var path_402657213 = newJObject()
  var body_402657214 = newJObject()
  if body != nil:
    body_402657214 = body
  add(path_402657213, "resourceArn", newJString(resourceArn))
  result = call_402657212.call(path_402657213, nil, nil, nil, body_402657214)

var untagResource* = Call_UntagResource_402657199(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "backup.amazonaws.com",
    route: "/untag/{resourceArn}", validator: validate_UntagResource_402657200,
    base: "/", makeUrl: url_UntagResource_402657201,
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