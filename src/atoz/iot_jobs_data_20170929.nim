
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_602457 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602457](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602457): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_UpdateJobExecution_603068 = ref object of OpenApiRestCall_602457
proc url_UpdateJobExecution_603070(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateJobExecution_603069(path: JsonNode; query: JsonNode;
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
  var valid_603071 = path.getOrDefault("thingName")
  valid_603071 = validateParameter(valid_603071, JString, required = true,
                                 default = nil)
  if valid_603071 != nil:
    section.add "thingName", valid_603071
  var valid_603072 = path.getOrDefault("jobId")
  valid_603072 = validateParameter(valid_603072, JString, required = true,
                                 default = nil)
  if valid_603072 != nil:
    section.add "jobId", valid_603072
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
  var valid_603073 = header.getOrDefault("X-Amz-Date")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-Date", valid_603073
  var valid_603074 = header.getOrDefault("X-Amz-Security-Token")
  valid_603074 = validateParameter(valid_603074, JString, required = false,
                                 default = nil)
  if valid_603074 != nil:
    section.add "X-Amz-Security-Token", valid_603074
  var valid_603075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Content-Sha256", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Algorithm")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Algorithm", valid_603076
  var valid_603077 = header.getOrDefault("X-Amz-Signature")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "X-Amz-Signature", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-SignedHeaders", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Credential")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Credential", valid_603079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603081: Call_UpdateJobExecution_603068; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status of a job execution.
  ## 
  let valid = call_603081.validator(path, query, header, formData, body)
  let scheme = call_603081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603081.url(scheme.get, call_603081.host, call_603081.base,
                         call_603081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603081, url, valid)

proc call*(call_603082: Call_UpdateJobExecution_603068; thingName: string;
          jobId: string; body: JsonNode): Recallable =
  ## updateJobExecution
  ## Updates the status of a job execution.
  ##   thingName: string (required)
  ##            : The name of the thing associated with the device.
  ##   jobId: string (required)
  ##        : The unique identifier assigned to this job when it was created.
  ##   body: JObject (required)
  var path_603083 = newJObject()
  var body_603084 = newJObject()
  add(path_603083, "thingName", newJString(thingName))
  add(path_603083, "jobId", newJString(jobId))
  if body != nil:
    body_603084 = body
  result = call_603082.call(path_603083, nil, nil, nil, body_603084)

