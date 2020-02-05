
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_612649 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612649](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612649): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_UpdateJobExecution_613261 = ref object of OpenApiRestCall_612649
proc url_UpdateJobExecution_613263(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateJobExecution_613262(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Updates the status of a job execution.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   jobId: JString (required)
  ##        : The unique identifier assigned to this job when it was created.
  ##   thingName: JString (required)
  ##            : The name of the thing associated with the device.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `jobId` field"
  var valid_613264 = path.getOrDefault("jobId")
  valid_613264 = validateParameter(valid_613264, JString, required = true,
                                 default = nil)
  if valid_613264 != nil:
    section.add "jobId", valid_613264
  var valid_613265 = path.getOrDefault("thingName")
  valid_613265 = validateParameter(valid_613265, JString, required = true,
                                 default = nil)
  if valid_613265 != nil:
    section.add "thingName", valid_613265
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
  var valid_613266 = header.getOrDefault("X-Amz-Signature")
  valid_613266 = validateParameter(valid_613266, JString, required = false,
                                 default = nil)
  if valid_613266 != nil:
    section.add "X-Amz-Signature", valid_613266
  var valid_613267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613267 = validateParameter(valid_613267, JString, required = false,
                                 default = nil)
  if valid_613267 != nil:
    section.add "X-Amz-Content-Sha256", valid_613267
  var valid_613268 = header.getOrDefault("X-Amz-Date")
  valid_613268 = validateParameter(valid_613268, JString, required = false,
                                 default = nil)
  if valid_613268 != nil:
    section.add "X-Amz-Date", valid_613268
  var valid_613269 = header.getOrDefault("X-Amz-Credential")
  valid_613269 = validateParameter(valid_613269, JString, required = false,
                                 default = nil)
  if valid_613269 != nil:
    section.add "X-Amz-Credential", valid_613269
  var valid_613270 = header.getOrDefault("X-Amz-Security-Token")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "X-Amz-Security-Token", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Algorithm")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Algorithm", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-SignedHeaders", valid_613272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613274: Call_UpdateJobExecution_613261; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status of a job execution.
  ## 
  let valid = call_613274.validator(path, query, header, formData, body)
  let scheme = call_613274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613274.url(scheme.get, call_613274.host, call_613274.base,
                         call_613274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613274, url, valid)

proc call*(call_613275: Call_UpdateJobExecution_613261; jobId: string;
          thingName: string; body: JsonNode): Recallable =
  ## updateJobExecution
  ## Updates the status of a job execution.
  ##   jobId: string (required)
  ##        : The unique identifier assigned to this job when it was created.
  ##   thingName: string (required)
  ##            : The name of the thing associated with the device.
  ##   body: JObject (required)
  var path_613276 = newJObject()
  var body_613277 = newJObject()
  add(path_613276, "jobId", newJString(jobId))
  add(path_613276, "thingName", newJString(thingName))
  if body != nil:
    body_613277 = body
  result = call_613275.call(path_613276, nil, nil, nil, body_613277)

var updateJobExecution* = Call_UpdateJobExecution_613261(
    name: "updateJobExecution", meth: HttpMethod.HttpPost,
    host: "data.jobs.iot.amazonaws.com",
    route: "/things/{thingName}/jobs/{jobId}",
    validator: validate_UpdateJobExecution_613262, base: "/",
    url: url_UpdateJobExecution_613263, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJobExecution_612987 = ref object of OpenApiRestCall_612649
proc url_DescribeJobExecution_612989(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeJobExecution_612988(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets details of a job execution.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   jobId: JString (required)
  ##        : The unique identifier assigned to this job when it was created.
  ##   thingName: JString (required)
  ##            : The thing name associated with the device the job execution is running on.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `jobId` field"
  var valid_613115 = path.getOrDefault("jobId")
  valid_613115 = validateParameter(valid_613115, JString, required = true,
                                 default = nil)
  if valid_613115 != nil:
    section.add "jobId", valid_613115
  var valid_613116 = path.getOrDefault("thingName")
  valid_613116 = validateParameter(valid_613116, JString, required = true,
                                 default = nil)
  if valid_613116 != nil:
    section.add "thingName", valid_613116
  result.add "path", section
  ## parameters in `query` object:
  ##   executionNumber: JInt
  ##                  : Optional. A number that identifies a particular job execution on a particular device. If not specified, the latest job execution is returned.
  ##   includeJobDocument: JBool
  ##                     : Optional. When set to true, the response contains the job document. The default is false.
  section = newJObject()
  var valid_613117 = query.getOrDefault("executionNumber")
  valid_613117 = validateParameter(valid_613117, JInt, required = false, default = nil)
  if valid_613117 != nil:
    section.add "executionNumber", valid_613117
  var valid_613118 = query.getOrDefault("includeJobDocument")
  valid_613118 = validateParameter(valid_613118, JBool, required = false, default = nil)
  if valid_613118 != nil:
    section.add "includeJobDocument", valid_613118
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
  var valid_613119 = header.getOrDefault("X-Amz-Signature")
  valid_613119 = validateParameter(valid_613119, JString, required = false,
                                 default = nil)
  if valid_613119 != nil:
    section.add "X-Amz-Signature", valid_613119
  var valid_613120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613120 = validateParameter(valid_613120, JString, required = false,
                                 default = nil)
  if valid_613120 != nil:
    section.add "X-Amz-Content-Sha256", valid_613120
  var valid_613121 = header.getOrDefault("X-Amz-Date")
  valid_613121 = validateParameter(valid_613121, JString, required = false,
                                 default = nil)
  if valid_613121 != nil:
    section.add "X-Amz-Date", valid_613121
  var valid_613122 = header.getOrDefault("X-Amz-Credential")
  valid_613122 = validateParameter(valid_613122, JString, required = false,
                                 default = nil)
  if valid_613122 != nil:
    section.add "X-Amz-Credential", valid_613122
  var valid_613123 = header.getOrDefault("X-Amz-Security-Token")
  valid_613123 = validateParameter(valid_613123, JString, required = false,
                                 default = nil)
  if valid_613123 != nil:
    section.add "X-Amz-Security-Token", valid_613123
  var valid_613124 = header.getOrDefault("X-Amz-Algorithm")
  valid_613124 = validateParameter(valid_613124, JString, required = false,
                                 default = nil)
  if valid_613124 != nil:
    section.add "X-Amz-Algorithm", valid_613124
  var valid_613125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "X-Amz-SignedHeaders", valid_613125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613148: Call_DescribeJobExecution_612987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details of a job execution.
  ## 
  let valid = call_613148.validator(path, query, header, formData, body)
  let scheme = call_613148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613148.url(scheme.get, call_613148.host, call_613148.base,
                         call_613148.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613148, url, valid)

proc call*(call_613219: Call_DescribeJobExecution_612987; jobId: string;
          thingName: string; executionNumber: int = 0;
          includeJobDocument: bool = false): Recallable =
  ## describeJobExecution
  ## Gets details of a job execution.
  ##   jobId: string (required)
  ##        : The unique identifier assigned to this job when it was created.
  ##   executionNumber: int
  ##                  : Optional. A number that identifies a particular job execution on a particular device. If not specified, the latest job execution is returned.
  ##   thingName: string (required)
  ##            : The thing name associated with the device the job execution is running on.
  ##   includeJobDocument: bool
  ##                     : Optional. When set to true, the response contains the job document. The default is false.
  var path_613220 = newJObject()
  var query_613222 = newJObject()
  add(path_613220, "jobId", newJString(jobId))
  add(query_613222, "executionNumber", newJInt(executionNumber))
  add(path_613220, "thingName", newJString(thingName))
  add(query_613222, "includeJobDocument", newJBool(includeJobDocument))
  result = call_613219.call(path_613220, query_613222, nil, nil, nil)

var describeJobExecution* = Call_DescribeJobExecution_612987(
    name: "describeJobExecution", meth: HttpMethod.HttpGet,
    host: "data.jobs.iot.amazonaws.com",
    route: "/things/{thingName}/jobs/{jobId}",
    validator: validate_DescribeJobExecution_612988, base: "/",
    url: url_DescribeJobExecution_612989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPendingJobExecutions_613278 = ref object of OpenApiRestCall_612649
proc url_GetPendingJobExecutions_613280(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetPendingJobExecutions_613279(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the list of all jobs for a thing that are not in a terminal status.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   thingName: JString (required)
  ##            : The name of the thing that is executing the job.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `thingName` field"
  var valid_613281 = path.getOrDefault("thingName")
  valid_613281 = validateParameter(valid_613281, JString, required = true,
                                 default = nil)
  if valid_613281 != nil:
    section.add "thingName", valid_613281
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
  var valid_613282 = header.getOrDefault("X-Amz-Signature")
  valid_613282 = validateParameter(valid_613282, JString, required = false,
                                 default = nil)
  if valid_613282 != nil:
    section.add "X-Amz-Signature", valid_613282
  var valid_613283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613283 = validateParameter(valid_613283, JString, required = false,
                                 default = nil)
  if valid_613283 != nil:
    section.add "X-Amz-Content-Sha256", valid_613283
  var valid_613284 = header.getOrDefault("X-Amz-Date")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "X-Amz-Date", valid_613284
  var valid_613285 = header.getOrDefault("X-Amz-Credential")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Credential", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Security-Token")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Security-Token", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Algorithm")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Algorithm", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-SignedHeaders", valid_613288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613289: Call_GetPendingJobExecutions_613278; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the list of all jobs for a thing that are not in a terminal status.
  ## 
  let valid = call_613289.validator(path, query, header, formData, body)
  let scheme = call_613289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613289.url(scheme.get, call_613289.host, call_613289.base,
                         call_613289.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613289, url, valid)

proc call*(call_613290: Call_GetPendingJobExecutions_613278; thingName: string): Recallable =
  ## getPendingJobExecutions
  ## Gets the list of all jobs for a thing that are not in a terminal status.
  ##   thingName: string (required)
  ##            : The name of the thing that is executing the job.
  var path_613291 = newJObject()
  add(path_613291, "thingName", newJString(thingName))
  result = call_613290.call(path_613291, nil, nil, nil, nil)

var getPendingJobExecutions* = Call_GetPendingJobExecutions_613278(
    name: "getPendingJobExecutions", meth: HttpMethod.HttpGet,
    host: "data.jobs.iot.amazonaws.com", route: "/things/{thingName}/jobs",
    validator: validate_GetPendingJobExecutions_613279, base: "/",
    url: url_GetPendingJobExecutions_613280, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartNextPendingJobExecution_613292 = ref object of OpenApiRestCall_612649
proc url_StartNextPendingJobExecution_613294(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartNextPendingJobExecution_613293(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets and starts the next pending (status IN_PROGRESS or QUEUED) job execution for a thing.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   thingName: JString (required)
  ##            : The name of the thing associated with the device.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `thingName` field"
  var valid_613295 = path.getOrDefault("thingName")
  valid_613295 = validateParameter(valid_613295, JString, required = true,
                                 default = nil)
  if valid_613295 != nil:
    section.add "thingName", valid_613295
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
  var valid_613296 = header.getOrDefault("X-Amz-Signature")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "X-Amz-Signature", valid_613296
  var valid_613297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613297 = validateParameter(valid_613297, JString, required = false,
                                 default = nil)
  if valid_613297 != nil:
    section.add "X-Amz-Content-Sha256", valid_613297
  var valid_613298 = header.getOrDefault("X-Amz-Date")
  valid_613298 = validateParameter(valid_613298, JString, required = false,
                                 default = nil)
  if valid_613298 != nil:
    section.add "X-Amz-Date", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Credential")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Credential", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Security-Token")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Security-Token", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Algorithm")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Algorithm", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-SignedHeaders", valid_613302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613304: Call_StartNextPendingJobExecution_613292; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets and starts the next pending (status IN_PROGRESS or QUEUED) job execution for a thing.
  ## 
  let valid = call_613304.validator(path, query, header, formData, body)
  let scheme = call_613304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613304.url(scheme.get, call_613304.host, call_613304.base,
                         call_613304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613304, url, valid)

proc call*(call_613305: Call_StartNextPendingJobExecution_613292;
          thingName: string; body: JsonNode): Recallable =
  ## startNextPendingJobExecution
  ## Gets and starts the next pending (status IN_PROGRESS or QUEUED) job execution for a thing.
  ##   thingName: string (required)
  ##            : The name of the thing associated with the device.
  ##   body: JObject (required)
  var path_613306 = newJObject()
  var body_613307 = newJObject()
  add(path_613306, "thingName", newJString(thingName))
  if body != nil:
    body_613307 = body
  result = call_613305.call(path_613306, nil, nil, nil, body_613307)

var startNextPendingJobExecution* = Call_StartNextPendingJobExecution_613292(
    name: "startNextPendingJobExecution", meth: HttpMethod.HttpPut,
    host: "data.jobs.iot.amazonaws.com", route: "/things/{thingName}/jobs/$next",
    validator: validate_StartNextPendingJobExecution_613293, base: "/",
    url: url_StartNextPendingJobExecution_613294,
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
