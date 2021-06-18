
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS IoT Jobs Data Plane
## version: 2017-09-29
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>AWS IoT Jobs is a service that allows you to define a set of jobs — remote operations that are sent to and executed on one or more devices connected to AWS IoT. For example, you can define a job that instructs a set of devices to download and install application or firmware updates, reboot, rotate certificates, or perform remote troubleshooting operations.</p> <p> To create a job, you make a job document which is a description of the remote operations to be performed, and you specify a list of targets that should perform the operations. The targets can be individual things, thing groups or both.</p> <p> AWS IoT Jobs sends a message to inform the targets that a job is available. The target starts the execution of the job by downloading the job document, performing the operations it specifies, and reporting its progress to AWS IoT. The Jobs service provides commands to track the progress of a job on a specific target and for all the targets of the job</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/iot/
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "data.jobs.iot.ap-northeast-1.amazonaws.com", "ap-southeast-1": "data.jobs.iot.ap-southeast-1.amazonaws.com", "us-west-2": "data.jobs.iot.us-west-2.amazonaws.com", "eu-west-2": "data.jobs.iot.eu-west-2.amazonaws.com", "ap-northeast-3": "data.jobs.iot.ap-northeast-3.amazonaws.com", "eu-central-1": "data.jobs.iot.eu-central-1.amazonaws.com", "us-east-2": "data.jobs.iot.us-east-2.amazonaws.com", "us-east-1": "data.jobs.iot.us-east-1.amazonaws.com", "cn-northwest-1": "data.jobs.iot.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "data.jobs.iot.ap-south-1.amazonaws.com", "eu-north-1": "data.jobs.iot.eu-north-1.amazonaws.com", "ap-northeast-2": "data.jobs.iot.ap-northeast-2.amazonaws.com", "us-west-1": "data.jobs.iot.us-west-1.amazonaws.com", "us-gov-east-1": "data.jobs.iot.us-gov-east-1.amazonaws.com", "eu-west-3": "data.jobs.iot.eu-west-3.amazonaws.com", "cn-north-1": "data.jobs.iot.cn-north-1.amazonaws.com.cn", "sa-east-1": "data.jobs.iot.sa-east-1.amazonaws.com", "eu-west-1": "data.jobs.iot.eu-west-1.amazonaws.com", "us-gov-west-1": "data.jobs.iot.us-gov-west-1.amazonaws.com", "ap-southeast-2": "data.jobs.iot.ap-southeast-2.amazonaws.com", "ca-central-1": "data.jobs.iot.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "data.jobs.iot.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "data.jobs.iot.ap-southeast-1.amazonaws.com",
      "us-west-2": "data.jobs.iot.us-west-2.amazonaws.com",
      "eu-west-2": "data.jobs.iot.eu-west-2.amazonaws.com",
      "ap-northeast-3": "data.jobs.iot.ap-northeast-3.amazonaws.com",
      "eu-central-1": "data.jobs.iot.eu-central-1.amazonaws.com",
      "us-east-2": "data.jobs.iot.us-east-2.amazonaws.com",
      "us-east-1": "data.jobs.iot.us-east-1.amazonaws.com",
      "cn-northwest-1": "data.jobs.iot.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "data.jobs.iot.ap-south-1.amazonaws.com",
      "eu-north-1": "data.jobs.iot.eu-north-1.amazonaws.com",
      "ap-northeast-2": "data.jobs.iot.ap-northeast-2.amazonaws.com",
      "us-west-1": "data.jobs.iot.us-west-1.amazonaws.com",
      "us-gov-east-1": "data.jobs.iot.us-gov-east-1.amazonaws.com",
      "eu-west-3": "data.jobs.iot.eu-west-3.amazonaws.com",
      "cn-north-1": "data.jobs.iot.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "data.jobs.iot.sa-east-1.amazonaws.com",
      "eu-west-1": "data.jobs.iot.eu-west-1.amazonaws.com",
      "us-gov-west-1": "data.jobs.iot.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "data.jobs.iot.ap-southeast-2.amazonaws.com",
      "ca-central-1": "data.jobs.iot.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "iot-jobs-data"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_UpdateJobExecution_402656485 = ref object of OpenApiRestCall_402656038
