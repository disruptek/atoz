
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

  OpenApiRestCall_599359 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599359](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599359): Option[Scheme] {.used.} =
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
  Call_UpdateJobExecution_599970 = ref object of OpenApiRestCall_599359
proc url_UpdateJobExecution_599972(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateJobExecution_599971(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_599973 = path.getOrDefault("thingName")
  valid_599973 = validateParameter(valid_599973, JString, required = true,
                                 default = nil)
  if valid_599973 != nil:
    section.add "thingName", valid_599973
  var valid_599974 = path.getOrDefault("jobId")
  valid_599974 = validateParameter(valid_599974, JString, required = true,
                                 default = nil)
  if valid_599974 != nil:
    section.add "jobId", valid_599974
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
  var valid_599975 = header.getOrDefault("X-Amz-Date")
  valid_599975 = validateParameter(valid_599975, JString, required = false,
                                 default = nil)
  if valid_599975 != nil:
    section.add "X-Amz-Date", valid_599975
  var valid_599976 = header.getOrDefault("X-Amz-Security-Token")
  valid_599976 = validateParameter(valid_599976, JString, required = false,
                                 default = nil)
  if valid_599976 != nil:
    section.add "X-Amz-Security-Token", valid_599976
  var valid_599977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599977 = validateParameter(valid_599977, JString, required = false,
                                 default = nil)
  if valid_599977 != nil:
    section.add "X-Amz-Content-Sha256", valid_599977
  var valid_599978 = header.getOrDefault("X-Amz-Algorithm")
  valid_599978 = validateParameter(valid_599978, JString, required = false,
                                 default = nil)
  if valid_599978 != nil:
    section.add "X-Amz-Algorithm", valid_599978
  var valid_599979 = header.getOrDefault("X-Amz-Signature")
  valid_599979 = validateParameter(valid_599979, JString, required = false,
                                 default = nil)
  if valid_599979 != nil:
    section.add "X-Amz-Signature", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-SignedHeaders", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Credential")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Credential", valid_599981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599983: Call_UpdateJobExecution_599970; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status of a job execution.
  ## 
  let valid = call_599983.validator(path, query, header, formData, body)
  let scheme = call_599983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599983.url(scheme.get, call_599983.host, call_599983.base,
                         call_599983.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599983, url, valid)

proc call*(call_599984: Call_UpdateJobExecution_599970; thingName: string;
          jobId: string; body: JsonNode): Recallable =
  ## updateJobExecution
  ## Updates the status of a job execution.
  ##   thingName: string (required)
  ##            : The name of the thing associated with the device.
  ##   jobId: string (required)
  ##        : The unique identifier assigned to this job when it was created.
  ##   body: JObject (required)
  var path_599985 = newJObject()
  var body_599986 = newJObject()
  add(path_599985, "thingName", newJString(thingName))
  add(path_599985, "jobId", newJString(jobId))
  if body != nil:
    body_599986 = body
  result = call_599984.call(path_599985, nil, nil, nil, body_599986)

var updateJobExecution* = Call_UpdateJobExecution_599970(
    name: "updateJobExecution", meth: HttpMethod.HttpPost,
    host: "data.jobs.iot.amazonaws.com",
    route: "/things/{thingName}/jobs/{jobId}",
    validator: validate_UpdateJobExecution_599971, base: "/",
    url: url_UpdateJobExecution_599972, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJobExecution_599696 = ref object of OpenApiRestCall_599359
proc url_DescribeJobExecution_599698(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeJobExecution_599697(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_599824 = path.getOrDefault("thingName")
  valid_599824 = validateParameter(valid_599824, JString, required = true,
                                 default = nil)
  if valid_599824 != nil:
    section.add "thingName", valid_599824
  var valid_599825 = path.getOrDefault("jobId")
  valid_599825 = validateParameter(valid_599825, JString, required = true,
                                 default = nil)
  if valid_599825 != nil:
    section.add "jobId", valid_599825
  result.add "path", section
  ## parameters in `query` object:
  ##   executionNumber: JInt
  ##                  : Optional. A number that identifies a particular job execution on a particular device. If not specified, the latest job execution is returned.
  ##   includeJobDocument: JBool
  ##                     : Optional. When set to true, the response contains the job document. The default is false.
  section = newJObject()
  var valid_599826 = query.getOrDefault("executionNumber")
  valid_599826 = validateParameter(valid_599826, JInt, required = false, default = nil)
  if valid_599826 != nil:
    section.add "executionNumber", valid_599826
  var valid_599827 = query.getOrDefault("includeJobDocument")
  valid_599827 = validateParameter(valid_599827, JBool, required = false, default = nil)
  if valid_599827 != nil:
    section.add "includeJobDocument", valid_599827
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
  var valid_599828 = header.getOrDefault("X-Amz-Date")
  valid_599828 = validateParameter(valid_599828, JString, required = false,
                                 default = nil)
  if valid_599828 != nil:
    section.add "X-Amz-Date", valid_599828
  var valid_599829 = header.getOrDefault("X-Amz-Security-Token")
  valid_599829 = validateParameter(valid_599829, JString, required = false,
                                 default = nil)
  if valid_599829 != nil:
    section.add "X-Amz-Security-Token", valid_599829
  var valid_599830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599830 = validateParameter(valid_599830, JString, required = false,
                                 default = nil)
  if valid_599830 != nil:
    section.add "X-Amz-Content-Sha256", valid_599830
  var valid_599831 = header.getOrDefault("X-Amz-Algorithm")
  valid_599831 = validateParameter(valid_599831, JString, required = false,
                                 default = nil)
  if valid_599831 != nil:
    section.add "X-Amz-Algorithm", valid_599831
  var valid_599832 = header.getOrDefault("X-Amz-Signature")
  valid_599832 = validateParameter(valid_599832, JString, required = false,
                                 default = nil)
  if valid_599832 != nil:
    section.add "X-Amz-Signature", valid_599832
  var valid_599833 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599833 = validateParameter(valid_599833, JString, required = false,
                                 default = nil)
  if valid_599833 != nil:
    section.add "X-Amz-SignedHeaders", valid_599833
  var valid_599834 = header.getOrDefault("X-Amz-Credential")
  valid_599834 = validateParameter(valid_599834, JString, required = false,
                                 default = nil)
  if valid_599834 != nil:
    section.add "X-Amz-Credential", valid_599834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599857: Call_DescribeJobExecution_599696; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details of a job execution.
  ## 
  let valid = call_599857.validator(path, query, header, formData, body)
  let scheme = call_599857.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599857.url(scheme.get, call_599857.host, call_599857.base,
                         call_599857.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599857, url, valid)

proc call*(call_599928: Call_DescribeJobExecution_599696; thingName: string;
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
  var path_599929 = newJObject()
  var query_599931 = newJObject()
  add(path_599929, "thingName", newJString(thingName))
  add(path_599929, "jobId", newJString(jobId))
  add(query_599931, "executionNumber", newJInt(executionNumber))
  add(query_599931, "includeJobDocument", newJBool(includeJobDocument))
  result = call_599928.call(path_599929, query_599931, nil, nil, nil)

var describeJobExecution* = Call_DescribeJobExecution_599696(
    name: "describeJobExecution", meth: HttpMethod.HttpGet,
    host: "data.jobs.iot.amazonaws.com",
    route: "/things/{thingName}/jobs/{jobId}",
    validator: validate_DescribeJobExecution_599697, base: "/",
    url: url_DescribeJobExecution_599698, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPendingJobExecutions_599987 = ref object of OpenApiRestCall_599359
proc url_GetPendingJobExecutions_599989(protocol: Scheme; host: string; base: string;
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

proc validate_GetPendingJobExecutions_599988(path: JsonNode; query: JsonNode;
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
  var valid_599990 = path.getOrDefault("thingName")
  valid_599990 = validateParameter(valid_599990, JString, required = true,
                                 default = nil)
  if valid_599990 != nil:
    section.add "thingName", valid_599990
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
  var valid_599991 = header.getOrDefault("X-Amz-Date")
  valid_599991 = validateParameter(valid_599991, JString, required = false,
                                 default = nil)
  if valid_599991 != nil:
    section.add "X-Amz-Date", valid_599991
  var valid_599992 = header.getOrDefault("X-Amz-Security-Token")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Security-Token", valid_599992
  var valid_599993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Content-Sha256", valid_599993
  var valid_599994 = header.getOrDefault("X-Amz-Algorithm")
  valid_599994 = validateParameter(valid_599994, JString, required = false,
                                 default = nil)
  if valid_599994 != nil:
    section.add "X-Amz-Algorithm", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Signature")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Signature", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-SignedHeaders", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Credential")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Credential", valid_599997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599998: Call_GetPendingJobExecutions_599987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the list of all jobs for a thing that are not in a terminal status.
  ## 
  let valid = call_599998.validator(path, query, header, formData, body)
  let scheme = call_599998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599998.url(scheme.get, call_599998.host, call_599998.base,
                         call_599998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599998, url, valid)

proc call*(call_599999: Call_GetPendingJobExecutions_599987; thingName: string): Recallable =
  ## getPendingJobExecutions
  ## Gets the list of all jobs for a thing that are not in a terminal status.
  ##   thingName: string (required)
  ##            : The name of the thing that is executing the job.
  var path_600000 = newJObject()
  add(path_600000, "thingName", newJString(thingName))
  result = call_599999.call(path_600000, nil, nil, nil, nil)

var getPendingJobExecutions* = Call_GetPendingJobExecutions_599987(
    name: "getPendingJobExecutions", meth: HttpMethod.HttpGet,
    host: "data.jobs.iot.amazonaws.com", route: "/things/{thingName}/jobs",
    validator: validate_GetPendingJobExecutions_599988, base: "/",
    url: url_GetPendingJobExecutions_599989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartNextPendingJobExecution_600001 = ref object of OpenApiRestCall_599359
proc url_StartNextPendingJobExecution_600003(protocol: Scheme; host: string;
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

proc validate_StartNextPendingJobExecution_600002(path: JsonNode; query: JsonNode;
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
  var valid_600004 = path.getOrDefault("thingName")
  valid_600004 = validateParameter(valid_600004, JString, required = true,
                                 default = nil)
  if valid_600004 != nil:
    section.add "thingName", valid_600004
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
  var valid_600005 = header.getOrDefault("X-Amz-Date")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "X-Amz-Date", valid_600005
  var valid_600006 = header.getOrDefault("X-Amz-Security-Token")
  valid_600006 = validateParameter(valid_600006, JString, required = false,
                                 default = nil)
  if valid_600006 != nil:
    section.add "X-Amz-Security-Token", valid_600006
  var valid_600007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Content-Sha256", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Algorithm")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Algorithm", valid_600008
  var valid_600009 = header.getOrDefault("X-Amz-Signature")
  valid_600009 = validateParameter(valid_600009, JString, required = false,
                                 default = nil)
  if valid_600009 != nil:
    section.add "X-Amz-Signature", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-SignedHeaders", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Credential")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Credential", valid_600011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600013: Call_StartNextPendingJobExecution_600001; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets and starts the next pending (status IN_PROGRESS or QUEUED) job execution for a thing.
  ## 
  let valid = call_600013.validator(path, query, header, formData, body)
  let scheme = call_600013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600013.url(scheme.get, call_600013.host, call_600013.base,
                         call_600013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600013, url, valid)

proc call*(call_600014: Call_StartNextPendingJobExecution_600001;
          thingName: string; body: JsonNode): Recallable =
  ## startNextPendingJobExecution
  ## Gets and starts the next pending (status IN_PROGRESS or QUEUED) job execution for a thing.
  ##   thingName: string (required)
  ##            : The name of the thing associated with the device.
  ##   body: JObject (required)
  var path_600015 = newJObject()
  var body_600016 = newJObject()
  add(path_600015, "thingName", newJString(thingName))
  if body != nil:
    body_600016 = body
  result = call_600014.call(path_600015, nil, nil, nil, body_600016)

var startNextPendingJobExecution* = Call_StartNextPendingJobExecution_600001(
    name: "startNextPendingJobExecution", meth: HttpMethod.HttpPut,
    host: "data.jobs.iot.amazonaws.com", route: "/things/{thingName}/jobs/$next",
    validator: validate_StartNextPendingJobExecution_600002, base: "/",
    url: url_StartNextPendingJobExecution_600003,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
