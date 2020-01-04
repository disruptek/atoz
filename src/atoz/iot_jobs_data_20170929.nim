
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

  OpenApiRestCall_601380 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601380](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601380): Option[Scheme] {.used.} =
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
  Call_UpdateJobExecution_601992 = ref object of OpenApiRestCall_601380
proc url_UpdateJobExecution_601994(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateJobExecution_601993(path: JsonNode; query: JsonNode;
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
  var valid_601995 = path.getOrDefault("jobId")
  valid_601995 = validateParameter(valid_601995, JString, required = true,
                                 default = nil)
  if valid_601995 != nil:
    section.add "jobId", valid_601995
  var valid_601996 = path.getOrDefault("thingName")
  valid_601996 = validateParameter(valid_601996, JString, required = true,
                                 default = nil)
  if valid_601996 != nil:
    section.add "thingName", valid_601996
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
  var valid_601997 = header.getOrDefault("X-Amz-Signature")
  valid_601997 = validateParameter(valid_601997, JString, required = false,
                                 default = nil)
  if valid_601997 != nil:
    section.add "X-Amz-Signature", valid_601997
  var valid_601998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601998 = validateParameter(valid_601998, JString, required = false,
                                 default = nil)
  if valid_601998 != nil:
    section.add "X-Amz-Content-Sha256", valid_601998
  var valid_601999 = header.getOrDefault("X-Amz-Date")
  valid_601999 = validateParameter(valid_601999, JString, required = false,
                                 default = nil)
  if valid_601999 != nil:
    section.add "X-Amz-Date", valid_601999
  var valid_602000 = header.getOrDefault("X-Amz-Credential")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "X-Amz-Credential", valid_602000
  var valid_602001 = header.getOrDefault("X-Amz-Security-Token")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Security-Token", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Algorithm")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Algorithm", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-SignedHeaders", valid_602003
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602005: Call_UpdateJobExecution_601992; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status of a job execution.
  ## 
  let valid = call_602005.validator(path, query, header, formData, body)
  let scheme = call_602005.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602005.url(scheme.get, call_602005.host, call_602005.base,
                         call_602005.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602005, url, valid)

proc call*(call_602006: Call_UpdateJobExecution_601992; jobId: string;
          thingName: string; body: JsonNode): Recallable =
  ## updateJobExecution
  ## Updates the status of a job execution.
  ##   jobId: string (required)
  ##        : The unique identifier assigned to this job when it was created.
  ##   thingName: string (required)
  ##            : The name of the thing associated with the device.
  ##   body: JObject (required)
  var path_602007 = newJObject()
  var body_602008 = newJObject()
  add(path_602007, "jobId", newJString(jobId))
  add(path_602007, "thingName", newJString(thingName))
  if body != nil:
    body_602008 = body
  result = call_602006.call(path_602007, nil, nil, nil, body_602008)

var updateJobExecution* = Call_UpdateJobExecution_601992(
    name: "updateJobExecution", meth: HttpMethod.HttpPost,
    host: "data.jobs.iot.amazonaws.com",
    route: "/things/{thingName}/jobs/{jobId}",
    validator: validate_UpdateJobExecution_601993, base: "/",
    url: url_UpdateJobExecution_601994, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJobExecution_601718 = ref object of OpenApiRestCall_601380
proc url_DescribeJobExecution_601720(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeJobExecution_601719(path: JsonNode; query: JsonNode;
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
  var valid_601846 = path.getOrDefault("jobId")
  valid_601846 = validateParameter(valid_601846, JString, required = true,
                                 default = nil)
  if valid_601846 != nil:
    section.add "jobId", valid_601846
  var valid_601847 = path.getOrDefault("thingName")
  valid_601847 = validateParameter(valid_601847, JString, required = true,
                                 default = nil)
  if valid_601847 != nil:
    section.add "thingName", valid_601847
  result.add "path", section
  ## parameters in `query` object:
  ##   executionNumber: JInt
  ##                  : Optional. A number that identifies a particular job execution on a particular device. If not specified, the latest job execution is returned.
  ##   includeJobDocument: JBool
  ##                     : Optional. When set to true, the response contains the job document. The default is false.
  section = newJObject()
  var valid_601848 = query.getOrDefault("executionNumber")
  valid_601848 = validateParameter(valid_601848, JInt, required = false, default = nil)
  if valid_601848 != nil:
    section.add "executionNumber", valid_601848
  var valid_601849 = query.getOrDefault("includeJobDocument")
  valid_601849 = validateParameter(valid_601849, JBool, required = false, default = nil)
  if valid_601849 != nil:
    section.add "includeJobDocument", valid_601849
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
  var valid_601850 = header.getOrDefault("X-Amz-Signature")
  valid_601850 = validateParameter(valid_601850, JString, required = false,
                                 default = nil)
  if valid_601850 != nil:
    section.add "X-Amz-Signature", valid_601850
  var valid_601851 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601851 = validateParameter(valid_601851, JString, required = false,
                                 default = nil)
  if valid_601851 != nil:
    section.add "X-Amz-Content-Sha256", valid_601851
  var valid_601852 = header.getOrDefault("X-Amz-Date")
  valid_601852 = validateParameter(valid_601852, JString, required = false,
                                 default = nil)
  if valid_601852 != nil:
    section.add "X-Amz-Date", valid_601852
  var valid_601853 = header.getOrDefault("X-Amz-Credential")
  valid_601853 = validateParameter(valid_601853, JString, required = false,
                                 default = nil)
  if valid_601853 != nil:
    section.add "X-Amz-Credential", valid_601853
  var valid_601854 = header.getOrDefault("X-Amz-Security-Token")
  valid_601854 = validateParameter(valid_601854, JString, required = false,
                                 default = nil)
  if valid_601854 != nil:
    section.add "X-Amz-Security-Token", valid_601854
  var valid_601855 = header.getOrDefault("X-Amz-Algorithm")
  valid_601855 = validateParameter(valid_601855, JString, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "X-Amz-Algorithm", valid_601855
  var valid_601856 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-SignedHeaders", valid_601856
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601879: Call_DescribeJobExecution_601718; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details of a job execution.
  ## 
  let valid = call_601879.validator(path, query, header, formData, body)
  let scheme = call_601879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601879.url(scheme.get, call_601879.host, call_601879.base,
                         call_601879.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601879, url, valid)

proc call*(call_601950: Call_DescribeJobExecution_601718; jobId: string;
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
  var path_601951 = newJObject()
  var query_601953 = newJObject()
  add(path_601951, "jobId", newJString(jobId))
  add(query_601953, "executionNumber", newJInt(executionNumber))
  add(path_601951, "thingName", newJString(thingName))
  add(query_601953, "includeJobDocument", newJBool(includeJobDocument))
  result = call_601950.call(path_601951, query_601953, nil, nil, nil)

var describeJobExecution* = Call_DescribeJobExecution_601718(
    name: "describeJobExecution", meth: HttpMethod.HttpGet,
    host: "data.jobs.iot.amazonaws.com",
    route: "/things/{thingName}/jobs/{jobId}",
    validator: validate_DescribeJobExecution_601719, base: "/",
    url: url_DescribeJobExecution_601720, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPendingJobExecutions_602009 = ref object of OpenApiRestCall_601380
proc url_GetPendingJobExecutions_602011(protocol: Scheme; host: string; base: string;
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

proc validate_GetPendingJobExecutions_602010(path: JsonNode; query: JsonNode;
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
  var valid_602012 = path.getOrDefault("thingName")
  valid_602012 = validateParameter(valid_602012, JString, required = true,
                                 default = nil)
  if valid_602012 != nil:
    section.add "thingName", valid_602012
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
  var valid_602013 = header.getOrDefault("X-Amz-Signature")
  valid_602013 = validateParameter(valid_602013, JString, required = false,
                                 default = nil)
  if valid_602013 != nil:
    section.add "X-Amz-Signature", valid_602013
  var valid_602014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602014 = validateParameter(valid_602014, JString, required = false,
                                 default = nil)
  if valid_602014 != nil:
    section.add "X-Amz-Content-Sha256", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-Date")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Date", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-Credential")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Credential", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Security-Token")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Security-Token", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Algorithm")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Algorithm", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-SignedHeaders", valid_602019
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602020: Call_GetPendingJobExecutions_602009; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the list of all jobs for a thing that are not in a terminal status.
  ## 
  let valid = call_602020.validator(path, query, header, formData, body)
  let scheme = call_602020.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602020.url(scheme.get, call_602020.host, call_602020.base,
                         call_602020.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602020, url, valid)

proc call*(call_602021: Call_GetPendingJobExecutions_602009; thingName: string): Recallable =
  ## getPendingJobExecutions
  ## Gets the list of all jobs for a thing that are not in a terminal status.
  ##   thingName: string (required)
  ##            : The name of the thing that is executing the job.
  var path_602022 = newJObject()
  add(path_602022, "thingName", newJString(thingName))
  result = call_602021.call(path_602022, nil, nil, nil, nil)

var getPendingJobExecutions* = Call_GetPendingJobExecutions_602009(
    name: "getPendingJobExecutions", meth: HttpMethod.HttpGet,
    host: "data.jobs.iot.amazonaws.com", route: "/things/{thingName}/jobs",
    validator: validate_GetPendingJobExecutions_602010, base: "/",
    url: url_GetPendingJobExecutions_602011, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartNextPendingJobExecution_602023 = ref object of OpenApiRestCall_601380
proc url_StartNextPendingJobExecution_602025(protocol: Scheme; host: string;
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

proc validate_StartNextPendingJobExecution_602024(path: JsonNode; query: JsonNode;
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
  var valid_602026 = path.getOrDefault("thingName")
  valid_602026 = validateParameter(valid_602026, JString, required = true,
                                 default = nil)
  if valid_602026 != nil:
    section.add "thingName", valid_602026
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
  var valid_602027 = header.getOrDefault("X-Amz-Signature")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-Signature", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-Content-Sha256", valid_602028
  var valid_602029 = header.getOrDefault("X-Amz-Date")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-Date", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Credential")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Credential", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Security-Token")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Security-Token", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Algorithm")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Algorithm", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-SignedHeaders", valid_602033
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602035: Call_StartNextPendingJobExecution_602023; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets and starts the next pending (status IN_PROGRESS or QUEUED) job execution for a thing.
  ## 
  let valid = call_602035.validator(path, query, header, formData, body)
  let scheme = call_602035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602035.url(scheme.get, call_602035.host, call_602035.base,
                         call_602035.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602035, url, valid)

proc call*(call_602036: Call_StartNextPendingJobExecution_602023;
          thingName: string; body: JsonNode): Recallable =
  ## startNextPendingJobExecution
  ## Gets and starts the next pending (status IN_PROGRESS or QUEUED) job execution for a thing.
  ##   thingName: string (required)
  ##            : The name of the thing associated with the device.
  ##   body: JObject (required)
  var path_602037 = newJObject()
  var body_602038 = newJObject()
  add(path_602037, "thingName", newJString(thingName))
  if body != nil:
    body_602038 = body
  result = call_602036.call(path_602037, nil, nil, nil, body_602038)

var startNextPendingJobExecution* = Call_StartNextPendingJobExecution_602023(
    name: "startNextPendingJobExecution", meth: HttpMethod.HttpPut,
    host: "data.jobs.iot.amazonaws.com", route: "/things/{thingName}/jobs/$next",
    validator: validate_StartNextPendingJobExecution_602024, base: "/",
    url: url_StartNextPendingJobExecution_602025,
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