proc url_UpdateJobExecution_402656487(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "thingName" in path, "`thingName` is a required path parameter"
  assert "jobId" in path, "`jobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/things/"),
                 (kind: VariableSegment, value: "thingName"),
                 (kind: ConstantSegment, value: "/jobs/"),
                 (kind: VariableSegment, value: "jobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateJobExecution_402656486(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the status of a job execution.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   jobId: JString (required)
                                 ##        : The unique identifier assigned to this job when it was created.
  ##   
                                                                                                            ## thingName: JString (required)
                                                                                                            ##            
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## name 
                                                                                                            ## of 
                                                                                                            ## the 
                                                                                                            ## thing 
                                                                                                            ## associated 
                                                                                                            ## with 
                                                                                                            ## the 
                                                                                                            ## device.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `jobId` field"
  var valid_402656488 = path.getOrDefault("jobId")
  valid_402656488 = validateParameter(valid_402656488, JString, required = true,
                                      default = nil)
  if valid_402656488 != nil:
    section.add "jobId", valid_402656488
  var valid_402656489 = path.getOrDefault("thingName")
  valid_402656489 = validateParameter(valid_402656489, JString, required = true,
                                      default = nil)
  if valid_402656489 != nil:
    section.add "thingName", valid_402656489
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
  var valid_402656490 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656490 = validateParameter(valid_402656490, JString,
                                      required = false, default = nil)
  if valid_402656490 != nil:
    section.add "X-Amz-Security-Token", valid_402656490
  var valid_402656491 = header.getOrDefault("X-Amz-Signature")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-Signature", valid_402656491
  var valid_402656492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656492 = validateParameter(valid_402656492, JString,
                                      required = false, default = nil)
  if valid_402656492 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Algorithm", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Date")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Date", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Credential")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Credential", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656496
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

