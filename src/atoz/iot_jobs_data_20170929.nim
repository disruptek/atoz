
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
  Scheme {.pure.} = enum
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

  OpenApiRestCall_21625426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625426): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "data.jobs.iot.ap-northeast-1.amazonaws.com", "ap-southeast-1": "data.jobs.iot.ap-southeast-1.amazonaws.com", "us-west-2": "data.jobs.iot.us-west-2.amazonaws.com", "eu-west-2": "data.jobs.iot.eu-west-2.amazonaws.com", "ap-northeast-3": "data.jobs.iot.ap-northeast-3.amazonaws.com", "eu-central-1": "data.jobs.iot.eu-central-1.amazonaws.com", "us-east-2": "data.jobs.iot.us-east-2.amazonaws.com", "us-east-1": "data.jobs.iot.us-east-1.amazonaws.com", "cn-northwest-1": "data.jobs.iot.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "data.jobs.iot.ap-south-1.amazonaws.com", "eu-north-1": "data.jobs.iot.eu-north-1.amazonaws.com", "ap-northeast-2": "data.jobs.iot.ap-northeast-2.amazonaws.com", "us-west-1": "data.jobs.iot.us-west-1.amazonaws.com", "us-gov-east-1": "data.jobs.iot.us-gov-east-1.amazonaws.com", "eu-west-3": "data.jobs.iot.eu-west-3.amazonaws.com", "cn-north-1": "data.jobs.iot.cn-north-1.amazonaws.com.cn", "sa-east-1": "data.jobs.iot.sa-east-1.amazonaws.com", "eu-west-1": "data.jobs.iot.eu-west-1.amazonaws.com", "us-gov-west-1": "data.jobs.iot.us-gov-west-1.amazonaws.com", "ap-southeast-2": "data.jobs.iot.ap-southeast-2.amazonaws.com", "ca-central-1": "data.jobs.iot.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_UpdateJobExecution_21626026 = ref object of OpenApiRestCall_21625426