var updateJobExecution* = Call_UpdateJobExecution_603068(
    name: "updateJobExecution", meth: HttpMethod.HttpPost,
    host: "data.jobs.iot.amazonaws.com",
    route: "/things/{thingName}/jobs/{jobId}",
    validator: validate_UpdateJobExecution_603069, base: "/",
    url: url_UpdateJobExecution_603070, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJobExecution_602794 = ref object of OpenApiRestCall_602457
proc url_DescribeJobExecution_602796(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DescribeJobExecution_602795(path: JsonNode; query: JsonNode;
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
  var valid_602922 = path.getOrDefault("thingName")
  valid_602922 = validateParameter(valid_602922, JString, required = true,
                                 default = nil)
  if valid_602922 != nil:
    section.add "thingName", valid_602922
  var valid_602923 = path.getOrDefault("jobId")
  valid_602923 = validateParameter(valid_602923, JString, required = true,
                                 default = nil)
  if valid_602923 != nil:
    section.add "jobId", valid_602923
  result.add "path", section
  ## parameters in `query` object:
  ##   executionNumber: JInt
  ##                  : Optional. A number that identifies a particular job execution on a particular device. If not specified, the latest job execution is returned.
  ##   includeJobDocument: JBool
  ##                     : Optional. When set to true, the response contains the job document. The default is false.
  section = newJObject()
  var valid_602924 = query.getOrDefault("executionNumber")
  valid_602924 = validateParameter(valid_602924, JInt, required = false, default = nil)
  if valid_602924 != nil:
    section.add "executionNumber", valid_602924
  var valid_602925 = query.getOrDefault("includeJobDocument")
  valid_602925 = validateParameter(valid_602925, JBool, required = false, default = nil)
  if valid_602925 != nil:
    section.add "includeJobDocument", valid_602925
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
  var valid_602926 = header.getOrDefault("X-Amz-Date")
  valid_602926 = validateParameter(valid_602926, JString, required = false,
                                 default = nil)
  if valid_602926 != nil:
    section.add "X-Amz-Date", valid_602926
  var valid_602927 = header.getOrDefault("X-Amz-Security-Token")
  valid_602927 = validateParameter(valid_602927, JString, required = false,
                                 default = nil)
  if valid_602927 != nil:
    section.add "X-Amz-Security-Token", valid_602927
  var valid_602928 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602928 = validateParameter(valid_602928, JString, required = false,
                                 default = nil)
  if valid_602928 != nil:
    section.add "X-Amz-Content-Sha256", valid_602928
  var valid_602929 = header.getOrDefault("X-Amz-Algorithm")
  valid_602929 = validateParameter(valid_602929, JString, required = false,
                                 default = nil)
  if valid_602929 != nil:
    section.add "X-Amz-Algorithm", valid_602929
  var valid_602930 = header.getOrDefault("X-Amz-Signature")
  valid_602930 = validateParameter(valid_602930, JString, required = false,
                                 default = nil)
  if valid_602930 != nil:
    section.add "X-Amz-Signature", valid_602930
  var valid_602931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602931 = validateParameter(valid_602931, JString, required = false,
                                 default = nil)
  if valid_602931 != nil:
    section.add "X-Amz-SignedHeaders", valid_602931
  var valid_602932 = header.getOrDefault("X-Amz-Credential")
  valid_602932 = validateParameter(valid_602932, JString, required = false,
                                 default = nil)
  if valid_602932 != nil:
    section.add "X-Amz-Credential", valid_602932
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602955: Call_DescribeJobExecution_602794; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details of a job execution.
  ## 
  let valid = call_602955.validator(path, query, header, formData, body)
  let scheme = call_602955.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602955.url(scheme.get, call_602955.host, call_602955.base,
                         call_602955.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602955, url, valid)

proc call*(call_603026: Call_DescribeJobExecution_602794; thingName: string;
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
  var path_603027 = newJObject()
  var query_603029 = newJObject()
  add(path_603027, "thingName", newJString(thingName))
  add(path_603027, "jobId", newJString(jobId))
  add(query_603029, "executionNumber", newJInt(executionNumber))
  add(query_603029, "includeJobDocument", newJBool(includeJobDocument))
  result = call_603026.call(path_603027, query_603029, nil, nil, nil)

var describeJobExecution* = Call_DescribeJobExecution_602794(
    name: "describeJobExecution", meth: HttpMethod.HttpGet,
    host: "data.jobs.iot.amazonaws.com",
    route: "/things/{thingName}/jobs/{jobId}",
    validator: validate_DescribeJobExecution_602795, base: "/",
    url: url_DescribeJobExecution_602796, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPendingJobExecutions_603085 = ref object of OpenApiRestCall_602457
proc url_GetPendingJobExecutions_603087(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetPendingJobExecutions_603086(path: JsonNode; query: JsonNode;
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
  var valid_603088 = path.getOrDefault("thingName")
  valid_603088 = validateParameter(valid_603088, JString, required = true,
                                 default = nil)
  if valid_603088 != nil:
    section.add "thingName", valid_603088
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
  var valid_603089 = header.getOrDefault("X-Amz-Date")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "X-Amz-Date", valid_603089
  var valid_603090 = header.getOrDefault("X-Amz-Security-Token")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Security-Token", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Content-Sha256", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-Algorithm")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-Algorithm", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Signature")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Signature", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-SignedHeaders", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Credential")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Credential", valid_603095
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603096: Call_GetPendingJobExecutions_603085; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the list of all jobs for a thing that are not in a terminal status.
  ## 
  let valid = call_603096.validator(path, query, header, formData, body)
  let scheme = call_603096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603096.url(scheme.get, call_603096.host, call_603096.base,
                         call_603096.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603096, url, valid)

proc call*(call_603097: Call_GetPendingJobExecutions_603085; thingName: string): Recallable =
  ## getPendingJobExecutions
  ## Gets the list of all jobs for a thing that are not in a terminal status.
  ##   thingName: string (required)
  ##            : The name of the thing that is executing the job.
  var path_603098 = newJObject()
  add(path_603098, "thingName", newJString(thingName))
  result = call_603097.call(path_603098, nil, nil, nil, nil)

var getPendingJobExecutions* = Call_GetPendingJobExecutions_603085(
    name: "getPendingJobExecutions", meth: HttpMethod.HttpGet,
    host: "data.jobs.iot.amazonaws.com", route: "/things/{thingName}/jobs",
    validator: validate_GetPendingJobExecutions_603086, base: "/",
    url: url_GetPendingJobExecutions_603087, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartNextPendingJobExecution_603099 = ref object of OpenApiRestCall_602457
proc url_StartNextPendingJobExecution_603101(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_StartNextPendingJobExecution_603100(path: JsonNode; query: JsonNode;
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
  var valid_603102 = path.getOrDefault("thingName")
  valid_603102 = validateParameter(valid_603102, JString, required = true,
                                 default = nil)
  if valid_603102 != nil:
    section.add "thingName", valid_603102
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
  var valid_603103 = header.getOrDefault("X-Amz-Date")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Date", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-Security-Token")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-Security-Token", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Content-Sha256", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Algorithm")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Algorithm", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-Signature")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-Signature", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-SignedHeaders", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Credential")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Credential", valid_603109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603111: Call_StartNextPendingJobExecution_603099; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets and starts the next pending (status IN_PROGRESS or QUEUED) job execution for a thing.
  ## 
  let valid = call_603111.validator(path, query, header, formData, body)
  let scheme = call_603111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603111.url(scheme.get, call_603111.host, call_603111.base,
                         call_603111.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603111, url, valid)

proc call*(call_603112: Call_StartNextPendingJobExecution_603099;
          thingName: string; body: JsonNode): Recallable =
  ## startNextPendingJobExecution
  ## Gets and starts the next pending (status IN_PROGRESS or QUEUED) job execution for a thing.
  ##   thingName: string (required)
  ##            : The name of the thing associated with the device.
  ##   body: JObject (required)
  var path_603113 = newJObject()
  var body_603114 = newJObject()
  add(path_603113, "thingName", newJString(thingName))
  if body != nil:
    body_603114 = body
  result = call_603112.call(path_603113, nil, nil, nil, body_603114)

var startNextPendingJobExecution* = Call_StartNextPendingJobExecution_603099(
    name: "startNextPendingJobExecution", meth: HttpMethod.HttpPut,
    host: "data.jobs.iot.amazonaws.com", route: "/things/{thingName}/jobs/$next",
    validator: validate_StartNextPendingJobExecution_603100, base: "/",
    url: url_StartNextPendingJobExecution_603101,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

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
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
