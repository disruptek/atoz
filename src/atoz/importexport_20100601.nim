
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Import/Export
## version: 2010-06-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Import/Export Service</fullname> AWS Import/Export accelerates transferring large amounts of data between the AWS cloud and portable storage devices that you mail to us. AWS Import/Export transfers data directly onto and off of your storage devices using Amazon's high-speed internal network and bypassing the Internet. For large data sets, AWS Import/Export is often faster than Internet transfer and more cost effective than upgrading your connectivity.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/importexport/
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

  OpenApiRestCall_402656029 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656029](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656029): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Https: {"cn-northwest-1": "importexport.cn-northwest-1.amazonaws.com.cn", "cn-north-1": "importexport.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Http: {
      "cn-northwest-1": "importexport.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "importexport.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "importexport"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_PostCancelJob_402656475 = ref object of OpenApiRestCall_402656029
proc url_PostCancelJob_402656477(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCancelJob_402656476(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   Timestamp: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  ##   Action: JString (required)
  ##   SignatureMethod: JString (required)
  ##   SignatureVersion: JString (required)
  ##   Operation: JString (required)
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `Signature` field"
  var valid_402656478 = query.getOrDefault("Signature")
  valid_402656478 = validateParameter(valid_402656478, JString, required = true,
                                      default = nil)
  if valid_402656478 != nil:
    section.add "Signature", valid_402656478
  var valid_402656479 = query.getOrDefault("Timestamp")
  valid_402656479 = validateParameter(valid_402656479, JString, required = true,
                                      default = nil)
  if valid_402656479 != nil:
    section.add "Timestamp", valid_402656479
  var valid_402656480 = query.getOrDefault("AWSAccessKeyId")
  valid_402656480 = validateParameter(valid_402656480, JString, required = true,
                                      default = nil)
  if valid_402656480 != nil:
    section.add "AWSAccessKeyId", valid_402656480
  var valid_402656481 = query.getOrDefault("Version")
  valid_402656481 = validateParameter(valid_402656481, JString, required = true,
                                      default = newJString("2010-06-01"))
  if valid_402656481 != nil:
    section.add "Version", valid_402656481
  var valid_402656482 = query.getOrDefault("Action")
  valid_402656482 = validateParameter(valid_402656482, JString, required = true,
                                      default = newJString("CancelJob"))
  if valid_402656482 != nil:
    section.add "Action", valid_402656482
  var valid_402656483 = query.getOrDefault("SignatureMethod")
  valid_402656483 = validateParameter(valid_402656483, JString, required = true,
                                      default = nil)
  if valid_402656483 != nil:
    section.add "SignatureMethod", valid_402656483
  var valid_402656484 = query.getOrDefault("SignatureVersion")
  valid_402656484 = validateParameter(valid_402656484, JString, required = true,
                                      default = nil)
  if valid_402656484 != nil:
    section.add "SignatureVersion", valid_402656484
  var valid_402656485 = query.getOrDefault("Operation")
  valid_402656485 = validateParameter(valid_402656485, JString, required = true,
                                      default = newJString("CancelJob"))
  if valid_402656485 != nil:
    section.add "Operation", valid_402656485
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   APIVersion: JString
                                     ##             : Specifies the version of the client tool.
  ##   
                                                                                               ## JobId: JString (required)
                                                                                               ##        
                                                                                               ## : 
                                                                                               ## A 
                                                                                               ## unique 
                                                                                               ## identifier 
                                                                                               ## which 
                                                                                               ## refers 
                                                                                               ## to 
                                                                                               ## a 
                                                                                               ## particular 
                                                                                               ## job.
  section = newJObject()
  var valid_402656486 = formData.getOrDefault("APIVersion")
  valid_402656486 = validateParameter(valid_402656486, JString,
                                      required = false, default = nil)
  if valid_402656486 != nil:
    section.add "APIVersion", valid_402656486
  assert formData != nil,
         "formData argument is necessary due to required `JobId` field"
  var valid_402656487 = formData.getOrDefault("JobId")
  valid_402656487 = validateParameter(valid_402656487, JString, required = true,
                                      default = nil)
  if valid_402656487 != nil:
    section.add "JobId", valid_402656487
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656488: Call_PostCancelJob_402656475; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
                                                                                         ## 
  let valid = call_402656488.validator(path, query, header, formData, body, _)
  let scheme = call_402656488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656488.makeUrl(scheme.get, call_402656488.host, call_402656488.base,
                                   call_402656488.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656488, uri, valid, _)

proc call*(call_402656489: Call_PostCancelJob_402656475; Signature: string;
           Timestamp: string; AWSAccessKeyId: string; JobId: string;
           SignatureMethod: string; SignatureVersion: string;
           Version: string = "2010-06-01"; APIVersion: string = "";
           Action: string = "CancelJob"; Operation: string = "CancelJob"): Recallable =
  ## postCancelJob
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ##   
                                                                                                                                                 ## Signature: string (required)
  ##   
                                                                                                                                                                                ## Timestamp: string (required)
  ##   
                                                                                                                                                                                                               ## AWSAccessKeyId: string (required)
  ##   
                                                                                                                                                                                                                                                   ## Version: string (required)
  ##   
                                                                                                                                                                                                                                                                                ## APIVersion: string
                                                                                                                                                                                                                                                                                ##             
                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                ## Specifies 
                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                ## version 
                                                                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                ## client 
                                                                                                                                                                                                                                                                                ## tool.
  ##   
                                                                                                                                                                                                                                                                                        ## Action: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                    ## JobId: string (required)
                                                                                                                                                                                                                                                                                                                    ##        
                                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                                    ## A 
                                                                                                                                                                                                                                                                                                                    ## unique 
                                                                                                                                                                                                                                                                                                                    ## identifier 
                                                                                                                                                                                                                                                                                                                    ## which 
                                                                                                                                                                                                                                                                                                                    ## refers 
                                                                                                                                                                                                                                                                                                                    ## to 
                                                                                                                                                                                                                                                                                                                    ## a 
                                                                                                                                                                                                                                                                                                                    ## particular 
                                                                                                                                                                                                                                                                                                                    ## job.
  ##   
                                                                                                                                                                                                                                                                                                                           ## SignatureMethod: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                ## SignatureVersion: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                      ## Operation: string (required)
  var query_402656490 = newJObject()
  var formData_402656491 = newJObject()
  add(query_402656490, "Signature", newJString(Signature))
  add(query_402656490, "Timestamp", newJString(Timestamp))
  add(query_402656490, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_402656490, "Version", newJString(Version))
  add(formData_402656491, "APIVersion", newJString(APIVersion))
  add(query_402656490, "Action", newJString(Action))
  add(formData_402656491, "JobId", newJString(JobId))
  add(query_402656490, "SignatureMethod", newJString(SignatureMethod))
  add(query_402656490, "SignatureVersion", newJString(SignatureVersion))
  add(query_402656490, "Operation", newJString(Operation))
  result = call_402656489.call(nil, query_402656490, nil, formData_402656491,
                               nil)

var postCancelJob* = Call_PostCancelJob_402656475(name: "postCancelJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=CancelJob&Action=CancelJob",
    validator: validate_PostCancelJob_402656476, base: "/",
    makeUrl: url_PostCancelJob_402656477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCancelJob_402656282 = ref object of OpenApiRestCall_402656029
proc url_GetCancelJob_402656284(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCancelJob_402656283(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   APIVersion: JString
                                  ##             : Specifies the version of the client tool.
  ##   
                                                                                            ## Signature: JString (required)
  ##   
                                                                                                                            ## Timestamp: JString (required)
  ##   
                                                                                                                                                            ## AWSAccessKeyId: JString (required)
  ##   
                                                                                                                                                                                                 ## JobId: JString (required)
                                                                                                                                                                                                 ##        
                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                 ## A 
                                                                                                                                                                                                 ## unique 
                                                                                                                                                                                                 ## identifier 
                                                                                                                                                                                                 ## which 
                                                                                                                                                                                                 ## refers 
                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                 ## a 
                                                                                                                                                                                                 ## particular 
                                                                                                                                                                                                 ## job.
  ##   
                                                                                                                                                                                                        ## Version: JString (required)
  ##   
                                                                                                                                                                                                                                      ## Action: JString (required)
  ##   
                                                                                                                                                                                                                                                                   ## SignatureMethod: JString (required)
  ##   
                                                                                                                                                                                                                                                                                                         ## SignatureVersion: JString (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                ## Operation: JString (required)
  section = newJObject()
  var valid_402656363 = query.getOrDefault("APIVersion")
  valid_402656363 = validateParameter(valid_402656363, JString,
                                      required = false, default = nil)
  if valid_402656363 != nil:
    section.add "APIVersion", valid_402656363
  assert query != nil,
         "query argument is necessary due to required `Signature` field"
  var valid_402656364 = query.getOrDefault("Signature")
  valid_402656364 = validateParameter(valid_402656364, JString, required = true,
                                      default = nil)
  if valid_402656364 != nil:
    section.add "Signature", valid_402656364
  var valid_402656365 = query.getOrDefault("Timestamp")
  valid_402656365 = validateParameter(valid_402656365, JString, required = true,
                                      default = nil)
  if valid_402656365 != nil:
    section.add "Timestamp", valid_402656365
  var valid_402656366 = query.getOrDefault("AWSAccessKeyId")
  valid_402656366 = validateParameter(valid_402656366, JString, required = true,
                                      default = nil)
  if valid_402656366 != nil:
    section.add "AWSAccessKeyId", valid_402656366
  var valid_402656367 = query.getOrDefault("JobId")
  valid_402656367 = validateParameter(valid_402656367, JString, required = true,
                                      default = nil)
  if valid_402656367 != nil:
    section.add "JobId", valid_402656367
  var valid_402656380 = query.getOrDefault("Version")
  valid_402656380 = validateParameter(valid_402656380, JString, required = true,
                                      default = newJString("2010-06-01"))
  if valid_402656380 != nil:
    section.add "Version", valid_402656380
  var valid_402656381 = query.getOrDefault("Action")
  valid_402656381 = validateParameter(valid_402656381, JString, required = true,
                                      default = newJString("CancelJob"))
  if valid_402656381 != nil:
    section.add "Action", valid_402656381
  var valid_402656382 = query.getOrDefault("SignatureMethod")
  valid_402656382 = validateParameter(valid_402656382, JString, required = true,
                                      default = nil)
  if valid_402656382 != nil:
    section.add "SignatureMethod", valid_402656382
  var valid_402656383 = query.getOrDefault("SignatureVersion")
  valid_402656383 = validateParameter(valid_402656383, JString, required = true,
                                      default = nil)
  if valid_402656383 != nil:
    section.add "SignatureVersion", valid_402656383
  var valid_402656384 = query.getOrDefault("Operation")
  valid_402656384 = validateParameter(valid_402656384, JString, required = true,
                                      default = newJString("CancelJob"))
  if valid_402656384 != nil:
    section.add "Operation", valid_402656384
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656398: Call_GetCancelJob_402656282; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
                                                                                         ## 
  let valid = call_402656398.validator(path, query, header, formData, body, _)
  let scheme = call_402656398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656398.makeUrl(scheme.get, call_402656398.host, call_402656398.base,
                                   call_402656398.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656398, uri, valid, _)

proc call*(call_402656447: Call_GetCancelJob_402656282; Signature: string;
           Timestamp: string; AWSAccessKeyId: string; JobId: string;
           SignatureMethod: string; SignatureVersion: string;
           APIVersion: string = ""; Version: string = "2010-06-01";
           Action: string = "CancelJob"; Operation: string = "CancelJob"): Recallable =
  ## getCancelJob
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ##   
                                                                                                                                                 ## APIVersion: string
                                                                                                                                                 ##             
                                                                                                                                                 ## : 
                                                                                                                                                 ## Specifies 
                                                                                                                                                 ## the 
                                                                                                                                                 ## version 
                                                                                                                                                 ## of 
                                                                                                                                                 ## the 
                                                                                                                                                 ## client 
                                                                                                                                                 ## tool.
  ##   
                                                                                                                                                         ## Signature: string (required)
  ##   
                                                                                                                                                                                        ## Timestamp: string (required)
  ##   
                                                                                                                                                                                                                       ## AWSAccessKeyId: string (required)
  ##   
                                                                                                                                                                                                                                                           ## JobId: string (required)
                                                                                                                                                                                                                                                           ##        
                                                                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                                                                           ## A 
                                                                                                                                                                                                                                                           ## unique 
                                                                                                                                                                                                                                                           ## identifier 
                                                                                                                                                                                                                                                           ## which 
                                                                                                                                                                                                                                                           ## refers 
                                                                                                                                                                                                                                                           ## to 
                                                                                                                                                                                                                                                           ## a 
                                                                                                                                                                                                                                                           ## particular 
                                                                                                                                                                                                                                                           ## job.
  ##   
                                                                                                                                                                                                                                                                  ## Version: string (required)
  ##   
                                                                                                                                                                                                                                                                                               ## Action: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                           ## SignatureMethod: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                ## SignatureVersion: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                      ## Operation: string (required)
  var query_402656448 = newJObject()
  add(query_402656448, "APIVersion", newJString(APIVersion))
  add(query_402656448, "Signature", newJString(Signature))
  add(query_402656448, "Timestamp", newJString(Timestamp))
  add(query_402656448, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_402656448, "JobId", newJString(JobId))
  add(query_402656448, "Version", newJString(Version))
  add(query_402656448, "Action", newJString(Action))
  add(query_402656448, "SignatureMethod", newJString(SignatureMethod))
  add(query_402656448, "SignatureVersion", newJString(SignatureVersion))
  add(query_402656448, "Operation", newJString(Operation))
  result = call_402656447.call(nil, query_402656448, nil, nil, nil)

var getCancelJob* = Call_GetCancelJob_402656282(name: "getCancelJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=CancelJob&Action=CancelJob",
    validator: validate_GetCancelJob_402656283, base: "/",
    makeUrl: url_GetCancelJob_402656284, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateJob_402656511 = ref object of OpenApiRestCall_402656029
proc url_PostCreateJob_402656513(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateJob_402656512(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   Timestamp: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  ##   Action: JString (required)
  ##   SignatureMethod: JString (required)
  ##   SignatureVersion: JString (required)
  ##   Operation: JString (required)
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `Signature` field"
  var valid_402656514 = query.getOrDefault("Signature")
  valid_402656514 = validateParameter(valid_402656514, JString, required = true,
                                      default = nil)
  if valid_402656514 != nil:
    section.add "Signature", valid_402656514
  var valid_402656515 = query.getOrDefault("Timestamp")
  valid_402656515 = validateParameter(valid_402656515, JString, required = true,
                                      default = nil)
  if valid_402656515 != nil:
    section.add "Timestamp", valid_402656515
  var valid_402656516 = query.getOrDefault("AWSAccessKeyId")
  valid_402656516 = validateParameter(valid_402656516, JString, required = true,
                                      default = nil)
  if valid_402656516 != nil:
    section.add "AWSAccessKeyId", valid_402656516
  var valid_402656517 = query.getOrDefault("Version")
  valid_402656517 = validateParameter(valid_402656517, JString, required = true,
                                      default = newJString("2010-06-01"))
  if valid_402656517 != nil:
    section.add "Version", valid_402656517
  var valid_402656518 = query.getOrDefault("Action")
  valid_402656518 = validateParameter(valid_402656518, JString, required = true,
                                      default = newJString("CreateJob"))
  if valid_402656518 != nil:
    section.add "Action", valid_402656518
  var valid_402656519 = query.getOrDefault("SignatureMethod")
  valid_402656519 = validateParameter(valid_402656519, JString, required = true,
                                      default = nil)
  if valid_402656519 != nil:
    section.add "SignatureMethod", valid_402656519
  var valid_402656520 = query.getOrDefault("SignatureVersion")
  valid_402656520 = validateParameter(valid_402656520, JString, required = true,
                                      default = nil)
  if valid_402656520 != nil:
    section.add "SignatureVersion", valid_402656520
  var valid_402656521 = query.getOrDefault("Operation")
  valid_402656521 = validateParameter(valid_402656521, JString, required = true,
                                      default = newJString("CreateJob"))
  if valid_402656521 != nil:
    section.add "Operation", valid_402656521
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   JobType: JString (required)
                                     ##          : Specifies whether the job to initiate is an import or export job.
  ##   
                                                                                                                    ## ValidateOnly: JBool (required)
                                                                                                                    ##               
                                                                                                                    ## : 
                                                                                                                    ## Validate 
                                                                                                                    ## the 
                                                                                                                    ## manifest 
                                                                                                                    ## and 
                                                                                                                    ## parameter 
                                                                                                                    ## values 
                                                                                                                    ## in 
                                                                                                                    ## the 
                                                                                                                    ## request 
                                                                                                                    ## but 
                                                                                                                    ## do 
                                                                                                                    ## not 
                                                                                                                    ## actually 
                                                                                                                    ## create 
                                                                                                                    ## a 
                                                                                                                    ## job.
  ##   
                                                                                                                           ## Manifest: JString (required)
                                                                                                                           ##           
                                                                                                                           ## : 
                                                                                                                           ## The 
                                                                                                                           ## UTF-8 
                                                                                                                           ## encoded 
                                                                                                                           ## text 
                                                                                                                           ## of 
                                                                                                                           ## the 
                                                                                                                           ## manifest 
                                                                                                                           ## file.
  ##   
                                                                                                                                   ## APIVersion: JString
                                                                                                                                   ##             
                                                                                                                                   ## : 
                                                                                                                                   ## Specifies 
                                                                                                                                   ## the 
                                                                                                                                   ## version 
                                                                                                                                   ## of 
                                                                                                                                   ## the 
                                                                                                                                   ## client 
                                                                                                                                   ## tool.
  ##   
                                                                                                                                           ## ManifestAddendum: JString
                                                                                                                                           ##                   
                                                                                                                                           ## : 
                                                                                                                                           ## For 
                                                                                                                                           ## internal 
                                                                                                                                           ## use 
                                                                                                                                           ## only.
  section = newJObject()
  var valid_402656522 = formData.getOrDefault("JobType")
  valid_402656522 = validateParameter(valid_402656522, JString, required = true,
                                      default = newJString("Import"))
  if valid_402656522 != nil:
    section.add "JobType", valid_402656522
  var valid_402656523 = formData.getOrDefault("ValidateOnly")
  valid_402656523 = validateParameter(valid_402656523, JBool, required = true,
                                      default = nil)
  if valid_402656523 != nil:
    section.add "ValidateOnly", valid_402656523
  var valid_402656524 = formData.getOrDefault("Manifest")
  valid_402656524 = validateParameter(valid_402656524, JString, required = true,
                                      default = nil)
  if valid_402656524 != nil:
    section.add "Manifest", valid_402656524
  var valid_402656525 = formData.getOrDefault("APIVersion")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "APIVersion", valid_402656525
  var valid_402656526 = formData.getOrDefault("ManifestAddendum")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "ManifestAddendum", valid_402656526
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656527: Call_PostCreateJob_402656511; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
                                                                                         ## 
  let valid = call_402656527.validator(path, query, header, formData, body, _)
  let scheme = call_402656527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656527.makeUrl(scheme.get, call_402656527.host, call_402656527.base,
                                   call_402656527.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656527, uri, valid, _)

proc call*(call_402656528: Call_PostCreateJob_402656511; Signature: string;
           Timestamp: string; ValidateOnly: bool; AWSAccessKeyId: string;
           Manifest: string; SignatureMethod: string; SignatureVersion: string;
           JobType: string = "Import"; Version: string = "2010-06-01";
           APIVersion: string = ""; Action: string = "CreateJob";
           Operation: string = "CreateJob"; ManifestAddendum: string = ""): Recallable =
  ## postCreateJob
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                        ## JobType: string (required)
                                                                                                                                                                                                                                                                                                                                                                                        ##          
                                                                                                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                                                                                                        ## Specifies 
                                                                                                                                                                                                                                                                                                                                                                                        ## whether 
                                                                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                                                                        ## job 
                                                                                                                                                                                                                                                                                                                                                                                        ## to 
                                                                                                                                                                                                                                                                                                                                                                                        ## initiate 
                                                                                                                                                                                                                                                                                                                                                                                        ## is 
                                                                                                                                                                                                                                                                                                                                                                                        ## an 
                                                                                                                                                                                                                                                                                                                                                                                        ## import 
                                                                                                                                                                                                                                                                                                                                                                                        ## or 
                                                                                                                                                                                                                                                                                                                                                                                        ## export 
                                                                                                                                                                                                                                                                                                                                                                                        ## job.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                               ## Signature: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                              ## Timestamp: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## ValidateOnly: bool (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ##               
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## Validate 
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## manifest 
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## parameter 
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## values 
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## request 
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## but 
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## do 
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## not 
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## actually 
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## create 
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## job.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## AWSAccessKeyId: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## Manifest: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ##           
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## UTF-8 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## encoded 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## text 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## manifest 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## file.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## Version: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## APIVersion: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## Specifies 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## version 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## client 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## tool.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## Action: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## SignatureMethod: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## SignatureVersion: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## Operation: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## ManifestAddendum: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ##                   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## For 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## internal 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## use 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## only.
  var query_402656529 = newJObject()
  var formData_402656530 = newJObject()
  add(formData_402656530, "JobType", newJString(JobType))
  add(query_402656529, "Signature", newJString(Signature))
  add(query_402656529, "Timestamp", newJString(Timestamp))
  add(formData_402656530, "ValidateOnly", newJBool(ValidateOnly))
  add(query_402656529, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_402656530, "Manifest", newJString(Manifest))
  add(query_402656529, "Version", newJString(Version))
  add(formData_402656530, "APIVersion", newJString(APIVersion))
  add(query_402656529, "Action", newJString(Action))
  add(query_402656529, "SignatureMethod", newJString(SignatureMethod))
  add(query_402656529, "SignatureVersion", newJString(SignatureVersion))
  add(query_402656529, "Operation", newJString(Operation))
  add(formData_402656530, "ManifestAddendum", newJString(ManifestAddendum))
  result = call_402656528.call(nil, query_402656529, nil, formData_402656530,
                               nil)

var postCreateJob* = Call_PostCreateJob_402656511(name: "postCreateJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=CreateJob&Action=CreateJob",
    validator: validate_PostCreateJob_402656512, base: "/",
    makeUrl: url_PostCreateJob_402656513, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateJob_402656492 = ref object of OpenApiRestCall_402656029
proc url_GetCreateJob_402656494(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateJob_402656493(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   APIVersion: JString
                                  ##             : Specifies the version of the client tool.
  ##   
                                                                                            ## Signature: JString (required)
  ##   
                                                                                                                            ## Timestamp: JString (required)
  ##   
                                                                                                                                                            ## ValidateOnly: JBool (required)
                                                                                                                                                            ##               
                                                                                                                                                            ## : 
                                                                                                                                                            ## Validate 
                                                                                                                                                            ## the 
                                                                                                                                                            ## manifest 
                                                                                                                                                            ## and 
                                                                                                                                                            ## parameter 
                                                                                                                                                            ## values 
                                                                                                                                                            ## in 
                                                                                                                                                            ## the 
                                                                                                                                                            ## request 
                                                                                                                                                            ## but 
                                                                                                                                                            ## do 
                                                                                                                                                            ## not 
                                                                                                                                                            ## actually 
                                                                                                                                                            ## create 
                                                                                                                                                            ## a 
                                                                                                                                                            ## job.
  ##   
                                                                                                                                                                   ## AWSAccessKeyId: JString (required)
  ##   
                                                                                                                                                                                                        ## Manifest: JString (required)
                                                                                                                                                                                                        ##           
                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                        ## The 
                                                                                                                                                                                                        ## UTF-8 
                                                                                                                                                                                                        ## encoded 
                                                                                                                                                                                                        ## text 
                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                        ## manifest 
                                                                                                                                                                                                        ## file.
  ##   
                                                                                                                                                                                                                ## Version: JString (required)
  ##   
                                                                                                                                                                                                                                              ## ManifestAddendum: JString
                                                                                                                                                                                                                                              ##                   
                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                              ## For 
                                                                                                                                                                                                                                              ## internal 
                                                                                                                                                                                                                                              ## use 
                                                                                                                                                                                                                                              ## only.
  ##   
                                                                                                                                                                                                                                                      ## Action: JString (required)
  ##   
                                                                                                                                                                                                                                                                                   ## JobType: JString (required)
                                                                                                                                                                                                                                                                                   ##          
                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                   ## Specifies 
                                                                                                                                                                                                                                                                                   ## whether 
                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                   ## job 
                                                                                                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                                                                                                   ## initiate 
                                                                                                                                                                                                                                                                                   ## is 
                                                                                                                                                                                                                                                                                   ## an 
                                                                                                                                                                                                                                                                                   ## import 
                                                                                                                                                                                                                                                                                   ## or 
                                                                                                                                                                                                                                                                                   ## export 
                                                                                                                                                                                                                                                                                   ## job.
  ##   
                                                                                                                                                                                                                                                                                          ## SignatureMethod: JString (required)
  ##   
                                                                                                                                                                                                                                                                                                                                ## SignatureVersion: JString (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                       ## Operation: JString (required)
  section = newJObject()
  var valid_402656495 = query.getOrDefault("APIVersion")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "APIVersion", valid_402656495
  assert query != nil,
         "query argument is necessary due to required `Signature` field"
  var valid_402656496 = query.getOrDefault("Signature")
  valid_402656496 = validateParameter(valid_402656496, JString, required = true,
                                      default = nil)
  if valid_402656496 != nil:
    section.add "Signature", valid_402656496
  var valid_402656497 = query.getOrDefault("Timestamp")
  valid_402656497 = validateParameter(valid_402656497, JString, required = true,
                                      default = nil)
  if valid_402656497 != nil:
    section.add "Timestamp", valid_402656497
  var valid_402656498 = query.getOrDefault("ValidateOnly")
  valid_402656498 = validateParameter(valid_402656498, JBool, required = true,
                                      default = nil)
  if valid_402656498 != nil:
    section.add "ValidateOnly", valid_402656498
  var valid_402656499 = query.getOrDefault("AWSAccessKeyId")
  valid_402656499 = validateParameter(valid_402656499, JString, required = true,
                                      default = nil)
  if valid_402656499 != nil:
    section.add "AWSAccessKeyId", valid_402656499
  var valid_402656500 = query.getOrDefault("Manifest")
  valid_402656500 = validateParameter(valid_402656500, JString, required = true,
                                      default = nil)
  if valid_402656500 != nil:
    section.add "Manifest", valid_402656500
  var valid_402656501 = query.getOrDefault("Version")
  valid_402656501 = validateParameter(valid_402656501, JString, required = true,
                                      default = newJString("2010-06-01"))
  if valid_402656501 != nil:
    section.add "Version", valid_402656501
  var valid_402656502 = query.getOrDefault("ManifestAddendum")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "ManifestAddendum", valid_402656502
  var valid_402656503 = query.getOrDefault("Action")
  valid_402656503 = validateParameter(valid_402656503, JString, required = true,
                                      default = newJString("CreateJob"))
  if valid_402656503 != nil:
    section.add "Action", valid_402656503
  var valid_402656504 = query.getOrDefault("JobType")
  valid_402656504 = validateParameter(valid_402656504, JString, required = true,
                                      default = newJString("Import"))
  if valid_402656504 != nil:
    section.add "JobType", valid_402656504
  var valid_402656505 = query.getOrDefault("SignatureMethod")
  valid_402656505 = validateParameter(valid_402656505, JString, required = true,
                                      default = nil)
  if valid_402656505 != nil:
    section.add "SignatureMethod", valid_402656505
  var valid_402656506 = query.getOrDefault("SignatureVersion")
  valid_402656506 = validateParameter(valid_402656506, JString, required = true,
                                      default = nil)
  if valid_402656506 != nil:
    section.add "SignatureVersion", valid_402656506
  var valid_402656507 = query.getOrDefault("Operation")
  valid_402656507 = validateParameter(valid_402656507, JString, required = true,
                                      default = newJString("CreateJob"))
  if valid_402656507 != nil:
    section.add "Operation", valid_402656507
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656508: Call_GetCreateJob_402656492; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
                                                                                         ## 
  let valid = call_402656508.validator(path, query, header, formData, body, _)
  let scheme = call_402656508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656508.makeUrl(scheme.get, call_402656508.host, call_402656508.base,
                                   call_402656508.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656508, uri, valid, _)

proc call*(call_402656509: Call_GetCreateJob_402656492; Signature: string;
           Timestamp: string; ValidateOnly: bool; AWSAccessKeyId: string;
           Manifest: string; SignatureMethod: string; SignatureVersion: string;
           APIVersion: string = ""; Version: string = "2010-06-01";
           ManifestAddendum: string = ""; Action: string = "CreateJob";
           JobType: string = "Import"; Operation: string = "CreateJob"): Recallable =
  ## getCreateJob
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                        ## APIVersion: string
                                                                                                                                                                                                                                                                                                                                                                                        ##             
                                                                                                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                                                                                                        ## Specifies 
                                                                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                                                                        ## version 
                                                                                                                                                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                                                                        ## client 
                                                                                                                                                                                                                                                                                                                                                                                        ## tool.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                ## Signature: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                               ## Timestamp: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## ValidateOnly: bool (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ##               
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## Validate 
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## manifest 
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## parameter 
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## values 
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## request 
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## but 
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## do 
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## not 
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## actually 
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## create 
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## job.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## AWSAccessKeyId: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## Manifest: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ##           
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## UTF-8 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## encoded 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## text 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## manifest 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## file.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## Version: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## ManifestAddendum: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ##                   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## For 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## internal 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## use 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## only.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## Action: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## JobType: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ##          
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## Specifies 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## whether 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## job 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## initiate 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## an 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## import 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## or 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## export 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## job.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## SignatureMethod: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## SignatureVersion: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## Operation: string (required)
  var query_402656510 = newJObject()
  add(query_402656510, "APIVersion", newJString(APIVersion))
  add(query_402656510, "Signature", newJString(Signature))
  add(query_402656510, "Timestamp", newJString(Timestamp))
  add(query_402656510, "ValidateOnly", newJBool(ValidateOnly))
  add(query_402656510, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_402656510, "Manifest", newJString(Manifest))
  add(query_402656510, "Version", newJString(Version))
  add(query_402656510, "ManifestAddendum", newJString(ManifestAddendum))
  add(query_402656510, "Action", newJString(Action))
  add(query_402656510, "JobType", newJString(JobType))
  add(query_402656510, "SignatureMethod", newJString(SignatureMethod))
  add(query_402656510, "SignatureVersion", newJString(SignatureVersion))
  add(query_402656510, "Operation", newJString(Operation))
  result = call_402656509.call(nil, query_402656510, nil, nil, nil)

var getCreateJob* = Call_GetCreateJob_402656492(name: "getCreateJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=CreateJob&Action=CreateJob",
    validator: validate_GetCreateJob_402656493, base: "/",
    makeUrl: url_GetCreateJob_402656494, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetShippingLabel_402656557 = ref object of OpenApiRestCall_402656029
proc url_PostGetShippingLabel_402656559(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetShippingLabel_402656558(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   Timestamp: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  ##   Action: JString (required)
  ##   SignatureMethod: JString (required)
  ##   SignatureVersion: JString (required)
  ##   Operation: JString (required)
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `Signature` field"
  var valid_402656560 = query.getOrDefault("Signature")
  valid_402656560 = validateParameter(valid_402656560, JString, required = true,
                                      default = nil)
  if valid_402656560 != nil:
    section.add "Signature", valid_402656560
  var valid_402656561 = query.getOrDefault("Timestamp")
  valid_402656561 = validateParameter(valid_402656561, JString, required = true,
                                      default = nil)
  if valid_402656561 != nil:
    section.add "Timestamp", valid_402656561
  var valid_402656562 = query.getOrDefault("AWSAccessKeyId")
  valid_402656562 = validateParameter(valid_402656562, JString, required = true,
                                      default = nil)
  if valid_402656562 != nil:
    section.add "AWSAccessKeyId", valid_402656562
  var valid_402656563 = query.getOrDefault("Version")
  valid_402656563 = validateParameter(valid_402656563, JString, required = true,
                                      default = newJString("2010-06-01"))
  if valid_402656563 != nil:
    section.add "Version", valid_402656563
  var valid_402656564 = query.getOrDefault("Action")
  valid_402656564 = validateParameter(valid_402656564, JString, required = true,
                                      default = newJString("GetShippingLabel"))
  if valid_402656564 != nil:
    section.add "Action", valid_402656564
  var valid_402656565 = query.getOrDefault("SignatureMethod")
  valid_402656565 = validateParameter(valid_402656565, JString, required = true,
                                      default = nil)
  if valid_402656565 != nil:
    section.add "SignatureMethod", valid_402656565
  var valid_402656566 = query.getOrDefault("SignatureVersion")
  valid_402656566 = validateParameter(valid_402656566, JString, required = true,
                                      default = nil)
  if valid_402656566 != nil:
    section.add "SignatureVersion", valid_402656566
  var valid_402656567 = query.getOrDefault("Operation")
  valid_402656567 = validateParameter(valid_402656567, JString, required = true,
                                      default = newJString("GetShippingLabel"))
  if valid_402656567 != nil:
    section.add "Operation", valid_402656567
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   street3: JString
                                     ##          : Specifies the optional third part of the street address for the return address, for example c/o Jane Doe.
  ##   
                                                                                                                                                            ## stateOrProvince: JString
                                                                                                                                                            ##                  
                                                                                                                                                            ## : 
                                                                                                                                                            ## Specifies 
                                                                                                                                                            ## the 
                                                                                                                                                            ## name 
                                                                                                                                                            ## of 
                                                                                                                                                            ## your 
                                                                                                                                                            ## state 
                                                                                                                                                            ## or 
                                                                                                                                                            ## your 
                                                                                                                                                            ## province 
                                                                                                                                                            ## for 
                                                                                                                                                            ## the 
                                                                                                                                                            ## return 
                                                                                                                                                            ## address.
  ##   
                                                                                                                                                                       ## jobIds: JArray (required)
  ##   
                                                                                                                                                                                                   ## street2: JString
                                                                                                                                                                                                   ##          
                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                   ## Specifies 
                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                   ## optional 
                                                                                                                                                                                                   ## second 
                                                                                                                                                                                                   ## part 
                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                   ## street 
                                                                                                                                                                                                   ## address 
                                                                                                                                                                                                   ## for 
                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                   ## return 
                                                                                                                                                                                                   ## address, 
                                                                                                                                                                                                   ## for 
                                                                                                                                                                                                   ## example 
                                                                                                                                                                                                   ## Suite 
                                                                                                                                                                                                   ## 100.
  ##   
                                                                                                                                                                                                          ## company: JString
                                                                                                                                                                                                          ##          
                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                          ## Specifies 
                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                          ## name 
                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                          ## company 
                                                                                                                                                                                                          ## that 
                                                                                                                                                                                                          ## will 
                                                                                                                                                                                                          ## ship 
                                                                                                                                                                                                          ## this 
                                                                                                                                                                                                          ## package.
  ##   
                                                                                                                                                                                                                     ## phoneNumber: JString
                                                                                                                                                                                                                     ##              
                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                     ## Specifies 
                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                     ## phone 
                                                                                                                                                                                                                     ## number 
                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                     ## person 
                                                                                                                                                                                                                     ## responsible 
                                                                                                                                                                                                                     ## for 
                                                                                                                                                                                                                     ## shipping 
                                                                                                                                                                                                                     ## this 
                                                                                                                                                                                                                     ## package.
  ##   
                                                                                                                                                                                                                                ## postalCode: JString
                                                                                                                                                                                                                                ##             
                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                ## Specifies 
                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                ## postal 
                                                                                                                                                                                                                                ## code 
                                                                                                                                                                                                                                ## for 
                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                ## return 
                                                                                                                                                                                                                                ## address.
  ##   
                                                                                                                                                                                                                                           ## city: JString
                                                                                                                                                                                                                                           ##       
                                                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                                                           ## Specifies 
                                                                                                                                                                                                                                           ## the 
                                                                                                                                                                                                                                           ## name 
                                                                                                                                                                                                                                           ## of 
                                                                                                                                                                                                                                           ## your 
                                                                                                                                                                                                                                           ## city 
                                                                                                                                                                                                                                           ## for 
                                                                                                                                                                                                                                           ## the 
                                                                                                                                                                                                                                           ## return 
                                                                                                                                                                                                                                           ## address.
  ##   
                                                                                                                                                                                                                                                      ## street1: JString
                                                                                                                                                                                                                                                      ##          
                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                      ## Specifies 
                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                      ## first 
                                                                                                                                                                                                                                                      ## part 
                                                                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                      ## street 
                                                                                                                                                                                                                                                      ## address 
                                                                                                                                                                                                                                                      ## for 
                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                      ## return 
                                                                                                                                                                                                                                                      ## address, 
                                                                                                                                                                                                                                                      ## for 
                                                                                                                                                                                                                                                      ## example 
                                                                                                                                                                                                                                                      ## 1234 
                                                                                                                                                                                                                                                      ## Main 
                                                                                                                                                                                                                                                      ## Street.
  ##   
                                                                                                                                                                                                                                                                ## APIVersion: JString
                                                                                                                                                                                                                                                                ##             
                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                ## Specifies 
                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                ## version 
                                                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                ## client 
                                                                                                                                                                                                                                                                ## tool.
  ##   
                                                                                                                                                                                                                                                                        ## country: JString
                                                                                                                                                                                                                                                                        ##          
                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                        ## Specifies 
                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                        ## name 
                                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                                        ## your 
                                                                                                                                                                                                                                                                        ## country 
                                                                                                                                                                                                                                                                        ## for 
                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                        ## return 
                                                                                                                                                                                                                                                                        ## address.
  ##   
                                                                                                                                                                                                                                                                                   ## name: JString
                                                                                                                                                                                                                                                                                   ##       
                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                   ## Specifies 
                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                   ## name 
                                                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                   ## person 
                                                                                                                                                                                                                                                                                   ## responsible 
                                                                                                                                                                                                                                                                                   ## for 
                                                                                                                                                                                                                                                                                   ## shipping 
                                                                                                                                                                                                                                                                                   ## this 
                                                                                                                                                                                                                                                                                   ## package.
  section = newJObject()
  var valid_402656568 = formData.getOrDefault("street3")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "street3", valid_402656568
  var valid_402656569 = formData.getOrDefault("stateOrProvince")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "stateOrProvince", valid_402656569
  assert formData != nil,
         "formData argument is necessary due to required `jobIds` field"
  var valid_402656570 = formData.getOrDefault("jobIds")
  valid_402656570 = validateParameter(valid_402656570, JArray, required = true,
                                      default = nil)
  if valid_402656570 != nil:
    section.add "jobIds", valid_402656570
  var valid_402656571 = formData.getOrDefault("street2")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "street2", valid_402656571
  var valid_402656572 = formData.getOrDefault("company")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "company", valid_402656572
  var valid_402656573 = formData.getOrDefault("phoneNumber")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "phoneNumber", valid_402656573
  var valid_402656574 = formData.getOrDefault("postalCode")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "postalCode", valid_402656574
  var valid_402656575 = formData.getOrDefault("city")
  valid_402656575 = validateParameter(valid_402656575, JString,
                                      required = false, default = nil)
  if valid_402656575 != nil:
    section.add "city", valid_402656575
  var valid_402656576 = formData.getOrDefault("street1")
  valid_402656576 = validateParameter(valid_402656576, JString,
                                      required = false, default = nil)
  if valid_402656576 != nil:
    section.add "street1", valid_402656576
  var valid_402656577 = formData.getOrDefault("APIVersion")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "APIVersion", valid_402656577
  var valid_402656578 = formData.getOrDefault("country")
  valid_402656578 = validateParameter(valid_402656578, JString,
                                      required = false, default = nil)
  if valid_402656578 != nil:
    section.add "country", valid_402656578
  var valid_402656579 = formData.getOrDefault("name")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "name", valid_402656579
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656580: Call_PostGetShippingLabel_402656557;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
                                                                                         ## 
  let valid = call_402656580.validator(path, query, header, formData, body, _)
  let scheme = call_402656580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656580.makeUrl(scheme.get, call_402656580.host, call_402656580.base,
                                   call_402656580.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656580, uri, valid, _)

proc call*(call_402656581: Call_PostGetShippingLabel_402656557;
           Signature: string; Timestamp: string; jobIds: JsonNode;
           AWSAccessKeyId: string; SignatureMethod: string;
           SignatureVersion: string; street3: string = "";
           stateOrProvince: string = ""; street2: string = "";
           company: string = ""; phoneNumber: string = "";
           postalCode: string = ""; Version: string = "2010-06-01";
           city: string = ""; street1: string = ""; APIVersion: string = "";
           Action: string = "GetShippingLabel"; country: string = "";
           Operation: string = "GetShippingLabel"; name: string = ""): Recallable =
  ## postGetShippingLabel
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ##   
                                                                                                                        ## street3: string
                                                                                                                        ##          
                                                                                                                        ## : 
                                                                                                                        ## Specifies 
                                                                                                                        ## the 
                                                                                                                        ## optional 
                                                                                                                        ## third 
                                                                                                                        ## part 
                                                                                                                        ## of 
                                                                                                                        ## the 
                                                                                                                        ## street 
                                                                                                                        ## address 
                                                                                                                        ## for 
                                                                                                                        ## the 
                                                                                                                        ## return 
                                                                                                                        ## address, 
                                                                                                                        ## for 
                                                                                                                        ## example 
                                                                                                                        ## c/o 
                                                                                                                        ## Jane 
                                                                                                                        ## Doe.
  ##   
                                                                                                                               ## Signature: string (required)
  ##   
                                                                                                                                                              ## Timestamp: string (required)
  ##   
                                                                                                                                                                                             ## stateOrProvince: string
                                                                                                                                                                                             ##                  
                                                                                                                                                                                             ## : 
                                                                                                                                                                                             ## Specifies 
                                                                                                                                                                                             ## the 
                                                                                                                                                                                             ## name 
                                                                                                                                                                                             ## of 
                                                                                                                                                                                             ## your 
                                                                                                                                                                                             ## state 
                                                                                                                                                                                             ## or 
                                                                                                                                                                                             ## your 
                                                                                                                                                                                             ## province 
                                                                                                                                                                                             ## for 
                                                                                                                                                                                             ## the 
                                                                                                                                                                                             ## return 
                                                                                                                                                                                             ## address.
  ##   
                                                                                                                                                                                                        ## jobIds: JArray (required)
  ##   
                                                                                                                                                                                                                                    ## AWSAccessKeyId: string (required)
  ##   
                                                                                                                                                                                                                                                                        ## street2: string
                                                                                                                                                                                                                                                                        ##          
                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                        ## Specifies 
                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                        ## optional 
                                                                                                                                                                                                                                                                        ## second 
                                                                                                                                                                                                                                                                        ## part 
                                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                        ## street 
                                                                                                                                                                                                                                                                        ## address 
                                                                                                                                                                                                                                                                        ## for 
                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                        ## return 
                                                                                                                                                                                                                                                                        ## address, 
                                                                                                                                                                                                                                                                        ## for 
                                                                                                                                                                                                                                                                        ## example 
                                                                                                                                                                                                                                                                        ## Suite 
                                                                                                                                                                                                                                                                        ## 100.
  ##   
                                                                                                                                                                                                                                                                               ## company: string
                                                                                                                                                                                                                                                                               ##          
                                                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                                                               ## Specifies 
                                                                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                                                                               ## name 
                                                                                                                                                                                                                                                                               ## of 
                                                                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                                                                               ## company 
                                                                                                                                                                                                                                                                               ## that 
                                                                                                                                                                                                                                                                               ## will 
                                                                                                                                                                                                                                                                               ## ship 
                                                                                                                                                                                                                                                                               ## this 
                                                                                                                                                                                                                                                                               ## package.
  ##   
                                                                                                                                                                                                                                                                                          ## phoneNumber: string
                                                                                                                                                                                                                                                                                          ##              
                                                                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                                                                          ## Specifies 
                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                          ## phone 
                                                                                                                                                                                                                                                                                          ## number 
                                                                                                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                          ## person 
                                                                                                                                                                                                                                                                                          ## responsible 
                                                                                                                                                                                                                                                                                          ## for 
                                                                                                                                                                                                                                                                                          ## shipping 
                                                                                                                                                                                                                                                                                          ## this 
                                                                                                                                                                                                                                                                                          ## package.
  ##   
                                                                                                                                                                                                                                                                                                     ## postalCode: string
                                                                                                                                                                                                                                                                                                     ##             
                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                     ## Specifies 
                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                     ## postal 
                                                                                                                                                                                                                                                                                                     ## code 
                                                                                                                                                                                                                                                                                                     ## for 
                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                     ## return 
                                                                                                                                                                                                                                                                                                     ## address.
  ##   
                                                                                                                                                                                                                                                                                                                ## Version: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                             ## city: string
                                                                                                                                                                                                                                                                                                                                             ##       
                                                                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                                                                             ## Specifies 
                                                                                                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                                                                                                             ## name 
                                                                                                                                                                                                                                                                                                                                             ## of 
                                                                                                                                                                                                                                                                                                                                             ## your 
                                                                                                                                                                                                                                                                                                                                             ## city 
                                                                                                                                                                                                                                                                                                                                             ## for 
                                                                                                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                                                                                                             ## return 
                                                                                                                                                                                                                                                                                                                                             ## address.
  ##   
                                                                                                                                                                                                                                                                                                                                                        ## street1: string
                                                                                                                                                                                                                                                                                                                                                        ##          
                                                                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                                                                        ## Specifies 
                                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                                        ## first 
                                                                                                                                                                                                                                                                                                                                                        ## part 
                                                                                                                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                                        ## street 
                                                                                                                                                                                                                                                                                                                                                        ## address 
                                                                                                                                                                                                                                                                                                                                                        ## for 
                                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                                        ## return 
                                                                                                                                                                                                                                                                                                                                                        ## address, 
                                                                                                                                                                                                                                                                                                                                                        ## for 
                                                                                                                                                                                                                                                                                                                                                        ## example 
                                                                                                                                                                                                                                                                                                                                                        ## 1234 
                                                                                                                                                                                                                                                                                                                                                        ## Main 
                                                                                                                                                                                                                                                                                                                                                        ## Street.
  ##   
                                                                                                                                                                                                                                                                                                                                                                  ## APIVersion: string
                                                                                                                                                                                                                                                                                                                                                                  ##             
                                                                                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                                                                                  ## Specifies 
                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                  ## version 
                                                                                                                                                                                                                                                                                                                                                                  ## of 
                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                  ## client 
                                                                                                                                                                                                                                                                                                                                                                  ## tool.
  ##   
                                                                                                                                                                                                                                                                                                                                                                          ## Action: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                      ## country: string
                                                                                                                                                                                                                                                                                                                                                                                                      ##          
                                                                                                                                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                                                                                                                                      ## Specifies 
                                                                                                                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                                                                                                                      ## name 
                                                                                                                                                                                                                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                                                                                                                                                                                                                      ## your 
                                                                                                                                                                                                                                                                                                                                                                                                      ## country 
                                                                                                                                                                                                                                                                                                                                                                                                      ## for 
                                                                                                                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                                                                                                                      ## return 
                                                                                                                                                                                                                                                                                                                                                                                                      ## address.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                 ## SignatureMethod: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## SignatureVersion: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## Operation: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## name: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ##       
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## Specifies 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## person 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## responsible 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## for 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## shipping 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## this 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## package.
  var query_402656582 = newJObject()
  var formData_402656583 = newJObject()
  add(formData_402656583, "street3", newJString(street3))
  add(query_402656582, "Signature", newJString(Signature))
  add(query_402656582, "Timestamp", newJString(Timestamp))
  add(formData_402656583, "stateOrProvince", newJString(stateOrProvince))
  if jobIds != nil:
    formData_402656583.add "jobIds", jobIds
  add(query_402656582, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_402656583, "street2", newJString(street2))
  add(formData_402656583, "company", newJString(company))
  add(formData_402656583, "phoneNumber", newJString(phoneNumber))
  add(formData_402656583, "postalCode", newJString(postalCode))
  add(query_402656582, "Version", newJString(Version))
  add(formData_402656583, "city", newJString(city))
  add(formData_402656583, "street1", newJString(street1))
  add(formData_402656583, "APIVersion", newJString(APIVersion))
  add(query_402656582, "Action", newJString(Action))
  add(formData_402656583, "country", newJString(country))
  add(query_402656582, "SignatureMethod", newJString(SignatureMethod))
  add(query_402656582, "SignatureVersion", newJString(SignatureVersion))
  add(query_402656582, "Operation", newJString(Operation))
  add(formData_402656583, "name", newJString(name))
  result = call_402656581.call(nil, query_402656582, nil, formData_402656583,
                               nil)

var postGetShippingLabel* = Call_PostGetShippingLabel_402656557(
    name: "postGetShippingLabel", meth: HttpMethod.HttpPost,
    host: "importexport.amazonaws.com",
    route: "/#Operation=GetShippingLabel&Action=GetShippingLabel",
    validator: validate_PostGetShippingLabel_402656558, base: "/",
    makeUrl: url_PostGetShippingLabel_402656559,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetShippingLabel_402656531 = ref object of OpenApiRestCall_402656029
proc url_GetGetShippingLabel_402656533(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetShippingLabel_402656532(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   street3: JString
                                  ##          : Specifies the optional third part of the street address for the return address, for example c/o Jane Doe.
  ##   
                                                                                                                                                         ## APIVersion: JString
                                                                                                                                                         ##             
                                                                                                                                                         ## : 
                                                                                                                                                         ## Specifies 
                                                                                                                                                         ## the 
                                                                                                                                                         ## version 
                                                                                                                                                         ## of 
                                                                                                                                                         ## the 
                                                                                                                                                         ## client 
                                                                                                                                                         ## tool.
  ##   
                                                                                                                                                                 ## jobIds: JArray (required)
  ##   
                                                                                                                                                                                             ## Signature: JString (required)
  ##   
                                                                                                                                                                                                                             ## Timestamp: JString (required)
  ##   
                                                                                                                                                                                                                                                             ## street2: JString
                                                                                                                                                                                                                                                             ##          
                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                             ## Specifies 
                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                             ## optional 
                                                                                                                                                                                                                                                             ## second 
                                                                                                                                                                                                                                                             ## part 
                                                                                                                                                                                                                                                             ## of 
                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                             ## street 
                                                                                                                                                                                                                                                             ## address 
                                                                                                                                                                                                                                                             ## for 
                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                             ## return 
                                                                                                                                                                                                                                                             ## address, 
                                                                                                                                                                                                                                                             ## for 
                                                                                                                                                                                                                                                             ## example 
                                                                                                                                                                                                                                                             ## Suite 
                                                                                                                                                                                                                                                             ## 100.
  ##   
                                                                                                                                                                                                                                                                    ## postalCode: JString
                                                                                                                                                                                                                                                                    ##             
                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                    ## Specifies 
                                                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                                                    ## postal 
                                                                                                                                                                                                                                                                    ## code 
                                                                                                                                                                                                                                                                    ## for 
                                                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                                                    ## return 
                                                                                                                                                                                                                                                                    ## address.
  ##   
                                                                                                                                                                                                                                                                               ## AWSAccessKeyId: JString (required)
  ##   
                                                                                                                                                                                                                                                                                                                    ## country: JString
                                                                                                                                                                                                                                                                                                                    ##          
                                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                                    ## Specifies 
                                                                                                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                                                                                                    ## name 
                                                                                                                                                                                                                                                                                                                    ## of 
                                                                                                                                                                                                                                                                                                                    ## your 
                                                                                                                                                                                                                                                                                                                    ## country 
                                                                                                                                                                                                                                                                                                                    ## for 
                                                                                                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                                                                                                    ## return 
                                                                                                                                                                                                                                                                                                                    ## address.
  ##   
                                                                                                                                                                                                                                                                                                                               ## Version: JString (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                             ## street1: JString
                                                                                                                                                                                                                                                                                                                                                             ##          
                                                                                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                                                                                             ## Specifies 
                                                                                                                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                                                                                                                             ## first 
                                                                                                                                                                                                                                                                                                                                                             ## part 
                                                                                                                                                                                                                                                                                                                                                             ## of 
                                                                                                                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                                                                                                                             ## street 
                                                                                                                                                                                                                                                                                                                                                             ## address 
                                                                                                                                                                                                                                                                                                                                                             ## for 
                                                                                                                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                                                                                                                             ## return 
                                                                                                                                                                                                                                                                                                                                                             ## address, 
                                                                                                                                                                                                                                                                                                                                                             ## for 
                                                                                                                                                                                                                                                                                                                                                             ## example 
                                                                                                                                                                                                                                                                                                                                                             ## 1234 
                                                                                                                                                                                                                                                                                                                                                             ## Main 
                                                                                                                                                                                                                                                                                                                                                             ## Street.
  ##   
                                                                                                                                                                                                                                                                                                                                                                       ## name: JString
                                                                                                                                                                                                                                                                                                                                                                       ##       
                                                                                                                                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                                                                                                                                       ## Specifies 
                                                                                                                                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                                                                                                                                       ## name 
                                                                                                                                                                                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                                                                                                                                       ## person 
                                                                                                                                                                                                                                                                                                                                                                       ## responsible 
                                                                                                                                                                                                                                                                                                                                                                       ## for 
                                                                                                                                                                                                                                                                                                                                                                       ## shipping 
                                                                                                                                                                                                                                                                                                                                                                       ## this 
                                                                                                                                                                                                                                                                                                                                                                       ## package.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                  ## phoneNumber: JString
                                                                                                                                                                                                                                                                                                                                                                                  ##              
                                                                                                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                                                                                                  ## Specifies 
                                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                                  ## phone 
                                                                                                                                                                                                                                                                                                                                                                                  ## number 
                                                                                                                                                                                                                                                                                                                                                                                  ## of 
                                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                                  ## person 
                                                                                                                                                                                                                                                                                                                                                                                  ## responsible 
                                                                                                                                                                                                                                                                                                                                                                                  ## for 
                                                                                                                                                                                                                                                                                                                                                                                  ## shipping 
                                                                                                                                                                                                                                                                                                                                                                                  ## this 
                                                                                                                                                                                                                                                                                                                                                                                  ## package.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                             ## Action: JString (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                          ## stateOrProvince: JString
                                                                                                                                                                                                                                                                                                                                                                                                                          ##                  
                                                                                                                                                                                                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## Specifies 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## your 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## state 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## or 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## your 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## province 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## for 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## return 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## address.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                     ## company: JString
                                                                                                                                                                                                                                                                                                                                                                                                                                     ##          
                                                                                                                                                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                     ## Specifies 
                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                     ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                     ## company 
                                                                                                                                                                                                                                                                                                                                                                                                                                     ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                     ## will 
                                                                                                                                                                                                                                                                                                                                                                                                                                     ## ship 
                                                                                                                                                                                                                                                                                                                                                                                                                                     ## this 
                                                                                                                                                                                                                                                                                                                                                                                                                                     ## package.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                ## SignatureMethod: JString (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## city: JString
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ##       
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## Specifies 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## your 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## city 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## for 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## return 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## address.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## SignatureVersion: JString (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## Operation: JString (required)
  section = newJObject()
  var valid_402656534 = query.getOrDefault("street3")
  valid_402656534 = validateParameter(valid_402656534, JString,
                                      required = false, default = nil)
  if valid_402656534 != nil:
    section.add "street3", valid_402656534
  var valid_402656535 = query.getOrDefault("APIVersion")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "APIVersion", valid_402656535
  assert query != nil,
         "query argument is necessary due to required `jobIds` field"
  var valid_402656536 = query.getOrDefault("jobIds")
  valid_402656536 = validateParameter(valid_402656536, JArray, required = true,
                                      default = nil)
  if valid_402656536 != nil:
    section.add "jobIds", valid_402656536
  var valid_402656537 = query.getOrDefault("Signature")
  valid_402656537 = validateParameter(valid_402656537, JString, required = true,
                                      default = nil)
  if valid_402656537 != nil:
    section.add "Signature", valid_402656537
  var valid_402656538 = query.getOrDefault("Timestamp")
  valid_402656538 = validateParameter(valid_402656538, JString, required = true,
                                      default = nil)
  if valid_402656538 != nil:
    section.add "Timestamp", valid_402656538
  var valid_402656539 = query.getOrDefault("street2")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "street2", valid_402656539
  var valid_402656540 = query.getOrDefault("postalCode")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "postalCode", valid_402656540
  var valid_402656541 = query.getOrDefault("AWSAccessKeyId")
  valid_402656541 = validateParameter(valid_402656541, JString, required = true,
                                      default = nil)
  if valid_402656541 != nil:
    section.add "AWSAccessKeyId", valid_402656541
  var valid_402656542 = query.getOrDefault("country")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "country", valid_402656542
  var valid_402656543 = query.getOrDefault("Version")
  valid_402656543 = validateParameter(valid_402656543, JString, required = true,
                                      default = newJString("2010-06-01"))
  if valid_402656543 != nil:
    section.add "Version", valid_402656543
  var valid_402656544 = query.getOrDefault("street1")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "street1", valid_402656544
  var valid_402656545 = query.getOrDefault("name")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "name", valid_402656545
  var valid_402656546 = query.getOrDefault("phoneNumber")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "phoneNumber", valid_402656546
  var valid_402656547 = query.getOrDefault("Action")
  valid_402656547 = validateParameter(valid_402656547, JString, required = true,
                                      default = newJString("GetShippingLabel"))
  if valid_402656547 != nil:
    section.add "Action", valid_402656547
  var valid_402656548 = query.getOrDefault("stateOrProvince")
  valid_402656548 = validateParameter(valid_402656548, JString,
                                      required = false, default = nil)
  if valid_402656548 != nil:
    section.add "stateOrProvince", valid_402656548
  var valid_402656549 = query.getOrDefault("company")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "company", valid_402656549
  var valid_402656550 = query.getOrDefault("SignatureMethod")
  valid_402656550 = validateParameter(valid_402656550, JString, required = true,
                                      default = nil)
  if valid_402656550 != nil:
    section.add "SignatureMethod", valid_402656550
  var valid_402656551 = query.getOrDefault("city")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "city", valid_402656551
  var valid_402656552 = query.getOrDefault("SignatureVersion")
  valid_402656552 = validateParameter(valid_402656552, JString, required = true,
                                      default = nil)
  if valid_402656552 != nil:
    section.add "SignatureVersion", valid_402656552
  var valid_402656553 = query.getOrDefault("Operation")
  valid_402656553 = validateParameter(valid_402656553, JString, required = true,
                                      default = newJString("GetShippingLabel"))
  if valid_402656553 != nil:
    section.add "Operation", valid_402656553
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656554: Call_GetGetShippingLabel_402656531;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
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

proc call*(call_402656555: Call_GetGetShippingLabel_402656531; jobIds: JsonNode;
           Signature: string; Timestamp: string; AWSAccessKeyId: string;
           SignatureMethod: string; SignatureVersion: string;
           street3: string = ""; APIVersion: string = ""; street2: string = "";
           postalCode: string = ""; country: string = "";
           Version: string = "2010-06-01"; street1: string = "";
           name: string = ""; phoneNumber: string = "";
           Action: string = "GetShippingLabel"; stateOrProvince: string = "";
           company: string = ""; city: string = "";
           Operation: string = "GetShippingLabel"): Recallable =
  ## getGetShippingLabel
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ##   
                                                                                                                        ## street3: string
                                                                                                                        ##          
                                                                                                                        ## : 
                                                                                                                        ## Specifies 
                                                                                                                        ## the 
                                                                                                                        ## optional 
                                                                                                                        ## third 
                                                                                                                        ## part 
                                                                                                                        ## of 
                                                                                                                        ## the 
                                                                                                                        ## street 
                                                                                                                        ## address 
                                                                                                                        ## for 
                                                                                                                        ## the 
                                                                                                                        ## return 
                                                                                                                        ## address, 
                                                                                                                        ## for 
                                                                                                                        ## example 
                                                                                                                        ## c/o 
                                                                                                                        ## Jane 
                                                                                                                        ## Doe.
  ##   
                                                                                                                               ## APIVersion: string
                                                                                                                               ##             
                                                                                                                               ## : 
                                                                                                                               ## Specifies 
                                                                                                                               ## the 
                                                                                                                               ## version 
                                                                                                                               ## of 
                                                                                                                               ## the 
                                                                                                                               ## client 
                                                                                                                               ## tool.
  ##   
                                                                                                                                       ## jobIds: JArray (required)
  ##   
                                                                                                                                                                   ## Signature: string (required)
  ##   
                                                                                                                                                                                                  ## Timestamp: string (required)
  ##   
                                                                                                                                                                                                                                 ## street2: string
                                                                                                                                                                                                                                 ##          
                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                 ## Specifies 
                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                 ## optional 
                                                                                                                                                                                                                                 ## second 
                                                                                                                                                                                                                                 ## part 
                                                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                 ## street 
                                                                                                                                                                                                                                 ## address 
                                                                                                                                                                                                                                 ## for 
                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                 ## return 
                                                                                                                                                                                                                                 ## address, 
                                                                                                                                                                                                                                 ## for 
                                                                                                                                                                                                                                 ## example 
                                                                                                                                                                                                                                 ## Suite 
                                                                                                                                                                                                                                 ## 100.
  ##   
                                                                                                                                                                                                                                        ## postalCode: string
                                                                                                                                                                                                                                        ##             
                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                        ## Specifies 
                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                        ## postal 
                                                                                                                                                                                                                                        ## code 
                                                                                                                                                                                                                                        ## for 
                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                        ## return 
                                                                                                                                                                                                                                        ## address.
  ##   
                                                                                                                                                                                                                                                   ## AWSAccessKeyId: string (required)
  ##   
                                                                                                                                                                                                                                                                                       ## country: string
                                                                                                                                                                                                                                                                                       ##          
                                                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                                                       ## Specifies 
                                                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                                                       ## name 
                                                                                                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                                                                                                       ## your 
                                                                                                                                                                                                                                                                                       ## country 
                                                                                                                                                                                                                                                                                       ## for 
                                                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                                                       ## return 
                                                                                                                                                                                                                                                                                       ## address.
  ##   
                                                                                                                                                                                                                                                                                                  ## Version: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                               ## street1: string
                                                                                                                                                                                                                                                                                                                               ##          
                                                                                                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                                                                                                               ## Specifies 
                                                                                                                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                                                                                                                               ## first 
                                                                                                                                                                                                                                                                                                                               ## part 
                                                                                                                                                                                                                                                                                                                               ## of 
                                                                                                                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                                                                                                                               ## street 
                                                                                                                                                                                                                                                                                                                               ## address 
                                                                                                                                                                                                                                                                                                                               ## for 
                                                                                                                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                                                                                                                               ## return 
                                                                                                                                                                                                                                                                                                                               ## address, 
                                                                                                                                                                                                                                                                                                                               ## for 
                                                                                                                                                                                                                                                                                                                               ## example 
                                                                                                                                                                                                                                                                                                                               ## 1234 
                                                                                                                                                                                                                                                                                                                               ## Main 
                                                                                                                                                                                                                                                                                                                               ## Street.
  ##   
                                                                                                                                                                                                                                                                                                                                         ## name: string
                                                                                                                                                                                                                                                                                                                                         ##       
                                                                                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                                                                                         ## Specifies 
                                                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                                                         ## name 
                                                                                                                                                                                                                                                                                                                                         ## of 
                                                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                                                         ## person 
                                                                                                                                                                                                                                                                                                                                         ## responsible 
                                                                                                                                                                                                                                                                                                                                         ## for 
                                                                                                                                                                                                                                                                                                                                         ## shipping 
                                                                                                                                                                                                                                                                                                                                         ## this 
                                                                                                                                                                                                                                                                                                                                         ## package.
  ##   
                                                                                                                                                                                                                                                                                                                                                    ## phoneNumber: string
                                                                                                                                                                                                                                                                                                                                                    ##              
                                                                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                                                                    ## Specifies 
                                                                                                                                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                                                                                                                                    ## phone 
                                                                                                                                                                                                                                                                                                                                                    ## number 
                                                                                                                                                                                                                                                                                                                                                    ## of 
                                                                                                                                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                                                                                                                                    ## person 
                                                                                                                                                                                                                                                                                                                                                    ## responsible 
                                                                                                                                                                                                                                                                                                                                                    ## for 
                                                                                                                                                                                                                                                                                                                                                    ## shipping 
                                                                                                                                                                                                                                                                                                                                                    ## this 
                                                                                                                                                                                                                                                                                                                                                    ## package.
  ##   
                                                                                                                                                                                                                                                                                                                                                               ## Action: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                           ## stateOrProvince: string
                                                                                                                                                                                                                                                                                                                                                                                           ##                  
                                                                                                                                                                                                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                                                                                                                                                                                                           ## Specifies 
                                                                                                                                                                                                                                                                                                                                                                                           ## the 
                                                                                                                                                                                                                                                                                                                                                                                           ## name 
                                                                                                                                                                                                                                                                                                                                                                                           ## of 
                                                                                                                                                                                                                                                                                                                                                                                           ## your 
                                                                                                                                                                                                                                                                                                                                                                                           ## state 
                                                                                                                                                                                                                                                                                                                                                                                           ## or 
                                                                                                                                                                                                                                                                                                                                                                                           ## your 
                                                                                                                                                                                                                                                                                                                                                                                           ## province 
                                                                                                                                                                                                                                                                                                                                                                                           ## for 
                                                                                                                                                                                                                                                                                                                                                                                           ## the 
                                                                                                                                                                                                                                                                                                                                                                                           ## return 
                                                                                                                                                                                                                                                                                                                                                                                           ## address.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                      ## company: string
                                                                                                                                                                                                                                                                                                                                                                                                      ##          
                                                                                                                                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                                                                                                                                      ## Specifies 
                                                                                                                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                                                                                                                      ## name 
                                                                                                                                                                                                                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                                                                                                                      ## company 
                                                                                                                                                                                                                                                                                                                                                                                                      ## that 
                                                                                                                                                                                                                                                                                                                                                                                                      ## will 
                                                                                                                                                                                                                                                                                                                                                                                                      ## ship 
                                                                                                                                                                                                                                                                                                                                                                                                      ## this 
                                                                                                                                                                                                                                                                                                                                                                                                      ## package.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                 ## SignatureMethod: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## city: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ##       
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## Specifies 
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## your 
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## city 
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## for 
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## return 
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## address.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## SignatureVersion: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## Operation: string (required)
  var query_402656556 = newJObject()
  add(query_402656556, "street3", newJString(street3))
  add(query_402656556, "APIVersion", newJString(APIVersion))
  if jobIds != nil:
    query_402656556.add "jobIds", jobIds
  add(query_402656556, "Signature", newJString(Signature))
  add(query_402656556, "Timestamp", newJString(Timestamp))
  add(query_402656556, "street2", newJString(street2))
  add(query_402656556, "postalCode", newJString(postalCode))
  add(query_402656556, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_402656556, "country", newJString(country))
  add(query_402656556, "Version", newJString(Version))
  add(query_402656556, "street1", newJString(street1))
  add(query_402656556, "name", newJString(name))
  add(query_402656556, "phoneNumber", newJString(phoneNumber))
  add(query_402656556, "Action", newJString(Action))
  add(query_402656556, "stateOrProvince", newJString(stateOrProvince))
  add(query_402656556, "company", newJString(company))
  add(query_402656556, "SignatureMethod", newJString(SignatureMethod))
  add(query_402656556, "city", newJString(city))
  add(query_402656556, "SignatureVersion", newJString(SignatureVersion))
  add(query_402656556, "Operation", newJString(Operation))
  result = call_402656555.call(nil, query_402656556, nil, nil, nil)

var getGetShippingLabel* = Call_GetGetShippingLabel_402656531(
    name: "getGetShippingLabel", meth: HttpMethod.HttpGet,
    host: "importexport.amazonaws.com",
    route: "/#Operation=GetShippingLabel&Action=GetShippingLabel",
    validator: validate_GetGetShippingLabel_402656532, base: "/",
    makeUrl: url_GetGetShippingLabel_402656533,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetStatus_402656600 = ref object of OpenApiRestCall_402656029
proc url_PostGetStatus_402656602(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetStatus_402656601(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   Timestamp: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  ##   Action: JString (required)
  ##   SignatureMethod: JString (required)
  ##   SignatureVersion: JString (required)
  ##   Operation: JString (required)
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `Signature` field"
  var valid_402656603 = query.getOrDefault("Signature")
  valid_402656603 = validateParameter(valid_402656603, JString, required = true,
                                      default = nil)
  if valid_402656603 != nil:
    section.add "Signature", valid_402656603
  var valid_402656604 = query.getOrDefault("Timestamp")
  valid_402656604 = validateParameter(valid_402656604, JString, required = true,
                                      default = nil)
  if valid_402656604 != nil:
    section.add "Timestamp", valid_402656604
  var valid_402656605 = query.getOrDefault("AWSAccessKeyId")
  valid_402656605 = validateParameter(valid_402656605, JString, required = true,
                                      default = nil)
  if valid_402656605 != nil:
    section.add "AWSAccessKeyId", valid_402656605
  var valid_402656606 = query.getOrDefault("Version")
  valid_402656606 = validateParameter(valid_402656606, JString, required = true,
                                      default = newJString("2010-06-01"))
  if valid_402656606 != nil:
    section.add "Version", valid_402656606
  var valid_402656607 = query.getOrDefault("Action")
  valid_402656607 = validateParameter(valid_402656607, JString, required = true,
                                      default = newJString("GetStatus"))
  if valid_402656607 != nil:
    section.add "Action", valid_402656607
  var valid_402656608 = query.getOrDefault("SignatureMethod")
  valid_402656608 = validateParameter(valid_402656608, JString, required = true,
                                      default = nil)
  if valid_402656608 != nil:
    section.add "SignatureMethod", valid_402656608
  var valid_402656609 = query.getOrDefault("SignatureVersion")
  valid_402656609 = validateParameter(valid_402656609, JString, required = true,
                                      default = nil)
  if valid_402656609 != nil:
    section.add "SignatureVersion", valid_402656609
  var valid_402656610 = query.getOrDefault("Operation")
  valid_402656610 = validateParameter(valid_402656610, JString, required = true,
                                      default = newJString("GetStatus"))
  if valid_402656610 != nil:
    section.add "Operation", valid_402656610
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   APIVersion: JString
                                     ##             : Specifies the version of the client tool.
  ##   
                                                                                               ## JobId: JString (required)
                                                                                               ##        
                                                                                               ## : 
                                                                                               ## A 
                                                                                               ## unique 
                                                                                               ## identifier 
                                                                                               ## which 
                                                                                               ## refers 
                                                                                               ## to 
                                                                                               ## a 
                                                                                               ## particular 
                                                                                               ## job.
  section = newJObject()
  var valid_402656611 = formData.getOrDefault("APIVersion")
  valid_402656611 = validateParameter(valid_402656611, JString,
                                      required = false, default = nil)
  if valid_402656611 != nil:
    section.add "APIVersion", valid_402656611
  assert formData != nil,
         "formData argument is necessary due to required `JobId` field"
  var valid_402656612 = formData.getOrDefault("JobId")
  valid_402656612 = validateParameter(valid_402656612, JString, required = true,
                                      default = nil)
  if valid_402656612 != nil:
    section.add "JobId", valid_402656612
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656613: Call_PostGetStatus_402656600; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
                                                                                         ## 
  let valid = call_402656613.validator(path, query, header, formData, body, _)
  let scheme = call_402656613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656613.makeUrl(scheme.get, call_402656613.host, call_402656613.base,
                                   call_402656613.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656613, uri, valid, _)

proc call*(call_402656614: Call_PostGetStatus_402656600; Signature: string;
           Timestamp: string; AWSAccessKeyId: string; JobId: string;
           SignatureMethod: string; SignatureVersion: string;
           Version: string = "2010-06-01"; APIVersion: string = "";
           Action: string = "GetStatus"; Operation: string = "GetStatus"): Recallable =
  ## postGetStatus
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ##   
                                                                                                                                                                                                                                           ## Signature: string (required)
  ##   
                                                                                                                                                                                                                                                                          ## Timestamp: string (required)
  ##   
                                                                                                                                                                                                                                                                                                         ## AWSAccessKeyId: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                             ## Version: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                          ## APIVersion: string
                                                                                                                                                                                                                                                                                                                                                                          ##             
                                                                                                                                                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                                                                                                                                                          ## Specifies 
                                                                                                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                                                                                                          ## version 
                                                                                                                                                                                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                                                                                                          ## client 
                                                                                                                                                                                                                                                                                                                                                                          ## tool.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                  ## Action: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                              ## JobId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                              ##        
                                                                                                                                                                                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                                                                                                                                                                                              ## A 
                                                                                                                                                                                                                                                                                                                                                                                                              ## unique 
                                                                                                                                                                                                                                                                                                                                                                                                              ## identifier 
                                                                                                                                                                                                                                                                                                                                                                                                              ## which 
                                                                                                                                                                                                                                                                                                                                                                                                              ## refers 
                                                                                                                                                                                                                                                                                                                                                                                                              ## to 
                                                                                                                                                                                                                                                                                                                                                                                                              ## a 
                                                                                                                                                                                                                                                                                                                                                                                                              ## particular 
                                                                                                                                                                                                                                                                                                                                                                                                              ## job.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                     ## SignatureMethod: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## SignatureVersion: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## Operation: string (required)
  var query_402656615 = newJObject()
  var formData_402656616 = newJObject()
  add(query_402656615, "Signature", newJString(Signature))
  add(query_402656615, "Timestamp", newJString(Timestamp))
  add(query_402656615, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_402656615, "Version", newJString(Version))
  add(formData_402656616, "APIVersion", newJString(APIVersion))
  add(query_402656615, "Action", newJString(Action))
  add(formData_402656616, "JobId", newJString(JobId))
  add(query_402656615, "SignatureMethod", newJString(SignatureMethod))
  add(query_402656615, "SignatureVersion", newJString(SignatureVersion))
  add(query_402656615, "Operation", newJString(Operation))
  result = call_402656614.call(nil, query_402656615, nil, formData_402656616,
                               nil)

var postGetStatus* = Call_PostGetStatus_402656600(name: "postGetStatus",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=GetStatus&Action=GetStatus",
    validator: validate_PostGetStatus_402656601, base: "/",
    makeUrl: url_PostGetStatus_402656602, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetStatus_402656584 = ref object of OpenApiRestCall_402656029
proc url_GetGetStatus_402656586(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetStatus_402656585(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   APIVersion: JString
                                  ##             : Specifies the version of the client tool.
  ##   
                                                                                            ## Signature: JString (required)
  ##   
                                                                                                                            ## Timestamp: JString (required)
  ##   
                                                                                                                                                            ## AWSAccessKeyId: JString (required)
  ##   
                                                                                                                                                                                                 ## JobId: JString (required)
                                                                                                                                                                                                 ##        
                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                 ## A 
                                                                                                                                                                                                 ## unique 
                                                                                                                                                                                                 ## identifier 
                                                                                                                                                                                                 ## which 
                                                                                                                                                                                                 ## refers 
                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                 ## a 
                                                                                                                                                                                                 ## particular 
                                                                                                                                                                                                 ## job.
  ##   
                                                                                                                                                                                                        ## Version: JString (required)
  ##   
                                                                                                                                                                                                                                      ## Action: JString (required)
  ##   
                                                                                                                                                                                                                                                                   ## SignatureMethod: JString (required)
  ##   
                                                                                                                                                                                                                                                                                                         ## SignatureVersion: JString (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                ## Operation: JString (required)
  section = newJObject()
  var valid_402656587 = query.getOrDefault("APIVersion")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "APIVersion", valid_402656587
  assert query != nil,
         "query argument is necessary due to required `Signature` field"
  var valid_402656588 = query.getOrDefault("Signature")
  valid_402656588 = validateParameter(valid_402656588, JString, required = true,
                                      default = nil)
  if valid_402656588 != nil:
    section.add "Signature", valid_402656588
  var valid_402656589 = query.getOrDefault("Timestamp")
  valid_402656589 = validateParameter(valid_402656589, JString, required = true,
                                      default = nil)
  if valid_402656589 != nil:
    section.add "Timestamp", valid_402656589
  var valid_402656590 = query.getOrDefault("AWSAccessKeyId")
  valid_402656590 = validateParameter(valid_402656590, JString, required = true,
                                      default = nil)
  if valid_402656590 != nil:
    section.add "AWSAccessKeyId", valid_402656590
  var valid_402656591 = query.getOrDefault("JobId")
  valid_402656591 = validateParameter(valid_402656591, JString, required = true,
                                      default = nil)
  if valid_402656591 != nil:
    section.add "JobId", valid_402656591
  var valid_402656592 = query.getOrDefault("Version")
  valid_402656592 = validateParameter(valid_402656592, JString, required = true,
                                      default = newJString("2010-06-01"))
  if valid_402656592 != nil:
    section.add "Version", valid_402656592
  var valid_402656593 = query.getOrDefault("Action")
  valid_402656593 = validateParameter(valid_402656593, JString, required = true,
                                      default = newJString("GetStatus"))
  if valid_402656593 != nil:
    section.add "Action", valid_402656593
  var valid_402656594 = query.getOrDefault("SignatureMethod")
  valid_402656594 = validateParameter(valid_402656594, JString, required = true,
                                      default = nil)
  if valid_402656594 != nil:
    section.add "SignatureMethod", valid_402656594
  var valid_402656595 = query.getOrDefault("SignatureVersion")
  valid_402656595 = validateParameter(valid_402656595, JString, required = true,
                                      default = nil)
  if valid_402656595 != nil:
    section.add "SignatureVersion", valid_402656595
  var valid_402656596 = query.getOrDefault("Operation")
  valid_402656596 = validateParameter(valid_402656596, JString, required = true,
                                      default = newJString("GetStatus"))
  if valid_402656596 != nil:
    section.add "Operation", valid_402656596
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656597: Call_GetGetStatus_402656584; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
                                                                                         ## 
  let valid = call_402656597.validator(path, query, header, formData, body, _)
  let scheme = call_402656597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656597.makeUrl(scheme.get, call_402656597.host, call_402656597.base,
                                   call_402656597.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656597, uri, valid, _)

proc call*(call_402656598: Call_GetGetStatus_402656584; Signature: string;
           Timestamp: string; AWSAccessKeyId: string; JobId: string;
           SignatureMethod: string; SignatureVersion: string;
           APIVersion: string = ""; Version: string = "2010-06-01";
           Action: string = "GetStatus"; Operation: string = "GetStatus"): Recallable =
  ## getGetStatus
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ##   
                                                                                                                                                                                                                                           ## APIVersion: string
                                                                                                                                                                                                                                           ##             
                                                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                                                           ## Specifies 
                                                                                                                                                                                                                                           ## the 
                                                                                                                                                                                                                                           ## version 
                                                                                                                                                                                                                                           ## of 
                                                                                                                                                                                                                                           ## the 
                                                                                                                                                                                                                                           ## client 
                                                                                                                                                                                                                                           ## tool.
  ##   
                                                                                                                                                                                                                                                   ## Signature: string (required)
  ##   
                                                                                                                                                                                                                                                                                  ## Timestamp: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                 ## AWSAccessKeyId: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## JobId: string (required)
                                                                                                                                                                                                                                                                                                                                                     ##        
                                                                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                                                                     ## A 
                                                                                                                                                                                                                                                                                                                                                     ## unique 
                                                                                                                                                                                                                                                                                                                                                     ## identifier 
                                                                                                                                                                                                                                                                                                                                                     ## which 
                                                                                                                                                                                                                                                                                                                                                     ## refers 
                                                                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                                                                     ## a 
                                                                                                                                                                                                                                                                                                                                                     ## particular 
                                                                                                                                                                                                                                                                                                                                                     ## job.
  ##   
                                                                                                                                                                                                                                                                                                                                                            ## Version: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                         ## Action: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                     ## SignatureMethod: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## SignatureVersion: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## Operation: string (required)
  var query_402656599 = newJObject()
  add(query_402656599, "APIVersion", newJString(APIVersion))
  add(query_402656599, "Signature", newJString(Signature))
  add(query_402656599, "Timestamp", newJString(Timestamp))
  add(query_402656599, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_402656599, "JobId", newJString(JobId))
  add(query_402656599, "Version", newJString(Version))
  add(query_402656599, "Action", newJString(Action))
  add(query_402656599, "SignatureMethod", newJString(SignatureMethod))
  add(query_402656599, "SignatureVersion", newJString(SignatureVersion))
  add(query_402656599, "Operation", newJString(Operation))
  result = call_402656598.call(nil, query_402656599, nil, nil, nil)

var getGetStatus* = Call_GetGetStatus_402656584(name: "getGetStatus",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=GetStatus&Action=GetStatus",
    validator: validate_GetGetStatus_402656585, base: "/",
    makeUrl: url_GetGetStatus_402656586, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListJobs_402656634 = ref object of OpenApiRestCall_402656029
proc url_PostListJobs_402656636(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListJobs_402656635(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   Timestamp: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  ##   Action: JString (required)
  ##   SignatureMethod: JString (required)
  ##   SignatureVersion: JString (required)
  ##   Operation: JString (required)
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `Signature` field"
  var valid_402656637 = query.getOrDefault("Signature")
  valid_402656637 = validateParameter(valid_402656637, JString, required = true,
                                      default = nil)
  if valid_402656637 != nil:
    section.add "Signature", valid_402656637
  var valid_402656638 = query.getOrDefault("Timestamp")
  valid_402656638 = validateParameter(valid_402656638, JString, required = true,
                                      default = nil)
  if valid_402656638 != nil:
    section.add "Timestamp", valid_402656638
  var valid_402656639 = query.getOrDefault("AWSAccessKeyId")
  valid_402656639 = validateParameter(valid_402656639, JString, required = true,
                                      default = nil)
  if valid_402656639 != nil:
    section.add "AWSAccessKeyId", valid_402656639
  var valid_402656640 = query.getOrDefault("Version")
  valid_402656640 = validateParameter(valid_402656640, JString, required = true,
                                      default = newJString("2010-06-01"))
  if valid_402656640 != nil:
    section.add "Version", valid_402656640
  var valid_402656641 = query.getOrDefault("Action")
  valid_402656641 = validateParameter(valid_402656641, JString, required = true,
                                      default = newJString("ListJobs"))
  if valid_402656641 != nil:
    section.add "Action", valid_402656641
  var valid_402656642 = query.getOrDefault("SignatureMethod")
  valid_402656642 = validateParameter(valid_402656642, JString, required = true,
                                      default = nil)
  if valid_402656642 != nil:
    section.add "SignatureMethod", valid_402656642
  var valid_402656643 = query.getOrDefault("SignatureVersion")
  valid_402656643 = validateParameter(valid_402656643, JString, required = true,
                                      default = nil)
  if valid_402656643 != nil:
    section.add "SignatureVersion", valid_402656643
  var valid_402656644 = query.getOrDefault("Operation")
  valid_402656644 = validateParameter(valid_402656644, JString, required = true,
                                      default = newJString("ListJobs"))
  if valid_402656644 != nil:
    section.add "Operation", valid_402656644
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
                                     ##         : Specifies the JOBID to start after when listing the jobs created with your account. AWS Import/Export lists your jobs in reverse chronological order. See MaxJobs.
  ##   
                                                                                                                                                                                                                    ## MaxJobs: JInt
                                                                                                                                                                                                                    ##          
                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                    ## Sets 
                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                    ## maximum 
                                                                                                                                                                                                                    ## number 
                                                                                                                                                                                                                    ## of 
                                                                                                                                                                                                                    ## jobs 
                                                                                                                                                                                                                    ## returned 
                                                                                                                                                                                                                    ## in 
                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                    ## response. 
                                                                                                                                                                                                                    ## If 
                                                                                                                                                                                                                    ## there 
                                                                                                                                                                                                                    ## are 
                                                                                                                                                                                                                    ## additional 
                                                                                                                                                                                                                    ## jobs 
                                                                                                                                                                                                                    ## that 
                                                                                                                                                                                                                    ## were 
                                                                                                                                                                                                                    ## not 
                                                                                                                                                                                                                    ## returned 
                                                                                                                                                                                                                    ## because 
                                                                                                                                                                                                                    ## MaxJobs 
                                                                                                                                                                                                                    ## was 
                                                                                                                                                                                                                    ## exceeded, 
                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                    ## response 
                                                                                                                                                                                                                    ## contains 
                                                                                                                                                                                                                    ## &lt;IsTruncated&gt;true&lt;/IsTruncated&gt;. 
                                                                                                                                                                                                                    ## To 
                                                                                                                                                                                                                    ## return 
                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                    ## additional 
                                                                                                                                                                                                                    ## jobs, 
                                                                                                                                                                                                                    ## see 
                                                                                                                                                                                                                    ## Marker.
  ##   
                                                                                                                                                                                                                              ## APIVersion: JString
                                                                                                                                                                                                                              ##             
                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                              ## Specifies 
                                                                                                                                                                                                                              ## the 
                                                                                                                                                                                                                              ## version 
                                                                                                                                                                                                                              ## of 
                                                                                                                                                                                                                              ## the 
                                                                                                                                                                                                                              ## client 
                                                                                                                                                                                                                              ## tool.
  section = newJObject()
  var valid_402656645 = formData.getOrDefault("Marker")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "Marker", valid_402656645
  var valid_402656646 = formData.getOrDefault("MaxJobs")
  valid_402656646 = validateParameter(valid_402656646, JInt, required = false,
                                      default = nil)
  if valid_402656646 != nil:
    section.add "MaxJobs", valid_402656646
  var valid_402656647 = formData.getOrDefault("APIVersion")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "APIVersion", valid_402656647
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656648: Call_PostListJobs_402656634; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
                                                                                         ## 
  let valid = call_402656648.validator(path, query, header, formData, body, _)
  let scheme = call_402656648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656648.makeUrl(scheme.get, call_402656648.host, call_402656648.base,
                                   call_402656648.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656648, uri, valid, _)

proc call*(call_402656649: Call_PostListJobs_402656634; Signature: string;
           Timestamp: string; AWSAccessKeyId: string; SignatureMethod: string;
           SignatureVersion: string; Marker: string = ""; MaxJobs: int = 0;
           Version: string = "2010-06-01"; APIVersion: string = "";
           Action: string = "ListJobs"; Operation: string = "ListJobs"): Recallable =
  ## postListJobs
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ##   
                                                                                                                                                                                                                                                                                                               ## Marker: string
                                                                                                                                                                                                                                                                                                               ##         
                                                                                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                                                                                               ## Specifies 
                                                                                                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                                                                                                               ## JOBID 
                                                                                                                                                                                                                                                                                                               ## to 
                                                                                                                                                                                                                                                                                                               ## start 
                                                                                                                                                                                                                                                                                                               ## after 
                                                                                                                                                                                                                                                                                                               ## when 
                                                                                                                                                                                                                                                                                                               ## listing 
                                                                                                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                                                                                                               ## jobs 
                                                                                                                                                                                                                                                                                                               ## created 
                                                                                                                                                                                                                                                                                                               ## with 
                                                                                                                                                                                                                                                                                                               ## your 
                                                                                                                                                                                                                                                                                                               ## account. 
                                                                                                                                                                                                                                                                                                               ## AWS 
                                                                                                                                                                                                                                                                                                               ## Import/Export 
                                                                                                                                                                                                                                                                                                               ## lists 
                                                                                                                                                                                                                                                                                                               ## your 
                                                                                                                                                                                                                                                                                                               ## jobs 
                                                                                                                                                                                                                                                                                                               ## in 
                                                                                                                                                                                                                                                                                                               ## reverse 
                                                                                                                                                                                                                                                                                                               ## chronological 
                                                                                                                                                                                                                                                                                                               ## order. 
                                                                                                                                                                                                                                                                                                               ## See 
                                                                                                                                                                                                                                                                                                               ## MaxJobs.
  ##   
                                                                                                                                                                                                                                                                                                                          ## Signature: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                         ## Timestamp: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                        ## AWSAccessKeyId: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                            ## MaxJobs: int
                                                                                                                                                                                                                                                                                                                                                                                                                            ##          
                                                                                                                                                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## Sets 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## jobs 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## returned 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## response. 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## If 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## there 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## additional 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## jobs 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## were 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## not 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## returned 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## because 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## MaxJobs 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## was 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## exceeded, 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## response 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## contains 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## &lt;IsTruncated&gt;true&lt;/IsTruncated&gt;. 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## To 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## return 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## additional 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## jobs, 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## see 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## Marker.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                      ## Version: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## APIVersion: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## Specifies 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## version 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## client 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## tool.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## Action: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## SignatureMethod: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## SignatureVersion: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## Operation: string (required)
  var query_402656650 = newJObject()
  var formData_402656651 = newJObject()
  add(formData_402656651, "Marker", newJString(Marker))
  add(query_402656650, "Signature", newJString(Signature))
  add(query_402656650, "Timestamp", newJString(Timestamp))
  add(query_402656650, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_402656651, "MaxJobs", newJInt(MaxJobs))
  add(query_402656650, "Version", newJString(Version))
  add(formData_402656651, "APIVersion", newJString(APIVersion))
  add(query_402656650, "Action", newJString(Action))
  add(query_402656650, "SignatureMethod", newJString(SignatureMethod))
  add(query_402656650, "SignatureVersion", newJString(SignatureVersion))
  add(query_402656650, "Operation", newJString(Operation))
  result = call_402656649.call(nil, query_402656650, nil, formData_402656651,
                               nil)

var postListJobs* = Call_PostListJobs_402656634(name: "postListJobs",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=ListJobs&Action=ListJobs",
    validator: validate_PostListJobs_402656635, base: "/",
    makeUrl: url_PostListJobs_402656636, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListJobs_402656617 = ref object of OpenApiRestCall_402656029
proc url_GetListJobs_402656619(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListJobs_402656618(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   APIVersion: JString
                                  ##             : Specifies the version of the client tool.
  ##   
                                                                                            ## Signature: JString (required)
  ##   
                                                                                                                            ## Timestamp: JString (required)
  ##   
                                                                                                                                                            ## MaxJobs: JInt
                                                                                                                                                            ##          
                                                                                                                                                            ## : 
                                                                                                                                                            ## Sets 
                                                                                                                                                            ## the 
                                                                                                                                                            ## maximum 
                                                                                                                                                            ## number 
                                                                                                                                                            ## of 
                                                                                                                                                            ## jobs 
                                                                                                                                                            ## returned 
                                                                                                                                                            ## in 
                                                                                                                                                            ## the 
                                                                                                                                                            ## response. 
                                                                                                                                                            ## If 
                                                                                                                                                            ## there 
                                                                                                                                                            ## are 
                                                                                                                                                            ## additional 
                                                                                                                                                            ## jobs 
                                                                                                                                                            ## that 
                                                                                                                                                            ## were 
                                                                                                                                                            ## not 
                                                                                                                                                            ## returned 
                                                                                                                                                            ## because 
                                                                                                                                                            ## MaxJobs 
                                                                                                                                                            ## was 
                                                                                                                                                            ## exceeded, 
                                                                                                                                                            ## the 
                                                                                                                                                            ## response 
                                                                                                                                                            ## contains 
                                                                                                                                                            ## &lt;IsTruncated&gt;true&lt;/IsTruncated&gt;. 
                                                                                                                                                            ## To 
                                                                                                                                                            ## return 
                                                                                                                                                            ## the 
                                                                                                                                                            ## additional 
                                                                                                                                                            ## jobs, 
                                                                                                                                                            ## see 
                                                                                                                                                            ## Marker.
  ##   
                                                                                                                                                                      ## AWSAccessKeyId: JString (required)
  ##   
                                                                                                                                                                                                           ## Marker: JString
                                                                                                                                                                                                           ##         
                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                           ## Specifies 
                                                                                                                                                                                                           ## the 
                                                                                                                                                                                                           ## JOBID 
                                                                                                                                                                                                           ## to 
                                                                                                                                                                                                           ## start 
                                                                                                                                                                                                           ## after 
                                                                                                                                                                                                           ## when 
                                                                                                                                                                                                           ## listing 
                                                                                                                                                                                                           ## the 
                                                                                                                                                                                                           ## jobs 
                                                                                                                                                                                                           ## created 
                                                                                                                                                                                                           ## with 
                                                                                                                                                                                                           ## your 
                                                                                                                                                                                                           ## account. 
                                                                                                                                                                                                           ## AWS 
                                                                                                                                                                                                           ## Import/Export 
                                                                                                                                                                                                           ## lists 
                                                                                                                                                                                                           ## your 
                                                                                                                                                                                                           ## jobs 
                                                                                                                                                                                                           ## in 
                                                                                                                                                                                                           ## reverse 
                                                                                                                                                                                                           ## chronological 
                                                                                                                                                                                                           ## order. 
                                                                                                                                                                                                           ## See 
                                                                                                                                                                                                           ## MaxJobs.
  ##   
                                                                                                                                                                                                                      ## Version: JString (required)
  ##   
                                                                                                                                                                                                                                                    ## Action: JString (required)
  ##   
                                                                                                                                                                                                                                                                                 ## SignatureMethod: JString (required)
  ##   
                                                                                                                                                                                                                                                                                                                       ## SignatureVersion: JString (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                              ## Operation: JString (required)
  section = newJObject()
  var valid_402656620 = query.getOrDefault("APIVersion")
  valid_402656620 = validateParameter(valid_402656620, JString,
                                      required = false, default = nil)
  if valid_402656620 != nil:
    section.add "APIVersion", valid_402656620
  assert query != nil,
         "query argument is necessary due to required `Signature` field"
  var valid_402656621 = query.getOrDefault("Signature")
  valid_402656621 = validateParameter(valid_402656621, JString, required = true,
                                      default = nil)
  if valid_402656621 != nil:
    section.add "Signature", valid_402656621
  var valid_402656622 = query.getOrDefault("Timestamp")
  valid_402656622 = validateParameter(valid_402656622, JString, required = true,
                                      default = nil)
  if valid_402656622 != nil:
    section.add "Timestamp", valid_402656622
  var valid_402656623 = query.getOrDefault("MaxJobs")
  valid_402656623 = validateParameter(valid_402656623, JInt, required = false,
                                      default = nil)
  if valid_402656623 != nil:
    section.add "MaxJobs", valid_402656623
  var valid_402656624 = query.getOrDefault("AWSAccessKeyId")
  valid_402656624 = validateParameter(valid_402656624, JString, required = true,
                                      default = nil)
  if valid_402656624 != nil:
    section.add "AWSAccessKeyId", valid_402656624
  var valid_402656625 = query.getOrDefault("Marker")
  valid_402656625 = validateParameter(valid_402656625, JString,
                                      required = false, default = nil)
  if valid_402656625 != nil:
    section.add "Marker", valid_402656625
  var valid_402656626 = query.getOrDefault("Version")
  valid_402656626 = validateParameter(valid_402656626, JString, required = true,
                                      default = newJString("2010-06-01"))
  if valid_402656626 != nil:
    section.add "Version", valid_402656626
  var valid_402656627 = query.getOrDefault("Action")
  valid_402656627 = validateParameter(valid_402656627, JString, required = true,
                                      default = newJString("ListJobs"))
  if valid_402656627 != nil:
    section.add "Action", valid_402656627
  var valid_402656628 = query.getOrDefault("SignatureMethod")
  valid_402656628 = validateParameter(valid_402656628, JString, required = true,
                                      default = nil)
  if valid_402656628 != nil:
    section.add "SignatureMethod", valid_402656628
  var valid_402656629 = query.getOrDefault("SignatureVersion")
  valid_402656629 = validateParameter(valid_402656629, JString, required = true,
                                      default = nil)
  if valid_402656629 != nil:
    section.add "SignatureVersion", valid_402656629
  var valid_402656630 = query.getOrDefault("Operation")
  valid_402656630 = validateParameter(valid_402656630, JString, required = true,
                                      default = newJString("ListJobs"))
  if valid_402656630 != nil:
    section.add "Operation", valid_402656630
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656631: Call_GetListJobs_402656617; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
                                                                                         ## 
  let valid = call_402656631.validator(path, query, header, formData, body, _)
  let scheme = call_402656631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656631.makeUrl(scheme.get, call_402656631.host, call_402656631.base,
                                   call_402656631.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656631, uri, valid, _)

proc call*(call_402656632: Call_GetListJobs_402656617; Signature: string;
           Timestamp: string; AWSAccessKeyId: string; SignatureMethod: string;
           SignatureVersion: string; APIVersion: string = ""; MaxJobs: int = 0;
           Marker: string = ""; Version: string = "2010-06-01";
           Action: string = "ListJobs"; Operation: string = "ListJobs"): Recallable =
  ## getListJobs
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ##   
                                                                                                                                                                                                                                                                                                               ## APIVersion: string
                                                                                                                                                                                                                                                                                                               ##             
                                                                                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                                                                                               ## Specifies 
                                                                                                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                                                                                                               ## version 
                                                                                                                                                                                                                                                                                                               ## of 
                                                                                                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                                                                                                               ## client 
                                                                                                                                                                                                                                                                                                               ## tool.
  ##   
                                                                                                                                                                                                                                                                                                                       ## Signature: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                      ## Timestamp: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                     ## MaxJobs: int
                                                                                                                                                                                                                                                                                                                                                                                     ##          
                                                                                                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                                                                                                     ## Sets 
                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                     ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                     ## number 
                                                                                                                                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                                                                                                                                     ## jobs 
                                                                                                                                                                                                                                                                                                                                                                                     ## returned 
                                                                                                                                                                                                                                                                                                                                                                                     ## in 
                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                     ## response. 
                                                                                                                                                                                                                                                                                                                                                                                     ## If 
                                                                                                                                                                                                                                                                                                                                                                                     ## there 
                                                                                                                                                                                                                                                                                                                                                                                     ## are 
                                                                                                                                                                                                                                                                                                                                                                                     ## additional 
                                                                                                                                                                                                                                                                                                                                                                                     ## jobs 
                                                                                                                                                                                                                                                                                                                                                                                     ## that 
                                                                                                                                                                                                                                                                                                                                                                                     ## were 
                                                                                                                                                                                                                                                                                                                                                                                     ## not 
                                                                                                                                                                                                                                                                                                                                                                                     ## returned 
                                                                                                                                                                                                                                                                                                                                                                                     ## because 
                                                                                                                                                                                                                                                                                                                                                                                     ## MaxJobs 
                                                                                                                                                                                                                                                                                                                                                                                     ## was 
                                                                                                                                                                                                                                                                                                                                                                                     ## exceeded, 
                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                     ## response 
                                                                                                                                                                                                                                                                                                                                                                                     ## contains 
                                                                                                                                                                                                                                                                                                                                                                                     ## &lt;IsTruncated&gt;true&lt;/IsTruncated&gt;. 
                                                                                                                                                                                                                                                                                                                                                                                     ## To 
                                                                                                                                                                                                                                                                                                                                                                                     ## return 
                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                     ## additional 
                                                                                                                                                                                                                                                                                                                                                                                     ## jobs, 
                                                                                                                                                                                                                                                                                                                                                                                     ## see 
                                                                                                                                                                                                                                                                                                                                                                                     ## Marker.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                               ## AWSAccessKeyId: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## Marker: string
                                                                                                                                                                                                                                                                                                                                                                                                                                   ##         
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## Specifies 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## JOBID 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## start 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## after 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## when 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## listing 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## jobs 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## created 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## with 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## your 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## account. 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## AWS 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## Import/Export 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## lists 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## your 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## jobs 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## reverse 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## chronological 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## order. 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## See 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## MaxJobs.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                              ## Version: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## Action: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## SignatureMethod: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## SignatureVersion: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## Operation: string (required)
  var query_402656633 = newJObject()
  add(query_402656633, "APIVersion", newJString(APIVersion))
  add(query_402656633, "Signature", newJString(Signature))
  add(query_402656633, "Timestamp", newJString(Timestamp))
  add(query_402656633, "MaxJobs", newJInt(MaxJobs))
  add(query_402656633, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_402656633, "Marker", newJString(Marker))
  add(query_402656633, "Version", newJString(Version))
  add(query_402656633, "Action", newJString(Action))
  add(query_402656633, "SignatureMethod", newJString(SignatureMethod))
  add(query_402656633, "SignatureVersion", newJString(SignatureVersion))
  add(query_402656633, "Operation", newJString(Operation))
  result = call_402656632.call(nil, query_402656633, nil, nil, nil)

var getListJobs* = Call_GetListJobs_402656617(name: "getListJobs",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=ListJobs&Action=ListJobs",
    validator: validate_GetListJobs_402656618, base: "/",
    makeUrl: url_GetListJobs_402656619, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateJob_402656671 = ref object of OpenApiRestCall_402656029
proc url_PostUpdateJob_402656673(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateJob_402656672(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   Timestamp: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  ##   Action: JString (required)
  ##   SignatureMethod: JString (required)
  ##   SignatureVersion: JString (required)
  ##   Operation: JString (required)
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `Signature` field"
  var valid_402656674 = query.getOrDefault("Signature")
  valid_402656674 = validateParameter(valid_402656674, JString, required = true,
                                      default = nil)
  if valid_402656674 != nil:
    section.add "Signature", valid_402656674
  var valid_402656675 = query.getOrDefault("Timestamp")
  valid_402656675 = validateParameter(valid_402656675, JString, required = true,
                                      default = nil)
  if valid_402656675 != nil:
    section.add "Timestamp", valid_402656675
  var valid_402656676 = query.getOrDefault("AWSAccessKeyId")
  valid_402656676 = validateParameter(valid_402656676, JString, required = true,
                                      default = nil)
  if valid_402656676 != nil:
    section.add "AWSAccessKeyId", valid_402656676
  var valid_402656677 = query.getOrDefault("Version")
  valid_402656677 = validateParameter(valid_402656677, JString, required = true,
                                      default = newJString("2010-06-01"))
  if valid_402656677 != nil:
    section.add "Version", valid_402656677
  var valid_402656678 = query.getOrDefault("Action")
  valid_402656678 = validateParameter(valid_402656678, JString, required = true,
                                      default = newJString("UpdateJob"))
  if valid_402656678 != nil:
    section.add "Action", valid_402656678
  var valid_402656679 = query.getOrDefault("SignatureMethod")
  valid_402656679 = validateParameter(valid_402656679, JString, required = true,
                                      default = nil)
  if valid_402656679 != nil:
    section.add "SignatureMethod", valid_402656679
  var valid_402656680 = query.getOrDefault("SignatureVersion")
  valid_402656680 = validateParameter(valid_402656680, JString, required = true,
                                      default = nil)
  if valid_402656680 != nil:
    section.add "SignatureVersion", valid_402656680
  var valid_402656681 = query.getOrDefault("Operation")
  valid_402656681 = validateParameter(valid_402656681, JString, required = true,
                                      default = newJString("UpdateJob"))
  if valid_402656681 != nil:
    section.add "Operation", valid_402656681
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   JobType: JString (required)
                                     ##          : Specifies whether the job to initiate is an import or export job.
  ##   
                                                                                                                    ## ValidateOnly: JBool (required)
                                                                                                                    ##               
                                                                                                                    ## : 
                                                                                                                    ## Validate 
                                                                                                                    ## the 
                                                                                                                    ## manifest 
                                                                                                                    ## and 
                                                                                                                    ## parameter 
                                                                                                                    ## values 
                                                                                                                    ## in 
                                                                                                                    ## the 
                                                                                                                    ## request 
                                                                                                                    ## but 
                                                                                                                    ## do 
                                                                                                                    ## not 
                                                                                                                    ## actually 
                                                                                                                    ## create 
                                                                                                                    ## a 
                                                                                                                    ## job.
  ##   
                                                                                                                           ## Manifest: JString (required)
                                                                                                                           ##           
                                                                                                                           ## : 
                                                                                                                           ## The 
                                                                                                                           ## UTF-8 
                                                                                                                           ## encoded 
                                                                                                                           ## text 
                                                                                                                           ## of 
                                                                                                                           ## the 
                                                                                                                           ## manifest 
                                                                                                                           ## file.
  ##   
                                                                                                                                   ## APIVersion: JString
                                                                                                                                   ##             
                                                                                                                                   ## : 
                                                                                                                                   ## Specifies 
                                                                                                                                   ## the 
                                                                                                                                   ## version 
                                                                                                                                   ## of 
                                                                                                                                   ## the 
                                                                                                                                   ## client 
                                                                                                                                   ## tool.
  ##   
                                                                                                                                           ## JobId: JString (required)
                                                                                                                                           ##        
                                                                                                                                           ## : 
                                                                                                                                           ## A 
                                                                                                                                           ## unique 
                                                                                                                                           ## identifier 
                                                                                                                                           ## which 
                                                                                                                                           ## refers 
                                                                                                                                           ## to 
                                                                                                                                           ## a 
                                                                                                                                           ## particular 
                                                                                                                                           ## job.
  section = newJObject()
  var valid_402656682 = formData.getOrDefault("JobType")
  valid_402656682 = validateParameter(valid_402656682, JString, required = true,
                                      default = newJString("Import"))
  if valid_402656682 != nil:
    section.add "JobType", valid_402656682
  var valid_402656683 = formData.getOrDefault("ValidateOnly")
  valid_402656683 = validateParameter(valid_402656683, JBool, required = true,
                                      default = nil)
  if valid_402656683 != nil:
    section.add "ValidateOnly", valid_402656683
  var valid_402656684 = formData.getOrDefault("Manifest")
  valid_402656684 = validateParameter(valid_402656684, JString, required = true,
                                      default = nil)
  if valid_402656684 != nil:
    section.add "Manifest", valid_402656684
  var valid_402656685 = formData.getOrDefault("APIVersion")
  valid_402656685 = validateParameter(valid_402656685, JString,
                                      required = false, default = nil)
  if valid_402656685 != nil:
    section.add "APIVersion", valid_402656685
  var valid_402656686 = formData.getOrDefault("JobId")
  valid_402656686 = validateParameter(valid_402656686, JString, required = true,
                                      default = nil)
  if valid_402656686 != nil:
    section.add "JobId", valid_402656686
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656687: Call_PostUpdateJob_402656671; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
                                                                                         ## 
  let valid = call_402656687.validator(path, query, header, formData, body, _)
  let scheme = call_402656687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656687.makeUrl(scheme.get, call_402656687.host, call_402656687.base,
                                   call_402656687.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656687, uri, valid, _)

proc call*(call_402656688: Call_PostUpdateJob_402656671; Signature: string;
           Timestamp: string; ValidateOnly: bool; AWSAccessKeyId: string;
           Manifest: string; JobId: string; SignatureMethod: string;
           SignatureVersion: string; JobType: string = "Import";
           Version: string = "2010-06-01"; APIVersion: string = "";
           Action: string = "UpdateJob"; Operation: string = "UpdateJob"): Recallable =
  ## postUpdateJob
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ##   
                                                                                                                                                                                                                                                                                                                                                    ## JobType: string (required)
                                                                                                                                                                                                                                                                                                                                                    ##          
                                                                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                                                                    ## Specifies 
                                                                                                                                                                                                                                                                                                                                                    ## whether 
                                                                                                                                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                                                                                                                                    ## job 
                                                                                                                                                                                                                                                                                                                                                    ## to 
                                                                                                                                                                                                                                                                                                                                                    ## initiate 
                                                                                                                                                                                                                                                                                                                                                    ## is 
                                                                                                                                                                                                                                                                                                                                                    ## an 
                                                                                                                                                                                                                                                                                                                                                    ## import 
                                                                                                                                                                                                                                                                                                                                                    ## or 
                                                                                                                                                                                                                                                                                                                                                    ## export 
                                                                                                                                                                                                                                                                                                                                                    ## job.
  ##   
                                                                                                                                                                                                                                                                                                                                                           ## Signature: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                          ## Timestamp: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                         ## ValidateOnly: bool (required)
                                                                                                                                                                                                                                                                                                                                                                                                                         ##               
                                                                                                                                                                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                         ## Validate 
                                                                                                                                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                         ## manifest 
                                                                                                                                                                                                                                                                                                                                                                                                                         ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                         ## parameter 
                                                                                                                                                                                                                                                                                                                                                                                                                         ## values 
                                                                                                                                                                                                                                                                                                                                                                                                                         ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                         ## request 
                                                                                                                                                                                                                                                                                                                                                                                                                         ## but 
                                                                                                                                                                                                                                                                                                                                                                                                                         ## do 
                                                                                                                                                                                                                                                                                                                                                                                                                         ## not 
                                                                                                                                                                                                                                                                                                                                                                                                                         ## actually 
                                                                                                                                                                                                                                                                                                                                                                                                                         ## create 
                                                                                                                                                                                                                                                                                                                                                                                                                         ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                         ## job.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                ## AWSAccessKeyId: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## Manifest: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ##           
                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## UTF-8 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## encoded 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## text 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## manifest 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## file.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## Version: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## APIVersion: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## Specifies 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## version 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## client 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## tool.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## Action: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## JobId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ##        
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## A 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## unique 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## identifier 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## which 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## refers 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## particular 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## job.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## SignatureMethod: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## SignatureVersion: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## Operation: string (required)
  var query_402656689 = newJObject()
  var formData_402656690 = newJObject()
  add(formData_402656690, "JobType", newJString(JobType))
  add(query_402656689, "Signature", newJString(Signature))
  add(query_402656689, "Timestamp", newJString(Timestamp))
  add(formData_402656690, "ValidateOnly", newJBool(ValidateOnly))
  add(query_402656689, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_402656690, "Manifest", newJString(Manifest))
  add(query_402656689, "Version", newJString(Version))
  add(formData_402656690, "APIVersion", newJString(APIVersion))
  add(query_402656689, "Action", newJString(Action))
  add(formData_402656690, "JobId", newJString(JobId))
  add(query_402656689, "SignatureMethod", newJString(SignatureMethod))
  add(query_402656689, "SignatureVersion", newJString(SignatureVersion))
  add(query_402656689, "Operation", newJString(Operation))
  result = call_402656688.call(nil, query_402656689, nil, formData_402656690,
                               nil)

var postUpdateJob* = Call_PostUpdateJob_402656671(name: "postUpdateJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=UpdateJob&Action=UpdateJob",
    validator: validate_PostUpdateJob_402656672, base: "/",
    makeUrl: url_PostUpdateJob_402656673, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateJob_402656652 = ref object of OpenApiRestCall_402656029
proc url_GetUpdateJob_402656654(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateJob_402656653(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   APIVersion: JString
                                  ##             : Specifies the version of the client tool.
  ##   
                                                                                            ## Signature: JString (required)
  ##   
                                                                                                                            ## Timestamp: JString (required)
  ##   
                                                                                                                                                            ## ValidateOnly: JBool (required)
                                                                                                                                                            ##               
                                                                                                                                                            ## : 
                                                                                                                                                            ## Validate 
                                                                                                                                                            ## the 
                                                                                                                                                            ## manifest 
                                                                                                                                                            ## and 
                                                                                                                                                            ## parameter 
                                                                                                                                                            ## values 
                                                                                                                                                            ## in 
                                                                                                                                                            ## the 
                                                                                                                                                            ## request 
                                                                                                                                                            ## but 
                                                                                                                                                            ## do 
                                                                                                                                                            ## not 
                                                                                                                                                            ## actually 
                                                                                                                                                            ## create 
                                                                                                                                                            ## a 
                                                                                                                                                            ## job.
  ##   
                                                                                                                                                                   ## AWSAccessKeyId: JString (required)
  ##   
                                                                                                                                                                                                        ## JobId: JString (required)
                                                                                                                                                                                                        ##        
                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                        ## A 
                                                                                                                                                                                                        ## unique 
                                                                                                                                                                                                        ## identifier 
                                                                                                                                                                                                        ## which 
                                                                                                                                                                                                        ## refers 
                                                                                                                                                                                                        ## to 
                                                                                                                                                                                                        ## a 
                                                                                                                                                                                                        ## particular 
                                                                                                                                                                                                        ## job.
  ##   
                                                                                                                                                                                                               ## Manifest: JString (required)
                                                                                                                                                                                                               ##           
                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                               ## The 
                                                                                                                                                                                                               ## UTF-8 
                                                                                                                                                                                                               ## encoded 
                                                                                                                                                                                                               ## text 
                                                                                                                                                                                                               ## of 
                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                               ## manifest 
                                                                                                                                                                                                               ## file.
  ##   
                                                                                                                                                                                                                       ## Version: JString (required)
  ##   
                                                                                                                                                                                                                                                     ## Action: JString (required)
  ##   
                                                                                                                                                                                                                                                                                  ## JobType: JString (required)
                                                                                                                                                                                                                                                                                  ##          
                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                  ## Specifies 
                                                                                                                                                                                                                                                                                  ## whether 
                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                  ## job 
                                                                                                                                                                                                                                                                                  ## to 
                                                                                                                                                                                                                                                                                  ## initiate 
                                                                                                                                                                                                                                                                                  ## is 
                                                                                                                                                                                                                                                                                  ## an 
                                                                                                                                                                                                                                                                                  ## import 
                                                                                                                                                                                                                                                                                  ## or 
                                                                                                                                                                                                                                                                                  ## export 
                                                                                                                                                                                                                                                                                  ## job.
  ##   
                                                                                                                                                                                                                                                                                         ## SignatureMethod: JString (required)
  ##   
                                                                                                                                                                                                                                                                                                                               ## SignatureVersion: JString (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                      ## Operation: JString (required)
  section = newJObject()
  var valid_402656655 = query.getOrDefault("APIVersion")
  valid_402656655 = validateParameter(valid_402656655, JString,
                                      required = false, default = nil)
  if valid_402656655 != nil:
    section.add "APIVersion", valid_402656655
  assert query != nil,
         "query argument is necessary due to required `Signature` field"
  var valid_402656656 = query.getOrDefault("Signature")
  valid_402656656 = validateParameter(valid_402656656, JString, required = true,
                                      default = nil)
  if valid_402656656 != nil:
    section.add "Signature", valid_402656656
  var valid_402656657 = query.getOrDefault("Timestamp")
  valid_402656657 = validateParameter(valid_402656657, JString, required = true,
                                      default = nil)
  if valid_402656657 != nil:
    section.add "Timestamp", valid_402656657
  var valid_402656658 = query.getOrDefault("ValidateOnly")
  valid_402656658 = validateParameter(valid_402656658, JBool, required = true,
                                      default = nil)
  if valid_402656658 != nil:
    section.add "ValidateOnly", valid_402656658
  var valid_402656659 = query.getOrDefault("AWSAccessKeyId")
  valid_402656659 = validateParameter(valid_402656659, JString, required = true,
                                      default = nil)
  if valid_402656659 != nil:
    section.add "AWSAccessKeyId", valid_402656659
  var valid_402656660 = query.getOrDefault("JobId")
  valid_402656660 = validateParameter(valid_402656660, JString, required = true,
                                      default = nil)
  if valid_402656660 != nil:
    section.add "JobId", valid_402656660
  var valid_402656661 = query.getOrDefault("Manifest")
  valid_402656661 = validateParameter(valid_402656661, JString, required = true,
                                      default = nil)
  if valid_402656661 != nil:
    section.add "Manifest", valid_402656661
  var valid_402656662 = query.getOrDefault("Version")
  valid_402656662 = validateParameter(valid_402656662, JString, required = true,
                                      default = newJString("2010-06-01"))
  if valid_402656662 != nil:
    section.add "Version", valid_402656662
  var valid_402656663 = query.getOrDefault("Action")
  valid_402656663 = validateParameter(valid_402656663, JString, required = true,
                                      default = newJString("UpdateJob"))
  if valid_402656663 != nil:
    section.add "Action", valid_402656663
  var valid_402656664 = query.getOrDefault("JobType")
  valid_402656664 = validateParameter(valid_402656664, JString, required = true,
                                      default = newJString("Import"))
  if valid_402656664 != nil:
    section.add "JobType", valid_402656664
  var valid_402656665 = query.getOrDefault("SignatureMethod")
  valid_402656665 = validateParameter(valid_402656665, JString, required = true,
                                      default = nil)
  if valid_402656665 != nil:
    section.add "SignatureMethod", valid_402656665
  var valid_402656666 = query.getOrDefault("SignatureVersion")
  valid_402656666 = validateParameter(valid_402656666, JString, required = true,
                                      default = nil)
  if valid_402656666 != nil:
    section.add "SignatureVersion", valid_402656666
  var valid_402656667 = query.getOrDefault("Operation")
  valid_402656667 = validateParameter(valid_402656667, JString, required = true,
                                      default = newJString("UpdateJob"))
  if valid_402656667 != nil:
    section.add "Operation", valid_402656667
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656668: Call_GetUpdateJob_402656652; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
                                                                                         ## 
  let valid = call_402656668.validator(path, query, header, formData, body, _)
  let scheme = call_402656668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656668.makeUrl(scheme.get, call_402656668.host, call_402656668.base,
                                   call_402656668.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656668, uri, valid, _)

proc call*(call_402656669: Call_GetUpdateJob_402656652; Signature: string;
           Timestamp: string; ValidateOnly: bool; AWSAccessKeyId: string;
           JobId: string; Manifest: string; SignatureMethod: string;
           SignatureVersion: string; APIVersion: string = "";
           Version: string = "2010-06-01"; Action: string = "UpdateJob";
           JobType: string = "Import"; Operation: string = "UpdateJob"): Recallable =
  ## getUpdateJob
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ##   
                                                                                                                                                                                                                                                                                                                                                    ## APIVersion: string
                                                                                                                                                                                                                                                                                                                                                    ##             
                                                                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                                                                    ## Specifies 
                                                                                                                                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                                                                                                                                    ## version 
                                                                                                                                                                                                                                                                                                                                                    ## of 
                                                                                                                                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                                                                                                                                    ## client 
                                                                                                                                                                                                                                                                                                                                                    ## tool.
  ##   
                                                                                                                                                                                                                                                                                                                                                            ## Signature: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                           ## Timestamp: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                          ## ValidateOnly: bool (required)
                                                                                                                                                                                                                                                                                                                                                                                                                          ##               
                                                                                                                                                                                                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## Validate 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## manifest 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## parameter 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## values 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## request 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## but 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## do 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## not 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## actually 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## create 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## job.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                 ## AWSAccessKeyId: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## JobId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ##        
                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## A 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## unique 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## identifier 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## which 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## refers 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## particular 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## job.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## Manifest: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ##           
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## UTF-8 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## encoded 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## text 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## manifest 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## file.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## Version: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## Action: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## JobType: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ##          
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## Specifies 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## whether 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## job 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## initiate 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## an 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## import 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## or 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## export 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## job.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## SignatureMethod: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## SignatureVersion: string (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## Operation: string (required)
  var query_402656670 = newJObject()
  add(query_402656670, "APIVersion", newJString(APIVersion))
  add(query_402656670, "Signature", newJString(Signature))
  add(query_402656670, "Timestamp", newJString(Timestamp))
  add(query_402656670, "ValidateOnly", newJBool(ValidateOnly))
  add(query_402656670, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_402656670, "JobId", newJString(JobId))
  add(query_402656670, "Manifest", newJString(Manifest))
  add(query_402656670, "Version", newJString(Version))
  add(query_402656670, "Action", newJString(Action))
  add(query_402656670, "JobType", newJString(JobType))
  add(query_402656670, "SignatureMethod", newJString(SignatureMethod))
  add(query_402656670, "SignatureVersion", newJString(SignatureVersion))
  add(query_402656670, "Operation", newJString(Operation))
  result = call_402656669.call(nil, query_402656670, nil, nil, nil)

var getUpdateJob* = Call_GetUpdateJob_402656652(name: "getUpdateJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=UpdateJob&Action=UpdateJob",
    validator: validate_GetUpdateJob_402656653, base: "/",
    makeUrl: url_GetUpdateJob_402656654, schemes: {Scheme.Https, Scheme.Http})
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