proc url_UpdateJobExecution_21626028(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_UpdateJobExecution_21626027(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the status of a job execution.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   thingName: JString (required)
  ##            : The name of the thing associated with the device.
  ##   jobId: JString (required)
  ##        : The unique identifier assigned to this job when it was created.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `thingName` field"
  var valid_21626029 = path.getOrDefault("thingName")
  valid_21626029 = validateParameter(valid_21626029, JString, required = true,
                                   default = nil)
  if valid_21626029 != nil:
    section.add "thingName", valid_21626029
  var valid_21626030 = path.getOrDefault("jobId")
  valid_21626030 = validateParameter(valid_21626030, JString, required = true,
                                   default = nil)
  if valid_21626030 != nil:
    section.add "jobId", valid_21626030
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
  var valid_21626031 = header.getOrDefault("X-Amz-Date")
  valid_21626031 = validateParameter(valid_21626031, JString, required = false,
                                   default = nil)
  if valid_21626031 != nil:
    section.add "X-Amz-Date", valid_21626031
  var valid_21626032 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626032 = validateParameter(valid_21626032, JString, required = false,
                                   default = nil)
  if valid_21626032 != nil:
    section.add "X-Amz-Security-Token", valid_21626032
  var valid_21626033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626033 = validateParameter(valid_21626033, JString, required = false,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626033
  var valid_21626034 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626034 = validateParameter(valid_21626034, JString, required = false,
                                   default = nil)
  if valid_21626034 != nil:
    section.add "X-Amz-Algorithm", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Signature")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Signature", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Credential")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Credential", valid_21626037
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

proc call*(call_21626039: Call_UpdateJobExecution_21626026; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the status of a job execution.
  ## 
  let valid = call_21626039.validator(path, query, header, formData, body, _)
  let scheme = call_21626039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626039.makeUrl(scheme.get, call_21626039.host, call_21626039.base,
                               call_21626039.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626039, uri, valid, _)

proc call*(call_21626040: Call_UpdateJobExecution_21626026; thingName: string;
          jobId: string; body: JsonNode): Recallable =
  ## updateJobExecution
  ## Updates the status of a job execution.
  ##   thingName: string (required)
  ##            : The name of the thing associated with the device.
  ##   jobId: string (required)
  ##        : The unique identifier assigned to this job when it was created.
  ##   body: JObject (required)
  var path_21626041 = newJObject()
  var body_21626042 = newJObject()
  add(path_21626041, "thingName", newJString(thingName))
  add(path_21626041, "jobId", newJString(jobId))
  if body != nil:
    body_21626042 = body
  result = call_21626040.call(path_21626041, nil, nil, nil, body_21626042)

var updateJobExecution* = Call_UpdateJobExecution_21626026(
    name: "updateJobExecution", meth: HttpMethod.HttpPost,
    host: "data.jobs.iot.amazonaws.com",
    route: "/things/{thingName}/jobs/{jobId}",
    validator: validate_UpdateJobExecution_21626027, base: "/",
    makeUrl: url_UpdateJobExecution_21626028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJobExecution_21625770 = ref object of OpenApiRestCall_21625426
proc url_DescribeJobExecution_21625772(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_DescribeJobExecution_21625771(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets details of a job execution.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   thingName: JString (required)
  ##            : The thing name associated with the device the job execution is running on.
  ##   jobId: JString (required)
  ##        : The unique identifier assigned to this job when it was created.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `thingName` field"
  var valid_21625886 = path.getOrDefault("thingName")
  valid_21625886 = validateParameter(valid_21625886, JString, required = true,
                                   default = nil)
  if valid_21625886 != nil:
    section.add "thingName", valid_21625886
  var valid_21625887 = path.getOrDefault("jobId")
  valid_21625887 = validateParameter(valid_21625887, JString, required = true,
                                   default = nil)
  if valid_21625887 != nil:
    section.add "jobId", valid_21625887
  result.add "path", section
  ## parameters in `query` object:
  ##   executionNumber: JInt
  ##                  : Optional. A number that identifies a particular job execution on a particular device. If not specified, the latest job execution is returned.
  ##   includeJobDocument: JBool
  ##                     : Optional. When set to true, the response contains the job document. The default is false.
  section = newJObject()
  var valid_21625888 = query.getOrDefault("executionNumber")
  valid_21625888 = validateParameter(valid_21625888, JInt, required = false,
                                   default = nil)
  if valid_21625888 != nil:
    section.add "executionNumber", valid_21625888
  var valid_21625889 = query.getOrDefault("includeJobDocument")
  valid_21625889 = validateParameter(valid_21625889, JBool, required = false,
                                   default = nil)
  if valid_21625889 != nil:
    section.add "includeJobDocument", valid_21625889
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
  var valid_21625890 = header.getOrDefault("X-Amz-Date")
  valid_21625890 = validateParameter(valid_21625890, JString, required = false,
                                   default = nil)
  if valid_21625890 != nil:
    section.add "X-Amz-Date", valid_21625890
  var valid_21625891 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625891 = validateParameter(valid_21625891, JString, required = false,
                                   default = nil)
  if valid_21625891 != nil:
    section.add "X-Amz-Security-Token", valid_21625891
  var valid_21625892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625892 = validateParameter(valid_21625892, JString, required = false,
                                   default = nil)
  if valid_21625892 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625892
  var valid_21625893 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625893 = validateParameter(valid_21625893, JString, required = false,
                                   default = nil)
  if valid_21625893 != nil:
    section.add "X-Amz-Algorithm", valid_21625893
  var valid_21625894 = header.getOrDefault("X-Amz-Signature")
  valid_21625894 = validateParameter(valid_21625894, JString, required = false,
                                   default = nil)
  if valid_21625894 != nil:
    section.add "X-Amz-Signature", valid_21625894
  var valid_21625895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625895 = validateParameter(valid_21625895, JString, required = false,
                                   default = nil)
  if valid_21625895 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625895
  var valid_21625896 = header.getOrDefault("X-Amz-Credential")
  valid_21625896 = validateParameter(valid_21625896, JString, required = false,
                                   default = nil)
  if valid_21625896 != nil:
    section.add "X-Amz-Credential", valid_21625896
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625921: Call_DescribeJobExecution_21625770; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets details of a job execution.
  ## 
  let valid = call_21625921.validator(path, query, header, formData, body, _)
  let scheme = call_21625921.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625921.makeUrl(scheme.get, call_21625921.host, call_21625921.base,
                               call_21625921.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625921, uri, valid, _)

proc call*(call_21625984: Call_DescribeJobExecution_21625770; thingName: string;
          jobId: string; executionNumber: int = 0; includeJobDocument: bool = false): Recallable =
  ## describeJobExecution
  ## Gets details of a job execution.
  ##   thingName: string (required)
  ##            : The thing name associated with the device the job execution is running on.
  ##   jobId: string (required)
  ##        : The unique identifier assigned to this job when it was created.
  ##   executionNumber: int
  ##                  : Optional. A number that identifies a particular job execution on a particular device. If not specified, the latest job execution is returned.
  ##   includeJobDocument: bool
  ##                     : Optional. When set to true, the response contains the job document. The default is false.
  var path_21625986 = newJObject()
  var query_21625988 = newJObject()
  add(path_21625986, "thingName", newJString(thingName))
  add(path_21625986, "jobId", newJString(jobId))
  add(query_21625988, "executionNumber", newJInt(executionNumber))
  add(query_21625988, "includeJobDocument", newJBool(includeJobDocument))
  result = call_21625984.call(path_21625986, query_21625988, nil, nil, nil)

var describeJobExecution* = Call_DescribeJobExecution_21625770(
    name: "describeJobExecution", meth: HttpMethod.HttpGet,
    host: "data.jobs.iot.amazonaws.com",
    route: "/things/{thingName}/jobs/{jobId}",
    validator: validate_DescribeJobExecution_21625771, base: "/",
    makeUrl: url_DescribeJobExecution_21625772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPendingJobExecutions_21626043 = ref object of OpenApiRestCall_21625426
proc url_GetPendingJobExecutions_21626045(protocol: Scheme; host: string;
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

proc validate_GetPendingJobExecutions_21626044(path: JsonNode; query: JsonNode;
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
  assert path != nil, "path argument is necessary due to required `thingName` field"
  var valid_21626046 = path.getOrDefault("thingName")
  valid_21626046 = validateParameter(valid_21626046, JString, required = true,
                                   default = nil)
  if valid_21626046 != nil:
    section.add "thingName", valid_21626046
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
  var valid_21626047 = header.getOrDefault("X-Amz-Date")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Date", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Security-Token", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626049 = validateParameter(valid_21626049, JString, required = false,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Algorithm", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Signature")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Signature", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-Credential")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-Credential", valid_21626053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626054: Call_GetPendingJobExecutions_21626043;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the list of all jobs for a thing that are not in a terminal status.
  ## 
  let valid = call_21626054.validator(path, query, header, formData, body, _)
  let scheme = call_21626054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626054.makeUrl(scheme.get, call_21626054.host, call_21626054.base,
                               call_21626054.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626054, uri, valid, _)

proc call*(call_21626055: Call_GetPendingJobExecutions_21626043; thingName: string): Recallable =
  ## getPendingJobExecutions
  ## Gets the list of all jobs for a thing that are not in a terminal status.
  ##   thingName: string (required)
  ##            : The name of the thing that is executing the job.
  var path_21626056 = newJObject()
  add(path_21626056, "thingName", newJString(thingName))
  result = call_21626055.call(path_21626056, nil, nil, nil, nil)

var getPendingJobExecutions* = Call_GetPendingJobExecutions_21626043(
    name: "getPendingJobExecutions", meth: HttpMethod.HttpGet,
    host: "data.jobs.iot.amazonaws.com", route: "/things/{thingName}/jobs",
    validator: validate_GetPendingJobExecutions_21626044, base: "/",
    makeUrl: url_GetPendingJobExecutions_21626045,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartNextPendingJobExecution_21626057 = ref object of OpenApiRestCall_21625426
proc url_StartNextPendingJobExecution_21626059(protocol: Scheme; host: string;
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

proc validate_StartNextPendingJobExecution_21626058(path: JsonNode;
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
  assert path != nil, "path argument is necessary due to required `thingName` field"
  var valid_21626060 = path.getOrDefault("thingName")
  valid_21626060 = validateParameter(valid_21626060, JString, required = true,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "thingName", valid_21626060
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
  var valid_21626061 = header.getOrDefault("X-Amz-Date")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "X-Amz-Date", valid_21626061
  var valid_21626062 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Security-Token", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626064 = validateParameter(valid_21626064, JString, required = false,
                                   default = nil)
  if valid_21626064 != nil:
    section.add "X-Amz-Algorithm", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Signature")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Signature", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Credential")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Credential", valid_21626067
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

proc call*(call_21626069: Call_StartNextPendingJobExecution_21626057;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets and starts the next pending (status IN_PROGRESS or QUEUED) job execution for a thing.
  ## 
  let valid = call_21626069.validator(path, query, header, formData, body, _)
  let scheme = call_21626069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626069.makeUrl(scheme.get, call_21626069.host, call_21626069.base,
                               call_21626069.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626069, uri, valid, _)

proc call*(call_21626070: Call_StartNextPendingJobExecution_21626057;
          thingName: string; body: JsonNode): Recallable =
  ## startNextPendingJobExecution
  ## Gets and starts the next pending (status IN_PROGRESS or QUEUED) job execution for a thing.
  ##   thingName: string (required)
  ##            : The name of the thing associated with the device.
  ##   body: JObject (required)
  var path_21626071 = newJObject()
  var body_21626072 = newJObject()
  add(path_21626071, "thingName", newJString(thingName))
  if body != nil:
    body_21626072 = body
  result = call_21626070.call(path_21626071, nil, nil, nil, body_21626072)

var startNextPendingJobExecution* = Call_StartNextPendingJobExecution_21626057(
    name: "startNextPendingJobExecution", meth: HttpMethod.HttpPut,
    host: "data.jobs.iot.amazonaws.com", route: "/things/{thingName}/jobs/$next",
    validator: validate_StartNextPendingJobExecution_21626058, base: "/",
    makeUrl: url_StartNextPendingJobExecution_21626059,
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
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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