proc call*(call_402656498: Call_UpdateJobExecution_402656485;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the status of a job execution.
                                                                                         ## 
  let valid = call_402656498.validator(path, query, header, formData, body, _)
  let scheme = call_402656498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656498.makeUrl(scheme.get, call_402656498.host, call_402656498.base,
                                   call_402656498.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656498, uri, valid, _)

proc call*(call_402656499: Call_UpdateJobExecution_402656485; jobId: string;
           body: JsonNode; thingName: string): Recallable =
  ## updateJobExecution
  ## Updates the status of a job execution.
  ##   jobId: string (required)
                                           ##        : The unique identifier assigned to this job when it was created.
  ##   
                                                                                                                      ## body: JObject (required)
  ##   
                                                                                                                                                 ## thingName: string (required)
                                                                                                                                                 ##            
                                                                                                                                                 ## : 
                                                                                                                                                 ## The 
                                                                                                                                                 ## name 
                                                                                                                                                 ## of 
                                                                                                                                                 ## the 
                                                                                                                                                 ## thing 
                                                                                                                                                 ## associated 
                                                                                                                                                 ## with 
                                                                                                                                                 ## the 
                                                                                                                                                 ## device.
  var path_402656500 = newJObject()
  var body_402656501 = newJObject()
  add(path_402656500, "jobId", newJString(jobId))
  if body != nil:
    body_402656501 = body
  add(path_402656500, "thingName", newJString(thingName))
  result = call_402656499.call(path_402656500, nil, nil, nil, body_402656501)

var updateJobExecution* = Call_UpdateJobExecution_402656485(
    name: "updateJobExecution", meth: HttpMethod.HttpPost,
    host: "data.jobs.iot.amazonaws.com",
    route: "/things/{thingName}/jobs/{jobId}",
    validator: validate_UpdateJobExecution_402656486, base: "/",
    makeUrl: url_UpdateJobExecution_402656487,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJobExecution_402656288 = ref object of OpenApiRestCall_402656038
proc url_DescribeJobExecution_402656290(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "thingName" in path, "`thingName` is a required path parameter"
  assert "jobId" in path, "`jobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/things/"),
                 (kind: VariableSegment, value: "thingName"),
                 (kind: ConstantSegment, value: "/jobs/"),
                 (kind: VariableSegment, value: "jobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeJobExecution_402656289(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets details of a job execution.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   jobId: JString (required)
                                 ##        : The unique identifier assigned to this job when it was created.
  ##   
                                                                                                            ## thingName: JString (required)
                                                                                                            ##            
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## thing 
                                                                                                            ## name 
                                                                                                            ## associated 
                                                                                                            ## with 
                                                                                                            ## the 
                                                                                                            ## device 
                                                                                                            ## the 
                                                                                                            ## job 
                                                                                                            ## execution 
                                                                                                            ## is 
                                                                                                            ## running 
                                                                                                            ## on.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `jobId` field"
  var valid_402656380 = path.getOrDefault("jobId")
  valid_402656380 = validateParameter(valid_402656380, JString, required = true,
                                      default = nil)
  if valid_402656380 != nil:
    section.add "jobId", valid_402656380
  var valid_402656381 = path.getOrDefault("thingName")
  valid_402656381 = validateParameter(valid_402656381, JString, required = true,
                                      default = nil)
  if valid_402656381 != nil:
    section.add "thingName", valid_402656381
  result.add "path", section
  ## parameters in `query` object:
  ##   executionNumber: JInt
                                  ##                  : Optional. A number that identifies a particular job execution on a particular device. If not specified, the latest job execution is returned.
  ##   
                                                                                                                                                                                                     ## includeJobDocument: JBool
                                                                                                                                                                                                     ##                     
                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                     ## Optional. 
                                                                                                                                                                                                     ## When 
                                                                                                                                                                                                     ## set 
                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                     ## true, 
                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                     ## response 
                                                                                                                                                                                                     ## contains 
                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                     ## job 
                                                                                                                                                                                                     ## document. 
                                                                                                                                                                                                     ## The 
                                                                                                                                                                                                     ## default 
                                                                                                                                                                                                     ## is 
                                                                                                                                                                                                     ## false.
  section = newJObject()
  var valid_402656382 = query.getOrDefault("executionNumber")
  valid_402656382 = validateParameter(valid_402656382, JInt, required = false,
                                      default = nil)
  if valid_402656382 != nil:
    section.add "executionNumber", valid_402656382
  var valid_402656383 = query.getOrDefault("includeJobDocument")
  valid_402656383 = validateParameter(valid_402656383, JBool, required = false,
                                      default = nil)
  if valid_402656383 != nil:
    section.add "includeJobDocument", valid_402656383
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
  var valid_402656384 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656384 = validateParameter(valid_402656384, JString,
                                      required = false, default = nil)
  if valid_402656384 != nil:
    section.add "X-Amz-Security-Token", valid_402656384
  var valid_402656385 = header.getOrDefault("X-Amz-Signature")
  valid_402656385 = validateParameter(valid_402656385, JString,
                                      required = false, default = nil)
  if valid_402656385 != nil:
    section.add "X-Amz-Signature", valid_402656385
  var valid_402656386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656386 = validateParameter(valid_402656386, JString,
                                      required = false, default = nil)
  if valid_402656386 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656386
  var valid_402656387 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-Algorithm", valid_402656387
  var valid_402656388 = header.getOrDefault("X-Amz-Date")
  valid_402656388 = validateParameter(valid_402656388, JString,
                                      required = false, default = nil)
  if valid_402656388 != nil:
    section.add "X-Amz-Date", valid_402656388
  var valid_402656389 = header.getOrDefault("X-Amz-Credential")
  valid_402656389 = validateParameter(valid_402656389, JString,
                                      required = false, default = nil)
  if valid_402656389 != nil:
    section.add "X-Amz-Credential", valid_402656389
  var valid_402656390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656390 = validateParameter(valid_402656390, JString,
                                      required = false, default = nil)
  if valid_402656390 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656404: Call_DescribeJobExecution_402656288;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets details of a job execution.
                                                                                         ## 
  let valid = call_402656404.validator(path, query, header, formData, body, _)
  let scheme = call_402656404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656404.makeUrl(scheme.get, call_402656404.host, call_402656404.base,
                                   call_402656404.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656404, uri, valid, _)

proc call*(call_402656453: Call_DescribeJobExecution_402656288; jobId: string;
           thingName: string; executionNumber: int = 0;
           includeJobDocument: bool = false): Recallable =
  ## describeJobExecution
  ## Gets details of a job execution.
  ##   jobId: string (required)
                                     ##        : The unique identifier assigned to this job when it was created.
  ##   
                                                                                                                ## thingName: string (required)
                                                                                                                ##            
                                                                                                                ## : 
                                                                                                                ## The 
                                                                                                                ## thing 
                                                                                                                ## name 
                                                                                                                ## associated 
                                                                                                                ## with 
                                                                                                                ## the 
                                                                                                                ## device 
                                                                                                                ## the 
                                                                                                                ## job 
                                                                                                                ## execution 
                                                                                                                ## is 
                                                                                                                ## running 
                                                                                                                ## on.
  ##   
                                                                                                                      ## executionNumber: int
                                                                                                                      ##                  
                                                                                                                      ## : 
                                                                                                                      ## Optional. 
                                                                                                                      ## A 
                                                                                                                      ## number 
                                                                                                                      ## that 
                                                                                                                      ## identifies 
                                                                                                                      ## a 
                                                                                                                      ## particular 
                                                                                                                      ## job 
                                                                                                                      ## execution 
                                                                                                                      ## on 
                                                                                                                      ## a 
                                                                                                                      ## particular 
                                                                                                                      ## device. 
                                                                                                                      ## If 
                                                                                                                      ## not 
                                                                                                                      ## specified, 
                                                                                                                      ## the 
                                                                                                                      ## latest 
                                                                                                                      ## job 
                                                                                                                      ## execution 
                                                                                                                      ## is 
                                                                                                                      ## returned.
  ##   
                                                                                                                                  ## includeJobDocument: bool
                                                                                                                                  ##                     
                                                                                                                                  ## : 
                                                                                                                                  ## Optional. 
                                                                                                                                  ## When 
                                                                                                                                  ## set 
                                                                                                                                  ## to 
                                                                                                                                  ## true, 
                                                                                                                                  ## the 
                                                                                                                                  ## response 
                                                                                                                                  ## contains 
                                                                                                                                  ## the 
                                                                                                                                  ## job 
                                                                                                                                  ## document. 
                                                                                                                                  ## The 
                                                                                                                                  ## default 
                                                                                                                                  ## is 
                                                                                                                                  ## false.
  var path_402656454 = newJObject()
  var query_402656456 = newJObject()
  add(path_402656454, "jobId", newJString(jobId))
  add(path_402656454, "thingName", newJString(thingName))
  add(query_402656456, "executionNumber", newJInt(executionNumber))
  add(query_402656456, "includeJobDocument", newJBool(includeJobDocument))
  result = call_402656453.call(path_402656454, query_402656456, nil, nil, nil)

var describeJobExecution* = Call_DescribeJobExecution_402656288(
    name: "describeJobExecution", meth: HttpMethod.HttpGet,
    host: "data.jobs.iot.amazonaws.com",
    route: "/things/{thingName}/jobs/{jobId}",
    validator: validate_DescribeJobExecution_402656289, base: "/",
    makeUrl: url_DescribeJobExecution_402656290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPendingJobExecutions_402656502 = ref object of OpenApiRestCall_402656038
proc url_GetPendingJobExecutions_402656504(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "thingName" in path, "`thingName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/things/"),
                 (kind: VariableSegment, value: "thingName"),
                 (kind: ConstantSegment, value: "/jobs")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetPendingJobExecutions_402656503(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the list of all jobs for a thing that are not in a terminal status.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   thingName: JString (required)
                                 ##            : The name of the thing that is executing the job.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `thingName` field"
  var valid_402656505 = path.getOrDefault("thingName")
  valid_402656505 = validateParameter(valid_402656505, JString, required = true,
                                      default = nil)
  if valid_402656505 != nil:
    section.add "thingName", valid_402656505
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
  var valid_402656506 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-Security-Token", valid_402656506
  var valid_402656507 = header.getOrDefault("X-Amz-Signature")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Signature", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Algorithm", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Date")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Date", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Credential")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Credential", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656513: Call_GetPendingJobExecutions_402656502;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the list of all jobs for a thing that are not in a terminal status.
                                                                                         ## 
  let valid = call_402656513.validator(path, query, header, formData, body, _)
  let scheme = call_402656513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656513.makeUrl(scheme.get, call_402656513.host, call_402656513.base,
                                   call_402656513.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656513, uri, valid, _)

proc call*(call_402656514: Call_GetPendingJobExecutions_402656502;
           thingName: string): Recallable =
  ## getPendingJobExecutions
  ## Gets the list of all jobs for a thing that are not in a terminal status.
  ##   
                                                                             ## thingName: string (required)
                                                                             ##            
                                                                             ## : 
                                                                             ## The 
                                                                             ## name 
                                                                             ## of 
                                                                             ## the 
                                                                             ## thing 
                                                                             ## that 
                                                                             ## is 
                                                                             ## executing 
                                                                             ## the 
                                                                             ## job.
  var path_402656515 = newJObject()
  add(path_402656515, "thingName", newJString(thingName))
  result = call_402656514.call(path_402656515, nil, nil, nil, nil)

var getPendingJobExecutions* = Call_GetPendingJobExecutions_402656502(
    name: "getPendingJobExecutions", meth: HttpMethod.HttpGet,
    host: "data.jobs.iot.amazonaws.com", route: "/things/{thingName}/jobs",
    validator: validate_GetPendingJobExecutions_402656503, base: "/",
    makeUrl: url_GetPendingJobExecutions_402656504,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartNextPendingJobExecution_402656516 = ref object of OpenApiRestCall_402656038
proc url_StartNextPendingJobExecution_402656518(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "thingName" in path, "`thingName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/things/"),
                 (kind: VariableSegment, value: "thingName"),
                 (kind: ConstantSegment, value: "/jobs/$next")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartNextPendingJobExecution_402656517(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Gets and starts the next pending (status IN_PROGRESS or QUEUED) job execution for a thing.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   thingName: JString (required)
                                 ##            : The name of the thing associated with the device.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `thingName` field"
  var valid_402656519 = path.getOrDefault("thingName")
  valid_402656519 = validateParameter(valid_402656519, JString, required = true,
                                      default = nil)
  if valid_402656519 != nil:
    section.add "thingName", valid_402656519
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
  var valid_402656520 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-Security-Token", valid_402656520
  var valid_402656521 = header.getOrDefault("X-Amz-Signature")
  valid_402656521 = validateParameter(valid_402656521, JString,
                                      required = false, default = nil)
  if valid_402656521 != nil:
    section.add "X-Amz-Signature", valid_402656521
  var valid_402656522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656522 = validateParameter(valid_402656522, JString,
                                      required = false, default = nil)
  if valid_402656522 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Algorithm", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Date")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Date", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Credential")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Credential", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656526
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

proc call*(call_402656528: Call_StartNextPendingJobExecution_402656516;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets and starts the next pending (status IN_PROGRESS or QUEUED) job execution for a thing.
                                                                                         ## 
  let valid = call_402656528.validator(path, query, header, formData, body, _)
  let scheme = call_402656528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656528.makeUrl(scheme.get, call_402656528.host, call_402656528.base,
                                   call_402656528.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656528, uri, valid, _)

proc call*(call_402656529: Call_StartNextPendingJobExecution_402656516;
           body: JsonNode; thingName: string): Recallable =
  ## startNextPendingJobExecution
  ## Gets and starts the next pending (status IN_PROGRESS or QUEUED) job execution for a thing.
  ##   
                                                                                               ## body: JObject (required)
  ##   
                                                                                                                          ## thingName: string (required)
                                                                                                                          ##            
                                                                                                                          ## : 
                                                                                                                          ## The 
                                                                                                                          ## name 
                                                                                                                          ## of 
                                                                                                                          ## the 
                                                                                                                          ## thing 
                                                                                                                          ## associated 
                                                                                                                          ## with 
                                                                                                                          ## the 
                                                                                                                          ## device.
  var path_402656530 = newJObject()
  var body_402656531 = newJObject()
  if body != nil:
    body_402656531 = body
  add(path_402656530, "thingName", newJString(thingName))
  result = call_402656529.call(path_402656530, nil, nil, nil, body_402656531)

var startNextPendingJobExecution* = Call_StartNextPendingJobExecution_402656516(
    name: "startNextPendingJobExecution", meth: HttpMethod.HttpPut,
    host: "data.jobs.iot.amazonaws.com",
    route: "/things/{thingName}/jobs/$next",
    validator: validate_StartNextPendingJobExecution_402656517, base: "/",
    makeUrl: url_StartNextPendingJobExecution_402656518,
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